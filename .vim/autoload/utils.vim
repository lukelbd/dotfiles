"-----------------------------------------------------------------------------"
" General utilities
"-----------------------------------------------------------------------------"
" Clear writable registers. On some vim versions [] fails (is ideal,
" because removes from :registers), but '' will at least empty them out.
" See: https://stackoverflow.com/questions/19430200/how-to-clear-vim-registers-effectively
function! utils#clear_regs()
  for i in range(34, 122)
    silent! call setreg(nr2char(i), '')
    silent! call setreg(nr2char(i), [])
  endfor
endfunction

" Close buffers that do not appear in windows
" See: https://stackoverflow.com/a/7321131/4970632
function! utils#close_bufs()
  let nums = []
  for t in range(1, tabpagenr('$'))
    call extend(nums, tabpagebuflist(t))
  endfor
  let names = []
  for b in range(1, bufnr('$'))
    if bufexists(b) && !getbufvar(b, '&mod') && index(nums, b) == -1
      call add(names, bufname(b))
      silent exe 'bwipeout ' b
    endif
  endfor
  if !empty(names)
    echom 'Closed invisible buffer(s): ' . join(names, ', ')
  endif
endfunction

" Search term for Rg and Ag
" Todo: Learn other options for rg and ag, write bashrc helpers
" Note: Rg is faster so use by default: https://unix.stackexchange.com/a/524094/112647
function! utils#grep_command(cmd) abort
  let prompt = "Search pattern (default '" . @/ . "'): "
  let search = input(prompt, '', 'customlist,utils#null_list')
  let search = empty(search) ? @/ : search
  let path = expand('%:h')
  exe a:cmd . ' ' . search . ' ' . path
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

" Show the active buffer names
function! utils#show_bufs() abort
  let result = {}
  for nr in range(0, bufnr('$'))
    if buflisted(nr) | let result[nr] = bufname(nr) | endif
  endfor
  echo join(values(map(result, "v:key . ': ' . v:val")), "\n")
  return result
endfunction

" Show the absolute path
function! utils#show_path(...) abort
  let path = a:0 ? a:1 : @%
  echom 'Path: ' . fnamemodify(path, ':p')
endfunction

" Reverse the selected lines
function! utils#reverse_lines() range abort
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  let num = empty(range) ? 0 : a:firstline - 1
  exec 'silent ' . range . 'g/^/m' . num
endfunction

" Helper function for comparing values
" Copied from: https://vi.stackexchange.com/a/14359
function! s:compare(a, b) abort
  for i in range(len(a:a))
    if a:a[i] < a:b[i]
      return -1
    elseif a:a[i] > a:b[i]
      return 1
    endif
  endfor
  return 0
endfunction

" Switch to next or previous colorschemes and print the name
" This is used when deciding on macvim colorschemes
function! utils#wrap_colorschemes(reverse) abort
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

" Cyclic next error in location list
" Copied from: https://vi.stackexchange.com/a/14359
function! utils#wrap_cyclic(count, list, ...) abort
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
    return utils#wrap_cyclic(a:count, a:list, reverse)
  else
    return 'echoerr ' . string(inext)  " string() adds quotes
  endif
endfunction
