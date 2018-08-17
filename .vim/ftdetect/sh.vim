"Custom filetype declarations, with auto commands specified in .vim/ftplugin
"Include some misc files where we want to use '#' for comments (e.g. GFDL
"diagnostic tables and experiment tables), and batch files for HPC submissions.
autocmd BufNewFile,BufRead 
  \ *.batch,*.sbatch,*.bash,*.ksh,*.zsh,*.sh,*.fish,diag_table*,experiments*
  \ set filetype=sh