"Open viewer with current script
"Install script with pip install restview
nnoremap <silent> <buffer> <C-z> :update<CR>:exec("!clear; set -x; restview -b -l 40000 ".shellescape(@%))<CR><CR>
