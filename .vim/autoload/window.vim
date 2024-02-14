"-----------------------------------------------------------------------------"
" Utilities for vim windows and sessions
"-----------------------------------------------------------------------------"
" Return buffers by most recent
" See: https://vi.stackexchange.com/a/22428/8084 (comment)
" Note: Here try to detect tabs that were either accessed within session or were only
" loaded sequentially on startup by finding the minimum access time that differs from
" its closest neighbors by more than a few seconds. Sort buffers before this threshold
" in reverse order i.e. tab order and after this in standard order i.e. access order.
function! s:buffers_recent() abort
  let times = map(getbufinfo(), {idx, val -> val['lastused']})
  let mintime = 0
  for buftime in sort(times)
    if mintime && buftime - mintime > 10 | break | endif
    let mintime = buftime  " approximate time all buffers were loaded
  endfor
  let info = sort(getbufinfo(), {val1, val2 ->
    \ val2['lastused'] <= mintime && val1['lastused'] <= mintime
    \ ? val1['lastused'] - val2['lastused'] : val2['lastused'] - val1['lastused']}
  \ )
  return map(info, {idx, val -> val['bufnr']})
endfunction
function! window#buffer_sort(args) abort
  let unsorted = {}  " note keys auto-convert to string
  for [nr, value] in items(a:args)  " valid for dicts and lists
    let nr = type(a:args) == 4 ? nr : bufnr(value)
    let values = type(value) == 3 ? value : [value]
    let unsorted[nr] = values
  endfor
  let sorted = []
  let bufnrs = keys(unsorted)
  for nr in s:buffers_recent()
    let idx = index(bufnrs, string(nr))
    if idx >= 0
      call extend(sorted, remove(unsorted, bufnrs[idx]))
      call remove(bufnrs, idx)
    endif
  endfor
  for items in values(unsorted)
    call extend(sorted, items)
  endfor
  return sorted
endfunction

" Return main buffers in each tab
" Note: This sorts by recent access to help replace :Buffers
" Warning: Critical to keep up-to-date with g:tabline_skip_filetypes name
function! window#buffer_source() abort
  let ndigits = len(string(tabpagenr('$')))
  let tabskip = get(g:, 'tabline_skip_filetypes', [])  " keep up to date
  let unsorted = {}
  let bnrs = TablineBuffers()
  for idx in range(len(bnrs))
    let tnr = idx + 1
    let bnr = bnrs[idx]
    if bnr < 0
      continue
    elseif exists('*RelativePath')
      let path = RelativePath(bufname(bnr))
    else
      let path = expand('#' . bnr . ':~:.')
    endif
    let flags = TablineFlags(bnr)  " skip processing
    let pad = repeat(' ', ndigits - len(string(tnr)))
    let value = pad . tnr . ': ' . path . flags  " displayed string
    let unsorted[bnr] = add(get(unsorted, bnr, []), value)
  endfor
  return window#buffer_sort(unsorted)
endfunction

" Safely closing tabs and windows
" Note: Currently codi emits annoying error messages when turning on/off but
" still works so suppress messages here.
" Note: Calling quit inside codi buffer triggers 'attempt to close buffer
" that is in use' error so instead return to main window and toggle codi.
function! window#close_tab() abort
  let ntabs = tabpagenr('$')
  let islast = ntabs == tabpagenr()
  let ftypes = map(tabpagebuflist(), "getbufvar(v:val, '&filetype', '')")
  if &filetype ==# 'codi'
    wincmd p | silent! Codi!!
  elseif index(ftypes, 'codi') != -1
    silent! Codi!!
  endif
  if ntabs == 1 | quitall | else
    tabclose | if !islast | silent! tabprevious | endif
  endif
endfunction
function! window#close_window() abort
  let ntabs = tabpagenr('$')
  let islast = ntabs == tabpagenr()
  let ftypes = map(tabpagebuflist(), "getbufvar(v:val, '&filetype', '')")
  if &filetype ==# 'codi'
    wincmd p | silent! Codi!!
  elseif index(ftypes, 'codi') != -1
    silent! Codi!! | quit
  else
    quit
  endif
  if ntabs != tabpagenr('$') && !islast
    silent! tabprevious
  endif
endfunction

" Change window size in given direction
" Note: Vim :resize and :vertical resize expand the bottom side and right side of the
" panel by default (respectively) unless we are on the rightmost or bottommost panel.
" This counts the panels in each direction to figure out the correct sign for mappings
function! window#count_panes(...) abort
  let panes = 1
  for direc in a:000
    let wnum = 1
    let prev = winnr()
    while prev != winnr(wnum . direc)
      let prev = winnr(wnum . direc)
      let wnum += 1
      let panes += 1
      if panes > 50
        echohl WarningMsg
        echom 'Error: Failed to count window panes'
        echohl None
        let panes = 1
        break
      endif
    endwhile
  endfor
  return panes
endfunction
function! window#change_width(count) abort
  let wnum = window#count_panes('l') == 1 ? winnr('h') : winnr()
  call win_move_separator(wnum, a:count)
endfunction
function! window#change_height(count) abort
  let wnum = window#count_panes('j') == 1 ? winnr('k') : winnr()
  call win_move_statusline(wnum, a:count)
endfunction

" Return standard window width and height
" Note: Numbers passed to :resize exclude tab and cmd lines but numbers passed to
" :vertical resize include entire window (i.e. ignoring sign and number columns).
function! window#default_size(width, ...) abort
  if a:width  " window width
    let direcs = ['l', 'h']
    let size = &columns
  else  " window height
    setlocal cmdheight=1  " override in case changed
    let tabheight = &showtabline > 1 || &showtabline == 1 && tabpagenr('$') > 1
    let direcs = ['j', 'k']
    let size = &lines - tabheight - 2  " statusline and commandline
  endif
  let panel = bufnr() != get(b:, 'tabline_bufnr', bufnr())
  let panes = call('window#count_panes', direcs)
  let size = size - panes + 1  " e.g. 2 panes == 1 divider
  let space = float2nr(ceil(0.23 * size))
  if a:0 && a:1 || !a:0 && panel && panes > 1  " panel window
    return space
  elseif panes > 1  " main window
    return size - space
  else  " single window
    return size
  endif
endfunction
function! window#default_width(...) abort
  return call('window#default_size', [1] + a:000)
endfunction
function! window#default_height(...) abort
  return call('window#default_size', [0] + a:000)
endfunction

" Refresh window contents
" Note: Here :Gedit returns to head after viewing a blob. Can also use e.g. :Mru
" to return but this is faster. See https://github.com/tpope/vim-fugitive/issues/543
function! window#edit_buf() abort
  let type = get(b:, 'fugitive_type', '')
  if !empty(type)  " return to original file
    call git#fugitive_return()
  else  " reload from disk
    edit | call fold#update_folds(1)
  endif
  normal! zv
endfunction

" Select from open tabs
" Note: This displays a list with the tab number and the file. As with other
" commands sorts by recent access time for ease of use.
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
  exe split(a:item, ':')[0] . 'tabnext'
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
      \ 'options': '--no-sort --prompt="Move> "',
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
  for bnr in s:buffers_recent()
    let pad = repeat(' ', ndigits - len(string(bnr)))
    call add(lines, pad . bnr . ': ' . bufname(bnr))
  endfor
  let message = "Open buffers (sorted by recent use):\n" . join(lines, "\n")
  echo message
endfunction

" Close buffers that do not appear in windows
" See: https://stackoverflow.com/a/7321131/4970632
" See: https://github.com/Asheq/close-buffers.vim
function! window#wipe_bufs()
  let nums = []
  for tnr in range(1, tabpagenr('$'))
    call extend(nums, tabpagebuflist(tnr))
  endfor
  let names = []
  for bnr in range(1, bufnr('$'))
    if bufexists(bnr) && !getbufvar(bnr, '&mod') && index(nums, bnr) == -1
      call add(names, bufname(bnr))
      silent exe 'bwipeout ' bnr
    endif
  endfor
  if !empty(names)
    echom 'Wiped out ' . len(names) . ' hidden buffer(s): ' . join(names, ', ')
  endif
endfunction
