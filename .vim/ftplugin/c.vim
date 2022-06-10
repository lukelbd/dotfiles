"------------------------------------------------------------------------------"
" C settings
"------------------------------------------------------------------------------"
" Compile code then run it and delete the executable
function! s:run_c_program() abort
  update
  if !exists('g:c_compiler')
    let g:c_compiler = 'gcc'
  endif
  let src = shellescape(expand('%'))
  let exe = shellescape(expand('%:r'))
  let cmd = g:c_compiler . ' -o ' . exe . ' ' . src . ' && ' . exe . ' && rm ' . exe
  call popup#job_win(cmd)
endfunction
nnoremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>run_c_program()<CR>
