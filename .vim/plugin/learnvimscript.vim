"From learn vimscript the hard way examples
"Source: http://learnvimscriptthehardway.stevelosh.com/chapters/34.html
"This shit doesn't work
" nnoremap <leader>g :set operatorfunc=GrepOperator<cr>g@
" vnoremap <leader>g :<c-u>call GrepOperator(visualmode())<cr>
" function! GrepOperator(type)
"   let saved_unnamed_register = @@
"   if a:type ==# 'v'
"       normal! `<v`>y
"   elseif a:type ==# 'char'
"       normal! `[y`]
"   else
"       return
"   endif
"   silent execute "grep! -R " . shellescape(@@) . " ."
"   copen
"   let @@ = saved_unnamed_register
" endfunction
