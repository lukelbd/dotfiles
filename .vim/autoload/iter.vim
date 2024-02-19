"-----------------------------------------------------------------------------"
" Utilities for navigating and iterating
"-----------------------------------------------------------------------------"
" Helper functions the custom-built buffer stack utilities
" Warning: Below returns name index optionally filtered to the last nmax entries
" of the stack. Note e.g. [1, 2, 3][-5:] is empty list, careful with this.
function! s:add_stack(head, stack, idx) abort
  let g:[a:head . '_stack'] = a:stack
  let g:[a:head . '_loc'] = a:idx
endfunction
function! s:echo_stack(head, name, idx, size, ...) abort
  if type(a:name) == 3
    let label = a:name[0] . ' (' . join(a:name[1:], ':') . ')'
  elseif bufexists(a:name)
    let label = RelativePath(a:name)
  else
    let label = string(a:name)
  endif
  let prefix = toupper(a:head[0]) . a:head[1:] . ': '
  let suffix = ' (' . (a:idx + 1) . '/' . a:size . ')'
  echom prefix . label . suffix
endfunction
function! s:query_stack(head, buf, ...) abort
  let bnr = bufnr(a:buf)
  let nmax = a:0 ? a:1 : 0
  let stack = get(g:, a:head . '_stack', [])
  let idx = get(g:, a:head . '_loc', -1)
  let name = getbufvar(bnr, a:head . '_name', '')  " buffer variable to push
  let jdx = !nmax ? 0 : len(stack) - min([nmax, len(stack)])
  " vint: -ProhibitUsingUndeclaredVariable
  let kdx = empty(name) ? -1 : index(stack[jdx:], name)
  let kdx = kdx != -1 ? jdx + kdx : -1
  return [stack, idx, name, kdx]
endfunction

" General bulk stack operations
" Note: Use e.g. ClearRecent ShowRecent commands in vimrc with these. All other
" functions are for autocommands or normal mode mappings
function! iter#clear_stack(head) abort
  if has_key(g:, a:head . '_stack')
    call remove(g:, a:head . '_stack')
    call remove(g:, a:head . '_loc')
    echom "Cleared '" . a:head . "' buffer stack"
  else
    echohl WarningMsg
    echom "Error: Buffer stack '" . a:head . "' does not exist"
    echohl None
  endif
endfunction
function! iter#show_stack(head) abort
  let [stack, idx; rest] = s:query_stack(a:head, '', 0)
  let ndigits = len(string(len(stack)))
  echom "Current '" . a:head . "' stack:"
  for jdx in range(len(stack))
    let pad = idx == jdx ? '> ' : '  '
    let pad .= repeat(' ', ndigits - len(string(jdx)))
    call s:echo_stack(pad . jdx, stack[jdx], jdx, len(stack))
  endfor
endfunction

" Modify or display the requested buffer stack
" Note: Here popping only used for recent window stack, are careful to keep synced
" Note: Use 1ms timer_start to prevent issue where echo hidden by buffer change
function! iter#pop_stack(head, ...) abort
  let buf = a:0 ? a:1 : ''
  let [stack, idx, name, kdx] = s:query_stack(a:head, buf, 0)
  if kdx == -1 | return | endif  " remove current item, generally
  call remove(stack, kdx)
  let idx = idx > kdx ? idx - 1 : idx  " if idx == jdx float to next entry
  let idx = empty(stack) ? -1 : min([max([idx, 0]), len(stack) - 1])
  call s:add_stack(a:head, stack, idx)
endfunction
function! iter#push_stack(head, scroll, ...) abort  " update location and possibly append
  let nmax = a:scroll ? 0 : 5  " number to search
  let [stack, idx, name, kdx] = s:query_stack(a:head, bufnr(), nmax)
  if empty(name) | return | endif
  let jdx = a:0 && a:1 >= 0 ? a:1 : len(stack)
  let echo = a:0 > 1 ? a:2 : 0  " verbose mode
  if jdx >= len(stack)  " update stack?
    " vint: -ProhibitUsingUndeclaredVariable
    if kdx == -1  " add new entry
      call add(stack, name)
      let jdx = len(stack) - 1
    elseif a:scroll  " scroll old entry
      let stack = stack
      let jdx = kdx
    else  " float old entry
      call add(stack, remove(stack, kdx))
      let jdx = len(stack) - 1
    endif
  endif
  call s:add_stack(a:head, stack, jdx)
  if echo  " delay message to ensure it displays
    call timer_start(1, function('s:echo_stack', [a:head, name, jdx, len(stack)]))
  endif
endfunction

" Move across a custom-built buffer stack using the input buffer-changing function
" Note: This is used for man/pydoc in shell.vim and window jumps in vimrc
" Note: 1 (0) goes backward (forward) in history, else goes to a default next buffer
function! iter#next_stack(func, head, ...) abort
  let bnr = bufnr()  " current buffer
  let scroll = a:0 && !type(a:1)
  let stack = get(g:, a:head . '_stack', [])
  let idx = get(g:, a:head . '_loc', -1)
  if scroll  " 'next'/'previous' e.g. iter#next_stack(..., 1)
    let jdx = idx + a:1  " arbitrary offset
    let kdx = a:1 > 0 ? idx + 1 : a:1 < 0 ? idx - 1 : idx  " error condition
    if kdx < 0 || kdx >= len(stack)
      let direc = a:1 < 0 ? 'start' : 'end'
      echohl WarningMsg
      echom 'Error: At ' . direc . " of '" . a:head . "' stack"
      echohl None | return
    endif
    let jdx = min([max([jdx, 0]), len(stack) - 1])
    let args = [stack[jdx]]
  elseif a:0  " 'default' e.g. iter#next_stack(..., '')
    let jdx = len(stack)
    let args = copy(a:000)
  else  " 'user-input' e.g. iter#next_stack(...)
    let jdx = len(stack)
    let args = []
  endif
  call call(a:func, args)  " echo after jumping
  if bnr != bufnr()
    call iter#push_stack(a:head, scroll, jdx, 1)
  endif
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
function! iter#next_match(reverse) abort
  let forward = get(g:, 'indexed_search_n_always_searches_forward', 0)  " default
  if forward && !v:searchforward
    let map = a:reverse ? 'n' : 'N'
  else
    let map = a:reverse ? 'N' : 'n'
  endif
  let b:prevpos = getcurpos()
  if !empty(@/)
    call feedkeys("\<Cmd>keepjumps normal! " . map . "zv\<CR>", 'n')
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
function! iter#next_scheme(reverse) abort
  " Get list of color schemes
  let step = a:reverse ? 1 : -1
  if !exists('g:all_colorschemes')
    let g:all_colorschemes = getcompletion('', 'color')
  endif
  let active_colorscheme = get(g:, 'colors_name', 'default')
  let idx = index(g:all_colorschemes, active_colorscheme)
  let idx = step + (idx < 0 ? -step : idx)   " if idx < 0, set to 0 by default
  " Jump to next color scheme circularly
  if idx < 0
   let idx += len(g:all_colorschemes)
  elseif idx >= len(g:all_colorschemes)
    let idx -= len(g:all_colorschemes)
  endif
  let scheme = g:all_colorschemes[idx]
  echom 'Colorscheme: ' . scheme
  exe 'colorscheme ' . scheme
  let g:colors_name = scheme
  doautocmd BufEnter
endfunction

" Insert complete menu items and scroll complete or preview windows (whichever open).
" Note: Used 'verb function! lsp#scroll' to figure out how to detect preview windows
" (also verified lsp#scroll l:window.find does not return popup completion windows)
function! s:scroll_default(scroll) abort
  let max = winheight(0)
  let nr = abs(type(a:scroll) == 5 ? float2nr(a:scroll * max) : a:scroll)
  let rv = a:scroll > 0 ? 0 : 1  " forward or reverse scroll
  let cmd = "\<Cmd>call scrollwrapped#scroll(" . nr . ', ' . rv . ")\<CR>"
  return mode() =~# '^[iIR]' ? '' : cmd  " only allowed in normal mode
endfunction
function! s:scroll_preview(info, scroll) abort
  let max = a:info['height']
  let nr = type(a:scroll) == 5 ? float2nr(a:scroll * max) : a:scroll
  let nr = a:scroll > 0 ? max([nr, 1]) : min([nr, -1])
  let cmd = lsp#scroll(nr)
  return cmd
endfunction
function! s:scroll_popup(info, scroll) abort
  let max = a:info['height']
  let nr = type(a:scroll) == 5 ? float2nr(a:scroll * max) : a:scroll
  let nr = a:scroll > 0 ? max([nr, 1]) : min([nr, -1])
  if type(a:scroll) == 5 && b:scroll_state != 0   " disable circular scroll
    let nr = max([0 - b:scroll_state + 1, nr])
    let nr = min([max - b:scroll_state, nr])
  endif
  let b:scroll_state += nr + (max + 1) * (1 + abs(nr) / (max + 1))
  let b:scroll_state %= max + 1  " only works with positive integers
  return repeat(nr > 0 ? "\<C-n>" : "\<C-p>", abs(nr))
endfunction

" Scroll complete menu or preview popup windows
" Note: This prevents vim's baked-in circular complete menu scrolling.
" Reset the scroll count (for <expr> maps)
function! iter#scroll_reset() abort
  let b:scroll_state = 0
  return ''
endfunction
" Scroll and update the count
function! iter#scroll_count(scroll) abort
  let complete_info = pum_getpos()  " automatically returns empty if not present
  let l:methods = vital#lsp#import('VS.Vim.Window')  " scope is necessary
  let preview_ids = l:methods.find({id -> l:methods.is_floating(id)})
  let preview_info = empty(preview_ids) ? {} : l:methods.info(preview_ids[0])
  if !empty(complete_info)
    return s:scroll_popup(complete_info, a:scroll)
  elseif !empty(preview_info)
    return s:scroll_preview(preview_info, a:scroll)
  else
    return s:scroll_default(a:scroll)
  endif
endfunction

" Update the jumplist
" Note: This prevents resetting when navigating backwards and forwards through
" jumplist or when navigating within paragraph of most recently set jump
function! iter#update_jumps() abort
  let [line1, line2] = [line("'{"), line("'}")]
  let [jlist, jloc] = getjumplist()
  let pline = line("''")  " line of previous jump
  let cline = pline
  if !empty(jlist)
    let opts = get(jlist, jloc, jlist[-1])
    let cline = opts['lnum']
  endif
  if line1 > cline || line2 < cline
    if line1 > pline || line2 < pline
      call feedkeys("m'", 'n')
    endif
  endif
endfunction
