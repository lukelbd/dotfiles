" HTML gets sourced after markdown syntax file is souced, so put this in after
let g:tex_conceal = "" "disable math conceal; this is for vim-markdown
let g:vim_markdown_math = 1 " turn on $$ math; this is for vim-markdown
" Helper function
function! s:markdown_open()
  update
  if $TERM_PROGRAM==""
    let terminal = "MacVim"
  elseif $TERM_PROGRAM =~? "Apple_Terminal"
    let terminal = "Terminal"
  else
    let terminal = $TERM_PROGRAM
  endif
  call system('open -a "Marked 2" '.shellescape(@%).'&'."\n".'open -a "'.terminal.'" &')
endfunction
nnoremap <silent> <buffer> <C-z> :call <sid>markdown_open()<CR>
