"-------------------------------------------------------------------------------
" Simple regex to add comment highlighting to fortran, with strict requirements:
" comments character c must be followed by whitespace, and cannot be a c = assignment
"-------------------------------------------------------------------------------
syn match fortranComment excludenl '^\s*[cC]\s\+=\@!.*$' contains=@fortranCommentGroup,@spell
