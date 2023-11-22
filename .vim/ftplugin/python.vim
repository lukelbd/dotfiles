"-----------------------------------------------------------------------------
" Python settings
"-----------------------------------------------------------------------------
" General settings
setlocal iskeyword-=.  " exclude period from word definition
setlocal tabstop=4  " number of tab spaces
setlocal shiftwidth=4
setlocal softtabstop=4

" Syntax settings
let g:python_slow_sync = 0  " use fast syncing
let g:python_highlight_all = 1  " builtin python syntax option
let g:python_highlight_func_calls = 1  " python-syntax syntax option
let g:python_highlight_builtin_funcs = 0  " python-syntax syntax option

" Add mappings (see also vim.vim)
noremap <expr> <buffer> <Plug>ExecuteMotion python#run_motion_expr()
noremap <buffer> <Plug>ExecuteFile1 <Cmd>call python#run_general()<CR>
noremap <buffer> <Plug>ExecuteFile2 <Cmd>call python#init_jupyter()<CR>
noremap <buffer> <Plug>ExecuteFile3 <Cmd>JupyterDisconnect<CR>

" Insert docstring (see autoload/python.vim)
noremap <buffer> gcd <Cmd>Pydocstring<CR><Cmd>call timer_start(500, function('python#split_docstrings'))<CR>
noremap <buffer> gcD <Cmd>Pydocstring<CR><Cmd>call timer_start(500, function('python#split_docstrings'))<CR>

" Translate dictionaries to kwargs (see autoload/python.vim)
noremap <expr> <buffer> g{ python#dict_to_kw_expr(0)
noremap <expr> <buffer> g} python#dict_to_kw_expr(1)

" Define python vim-surround macros
" Todo: Support [frub]* regex delimiters by adding succinct#add_delims() parameter
" to bypass regex escape and adding [] and *?+ support to succinct#process_value().
call succinct#add_delims({
  \ 'l': "list(\r)",
  \ 't': "tuple(\r)",
  \ "'": "'\r'",
  \ '"': "\"\r\"",
  \ 'd': "\"\"\"\r\"\"\"",
  \ 'D': "'''\r'''",
  \ },
  \ 1)

" Define indention-based 'm' text objects
" BracelessEnable +indent  " bug causes screen view to jump
" BracelessEnable +highlight  " slows things down even on mac
if exists(':BracelessEnable')
  BracelessEnable
endif
