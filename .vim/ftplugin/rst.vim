"-----------------------------------------------------------------------------
" ReST settings
"-----------------------------------------------------------------------------
" Open primary header folds on startup
" Note: Not possible to set foldlevelstart=1 for specific filetype
if &l:foldlevel == 0 | let &l:foldlevel = 1 | endif

" DelimitMate plugin
let b:delimitMate_quotes = "\" ' $ `"

" Opening files. Install viewer script with pip install restview.
" Warning: Must run ! call so we can close the server when done, otherwise
" process hangs and freezes the window!
function! s:open_rst_file() abort
  update
  let cmd = '~/miniconda3/bin/restview -b -l 40000 ' . shellescape(@%)
  call shell#job_win(cmd, 0)  " without display window
endfunction
nnoremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>open_rst_file()<CR>
