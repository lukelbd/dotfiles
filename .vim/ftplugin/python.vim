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
noremap <buffer> <Plug>ExecuteFile0 <Cmd>call python#run_general()<CR>
noremap <buffer> <Plug>ExecuteFile1 <Cmd>call python#init_jupyter()<CR>
noremap <buffer> <Plug>ExecuteFile2 <Cmd>JupyterDisconnect<CR>

" Insert docstring or translate dicts (see autoload/python.vim)
noremap <buffer> g\| <Cmd>call python#insert_docstring()<CR>
noremap <expr> <buffer> g{ python#dict_to_kw_expr(0)
noremap <expr> <buffer> g} python#dict_to_kw_expr(1)
map <buffer> g{{ g{iccscfdict<CR>
map <buffer> g}} g}ibcsfc

" Add indention-based 'm' text objects
" BracelessEnable +indent  " bug causes screen view to jump
" BracelessEnable +highlight  " slows things down even on mac
if exists(':BracelessEnable')
  BracelessEnable
endif

" Add multiline docstring 'd' delimiters
" Note: This will include matches e.g. 'r' prefixes. Also re-apply single quote
" mappings for consistency but should work in python files anyway.
let b:succinct_delims = {
  \ "'": '''\r''',
  \ '"': '"\r"',
  \ 'd': '"""\r"""',
  \ 'D': '''''''\r''''''',
\ }
