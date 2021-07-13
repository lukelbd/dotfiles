"------------------------------------------------------------------------------"
" NCL settings
"------------------------------------------------------------------------------"
" Comment string
setlocal commentstring=;%s

" Highlight builtin NCL commands as keyword by adding dictionary
setlocal dictionary+=~/.vim/words/ncl.dic

" Run NCL script
function! s:run_ncl_script()
  update
  exe '!clear; set -x; ncl -n -Q ' . shellescape(@%)
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>run_ncl_script()<CR>
