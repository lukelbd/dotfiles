"------------------------------------------------------------------------------"
" Julia settings
"------------------------------------------------------------------------------"
" Comment string
setlocal commentstring=#%s

" Run the julia file
" Todo: Pair with persistent julia session using vim-jupyter? See python.vim.
function! s:run_julia_script()
  update
  exe '!clear; set -x; julia ' . shellescape(@%)
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>run_julia_script()<CR>
