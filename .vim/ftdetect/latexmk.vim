" Filetype declaration for latexmk files
augroup latexmk
  au!
  au BufNewFile,BufRead *.latexmk set filetype=latexmk
augroup END
