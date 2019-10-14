"-----------------------------------------------------------------------------"
" Unite.vim plugin popup window settings
"-----------------------------------------------------------------------------"
" Pseudo fuzzy matching but still sucks
" See Github issue: https://github.com/Shougo/unite.vim/issues/276
call unite#filters#sorter_default#use(['sorter_rank'])
" Declare specific mappings
nmap <buffer> q <Plug>(unite_exit)a
nmap <buffer> <C-g> <Plug>(unite_exit)a
nmap <buffer> <Tab> <Plug>(unite_choose_action)a
imap <buffer> <CR> <Plug>(unite_do_default_action)a
imap <buffer> q i_<Plug>(unite_exit)a
imap <buffer> <C-g> i_<Plug>(unite_exit)a
imap <buffer> <Tab> i_<Plug>(unite_choose_action)a
" Disable some normal insert mode features
" Basically make popup menu behave more like FZF
" silent! iunmap <buffer> <C-c>
inoremap <buffer> <C-c> <Esc>:q<CR>
inoremap <buffer> <Esc> <Esc>:q<CR>
