"------------------------------------------------------------------------------"
"Compile code, then run it and delete the executable
function! s:crun()
  w
  let cpp_path=shellescape(@%)
  let exe_path=shellescape(expand('%:p:r'))
  exe '!clear; set -x; gcc '.cpp_path.' -o '.exe_path.' && '.exe_path.' && rm '.exe_path
  return
endfunction
nnoremap <silent> <buffer> <C-z> :update<CR>:call <sid>crun()<CR>
