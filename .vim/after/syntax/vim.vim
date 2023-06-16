"-----------------------------------------------------------------------------"
" Convert vim9 strings back into comments
" See: https://github.com/vim/vim/issues/11307
"-----------------------------------------------------------------------------"
syntax match customComment /^[ \t:]*".*$/ contains=.*vimComment.* containedin=.*\(Body\|\)
highlight link customComment vimComment
highlight link vimCommentString vimComment