"-----------------------------------------------------------------------------
" Markdown settings
"-----------------------------------------------------------------------------
" Vim-markdown settings
let g:tex_conceal = ''  " disable math conceal
let g:vim_markdown_math = 1 " turn on $$ math

" DelimitMate plugin
let b:delimitMate_quotes = "\" ' $ ` * _"

" Open markdown files
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
  call popup#job_win(cmd, 0)
endfunction
nnoremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>open_markdown_file()<CR>

" Define markdown vim-surround macros. Note we generally use multi-markdown
" syntax instead of github for improved latex support.
" See: https://github.com/fletcher/MultiMarkdown-4/issues/130
" See: http://fletcher.github.io/MultiMarkdown-4/criticmarkup.html
" \ '-': "~~\r~~",
call succinct#add_delims({
  \ 't': "<\1<\1>\r</\1\1>",
  \ 'i': "*\r*",
  \ 'o': "**\r**",
  \ '-': "<s>\r</s>",
  \ 'e': "{==\r==}",
  \ 'd': "{--\r--}",
  \ '$': "$$\r$$",
  \ },
  \ 1)
