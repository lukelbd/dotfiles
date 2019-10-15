"-----------------------------------------------------------------------------"
" Settings for .bib BibTeX files
"-----------------------------------------------------------------------------"
" Add regexes that filter out useless bibtex entries
nnoremap <silent> <buffer> \x :%s/^\s*\(abstract\\|file\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=\s*{\_.\{-}},\?\n//gc<CR>
nnoremap <silent> <buffer> \X :%s/^\s*\(abstract\\|language\\|file\\|doi\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=\s*{\_.\{-}},\?\n//gc<CR>

