"A simple run mapping, so far. Feel free to add to this.
"------------------------------------------------------------------------------"
"Run bash script with simple command
nnoremap <silent> <buffer> <C-b> :w<CR>:exe '!clear; set -x; '.shellescape(expand('%:p'))<CR>
"------------------------------------------------------------------------------"
"Syntax settings
"See :help bash-syntax
"First make sure bash is enabled
let g:is_bash=1
"Next, the syntax errors I see that are fixed when scrolling/redrawing are actually
"officially documented. To fix them, make this bigger. Default is 200. Seems 1000
"is necessary for bashrc.
let g:sh_minlines = 2000

