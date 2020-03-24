"------------------------------------------------------------------------------"
" HTML settings
"------------------------------------------------------------------------------"
" Declare command to 'compile' page, i.e. show it in Safari
nnoremap <silent> <buffer> <C-z> :exec("!clear; set -x; open -a Safari ".shellescape(@%))<CR><CR>

" Define HTML vim-surround macros
" Todo: Why don't we put everything in textools plugin in tex.vim file?
if &rtp =~ 'vim-surround'
  " HTML tools
  " Todo: Understand example from documentation:
  " "<div\1id: \r..*\r id=\"&\"\1>\r</div>"
  let s:htmltools_surround = {
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
  for [s:binding, s:pair] in items(s:htmltools_surround)
    let [s:left, s:right] = s:pair
    let b:surround_{char2nr(s:binding)} = s:left . "\r" . s:right
  endfor
endif
