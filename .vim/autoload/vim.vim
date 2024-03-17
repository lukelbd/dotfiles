"-----------------------------------------------------------------------------"
" Utilities for vimscript files
"-----------------------------------------------------------------------------"
" Refresh recently modified configuration files
" Note: Previously tried to update and track per-filetype refreshes but was way
" overkill and need ':filetype detect' anyway to both detect changes and to trigger
" e.g. markdown or python folding overrides. Note (after testing) this will also
" apply the updates because all ':filetype' command does is trigger script sourcing.
let s:config_ignore = [
  \ '/.fzf/',
  \ '/plugged/',
  \ '/\.\?vimsession*',
  \ '/\.\?vim/autoload/vim.vim',
  \ '/\.\?vim/after/common.vim',
  \ '/\(micro\|mini\|mamba\)\(forge\|conda\|mamba\)\d\?/'
\ ]  " manually source common.vim and others are externally managed
function! vim#config_refresh(bang, ...) abort
  silent! runtime autoload/succinct.vim  " remove this after restarting sessions
  let time = get(g:, 'refresh', localtime())
  let paths = utils#get_scripts(1)[0]
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
  let path = $VIMRUNTIME . '/syntax/colortest.vim'
  exe 'source ' . path
  call window#setup_panel(1)
endfunction
function! vim#show_runtime(...) abort
  let path = a:0 ? a:1 : 'ftplugin'
  let path = $VIMRUNTIME . '/' . path . '/' . &l:filetype . '.vim'
  call file#open_drop(path)
  call window#setup_panel(1)
endfunction
function! vim#show_stack(...) abort
  let sids = a:0 ? map(copy(a:000), 'hlID(v:val)') : synstack(line('.'), col('.'))
  let [names, labels] = [[], []]
  for sid in sids
    let name = synIDattr(sid, 'name')
    let group = synIDattr(synIDtrans(sid), 'name')
    let label = empty(group) ? name : name . ' (' . group . ')'
    call add(names, name)
    call add(labels, label)
  endfor
  if !empty(names)
    echohl Title | echom '--- Syntax names ---' | echohl None
    for label in labels | echom label | endfor
    exe 'syntax list ' . join(names, ' ')
  else  " no syntax
    echohl WarningMsg
    echom 'Warning: No syntax under cursor.'
    echohl None
  endif
endfunction

" Show and setup vim help page
" Note: All vim tag utilities including <C-]>, :pop, :tag work by searching 'tags' files
" and updating the tag 'stack' (effectively a cache). Seems that $VIMRUNTIME/docs/tags
" is included with vim by default, and this is always used no matter the value of &tags
" (try ':echo tagfiles()' when inside help page, shows various doc/tags files).
function! vim#show_help(...) abort
  if a:0
    let item = a:1
  else
    let item = utils#input_default('Vim help', expand('<cword>'), 'help')
  endif
  if !empty(item)
    exe 'vertical help ' . item
  endif
endfunction
function! vim#setup_cmdwin() abort
  inoremap <buffer> <expr> <CR> ""
  exe 'nnoremap <buffer> <CR> <C-c><CR>'
  exe 'nnoremap <buffer> <Plug>ExecuteFile1 <C-c><CR>'
endfunction
function! vim#setup_help() abort
  wincmd L | vert resize 88 | nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ <Cmd>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] <Cmd>tag<CR>
endfunction

" Source file, lines, or motion
" Todo: Add generalization for running chunks of arbitrary filetypes?
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
" For input line range
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
