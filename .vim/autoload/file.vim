"-----------------------------------------------------------------------------"
" Utilities for managing files
"-----------------------------------------------------------------------------"
" Global settinsg
let s:newfile = '[new file]'  " dummy entry for requesting new file in current directory

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
function! file#rename(name, bang)
  let curfile = expand('%:p')
  let curfilepath = expand('%:p:h')
  let newname = curfilepath . '/' . a:name
  let v:errmsg = ''
  silent! exe 'saveas' . a:bang . ' ' . newname
  if v:errmsg =~# '^$\|^E329'
    if expand('%:p') !=# curfile && filewritable(expand('%:p'))
      silent exe 'bwipe! ' . curfile
      if delete(curfile)
        echoerr 'Could not delete ' . curfile
      endif
    endif
  else
    echoerr v:errmsg
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
" Warning: For some reason including 'down' in fzf#run prevents it from returning a
" list in latest version. Think list-returning behavior is fragile and undocumented.
function! s:list_files(dir) abort
  let paths = split(globpath(a:dir, '*'), "\n") + split(globpath(a:dir, '.?*'), "\n")
  let paths = map(paths, 'fnamemodify(v:val, '':t'')')
  call insert(paths, s:newfile, 0) " highest priority
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

" Check if user selection is directory, descend until user selects a file. This
" is similar to default shell tab expansion.
function! file#null_list(...) abort
  return []
endfunction
function! file#open_continuous(...) abort
  " Expand input paths
  let paths = []
  for pattern in a:000
    let pattern = substitute(pattern, '^\s*\(.\{-}\)\s*$', '\1', '')  " strip spaces
    call extend(paths, expand(pattern, 0, 1))
  endfor
  while empty(paths) || len(paths) == 1 && isdirectory(paths[0])
    " Format directory name
    let path = empty(paths) ? '.' : paths[0]
    let path = fnamemodify(path, ':p')
    let path = substitute(path, '/$', '', '')
    " Get user selection
    let prompt = substitute(path, '^' . expand('~'), '~', '')
    let items = fzf#run({
      \ 'source': s:list_files(path),
      \ 'options': "--no-sort --prompt='" . prompt . "/'",
      \ })
    " Turn user selections into paths, possibly requesting input file names
    if empty(items)
      break
    endif
    let paths = []
    for item in items
      if item == s:newfile
        let item = input(prompt . '/', '', 'customlist,file#null_list')
      endif
      if item ==# '..'  " fnamemodify :p does not expand the previous direcotry sign, so must do this instead
        call add(paths, fnamemodify(path, ':h'))  " head of current directory
      elseif !empty(item)
        call add(paths, path . '/' . item)
      endif
    endfor
  endwhile
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
  call fzf#run({
    \ 'source': s:tab_source(),
    \ 'options': '--no-sort --prompt="Tab> "',
    \ 'sink': function('s:tab_select_sink'),
    \ })
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
    call fzf#run({
      \ 'source': s:tab_source(),
      \ 'options': '--no-sort --prompt="Number> "',
      \ 'sink': function('s:tab_move_sink'),
      \ })
  endif
endfunction
