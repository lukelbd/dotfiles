"------------------------------------------------------------------------------"
"Another simple run-view result mapping
nnoremap <silent> <buffer> <C-z> :w<CR>:exec("!clear; set -x; julia ".shellescape(@%))<CR><CR>
