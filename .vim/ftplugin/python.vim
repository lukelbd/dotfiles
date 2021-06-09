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

" Custom mappings
noremap <expr> <buffer> cd utils#translate_kwargs_dict_expr(1)
noremap <expr> <buffer> cD utils#translate_kwargs_dict_expr(0)

" Run current script using anaconda python, not vim python (important for macvim)
function! s:run_python_script() abort
  update
  let python = $HOME . '/miniconda3/bin/python'
  let projlib = $HOME . '/miniconda3/share/proj'
  if !executable(python)
    echohl WarningMsg
    echom "Anaconda python '" . python . "' not found."
    echohl None
  else
    exe
      \ '!clear; set -x; PROJ_LIB=' . shellescape(projlib)
      \ . ' ' . shellescape(python) . ' ' . shellescape(@%)
  endif
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>run_python_script()<CR>
