"Custom filetype declarations, with auto commands specified in .vim/ftplugin
"Include fortran diagnostic tables here
autocmd BufNewFile,BufRead *.bash,*.sh,*.zsh,diag_table* set filetype=sh
