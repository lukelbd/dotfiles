"-----------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-09-20
" Various settings and macros for python files
" Includes a couple mappings for converting {'a':1} to a=1
"-----------------------------------------------------------------------------"
" Misc settings
setlocal tabstop=4 softtabstop=4 shiftwidth=4
setlocal indentexpr=s:pyindent(v:lnum)  " new indent expression
setlocal iskeyword-=.  " never include period in word definition
let g:python_highlight_all = 1  " builtin python syntax option
let g:python_highlight_builtin_funcs = 0  " python-syntax syntax option
" let g:python_highlight_func_calls = 0  " python-syntax syntax option

" Enable braceless
if exists(':BracelessEnable')
  BracelessEnable
  " BracelessEnable +indent  " weird bug causes screen view to jump
  " BracelessEnable +indent +highlight  " highlight slows things down, even on mac
endif

" Translating dictionaries to keyword input
noremap <expr> <buffer> cd python#kwargs_dict_expr(1)
noremap <expr> <buffer> cD python#kwargs_dict_expr(0)

" Add mappings
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
