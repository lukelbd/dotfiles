"Custom filetype declarations, with auto commands specified in .vim/ftplugin
"Include GFDL diagnostic tables here, just because they use '#' for comment
"Also include sbatch and batch files for HPC submission files
autocmd BufNewFile,BufRead *.batch,*.sbatch,*.bash,*.ksh,*.zsh,*.sh,*.fish,diag_table* set filetype=sh
