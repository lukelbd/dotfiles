"This disables the default git-gutter updating behavior, to make it
"a bit more calm. Find CursorHold annoying.
augroup gitgutter
  au!
  let autocmds="InsertLeave"
  if exists("##TextChanged") | let autocmds.=",TextChanged" | endif
  exe "au ".autocmds." * GitGutter"
augroup END
