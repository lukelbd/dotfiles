"-----------------------------------------------------------------------------"
" Utilities for setting up windows
"-----------------------------------------------------------------------------"
" Helper function
function! s:no_buffer_map(map)
  let dict = maparg(a:map, 'n', v:false, v:true)
  return empty(dict) || !dict['buffer']
endfunction

" Setup popup windows
" File mode can be 0 (no file) 1 (simple file) or 2 (editable file)
" Warning: Critical error happens if try to auto-quite when only popup window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with file#tab_close().
function! setup#popup_win(...) abort
  let filemode = a:0 ? a:1 : 1
  if s:no_buffer_map('q') | nnoremap <silent> <buffer> q :call file#close_window()<CR> | endif
  if s:no_buffer_map('<C-w>') | nnoremap <silent> <buffer> <C-w> :call file#close_window()<CR> | endif
  setlocal nolist nonumber norelativenumber nocursorline colorcolumn=
  if filemode == 0 | setlocal buftype=nofile | endif  " this has no file
  if filemode == 2 | return | endif  " this is editable file
  setlocal nospell statusline=%{'[Popup\ Window]'}%=%{PrintLoc()}  " additional settings
  if s:no_buffer_map('u') | nnoremap <buffer> u <C-u> | endif
  if s:no_buffer_map('d') | nnoremap <buffer> <nowait> d <C-d> | endif
  if s:no_buffer_map('b') | nnoremap <buffer> b <C-b> | endif
  if s:no_buffer_map('f') | nnoremap <buffer> <nowait> f <C-f> | endif
endfunction

" Setup command windows, make sure local maps work
" Note: Here 'execute' means run the selected line
function! setup#cmd_win() abort
  inoremap <buffer> <expr> <CR> ""
  nnoremap <buffer> <CR> <C-c><CR>
  nnoremap <buffer> <Plug>Execute0 <C-c><CR>
  silent call setup#popup_win()
endfunction

" Setup help windows
function! setup#help_win() abort
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
  silent call setup#popup_win()
endfunction

" Setup job popup window
" Note: The '.log' extension should trigger popup.
" Note: Add 'set -x' to display commands and no-op ':' to signal completion.
" Note: The '/bin/sh' is critical to permit chained commands e.g. with && or
" || otherwise they are interpreted as literals.
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')  " copied from autoreload/plug.vim
function! setup#job_win(cmd, ...) abort
  if !s:vim8
    echohl ErrorMsg
    echom 'Error: Running jobs requires vim >= 8.0'
    echohl None
    return 1
  endif
  let opts = {}  " job options, empty by default
  let show = a:0 ? a:1 : 1
  if show  " show popup window
    let logfile = expand('%:t:r') . '.log'
    let lognum = bufwinnr(logfile)
    if lognum == -1  " open a logfile window
      silent! exe string(winheight('.') / 4) . 'split ' . logfile
      silent! exe winnr('#') . 'wincmd w'
    else  " jump to logfile window and clean its contents
      silent! exe bufwinnr(logfile) . 'wincmd w'
      silent! 1,$d _
      silent! exe winnr('#') . 'wincmd w'
    endif
    let num = bufnr(logfile)
    let opts = {'out_io': 'buffer', 'out_buf': num, 'err_io': 'buffer', 'err_buf': num}
  endif
  let b:run_job = job_start(['/bin/sh', '-c', 'set -x; ' . a:cmd . '; :'], opts)
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

" Custom codi window autocommands Want TextChanged,InsertLeave, not
" TextChangedI which is enabled with g:codi#autocmd = 'TextChanged'
" See: https://github.com/metakirby5/codi.vim/issues/90
function! setup#codi_win(toggle) abort
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
