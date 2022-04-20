" Filetype declarations. Include namelist files and 'include' files
" which are loaded and read as if they were inserted in the document.
au BufNewFile,BufRead *.[fF],*.[fF][0-9][0-9],*.inc,*.nml set filetype=fortran
