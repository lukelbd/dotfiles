"-----------------------------------------------------------------------------"
" Utilities for sourcing vimscript
"-----------------------------------------------------------------------------"
" Setup command windows and ensure local maps work
" Note: Here 'execute' means run the selected line
function! vim#cmdwin_setup() abort
  inoremap <buffer> <expr> <CR> ""
  nnoremap <buffer> <CR> <C-c><CR>
  nnoremap <buffer> <Plug>ExecuteFile1 <C-c><CR>
endfunction

" Refresh recently modified configuration files
" Note: This also tracks filetypes outside of current one and queues the
" update until next time function is called from within that filetype.
" let files = substitute(files, '\(^\|\n\@<=\)\s*\d*:\s*\(.*\)\($\|\n\@=\)', '\2', 'g')
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
  if !suppress
    echom 'Script names: ' . join(paths, ', ')
  endif
  return [paths, sids]
endfunction
function! vim#config_refresh(bang, ...) abort
  filetype detect  " in case started with empty file and shebang changes this
  let g:refresh_times = get(g:, 'refresh_times', {'global': localtime()})
  let default = get(g:refresh_times, 'global', 0)
  let current = localtime()
  let compare = a:0 ? a:1 : ''
  let regexes = [
    \ '/.fzf/',
    \ '/plugged/',
    \ '/\.\?vimsession*',
    \ '/\.\?vim/autoload/vim.vim',
    \ '/\(micro\|mini\|mamba\)\(forge\|conda\|mamba\)\d\?/'
    \ ]
  let regex = join(regexes, '\|')
  let loaded = []
  let updates = {}
  for path in vim#config_scripts(1)[0]
    let ftype = path =~# '/syntax/\|/ftplugin/' ? fnamemodify(path, ':t:r') : 'global'
    let vimrc = path =~# '/\.\?vimrc\|/init\.vim'  " always source and trigger filetypes
    if path !~# expand('~') || path =~# regex || !empty(compare) && path !~# compare
      continue  " skip files not edited by user or not matching input regex
    endif
    if index(loaded, path) != -1
      continue  " already loaded this
    endif
    if !vimrc && !a:bang && getftime(path) < get(g:refresh_times, ftype, default)
      continue  " only refresh if outdated
    endif
    if ftype ==# 'global' || ftype ==# &filetype
      exe 'so ' . path | call add(loaded, path) | let updates[ftype] = current
    else
      let updates[ftype] = get(g:refresh_times, ftype, default)
    endif
    if vimrc  " trigger autocommand
      doautocmd Filetype
    endif
  endfor
  doautocmd BufEnter
  echom 'Loaded: ' . join(map(loaded, "fnamemodify(v:val, ':~')[2:]"), ', ') . '.'
  call extend(g:refresh_times, updates)
endfunction

" Create session file or load existing one
" Note: Sets string for use with MacVim windows and possibly other GUIs
" See: https://vi.stackexchange.com/a/34669/8084
function! vim#session_list(lead, line, cursor) abort
  let regex = glob2regpat(a:lead)
  let regex = regex[0:len(regex) - 2]
  let opts = glob('.vimsession*', 0, 1)
  let opts = filter(opts, 'v:val =~# regex')
  echom 'Lead: ' . a:lead . ' Options: ' . join(opts, ', ')
  return opts
endfunction
function! vim#session_loaded() abort
  let regex = glob2regpat($HOME)
  let regex = regex[0:len(regex) - 2]  " remove trailing '$'
  let bufs = getbufinfo({'buflisted': 1})
  let bufs = map(bufs, 'v:val.name')
  let bufs = filter(bufs, 'v:val =~# regex')
  return len(bufs) > 0
endfunction
function! vim#init_session(...)
  if !exists(':Obsession')
    echoerr ':Obsession is not installed.'
    return
  endif
  let input = a:0 ? a:1 : ''
  let current = v:this_session
  if !empty(input) && !filereadable(a:1) && fnamemodify(a:1, ':t') !~# '^\.vimsession'
    let session = fnamemodify(a:1, ':h') . '/.vimsession-' . fnamemodify(a:1, ':t')
  elseif !empty(input)  " manual session name
    let session = a:1
  elseif !empty(current)
    let session = current
  else
    let session = '.vimsession'
  endif
  let suffix = substitute(fnamemodify(session, ':t'), '^\.vimsession[-_]*\(.*\)$', '\1', '')
  if filereadable(session) && !vim#session_loaded()
    exe 'source ' . session
  elseif !filereadable(session)
    exe 'Obsession ' . session
  else  " never overwrite existing session files
    echoerr 'Error: Cannot source session file (current session is active).'
    return 0
  endif
  if !empty(current) && fnamemodify(session, ':p') != fnamemodify(current, ':p')
    echom 'Removing old session file ' . fnamemodify(current, ':t')
    call delete(current)
  endif
  if !empty(suffix)
    echom 'Applying session title ' . suffix
    let &g:titlestring = suffix
  endif
endfunction

" Show runtime color and plugin information
" Note: Consistent with other utilities this uses separate tabs
function! vim#runtime_colors() abort
  exe 'Drop colortest.vim'
  source $VIMRUNTIME/syntax/colortest.vim
  silent call utils#popup_setup(0)
endfunction
function! vim#runtime_ftplugin() abort
  exe 'Drop $VIMRUNTIME/ftplugin/' . &filetype . '.vim'
  silent call utils#popup_setup(0)
endfunction
function! vim#runtime_syntax() abort
  exe 'Drop $VIMRUNTIME/syntax/' . &filetype . '.vim'
  silent call utils#popup_setup(0)
endfunction

" Source file or lines
" Note: Compare to python#run_content()
function! vim#source_content() abort
  if v:count
    let range = line('.') . ',' . (line('.') + v:count)
    exe range . 'source'
    echom 'Sourced ' . v:count . ' lines'
  else
    update
    source %
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
function! vim#syntax_list(name) abort
  if a:name
    exe 'verb syntax list ' . a:name
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
function! vim#vim_page(...) abort
  let item = a:0 ? a:1 : input('Vim help item: ', '', 'help')
  if !empty(item)
    exe 'vert help ' . item
  endif
endfunction
function! vim#vim_setup() abort
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
endfunction
