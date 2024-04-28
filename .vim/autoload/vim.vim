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
\ ]  " common.vim sourced manually, others managed externally
function! vim#config_refresh(bang, ...) abort
  silent! runtime autoload/succinct.vim  " remove this after restarting sessions
  let time = get(g:, 'refresh', localtime())
  let regex = join(s:config_ignore, '\|')
  let paths = []
  for ipath in utils#get_scripts(a:0 ? a:1 : '')
    let path = fnamemodify(ipath, ':p')
    if path !~# expand('~') || path =~# regex || index(paths, ipath) != -1
      continue  " skip files not edited by user or matching regex
    endif
    if path =~# '/syntax/\|/ftplugin/'  " sourced by :filetype detect
      let ftype = fnamemodify(path, ':t:r')  " e.g. ftplugin/python.vim --> python
      if &filetype ==# ftype | call add(paths, ipath) | endif
    elseif a:bang || getftime(path) > time || path =~# '/\.\?vimrc\|/init\.vim'
      exe 'source ' . path
      call add(paths, ipath)
    endif
  endfor
  let closed = foldclosed('.')
  call tag#update_files()  " call during .vimrc refresh
  filetype detect
  doautocmd FileType
  runtime after/common.vim
  if closed <= 0 | exe 'silent! normal! zv' | endif | redraw
  echom 'Loaded: ' . join(map(paths, "fnamemodify(v:val, ':~')[2:]"), ', ') . '.'
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
function! vim#complete_sessions(lead, line, cursor) abort
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

" Show and setup vim help page
" Warning: Use feedkeys() in case e.g. run these from 'git' panel.
" Note: All vim tag utilities including <C-]>, :pop, :tag work by searching 'tags' files
" and updating the tag 'stack' (effectively a cache). Seems that $VIMRUNTIME/docs/tags
" is included with vim by default, and this is always used no matter the value of &tags
" (try ':echo tagfiles()' when inside help page, shows various doc/tags files).
function! vim#show_help(...) abort
  let item = a:0 ? a:1 : utils#input_default('Vim help', expand('<cword>'), 'help')
  if empty(item) | return | endif
  exe 'vertical help ' . item
endfunction
function! vim#show_runtime(name, ...) abort
  let path = $VIMRUNTIME . '/' . a:name . '/' . (a:0 ? a:1 : &l:filetype) . '.vim'
  let cmd = 'call window#setup_panel() | call switch#copy(1, 1)'
  if a:0 && a:1 =~# 'test' | let cmd .= ' | source %' | endif
  call file#drop_file(path) | call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
endfunction
function! vim#setup_help() abort
  wincmd L | vertical resize 88
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ <Cmd>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] <Cmd>tag<CR>
endfunction
function! vim#setup_cmdwin() abort
  call switch#copy(1, 1)  " hide special characters
  nnoremap <buffer> <C-s> <Nop>
  inoremap <buffer> <expr> <CR> "\<C-m>"
  nnoremap <buffer> <expr> <CR> (line('.') == line('$') ? '<Up>' : '' ) . '<C-c><CR>'
  nnoremap <buffer> <expr> ; (line('.') == line('$') ? '<Up>' : '' ) . '<C-c><CR>'
  nnoremap <buffer> <expr> / (line('.') == line('$') ? '<Up>' : '' ) . '<C-c><CR>'
  nnoremap <buffer> <Plug>ExecuteFile1 <C-c><CR>
endfunction

" Source current file or lines
" Note: This fails when calling from current script so use expr mapping
function! vim#source_general() abort
  let name = 'g:loaded_' . expand('%:t:r')
  if exists(name) | exe 'unlet! ' . name | endif
  if v:count
    exe line('.') . ',' . (line('.') + v:count) . 'source'
    echom 'Sourced ' . v:count . ' lines'
  else
    update | source % | UpdateTags   " required e.g. for autoload files
    redraw | echom 'Sourced current file'
  endif
endfunction
" For <expr> execution map
function! vim#source_general_expr() abort
  let cmd = expand('%:p') =~# 'autoload/vim\.vim$' ? 'source %' : 'call vim#source_general()'
  return "\<Cmd>" . cmd . "\<CR>"
endfunction

" Source input motion or selection
" Todo: Add generalization for running chunks of arbitrary filetypes?
function! vim#source_motion() range abort
  update | let range = a:firstline . ',' . a:lastline
  exe range . 'source'
  redraw | echom 'Sourced lines ' . a:firstline . ' to ' . a:lastline
endfunction
" For <expr> map accepting motion
function! vim#source_motion_expr(...) abort
  return utils#motion_func('vim#source_motion', a:000)
endfunction
