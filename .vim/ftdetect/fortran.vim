"Declaration for Fortran-type files
"Includes all fortran files, 'include' files (accessed by include "file.inc", for
"sharing code snippets in different places), and namelist files.
autocmd BufNewFile,BufRead *.f,*.F,*.[fF][0-9][0-9],*.inc,*.nml set filetype=fortran

