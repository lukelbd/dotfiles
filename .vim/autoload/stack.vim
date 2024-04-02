"-----------------------------------------------------------------------------"
" Utilities for navigating stacks of locations
"-----------------------------------------------------------------------------"
" Helper functions
" Warning: Below returns name index optionally filtered to the last nmax entries
" of the stack. Note e.g. [1, 2, 3][-5:] is empty list, careful with this.
function! s:set_stack(head, stack, idx) abort
  let index = min([max([a:idx, 0]), len(a:stack) - 1])
  let index = empty(a:stack) ? -1 : index  " initial value -1
  let g:[a:head . '_stack'] = a:stack
  let g:[a:head . '_loc'] = index
endfunction
function! s:get_stack(head, ...) abort  " remove in future
  let stack = a:head ==# 'tab' ? get(g:, 'recent_stack', []) : []
  let idx = a:head ==# 'tab' ? get(g:, 'recent_loc', -1) : -1
  let stack = get(g:, a:head . '_stack', stack)
  let idx = get(g:, a:head . '_loc', idx)
  let key = a:head . '_name'  " set by input function
  let name = !a:0 ? '' : type(a:1) ? a:1 : getbufvar(a:1, key, get(g:, key, ''))
  let nmax = min([a:0 < 2 ? 0 : a:2 >= 0 ? a:2 : len(stack), len(stack)])
  let part = nmax ? reverse(copy(stack))[:nmax - 1] : []
  let jdx = empty(name) ? -1 : index(part, name)
  let kdx = jdx < 0 ? -1 : (len(stack) - nmax) + (len(part) - jdx - 1)
  return [stack, idx, name, kdx]
endfunction

" Stack printing operations
" Note: Use e.g. ShowTabs ClearTabs commands in vimrc with these. All other
" functions are for autocommands or normal mode mappings
function! stack#show_stack(head) abort
  let [stack, idx; rest] = s:get_stack(a:head)
  let digits = len(string(len(stack)))
  redraw | echom "Current '" . a:head . "' stack:"
  for jdx in range(len(stack))
    let pad = idx == jdx ? '> ' : '  '
    let pad .= repeat(' ', digits - len(string(jdx)))
    call stack#show_item(pad . jdx, stack[jdx])
  endfor
endfunction
function! stack#show_item(head, name, ...) abort
  if type(a:name) == 3
    let parts = map(copy(a:name), {_, val -> type(val) == 1 && filereadable(val) ? RelativePath(val) : val})
    let parts = map(parts, {idx, val -> type(val) == 3 ? join(val, ':') : val})
    let label = join(parts, ':')
  elseif bufexists(a:name)  " tab page then path
    let winid = get(win_findbuf(bufnr(a:name)), 0, 0)
    let tabnr = win_id2tabwin(winid)[0]
    let label = RelativePath(a:name) . ' (' . (tabnr ? tabnr : '*') . ')'
  else  " default label
    let label = string(a:name)
  endif
  let head = toupper(a:head[0]) . a:head[1:] . ': '
  let tail = a:0 ? ' (' . (a:1 + 1) . '/' . a:2 . ')' : ''
  exe a:0 ? 'redraw' : '' | echom head . label . tail
endfunction

" Update the requested buffer stack
" Note: This is used for man/pydoc in shell.vim and window jumps in vimrc
function! stack#clear_stack(head) abort
  try
    call remove(g:, a:head . '_stack')
    call remove(g:, a:head . '_loc')
    redraw | echom "Cleared '" . a:head . "' location stack"
  catch
    redraw | echohl WarningMsg
    echom "Error: Location stack '" . a:head . "' does not exist"
    echohl None
  endtry
endfunction
function! stack#update_stack(head, scroll, ...) abort
  let [stack, idx, name, kdx] = s:get_stack(a:head, bufnr(), a:scroll ? -1 : 5)
  let verbose = a:0 > 1 ? a:2 : 0  " verbose mode
  if empty(name) | return | endif
  if a:0 && a:1 >= 0 && a:1 < len(stack)  " scroll to input index
    let jdx = a:1
  elseif a:scroll && kdx >= 0  " scroll to inferred entry
    let jdx = kdx
  elseif kdx == -1  " add missing entry
    call add(stack, name) | let jdx = len(stack) - 1
  else  " float existing entry
    call add(stack, remove(stack, kdx)) | let jdx = len(stack) - 1
  endif
  call s:set_stack(a:head, stack, jdx)
  if verbose && v:vim_did_enter && (verbose > 1 || jdx != idx || name != get(stack, idx, ''))
    call stack#show_item(a:head, name, jdx, len(stack))
  endif
endfunction

" Move across a custom-built buffer stack using the input buffer-changing function
" Note: Here 1 (0) goes backward (forward) in history, else goes to a default next
" buffer. Functions should return non-zero on failure (either manually or through
" vim error triggered on function with abort-label, which returns -1 by default).
function! stack#pop_stack(head, name) abort
  let convert = type(a:name) == 1 && a:name =~# '^\d\+$'
  let [num, nmax, name] = [0, 100, convert ? str2nr(a:name) : a:name]
  while num < nmax
    let [stack, idx, name, kdx] = s:get_stack(a:head, name, -1)
    if kdx == -1 | break | endif  " remove current item, generally
    let num += 1 | call remove(stack, kdx)
    let idx = idx > kdx ? idx - 1 : idx  " if idx == jdx float to next entry
    call s:set_stack(a:head, stack, idx)
  endwhile
endfunction
function! stack#push_stack(head, func, ...) abort
  let [stack, idx; rest] = s:get_stack(a:head)
  let verbose = a:0 > 1 ? a:2 : 1
  if !a:0 || type(a:1)  " fzf-sink, user-input, or default e.g. push_stack(...[, ''])
    let jdx = -1
    let args = !a:0 ? [] : type(a:1) == type([]) ? a:1 : [a:1]
    let scroll = 0
  else  " next or previous e.g. stack#push_stack(..., [1|-1])
    let jdx = idx + a:1  " arbitrary offset
    let kdx = a:1 > 0 ? idx + 1 : a:1 < 0 ? idx - 1 : idx  " error condition
    if kdx < 0 || kdx >= len(stack)
      let direc = a:1 < 0 ? 'bottom' : 'top'
      redraw | echohl WarningMsg
      echom 'Error: At ' . direc . ' of ' . a:head . ' stack'
      echohl None | return
    endif
    let jdx = min([max([jdx, 0]), len(stack) - 1])
    let args = type(stack[jdx]) == 3 ? stack[jdx] : [stack[jdx]]
    let scroll = 1
  endif
  if !empty(a:func)
    if verbose  " ignore message
      silent let status = call(a:func, args)
    else  " preserve message
      let status = call(a:func, args)
    endif
    if status != 0 | return | endif
  endif
  call stack#update_stack(a:head, scroll, jdx, verbose)
endfunction

" Reset recent files
" Note: Recent stack will always be in sync before scrolling, since b:tab_scroll
" is only true after scrolling to a window and before leaving that window (TabLeave).
" Note: This only triggers after spending time on window instead of e.g. browsing
" across tabs with maps, similar to jumplist. Then can access jumps in each window.
function! s:tab_name() abort
  let name = bufname()
  let name = filereadable(name) || isdirectory(name) ? expand('%:p') : name
  let b:tab_name = name  " buffer name or absolute path
endfunction
function! s:tab_scroll(...) abort
  silent call call('file#open_drop', a:000)  " triggers TabLeave and TabEnter
  for bnr in tabpagebuflist() | call setbufvar(bnr, 'tab_scroll', 1) | endfor
  call s:tab_name()  " apply tab_name
endfunction
function! stack#reset_tabs() abort
  for bnr in tabpagebuflist()
    call setbufvar(bnr, 'tab_scroll', 0)
  endfor
endfunction
function! stack#scroll_tabs(...) abort
  let bnr = bufnr()
  let scroll = a:0 ? a:1 : v:count1
  if !get(b:, 'tab_scroll', 0)
    call stack#update_tabs()  " possibly float to top
  endif
  call stack#push_stack('tab', function('s:tab_scroll'), scroll)
endfunction
function! stack#update_tabs(...) abort  " set current buffer
  let skip = index(g:tags_skip_filetypes, &filetype)
  let verbose = a:0 ? a:1 : 0  " disabled by default
  let scroll = get(b:, 'tab_scroll', 0)
  let b:tab_scroll = scroll  " update in case
  call s:tab_name()  " apply tab_name
  if skip != -1 || line('$') <= 1 || empty(&filetype)
    if len(tabpagebuflist()) > 1 | return | endif
  endif
  call stack#update_stack('tab', scroll, -1, verbose)
endfunction
