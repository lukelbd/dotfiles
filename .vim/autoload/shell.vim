"-----------------------------------------------------------------------------"
" Utilities for shell commands and processes
"-----------------------------------------------------------------------------"
" Popup tab with command --help
" Note: 'getcompletion()' seems to cache results by default so no need to use internal
" '~/.fzf.commands' file from .fzf 'completion-edits' branch. This is fast enough.
" Note: See also .bashrc help(). Note we previously used 'powerman/vim-plugin-AnsiEsc'
" to preserve colors shown in 'command --help' pages but now simply redirect git
" commands that include ANSI colors to their correponsding (identical) man pages.
function! shell#cmd_help(...) abort
  if a:0  " input help
    let page = a:1
  else  " default help
    let page = utils#input_default('Help info', expand('<cword>'), 'shellcmd')
  endif
  if empty(page) | return | endif
  let args = split(page, '\s\+')
  if args[0] ==# 'git' && len(filter(args[1:], "v:val[:0] !=# '-'"))
    return shell#cmd_man(join(args, '-'))  " identical result
  endif
  if args[0] ==# 'cdo'
    call insert(args, '--help', 1)
  else
    call add(args, '--help')
  endif
  let cmd = join(args, ' ')
  let result = split(system(cmd . ' 2>&1'), "\n")
  if !executable(args[0]) || len(result) < 3
    echom "help.vim: nothing returned from '" . cmd . "'"
    return
  endif
  let bnum = bufnr(cmd)
  if bnum != -1 | exe bnum . 'bdelete' | endif
  tabedit | call append(0, result) | goto
  set filetype=popup
  set buftype=nofile
  exe 'file ' . cmd
  call utils#panel_setup(0)
endfunction
function! shell#fzf_help() abort
  call fzf#run(fzf#wrap({
    \ 'source': getcompletion('', 'shellcmd'),
    \ 'options': '--no-sort --prompt="--help> "',
    \ 'sink': function('shell#cmd_help'),
    \ }))
endfunction

" Man page and pydoc page utilities
" Warning: Calling :Man changes the buffer, so use buffer variables specific to each
" page to record navigation history. Order of assignment below is critical.
function! s:doc_jump(forward) abort
  let curr = b:doc_curr
  let name = a:forward ? 'doc_next' : 'doc_prev'
  let page = get(b:, name, '')
  if empty(page) | return | endif
  call python#doc_page(page)
  if a:forward
    let b:doc_prev = curr
  else
    let b:doc_next = curr
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
function! shell#man_setup(...) abort
  setlocal tabstop=8 softtabstop=8 shiftwidth=8
  let page = tolower(matchstr(getline(1), '\f\+'))  " from highlight group
  let pnum = matchstr(getline(1), '(\@<=[1-9][a-z]\=)\@=')  " from highlight group
  if get(b:, 'pydoc', 0)
    let b:doc_curr = @%
    noremap <nowait> <buffer> [ <Cmd>call <sid>doc_jump(0)<CR>
    noremap <nowait> <buffer> ] <Cmd>call <sid>doc_jump(1)<CR>
    noremap <silent> <buffer> <CR> <Cmd>call python#doc_page(python#doc_name())<CR>
  else
    let b:man_curr = [page, pnum]  " see below
    noremap <nowait> <buffer> [ <Cmd>call <sid>man_jump(0)<CR>
    noremap <nowait> <buffer> ] <Cmd>call <sid>man_jump(1)<CR>
    noremap <silent> <buffer> <CR> <Cmd>call <sid>man_cursor()<CR>
  endif
  if get(b:, 'pydoc', 0)
    let pad = '^\(\s\{4}\)\{1,2}'
    let item = pad . '\zs\(class\s\+\)\?\k\+\ze(.*)'
    let data = pad . '\zs\k\+\ze\s*=\s*\(<.*>\|\(class\s\+\)\?\k\+(.*)\)'
    let dash = pad . '\s*\zs[-=]\{3,}.*$'
    let mess = pad . '\s*\C[A-Z].*\(defined here\|resolution order\|inherited\s*from\s*\S*\):$'
    let head = ''
      \ . '\(' . pad . '\(\s*\|\s*[-=]\{3,}.*\)\n' . pad . '\s*\)\@<='
      \ . '\C[A-Z]\a\{2,}.*'
      \ . '\(\n' . pad . '\s*[-=]\{3,}.*$\)\@='
    exe 'syntax clear manLongOptionDesc'
    exe "syntax match docItem '" . item . "'"
    exe "syntax match docData '" . data . "'"
    exe "syntax match docMess '" . mess . "'"
    exe "syntax match docHeader '" . head . "'"
    exe "syntax match docDashes '" . dash . "'"
    highlight link docItem manSectionHeading
    highlight link docData manSectionHeading
    highlight link docMess manHeader
    highlight link docHeader manHeader
    highlight link docDashes manHeader
  endif
endfunction

" Popup tab with man page and navigation tools
" Note: See also .bashrc man(). These utils are expanded from vim-superman.
" Note: Apple will have empty line then BUILTIN(1) on second line, but linux
" will show as first line BASH_BUILTINS(1), so we search the first two lines.
function! shell#cmd_man(...) abort
  if a:0  " input man
    let page = a:1
  else  " default man
    let page = utils#input_default('Man page', expand('<cword>'), 'shellcmd')
  endif
  let g:ft_man_folding_enable = 1  " see :help Man
  let current = @%  " current file
  if empty(page) | return | endif
  tabedit | set filetype=man | exe 'Man ' . page
  if line('$') <= 1
    silent! quit
    call file#open_drop(current)
    echom "man.vim: nothing returned from 'man " . page . "'"
  endif
  if getline(1) =~# 'BUILTIN' || getline(2) =~# 'BUILTIN'
    if has('macunix') && page !=# 'builtin'
      Man bash
    endif
    let @/ = '^       ' . page . ' [.*$'
    normal! n
  endif
endfunction
function! shell#fzf_man() abort
  call fzf#run(fzf#wrap({
    \ 'source': getcompletion('', 'shellcmd'),
    \ 'options': '--no-sort --prompt="man> "',
    \ 'sink': function('shell#cmd_man'),
    \ }))
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
