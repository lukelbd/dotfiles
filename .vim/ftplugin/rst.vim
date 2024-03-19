"-----------------------------------------------------------------------------
" ReST settings
"-----------------------------------------------------------------------------
" Tab and delimiter settings
let b:delimitMate_quotes = "\" ' $ `"
setlocal tabstop=4  " required for nested bullets
setlocal shiftwidth=4
setlocal softtabstop=4

" Open rest file in viewer (install with 'pip install restview')
" Warning: Use ! call so we can close the server when done, otherwise freezes window
function! s:open_rst_file() abort
  update
  let cmd = '~/miniconda3/bin/restview -b -l 40000 ' . shellescape(@%)
  call shell#job_win(cmd, 0)  " without display window
endfunction
nnoremap <buffer> <Plug>ExecuteFile0 <Cmd>call <sid>open_rst_file()<CR>
