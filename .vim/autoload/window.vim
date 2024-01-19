"-----------------------------------------------------------------------------"
" Utilities for vim windows and sessions
"-----------------------------------------------------------------------------"
" Return buffers by most recent
" See: https://vi.stackexchange.com/a/22428/8084 (comment)
" Note: For some reason some edited files have 'nobuflisted' set (so ignored by
" e.g. :bnext). Maybe due to some plugin. Anyway do not use buflisted() filter.
" return filter(map(info, {idx, val -> val.bufnr}), {val -> buflisted(val)})
function! s:buffers_recent() abort
  let info = sort(getbufinfo(), {val1, val2 -> val2.lastused - val1.lastused})
  return map(info, {idx, val -> val.bufnr})
endfunction
function! window#buffer_sort(args) abort
  let unsorted = {}  " note keys auto-convert to string
  for [bufnr, value] in items(a:args)  " valid for lists and dictionaries
    let bufnr = type(a:args) == 3 ? bufnr(value) : bufnr
    let unsorted[bufnr] = value
  endfor
  let sorted = []
  let bufnrs = keys(unsorted)
  for bufnr in s:buffers_recent()
    let idx = index(bufnrs, string(bufnr))
    if idx >= 0
      call add(sorted, remove(unsorted, bufnrs[idx]))
      call remove(bufnrs, idx)
    endif
  endfor
  return sorted + values(unsorted)
endfunction

" Return main buffers in each tab
" Note: This sorts by recent access to help replace :Buffers
" Warning: Critical to keep up-to-date with g:tabline_skip_filetypes name
function! window#buffer_source() abort
  let ndigits = len(string(tabpagenr('$')))
  let tabskip = get(g:, 'tabline_skip_filetypes', [])  " keep up to date
  let unsorted = {}
  for tabnr in range(1, tabpagenr('$'))  " iterate through each tab
    let nr = -1  " default number
    let bufnrs = tabpagebuflist(tabnr)
    for bufnr in bufnrs
      if bufnr == bufnr()
        continue
      elseif index(tabskip, getbufvar(bufnr, '&ft')) == -1  " use if not a popup window
        let nr = bufnr | break
      elseif bufnr == bufnrs[-1]  " use if no non-popup windows
        let nr = bufnr
      endif
    endfor
    if nr < 0
      continue
    elseif exists('*RelativePath')
      let path = RelativePath(bufname(nr))
    else
      let path = fnamemodify(bufname(nr), ':~:.')
    endif
    let pad = repeat(' ', ndigits - len(string(tabnr)))
    let path = pad . tabnr . ': ' . path  " displayed string
    let unsorted[nr] = path
  endfor
  return window#buffer_sort(unsorted)
endfunction

" Safely closing tabs and windows
" Note: This moves to the left tab after closure
" Note: Calling quit inside codei buffer triggers 'attempt to close buffer
" that is in use' error so instead return to main window and toggle codi.
function! window#close_window() abort
  let ntabs = tabpagenr('$')
  let islast = ntabs == tabpagenr()
  if &l:filetype !=# 'codi'
    quit
  else
    wincmd p | Codi!!
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

" Select from open tabs
" Note: This displays a list with the tab number and the file
function! window#jump_tab(...) abort
  if a:0 && a:1
    call s:jump_tab_sink(a:1)
  else
    call fzf#run(fzf#wrap({
      \ 'source': window#buffer_source(),
      \ 'options': '--no-sort --prompt="Tab> "',
      \ 'sink': function('s:jump_tab_sink'),
      \ }))
  endif
endfunction
function! s:jump_tab_sink(item) abort
  exe 'normal! ' . split(a:item, ':')[0] . 'gt'
endfunction

" Move to selected tab
" Note: This also displays the tab names in case user wants to
" group this file appropriately amongst similar open files.
function! window#move_tab(...) abort
  if a:0 && a:1
    call s:move_tab_sink(a:1)
  else
    call fzf#run(fzf#wrap({
      \ 'source': window#buffer_source(),
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
  for bufnr in s:buffers_recent()
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
