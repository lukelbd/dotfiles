"------------------------------------------------------------------------------"
" Bash
"------------------------------------------------------------------------------"
" Syntax settings, see :help bash-syntax
" First make sure bash is enabled
let g:is_bash = 1

" Next, the syntax errors I see that are fixed when scrolling/redrawing are actually
" officially documented. To fix them, make this bigger. Default is 200.
let g:sh_minlines = 2000
let g:sh_maxlines = 5000

" Run bash script with simple command
function! s:run_shell_script() abort
  update
  exe '!clear; set -x; bash ' . shellescape(@%)
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>run_shell_script()<CR>
