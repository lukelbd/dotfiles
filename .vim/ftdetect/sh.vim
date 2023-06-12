" Filetype declarations. Include shell-like files where '#' is the comment
" character e.g. GFDL diagnostic tables and HPC batch file instructions.
au BufNewFile,BufRead {.,}rvmrc*,{.,}bashrc*,{.,}bash_profile*,diag_table*,*.{pbs,slurm},*.{,p,s}batch,*.{cdo,nco},*.ncap{,2} set filetype=sh
