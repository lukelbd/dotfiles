"-----------------------------------------------------------------------------
" Vim settings
"-----------------------------------------------------------------------------
" General settings
" NOTE: Exclude ':' except for insert mode popup completion
setlocal iskeyword=@,48-57,_,#,192-255

" Delimiter settings
let b:delimitMate_quotes = "'"
let b:delimitMate_matchpairs = '(:),{:},[:],<:>'

" Add mappings (see also python.vim)
noremap <expr> <buffer> <Plug>ExecuteMotion vim#source_motion_expr()
noremap <expr> <buffer> <Plug>ExecuteFile0 vim#source_general_expr()
