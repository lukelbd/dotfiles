"-----------------------------------------------------------------------------"
" Utilities for navigating buffer stacks
"-----------------------------------------------------------------------------"
" Helper functions the custom-built buffer stack utilities
" Warning: Below returns name index optionally filtered to the last nmax entries
" of the stack. Note e.g. [1, 2, 3][-5:] is empty list, careful with this.
function! s:add_stack(head, stack, idx) abort
  if empty(a:stack)  " initial value
    let jdx = -1
  else  " restrict values
    let jdx = min([max([a:idx, 0]), len(a:stack) - 1])
  endif
  let g:[a:head . '_stack'] = a:stack
  let g:[a:head . '_loc'] = jdx
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
  let kdx = kdx == -1 ? -1 : jdx + kdx
  return [stack, idx, name, kdx]
endfunction

" General bulk stack operations
" Note: Use e.g. ClearRecent ShowRecent commands in vimrc with these. All other
" functions are for autocommands or normal mode mappings
function! stack#clear_stack(head) abort
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
function! stack#show_stack(head) abort
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
function! stack#pop_stack(head, ...) abort
  let buf = a:0 ? a:1 : ''
  let [stack, idx, name, kdx] = s:query_stack(a:head, buf, 0)
  if kdx == -1 | return | endif  " remove current item, generally
  call remove(stack, kdx)
  let idx = idx > kdx ? idx - 1 : idx  " if idx == jdx float to next entry
  call s:add_stack(a:head, stack, idx)
endfunction
function! stack#push_stack(head, scroll, ...) abort  " update location and possibly append
  let nmax = a:scroll ? 0 : 5  " number to search
  let [stack, idx, name, kdx] = s:query_stack(a:head, bufnr(), nmax)
  if empty(name) | return | endif
  let jdx = a:0 && a:1 >= 0 ? a:1 : len(stack)
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
  if a:0 > 1 && a:2  " delay message to ensure it displays
    call timer_start(10, function('s:echo_stack', [a:head, name, jdx, len(stack)]))
  endif
endfunction

" Move across a custom-built buffer stack using the input buffer-changing function
" Note: This is used for man/pydoc in shell.vim and window jumps in vimrc
" Note: 1 (0) goes backward (forward) in history, else goes to a default next buffer
function! stack#jump_stack(func, head, ...) abort
  let bnr = bufnr()  " current buffer
  let scroll = a:0 && !type(a:1)
  let stack = get(g:, a:head . '_stack', [])
  let idx = get(g:, a:head . '_loc', -1)
  if scroll  " 'next'/'previous' e.g. stack#jump_stack(..., 1)
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
  elseif a:0  " 'default' e.g. stack#jump_stack(..., '')
    let jdx = len(stack)
    let args = copy(a:000)
  else  " 'user-input' e.g. stack#jump_stack(...)
    let jdx = len(stack)
    let args = []
  endif
  call call(a:func, args)  " echo after jumping
  if bnr != bufnr()
    call stack#push_stack(a:head, scroll, jdx, 1)
  endif
endfunction

" Reset recent files
" Note: This only triggers after spending time on window instead of e.g. browsing
" across tabs with maps, similar to jumplist. Then can access jumps in each window.
function! stack#reset_recent() abort  " non-scrolling window change floats 'recent' to top
  for bnr in tabpagebuflist()  " tab page buffers
    call setbufvar(bnr, 'recent_scroll', 0)
  endfor
endfunction
function! stack#scroll_recent(...) abort  " scrolling window change preserves list order
  let bnr = bufnr()
  let scroll = a:0 ? a:1 : v:count1
  call stack#update_recent()  " sync location, possibly float if starting scroll
  call stack#jump_stack(function('file#open_drop', [1]), 'recent', scroll)  " quiet flag
  if bnr != bufnr() | call stack#update_recent(1, 1) | endif  " apply b:recent_scroll
endfunction
function! stack#update_recent(...) abort  " set current buffer
  let skip = index(g:tags_skip_filetypes, &filetype)
  let scroll = a:0 ? a:1 : get(b:, 'recent_scroll', 0)
  let echo = a:0 > 1 ? a:2 : 0
  let b:recent_name = expand('%:p')  " apply name
  let b:recent_scroll = scroll
  if skip != -1 || line('$') <= 1 || empty(&filetype)
    if len(tabpagebuflist()) > 1 | return | endif
  endif
  call stack#push_stack('recent', scroll, -1, echo)  " possibly update stack
endfunction
