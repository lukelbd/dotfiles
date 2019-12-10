"------------------------------------------------------------------------------"
" HTML settings
"------------------------------------------------------------------------------"
" Declare command to 'compile' page, i.e. show it in Safari
nnoremap <silent> <buffer> <C-z> :exec("!clear; set -x; open -a Safari ".shellescape(@%))<CR><CR>

" Define HTML vim-surround macros
" TODO: Why don't we put everything in textools plugin in tex.vim file?
if &rtp =~ 'vim-surround'
  function! s:delim(map, start, end) " if final argument passed, this is buffer-local
    let g:surround_{char2nr(a:map)} = a:start . "\r" . a:end
  endfunction
  call s:delim('h', '<head>',   '</head>')
  call s:delim('m', '<body>',   '</body>') " m for main
  call s:delim('f', '<footer>', '</footer>')
  call s:delim('t', '<title>',  '</title>')
  call s:delim('e', '<em>',     '</em>')
  call s:delim('o', '<b>',      '</b>') " o for bold
  call s:delim('i', '<i>',      '</i>')
  call s:delim('s', '<strong>', '</strong>')
  call s:delim('p', '<p>',      '</p>')
  call s:delim('1', '<h1>',     '</h1>')
  call s:delim('2', '<h2>',     '</h2>')
  call s:delim('3', '<h3>',     '</h3>')
  call s:delim('4', '<h4>',     '</h4>')
  call s:delim('5', '<h5>',     '</h5>')
endif
