"-----------------------------------------------------------------------------"
" Markdown settings
" HTML ftplugin file gets sourced after markdown syntax file is sourced, so put
" this in after so we can override HTML settings.
"-----------------------------------------------------------------------------"
" Vim-markdown settings
let g:tex_conceal = ''  " disable math conceal
let g:vim_markdown_math = 1 " turn on $$ math

" DelimitMate plugin
let b:delimitMate_quotes = "\" ' $ ` * _"

" Open markdown files
function! s:open_markdown_file()
  update
  if $TERM_PROGRAM ==? ''
    let terminal = 'MacVim'
  elseif $TERM_PROGRAM =~? 'Apple_Terminal'
    let terminal = 'Terminal'
  else
    let terminal = $TERM_PROGRAM
  endif
  call system(
    \ 'open -a "Marked 2" ' . shellescape(@%) . "&\n"
    \ . 'open -a "'.terminal.'" &'
    \ )
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>open_markdown_file()<CR>

" Define markdown vim-surround macros
" Todo: Put everything in textools ftplugin files
" Todo: Understand example from documentation:
" "<div\1id: \r..*\r id=\"&\"\1>\r</div>"
if &runtimepath =~# 'vim-surround'
  let s:markdown_surround = {
    \ 'i': ['*',  '*'],
    \ 'o': ['**', '**'],
    \ '-': ['~~',  '~~'],
  \ }
  for [s:binding, s:pair] in items(s:markdown_surround)
    let [s:left, s:right] = s:pair
    let b:surround_{char2nr(s:binding)} = s:left . "\r" . s:right
  endfor
endif
