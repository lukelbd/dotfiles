"------------------------------------------------------------------------------"
" Override the default git-gutter updating behavior. Prevents dependence on
" cursorhold events. Otherwise have to use e.g. 100ms which can cause lags.
"------------------------------------------------------------------------------"
augroup gitgutter
  au!
  let cmds = (exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave')
  exe 'au BufReadPost,BufWritePost,' . cmds . ' * GitGutter'
augroup END
