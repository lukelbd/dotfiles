"-----------------------------------------------------------------------------"
" Utilities for setting up windows
"-----------------------------------------------------------------------------"
" For popup windows
" File mode can be 0 (no file) 1 (simple file) or 2 (editable file)
" Warning: Critical error happens if try to auto-quite when only popup window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with file#tab_close().
function! s:no_buffer_map(map)
  let dict = maparg(a:map, 'n', v:false, v:true)
  return empty(dict) || !dict['buffer']
endfunction
function! setup#popup(...) abort
  let filemode = a:0 ? a:1 : 1
  if s:no_buffer_map('q') | nnoremap <silent> <buffer> q :call file#close_window()<CR> | endif
  if s:no_buffer_map('<C-w>') | nnoremap <silent> <buffer> <C-w> :call file#close_window()<CR> | endif
  setlocal nolist nonumber norelativenumber nocursorline colorcolumn=
  if filemode == 0 | setlocal buftype=nofile | endif  " this has no file
  if filemode == 2 | return | endif  " this is editable file
  setlocal nospell statusline=%{''}  " additional settings
  if s:no_buffer_map('u') | nnoremap <buffer> u <C-u> | endif
  if s:no_buffer_map('d') | nnoremap <buffer> <nowait> d <C-d> | endif
  if s:no_buffer_map('b') | nnoremap <buffer> b <C-b> | endif
  if s:no_buffer_map('f') | nnoremap <buffer> <nowait> f <C-f> | endif
endfunction

" For help windows
function! setup#help() abort
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
  silent call setup#popup()
endfunction

" For command windows, make sure local maps work
function! setup#cmdwin() abort
  inoremap <buffer> <expr> <CR> ""
  nnoremap <buffer> <CR> <C-c><CR>
  nnoremap <buffer> <Plug>Execute <C-c><CR>
  silent call setup#popup()
endfunction

" Setup new codi window
function! setup#codi_new(...) abort
  if a:0 && a:1 !~# '^\s*$'
    let name = a:1
  else
    let name = input('Calculator name (' . getcwd() . '): ', '', 'file')
  endif
  if name !~# '^\s*$'
    exe 'tabe ' . fnamemodify(name, ':r') . '.py'
    Codi!!
  endif
endfunction

" Custom codi window autocommands
" See: https://github.com/metakirby5/codi.vim/issues/90
" Want TextChanged and InsertLeave, not TextChangedI which is enabled when
" setting g:codi#autocmd to 'TextChanged'.
function! setup#codi_window(toggle) abort
  if a:toggle
    let cmds = exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave'
    exe 'augroup codi_' . bufnr('%')
      au!
      exe 'au ' . cmds . ' <buffer> call codi#update()'
    augroup END
  else
    exe 'augroup codi_' . bufnr('%')
      au!
    augroup END
  endif
endfunction
