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
let g:python_highlight_all = 1  " builtin python ftplugin syntax option

" Enable braceless
if exists(':BracelessEnable')
  " BracelessEnable +indent +highlight  " highlight slows things down, even on mac
  " BracelessEnable +indent  " weird bug causes screen view to jump
  BracelessEnable
endif

" Translating dictionaries to keyword input
noremap <expr> <buffer> cd python#translate_kwargs_dict_expr(1)
noremap <expr> <buffer> cD python#translate_kwargs_dict_expr(0)

" Run current script using anaconda python, not vim python (important for macvim)
" Todo: Pair with persistent python session using vim-jupyter? See julia.vim.
function! s:run_python_script() abort
  update
  let exe = $HOME . '/miniconda3/bin/python'
  let proj = $HOME . '/miniconda3/share/proj'
  if !executable(exe)
    echohl WarningMsg
    echom "Miniconda python '" . exe . "' not found."
    echohl None
  else
    update
    let cmd = 'PROJ_LIB=' . shellescape(proj) . ' ' . shellescape(exe) . ' ' . shellescape(@%)
    call setup#job_win(cmd)
  endif
endfunction

" Run the jupyter file or block of code
" Warning: Monitor private variable _jupyter_session for changes
function! s:run_jupyter_vim() range abort
  let active = str2nr(py3eval('int('
    \ . '"_jupyter_session" in globals() and '
    \ . '_jupyter_session.kernel_client.check_connection()'
    \ . ')'))
  if !active
    echom 'Running python script.'
    call s:run_python_script()
  elseif v:count
    echom 'Sending ' . v:count . ' lines.'
    exe 'JupyterSendCount ' . v:count
  elseif a:firstline != a:lastline
    echom 'Sending lines ' . a:firstline . ' to ' . a:lastline . '.'
    exe a:firstline . ',' . a:lastline . 'JupyterSendRange'
  else
    echom 'Sending entire file.'
    exe 'JupyterRunFile'
  endif
endfunction

" Add mappings
noremap <silent> <buffer> <Plug>Execute0 :call <sid>run_jupyter_vim()<CR>
noremap <silent> <buffer> <Plug>Execute1 :call <sid>run_jupyter_vim()<CR>
noremap <silent> <buffer> <Plug>Execute2 :call <sid>run_jupyter_vim()<CR>

" Define python vim-surround macros
call succinct#add_delims({
  \ 'd': "'''\r'''",
  \ 'D': "\"\"\"\r\"\"\"",
  \ 'l': "list(\r)",
  \ 't': "tuple(\r)",
  \ },
  \ 1)
