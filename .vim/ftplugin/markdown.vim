"-----------------------------------------------------------------------------
" Markdown settings
"-----------------------------------------------------------------------------
" Tab and delimiter settings
let b:delimitMate_quotes = "\" ' $ ` * _"
setlocal tabstop=4  " required for nested bullets
setlocal shiftwidth=4
setlocal softtabstop=4

" Open markdown file in viewer
" Note: This is designed for side-by-side terminal/viewer workflow. See also tex.vim
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
nnoremap <buffer> <Plug>ExecuteFile0 <Cmd>call <sid>open_markdown_file()<CR>

" Add delimiters. Note we generally use multi-markdown instead of github for tex math.
" See: https://github.com/fletcher/MultiMarkdown-4/issues/130
" See: http://fletcher.github.io/MultiMarkdown-4/criticmarkup.html
let b:succinct_delims = {
  \ 't': '<\1<\1>\r</\1\1>',
  \ 'i': '*\r*',
  \ 'o': '**\r**',
  \ '-': '<s>\r</s>',
  \ 'e': '{==\r==}',
  \ 'd': '{--\r--}',
  \ '$': '$$\r$$',
\ }
