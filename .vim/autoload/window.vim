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
  " Get fold text
  let status = string(v:foldend - v:foldstart + 1)
  let status = repeat(' ', len(string(line('$'))) - len(status)) . status
  let status = repeat('+ ', len(v:folddashes)) . status . ' lines'
  let regex = '\s*' . comment#get_char() . '\s\+.*$'
  for line in range(v:foldstart, v:foldend)
    let label = substitute(getline(line), regex, '', 'g')
    let chars = substitute(label, '\s\+', '', 'g')
    if !empty(chars) | break | endif
  endfor
  " Format fold text
  if &filetype ==# 'tex'  " hide backslashes
    let regex = '\\\@<!\\'
    let label = substitute(label, regex, '', 'g')
  endif
  if &filetype ==# 'python'  " replace docstrings
    let regex = '\("""\|' . "'''" . '\)'
    let label = substitute(label, regex, '<docstring>', 'g')
  endif
  let width = &textwidth - 1 - len(status)  " at least two spaces
  let label = len(label) > width - 4 ? label[:width - 6] . '···  ' : label
  " Combine components
  let space = repeat(' ', &textwidth - 1 - len(label) - len(status))
  let origin = 0  " string truncation point
  if !foldclosed(line('.'))
    let offset = scrollwrapped#numberwidth() + scrollwrapped#signwidth()
    let origin = col('.') - (wincol() - offset)
  endif
  let text = label . space . status
  " vint: next-line -ProhibitUsingUndeclaredVariable
  return text[origin:]
endfunction

" Function that generates lists of tabs and their numbers
" Note: Here sorty by recently accessed to help replace :Buffers
" Warning: Need to keep up-to-date with tabline setting name
function! s:fzf_tab_source() abort
  let ndigits = len(string(tabpagenr('$')))
  let tabskip = get(g:, 'tabline_skip_filetypes', [])
  let unsorted = {}
  for tnr in range(1, tabpagenr('$'))  " iterate through each tab
    let bnrs = tabpagebuflist(tnr)
    for bnr in bnrs
      if index(tabskip, getbufvar(bnr, '&ft')) == -1  " use if not a popup window
        let buf = bnr | break
      elseif bnr == bnrs[-1]  " use if no non-popup windows
        let buf = bnr
      endif
    endfor
    if exists('*RelativePath')
      let path = RelativePath(bufname(buf))
    else
      let path = fnamemodify(bufname(buf), ':~:.')
    endif
    let pad = repeat(' ', ndigits - len(string(tnr)))
    let path = pad . tnr . ': ' . path  " displayed string
    let unsorted[string(buf)] = path
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
