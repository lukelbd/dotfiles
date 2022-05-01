"------------------------------------------------------------------------------"
" Fortran settings
"------------------------------------------------------------------------------"
" These mostly make automatic indentation better
" See this helpful thread: https://stackoverflow.com/a/17619568/4970632
" See $VIMRUNTIME/indent/fortran.vim for setting the relevant global variables
let g:fortran_do_enddo = 1    " otherwise do/enddo loops aren't indented!
let g:fortran_indent_more = 1 " more better indenting
let g:fortran_fold = 0
let g:fortran_have_tabs = 0
let g:fortran_more_precise = 0
let b:fortran_dialect = 'f08' " used by plugin?

" Let fortran *automatically* detect free or fixed source
" See :help ft-fortran-syntax
silent! unlet g:fortran_free_source
silent! unlet g:fortran_fixed_source

" Tool that compiles code, then runs it, then deletes the executable
function! s:run_fortran_program()
  update
  if !exists('g:fortran_compiler')
    let g:fortran_compiler = 'gfortran'
  endif
  let src = shellescape(expand('%'))
  let exe = shellescape(expand('%:r'))
  let cmd = g:fortran_compiler . ' -o ' . exe . ' ' . src . ' && ' . exe . ' && rm ' . exe
  call popup#job_win(cmd)
endfunction
nnoremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>run_fortran_program()<CR>
