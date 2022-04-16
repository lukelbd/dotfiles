"-----------------------------------------------------------------------------"
" Vim settings
"-----------------------------------------------------------------------------"
" DelimitMate settings
let b:delimitMate_quotes = "'"
let b:delimitMate_matchpairs = '(:),{:},[:],<:>'

" Source current vim script
function! s:source_vim_script()
  update
  source %
  echo 'Sourced ' . expand('%:p:t')
endfunction
nnoremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>source_vim_script()<CR>
