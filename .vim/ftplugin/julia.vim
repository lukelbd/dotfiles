"------------------------------------------------------------------------------"
" Julia settings
"------------------------------------------------------------------------------"
" Comment string
setlocal commentstring=#%s

" Run the julia file
" Todo: Pair with persistent julia session using vim-jupyter? See python.vim.
function! s:run_julia_script()
  update
  let cmd = 'julia ' . shellescape(@%)
  call popup#job_win(cmd)
endfunction
nnoremap <silent> <buffer> <Plug>ExecuteFile1 :call <sid>run_julia_script()<CR>
