"-----------------------------------------------------------------------------"
" Utilities for vim windows and sessions
"-----------------------------------------------------------------------------"
" Return main buffers in each tab
" Note: This sorts by recent access to help replace :Buffers
" Warning: Critical to keep up-to-date with g:tabline_skip_filetypes name
function! window#buffer_source() abort
  let nprocess = 20  " maximum tablines to process
  let ndigits = len(string(tabpagenr('$')))
  let tabskip = get(g:, 'tabline_skip_filetypes', [])  " keep up to date
  let values = []
  let pairs = tags#buffer_paths()
  for idx in range(len(pairs))
    let [tnr, path] = pairs[idx]
    let process = idx < nprocess
    if exists('*RelativePath')
      let name = RelativePath(path)
    else
      let name = fnamemodify(path, ':~:.')
    endif
    let pad = repeat(' ', ndigits - len(string(tnr)))
    let flags = TablineFlags(path, process) . ' '  " mostly skip processing
    let hunks =  getbufvar(bufnr(path), 'gitgutter', {})
    let [acnt, mcnt, rcnt] = get(hunks, 'summary', [0, 0, 0])
    for [key, cnt] in [['+', acnt], ['~', mcnt], ['-', rcnt]]
      if !empty(cnt) | let flags .= key . cnt | endif
    endfor
    let value = pad . tnr . ': ' . name . flags  " displayed string
    call add(values, value)
  endfor
  return values
endfunction

" Safely closing tabs and windows
" Note: Currently codi emits annoying error messages when turning on/off but
" still works so suppress messages here.
" Note: Calling quit inside codi buffer triggers 'attempt to close buffer
" that is in use' error so instead return to main window and toggle codi.
function! window#close_tab(...) abort
  let bang = a:0 && a:1 ? '!' : ''
  let ntabs = tabpagenr('$')
  let islast = ntabs == tabpagenr()
  let ftypes = map(tabpagebuflist(), "getbufvar(v:val, '&filetype', '')")
  if &filetype ==# 'codi'
    wincmd p | silent! Codi!!
  elseif index(ftypes, 'codi') != -1
    silent! Codi!!
  endif
  if ntabs == 1 | quitall | else
    exe 'tabclose' . bang | if !islast | silent! tabprevious | endif
  endif
endfunction
function! window#close_window(...) abort
  let bang = a:0 && a:1 ? '!' : ''
  let ntabs = tabpagenr('$')
  let islast = ntabs == tabpagenr()
  let ftypes = map(tabpagebuflist(), "getbufvar(v:val, '&filetype', '')")
  if &filetype ==# 'codi'
    wincmd p | silent! Codi!!
  elseif index(ftypes, 'codi') != -1
    silent! Codi!! | exe 'quit' . bang
  else
    exe 'quit' . bang
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
  if panes == 1
    return size
  elseif a:0 && type(a:1) == 5
    return a:1 * size
  elseif a:0 && a:1 || !a:0 && panel
    return space
  else  " main window
    return size - space
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
function! s:parse_tab(item) abort
  if !type(a:item) | return [a:item, ''] | endif
  let [tnr; path] = split(a:item, ':')
  let flags = '\s\+\(\[.\]\s*\)*'  " tabline flags
  let stats = '\([+-~]\d\+\)*'  " statusline stats
  let path = join(path, ':')
  let path = substitute(path, flags . stats . '$', '', 'g')
  let path = substitute(path, '\(^\s\+\|\s\+$\)', '', 'g')
  call file#echo_path(path)
  return [str2nr(tnr), path]  " returns zero on error
endfunction
function! s:jump_tab(item) abort
  let [tnr, path] = s:parse_tab(a:item)
  exe tnr . 'tabnext'
endfunction
function! window#jump_tab(...) abort
  if a:0 && a:1
    return s:jump_tab(a:1)
  endif
  call fzf#run(fzf#wrap({
    \ 'source': window#buffer_source(),
    \ 'options': '--no-sort --prompt="Tab> "',
    \ 'sink': function('s:jump_tab'),
  \ }))
endfunction

" Move to selected tab
" Note: This also displays the tab names in case user wants to
" group this file appropriately amongst similar open files.
function! s:move_tab(item) abort
  let [tnr, path] = s:parse_tab(a:item)
  if tnr == 0 || tnr == tabpagenr()
    return
  elseif tnr > tabpagenr() && v:version[0] > 7
    exe 'tabmove ' . min([tnr, tabpagenr('$')])
  else
    exe 'tabmove ' . min([tnr - 1, tabpagenr('$')])
  endif
endfunction
function! window#move_tab(...) abort
  if a:0 && a:1
    return s:move_tab(a:1)
  endif
  call fzf#run(fzf#wrap({
    \ 'source': window#buffer_source(),
    \ 'options': '--no-sort --prompt="Move> "',
    \ 'sink': function('s:move_tab'),
  \ }))
endfunction

" Print currently open buffers
" Note: This should be used in conjunction with :WipeBufs. Note s:buffers_recent()
" normally restricts output to files loaded after VimEnter but bypass that here.
function! window#show_bufs() abort
  let ndigits = len(string(bufnr('$')))
  let result = {}
  let lines = []
  for bnr in tags#buffers_recent(0)  " include all buffers
    let pad = repeat(' ', ndigits - len(string(bnr)))
    if exists('*RelativePath')
      let path = RelativePath(bufname(bnr))
    else
      let path = expand('#' . bnr . ':~:.')
    endif
    call add(lines, pad . bnr . ': ' . path)
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

" Reset recent files
" Note: This only triggers after spending time on window instead of e.g. browsing
" across tabs with maps, similar to jumplist. Then can access jumps in each window.
function! window#reset_recent() abort  " non-scrolling window change floats 'recent' to top
  for bnr in tabpagebuflist()  " tab page buffers
    call setbufvar(bnr, 'recent_scroll', 0)
  endfor
endfunction
function! window#scroll_recent(...) abort  " scrolling window change preserves list order
  let bnr = bufnr()
  let scroll = a:0 ? a:1 : v:count1
  call window#update_recent()  " sync location, possibly float if starting scroll
  call iter#next_stack(function('file#open_drop', [1]), 'recent', scroll)  " quiet flag
  if bnr != bufnr() | call window#update_recent(1, 1) | endif  " apply b:recent_scroll
endfunction
function! window#update_recent(...) abort  " set current buffer
  let skip = index(g:tags_skip_filetypes, &filetype)
  let scroll = a:0 ? a:1 : get(b:, 'recent_scroll', 0)
  let echo = a:0 > 1 ? a:2 : 0
  let b:recent_name = expand('%:p')  " apply name
  let b:recent_scroll = scroll
  if skip != -1 || line('$') <= 1 || empty(&filetype)
    if len(tabpagebuflist()) > 1 | return | endif
  endif
  call iter#push_stack('recent', scroll, -1, echo)  " possibly update stack
endfunction
