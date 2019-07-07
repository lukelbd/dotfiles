"LaTeX specific settings
"Restrict concealmeant to just symbols and stuff
" a=accents/ligatures
" b=bold/italics
" d=delimiters (e.g. $$ math mode)
" m=math symbols
" g=Greek
" s=superscripts/subscripts
let g:tex_conceal='agm'

"Allow @ in makeatletter, allow texmathonly outside of math regions (i.e.
"don't highlight [_^] when you think they are outside math zone
let g:tex_stylish=1

"Disable spell checking in verbatim mode and comments, disable errors
" let g:tex_fast="" "fast highlighting, but pretty ugly
let g:tex_fold_enable=1
let g:tex_comment_nospell=1
let g:tex_verbspell=0
let g:tex_no_error=1

"Typesetting LaTeX and displaying PDF viewer
"Use C-z for compiling normally, and <Leader>Z for compiling to word document.
function! s:latex_background(...)
  let opts=(a:0 ? a:1 : '') "flags
  let logfile=expand('%:t:r').'.exe'
  let tabnames=map(tabpagebuflist(), 'expand("#".v:val.":t")')
  "Jump to logfile if it is open, else open one
  let idx=index(tabnames, logfile)
  if idx==-1
    exe 'split '.logfile
    setlocal autoread "open file and set autoread before starting script!
    exe "normal! \<C-w>\<C-p>"
  endif
  "Run function
  call system('~/bin/vimlatex '.shellescape(@%).' '.opts.' &>'.logfile.' &')
  " silent! call execute('~/bin/vimlatex '.curfile.' '.opts.' &>'.logfile.' &')
endfunction
noremap <silent> <buffer> <C-z> :call <sid>latex_background()<CR>
noremap <silent> <buffer> <Leader>z :call <sid>latex_background(' --diff')<CR>
noremap <silent> <buffer> <Leader>Z :call <sid>latex_background(' --word')<CR>

