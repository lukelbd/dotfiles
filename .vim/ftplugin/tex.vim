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
" Todo: Pull figures from remote location if applicable
function! s:latexmk(...)
  exe 'Latexmk ' . join(a:000, ' ')
endfunction
noremap <buffer> <silent> <Plug>Execute :<C-u>call <sid>latexmk()<CR>
noremap <buffer> <silent> <Plug>AltExecute1 :<C-u>call <sid>latexmk('--diff')<CR>
noremap <buffer> <silent> <Plug>AltExecute2 :<C-u>call <sid>latexmk('--word')<CR>
