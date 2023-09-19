"-----------------------------------------------------------------------------"
" Menu utilities
"-----------------------------------------------------------------------------"
" Insert complete menu items and scroll complete or preview windows (whichever is open).
" Note: Used 'verb function! lsp#scroll' to figure out how to detect
" preview windows for a reference scaling (also verified that l:window.find
" and therefore lsp#scroll do not return popup completion windows).
function! s:scroll_default(scroll) abort
  let nr = abs(type(a:scroll) == 5 ? float2nr(a:scroll * winheight(0)) : a:scroll)
  let rev = a:scroll > 0 ? 0 : 1  " forward or reverse scroll
  let cmd = "\<Cmd>call scrollwrapped#scroll(" . nr . ', ' . rev . ")\<CR>"
  return mode() =~# '^[iIR]' ? '' : cmd  " only allowed in normal mode
endfunction
function! s:scroll_preview(info, scroll) abort
  let nr = type(a:scroll) == 5 ? float2nr(a:scroll * a:info['height']) : a:scroll
  let nr = a:scroll > 0 ? max([nr, 1]) : min([nr, -1])
  let cmd = lsp#scroll(nr)
  return cmd
endfunction
function! s:scroll_popup(info, scroll) abort
  let nr = type(a:scroll) == 5 ? float2nr(a:scroll * a:info['height']) : a:scroll
  let nr = a:scroll > 0 ? max([nr, 1]) : min([nr, -1])
  let nr = max([0 - b:scroll_state, nr])
  let nr = min([a:info['size'] - b:scroll_state, nr])
  let b:scroll_state += nr  " complete menu offset
  return repeat(nr > 0 ? "\<C-n>" : "\<C-p>", abs(nr))
endfunction

" Scroll complete mneu or preview popup windows
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

" Switch to next or previous colorschemes and print the name
" Note: Have to trigger 'BufEnter' so status line updates.
function! iter#jump_colorschemes(reverse) abort
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
  let colorscheme = g:all_colorschemes[idx]
  echom 'Colorscheme: ' . colorscheme
  exe 'colorscheme ' . colorscheme
  let g:colors_name = colorscheme  " convention: https://stackoverflow.com/a/2419692/4970632
  doautocmd BufEnter
endfunction

" Cyclic next error in location list
" Adapted from: https://vi.stackexchange.com/a/14359
" Note: Adding the '+ 1 - reverse' term empirically fixes vim 'vint' issue where
" cursor is on final error in the file but ]x does not cycle to the next one.
function! iter#jump_cyclic(count, list, ...) abort
  " Get list of loc dictionaries
  let func = 'get' . a:list . 'list'
  let reverse = a:0 && a:1
  let params = a:list ==# 'loc' ? [0] : []
  let cmd = a:list ==# 'loc' ? 'll' : 'cc'
  let items = call(func, params)
  if empty(items) | return "echoerr 'E42: No errors'" | endif
  call map(items, "extend(v:val, {'idx': v:key + 1})")
  if reverse | call reverse(items) | endif
  " Jump to next loc circularly
  let [lnum, cnum] = [line('.'), col('.')]
  let [cmps, oper] = [[], reverse ? '<' : '>']
  call add(cmps, 'v:val.lnum ' . oper . ' lnum')
  call add(cmps, 'v:val.col ' . oper . ' cnum + 1 - reverse')
  call filter(items, join(cmps, ' || '))
  let inext = get(get(items, 0, {}), 'idx', '')
  if type(inext) == type(0)
    return cmd . inext
  endif
  exe reverse ? line('$') : 0
  return iter#jump_cyclic(a:count, a:list, reverse)
endfunction
