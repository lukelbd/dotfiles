" Filetype declarations. Include namelist files and 'include' files (which can be
" loaded and read as if they were inserted in the document).
au BufNewFile,BufRead
  \ *.f,*.F,*.f[0-9][0-9],*.F[0-9][0-9],*.inc,*.nml,INPUT*
  \ set filetype=fortran
