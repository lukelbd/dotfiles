"Custom filetype declarations, with auto commands specified in .vim/ftplugin
"NCL syntax
au BufRead,BufNewFile *.ncl set filetype=ncl
" au! Syntax newlang source $VIM/ncl.vim
  "I'm supposed to also add the above line; but doesn't seem to do anything
"NCL completion for its weird functions
" set complete-=k complete+=k " Add dictionary search (as per dictionary option)
" au BufRead,BufNewFile *.ncl set dictionary=~/.vim/words/ncl.dic
" au FileType * execute 'setlocal dict+=~/.vim/words/'.&filetype.'.dic'

