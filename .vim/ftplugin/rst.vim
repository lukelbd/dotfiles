"-----------------------------------------------------------------------------"
" ReST settings
"-----------------------------------------------------------------------------"
" DelimitMate plugin
let b:delimitMate_quotes = "\" ' $ `"

" Opening files. Install viewer script with pip install restview.
" Warning: Must run ! call so we can close the server when done, otherwise
" process hangs and freezes the window!
function! s:open_rst_file()
  update
  let cmd = '~/miniconda3/bin/restview -b -l 40000 ' . shellescape(@%)
  call setup#job_win(cmd, 0)  " without display window
endfunction
nnoremap <silent> <buffer> <Plug>Execute0 :call <sid>open_rst_file()<CR>
