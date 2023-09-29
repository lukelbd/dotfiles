"-----------------------------------------------------------------------------"
" Tweak markdown syntax
"-----------------------------------------------------------------------------"
" Re-enforce fold text overwritten by $RUNTIME syntax/markdown and syntax/javascript
setlocal foldtext=fold#fold_text()

" Re-apply folds (refreshing vim session seems to delete them)
doautocmd BufWritePost
