"------------------------------------------------------------------------------"
" NCL settings
"------------------------------------------------------------------------------"
" Highlight builtin NCL commands as keyword by adding dictionary
setlocal commentstring=;%s
setlocal dict+=~/.vim/words/ncl.dic

" Run NCL script
function! s:run_ncl_script()
  update
  exe '!clear; set -x; ncl -n -Q ' . shellescape(@%)
endfunction
nnoremap <silent> <buffer> <C-z> :call <sid>run_ncl_script()<CR>
