"-----------------------------------------------------------------------------
" Vim settings
"-----------------------------------------------------------------------------
" General settings
" Note: For most filetypes not necessary to set foldmethod but for some reason required
" for vim. Also setglobal foldmethod=syntax at top of vimrc did not work. Revisit.
setlocal iskeyword=@,48-57,_,#,192-255
setlocal foldmethod=syntax

" Delimiter settings
let b:delimitMate_quotes = "'"
let b:delimitMate_matchpairs = '(:),{:},[:],<:>'

" Add mappings (see also python.vim)
noremap <expr> <buffer> <Plug>ExecuteMotion vim#source_motion_expr()
noremap <buffer> <Plug>ExecuteFile0 <Cmd>call vim#source_general()<CR>
