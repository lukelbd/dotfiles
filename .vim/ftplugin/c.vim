"------------------------------------------------------------------------------
" C settings
"------------------------------------------------------------------------------
" Compile program then remove the executable
" See: ftplugin/fortran.vim
function! s:run_c_program() abort
  update
  if !exists('g:c_compiler')
    let g:c_compiler = 'gcc'
  endif
  let src = shellescape(expand('%'))
  let exe = shellescape(expand('%:r'))
  let cmd = g:c_compiler . ' -o ' . exe . ' ' . src . ' && ' . exe . ' && rm ' . exe
  call shell#job_win(cmd)
endfunction
setlocal commentstring=//%s
nnoremap <buffer> <Plug>ExecuteFile0 <Cmd>call <sid>run_c_program()<CR>
