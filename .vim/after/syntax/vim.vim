"-----------------------------------------------------------------------------"
" Tweak vim syntax
"-----------------------------------------------------------------------------"
" Convert vim9 strings back into comments
" See: https://github.com/vim/vim/issues/11307
syntax match vimCustomComment /^[ \t:]*".*$/ contains=.*vimComment.* containedin=.*\(Body\|\)
highlight link vimCustomComment vimComment
highlight link vimCommentString vimComment
