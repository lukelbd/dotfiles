"-----------------------------------------------------------------------------"
" Builtin TeX settings
" Note: This used to be in textools plugin, but want to keep things modular.
"-----------------------------------------------------------------------------"
" Restrict concealmeant to just accents, Greek symbols, and math symbols
let g:tex_conceal = 'agmd'

" Allow @ in makeatletter, allow texmathonly outside of math regions (i.e.
" don't highlight [_^] when you think they are outside math zone)
let g:tex_stylish = 1

" Disable spell checking in verbatim mode and comments, disable errors
" let g:tex_fast = ''  " fast highlighting, but pretty ugly
let g:tex_fold_enable = 1
let g:tex_comment_nospell = 1
let g:tex_verbspell = 0
let g:tex_no_error = 1

" Add maps to custom textools latexmk command
noremap <buffer> <silent> <Plug>Execute :Latexmk --pull<CR>
noremap <buffer> <silent> <Plug>AltExecute1 :Latexmk --pull --diff<CR>
noremap <buffer> <silent> <Plug>AltExecute2 :Latexmk --pull --word<CR>
