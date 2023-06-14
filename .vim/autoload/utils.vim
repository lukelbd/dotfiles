"-----------------------------------------------------------------------------"
" General utilities
"-----------------------------------------------------------------------------"
" Compare position indices [lnum, col, idx]
" See: https://vi.stackexchange.com/a/14359
function! s:compare_lists(a, b) abort
  for i in range(len(a:a))
    if a:a[i] < a:b[i]
      return -1
    elseif a:a[i] > a:b[i]
      return 1
    endif
  endfor
  return 0
endfunction

" Grep commands
" Todo: Only use search pattern? https://github.com/junegunn/fzf.vim/issues/346
" Todo: Override sink function with custom s:tab_jump plugin: https://stackoverflow.com/questions/49443373/vim-overwrite-plugin-scoped-function
" Ag ripgrep flags: https://github.com/junegunn/fzf.vim/issues/921#issuecomment-1577879849
" Ag ignore file: https://github.com/ggreer/the_silver_searcher/issues/1097
function! utils#grep_ag(bang, level, depth, ...) abort
  let flags = '--path-to-ignore ~/.ignore --skip-vcs-ignores --hidden'
  let extra = a:depth ? ' --depth ' . (a:depth - 1) : ''
  let args = call('utils#grep_parse', [a:level] + a:000)
  " let opts = a:level > 0 ? {'dir': expand('%:h')} : {}
  " let opts = fzf#vim#with_preview(opts)
  let opts = fzf#vim#with_preview()
  call fzf#vim#ag_raw(flags . ' -- ' . args, opts, a:bang)  " bang uses fullscreen
endfunction
function! utils#grep_rg(bang, level, depth, ...) abort
  let flags = '--no-ignore-vcs --hidden'
  let extra = a:depth ? ' --max-depth ' . a:depth : ''
  let args = call('utils#grep_parse', [a:level] + a:000)
  " let opts = a:level > 0 ? {'dir': expand('%:h')} : {}
  " let opts = fzf#vim#with_preview(opts)
  let opts = fzf#vim#with_preview()
  let cmd = 'rg --column --line-number --no-heading --color=always --smart-case '
  call fzf#vim#grep(cmd . ' ' . flags . extra . ' -- ' . args, opts, a:bang)  " bang uses fullscreen
endfunction

" Parse grep args and translate regex indicators
" Warning: Strange bug seems to cause :Ag and :Rg to only work on individual files
" if more than one file is passed. Otherwise preview window shows 'file is not found'
" error and selecting from menu fails. So always pass extra dummy name.
function! utils#grep_parse(level, search, ...) abort
  let regex = fzf#shellescape(a:search)  " similar to native but handles other shells
  let regex = substitute(regex, '\(\\<\|\\>\)', '\\b', 'g')  " translate word borders
  let regex = substitute(regex, '\(\\c\|\\C\)', '', 'g')  " smartcase imposed by flag
  let regex = substitute(regex, '\\S', "[^ \t]", 'g')  " non-whitespace characters
  let regex = substitute(regex, '\\s', "[ \t]",  'g')  " whitespace characters
  let regex = substitute(regex, '\\[ikf]', '\\w', 'g')  " keyword, identifier, filename
  let regex = substitute(regex, '\\[IKF]', '[a-zA-Z_]', 'g')  " same but no numbers
  let paths = a:000  " list of paths
  if empty(paths)  " default path or directory
    let paths = [a:level > 1 ? @% : a:level > 0 ? expand('%:h') : getcwd()]
  endif
  let cmd = regex  " concatenated paths
  for path in paths  " iterate over all
    let path = substitute(path, '^\~', expand('~'), '')  " see also file.vim
    let path = substitute(path, '^' . getcwd(), '.', '')
    let path = substitute(path, '^' . expand('~'), '~', '')
    let cmd = cmd . ' ' . path  " do not escape paths to permit e.g. glob patterns
  endfor
  return cmd . ' dummy.fzf'  " fix bug described above
endfunction

" Call Rg or Ag grep commands
" Todo: Support
function! utils#grep_pattern(grep, level, depth) abort
  let prompt = toupper(a:grep[0]) . a:grep[1:] . " pattern (default '" . @/ . "'): "
  let search = input(prompt, '', 'customlist,utils#null_list')
  let search = empty(search) ? @/ : search
  let path = expand('%:h')  " command also translates regex
  let func = 'utils#grep_' . tolower(a:grep)
  call call(func, [0, a:level, a:depth, search])
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

" Reverse the selected lines
function! utils#reverse_lines() range abort
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  let num = empty(range) ? 0 : a:firstline - 1
  exec 'silent ' . range . 'g/^/m' . num
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
  let expr = 'compare == s:compare_lists(context, [v:val.lnum, v:val.col, v:val.idx])'
  call filter(items, 'v:val.bufnr == bufnr')
  let nbuffer = len(get(items, 0, {}))
  call filter(items, expr)
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
