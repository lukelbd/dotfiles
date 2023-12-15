"-----------------------------------------------------------------------------
" Markdown settings
"-----------------------------------------------------------------------------
" Delimit-mate settings
let b:delimitMate_quotes = "\" ' $ ` * _"

" Open markdown file in viewer
function! s:open_markdown_file() abort
  update
  if $TERM_PROGRAM ==? ''
    let terminal = 'MacVim'
  elseif $TERM_PROGRAM =~? 'Apple_Terminal'
    let terminal = 'Terminal'
  else
    let terminal = $TERM_PROGRAM
  endif
  let cmd = 'open -a "Marked 2" ' . shellescape(@%) . ' && open -a "' . terminal . '"'
  call shell#job_win(cmd, 0)
endfunction
nnoremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>open_markdown_file()<CR>

" Add delimiters. Note we generally use multi-markdown instead of github for tex math.
" See: https://github.com/fletcher/MultiMarkdown-4/issues/130
" See: http://fletcher.github.io/MultiMarkdown-4/criticmarkup.html
let s:delims = {
  \ 't': '<\1<\1>\r</\1\1>',
  \ 'i': '*\r*',
  \ 'o': '**\r**',
  \ '-': '<s>\r</s>',
  \ 'e': '{==\r==}',
  \ 'd': '{--\r--}',
  \ '$': '$$\r$$',
  \ }
call succinct#add_delims(s:delims, 1)
