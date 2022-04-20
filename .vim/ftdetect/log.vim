" Filetype declarations. Include popups that otherwise have no filetype.
au BufNewFile,BufRead *.log,*.info,__LSP_SETTINGS__* set filetype=log
