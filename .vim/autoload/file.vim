"-----------------------------------------------------------------------------"
" Utilities for managing files
"-----------------------------------------------------------------------------"
" Helper functions and variables
" Warning: For some reason including 'down' in fzf#run prevents fzf from returning
" a list (version 0.29). However exluding it produces weird behavior that blacks
" out rest of screen. Workaround is to factor out an unnecessary source function.
let s:new_file = '[new file]'  " dummy entry for requesting new file in current directory

" Generate list of files in directory
" Note: This includes hidden and non-hidden files
function! s:path_source(dir) abort
  let paths = split(globpath(a:dir, '*'), "\n") + split(globpath(a:dir, '.?*'), "\n")
  let paths = map(paths, 'fnamemodify(v:val, '':t'')')
  call insert(paths, s:new_file, 0)  " highest priority
  return paths
endfunction

" Abbreviate path for the continuous open prompt
" Note: This removes $HOME folder and current path from string. Used in utils.vim
function! file#path_abbrev(path) abort
  let abb = substitute(a:path, '^\~', expand('~'), '')
  let abb = substitute(abb, '^' . getcwd(), '.', '')
  let abb = substitute(abb, '^' . expand('~'), '~', '')
  return empty(abb) ? '.' : abb
endfunction

" Open file or jump to tab. From tab drop plugin: https://github.com/ohjames/tabdrop
" Warning: For some reason :tab drop and even :<bufnr>wincmd w fails
" on monde version of vim so need to use the *tab jump* command instead!
function! file#open_existing(file) abort
  let visible = {}
  let path = fnamemodify(a:file, ':p')
  let tabjump = 0
  for t in range(tabpagenr('$')) " iterate through each tab
    let tabnr = t + 1 " the tab number
    for b in tabpagebuflist(tabnr)
      if fnamemodify(bufname(b), ':p') == path
        exe 'normal! ' . tabnr . 'gt'
        return
      endif
    endfor
  endfor
  if bufname('%') ==# '' && &modified == 0  " fill this window
    exec 'edit ' . a:file
  else  " create new tab
    exec 'tabnew ' . a:file
  end
endfunction

" Open from local or current directory
" Note: Using <expr> instead of this tiny helper function causes <C-c> to display
" annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
function! file#open_from(files, local) abort
  if a:files  " fzf recursively-descending open command
    let command = 'Files'
  else  " custom 'continuous' per-directory open command
    let command = 'Open'
  endif
  if a:local
    let default = expand('%:p:h') . '/'  " start from local directory
  else
    let default = fnamemodify(getcwd(), ':p')  " start from current directory
  endif
  let result = input(command . ': ', default, 'file')
  if !empty(result)
    exe command . ' ' . result
  endif
endfunction

" Check if user selection is directory, descend until user selects a file.
" Warning: Must use expand() rather than glob() or new file names are not completed.
" Warning: FZF executes asynchronously so cannot do loop recursion inside driver
" function. See https://github.com/junegunn/fzf/issues/1577#issuecomment-492107554
function! file#open_continuous(...) abort
  let paths = []
  for pattern in a:000
    let pattern = substitute(pattern, '^\s*\(.\{-}\)\s*$', '\1', '')  " strip spaces
    let files = expand(pattern, 0, 1)  " expand glob patterns
    call extend(paths, files)
  endfor
  call s:open_continuous(paths)  " call fzf sink function
endfunction
function! s:open_continuous(...) abort
  " Parse arguments
  if a:0 == 1  " user invocation
    let base = ''
    let items = a:1
  else  " fzf invocation
    let base = a:1
    let items = a:2
  endif
  " Process paths input manually or from fzf
  let paths = []
  for item in items
    if item == s:new_file  " should be recursed at least one level
      let item = input(file#path_abbrev(base) . '/', '', 'customlist,internals#null_list')
    endif
    let item = substitute(item, '\s', '\ ', 'g')
    if item ==# '..'  " fnamemodify :p does not remove the .. so must do this
      call add(paths, fnamemodify(base, ':p:h'))
    elseif !empty(item)
      call add(paths, empty(base) ? item : base . '/' . item)
    endif
  endfor
  " Possibly activate or re-activate fzf
  if empty(paths) || len(paths) == 1 && isdirectory(paths[0])
    let base = empty(paths) ? '.' : paths[0]
    let base = fnamemodify(base, ':p')  " full directory name
    let base = substitute(base, '/$', '', '')  " remove trailing slash
    let paths = []  " only continue in recursion
    call fzf#run(fzf#wrap({
      \ 'source': s:path_source(base),
      \ 'sinklist': function('s:open_continuous', [base]),
      \ 'options': "--multi --no-sort --prompt='" . file#path_abbrev(base) . "/'",
      \ }))
  endif
  " Open file(s), or if it is already open just to that tab
  for path in paths
    if isdirectory(path)  " false for empty string
      echohl WarningMsg
      echom "Warning: Skipping directory '" . path . "'."
      echohl None
    elseif path =~# '[*?[\]]'  " failed glob search so do nothing
      :
    elseif !empty(path)
      call file#open_existing(path)
    endif
  endfor
endfunction

" Print the absolute path
" Print whether the current file exists
function! file#print_abspath(...) abort
  let paths = a:0 ? a:000 : [@%]
  for path in paths
    let abs = fnamemodify(path, ':p')
    echom "Relative: '" . path "'"
    echom "Absolute: '" . abs . "'"
  endfor
endfunction
function! file#print_exists() abort
  let files = glob(expand('<cfile>'))
  if empty(files)
    echom "File or pattern '" . expand('<cfile>') . "' does not exist."
  else
    echom 'File(s) ' . join(map(a:0, '"''".v:val."''"'), ', ') . ' exist.'
  endif
endfunction

" Rename2.vim  -  Rename a buffer within Vim and on disk
" Copyright July 2009 by Manni Heumann <vim at lxxi.org> based on Rename.vim
" Usage: Rename[!] {newname}
function! file#rename_to(name, bang) abort
  let curfile = expand('%:p')
  let curfilepath = expand('%:p:h')
  let newname = curfilepath . '/' . a:name
  let v:errmsg = ''
  silent! exe 'saveas' . a:bang . ' ' . newname
  if v:errmsg =~# '^$\|^E329'
    if expand('%:p') !=# curfile && filewritable(expand('%:p'))
      silent exe 'bwipe! ' . curfile
      if delete(curfile) != 0
        throw 'Could not delete ' . curfile
      endif
    endif
  else
    throw v:errmsg
  endif
endfunction
