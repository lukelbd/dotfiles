"------------------------------------------------------------------------------"
" HTML settings
"------------------------------------------------------------------------------"
" DelimitMate plugin
let b:delimitMate_matchpairs = '(:),{:},[:],<:>'
if &filetype !=# 'html'  " skip html-derived types, e.g. markdown
  finish
endif

" Declare command to "compile' page, i.e. show it in Safari
function! s:open_html_file()
  update
  exe '!clear; set -x; open -a Safari ' . shellescape(@%)
endfunction
nnoremap <silent> <buffer> <Plug>Execute0 :call <sid>open_html_file()

" Define HTML vim-surround macros
" Note: div is generally used just to add a class or id to sections of
" a document for styling with e.g. a CSS file.
" Note: div delim adapted from :help surround to only insert the tag
" if a class is provided (see tex.vim).
call succinct#add_delims({
  \ 't': "<\1<\1>\r</\1\1>",
  \ 'T': "<title>\r</title>",
  \ '1': "<h1>\r</h1>",
  \ '2': "<h2>\r</h2>",
  \ '3': "<h3>\r</h3>",
  \ '4': "<h4>\r</h4>",
  \ '5': "<h5>\r</h5>",
  \ 'h': "<head>\r</head>",
  \ 'm': "<body>\r</body>",
  \ 'f': "<footer>\r</footer>",
  \ 'p': "<p>\r</p>",
  \ 'i': "<i>\r</i>",
  \ 'o': "<b>\r</b>",
  \ 'e': "<em>\r</em>",
  \ 's': "<strong>\r</strong>",
  \ 'l': "\1Link: \r..*\r<a href=\"&\">\1\r\1\r..*\r</a>\1",
  \ 'd': "\1Class: \r..*\r<div class=\"&\">\1\r\1\r..*\r</div>\1",
  \ },
  \ 1)
