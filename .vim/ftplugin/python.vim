"-----------------------------------------------------------------------------
" Python settings
"-----------------------------------------------------------------------------
" General settings
setlocal iskeyword-=.  " exclude period from word definition
setlocal tabstop=4  " number of tab spaces
setlocal shiftwidth=4
setlocal softtabstop=4

" Syntax settings
let b:delimitMate_nesting_quotes = ['"', "'"]
let g:python_slow_sync = 0  " use fast syncing
let g:python_highlight_all = 1  " enable python-syntax options
let g:python_highlight_operators = 1  " avoid highlighting operators (messes up decorators)
let g:python_highlight_func_calls = 1  " highlight parenthetical function calls
let g:python_highlight_builtin_funcs = 1  " highlight builtins (including variables)
let g:python_highlight_builtin_funcs_kwarg = 0  " avoid highlighting within kwargs

" Add mappings (see also vim.vim)
noremap <expr> <buffer> <Plug>ExecuteMotion python#run_motion_expr()
noremap <buffer> <Plug>ExecuteFile0 <Cmd>call python#run_general()<CR>
noremap <buffer> <Plug>ExecuteFile1 <Cmd>call python#jupyter_setup()<CR>
noremap <buffer> <Plug>ExecuteFile2 <Cmd>JupyterDisconnect<CR>

" Insert docstring or translate dicts (see autoload/python.vim)
silent! unmap <buffer> g\|
noremap <buffer> gD <Cmd>call python#insert_docstring()<CR>
noremap <buffer> g(( <Cmd>call python#kwargs_to_dict(1)<CR>
noremap <buffer> g)) <Cmd>call python#kwargs_to_dict(0)<CR>
noremap <expr> <buffer> g( python#kwargs_to_dict_expr(1)
noremap <expr> <buffer> g) python#kwargs_to_dict_expr(0)

" Create string delimiters (include [frub] prefixes)
" BracelessEnable +indent  " bug causes screen view to jump
" BracelessEnable +highlight  " slows things down even on mac
exe 'BracelessEnable'
let b:succinct_delims = {
  \ "'": '''\r''',
  \ '"': '"\r"',
  \ 'd': '"""\r"""',
  \ 'D': '''''''\r''''''',
\ }
