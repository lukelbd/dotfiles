"Custom filetype declarations, with auto commands specified in .vim/ftplugin
"Include GFDL diagnostic tables here, just because they use '#' for comment
autocmd BufNewFile,BufRead *.bash,*.sh,*.zsh,diag_table* set filetype=sh
