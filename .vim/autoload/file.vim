"-----------------------------------------------------------------------------"
" Utilities for managing files
"-----------------------------------------------------------------------------"
" Helper functions and variables
let s:newfile = '[new file]'  " dummy entry for requesting new file in current directory
function! s:make_prompt(dir) abort
  return substitute(a:dir, '^' . expand('~'), '~', '') . '/'  " remove user folder
endfunction

" Test if file exists
function! file#exists() abort
  let files = glob(expand('<cfile>'))
  if empty(files)
    echom "File or pattern '" . expand('<cfile>') . "' does not exist."
  else
    echom 'File(s) ' . join(map(a:0, '"''".v:val."''"'), ', ') . ' exist.'
  endif
endfunction

" Refresh settings
function! file#refresh() abort
  filetype detect " if started with empty file, but now shebang makes filetype clear
  filetype plugin indent on
  let loaded = []
  let files = [
    \ '~/.vimrc',
    \ '~/.vim/ftplugin/' . &filetype . '.vim',
    \ '~/.vim/syntax/' . &filetype . '.vim',
    \ '~/.vim/after/ftplugin/' . &filetype . '.vim',
    \ '~/.vim/after/syntax/' . &filetype . '.vim'
    \ ]
  for file in files
    if !empty(glob(file))
      exe 'so ' . file
      call add(loaded, file)
    endif
  endfor
  echom 'Loaded ' . join(map(loaded, 'fnamemodify(v:val, ":~")[2:]'), ', ') . '.'
endfunction

" Rename2.vim  -  Rename a buffer within Vim and on disk
" Copyright July 2009 by Manni Heumann <vim at lxxi.org> based on Rename.vim
" Copyright June 2007 by Christian J. Robinson <infynity@onewest.net>
" Usage: Rename[!] {newname}
function! file#rename(name, bang) abort
  let curfile = expand('%:p')
  let curfilepath = expand('%:p:h')
  let newname = curfilepath . '/' . a:name
  let v:errmsg = ''
  silent! exe 'saveas' . a:bang . ' ' . newname
  if v:errmsg =~# '^$\|^E329'
    if expand('%:p') !=# curfile && filewritable(expand('%:p'))
      silent exe 'bwipe! ' . curfile
      if delete(curfile)
        throw 'Could not delete ' . curfile
      endif
    endif
  else
    throw v:errmsg
  endif
endfunction

" Safely closing tabs and windows
" Note: This moves to the left tab after closure
function! file#close_window() abort
  let ntabs = tabpagenr('$')
  let islast = tabpagenr('$') == tabpagenr()
  quit
  if ntabs != tabpagenr('$') && !islast
    silent! tabp
  endif
endfunction
function! file#close_tab() abort
  let ntabs = tabpagenr('$')
  let islast = tabpagenr('$') == tabpagenr()
  if ntabs == 1
    qall
  else
    tabclose
    if !islast
      silent! tabp
    endif
  endif
endfunction

" Current directory change
function! file#directory_descend() abort
  let cd_prev = getcwd()
  if !exists('b:cd_prev') || b:cd_prev != cd_prev
    let b:cd_prev = cd_prev
  endif
  lcd %:p:h
  echom 'Descended into file directory.'
endfunction
function! file#directory_return() abort
  if exists('b:cd_prev')
    exe 'lcd ' . b:cd_prev
    unlet b:cd_prev
    echom 'Returned to previous directory.'
  else
    echom 'Previous directory is unset.'
  endif
endfunction

"-----------------------------------------------------------------------------"
" Opening files
"-----------------------------------------------------------------------------"
" Generate list of files in directory including hidden and non-hidden
" Warning: For some reason including 'down' in fzf#run prevents fzf from returning a
" list (version 0.29). However exluding it produces weird behavior that blacks out
" rest of screen. Workaround is to factor out an unnecessary source function.
function! s:list_files(dir) abort
  let paths = split(globpath(a:dir, '*'), "\n") + split(globpath(a:dir, '.?*'), "\n")
  let paths = map(paths, 'fnamemodify(v:val, '':t'')')
  call insert(paths, s:newfile, 0)  " highest priority
  return paths
endfunction

" Tab drop plugin from: https://github.com/ohjames/tabdrop
" Warning: For some reason :tab drop and even :<bufnr>wincmd w fails
" on monde so need to use the *tab jump* command instead!
function! s:tab_drop(file) abort
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
  let command = a:files ? 'Files' : 'Open'
  let default = a:local ? expand('%:p:h') . '/' : fnamemodify(getcwd(), ':p')
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
    call extend(paths, expand(pattern, 0, 1))  " expand glob patterns
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
    if item == s:newfile  " should be recursed at least one level
      let base = empty(base) ? '.' : base  " should be impossible but just in case
      let item = input(s:make_prompt(base), '', 'customlist,utils#null_list')
    endif
    if empty(item)  " e.g. cancelled input
      :
    elseif empty(base)
      call add(paths, item)
    elseif item ==# '..'  " fnamemodify :p does not expand .. so must do this instead
      call add(paths, fnamemodify(base, ':h'))  " head of current directory
    elseif !empty(item)
      call add(paths, base . '/' . item)
    endif
  endfor
  " Possibly activate or re-activate fzf
  if empty(paths) || len(paths) == 1 && isdirectory(paths[0])
    let base = empty(paths) ? '.' : paths[0]
    let base = fnamemodify(base, ':p')  " full directory name
    let base = substitute(base, '/$', '', '')  " remove trailing slash
    let paths = []  " only continue in recursion
    call fzf#run(fzf#wrap({
      \ 'source': s:list_files(base),
      \ 'sinklist': function('s:open_continuous', [base]),
      \ 'options': "--multi --no-sort --prompt='" . s:make_prompt(base) . "'",
      \ }))
  endif
  " Open file(s), or if it is already open just jump to that tab
  for path in paths
    if isdirectory(path)  " false for empty string
      echohl WarningMsg
      echom "Warning: Skipping directory '" . path . "'."
      echohl None
    elseif path =~# '[*?[\]]'  " failed glob search so do nothing
      :
    elseif !empty(path)
      call s:tab_drop(path)
    endif
  endfor
endfunction

"-----------------------------------------------------------------------------"
" Tab management
"-----------------------------------------------------------------------------"
" Function that generates lists of tabs and their numbers
function! s:tab_source() abort
  if !exists('g:tabline_bufignore')
    let g:tabline_bufignore = ['qf', 'vim-plug', 'help', 'diff', 'man', 'fugitive', 'nerdtree', 'tagbar', 'codi'] " filetypes considered 'helpers'
  endif
  let unsorted = []
  for t in range(tabpagenr('$')) " iterate through each tab
    let tabnr = t + 1 " the tab number
    let buflist = tabpagebuflist(tabnr)
    for b in buflist
      " Get the 'primary' panel in a tab, ignore 'helper' panels even when in focus
      " If there is *only* a 'helper' panel, use it for the title
      if index(g:tabline_bufignore, getbufvar(b, '&ft')) == -1
        let bufnr = b
        break
      elseif b == buflist[-1]
        let bufnr = b
      endif
    endfor
    call add(unsorted, tabnr . ': ' . fnamemodify(bufname(bufnr), '%:t'))  " name
  endfor
  let ctab = tabpagenr()
  let sorted = []
  for offset in range(1, tabpagenr('$'))
    if ctab + offset <= len(unsorted)
      call add(sorted, unsorted[ctab + offset - 1])
    endif
    if ctab - offset > 0
      call add(sorted, unsorted[ctab - offset - 1])
    endif
  endfor
  return sorted
endfunction

" Function that jumps to the tab number from a line generated by tabselect
function! s:tab_select_sink(item) abort
  exe 'normal! ' . split(a:item, ':')[0] . 'gt'
endfunction

" Select from open tabs
function! file#tab_select() abort
  call fzf#run(fzf#wrap({
    \ 'source': s:tab_source(),
    \ 'options': '--no-sort --prompt="Tab> "',
    \ 'sink': function('s:tab_select_sink'),
    \ }))
endfunction

" Move current tab to the exact place of tab number N
function! s:tab_move_sink(nr) abort
  if type(a:nr) == 0
    let nr = a:nr
  else
    let parts = split(a:nr, ':')  " fzf selection
    let nr = str2nr(parts[0])
  endif
  if nr == tabpagenr() || nr == 0 || nr ==# ''
    return
  elseif nr > tabpagenr() && v:version[0] > 7
    exe 'tabmove ' . nr
  else
    exe 'tabmove ' . (nr - 1)
  endif
endfunction

" Move to selected tab
" Note: We display the tab names in case we want to group this
" file appropriately amongst similar open files.
function! file#tab_move(...) abort
  if a:0
    call s:tab_move_sink(a:1)
  else
    call fzf#run(fzf#wrap({
      \ 'source': s:tab_source(),
      \ 'options': '--no-sort --prompt="Number> "',
      \ 'sink': function('s:tab_move_sink'),
      \ }))
  endif
endfunction
