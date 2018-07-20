"-------------------------------------------------------------------------------
" Simple regex to add comment highlighting to fortran, with strict requirements:
" comments character c must be followed by whitespace, and cannot be a c = assignment
if !exists('b:current_syntax')
  let b:current_syntax = 'fortran'
elseif b:current_syntax !=# 'fortran'
  finish "expr is not equal to, matching case; !=? would test ignoring case
endif
syn match fortranComment excludenl '^\s*[cC]\s\+=\@!.*$' contains=@fortranCommentGroup,@spell
