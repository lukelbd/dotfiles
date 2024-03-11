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
    call cursor(pos0)
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
endfunction

" Navigate search matches without editing jumplist
" Note: This implements indexed-search directional consistency and avoids
" adding to the jumplist to prevent overpopulation
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

" Switch to next or previous colorschemes and print the name
" See: https://stackoverflow.com/a/2419692/4970632
" Note: Have to trigger 'BufEnter' so status line updates. Also note g:colors_name
" is convention shared by most color schemes, otherwise there is no vim setting.
function! iter#next_scheme(count) abort
  if !exists('g:all_colorschemes')
    let g:all_colorschemes = getcompletion('', 'color')
  endif
  let active_colorscheme = get(g:, 'colors_name', 'default')
  let idx = index(g:all_colorschemes, active_colorscheme)
  let idx = idx == -1 ? 0 : idx + a:count   " set to zero if not present
  let idx = idx % len(g:all_colorschemes)
  let scheme = g:all_colorschemes[idx]
  echom 'Colorscheme: ' . scheme
  exe 'colorscheme ' . scheme
  let g:colors_name = scheme
  doautocmd BufEnter
endfunction

" Insert complete menu items and scroll complete or preview windows (whichever open).
" Note: Used 'verb function! lsp#scroll' to figure out how to detect preview windows
" (also verified lsp#scroll l:window.find does not return popup completion windows)
function! s:scroll_default(scroll, height) abort
  let cnt = type(a:scroll) == 5 ? float2nr(a:scroll * a:height) : a:scroll
  let rev = a:scroll > 0 ? 0 : 1  " forward or reverse scroll
  let cmd = 'call scrollwrapped#scroll(' . abs(cnt) . ', ' . rev . ')'
  return mode() =~# '^[iIR]' ? '' : "\<Cmd>" . cmd . "\<CR>"  " only normal mode
endfunction
function! s:scroll_popup(scroll, height) abort
  let cnt = type(a:scroll) == 5 ? float2nr(a:scroll * a:height) : a:scroll
  let cnt = a:scroll > 0 ? max([cnt, 1]) : min([cnt, -1])
  if type(a:scroll) == 5 && b:scroll_state != 0   " disable circular scroll
    let cnt = max([0 - b:scroll_state + 1, cnt])
    let cnt = min([a:height - b:scroll_state, cnt])
  endif
  let b:scroll_state += cnt + (a:height + 1) * (1 + abs(cnt) / (a:height + 1))
  let b:scroll_state %= a:height + 1  " only works with positive integers
  let keys = repeat(cnt > 0 ? "\<C-n>" : "\<C-p>", abs(cnt))
  let keys .= "\<Cmd>doautocmd User lsp_float_opened\<CR>"
  return keys
endfunction
function! s:scroll_preview(scroll, ...) abort
  for winid in a:000
    let info = popup_getpos(winid)
    if !info.visible | continue | endif
    let width = info.core_width  " excluding borders (as with minwidth)
    let height = info.core_height  " excluding borders (as with minheight)
    let cnt = type(a:scroll) == 5 ? float2nr(a:scroll * height) : a:scroll
    let cnt = a:scroll > 0 ? max([cnt, 1]) : min([cnt, -1])
    let lmax = max([line('$', winid) - height + 2, 1])  " up to one after end
    let lnum = info.firstline + cnt
    let lnum = min([max([lnum, 1]), lmax])
    let opts = {'firstline': lnum, 'minwidth': width, 'minheight': height}
    call popup_setoptions(winid, opts)
  endfor
  return "\<Ignore>"
endfunction

" Scroll complete menu or preview popup windows
" Note: This prevents vim's baked-in circular complete menu scrolling.
" Reset the scroll count (for <expr> maps)
function! iter#scroll_reset() abort
  let b:scroll_state = 0
  return ''
endfunction
" Scroll and update the count
function! iter#scroll_count(scroll, ...) abort
  let popup_pos = pum_getpos()
  let preview_ids = popup_list()
  if a:0 && a:1 || !empty(popup_pos)  " automatically returns empty if not present
    return call('s:scroll_popup', [a:scroll, get(popup_pos, 'size', 1)])
  elseif !empty(preview_ids)
    return call('s:scroll_preview', [a:scroll] + preview_ids)
  elseif a:0 && !a:1
    return call('s:scroll_default', [a:scroll, winheight(0)])
  else  " default fallback is arrow press
    return a:scroll > 0 ? "\<Down>" : a:scroll < 0 ? "\<Up>" : ''
  endif
endfunction
