"------------------------------------------------------------------------------"
"Compiles current file, runs it, then shows user the output
"------------------------------------------------------------------------------"
" augroup c
"   au!
"   au FileType c call s:cmacros()
" augroup END
" function! s:cmacros()
nnoremap <silent> <buffer> <expr> <C-b> ":w<CR>:!clear; set -x; "
      \."gcc ".shellescape(@%)." -o ".expand('%:r')." && ".expand('%:r')."<CR>"
" endfunction
