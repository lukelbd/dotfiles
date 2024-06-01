" Filetype declarations. Add default gitignore and grep ignore files
au BufNewFile,BufRead .gitignore.default,.{,ag,rg,wild}ignore set filetype=gitignore
