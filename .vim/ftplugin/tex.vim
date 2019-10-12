"-----------------------------------------------------------------------------"
" LaTeX specific settings
"-----------------------------------------------------------------------------"
" Restrict concealmeant to just symbols and stuff
" a=accents/ligatures
" b=bold/italics
" d=delimiters (e.g. $$ math mode)
" m=math symbols
" g=Greek
" s=superscripts/subscripts
let g:tex_conceal = 'agm'

" Allow @ in makeatletter, allow texmathonly outside of math regions (i.e.
" don't highlight [_^] when you think they are outside math zone
let g:tex_stylish = 1

" Disable spell checking in verbatim mode and comments, disable errors
" let g:tex_fast = "" "fast highlighting, but pretty ugly
let g:tex_fold_enable = 1
let g:tex_comment_nospell = 1
let g:tex_verbspell = 0
let g:tex_no_error = 1

" Typesetting LaTeX and displaying PDF viewer
" Copied s:vim8 from autoreload/plug.vim file
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')
function! s:latex_background(...)
  if !s:vim8
    echom "Error: Latex compilation requires vim >= 8.0"
    return 1
  endif
  " Jump to logfile if it is open, else open one
  let opts = (a:0 ? a:1 : '') " flags
  let texfile = expand('%')
  let logfile = expand('%:t:r') . '.log'
  let lognum = bufwinnr(logfile)
  if lognum == -1
    silent! exe string(winheight('.')/4) . 'split ' . logfile
    silent! exe winnr('#') . 'wincmd w'
  else
    silent! exe bufwinnr(logfile) . 'wincmd w'
    silent! 1,$d
    silent! exe winnr('#') . 'wincmd w'
  endif
  " Run job in realtime
  " WARNING: Trailing space will be escaped as a flag! So trim it.
  let num = bufnr(logfile)
  let g:tex_job = job_start('/Users/ldavis/bin/latexmk ' . texfile . trim(opts),
      \ { 'out_io': 'buffer', 'out_buf': num })
endfunction
" Maps
noremap <silent> <buffer> <C-z> :call <sid>latex_background()<CR>
noremap <silent> <buffer> <Leader>z :call <sid>latex_background(' --diff')<CR>
noremap <silent> <buffer> <Leader>Z :call <sid>latex_background(' --word')<CR>

