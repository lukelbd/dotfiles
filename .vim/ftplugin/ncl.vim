"------------------------------------------------------------------------------"
" NCL settings
"------------------------------------------------------------------------------"
" Comment string
setlocal commentstring=;%s

" Highlight builtin NCL commands as keyword by adding dictionary
setlocal dictionary+=~/.vim/words/ncl.dic

" Run NCL script
function! s:run_ncl_script()
  update
  let cmd = 'ncl -n -Q ' . shellescape(@%)
  call popup#job_win(cmd)
endfunction
nnoremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>run_ncl_script()<CR>
