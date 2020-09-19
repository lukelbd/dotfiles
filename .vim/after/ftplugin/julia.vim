" Another simple run/view-result mapping
" NOTE: The julia plugin will overwrite some of these, so this must be in
" the 'after/ftplugin' directory instead of 'ftplugin'
set commentstring=#%s
function! s:run_julia_script()
  update
  exe '!clear; set -x; julia ' . shellescape(@%)
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>run_julia_script()<CR>
