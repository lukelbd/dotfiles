"------------------------------------------------------------------------------
" Fortran settings
"------------------------------------------------------------------------------
" Syntax and indentation settings
" See: https://stackoverflow.com/a/17619568/4970632
" See: $VIMRUNTIME/indent/fortran.vim for relevant global variables
let g:fortran_do_enddo = 1  " otherwise do/enddo loops aren't indented!
let g:fortran_indent_more = 1  " more better indenting
let g:fortran_have_tabs = 0
let g:fortran_more_precise = 0
let b:fortran_dialect = 'f08'  " used by plugin?

" Let fortran *automatically* detect free or fixed source
" See :help ft-fortran-syntax
silent! unlet g:fortran_free_source
silent! unlet g:fortran_fixed_source

" Compile program then remove the executable
" See: ftplugin/c.vim
function! s:run_fortran_program() abort
  update
  if !exists('g:fortran_compiler')
    let g:fortran_compiler = 'gfortran'
  endif
  let src = shellescape(expand('%'))
  let exe = shellescape(expand('%:r'))
  let cmd = g:fortran_compiler . ' -o ' . exe . ' ' . src . ' && ' . exe . ' && rm ' . exe
  call shell#job_win(cmd)
endfunction
nnoremap <buffer> <Plug>ExecuteFile0 <Cmd>call <sid>run_fortran_program()<CR>
