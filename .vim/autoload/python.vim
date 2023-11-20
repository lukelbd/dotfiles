"-----------------------------------------------------------------------------"
" Python utils defined here
"-----------------------------------------------------------------------------"
" Convert between key=value pairs and 'key': value dictionaries
" Warning: Use kludge where lastcol is always at the end of line. Accounts for weird
" bug where if opening bracket is immediately followed by newline, then 'inner'
" bracket range incorrectly sets the closing bracket column position to '1'.
function! python#dict_to_kw(invert, ...) abort range
  let winview = winsaveview()
  let lines = []
  let marks = a:0 && a:1 ==# 'n' ? '[]' : '<>'
  let firstcol = col("'" . marks[0]) - 1  " first column, note ' really means ` here
  let lastcol = len(getline("'" . marks[1])) - 1  " last selection column
  let [firstline, lastline] = sort([a:firstline, a:lastline], 'n')
  for lnum in range(firstline, lastline)
    let [line, prefix, suffix] = [getline(lnum), '', '']
    if lnum == firstline && lnum == lastline  " vint: -ProhibitUsingUndeclaredVariable
      let prefix = firstcol > 0 ? line[:firstcol - 1] : ''
      let suffix = line[lastcol + 1:]
      let line = line[firstcol:lastcol]  " must come last
    elseif lnum == firstline
      let prefix = firstcol > 0 ? line[:firstcol - 1] : ''
      let line = line[firstcol:]  " must come last
    elseif lnum == lastline
      let suffix = line[lastcol + 1:]
      let line = line[:lastcol]  " must come last
    endif
    if !empty(matchstr(line, ':')) && !empty(matchstr(line, '='))
      echohl WarningMsg
      echom 'Warning: Text is both dictionary-like and kwarg-like.'
      echohl None
    endif
    if a:invert  " dictionary to kwargs
      let line = substitute(line, '\<\ze\w\+\s*=', "'", 'g')  " add leading quote first
      let line = substitute(line, '\>\ze\s*=', "'", 'g')
      let line = substitute(line, '\s*=\s*', ': ', 'g')
    else
      let line = substitute(line, '\>[''"]\ze\s*:', '', 'g')  " remove trailing quote first
      let line = substitute(line, '[''"]\<\ze\w\+\s*:', '', 'g')
      let line = substitute(line, '\s*:\s*', '=', 'g')
    endif
    call add(lines, prefix . line . suffix)
  endfor
  exe firstline . ',' . lastline . 'd _'
  call append(firstline - 1, lines)  " replace with fixed lines
  call winrestview(winview)
  call cursor(firstline, firstcol)
endfunction
" For <expr> map accepting motion
function! python#dict_to_kw_expr(invert) abort
  return utils#motion_func('python#dict_to_kw', [a:invert, mode()])
endfunction

" Folding expression to add global constants and docstrings to SimpylFold cache
" Note: Here 'fold_edit' refreshes folds after calling :edit and for some reason
" is required to open files with overridden folds (especially BufWritePost).
" Warning: Only call this when SimpylFold updates to improve performance. Might break
" if SimpylFold renames internal cache variable (monitor). Note
function! s:fold_exists(lnum) abort
  return exists('b:SimpylFold_cache')
    \ && !empty(b:SimpylFold_cache[a:lnum])
    \ && !empty(b:SimpylFold_cache[a:lnum]['foldexpr'])  " note empty(0) returns 1
endfunction
function! python#fold_expr(lnum) abort
  let recache = !exists('b:SimpylFold_cache')
  call SimpylFold#FoldExpr(a:lnum)  " auto recache
  if recache | call python#fold_cache() | endif
  return b:SimpylFold_cache[a:lnum]['foldexpr']
endfunction
function! python#fold_cache() abort
  let lnum = 1
  let cache = b:SimpylFold_cache
  let global = '^[A-Z_]\k*'
  let docstring = '[frub]*["'']\{3}'  " doctring regex (see fold.vim)
  while lnum <= line('$')
    if s:fold_exists(lnum) | let lnum += 1 | continue | endif
    let line = getline(lnum)
    let group = []
    " Docstring fold (e.g. _docstring_snippet = '''...)
    let [_, _, pos] = matchstrpos(line, '^\(#\|\s\)\@!.*' . docstring)
    if pos > -1  " vint: -ProhibitUsingUndeclaredVariable
      call add(group, lnum)
      while line[pos:] !~# docstring  " fold entire docstring
        let pos = 0
        let lnum += 1
        let line = getline(lnum)
        call add(group, lnum)
        if s:fold_exists(lnum) | let group = [] | break | endif
      endwhile
    endif
    " Variable fold (e.g. GLOBAL_VARIABLE = [...)
    if empty(group) && line =~# global  " zero-indent private or global variable
      call add(group, lnum)
      while lnum < line('$') && get(cache[lnum + 1], 'indent', 0)  " fold indents
        let lnum += 1
        call add(group, lnum)
        if s:fold_exists(lnum) | let group = [] | break | endif
      endwhile
      if len(group) > 1
        let lnum += 1
        call add(group, lnum)
      endif
    endif
    " Apply results (see :help fold-expr)
    if len(group) > 1  " constant group found
      let cache[group[0]]['foldexpr'] = '>1'  " fold start
      let cache[group[-1]]['foldexpr'] = '<1'  " fold end
      for value in range(group[1], group[-2])  " avoid overwriting 'lnum'
        let cache[value]['foldexpr'] = 1
      endfor
    endif
    let lnum += 1  " e.g. termination of constant group
  endwhile
endfunction

" Initiate jupyter-vim connection using the file matching this directory or a parent
" Note: This relies on automatic connection file naming in jupyter_[qt|]console.py.
" Also depends on private variable _jupyter_session. Should monitor for changes.
" Note: The jupyter-vim plugin offloads connection file searching to jupyter_client's
" find_connection_file(), which selects the most recently accessed file from the glob
" pattern. Therefore pass the entire pattern to jupyter#Connect() rather than the file.
function! python#has_jupyter() abort
  let check = (
    \ '"_jupyter_session" in globals() and '
    \ . '_jupyter_session.kernel_client.check_connection()'
  \ )
  if has('python3')
    return str2nr(py3eval('int(' . check . ')'))
  else
    return 0
  endif
endfunction
function! python#init_jupyter() abort
  let parent = 0
  let runtime = trim(system('jupyter --runtime-dir'))  " vim 8.0.163: https://stackoverflow.com/a/53250594/4970632
  while !exists('folder') || !empty(folder)  " note default scope is l: (g: is ignored)
    let parent += 1
    let string = '%:p' . repeat(':h', parent)
    let folder = expand(string . ':t')
    let path = expand(string)
    let pattern = 'kernel-' . folder . '-[0-9][0-9].json'
    if !empty(glob(runtime . '/' . pattern)) | return jupyter#Connect(pattern) | endif
  endwhile
  echohl WarningMsg
  echom "Warning: No connection files found for path '" . expand('%:p:h') . "'."
  echohl None
endfunction

" Run with popup window using conda python, not vim python (important for macvim)
" Todo: More robust checking for anaconda python in other places.
function! python#run_file()
  if !exists('$CONDA_PREFIX')
    echohl WarningMsg
    echom 'Cannot find conda prefix.'
    echohl None
  else
    let exe = $CONDA_PREFIX . '/bin/python'
    let proj = $CONDA_PREFIX . '/share/proj'
    let cmd = 'PROJ_LIB=' . shellescape(proj) . ' ' . shellescape(exe) . ' ' . shellescape(@%)
    silent call shell#job_win(cmd)
  endif
endfunction

" Run file or lines using either popup window or jupyter session
" Note: Running 'cell' in file without cells still works
function! python#run_general() abort
  update
  if v:count  " see also vim.vim
    echom 'Running ' . v:count . ' lines'
    exe 'JupyterSendCount ' . v:count
  elseif !python#has_jupyter()
    echom 'Running file with python'
    call python#run_file()
  elseif search('^# %%', 'n')  " returns line number if match found, zero if none found
    echom 'Running block with jupyter'
    JupyterSendCell
  else
    echom 'Running file with jupyter'
    JupyterRunFile
  endif
endfunction

" Run input motion using jupyter session. Warning is issued if no connection
" Todo: Add generalization for running chunks of arbitrary filetypes?
function! python#run_motion() range abort
  update
  if python#has_jupyter()
    echom 'Running lines ' . a:firstline . ' to ' . a:lastline . '.'
    exe a:firstline . ',' . a:lastline . 'JupyterSendRange'
  else
    echohl WarningMsg
    echom 'Jupyter session not found. Cannot send selection.'
    echohl None
  endif
endfunction
" For <expr> map accepting motion
function! python#run_motion_expr(...) abort
  return utils#motion_func('python#run_motion', a:000)
endfunction

" Split docstrings over multiple lines
" Note: This is used to adjust vim-pydocstring without using complicated template files.
" Use 'timer_start' to avoid race condition with plugin job (see ftplugin/python.vim).
" Note: This ensures correct indentation after line break. Below shows alternative
" approach using 'gnd' and auto-indent by adding newline to @" match via @= and using
" indent-preserving paste ]p. See https://stackoverflow.com/a/2783670/4970632
" exe 'global/' . regex . '/normal! gnd"="\n" . @"' . '\<CR>' . ']p'
function! python#split_docstrings(...) abort
  let regex = '["'']\{3}\n\@!\zs.*$'
  let cmd = "normal! gnc\<CR>\<C-r>\""
  exe 'global/' . regex . '/' . cmd
  let regex = '\(\(^\|\_s\)[frub]*\)\@<!'
  let regex = regex . '["'']\{3}\s*$'
  exe 'global/' . regex . '/' . cmd
endfunction
