"-----------------------------------------------------------------------------"
" Tweak javascript syntax
"-----------------------------------------------------------------------------"
" Re-enforce fold text overwritten by $RUNTIME syntax/javascript
setlocal foldtext=fold#fold_text()

" Re-apply folds (refreshing vim session seems to delete them)
doautocmd BufWritePost
