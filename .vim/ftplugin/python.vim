"-----------------------------------------------------------------------------
" Python settings
"-----------------------------------------------------------------------------
" Various settings
setlocal iskeyword-=.  " exclude period from word definition
setlocal tabstop=4  " number of tab spaces
setlocal shiftwidth=4
setlocal softtabstop=4
let g:python_slow_sync = 0  " use fast syncing
let g:python_highlight_all = 1  " builtin python syntax option
let g:python_highlight_func_calls = 1  " python-syntax syntax option
let g:python_highlight_builtin_funcs = 0  " python-syntax syntax option

" Translate dictionaries to keyword input
noremap <expr> <buffer> g{ python#dict_to_kw_expr(0)
noremap <expr> <buffer> g} python#dict_to_kw_expr(1)

" Add mappings (see also vim.vim)
noremap <expr> <buffer> <Plug>ExecuteMotion python#run_motion_expr()
noremap <buffer> <Plug>ExecuteFile1 <Cmd>call python#run_content()<CR>
noremap <buffer> <Plug>ExecuteFile2 <Cmd>call python#start_jupyter()<CR>
noremap <buffer> <Plug>ExecuteFile3 <Cmd>JupyterDisconnect<CR>

" Define python vim-surround macros
call succinct#add_delims({
  \ 'd': "'''\r'''",
  \ 'D': "\"\"\"\r\"\"\"",
  \ 'l': "list(\r)",
  \ 't': "tuple(\r)",
  \ },
  \ 1)

" Define indention-based 'm' text objects
if exists(':BracelessEnable')
  BracelessEnable  " enable basic 'm' objects
  " BracelessEnable +indent  " weird bug causes screen view to jump
  " BracelessEnable +indent +highlight  " highlight slows things down even on mac
endif
