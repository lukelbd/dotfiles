"-----------------------------------------------------------------------------"
" Utilities for managing files
"-----------------------------------------------------------------------------"
" Helper functions and variables
" Warning: For some reason including 'down' in fzf#run prevents fzf from returning
" a list (version 0.29). However exluding it produces weird behavior that blacks
" out rest of screen. Workaround is to factor out an unnecessary source function.
let s:new_file = '[new file]'  " dummy entry for requesting new file in current directory

" Path utilities
" Print information and whether current file exists
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

" Generate list of files in directory
" Warning: Critical that the list options match the prompt lead or else
" when a single path is returned <Tab> during input() does not complete it.
function! s:path_source(dir, user) abort
  let paths = split(globpath(a:dir, '*'), "\n") + split(globpath(a:dir, '.?*'), "\n")
  let paths = map(paths, "fnamemodify(v:val, ':t')")
  if a:user | call insert(paths, s:new_file, 0) | endif
  return paths
endfunction
function! file#path_list(lead, line, cursor) abort
  let head = fnamemodify(a:lead, ':h')
  let tail = fnamemodify(a:lead, ':t')
  if head ==# '.'  " exclude leading component
    let paths = glob(tail . '*', 1, 1) + glob(tail . '.*', 1, 1)
  else  " include leading component
    let paths = globpath(head, tail . '*', 1, 1) + globpath(head, tail . '.*', 1, 1)
  endif
  let paths = filter(paths, "fnamemodify(v:val, ':t') !~# '^\\.\\+$'")
  let paths = map(paths, "isdirectory(v:val) ? v:val . '/' : v:val")
  return paths
endfunction

" Open from local or current directory (see also grep.vim)
" Note: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
function! file#open_from(files, local) abort
  let cmd = a:files ? 'Files' : 'Open'  " recursive fzf or non-resucrive internal
  let dir = a:local ? expand('%:p:h') : getcwd()  " neither has trailing slash
  let path = fnamemodify(dir, ':~')
  let prompt = cmd . ' (' . path . ')'  " display longer version in prompt
  let default = fnamemodify(dir, ':p:~:.')  " display shorter version here
  let start = utils#input_complete(prompt, 'file#path_list', default)
  if empty(start) | return | endif
  exe cmd . ' ' . start
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
    let user = item ==# s:new_file
    if user  " should be recursed at least one level
      let item = input(fnamemodify(base, ':~:.') . '/', '', 'customlist,utils#null_list')
    endif
    let item = substitute(item, '\s', '\ ', 'g')
    if item ==# '..'  " :p adds a slash so need two :h:h to remove then
      call add(paths, fnamemodify(base, ':p:h:h'))
    elseif !empty(item)
      call add(paths, empty(base) ? item : base . '/' . item)
    elseif user
      call add(paths, base)
    endif
  endfor
  " Possibly activate or re-activate fzf
  if empty(paths) || len(paths) == 1 && isdirectory(paths[0])
    let base = empty(paths) ? '.' : paths[0]
    let base = fnamemodify(base, ':p')  " full directory name
    let base = substitute(base, '/$', '', '')  " remove trailing slash
    let trunc = fnamemodify(base, ':~:.')  " remove unnecessary stuff
    let trunc = trunc[:1] =~# '/' ? trunc : './' . trunc
    let paths = []  " only continue in recursion
    call fzf#run(fzf#wrap({
      \ 'source': s:path_source(base, 1),
      \ 'sinklist': function('s:open_continuous', [base]),
      \ 'options': "--multi --no-sort --prompt='" . trunc . "/'",
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

" Open file or jump to tab. From tab drop plugin: https://github.com/ohjames/tabdrop
" Warning: The defaiult ':tab drop' seems to jump to the last tab on failure and
" also takes forever. Also have run into problems with it on some vim versions.
function! file#open_existing(file) abort
  let visible = {}
  let path = fnamemodify(a:file, ':p')
  let tabjump = 0
  for tnr in range(tabpagenr('$')) " iterate through each tab
    let tabnr = tnr + 1 " the tab number
    for bnr in tabpagebuflist(tabnr)
      if fnamemodify(bufname(bnr), ':p') ==# path
        let winnr = bufwinnr(bnr)
        exe tabnr . 'tabnext'
        exe winnr . 'wincmd w'
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

" Rename2.vim  -  Rename a buffer within Vim and on disk
" Copyright July 2009 by Manni Heumann <vim at lxxi.org> based on Rename.vim
" Note: Ignore missing 'b:gitgutter_was_enabled' error
function! file#rename_to(name, bang)
  let b:gitgutter_was_enabled = get(b:, 'gitgutter_was_enabled', 0)
  let curfile = expand('%:p')
  let curfilepath = expand('%:p:h')
  let newname = curfilepath . '/' . a:name
  let v:errmsg = ''
  silent! exe 'saveas' . a:bang . ' ' . newname
  if v:errmsg =~# '^$\|^E329\|^E108'
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
