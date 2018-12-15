"------------------------------------------------------------------------------"
"Another simple run-view result mapping
"NOTE: The julia plugin will overwrite some of these, so this must be in
"the 'after/ftplugin' directory instead of 'ftplugin'
set commentstring=#%s
nnoremap <silent> <buffer> <C-z> :update<CR>:exec("!clear; set -x; julia ".shellescape(@%))<CR><CR>
