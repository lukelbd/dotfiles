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
function! popup#popup_win(...) abort
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

" Setup command windows and ensure local maps work
" Note: Here 'execute' means run the selected line
function! popup#cmd_win() abort
  inoremap <buffer> <expr> <CR> ""
  nnoremap <buffer> <CR> <C-c><CR>
  nnoremap <buffer> <Plug>ExecuteFile1 <C-c><CR>
  silent call popup#popup_win()
endfunction

" Setup new codi window
function! popup#codi_new(...) abort
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
function! popup#codi_win(toggle) abort
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

" Pre-processor fixes escapes returned by interpreters. For the
" escape issue see: https://github.com/metakirby5/codi.vim/issues/120
function! popup#codi_preprocess(line) abort
  return substitute(a:line, '�[?2004l', '', '')
endfunction

" Rephraser to remove comment characters before passing to interpreter. For the
" 1000 char limit issue see: https://github.com/metakirby5/codi.vim/issues/88
" Warning: Vim substitute() function works differently fron :substitute command, with
" escape characters disallowed in [] (requires literals) and '.' matching newlines.
" Also codi silently fials if rephrased input lines don't match original line count.
function! popup#codi_rephrase(text) abort
  let text = substitute(a:text, utils#comment_char() . "[^\n]*\\(\n\\|$\\)", '\1', 'g')
  if len(text) > 1000
    echohl WarningMsg
    echom 'Warning: Too many characters for calculator. Truncating the input.'
    echohl None
  endif
  return text
endfunction

" Information about syntax and colors
" The show commands produce popup windows
function! popup#current_syntax(name) abort
  if a:name
    exe 'verb syntax list ' . a:name
  else
    exe 'verb syntax list ' . synIDattr(synID(line('.'), col('.'), 0), 'name')
  endif
endfunction
function! popup#current_group() abort
  let names = []
  for id in synstack(line('.'), col('.'))
    let name = synIDattr(id, 'name')
    let group = synIDattr(synIDtrans(id), 'name')
    if name != group
      let name .= ' (' . group . ')'
    endif
    let names += [name]
  endfor
  echo join(names, ', ')
endfunction
function! popup#show_plugin() abort
  execute 'split $VIMRUNTIME/ftplugin/' . &filetype . '.vim'
  silent call popup#popup_setup()
endfunction
function! popup#show_syntax() abort
  execute 'split $VIMRUNTIME/syntax/' . &filetype . '.vim'
  silent call popup#popup_setup()
endfunction
function! popup#show_colors() abort
  source $VIMRUNTIME/syntax/colortest.vim
  silent call popup#popup_setup()
endfunction

" Show command help
" Note: This is low-level companion to high-level vim-lsp features
function! popup#help_flag(...) abort
  if a:0
    let cmd = a:1
  else
    let cmd = input('Get --help info: ', expand('<cword>'), 'shellcmd')
  endif
  if !empty(cmd)
    silent! exe '!clear; '
      \ . 'search=' . cmd . '; '
      \ . 'if [ -n $search ] && builtin help $search &>/dev/null; then '
      \ . '  builtin help $search 2>&1 | less; '
      \ . 'elif $search --help &>/dev/null; then '
      \ . '  $search --help 2>&1 | less; '
      \ . 'fi'
    if v:shell_error != 0
      echohl WarningMsg
      echom "Warning: 'man " . cmd . "' failed."
      echohl None
    endif
  endif
endfunction

" Show command manual
" Note: This is low-level companion to high-level vim-lsp features
function! popup#help_man(...) abort
  if a:0
    let cmd = a:1
  else
    let cmd = input('Get man page: ', expand('<cword>'), 'shellcmd')
  endif
  if !empty(cmd)
    silent! exe '!clear; '
      \ . 'search=' . cmd . '; '
      \ . 'if [ -n $search ] && command man $search &>/dev/null; then '
      \ . '  command man $search; '
      \ . 'fi'
    if v:shell_error != 0
      echohl WarningMsg
      echom "Warning: '" . cmd . " --help' failed."
      echohl None
    endif
  endif
endfunction

" Show vim help window
" Note: This is low-level companions to fzf feature
function! popup#help_vim(...) abort
  if a:0
    let item = a:1
  else
    let item = input('Vim help item: ', '', 'help')
  endif
  if !empty(item)
    exe 'vert help ' . item
  endif
endfunction

" Setup help windows
function! popup#help_win() abort
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
  silent call popup#popup_win()
endfunction

" Setup job popup window
" Note: The '.log' extension should trigger popup.
" Note: Add 'set -x' to display commands and no-op ':' to signal completion.
" Note: The '/bin/sh' is critical to permit chained commands e.g. with && or
" || otherwise they are interpreted as literals.
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')  " copied from autoreload/plug.vim
function! popup#job_win(cmd, ...) abort
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
  let b:popup_job = job_start(['/bin/sh', '-c', 'set -x; ' . a:cmd . '; :'], opts)
endfunction
