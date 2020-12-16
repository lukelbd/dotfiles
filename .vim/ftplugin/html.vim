"------------------------------------------------------------------------------"
" HTML settings
"------------------------------------------------------------------------------"
" DelimitMate plugin
let b:delimitMate_matchpairs = '(:),{:},[:],<:>'

" Declare command to 'compile' page, i.e. show it in Safari
function! s:open_html_file()
  update
  exe '!clear; set -x; open -a Safari ' . shellescape(@%)
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>open_html_file()

" Define HTML vim-surround macros
" Todo: Put everything in textools ftplugin files
if &runtimepath =~# 'vim-surround'
  let s:html_surround = {
    \ 't': ["<\1<\1>",  "</\1\1>"],
    \ 'd': ['<div>',    '</div>'],
    \ 'h': ['<head>',   '</head>'],
    \ 'm': ['<body>',   '</body>'],
    \ 'f': ['<footer>', '</footer>'],
    \ 'T': ['<title>',  '</title>'],
    \ 'e': ['<em>',     '</em>'],
    \ 'o': ['<b>',      '</b>'],
    \ 'i': ['<i>',      '</i>'],
    \ 's': ['<strong>', '</strong>'],
    \ 'p': ['<p>',      '</p>'],
    \ '1': ['<h1>',     '</h1>'],
    \ '2': ['<h2>',     '</h2>'],
    \ '3': ['<h3>',     '</h3>'],
    \ '4': ['<h4>',     '</h4>'],
    \ '5': ['<h5>',     '</h5>'],
  \ }
  for [s:binding, s:pair] in items(s:html_surround)
    let [s:left, s:right] = s:pair
    let b:surround_{char2nr(s:binding)} = s:left . "\r" . s:right
  endfor
endif
