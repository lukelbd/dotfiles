"A simple compile mapping, and trigger some global settings compatible
"with vim's builtin fotran syntax highlighter.
" augroup fortran
"   au!
"   au FileType fortran call s:fortranmacros()
" augroup END
"------------------------------------------------------------------------------"
"Compile code, then run it and show user the output
" function! s:fortranmacros()
nnoremap <silent> <buffer> <expr> <C-b> ":w<CR>:!clear; set -x; "
  \."gfortran ".shellescape(@%)." -o ".expand('%:r')." && ./".expand('%:r')."<CR>"
" endfunction
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

