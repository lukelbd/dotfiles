"LaTeX filetype detection for custom formatting and custom FileType commands
" au BufRead,BufNewFile,TabEnter,WinEnter *.aux,*.tex,*.bib,*.bbl,*.sty,*.cls,*.toc,*.lot,*.lof,*.bst set filetype=tex
" au BufRead,BufNewFile,TabEnter,WinEnter *.aux,*.bst,*.cls,*.sty,*.tex,*.bbl,*.toc,*.lot,*.lof set filetype=tex
" au BufRead,BufNewFile,TabEnter,WinEnter *.tex,*.bbl,*.toc,*.lot,*.lof set filetype=tex
au BufRead,BufNewFile *.tex,*.bbl,*.toc,*.lot,*.lof set filetype=tex
