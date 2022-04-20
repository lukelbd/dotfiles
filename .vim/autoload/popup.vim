"-----------------------------------------------------------------------------"
" Utilities for setting up windows
"-----------------------------------------------------------------------------"
" Setup popup windows. Mode can be 0 (not editable) or 1 (editable).
" Warning: Setting nomodifiable tends to cause errors e.g. for log files run with
" popup#job_win() or other internal stuff. So instead just try to disable normal mode
" commands that could accidentally modify text (aside from d used for scrolling).
" Warning: Critical error happens if try to auto-quit when only popup window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with file#close_tab().
function! popup#popup_setup(...) abort
  echom 'Configuring popup window for filetype: ' . &filetype
  let filemode = a:0 ? a:1 : 1
  nnoremap <silent> <buffer> q :call file#close_window()<CR>
  nnoremap <silent> <buffer> <C-w> :call file#close_window()<CR>
  setlocal nolist nonumber norelativenumber nocursorline colorcolumn=
  if filemode == 1 | return | endif  " this is an editable file
  setlocal nospell statusline=%{'[Popup\ Window]'}%=%{StatusRight()}  " additional settings
  for char in 'xXpPDaAiIcCoO' | exe 'nnoremap <buffer> ' char . ' <Nop>' | endfor
  for char in 'ubdf' | exe 'nnoremap <buffer> <nowait> ' char . ' <C-' . char . '>' | endfor
endfunction

" Setup command windows and ensure local maps work
" Note: Here 'execute' means run the selected line
function! popup#cmd_setup() abort
  inoremap <buffer> <expr> <CR> ""
  nnoremap <buffer> <CR> <C-c><CR>
  nnoremap <buffer> <Plug>ExecuteFile1 <C-c><CR>
  silent call popup#popup_setup()
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
" Note: Warning message will be gobbled so don't bother. Just silent failure.
" Note: Vim substitute() function '.' matches newlines and codi silently fails
" if the rephrased input lines don't match original line count so be careful.
function! popup#codi_preprocess(line) abort
  return substitute(a:line, '�[?2004l', '', '')
endfunction
function! popup#codi_rephrase(text) abort
  let pat = '\s*' . utils#comment_char() . '[^\n]*\(\n\|$\)'  " remove comments
  let text = substitute(a:text, pat, '\1', 'g')
  let pat = '\s\+\([+-=*^|&%;:]\+\)\s\+'  " remove whitespace
  let text = substitute(text, pat, '\1', 'g')
  let pat = '\(\_s*\)\(\k\+\)=\([^\n]*\)'  " append variable defs
  let text = substitute(text, pat, '\1\2=\3;_r("\2")', 'g')
  if &filetype ==# 'julia'  " prepend repr functions
    let text = '_r=s->print(s*" = "*repr(eval(s)));' . text
  else
    let text = '_r=lambda s:print(s+" = "+repr(eval(s)));' . text
  endif
  let maxlen = 950  " too close to 1000 gets risky even if under 1000
  let cutoff = maxlen
  while len(text) > maxlen && (!exists('prevlen') || prevlen != len(text))
    let prevlen = len(text)
    let cutoff -= count(text[cutoff:], "\n")
    let text = ''
      \ . substitute(text[:cutoff - 1], '\(^\|\n\)[^\n]*$', '\n', '')
      \ . substitute(text[cutoff:], '[^\n]', '', 'g')
  endwhile
  return text
endfunction

" Popup windows with filetype and color information
function! popup#colors_win() abort
  source $VIMRUNTIME/syntax/colortest.vim
  silent call popup#popup_setup()
endfunction
function! popup#plugin_win() abort
  execute 'split $VIMRUNTIME/ftplugin/' . &filetype . '.vim'
  silent call popup#popup_setup()
endfunction
function! popup#syntax_win() abort
  execute 'split $VIMRUNTIME/syntax/' . &filetype . '.vim'
  silent call popup#popup_setup()
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

" Setup help windows
function! popup#help_setup() abort
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
  silent call popup#popup_setup()
endfunction

" Show vim help window
" Note: This is low-level companions to fzf feature
function! popup#help_win(...) abort
  if a:0
    let item = a:1
  else
    let item = input('Vim help item: ', '', 'help')
  endif
  if !empty(item)
    exe 'vert help ' . item
  endif
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
  let cmds = ['/bin/sh', '-c', 'set -x; ' . a:cmd . '; :']
  let hght = winheight('.') / 4
  let opts = {}  " job options, empty by default
  if (a:0 ? a:1 : 1)  " whether to show popup window
    let logfile = expand('%:t:r') . '.log'
    let lognum = bufwinnr(logfile)
    if lognum == -1  " open a logfile window
      exe hght . 'split ' . logfile
      exe winnr('#') . 'wincmd w'
    else  " jump to logfile window and clean its contents
      exe bufwinnr(logfile) . 'wincmd w'
      1,$d _
      exe winnr('#') . 'wincmd w'
    endif
    let num = bufnr(logfile)
    let opts = {'out_io': 'buffer', 'out_buf': num, 'err_io': 'buffer', 'err_buf': num}
  endif
  let b:popup_job = job_start(cmds, opts)
endfunction
