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

" DelimitMate integration
let b:delimitMate_quotes = '$ |'
let b:delimitMate_matchpairs = "(:),{:},[:],`:'"

" Custom delimiters
" Todo: Define these!

" Running latexmk in background
" The `latexmk` script included with this package typesets the document and opens the
" file in the [Skim PDF viewer](https://en.wikipedia.org/wiki/Skim_(software)).
" This script has the following features:
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')  " copied from autoreload/plug.vim
let s:path = expand('<sfile>:p:h')
function! s:latexmk(...) abort
  if !s:vim8
    echohl ErrorMsg
    echom 'Error: Latex compilation requires vim >= 8.0'
    echohl None
    return 1
  endif
  " Jump to logfile if it is open, else open one
  " Warning: Trailing space will be escaped as flag! So trim unless we have any options
  let opts = trim(a:0 ? a:1 : '') . ' -l=' . string(line('.'))
  let texfile = expand('%')
  let logfile = expand('%:t:r') . '.latexmk'
  let lognum = bufwinnr(logfile)
  if lognum == -1
    silent! exe string(winheight('.') / 4) . 'split ' . logfile
    silent! exe winnr('#') . 'wincmd w'
  else
    silent! exe bufwinnr(logfile) . 'wincmd w'
    silent! 1,$d _
    silent! exe winnr('#') . 'wincmd w'
  endif
  " Run job in realtime
  let num = bufnr(logfile)
  let g:tex_job = job_start(
    \ s:path . '/../bin/latexmk ' . texfile . ' ' . opts,
    \ {'out_io': 'buffer', 'out_buf': num, 'err_io': 'buffer', 'err_buf': num}
    \ )
endfunction

" Latexmk command and shortcuts
command! -buffer -nargs=* Latexmk call s:latexmk(<q-args>)
noremap <buffer> <silent> <Plug>Execute :<C-u>call <sid>latexmk()<CR>
noremap <buffer> <silent> <Plug>AltExecute1 :<C-u>call <sid>latexmk('--diff')<CR>
noremap <buffer> <silent> <Plug>AltExecute2 :<C-u>call <sid>latexmk('--word')<CR>
