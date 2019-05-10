"Some settings, must be in ftplugin/after because html apparently gets
"sourced after the markdown syntax file is sourced
let g:tex_conceal="" "disable math conceal; this is for vim-markdown
let g:vim_markdown_math=1 "turn on $$ math; this is for vim-markdown
nnoremap <silent> <buffer> <C-z> :update<CR>:exec("!clear; set -x; open -a 'Marked 2' ".shellescape(@%))<CR><CR>
"Previous thing
" function! s:terminal()
"   if $TERM_PROGRAM == 'Apple_Terminal'
"     let terminal='Terminal'
"   elseif $TERM_PROGRAM
"     let terminal=$TERM_PROGRAM
"   else
"     let terminal='MacVim' "means we are running from GUI in this case
"   endif
"   return terminal
" endfunction
" nnoremap <silent> <buffer> <C-z> :update<CR>:exec("!clear; set -x; open -a 'Marked 2' ".shellescape(@%).'; open -a '.<sid>terminal())<CR><CR>
