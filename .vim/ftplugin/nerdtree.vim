"-----------------------------------------------------------------------------"
" Misc settings
"-----------------------------------------------------------------------------"
setlocal nolist nonumber norelativenumber
if (v:version >= 704 || v:version == 703 && has('patch1261'))
  nmap <buffer> <nowait> d D
endif
