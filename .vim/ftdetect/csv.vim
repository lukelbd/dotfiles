" Filetype declarations. Add fixed width and table files
" character e.g. GFDL diagnostic tables and HPC batch file instructions.
au BufNewFile,BufRead *.{dat,data,tab,table}{,.txt},*_{*Data,event,month}.txt set filetype=csv_whitespace
