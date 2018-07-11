" ------------------------------------------------------------------------------"
" Map for rendering Markdown by opening it up/refreshing a nice viewer
" Also some settings
" ------------------------------------------------------------------------------"
" augroup markdown
" au!
" for a up
"   au FileType markdown call s:markdownmacros()
" augroup END
" function! s:markdownmacros()
" inoremap <silent> <buffer> <C-b> <Esc>:w<CR>:exec("!clear; set -x; "
"   \."open -a 'Marked 2' ".shellescape(@%))<CR>a
let g:tex_conceal="" "disable math conceal; this is for vim-markdown
let g:vim_markdown_math=1 "turn on $$ math; this is for vim-markdown
nnoremap <silent> <buffer> <C-b> :w<CR>:exec("!clear; set -x; open -a 'Marked 2' ".shellescape(@%))<CR><CR>
" endfunction
