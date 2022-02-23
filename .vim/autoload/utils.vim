"-----------------------------------------------------------------------------"
" General utilities
"-----------------------------------------------------------------------------"
" Empty list. This is used to prevent input() from returning literal
" tabs and where no tab completion is desired.
function! utils#null_list(...) abort
  return []
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

" Vim help, command --help, and man command information
" Note: These are low-level companions to higher-level vim-lsp and fzf features
function! utils#help_vim(...) abort
  if a:0
    let item = a:1
  else
    let item = input('Vim help item: ', '', 'help')
  endif
  if !empty(item)
    exe 'vert help ' . item
  endif
endfunction
function! utils#help_sh(...) abort
  if a:0
    let cmd = a:1
  else
    let cmd = input('Get --help info: ', expand('<cword>'), 'shellcmd')
  endif
  if !empty(cmd)
    silent! exe '!clear; '
      \ . 'search=' . cmd . '; '
      \ . 'if [ -n $search ] && builtin help $search &>/dev/null; then '
      \ . '  builtin help $search 2>&1 | less; '
      \ . 'elif $search --help &>/dev/null; then '
      \ . '  $search --help 2>&1 | less; '
      \ . 'fi'
    if v:shell_error != 0
      echohl WarningMsg
      echom 'Warning: "man ' . cmd . '" failed.'
      echohl None
    endif
  endif
endfunction
function! utils#help_man(...) abort
  if a:0
    let cmd = a:1
  else
    let cmd = input('Get man page: ', expand('<cword>'), 'shellcmd')
  endif
  if !empty(cmd)
    silent! exe '!clear; '
      \ . 'search=' . cmd . '; '
      \ . 'if [ -n $search ] && command man $search &>/dev/null; then '
      \ . '  command man $search; '
      \ . 'fi'
    if v:shell_error != 0
      echohl WarningMsg
      echom 'Warning: "' . cmd . ' --help" failed.'
      echohl None
    endif
  endif
endfunction

" Information about syntax and colors
" The show commands produce popup windows
function! utils#current_syntax(name) abort
  if a:name
    exe 'verb syntax list ' . a:name
  else
    exe 'verb syntax list ' . synIDattr(synID(line('.'), col('.'), 0), 'name')
  endif
endfunction
function! utils#current_group() abort
  let names = []
  for id in synstack(line('.'), col('.'))
    let name = synIDattr(id, 'name')
    let group = synIDattr(synIDtrans(id), 'name')
    if name != group
      let name .= ' (' . group . ')'
    endif
    let names += [name]
  endfor
  echo join(names, ', ')
endfunction
function! utils#show_plugin() abort
  execute 'split $VIMRUNTIME/ftplugin/' . &filetype . '.vim'
  silent call utils#popup_setup()
endfunction
function! utils#show_syntax() abort
  execute 'split $VIMRUNTIME/syntax/' . &filetype . '.vim'
  silent call utils#popup_setup()
endfunction
function! utils#show_colors() abort
  source $VIMRUNTIME/syntax/colortest.vim
  silent call utils#popup_setup()
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

" Cyclic next error in location list
" Copied from: https://vi.stackexchange.com/a/14359
function! utils#iter_cyclic(count, list, ...) abort
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
  let [bufnr, cmp] = [bufnr('%'), reverse ? 1 : -1]
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
  call filter(items, 's:cmp(context, [v:val.lnum, v:val.col, v:val.idx]) == cmp')
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
