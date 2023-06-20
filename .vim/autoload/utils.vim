"-----------------------------------------------------------------------------"
" Internal utilities
"-----------------------------------------------------------------------------"
" Convert input count to register
" Note: This disables e.g. 2dd for 2 lines but use e.g. d2j or other motions instead
function! utils#apply_register(map) abort
  if v:count
    return '"' . v:count
  endif
  let char = nr2char(getchar())
  if char ==# "'"  " manual register selection
    return '"'
  elseif char ==# '"'  " peekaboo register selection
    return '""'
  elseif a:map ==# "'"
    return '"_' . char
  elseif a:map ==# '"'
    return '"*' . char
  else
    return ''
  endif
endfunction
function! utils#count_register(cmd) abort
  if a:cmd =~# 'q\|@'
    let char = b:recording && a:cmd ==# 'q' ? '' : nr2char(106 + v:count1)
  elseif a:cmd =~# '`\|m'
    let char = nr2char(97 + v:count)
  elseif a:cmd =~# 'p\|m'
  elseif a:cmd =~# "'"  " register pasting
    let char = nr2char(97 + v:count)
  elseif a:cmd =~# '"'  " macro pasting
    let char = nr2char(107 + v:count)
  endif
endfunction

" Implement input behavior
" Note: This is used for both grep and file completion
function! utils#complete_list(...)
  let [init, fhandle, default] = s:complete_params
  if !init  " kludge for default behavior
    return call(fhandle, a:000)
  else
    let s:complete_params[0] = 0
    try
      let char = nr2char(getchar())
    catch  " user presses Ctrl-C
      call feedkeys("\<CR>", 't')
      return ['']
    endtry
    if char ==# "\<Tab>"
      return [default]
    elseif char ==# "\<CR>"
      call feedkeys("\<CR>", 't')
      return [default]
    elseif char =~# '\p'
      return [char]
    else
      call feedkeys("\<CR>", 't')
      return ['']
    endif
  endif
endfunction
function! utils#complete_input(prompt, default, func) abort
  let message = a:prompt . ' (' . a:default . '): '
  let s:complete_params = [1, a:func, a:default]
  call feedkeys("\<Tab>", 't')
  return input(message, '', 'customlist,utils#complete_list')
endfunction

" Null input() completion function to prevent unexpected insertion of literal tabs
" Note: This is used in other autoload functions
function! utils#null_list(...) abort
  return []
endfunction
" Null operator motion function
function! utils#null_operator(...) range abort
  return ''
endfunction
" For <expr> mapping accepting motion
function! utils#null_operator_expr(...) abort
  return utils#motion_func('utils#null_operator', a:000)
endfunction

" Call function over the visual line range or the user motion line range
" Note: Use this approach rather than adding line range as physical arguments and
" calling with call call(func, firstline, lastline, ...) so that funcs can still be
" invoked manually with V<motion>:call func(). This is more standard paradigm.
function! utils#motion_func(funcname, args) abort
  let g:operator_func_signature = a:funcname . '(' . string(a:args)[1:-2] . ')'
  if mode() =~# '^\(v\|V\|\)$'
    return ":\<C-u>'<,'>call utils#operator_func('')\<CR>"
  elseif mode() ==# 'n'
    set operatorfunc=utils#operator_func
    return 'g@'  " uses the input line range
  else
    echoerr 'E999: Illegal mode: ' . string(mode())
    return ''
  endif
endfunction

" Execute the function name and call signature passed to utils#motion_func. This
" is generally invoked inside an <expr> mapping.
" Note: Only motions can cause backwards firstline to lastline order. Manual
" calls to the function will have sorted lines.
function! utils#operator_func(type) range abort
  if empty(a:type)  " default behavior
      let firstline = a:firstline
      let lastline  = a:lastline
  elseif a:type =~? 'line\|char\|block'  " builtin g@ type strings
      let firstline = line("'[")
      let lastline  = line("']")
  else
    echoerr 'E474: Invalid argument: ' . string(a:type)
    return ''
  endif
  if firstline > lastline
    let [firstline, lastline] = [lastline, firstline]
  endif
  exe firstline . ',' . lastline . 'call ' . g:operator_func_signature
  return ''
endfunction

" Run command with v:count register specification
" Note: Powers 'c', 'y', 'd', and 'q' (mapped to 'Q')
function! utils#register_func(macro, count) abort
  let base = a:macro ? 96 : 106  " default uses a-j for text k-t for macros
  if a:count
    let prefix = nr2char(base + a:count)
  else
    let prefix = ''
  endif
  return "\<Esc>" . prefix
endfunction

" Reverse the selected lines
" Note: Adaptation of hard-to-remember :g command shortcut.
" https://vim.fandom.com/wiki/Reverse_order_of_lines
function! utils#reverse_lines() range abort
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  let num = empty(range) ? 0 : a:firstline - 1
  exec 'silent ' . range . 'g/^/m' . num
endfunction

" Switch to next or previous colorschemes and print the name
" This is used when deciding on macvim colorschemes
function! utils#wrap_colorschemes(reverse) abort
  " Get colorscheme list
  let step = a:reverse ? 1 : -1
  if !exists('g:all_colorschemes')
    let g:all_colorschemes = getcompletion('', 'color')
  endif
  let active_colorscheme = get(g:, 'colors_name', 'default')
  let idx = index(g:all_colorschemes, active_colorscheme)
  let idx = step + (idx < 0 ? -step : idx)   " if idx < 0, set to 0 by default
  " Jump to next
  if idx < 0
    let idx += len(g:all_colorschemes)
  elseif idx >= len(g:all_colorschemes)
    let idx -= len(g:all_colorschemes)
  endif
  let colorscheme = g:all_colorschemes[idx]
  echom 'Colorscheme: ' . colorscheme
  exe 'colorscheme ' . colorscheme
  silent redraw
  let g:colors_name = colorscheme  " many plugins do this, but this is a backstop
endfunction

" Cyclic next error in location list
" Adapted from: https://vi.stackexchange.com/a/14359
" Note: Adding the '+ 1 - reverse' term empirically fixes vim 'vint' issue where
" cursor is on final error in the file but ]x does not cycle to the next one.
function! utils#wrap_cyclic(count, list, ...) abort
  " Build up list of loc dictionaries
  let func = 'get' . a:list . 'list'
  let reverse = a:0 && a:1
  let params = a:list ==# 'loc' ? [0] : []
  let cmd = a:list ==# 'loc' ? 'll' : 'cc'
  let items = call(func, params)
  call filter(items, "v:val.bufnr == bufnr('%')")
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
  return utils#wrap_cyclic(a:count, a:list, reverse)
endfunction
