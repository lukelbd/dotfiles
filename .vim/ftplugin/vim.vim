"-----------------------------------------------------------------------------
" Vim settings
"-----------------------------------------------------------------------------
" General settings
" Note: For most filetypes not necessary to set foldmethod but for some reason
" this does seem to be necessary in vim.
" some reason have to explicitly set foldmethod=syntax here or functions,
" augroups, etc. not folded automatically. FastFold still works and will still
" auto-toggle between 'syntax' and 'manual' afterward.
" Not necessary for other filetypes. Also
" not sure why but have to re-assert '#' as keyword character here.
setlocal iskeyword=@,48-57,_,192-255,#
" setlocal foldmethod=syntax

" DelimitMate settings
let b:delimitMate_quotes = "'"
let b:delimitMate_matchpairs = '(:),{:},[:],<:>'

" Add mappings (see also python.vim)
noremap <expr> <buffer> <Plug>ExecuteMotion vim#source_motion_expr()
noremap <buffer> <Plug>ExecuteFile1 <Cmd>call vim#source_content()<CR>
