"------------------------------------------------------------------------------
" NCL settings
"------------------------------------------------------------------------------
" Comment string
setlocal commentstring=;%s

" Highlight builtin NCL commands as keyword by adding dictionary
setlocal dictionary+=~/.vim/words/ncl.dic

" Run NCL script
function! s:run_ncl_script() abort
  update
  let cmd = 'ncl -n -Q ' . shellescape(@%)
  call shell#job_win(cmd)
endfunction
nnoremap <buffer> <Plug>ExecuteFile0 <Cmd>call <sid>run_ncl_script()<CR>
