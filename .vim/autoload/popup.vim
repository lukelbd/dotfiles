"-----------------------------------------------------------------------------"
" Utilities for setting up windows
"-----------------------------------------------------------------------------"
" Global encoding for special character
scriptencoding utf-8

" Setup popup windows. Mode can be 0 (not editable) or 1 (editable).
" Warning: Setting nomodifiable tends to cause errors e.g. for log files run with
" popup#job_win() or other internal stuff. So instead just try to disable normal mode
" commands that could accidentally modify text (aside from d used for scrolling).
" Warning: Critical error happens if try to auto-quit when only popup window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with session#close_tab().
function! popup#popup_setup(filemode) abort
  nnoremap <silent> <buffer> q :call session#close_window()<CR>
  nnoremap <silent> <buffer> <C-w> :call session#close_window()<CR>
  setlocal nolist nonumber norelativenumber nocursorline
  if &filetype ==# 'qf' | nnoremap <buffer> <CR> <CR> | endif
  if a:filemode == 1 | return | endif  " this is an editable file
  setlocal nospell colorcolumn= statusline=%{'[Popup\ Window]'}%=%{StatusRight()}  " additional settings
  for char in 'uUrRxXpPdDaAiIcCoO' | exe 'nmap <buffer> ' char . ' <Nop>' | endfor
  for char in 'dufb' | exe 'map <buffer> <nowait> ' . char . ' <C-' . char . '>' | endfor
endfunction

" Setup command windows and ensure local maps work
" Note: Here 'execute' means run the selected line
function! popup#cmdwin_setup() abort
  inoremap <buffer> <expr> <CR> ""
  nnoremap <buffer> <CR> <C-c><CR>
  nnoremap <buffer> <Plug>ExecuteFile1 <C-c><CR>
endfunction

" Popup window with help information
" Note: See also .bashrc help(). These utils
function! popup#help_page(tab, ...) abort
  let file = @%
  let page = a:0 ? a:1 : input('Help info: ', '', 'shellcmd')
  let args = split(page, '\s\+')
  if empty(page) | return | endif
  if args[0] ==# 'git' && len(filter(args[1:], "v:val[:0] !=# '-'"))
    return popup#man_page(a:tab, join(args, '-'))  " identical result
  endif
  if args[0] ==# 'cdo'
    call insert(args, '--help', 1)
  else
    call add(args, '--help')
  endif
  if !executable(args[0])
    echom 'help.vim: no --help info for "' . args[0] . '"'
    return
  endif
  let name = join(args, ' ')
  let bnum = bufnr(name)
  if a:tab | tabedit | endif
  if bnum != -1 | exe bnum . 'bdelete' | endif
  let result = split(system(join(args, ' ') . ' 2>&1'), "\n")
  call append(0, result)
  goto
  set filetype=popup
  set buftype=nofile
  exe 'file ' . name
  call popup#popup_setup(0)
  if len(result) == 0
    silent! quit
    call file#open_existing(file)
  endif
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

" Man page utilities
" Warning: Calling :Man changes the buffer, so use buffer variables specific to each
" page to record navigation history. Order of assignment below is critical.
function! s:man_cursor() abort
  let bnr = bufnr()
  let curr = b:man_curr
  let word = expand('<cWORD>')  " possibly includes trailing puncation
  let page = matchstr(word, '\f\+')  " from highlight group
  let pnum = matchstr(word, '(\@<=[1-9][a-z]\=)\@=')  " from highlight group
  exe 'Man ' . pnum . ' ' . page
  if bnr != bufnr()  " original buffer
    let b:man_prev = curr
    let b:man_curr = [page, pnum]
  endif
endfunction
function! s:man_jump(forward) abort
  let curr = b:man_curr
  let name = a:forward ? 'man_next' : 'man_prev'
  let pair = get(b:, name, '')
  if empty(pair) | return | endif
  exe 'Man ' . pair[1] . ' ' . pair[0]
  if a:forward
    let b:man_prev = curr
  else
    let b:man_next = curr
  endif
endfunction

" Show and setup shell man page
" Note: See also .bashrc man(). These utils are expanded from vim-superman.
" Note: Apple will have empty line then BUILTIN(1) on second line, but linux
" will show as first line BASH_BUILTINS(1), so we search the first two lines.
function! popup#man_page(tab, ...) abort
  let file = @%
  let page = a:0 ? a:1 : input('Man page: ', '', 'shellcmd')
  if empty(page) | return | endif
  if a:tab | tabedit | endif
  set filetype=man
  exe 'Man ' . page
  if line('$') <= 1
    silent! quit
    call file#open_existing(file)
  endif
  if getline(1) =~# 'BUILTIN' || getline(2) =~# 'BUILTIN'
    if has('macunix') && page !=# 'builtin'
      Man bash
    endif
    let @/ = '^       ' . page . ' [.*$'
    normal! n
  endif
endfunction
function! popup#man_setup(...) abort
  let page = tolower(matchstr(getline(1), '\f\+'))  " from highlight group
  let pnum = matchstr(getline(1), '(\@<=[1-9][a-z]\=)\@=')  " from highlight group
  let b:man_curr = [page, pnum]
  setlocal tabstop=8
  setlocal softtabstop=8
  setlocal shiftwidth=8
  noremap <nowait> <buffer> [ <Cmd>call <sid>man_jump(0)<CR>
  noremap <nowait> <buffer> ] <Cmd>call <sid>man_jump(1)<CR>
  noremap <silent> <buffer> <CR> <Cmd>call <sid>man_cursor()<CR>
endfunction

" Insert complete menu items and scroll complete or preview windows (whichever is open).
" Note: This prevents vim's baked-in circular complete menu scrolling. It
" also prefers scrolling complete menus over preview windows.
" Note: Used 'verb function! lsp#scroll' to figure out how to detect
" preview windows for a reference scaling (also verified that l:window.find
" and therefore lsp#scroll do not return popup completion windows).
function! popup#scroll_reset() abort
  let b:scroll_state = 0
  return ''
endfunction
function! s:scroll_preview(info, scroll) abort
  let nr = type(a:scroll) == 5 ? float2nr(a:scroll * a:info['height']) : a:scroll
  let nr = a:scroll > 0 ? max([nr, 1]) : min([nr, -1])
  return lsp#scroll(nr)
endfunction
function! s:scroll_popup(info, scroll) abort
  let nr = type(a:scroll) == 5 ? float2nr(a:scroll * a:info['height']) : a:scroll
  let nr = a:scroll > 0 ? max([nr, 1]) : min([nr, -1])
  let nr = max([0 - b:scroll_state, nr])
  let nr = min([a:info['size'] - b:scroll_state, nr])
  let b:scroll_state += nr  " complete menu offset
  return repeat(nr > 0 ? "\<C-n>" : "\<C-p>", abs(nr))
endfunction
function! s:scroll_normal(scroll) abort
  let nr = abs(type(a:scroll) == 5 ? float2nr(a:scroll * winheight(0)) : a:scroll)
  let cmd = ''
  if mode() !~# '^[iIR]'  " revert to normal mode scrolling
    let updown = a:scroll > 0 ? 'd' : 'u'
    let cmd = "\<Cmd>call scrollwrapped#scroll(" . nr . ", '" . updown . "', 1)\<CR>"
  endif
  return cmd
endfunction
function! popup#scroll_count(scroll) abort
  let complete_info = pum_getpos()  " automatically returns empty if not present
  let l:methods = vital#lsp#import('VS.Vim.Window')  " scope is necessary
  let preview_ids = l:methods.find({id -> l:methods.is_floating(id)})
  let preview_info = empty(preview_ids) ? {} : l:methods.info(preview_ids[0])
  if !empty(complete_info)
    return s:scroll_popup(complete_info, a:scroll)
  elseif !empty(preview_info)
    return s:scroll_preview(preview_info, a:scroll)
  else
    return s:scroll_normal(a:scroll)
  endif
endfunction

" Print information about syntax group
" Note: Top command more verbose than bottom
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

" Show and setup vim help page
" Note: This ensures original plugins are present
function! popup#vim_page(...) abort
  if a:0
    let item = a:1
  else
    let item = input('Vim help item: ', '', 'help')
  endif
  if !empty(item)
    exe 'vert help ' . item
  endif
endfunction
function! popup#vim_setup() abort
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
endfunction

" Popup windows with filetype and color information
function! popup#runtime_colors() abort
  source $VIMRUNTIME/syntax/colortest.vim
  silent call popup#popup_setup(0)
endfunction
function! popup#runtime_ftplugin() abort
  execute 'split $VIMRUNTIME/ftplugin/' . &filetype . '.vim'
  silent call popup#popup_setup(0)
endfunction
function! popup#runtime_syntax() abort
  execute 'split $VIMRUNTIME/syntax/' . &filetype . '.vim'
  silent call popup#popup_setup(0)
endfunction
