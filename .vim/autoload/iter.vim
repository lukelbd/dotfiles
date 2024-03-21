"-----------------------------------------------------------------------------"
" Utilities for scrolling and iterating
"-----------------------------------------------------------------------------"
" Helper functions
" Note: This auto opens folds when jumping from quickfix and removes taglist
" normal-mode mappings. Should add to this in future.
function! iter#setup_quickfix() abort
  exe 'nnoremap <buffer> <CR> <CR>zv'
endfunction
function! iter#setup_taglist() abort
  for char in 'ud' | silent! exe 'nunmap <buffer> ' . char | endfor
endfunction

" Perform action conditional on insert-mode popup or cmdline complete state
" Note: This supports hiding complete-mode options or insert-mode popup menu
" before proceeding with other actions. See vimrc for details
function! iter#complete_popup(map, ...) abort
  let s = a:0 > 1 && a:2 ? '' : a:map
  if a:0 && a:1 > 1  " select item or perform action
    let [map1, map2, map3] = ["\<C-y>" . s, "\<C-n>\<C-y>" . s, a:map]
  elseif a:0 && a:1 > 0  " select item only if scrolled
    let [map1, map2, map3] = ["\<C-y>" . s, a:map, a:map]
  else  " exit popup or perform action
    let [map1, map2, map3] = ["\<C-e>" . s, "\<C-e>" . s, a:map]
  endif
  let state = get(b:, 'scroll_state', 0) | let b:scroll_state = 0
  return state && pumvisible() ? map1 : pumvisible() ? map2 : map3
endfunction
function! iter#complete_cmdline(map, ...) abort
  let state = get(b:, 'complete_state', 0)  " tabbed through entries
  if a:0 && a:1 || !state && !wildmenumode()
    let [keys1, keys2] = ['', a:map]
    let b:complete_state = state
  else  " e.g. cursor motions
    let [pos, line] = [getcmdpos(), getcmdline()]  " pos 1 is string index 0
    let keys1 = "\<C-c>\<Cmd>redraw\<CR>:" . line . a:map
    let keys2 = pos >= len(line) && a:map ==# "\<Right>" ? "\<Tab>" : ''
    let b:complete_state = 0  " manually disabled
  endif
  call feedkeys(keys1, 'n') | call feedkeys(keys2, 'tn') | return ''
endfunction

" Navigate conflict markers cyclically
" Note: This is adapted from conflict-marker.vim/autoload/conflict_marker.vim. Only
" searches for complete blocks, ignores false-positive block matches e.g. markdown ===
function! iter#next_conflict(count, ...) abort
  let winview = winsaveview()
  let reverse = a:0 && a:1
  if !reverse
    for _ in range(a:count) | let pos0 = searchpos(g:conflict_marker_begin, 'w') | endfor
    let pos1 = searchpos(g:conflict_marker_separator, 'cW')
    let pos2 = searchpos(g:conflict_marker_end, 'cW')
  else
    for _ in range(a:count) | let pos2 = searchpos(g:conflict_marker_end, 'bw') | endfor
    let pos1 = searchpos(g:conflict_marker_separator, 'bcW')
    let pos0 = searchpos(g:conflict_marker_begin, 'bcW')
  endif
  if pos2[0] > pos1[0] && pos1[0] > pos0[0]
    call cursor(pos0)  " always open folds (same as gitgutter)
    exe 'normal! zv'
  else  " echo warning
    call winrestview(winview)
    echohl ErrorMsg
    echom 'Error: No conflicts'
    echohl None
  endif
endfunction

" Navigate location list errors cyclically: https://vi.stackexchange.com/a/14359
" Note: Adding '+ 1 - reverse' fixes vint issue where ]x does not move from final error
function! iter#next_loc(count, list, ...) abort
  " Generate list of loc dictionaries
  let cmd = a:list ==# 'loc' ? 'll' : 'cc'
  let func = 'get' . a:list . 'list'
  let reverse = a:0 && a:1
  let params = a:list ==# 'loc' ? [0] : []
  let items = call(func, params)
  call map(items, "extend(v:val, {'idx': v:key + 1})")
  if reverse  " reverse search
    call reverse(items)
  endif
  if empty(items)
    echohl ErrorMsg
    echom 'Error: No errors'
    echohl None | return
  endif
  " Circularly jump to next loc
  let [lnum, cnum] = [line('.'), col('.')]
  let [cmps, oper] = [[], reverse ? '<' : '>']
  call add(cmps, 'v:val.lnum ' . oper . ' lnum')
  call add(cmps, 'v:val.col ' . oper . ' cnum + 1 - reverse')
  call filter(items, join(cmps, ' || '))
  let idx = get(get(items, 0, {}), 'idx', '')
  if type(idx) != 0
    exe reverse ? line('$') : 1 | call iter#next_loc(a:count, a:list, reverse)
  elseif a:count > 1
    exe cmd . ' ' . idx | call iter#next_loc(a:count - 1, a:list, reverse)
  else  " jump to error
    exe cmd . ' ' . idx
  endif
  if &l:foldopen =~# 'quickfix' | exe 'normal! zv' | endif
endfunction

" Navigate matches without editing jumplist and words with conservative iskeyword
" Note: This implements indexed-search directional consistency
" and avoids adding to the jumplist to prevent overpopulation
function! iter#next_motion(motion, ...) abort
  let cmd = 'setlocal iskeyword=' . &l:iskeyword
  setlocal iskeyword=@,48-57,192-255
  let action = a:0 ? a:1 ==# 'c' ? "\<Esc>c" : a:1 : ''
  echom 'Go!!! ' . action . v:count1 . a:motion
  call feedkeys(action . v:count1 . a:motion . "\<Cmd>" . cmd . "\<CR>", 'n')
endfunction
function! iter#next_match(count) abort
  let forward = get(g:, 'indexed_search_n_always_searches_forward', 0)  " default
  if forward && !v:searchforward
    let map = a:count > 0 ? 'N' : 'n'
  else
    let map = a:count > 0 ? 'n' : 'N'
  endif
  let b:prevpos = getcurpos()
  if !empty(@/)
    call feedkeys("\<Cmd>keepjumps normal! " . abs(a:count) . map . "\<CR>", 'n')
  else
    echohl ErrorMsg | echom 'Error: Pattern not set' | echohl None
  endif
  if !empty(@/)
    call feedkeys("\<Cmd>exe b:prevpos == getcurpos() ? '' : 'ShowSearchIndex'\<CR>", 'n')
  endif
endfunction

" Insert complete menu items and scroll complete or preview windows (whichever open).
" Note: Used 'verb function! lsp#scroll' to figure out how to detect preview windows
" (also verified lsp#scroll l:window.find does not return popup completion windows)
function! s:scroll_popup(scroll, ...) abort
  let size = a:0 ? a:1 : get(pum_getpos(), 'size', 1)
  let state = get(b:, 'scroll_state', 0)
  let cnt = type(a:scroll) ? float2nr(a:scroll * size) : a:scroll
  let cnt = a:scroll > 0 ? max([cnt, 1]) : min([cnt, -1])
  if type(a:scroll) && state != 0   " disable circular scroll
    let cnt = max([0 - state + 1, cnt])
    let cnt = min([size - state, cnt])
  endif
  let cmax = size + 1  " i.e. nothing selected
  let state += cnt + cmax * (1 + abs(cnt) / cmax)
  let state %= cmax  " only works with positive integers
  let keys = repeat(cnt > 0 ? "\<C-n>" : "\<C-p>", abs(cnt))
  let b:scroll_state = state | return keys
endfunction
function! s:scroll_preview(scroll, ...) abort
  for winid in a:000  " iterate previews
    let info = popup_getpos(winid)
    if !info.visible | continue | endif
    let width = info.core_width  " excluding borders (as with minwidth)
    let height = info.core_height  " excluding borders (as with minheight)
    let cnt = type(a:scroll) ? float2nr(a:scroll * height) : a:scroll
    let cnt = a:scroll > 0 ? max([cnt, 1]) : min([cnt, -1])
    let lmax = max([line('$', winid) - height + 2, 1])  " up to one after end
    let lnum = info.firstline + cnt
    let lnum = min([max([lnum, 1]), lmax])
    let opts = {'firstline': lnum, 'minwidth': width, 'minheight': height}
    call popup_setoptions(winid, opts)
  endfor
  return "\<Cmd>doautocmd User lsp_float_opened\<CR>"
endfunction

" Scroll complete menu or preview popup windows
" Note: This prevents vim's baked-in circular complete menu scrolling.
" Scroll normal mode lines
function! iter#scroll_normal(scroll, ...) abort
  let height = a:0 ? a:1 : winheight(0)
  let cnt = type(a:scroll) ? float2nr(a:scroll * height) : a:scroll
  let rev = a:scroll > 0 ? 0 : 1  " forward or reverse scroll
  let cmd = 'call scrollwrapped#scroll(' . abs(cnt) . ', ' . rev . ')'
  return mode() =~? '^[ir]' ? '' : "\<Cmd>" . cmd . "\<CR>"  " only normal mode
endfunction
" Scroll and update the count
function! iter#scroll_infer(scroll, ...) abort
  let popup_pos = pum_getpos()
  let preview_ids = popup_list()
  if a:0 && a:1 || !empty(popup_pos)  " automatically returns empty if not present
    return call('s:scroll_popup', [a:scroll])
  elseif !empty(preview_ids)
    return call('s:scroll_preview', [a:scroll] + preview_ids)
  elseif a:0 && !a:1
    return call('iter#scroll_normal', [a:scroll])
  else  " default fallback is arrow press
    return a:scroll > 0 ? "\<Down>" : a:scroll < 0 ? "\<Up>" : ''
  endif
endfunction
