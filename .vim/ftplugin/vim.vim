"-----------------------------------------------------------------------------
" Vim settings
"-----------------------------------------------------------------------------
" DelimitMate settings
let b:delimitMate_quotes = "'"
let b:delimitMate_matchpairs = '(:),{:},[:],<:>'
setlocal iskeyword=@,48-57,_,192-255,#

" Add mappings (see also python.vim)
noremap <expr> <buffer> <Plug>ExecuteMotion vim#source_motion_expr()
noremap <buffer> <Plug>ExecuteFile1 <Cmd>call vim#source_content()<CR>
