"-----------------------------------------------------------------------------"
" Utilities for navigating stacks of locations
"-----------------------------------------------------------------------------"
" Helper functions
" WARNING: Below returns name index optionally filtered to the last nmax entries
" of the stack. Note e.g. [1, 2, 3][-5:] is empty list, careful with this.
function! stack#get_loc(head, ...) abort
  let [stack, idx] = s:get_stack(a:head)
  return [idx, len(stack)]  " return length
endfunction
function! stack#get_name(head, ...) abort
  let [key, iarg] = [a:head . '_name', a:0 ? a:1 : '']  " set by input function
  return a:0 && type(a:1) ? iarg : getbufvar(iarg, key, get(g:, key, ''))
endfunction
function! stack#get_item(head, ...) abort
  let [stack, idx] = s:get_stack(a:head)
  return get(stack, a:0 ? a:1 : idx, '')
endfunction
function! s:get_stack(head) abort
  let stack = get(g:, a:head . '_stack', [])
  return [stack, get(g:, a:head . '_loc', -1)]
endfunction
function! s:set_stack(head, stack, idx) abort
  let g:[a:head . '_stack'] = a:stack  " note if empty initial index is -1
  let g:[a:head . '_loc'] = min([max([a:idx, 0]), len(a:stack) - 1])
endfunction
function! s:get_index(head, ...) abort  " remove in future
  let [stack, idx] = s:get_stack(a:head)
  let nmax = a:0 > 1 ? a:2 < 0 ? len(stack) : a:2 : 0
  let name = stack#get_name(a:head, a:0 ? a:1 : '')  " e.g. g:tag_name
  let istack = nmax ? reverse(copy(stack))[:nmax - 1] : []
  let nstack = max([0, len(stack) - nmax])  " remaining stack
  if empty(name)  " invalid input name
    let jdx = -1
  elseif !empty(istack) && type(istack[0]) > type(name)  " e.g. tag name
    let jdx = indexof(istack, 'v:val[-1] ==# name')
  else  " matching list
    let jdx = index(istack, name)
  endif
  let kdx = jdx < 0 ? -1 : len(istack) + nstack - jdx - 1
  return [stack, idx, name, kdx]
endfunction

" Stack printing operations
" NOTE: Use this with Show/Clear vimrc commands. Print the entire table
" or print current position in the stack with auto-formatted label.
function! stack#print_item(head, ...) abort
  let [stack, idx] = s:get_stack(a:head)
  let item = a:0 ? a:1 : stack#get_item(a:head)
  let label = s:get_label(item)
  let head = toupper(a:head[0]) . tolower(a:head[1:])
  let index = (len(stack) - idx) . '/' . len(stack)
  redraw | echo head . ': ' . label . ' (' . index . ')'
endfunction
function! stack#print_stack(head) abort
  let [stack, idx] = s:get_stack(a:head)
  let digits = len(string(len(stack)))
  redraw | echo "Current '" . a:head . "' stack:"
  for jdx in range(len(stack))  " iterate entries
    let pad = repeat(' ', digits - len(string(jdx)) + 1)
    let flag = idx == jdx ? '>' : ' '
    let label = s:get_label(stack[jdx])
    let index = len(stack) - jdx
    echo flag . pad . index . ': ' . label
  endfor
endfunction
function! s:get_label(arg) abort
  if type(a:arg) == 3
    let parts = copy(a:arg)
    call map(parts, {_, val -> type(val) == 1 && filereadable(val) ? RelativePath(val, 1) : val})
    call map(parts, {_, val -> type(val) == 3 ? join(val, ':') : val})
    let label = join(parts, ':')
  elseif bufexists(a:arg)  " tab page then path
    let winid = get(win_findbuf(bufnr(a:arg)), 0, 0)
    let tabnr = get(win_id2tabwin(winid), 0, 0)
    let tabnr = tabnr > 0 ? tabnr : '*'
    let label = RelativePath(a:arg, 1) . ' (' . tabnr . ')'
  elseif a:arg =~# '^[A-Z]$'  " mark label
    let label = a:arg
  else  " generic label
    let label = string(a:arg)
  endif | return label
endfunction

" Update the requested buffer stack
" NOTE: Use this with man/pydoc in shell.vim and window jumps in vimrc. Updates
" the stack by scrolling, adding entries, or floating entries to the top.
function! stack#clear_stack(head) abort
  try
    call remove(g:, a:head . '_stack')
    call remove(g:, a:head . '_loc')
    redraw | echom 'Cleared ' . string(a:head) . ' location stack'
  catch
    let msg = 'Error: Location stack ' . string(a:head) . ' does not exist'
    redraw | echohl WarningMsg | echom msg | echohl None
  endtry
endfunction
function! stack#update_stack(head, ...) abort
  let scroll = a:0 > 0 && !empty(a:1)
  let index = a:0 > 1 ? a:2 : -1  " scroll index
  let level = a:0 > 2 ? a:3 : 0  " verbose mode
  let nmax = scroll ? -1 : 5
  let [stack, idx, name, kdx] = s:get_index(a:head, bufnr(), nmax)
  if empty(name) | return | endif
  if index >= 0 && index < len(stack)  " scroll to input index
    let jdx = index
  elseif scroll && kdx >= 0  " scroll to inferred entry
    let jdx = kdx
  elseif kdx == -1  " add missing entry
    call add(stack, name) | let jdx = len(stack) - 1
  else  " float existing entry
    call add(stack, remove(stack, kdx)) | let jdx = len(stack) - 1
  endif
  let updated = jdx != idx || name != get(stack, idx, '')
  call s:set_stack(a:head, stack, jdx)
  if updated && v:vim_did_enter && level > 0 || level > 1
    call stack#print_item(a:head, name)
  endif
endfunction

" Move across a custom-built buffer stack using the input buffer-changing function
" NOTE: Here 1 (0) goes backward (forward) in history, else goes to a default next
" buffer. Functions should return non-zero on failure (either manually or through
" vim error triggered on function with abort-label, which returns -1 by default).
function! stack#pop_stack(head, ...) abort
  let [cnt, nmax] = [0, 100]
  let name = a:0 > 0 ? a:1 : stack#get_name(a:head)
  let level = a:0 > 1 ? a:2 : 0  " verbose level
  if type(name) == 1 && name =~# '^\d\+$'
    let name = str2nr(name)  " i.e. buffer number passed to command
  elseif type(name) == 1 && filereadable(resolve(expand(name)))
    let name = fnamemodify(resolve(expand(name)), ':p')  " e.g. ~/path/to/file
  endif
  while cnt < nmax
    let [stack, idx, name, kdx] = s:get_index(a:head, name, -1)
    if kdx == -1 | break | endif  " remove current item, generally
    let cnt += 1 | call remove(stack, kdx)
    let idx = idx > kdx ? idx - 1 : idx  " if idx == jdx float to next entry
    call s:set_stack(a:head, stack, idx)
  endwhile
  if !level | return | endif
  if cnt
    let msg = cnt > 1 ? 'entries' : 'entry'
    redraw | echom 'Popped ' . cnt . ' matching ' . string(a:head) . ' ' . msg
  else
    let msg = 'Warning: Failed to pop name ' . string(name) . ' from ' . a:head . ' stack'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
endfunction
function! stack#push_stack(head, func, ...) abort
  let level = a:0 > 1 ? a:2 : 1
  let iarg = a:0 > 0 ? a:1 : []
  if type(iarg)  " fzf-sink, user-input, or default e.g. push_stack(...[, ''])
    let index = -1
    let args = iarg
  else  " next or previous e.g. stack#push_stack(..., [1|-1])
    let [stack, idx] = s:get_stack(a:head)
    let index = idx + iarg  " arbitrary offset
    let delta = iarg > 0 ? 1 : iarg < 0 ? -1 : 0  " error condition
    if idx + delta < 0 || idx + delta >= len(stack)
      let direc = iarg < 0 ? 'bottom' : 'top'
      let msg = 'Error: At ' . direc . ' of ' . string(a:head) . ' stack'
      redraw | echohl WarningMsg | echom msg | echohl None | return 1
    endif
    let index = min([max([index, 0]), len(stack) - 1])
    let args = stack[index]  " function arguments
  endif
  if !empty(a:func)
    if !level  " preserve function message
      let result = call(a:func, type(args) > 1 ? args : [args])
    else  " show stack message instead
      silent let result = call(a:func, type(args) > 1 ? args : [args])
    endif
    if !empty(result) | return result | endif
  endif
  let [stack, idx] = s:get_stack(a:head)  " in case triggered
  call stack#update_stack(a:head, !type(iarg), index, level)
endfunction
