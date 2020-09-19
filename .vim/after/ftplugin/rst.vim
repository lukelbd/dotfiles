"-----------------------------------------------------------------------------"
" ReST settings
" This is in after for consistency with markdown.vim
"-----------------------------------------------------------------------------"
" DelimitMate delimiters
let b:delimitMate_quotes = "\" ' $ `"

" Opening files. Install viewer script with pip install restview.
" Warning: Must run ! call so we can close the server when done, otherwise
" process hangs and freezes the window!
function! s:open_rst_file()
  update
  exe '!~/miniconda3/bin/restview -b -l 40000 ' . shellescape(@%)
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>open_rst_file()<CR>
