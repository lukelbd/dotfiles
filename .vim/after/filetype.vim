"-----------------------------------------------------------------------------"
" Override filetype and syntax settings
" See: https://stackoverflow.com/a/4301809/4970632
"-----------------------------------------------------------------------------"
augroup filetype_overrides
  au!
  au BufNewFile,BufRead * source ~/.vim/after/common.vim
augroup END
