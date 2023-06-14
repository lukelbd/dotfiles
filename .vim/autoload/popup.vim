"-----------------------------------------------------------------------------"
" Utilities for setting up windows
"-----------------------------------------------------------------------------"
" Update encoding for special character
scriptencoding utf-8

" Setup popup windows. Mode can be 0 (not editable) or 1 (editable).
" Warning: Setting nomodifiable tends to cause errors e.g. for log files run with
" popup#job_win() or other internal stuff. So instead just try to disable normal mode
" commands that could accidentally modify text (aside from d used for scrolling).
" Warning: Critical error happens if try to auto-quit when only popup window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with vim#close_tab().
function! popup#popup_setup(filemode) abort
  nnoremap <silent> <buffer> q :call vim#close_window()<CR>
  nnoremap <silent> <buffer> <C-w> :call vim#close_window()<CR>
  setlocal nolist nonumber norelativenumber nocursorline colorcolumn=
  if &filetype ==# 'qf' | nnoremap <buffer> <CR> <CR> | endif
  if a:filemode == 1 | return | endif  " this is an editable file
  setlocal nospell statusline=%{'[Popup\ Window]'}%=%{StatusRight()}  " additional settings
  for char in 'uUrRxXpPdDaAiIcCoO' | exe 'nmap <buffer> ' char . ' <Nop>' | endfor
  for char in 'dufb' | exe 'map <buffer> <nowait> ' . char . ' <C-' . char . '>' | endfor
endfunction

" Setup command windows and ensure local maps work
" Note: Here 'execute' means run the selected line
function! popup#cmd_setup() abort
  inoremap <buffer> <expr> <CR> ""
  nnoremap <buffer> <CR> <C-c><CR>
  nnoremap <buffer> <Plug>ExecuteFile1 <C-c><CR>
  silent call popup#popup_setup(0)
endfunction

" Popup windows with filetype and color information
function! popup#colors_win() abort
  source $VIMRUNTIME/syntax/colortest.vim
  silent call popup#popup_setup(0)
endfunction
function! popup#plugin_win() abort
  execute 'split $VIMRUNTIME/ftplugin/' . &filetype . '.vim'
  silent call popup#popup_setup(0)
endfunction
function! popup#syntax_win() abort
  execute 'split $VIMRUNTIME/syntax/' . &filetype . '.vim'
  silent call popup#popup_setup(0)
endfunction

" Show and setup vim help page
" Note: This ensures original plugins are present
function! popup#help_page(...) abort
  if a:0
    let item = a:1
  else
    let item = input('Vim help item: ', '', 'help')
  endif
  if !empty(item)
    exe 'vert help ' . item
  endif
endfunction
function! popup#help_setup() abort
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
endfunction

" Show and setup shell man page
" Warning: Calling :Man changes the buffer, so use buffer variables specific to each
" page to record navigation history. Order of assignment below is critical.
" Note: Adapted from vim-superman. The latter runs quit on failure so not viable
" for interactive use during vim sessions. Turns out to be very simple.
function! s:man_cursor() abort
  let bnr = bufnr()
  let curr = b:man_curr
  let page = expand('<cWORD>')  " below copied from highlight group
  let page = substitute(page, '([1-9][a-z]\=)\S*', '', '')
  exe 'Man ' . page
  if bnr != bufnr()  " original buffer
    let b:man_prev = curr
    let b:man_curr = page
  endif
endfunction
function! s:man_jump(forward) abort
  let curr = b:man_curr
  let name = a:forward ? 'man_next' : 'man_prev'
  let page = get(b:, name, '')
  if empty(page) | return | endif
  exe 'Man ' . page
  if a:forward
    let b:man_prev = curr
  else
    let b:man_next = curr
  endif
endfunction
function! popup#man_page() abort
  let file = @%
  let page = input('Man page: ', '', 'shellcmd')
  if empty(page) | return | endif
  tabedit
  set filetype=man
  exe 'Man ' . page
  if line('$') <= 1
    silent! quit
    call file#open_jump(file)
  endif
endfunction
function! popup#man_setup(...) abort
  let b:man_curr = expand('%:t:r')
  noremap <nowait> <buffer> [ <Cmd>call <sid>man_jump(0)<CR>
  noremap <nowait> <buffer> ] <Cmd>call <sid>man_jump(1)<CR>
  noremap <silent> <buffer> <CR> <Cmd>call <sid>man_cursor()<CR>
endfunction

" Print information about syntax group
function! popup#syntax_list(name) abort
  if a:name
    exe 'verb syntax list ' . a:name
  else
    exe 'verb syntax list ' . synIDattr(synID(line('.'), col('.'), 0), 'name')
  endif
endfunction
function! popup#syntax_group() abort
  let names = []
  for id in synstack(line('.'), col('.'))
    let name = synIDattr(id, 'name')
    let group = synIDattr(synIDtrans(id), 'name')
    if name != group | let name .= ' (' . group . ')' | endif
    let names += [name]
  endfor
  echom 'Syntax Group: ' . join(names, ', ')
endfunction

" Setup job popup window
" Note: The '.job' extension should trigger popup windows. Also add 'set -x' to
" display commands and no-op ':' to signal completion.
" Note: The '/bin/sh' is critical to permit chained commands e.g. with && or
" || otherwise they are interpreted as literals.
" Note: Use 'pty' intead of pipe to prevent output buffering and delayed
" printing as a result. See https://vi.stackexchange.com/a/20639/8084
" Note: Job has to be non-local variable or else can terminate
" early when references gone. See https://vi.stackexchange.com/a/22597/8084
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')  " copied from autoreload/plug.vim
function! popup#job_win(cmd, ...) abort
  if !s:vim8
    echohl ErrorMsg
    echom 'Error: Running jobs requires vim >= 8.0'
    echohl None
    return 1
  endif
  let popup = a:0 ? a:1 : 1  " whether to show popup window
  let cmds = ['/bin/sh', '-c', 'set -x; ' . a:cmd . '; :']
  let hght = winheight('.') / 4
  let opts = {}  " job options, empty by default
  if popup  " show popup, or run job
    let logfile = expand('%:t:r') . '.job'
    let lognum = bufwinnr(logfile)
    if lognum == -1  " open a logfile window
      exe hght . 'split ' . logfile
    else  " jump to logfile window and clean its contents
      exe lognum . 'wincmd w' | 1,$d _
    endif
    let num = bufnr(logfile)
    call setbufvar(num, '&buftype', 'nofile')
    let opts = {
      \ 'in_io': 'null',
      \ 'out_io': 'buffer',
      \ 'err_io': 'buffer',
      \ 'out_buf': num,
      \ 'err_buf': num,
      \ 'noblock': 1,
      \ 'pty': 0
      \ }
  endif
  let b:popup_job = job_start(cmds, opts)
  exe winnr('#') . 'wincmd w'
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
" Note: This sets up the calculator window not the display window
function! popup#codi_setup(toggle) abort
  if a:toggle
    let cmds = exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave'
    nnoremap <buffer> q <C-w>p<Cmd>Codi!!<CR>
    nnoremap <buffer> <C-w> <C-w>p<Cmd>Codi!!<CR>
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
" Rephraser to remove comment characters before passing to interpreter. For the
" 1000 char limit issue see: https://github.com/metakirby5/codi.vim/issues/88
" Note: Warning message will be gobbled so don't bother. Just silent failure. Also
" vim substitute() function '.' matches newlines and codi silently fails if the
" rephrased input lines don't match original line count so be careful.
function! popup#codi_preprocess(line) abort
  return substitute(a:line, '�[?2004l', '', '')
endfunction
function! popup#codi_rephrase(text) abort
  let pat = '\s*' . comment#comment_char() . '[^\n]*\(\n\|$\)'  " remove comments
  let text = substitute(a:text, pat, '\1', 'g')
  let pat = '\s\+\([+-=*^|&%;:]\+\)\s\+'  " remove whitespace
  let text = substitute(text, pat, '\1', 'g')
  let pat = '\(\_s*\)\(\k\+\)=\([^\n]*\)'  " append variable defs
  let text = substitute(text, pat, '\1\2=\3;_r("\2")', 'g')
  if &filetype ==# 'julia'  " prepend repr functions
    let text = '_r=s->print(s*" = "*string(eval(s)));' . text
  else
    let text = '_r=lambda s:print(s+" = "+str(eval(s)));' . text
  endif
  let maxlen = 950  " too close to 1000 gets risky even if under 1000
  let cutoff = maxlen
  while len(text) > maxlen && (!exists('prevlen') || prevlen != len(text))
    " vint: next-line -ProhibitUsingUndeclaredVariable  " erroneous warning
    let prevlen = len(text)
    let cutoff -= count(text[cutoff:], "\n")
    let text = ''
      \ . substitute(text[:cutoff - 1], '\(^\|\n\)[^\n]*$', '\n', '')
      \ . substitute(text[cutoff:], '[^\n]', '', 'g')
  endwhile
  return text
endfunction
