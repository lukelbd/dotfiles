" Filetype declarations. Add fixed width and table files
au BufNewFile,BufRead *.{dat,data,tab,table}{,.txt},*_{*Data,event,month}.txt set filetype=csv
