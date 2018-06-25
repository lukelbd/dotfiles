"------------------------------------------------------------------------------"
"Another simple run-view result mapping
"------------------------------------------------------------------------------"
" augroup julia
"   au!
"   au FileType julia call s:jmacros()
" augroup END
" function! s:jmacros()
nnoremap <silent> <buffer> <expr> <C-b> ":w<CR>:!clear; set -x; "
  \."julia ".shellescape(@%)."<CR>"
" endfunction
