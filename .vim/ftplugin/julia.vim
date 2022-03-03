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
  call setup#job_win(cmd)
endfunction
nnoremap <silent> <buffer> <Plug>Execute0 :call <sid>run_julia_script()<CR>
