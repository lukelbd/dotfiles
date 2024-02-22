"-----------------------------------------------------------------------------"
" Utilities for shell commands and processes
"-----------------------------------------------------------------------------"
" Popup tab with command --help
" Note: 'getcompletion()' seems to cache results by default so no need to use internal
" '~/.fzf.commands' file from .fzf 'completion-edits' branch. This is fast enough.
" Note: See also .bashrc help(). Note we previously used 'powerman/vim-plugin-AnsiEsc'
" to preserve colors shown in 'command --help' pages but now simply redirect git
" commands that include ANSI colors to their correponsding (identical) man pages.
function! shell#help_page(...) abort
  if a:0  " input help
    let page = a:1
  else  " default help
    let page = utils#input_default('Help info', expand('<cword>'), 'shellcmd')
  endif
  if empty(page) | return | endif
  let args = split(page, '\s\+')
  if args[0] ==# 'git' && len(filter(args[1:], "v:val[:0] !=# '-'"))
    return shell#man_page(join(args, '-'))  " identical result
  endif
  if args[0] ==# 'cdo'
    call insert(args, '--help', 1)
  else
    call add(args, '--help')
  endif
  let type = &l:filetype
  let bnr = bufnr()
  let cmd = join(args, ' ')
  if type !=# 'popup' | tabedit | endif
  if bufexists(cmd)
    silent exe bufnr(cmd) . 'buffer'
  else
    let result = split(system(cmd . ' 2>&1'), "\n")
    setlocal nobuflisted bufhidden=hide buftype=nofile filetype=popup
    call window#panel_setup(0) | call append(0, result) | goto
  endif
  if line('$') > 3 | exe 'file ' . fnameescape(cmd) | else
    echohl ErrorMsg
    echom "Error: Help info '" . cmd . "' not found"
    echohl None
    if type !=# 'popup'
      silent quit!
      call file#open_drop(1, bufname(bnr))
    endif
    return
  endif
endfunction
function! shell#fzf_help() abort
  call fzf#run(fzf#wrap({
    \ 'source': getcompletion('', 'shellcmd'),
    \ 'options': '--no-sort --prompt="--help> "',
    \ 'sink': function('stack#push_stack', ['shell#help_page', 'help'])
  \ }))
endfunction

" Man page and pydoc page utilities
" Warning: Calling :Man changes the buffer, so use buffer variables specific to each
" page to record navigation history. Order of assignment below is critical.
function! s:syntax_setup() abort  " man-style pydoc syntax
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
function! shell#man_setup(...) abort
  let page = tolower(matchstr(getline(1), '\f\+'))  " from man syntax group
  let pnum = matchstr(getline(1), '(\@<=[1-9][a-z]\=)\@=')  " from man syntax
  if !empty(get(b:, 'doc_name', ''))
    setlocal tabstop=4 softtabstop=4 shiftwidth=4 foldnestmax=3
    let b:doc_name = @% | call s:syntax_setup()
    noremap <buffer> <CR> <Cmd>call stack#push_stack('python#doc_page', 'doc', '')<CR>
    noremap <nowait> <buffer> [ <Cmd>call stack#push_stack('python#doc_page', 'doc', -v:count1)<CR>
    noremap <nowait> <buffer> ] <Cmd>call stack#push_stack('python#doc_page', 'doc', v:count1)<CR>
  else
    setlocal tabstop=7 softtabstop=7 shiftwidth=7 foldnestmax=3
    let b:man_name = [page, pnum]  " see below
    noremap <buffer> <CR> <Cmd>call stack#push_stack('shell#man_page', 'man', '')<CR>
    noremap <nowait> <buffer> [ <Cmd>call stack#push_stack('shell#man_page', 'man', -v:count1)<CR>
    noremap <nowait> <buffer> ] <Cmd>call stack#push_stack('shell#man_page', 'man', v:count1)<CR>
  endif
endfunction

" Popup tab with man page and navigation tools
" Note: See also .bashrc man(). These utils are expanded from vim-superman.
" Note: Apple will have empty line then BUILTIN(1) on second line, but linux
" will show as first line BASH_BUILTINS(1), so we search the first two lines.
function! shell#man_page(...) abort
  let bnr = bufnr()
  if a:0 && empty(a:1)  " input man
    let page = matchstr(expand('<cWORD>'), '\f\+')  " from man syntax
    let pnum = matchstr(expand('<cWORD>'), '(\@<=[1-9][a-z]\=)\@=')  " from man syntax
  elseif a:0  " input page or [page, number]
    let [page, pnum] = type(a:1) == 1 ? [a:1, 0] : a:1
  else  " default man
    let [page, pnum] = [utils#input_default('Man page', expand('<cword>'), 'shellcmd'), 0]
  endif
  if empty(page) | return | endif
  let type = &l:filetype
  let name = page . '(' . max([pnum, 1]) . ')'
  let args = pnum ? pnum . ' ' . page : page
  if type !=# 'man'
    tabedit | setlocal filetype=man
  endif
  if bufexists(name)
    exe bufnr(name) . 'buffer'
  else
    silent exe 'Man ' . args | goto
  endif
  if line('$') > 1 | exe 'file ' . name | else
    echohl ErrorMsg
    echom "Error: Man page '" . page . "' not found"
    echohl None
    if type !=# 'man'
      silent quit!
      call file#open_drop(1, bufname(bnr))
    endif
    return
  endif
  if getline(1) =~# 'BUILTIN' || getline(2) =~# 'BUILTIN'
    if has('macunix') && page !=# 'builtin' | exe 'Man bash' | endif
    let @/ = '^ \{7}' . page . ' [.*$' | normal! n
  endif
endfunction
function! shell#fzf_man() abort
  call fzf#run(fzf#wrap({
    \ 'source': getcompletion('', 'shellcmd'),
    \ 'options': '--no-sort --prompt="man> "',
    \ 'sink': function('stack#push_stack', ['shell#man_page', 'man'])
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

" Tables of netrw mappings
" See: :help netrw-quickmaps
" ---     -----------------      ----
" Map     Quick Explanation      Link
" ---     -----------------      ----
" <F1>    Causes Netrw to issue help
" <cr>    Netrw will enter the directory or read the file
" <del>   Netrw will attempt to remove the file/directory
" <c-h>   Edit file hiding list
" <c-l>   Causes Netrw to refresh the directory listing
" <c-r>   Browse using a gvim server
" <c-tab> Shrink/expand a netrw/explore window
"   -     Makes Netrw go up one directory
"   a     Cycles between normal display, hiding  (suppress display of files matching
"         g:netrw_list_hide) and showing (display only files which match g:netrw_list_hide)
"   cd    Make browsing directory the current directory
"   C     Setting the editing window
"   d     Make a directory
"   D     Attempt to remove the file(s)/directory(ies)
"   gb    Go to previous bookmarked directory
"   gd    Force treatment as directory
"   gf    Force treatment as file
"   gh    Quick hide/unhide of dot-files
"   gn    Make top of tree the directory below the cursor
"   gp    Change local-only file permissions
"   i     Cycle between thin, long, wide, and tree listings
"   I     Toggle the displaying of the banner
"   mb    Bookmark current directory
"   mc    Copy marked files to marked-file target directory
"   md    Apply diff to marked files (up to 3)
"   me    Place marked files on arg list and edit them
"   mf    Mark a file
"   mF    Unmark files
"   mg    Apply vimgrep to marked files
"   mh    Toggle marked file suffices' presence on hiding list
"   mm    Move marked files to marked-file target directory
"   mp    Print marked files
"   mr    Mark files using a shell-style
"   mt    Current browsing directory becomes markfile target
"   mT    Apply ctags to marked files
"   mu    Unmark all marked files
"   mv    Apply arbitrary vim   command to marked files
"   mx    Apply arbitrary shell command to marked files
"   mX    Apply arbitrary shell command to marked files en bloc
"   mz    Compress/decompress marked files
"   o     Enter the file/directory under the cursor in a new horizontal split browser.
"   O     Obtain a file specified by cursor
"   p     Preview the file
"   P     Browse in the previously used window
"   qb    List bookmarked directories and history
"   qf    Display information on file
"   qF    Mark files using a quickfix list
"   qL    Mark files using a
"   r     Reverse sorting order
"   R     Rename the designated file(s)/directory(ies)
"   s     Select sorting style: by name, time, or file size
"   S     Specify suffix priority for name-sorting
"   t     Enter the file/directory under the cursor in a new tab
"   u     Change to recently-visited directory
"   U     Change to subsequently-visited directory
"   v     Enter the file/directory under the cursor in a new vertical split browser.
"   x     View file with an associated program
"   X     Execute filename under cursor via
"   %  Open a new file in netrw's current directory
