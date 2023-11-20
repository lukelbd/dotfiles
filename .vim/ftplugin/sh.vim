"------------------------------------------------------------------------------
" Bash
"------------------------------------------------------------------------------
" General settings
" Note: Without this $VIMRUNTIME will fold every nested 'if' 'case' etc. block
setlocal foldnestmax=1

" Syntax settings and enable bash
" Note: Defaults are 200. This fixes syntax error highlighting issues when scrolling.
let g:is_bash = 1
let g:sh_minlines = 2000
let g:sh_maxlines = 5000

" Run shell script
function! s:run_shell_script() abort
  update
  let cmd = 'bash ' . shellescape(@%)
endfunction
nnoremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>run_shell_script()<CR>
