"------------------------------------------------------------------------------"
" Override the default git-gutter updating behavior. Prevents dependence on
" cursorhold events. Otherwise have to use e.g. 100ms which can cause lags.
"------------------------------------------------------------------------------"
augroup gitgutter
  au!
  let autocmds = 'BufRead,BufWritePost,InsertLeave'
  if exists('##TextChanged') | let autocmds .= ',TextChanged' | endif
  exe 'au ' . autocmds . ' * GitGutter'
augroup END
