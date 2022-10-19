"-----------------------------------------------------------------------------"
" Add comment highlighting to fortran with strict requirements
" Character c must be followed by whitespace and cannot be a c = assignment
"-----------------------------------------------------------------------------"
syn match fortranComment excludenl '^\s*[cC]\s\+=\@!.*$' contains=@spell,@fortranCommentGroup
