"Custom filetype declarations, with auto commands specified in .vim/ftplugin
"Declaration for Fortran-type files
" autocmd BufNewFile,BufRead,TabEnter,WinEnter *.f,*.F,*.f[0-9][0-9],*.F[0-9][0-9] set filetype=fortran
autocmd BufNewFile,BufRead *.f,*.F,*.f[0-9][0-9],*.F[0-9][0-9] set filetype=fortran

