"-----------------------------------------------------------------------------"
" Utilities for vimscript files
"-----------------------------------------------------------------------------"
" Setup command windows and ensure local maps work
" Note: Here 'execute' is mapped to run the selected line.
" Note: This is used e.g. when browsing past commands or searches
function! vim#cmdwin_setup() abort
  inoremap <buffer> <expr> <CR> ""
  nnoremap <buffer> <CR> <C-c><CR>
  nnoremap <buffer> <Plug>ExecuteFile1 <C-c><CR>
endfunction

" Configuration scripts to skip when refreshing
" Note: Accounts for external plugins, prevents redefining refresh function while
" running, and prevents sourcing manually-sourced common script.
let s:config_ignore = [
  \ '/.fzf/',
  \ '/plugged/',
  \ '/\.\?vimsession*',
  \ '/\.\?vim/autoload/vim.vim',
  \ '/\.\?vim/after/common.vim',
  \ '/\(micro\|mini\|mamba\)\(forge\|conda\|mamba\)\d\?/'
\ ]

" Refresh recently modified configuration files
" Note: Previously tried to update and track per-filetype refreshes but was way
" overkill and need ':filetype detect' anyway to both detect changes and to trigger
" e.g. markdown or python folding overrides. Note (after testing) this will also
" apply the updates because all ':filetype' command does is trigger script sourcing.
function! vim#config_scripts(...) abort
  let suppress = a:0 > 0 ? a:1 : 0
  let regex = a:0 > 1 ? a:2 : ''
  let [paths, sids] = [[], []]  " no dictionary because confusing
  for path in split(execute('scriptnames'), "\n")
    let sid = substitute(path, '^\s*\(\d*\):.*$', '\1', 'g')
    let path = substitute(path, '^\s*\d*:\s*\(.*\)$', '\1', 'g')
    let path = fnamemodify(resolve(expand(path)), ':p')  " then compare to home
    if !empty(regex) && path !~# regex
      continue
    endif
    call add(paths, path)
    call add(sids, sid)
  endfor
  if !suppress | echom 'Script names: ' . join(paths, ', ') | endif
  return [paths, sids]
endfunction
function! vim#config_refresh(bang, ...) abort
  let time = get(g:, 'refresh', localtime())
  let paths = vim#config_scripts(1)[0]
  let ignore = join(s:config_ignore, '\|')
  let loaded = []
  for path in paths
    if index(loaded, path) != -1
      continue  " already loaded this
    endif
    if path !~# expand('~') || path =~# ignore || a:0 && path !~# a:1 || index(loaded, path) != -1
      continue  " skip files not edited by user or matching regex
    endif
    if path =~# '/syntax/\|/ftplugin/'  " sourced by :filetype detect
      let ftype = fnamemodify(path, ':t:r')  " e.g. ftplugin/python.vim --> python
      if &filetype ==# ftype | call add(loaded, path) | endif
    elseif a:bang || getftime(path) > time || path =~# '/\.\?vimrc\|/init\.vim'
      exe 'source ' . path
      call add(loaded, path)
    endif
  endfor
  let closed = foldclosed('.')
  call tag#update_paths()  " call during .vimrc refresh
  filetype detect
  doautocmd FileType
  runtime after/common.vim
  if closed <= 0 | exe 'silent! normal! zv' | endif
  echom 'Loaded: ' . join(map(loaded, "fnamemodify(v:val, ':~')[2:]"), ', ') . '.'
  let g:refresh = localtime()
endfunction

" Create session file or load existing one
" Note: Sets string for use with MacVim windows and possibly other GUIs
" See: https://vi.stackexchange.com/a/34669/8084
function! s:session_loaded() abort
  let regex = glob2regpat($HOME)
  let regex = regex[0:len(regex) - 2]  " remove trailing '$'
  let bufs = getbufinfo({'buflisted': 1})
  let bufs = map(bufs, 'v:val.name')
  return !empty(filter(bufs, 'v:val =~# regex'))
endfunction
function! vim#session_list(lead, line, cursor) abort
  let regex = glob2regpat(a:lead)
  let regex = regex[0:len(regex) - 2]
  let opts = glob('.vimsession*', 0, 1)
  let opts = filter(opts, 'v:val =~# regex')
  return opts
endfunction
function! vim#init_session(...)
  let input = a:0 ? a:1 : ''
  let current = v:this_session
  if !empty(input) && !filereadable(a:1) && fnamemodify(a:1, ':t') !~# '^\.vimsession'
    let session = fnamemodify(a:1, ':h') . '/.vimsession-' . fnamemodify(a:1, ':t')
  else  " manual current or default session name
    let session = !empty(input) ? a:1 : !empty(current) ? current : '.vimsession'
  endif
  if filereadable(session) && !s:session_loaded()
    exe 'source ' . session
  elseif !filereadable(session)
    exe 'Obsession ' . session
  else  " never overwrite existing session files
    echoerr 'Error: Cannot source session file (current session is active).' | return 0
  endif
  let title = substitute(fnamemodify(session, ':t'), '^\.vimsession[-_]*\(.*\)$', '\1', '')
  if !empty(current) && fnamemodify(session, ':p') != fnamemodify(current, ':p')
    echom 'Removing old session file ' . fnamemodify(current, ':t')
    call delete(current)
  endif
  if !empty(title)
    echom 'Applying session title ' . title
    let &g:titlestring = title
  endif
endfunction

" Show runtime color and plugin information
" Note: Consistent with other utilities this uses separate tabs
function! vim#show_colors() abort
  call file#open_drop('colortest.vim')
  call feedkeys("\<Cmd>source $VIMRUNTIME/syntax/colortest.vim\<CR>", 'n')
  call feedkeys("\<Cmd>call window#panel_setup(1)\<CR>", 'n')
endfunction
function! vim#show_ftplugin() abort
  call file#open_drop($VIMRUNTIME . '/ftplugin/' . &filetype . '.vim')
  call feedkeys("\<Cmd>call window#panel_setup(1)\<CR>", 'n')
endfunction
function! vim#show_syntax() abort
  call file#open_drop($VIMRUNTIME . '/syntax/' . &filetype . '.vim')
  call feedkeys("\<Cmd>call window#panel_setup(1)\<CR>", 'n')
endfunction

" Source file or lines
" Note: Compare to python#run_general()
function! vim#source_general() abort
  let name = 'g:loaded_' . expand('%:t:r')
  if exists(name) | exe 'unlet! ' . name | endif
  if v:count
    exe line('.') . ',' . (line('.') + v:count) . 'source'
    echom 'Sourced ' . v:count . ' lines'
  else
    update | source %  " required e.g. for autoload files
    echo 'Sourced current file'
  endif
endfunction

" Source input motion
" Todo: Add generalization for running chunks of arbitrary filetypes?
function! vim#source_motion() range abort
  update
  let range = a:firstline . ',' . a:lastline
  exe range . 'source'
  echom 'Sourced lines ' . a:firstline . ' to ' . a:lastline
endfunction
" For <expr> map accepting motion
function! vim#source_motion_expr(...) abort
  return utils#motion_func('vim#source_motion', a:000)
endfunction

" Print information about syntax group
" Note: Top command more verbose than bottom
function! vim#syntax_list(...) abort
  if a:0 && !empty(a:1)
    exe 'verb syntax list ' . join(a:000, ' ')
  else
    exe 'verb syntax list ' . synIDattr(synID(line('.'), col('.'), 0), 'name')
  endif
endfunction
function! vim#syntax_group() abort
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
" Note: All vim tag utilities including <C-]>, :pop, :tag work by searching 'tags' files
" and updating the tag 'stack' (effectively a cache). Seems that $VIMRUNTIME/docs/tags
" is included with vim by default, and this is always used no matter the value of &tags
" (try ':echo tagfiles()' when inside help page, shows various doc/tags files).
function! vim#vim_help(...) abort
  if a:0
    let item = a:1
  else
    let item = utils#input_default('Vim help', expand('<cword>'), 'help')
  endif
  if !empty(item)
    exe 'vertical help ' . item
  endif
endfunction
function! vim#vim_setup() abort
  wincmd L  " move current window to far-right
  vertical resize 80  " help pages have fixed width
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ <Cmd>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] <Cmd>tag<CR>
endfunction
