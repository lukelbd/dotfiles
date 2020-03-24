" Include some misc files where we want to use '#' for comments (e.g. GFDL
" diagnostic tables and experiment tables), and batch files for HPC submissions
" with SLURM manager (Midway, Geyser, Yellowstone) or PBS system (Cheyenne)
autocmd BufNewFile,BufRead 
  \ .bashrc,.rvmrc,*.batch,*.sbatch,*.pbs,*.bash,*.ksh,*.zsh,*.sh,*.fish,*.cdo,*.nco,diag_table*
  \ set filetype=sh
