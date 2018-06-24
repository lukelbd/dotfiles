"------------------------------------------------------------------------------"
"Highlight builtin NCL commands by adding this dictionary to
"the dictionary; not sure how it works. From NCL UCAR page VIM recommendations.
"------------------------------------------------------------------------------"
setlocal dict+=~/.vim/words/ncl.dic
" augroup ncl
"   au!
"   au FileType * execute 'setlocal dict+=~/.vim/words/'.&ft.'.dic'
" augroup END
" set complete-=k complete+=k " Add dictionary search (as per dictionary option)
" au BufRead,BufNewFile *.ncl set dictionary=~/.vim/words/ncl.dic
