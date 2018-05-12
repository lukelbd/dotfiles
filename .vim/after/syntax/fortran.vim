"-------------------------------------------------------------------------------
"-------------------------------------------------------------------------------
"-------------------------------------------------------------------------------
" NEW SYNTAX FILE
" DONWLOADED: 2018-02-20
" From this thread, enables 'c' comments: from https://stackoverflow.com/q/11903166
if !exists('b:current_syntax')
  let b:current_syntax = 'fortran'
elseif b:current_syntax !=# 'fortran'
  finish "expr is not equal to, matching case; !=? would test ignoring case
endif
syn match fortranComment excludenl "^[!c*].*$" contains=@fortranCommentGroup,@spell
syn match fortranComment excludenl "!.*$" contains=@fortranCommentGroup,@spell
