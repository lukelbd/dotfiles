"Helper function
"Install viewer script with pip install restview
"WARNING: Must run ! call so we can close the server when done, otherwise
"process hangs and freezes the window!
function! s:rst_open()
  update
  exe "!~/miniconda3/bin/restview -b -l 40000 ".shellescape(@%)
endfunction
nnoremap <silent> <buffer> <C-z> :call <sid>rst_open()<CR>
