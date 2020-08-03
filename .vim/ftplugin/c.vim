"------------------------------------------------------------------------------"
" C settings
"------------------------------------------------------------------------------"
" Compile code then run it and delete the executable
function! s:run_c_program()
  update
  let dir_path = shellescape(expand('%:h'))
  let cpp_path = shellescape(expand('%:t'))
  let exe_path = shellescape(expand('%:t:r'))
  exe
    \ '!clear; set -x; '
    \ . 'cd ' . dir_path . '; '
    \ . 'gcc ' . cpp_path . ' -o ' . exe_path . ' '
    \ . '&& ' . exe_path . ' && rm ' . exe_path
  return
endfunction
nnoremap <silent> <buffer> <C-z> :call <sid>run_c_program()<CR>
