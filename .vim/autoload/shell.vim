"-----------------------------------------------------------------------------"
" Utilities for shell commands and processes
"-----------------------------------------------------------------------------"
" Popup tab with command --help
" NOTE: 'getcompletion()' seems to cache results by default so no need to use internal
" '~/.fzf.commands' file from .fzf 'completion-edits' branch. This is fast enough.
" NOTE: See also .bashrc help(). Note we previously used 'powerman/vim-plugin-AnsiEsc'
" to preserve colors shown in 'command --help' pages but now simply redirect git
" commands that include ANSI colors to their correponsding (identical) man pages.
function! shell#help_page(...) abort
  let opt1 = expand('<cword>')
  let opt2 = get(s:, 'help_prev', '')
  let default = executable(opt1) || empty(opt2) ? opt1 : opt2
  if a:0  " input help
    let page = a:1
  else  " default help
    let page = utils#input_default('Help info', default, 'shellcmd')
  endif
  if empty(page) | return 1 | endif
  let [name; args] = split(page, '\s\+', 1)
  if name ==# 'git' && len(filter(args, "v:val[:0] !=# '-'"))
    return shell#man_page('git-' . join(args, ' '))  " identical result
  endif
  if args[0] ==# 'cdo'
    call insert(args, '--help', 1)
  else
    call add(args, '--help')
  endif
  let type = &l:filetype
  let bnr = bufnr()
  let cmd = join(args, ' ')
  if type !=# 'stdout'
    tabedit | setlocal nobuflisted bufhidden=hide buftype=nofile filetype=stdout
    doautocmd BufWinEnter
  endif
  if bufexists(cmd)
    silent exe bufnr(cmd) . 'buffer'
  else
    let result = split(system(cmd . ' 2>&1'), "\n") | call append(0, result) | goto
  endif
  if line('$') > 3
    silent exe 'file ' . fnameescape(cmd)
    let s:help_prev = page
  else
    if type !=# 'stdout'  " see above
      silent quit! | silent call file#drop_file(bufname(bnr))
    endif
    echohl ErrorMsg
    echom "Error: Help info '" . cmd . "' not found"
    echohl None | return 1
  endif
endfunction
function! shell#fzf_help() abort
  let options = {
    \ 'source': getcompletion('', 'shellcmd'),
    \ 'options': '--tiebreak length,index --prompt="--help> "',
    \ 'sink': function('stack#push_stack', ['help', 'shell#help_page'])
  \ }
  call fzf#run(fzf#wrap(options))
endfunction

" Popup tab with man page and navigation tools
" NOTE: See also .bashrc man(). These utils are expanded from vim-superman.
" NOTE: Apple will have empty line then BUILTIN(1) on second line, but linux
" will show as first line BASH_BUILTINS(1), so we search the first two lines.
function! s:load_page(...) abort
  silent call call('dist#man#GetPage', a:000)  " native utility
  call stack#pop_stack('tab', bufnr())  " avoid premature addition to stack
endfunction
function! shell#man_page(...) abort
  let bnr = bufnr()
  let opt1 = expand('<cword>')
  let opt2 = get(s:, 'man_prev', '')
  let default = executable(opt1) || empty(opt2) ? opt1 : opt2
  if a:0 && empty(a:1)  " input man
    let page = matchstr(expand('<cWORD>'), '\f\+')  " from man syntax
    let pnum = matchstr(expand('<cWORD>'), '(\@<=[1-9][a-z]\=)\@=')  " from man syntax
  elseif a:0  " input page and/or number
    let [page, pnum] = type(a:1) == 1 ? [a:1, 0] : a:000
  else  " default man
    let [page, pnum] = [utils#input_default('Man page', default, 'shellcmd'), 0]
  endif
  if empty(page) | return 1 | endif
  let type = &l:filetype
  let name = page . '(' . max([pnum, 1]) . ')'
  let args = reverse(pnum ? [page, pnum] : [page])
  if type !=# 'man'
    tabedit | setlocal filetype=man
  endif
  if bufexists(name)
    exe bufnr(name) . 'buffer'
  else  " load new man page
    call call('s:load_page', [''] + args)
  endif
  if line('$') > 1  " jump to relevant file
    if getline(1) =~# 'BUILTIN' || getline(2) =~# 'BUILTIN'
      if has('macunix') && page !=# 'builtin' | call s:load_page('', 'bash') | endif
      keepjumps goto | call search('^ \{7}' . page . ' [.*$', '')
    endif
    silent exe 'file ' . name
    let s:man_prev = page
  else
    if type !=# 'man'
      silent quit! | silent call file#drop_file(bufname(bnr))
    endif
    let msg = 'Error: Man page ' . string(page) . ' not found'
    redraw | echohl ErrorMsg | echom msg | echohl None | return 1
  endif
endfunction
function! shell#fzf_man() abort
  let options = {
    \ 'source': getcompletion('', 'shellcmd'),
    \ 'options': '--tiebreak length,index --prompt="man> "',
    \ 'sink': function('stack#push_stack', ['man', 'shell#man_page'])
  \ }
  call fzf#run(fzf#wrap(options))
endfunction

" Run job and feed standard output to preview window
" NOTE: Add 'set -x' to display commands and no-op ':' to signal completion. The
" '/bin/sh' is needed to permit command chains with e.g. && or || otherwise fails.
" NOTE: Use 'pty' intead of pipe to prevent output buffering and delayed
" printing as a result. See https://vi.stackexchange.com/a/20639/8084
" NOTE: Job has to be non-local variable or else can terminate
" early when references gone. See https://vi.stackexchange.com/a/22597/8084
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')  " copied from autoreload/plug.vim
function! shell#job_win(cmd, ...) abort
  if !s:vim8
    echohl ErrorMsg
    echom 'Error: Running jobs requires vim >= 8.0'
    echohl None
    return 1
  endif
  let cmds = ['/bin/sh', '-c', 'set -x; ' . a:cmd . '; :']
  let hght = winheight('.') / 4
  let opts = {}  " job options, empty by default
  if a:0 && a:1  " show panel, or run job
    let logfile = expand('%:t:r') . '.job'
    let lognum = bufwinnr(logfile)
    if lognum == -1  " open a logfile window
      exe hght . 'split ' . logfile
    else  " jump to logfile window and clean its contents
      exe lognum . 'wincmd w' | %delete
    endif
    let num = bufnr(logfile)
    call setbufvar(num, '&filetype', 'stdout')
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

" Man page and pydoc page utilities
" WARNING: Order of assignment of variables below is critical, since use buffer
" variables specific to each page then allow :Man to change the buffer in stack.
function! s:setup_syntax() abort  " man-style pydoc syntax
  let indent = '^\(\s\{4}\)*'
  let item = indent . '\zs\(class\s\+\)\?\k\+\ze(.*)'
  let data = indent . '\zs\k\+\ze\s*=\s*\(<.*>\|\(class\s\+\)\?\k\+(.*)\)'
  let dash = indent . '\s*\zs[-=]\{3,}.*$'
  let mess = indent . '\s*\C[A-Z].*\(defined here\|resolution order\|inherited\s*from\s*\S*\):$'
  let head = ''
    \ . '\(' . indent . '\(\s*\|\s*[-=]\{3,}.*\)\n' . indent . '\s*\)\@<='
    \ . '\C[A-Z]\a\{2,}.*'
    \ . '\(\n' . indent . '\s*[-=]\{3,}.*$\)\@='
  exe "syntax match docItem '" . item . "'"
  exe "syntax match docData '" . data . "'"
  exe "syntax match docDash '" . dash . "'"
  exe "syntax match docMess '" . mess . "'"
  exe "syntax match docHead '" . head . "'"
  silent! syntax clear manLongOptionDesc
  silent! syntax clear manSectionHeading
  highlight link docItem manSectionHeading
  highlight link docData manSectionHeading
  highlight link docDash manHeader
  highlight link docMess manHeader
  highlight link docHead manHeader
endfunction
function! shell#setup_man(...) abort
  if !empty(get(b:, 'doc_name', ''))
    setlocal tabstop=4 softtabstop=4 shiftwidth=4 foldmethod=indent foldnestmax=3
    call s:setup_syntax()  " set up syntax highlighting
    let [b:doc_name, key, cmd] = [@%, 'doc', 'python#doc_page']
  else
    setlocal tabstop=7 softtabstop=7 shiftwidth=7 foldmethod=indent foldnestmax=3
    let page = tolower(matchstr(getline(1), '\f\+'))  " from man syntax group
    let pnum = matchstr(getline(1), '(\@<=[1-9][a-z]\=)\@=')  " from man syntax
    let [b:man_name, key, cmd] = [[page, pnum], 'man', 'shell#man_page']
  endif
  let push = '<Cmd>call stack#push_stack(%s, %s, %s)<CR>'  " template invocation
  exe 'noremap <buffer> <CR> ' . printf(push, string(key), string(cmd), string(''))
  exe 'noremap <nowait> <buffer> [ ' . printf(push, string(key), string(cmd), '-v:count1')
  exe 'noremap <nowait> <buffer> ] ' . printf(push, string(key), string(cmd), 'v:count1')
endfunction

" Show directory network and terminal
" WARNING: Critical to load vim-vinegar plugin/vinegar.vim before
" setup_netrw() or else mappings are overwritten (see vimrc).
function! shell#setup_netrw() abort
  let maps = [['n', '<CR>', 't'], ['n', '.', 'gn'], ['n', ',', '-'], ['nx', ';', '.']]
  call call('utils#map_from', maps)
  for char in 'fbFL' | silent! exe 'unmap <buffer> q' . char | endfor
endfunction
function! shell#show_netrw(cmd, local) abort
  let base = a:local ? expand('%:p:h') : parse#get_root()
  let [width, height] = [window#get_width(0), window#get_height(0)]
  exe a:cmd . ' ' . base | goto
  exe a:cmd =~# 'vsplit' ? 'vert resize ' . width : 'resize ' . height 
endfunction
function! shell#show_terminal() abort
  if has('terminal')
    let $VIMTERMDIR = expand('%:p:h')
    terminal | call feedkeys('cd $VIMTERMDIR', 'tn')
  else  " raise error
    let msg = 'Error: Terminal not supported.'
    redraw | echohl ErrorMsg | echom msg | echohl None | return
  endif
endfunction
