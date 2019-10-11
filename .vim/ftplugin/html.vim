"------------------------------------------------------------------------------"
" Declare command to 'compile' page, i.e. show it in Chromium
" nnoremap <silent> <buffer> <C-z> :!open -a Chromium %<CR>:redraw!<CR>
nnoremap <silent> <buffer> <C-z> :exec("!clear; set -x; open -a Chromium ".shellescape(@%))<CR><CR>
