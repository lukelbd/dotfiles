"------------------------------------------------------------------------------"
"Some settings
let g:tex_conceal="" "disable math conceal; this is for vim-markdown
let g:vim_markdown_math=1 "turn on $$ math; this is for vim-markdown
"------------------------------------------------------------------------------"
"Map for rendering Markdown by opening it up/refreshing a nice viewer
nnoremap <silent> <buffer> <C-z> :w<CR>:exec("!clear; set -x; open -a 'Marked 2' ".shellescape(@%))<CR><CR>
