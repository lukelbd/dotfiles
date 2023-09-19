"-----------------------------------------------------------------------------"
" Utilities for vim windows and sessions
"-----------------------------------------------------------------------------"
" List buffers by most recent
" See: https://vi.stackexchange.com/a/22428/8084 (comment)
" Note: For some reason some edited files have 'nobuflisted' set (so ignored by
" e.g. :bnext). Maybe due to some plugin. Anyway do not use buflisted() filter.
scriptencoding utf-8
function! s:recent_bufs() abort
  let info = getbufinfo()
  let info = sort(info, {val1, val2 -> val2.lastused - val1.lastused})
  return map(info, {idx, val -> val.bufnr})
" let nums = map(info, {idx, val -> val.bufnr})
" return filter(nums, {val -> buflisted(val)})
endfunction

" Safely closing tabs and windows
" Note: This moves to the left tab after closure
" Note: Calling quit inside codei buffer triggers 'attempt to close buffer
" that is in use' error so instead return to main window and toggle codi.
function! window#close_window() abort
  let ntabs = tabpagenr('$')
  let islast = ntabs == tabpagenr()
  if &l:filetype ==# 'codi'
    wincmd p | Codi!!
  else
    silent! quit
  endif
  if ntabs != tabpagenr('$') && !islast
    silent! tabprevious
  endif
endfunction
function! window#close_tab() abort
  let ntabs = tabpagenr('$')
  let islast = ntabs == tabpagenr()
  if ntabs == 1
    silent! quitall
  else
    silent! tabclose
    if !islast
      silent! tabprevious
    endif
  endif
endfunction

" Show truncated fold text
" Note: Style here is inspired by vim-anyfold. For now stick to native
" per-filetype syntax highlighting becuase still has some useful features.
function! window#fold_text() abort
  " Format lines
  let digits = len(string(line('$')))
  let lines = string(v:foldend - v:foldstart + 1)
  let lines = repeat(' ', digits - len(lines)) . lines
  let lines = repeat('+ ', len(v:folddashes)) . lines . ' lines'
  " Format text
  let regex = '\s*' . comment#get_char() . '\s\+.*$'
  let text = substitute(getline(v:foldstart), regex, '', 'g')
  let regex = '\("""\|' . "'''" . '\)'  " replace docstrings
  let text = substitute(text, regex, '<docstring>', 'g')
  " Combine components
  let offset = scrollwrapped#numberwidth() + scrollwrapped#signwidth()
  let width = winwidth(0) - offset
  let width = min([width, &textwidth - 1])  " set maximum width
  let size = width - len(lines) - 2  " at least two spaces
  let text = len(text) > size ? text[:size - 4] . '···  ' : text
  let space = repeat(' ', width - len(text) - len(lines))
  let origin = line('.') == v:foldstart ? 0 : col('.') - (wincol() - offset)
  let result = text . space . lines
  return result[origin:]
endfunction

" Function that generates lists of tabs and their numbers
" Note: Here sorty by recently accessed to help replace :Buffers
" Warning: Need to keep up-to-date with tabline setting name
function! s:fzf_tab_source() abort
  let ndigits = len(string(tabpagenr('$')))
  let tabskip = get(g:, 'tabline_skip_filetypes', [])
  let unsorted = {}
  for tnr in range(1, tabpagenr('$'))  " iterate through each tab
    let tbufs = tabpagebuflist(tnr)
    for bnr in tbufs
      if index(tabskip, getbufvar(bnr, '&ft')) == -1  " use if not a popup window
        let bufnr = bnr | break
      elseif bnr == tbufs[-1]  " use if no non-popup windows
        let bufnr = bnr
      endif
    endfor
    if exists('*RelativePath')
      let path = RelativePath(bufname(bufnr))
    else
      let path = fnamemodify(bufname(bufnr), ':~:.')
    endif
    let pad = repeat(' ', ndigits - len(string(tnr)))
    let path = pad . tnr . ': ' . path  " displayed string
    let unsorted[string(bufnr)] = path
  endfor
  let sorted = []
  let used = []
  let nums = keys(unsorted)
  for bnr in s:recent_bufs()
    let idx = index(nums, string(bnr))
    if idx >= 0
      call add(sorted, remove(unsorted, nums[idx]))
    endif
  endfor
  return sorted + values(unsorted)
endfunction

" Select from open tabs
" Note: This displays a list with the tab number and the file
function! window#jump_tab() abort
  call fzf#run(fzf#wrap({
    \ 'source': s:fzf_tab_source(),
    \ 'options': '--no-sort --prompt="Tab> "',
    \ 'sink': function('s:jump_tab_sink'),
    \ }))
endfunction
function! s:jump_tab_sink(item) abort
  exe 'normal! ' . split(a:item, ':')[0] . 'gt'
endfunction

" Move to selected tab
" Note: This also displays the tab names in case user wants to
" group this file appropriately amongst similar open files.
function! window#move_tab(...) abort
  if a:0
    call s:move_tab_sink(a:1)
  else
    call fzf#run(fzf#wrap({
      \ 'source': s:fzf_tab_source(),
      \ 'options': '--no-sort --prompt="Number> "',
      \ 'sink': function('s:move_tab_sink'),
      \ }))
  endif
endfunction
function! s:move_tab_sink(nr) abort
  if type(a:nr) == 0  " input tab number
    let nr = a:nr
  else  " fzf selections string
    let nr = str2nr(split(a:nr, ':')[0])
  endif
  if nr == tabpagenr() || nr == 0 || nr ==# ''
    return
  elseif nr > tabpagenr() && v:version[0] > 7
    exe 'tabmove ' . min([nr, tabpagenr('$')])
  else
    exe 'tabmove ' . min([nr - 1, tabpagenr('$')])
  endif
endfunction

" Print currently open buffers
" Note: This should be used in conjunction with :WipeBufs
function! window#show_bufs() abort
  let ndigits = len(string(bufnr('$')))
  let result = {}
  let lines = []
  for bufnr in s:recent_bufs()
    let pad = repeat(' ', ndigits - len(string(bufnr)))
    call add(lines, pad . bufnr . ': ' . bufname(bufnr))
  endfor
  let message = "Open buffers (sorted by recent use):\n" . join(lines, "\n")
  echo message
endfunction

" Close buffers that do not appear in windows
" See: https://stackoverflow.com/a/7321131/4970632
" See: https://github.com/Asheq/close-buffers.vim
function! window#wipe_bufs()
  let nums = []
  for t in range(1, tabpagenr('$'))
    call extend(nums, tabpagebuflist(t))
  endfor
  let names = []
  for b in range(1, bufnr('$'))
    if bufexists(b) && !getbufvar(b, '&mod') && index(nums, b) == -1
      call add(names, bufname(b))
      silent exe 'bwipeout ' b
    endif
  endfor
  if !empty(names)
    echom 'Wiped out ' . len(names) . ' hidden buffer(s): ' . join(names, ', ')
  endif
endfunction
