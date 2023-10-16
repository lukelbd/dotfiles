"-----------------------------------------------------------------------------"
" Utilities for shell commands and processes
"-----------------------------------------------------------------------------"
" Popup window with help information
" Note: See also .bashrc help(). Note we previously used 'powerman/vim-plugin-AnsiEsc'
" to preserve colors shown in 'command --help' pages but now simply redirect git
" commands that include ANSI colors to their correponsding (identical) man pages.
function! shell#help_page(tab, ...) abort
  let file = @%
  let page = a:0 ? a:1 : utils#input_default('Help info', 'shellcmd', expand('<cword>'))
  let args = split(page, '\s\+')
  if empty(page) | return | endif
  if args[0] ==# 'git' && len(filter(args[1:], "v:val[:0] !=# '-'"))
    return shell#man_page(a:tab, join(args, '-'))  " identical result
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
  call utils#panel_setup(0)
  if len(result) == 0
    silent! quit
    call file#open_drop(file)
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
function! shell#job_win(cmd, ...) abort
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
function! shell#man_page(tab, ...) abort
  let file = @%
  let page = a:0 ? a:1 : utils#input_default('Man page', 'shellcmd', expand('<cword>'))
  if empty(page) | return | endif
  if a:tab | tabedit | endif
  set filetype=man
  exe 'Man ' . page
  if line('$') <= 1
    silent! quit
    call file#open_drop(file)
  endif
  if getline(1) =~# 'BUILTIN' || getline(2) =~# 'BUILTIN'
    if has('macunix') && page !=# 'builtin'
      Man bash
    endif
    let @/ = '^       ' . page . ' [.*$'
    normal! n
  endif
endfunction
function! shell#man_setup(...) abort
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
