"Open viewer with current script
"HTML gets sourced after markdown syntax file is souced, so put this in after
let g:tex_conceal="" "disable math conceal; this is for vim-markdown
let g:vim_markdown_math=1 "turn on $$ math; this is for vim-markdown
nnoremap <silent> <buffer> <C-z> :update<CR>:exec("!clear; set -x; open -a 'Marked 2' ".shellescape(@%))<CR><CR>
