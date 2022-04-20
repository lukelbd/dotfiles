" Filetype declarations. Include vaguely shell-like files where '#' is the comment
" character, e.g. GFDL diagnostic tables and HPC batch file instructions.
au BufNewFile,BufRead *.rvmrc,*.{pbs,slurm},*.{,p,s}batch,*.{cdo,nco},*.ncap{,2},diag_table* set filetype=sh
