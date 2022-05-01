"-----------------------------------------------------------------------------"
" General utilities
"-----------------------------------------------------------------------------"
" Absolute path
function! utils#abs_path(...) abort
  let path = a:0 ? a:1 : @%
  echom 'Path: ' . fnamemodify(path, ':p')
endfunction

" Comment character
function! utils#comment_char() abort
  let string = substitute(&commentstring, '%s.*', '', '')  " leading comment indicator
  let string = substitute(string, '\s\+', '', 'g')  " ignore spaces
  return escape(string, '[]\.*$~')  " escape magic characters
endfunction

" Better grep, with limited regex translation
function! utils#grep_pattern(regex) abort 
  let regex = a:regex
  let regex = substitute(regex, '\(\\<\|\\>\)', '\\b', 'g')
  let regex = substitute(regex, '\\s', "[ \t]",  'g')
  let regex = substitute(regex, '\\S', "[^ \t]", 'g')
  let result = split(system("grep '" . regex . "' " . shellescape(@%) . ' 2>/dev/null'), "\n")
  echo join(result, "\n")
  return result
endfunction

" List the active buffer names
function! utils#open_bufs() abort
  let result = {}
  for nr in range(0, bufnr('$'))
    if buflisted(nr) | let result[nr] = bufname(nr) | endif
  endfor
  echo join(values(map(result, "v:key . ': ' . v:val")), "\n")
  return result
endfunction

" Reverse the selected lines
function! utils#reverse_lines() range abort
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  let num = empty(range) ? 0 : a:firstline - 1
  exec 'silent ' . range . 'g/^/m' . num
endfunction

" Null input() completion function to prevent unexpected insertion of literal tabs
function! utils#null_list(...) abort
  return []
endfunction

" Null operator motion function to gobble up the motion and prevent unexpected behavior
function! utils#null_operator(...) range abort
  return ''
endfunction
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

" Switch to next or previous colorschemes and print the name
" This is used when deciding on macvim colorschemes
function! utils#iter_colorschemes(reverse) abort
  let step = a:reverse ? 1 : -1
  if !exists('g:all_colorschemes')
    let g:all_colorschemes = getcompletion('', 'color')
  endif
  let active_colorscheme = get(g:, 'colors_name', 'default')
  let idx = index(g:all_colorschemes, active_colorscheme)
  let idx = step + (idx < 0 ? -step : idx)   " if idx < 0, set to 0 by default
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

" Helper function for comparing values
" Copied from: https://vi.stackexchange.com/a/14359
function! s:compare(a, b)
  for i in range(len(a:a))
    if a:a[i] < a:b[i]
      return -1
    elseif a:a[i] > a:b[i]
      return 1
    endif
  endfor
  return 0
endfunction

" Cyclic next error in location list
" Copied from: https://vi.stackexchange.com/a/14359
function! utils#iter_cyclic(count, list, ...) abort
  " Initial stuff
  let reverse = a:0 && a:1
  let func = 'get' . a:list . 'list'
  let params = a:list ==# 'loc' ? [0] : []
  let cmd = a:list ==# 'loc' ? 'll' : 'cc'
  let items = call(func, params)
  if empty(items)
    return 'echoerr ' . string('E42: No Errors')  " string() adds quotes
  endif
  " Build up list of loc dictionaries
  call map(items, 'extend(v:val, {"idx": v:key + 1})')
  if reverse
    call reverse(items)
  endif
  let [bufnr, compare] = [bufnr('%'), reverse ? 1 : -1]
  let context = [line('.'), col('.')]
  if v:version > 800 || has('patch-8.0.1112')
    let current = call(func, extend(copy(params), [{'idx':1}])).idx
  else
    redir => capture | execute cmd | redir END
    let current = str2nr(matchstr(capture, '(\zs\d\+\ze of \d\+)'))
  endif
  call add(context, current)
  " Jump to next loc circularly
  call filter(items, 'v:val.bufnr == bufnr')
  let nbuffer = len(get(items, 0, {}))
  call filter(items, 's:compare(context, [v:val.lnum, v:val.col, v:val.idx]) == compare')
  let inext = get(get(items, 0, {}), 'idx', 'E553: No more items')
  if type(inext) == type(0)
    return cmd . inext
  elseif nbuffer != 0
    exe '' . (reverse ? line('$') : 0)
    return utils#iter_cyclic(a:count, a:list, reverse)
  else
    return 'echoerr ' . string(inext)  " string() adds quotes
  endif
endfunction
