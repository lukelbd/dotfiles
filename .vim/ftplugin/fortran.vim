"A simple compile mapping, and trigger some global settings compatible
"with vim's builtin fotran syntax highlighter.
"------------------------------------------------------------------------------"
"These mostly make automatic indentation better
"See this helpful thread: https://stackoverflow.com/a/17619568/4970632
"See $VIMRUNTIME/indent/fortran.vim for setting the relevant global variables
let fortran_do_enddo=1    " otherwise do/enddo loops aren't indented!
let fortran_indent_more=1 " more better indenting
let fortran_fold=1
let fortran_have_tabs=1
let fortran_free_source=1
let fortran_more_precise=1
let b:fortran_dialect='f08' "can be F or f08
"------------------------------------------------------------------------------"
"Compile code, then run it and delete the executable
function! s:fortranrun()
  w
  let f90_path=shellescape(@%)
  let exe_path=shellescape(expand('%:p:r'))
  exe '!clear; set -x; gfortran '.f90_path.' -o '.exe_path.' && '.exe_path.' && rm '.exe_path
  return
endfunction
nnoremap <silent> <buffer> <C-z> :w<CR>:call <sid>fortranrun()<CR>
