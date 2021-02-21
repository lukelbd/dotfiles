"------------------------------------------------------------------------------"
" HTML settings
"------------------------------------------------------------------------------"
" DelimitMate plugin
let b:delimitMate_matchpairs = '(:),{:},[:],<:>'

" Declare command to "compile' page, i.e. show it in Safari
function! s:open_html_file()
  update
  exe '!clear; set -x; open -a Safari ' . shellescape(@%)
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>open_html_file()

" Define HTML vim-surround macros
" Todo: Put everything in textools ftplugin files
if &runtimepath =~# 'vim-surround'
  let s:html_surround = {
    \ 't': "<\1<\1>\r</\1\1>",
    \ 'd': "<div>\r</div>",
    \ 'h': "<head>\r</head>",
    \ 'm': "<body>\r</body>",
    \ 'f': "<footer>\r</footer>",
    \ 'T': "<title>\r</title>",
    \ 'e': "<em>\r</em>",
    \ 'o': "<b>\r</b>",
    \ 'i': "<i>\r</i>",
    \ 's': "<strong>\r</strong>",
    \ 'p': "<p>\r</p>",
    \ '1': "<h1>\r</h1>",
    \ '2': "<h2>\r</h2>",
    \ '3': "<h3>\r</h3>",
    \ '4': "<h4>\r</h4>",
    \ '5': "<h5>\r</h5>",
  \ }
  for [s:binding, s:pair] in items(s:html_surround)
    let b:surround_{char2nr(s:binding)} = s:pair
  endfor
endif
