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
  let logfile=expand('%:r').'.exe'
  "Jump to logfile if it is open, else open one
  silent! call system('rm '.logfile)
  silent! call system('touch '.logfile)
  let lognum=bufwinnr(logfile)
  if lognum==-1
    silent! exe string(winheight('.')/4).'split '.logfile
    " setlocal autoread "open file and set autoread before starting script!
    silent! exe winnr('#').'wincmd w'
  else
    silent! exe bufwinnr(logfile)."wincmd w"
    silent! edit +$
    silent! exe winnr('#').'wincmd w'
  endif
  "Run function
  silent! call system('~/bin/vimlatex '.shellescape(@%).' '.opts.' &>'.logfile.' &')
  echom "Running vimlatex in background."
endfunction
"Refresh log
function! s:latex_refresh()
  let logfile=expand('%:r').'.exe'
  if expand('%') == logfile
    edit +$
  else
    silent! exe bufwinnr(logfile)."wincmd w"
    silent! edit +$
    silent! exe winnr('#').'wincmd w'
  endif
endfunction
"Maps
noremap <silent> <buffer> <C-z> :call <sid>latex_background()<CR>
noremap <silent> <buffer> <Leader>z :call <sid>latex_background(' --diff')<CR>
noremap <silent> <buffer> <Leader>Z :call <sid>latex_background(' --word')<CR>
noremap <silent> <buffer> <Leader>l :call <sid>latex_refresh()<CR>

