" Source current vim script
nnoremap <silent> <buffer> <C-z> :update<CR>:so %<CR>:echo "Sourced ".expand('%:p:t')<CR>
