"Custom filetype declarations, with auto commands specified in .vim/ftplugin
"Include namelist files and 'include' files (which can be loaded and read as if 
"they were inserted in the document)
autocmd BufNewFile,BufRead *.f,*.F,*.f[0-9][0-9],*.F[0-9][0-9],*.inc,*.nml set filetype=fortran

