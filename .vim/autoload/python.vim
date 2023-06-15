"-----------------------------------------------------------------------------"
" Python utils defined here
"-----------------------------------------------------------------------------"
" Return indication whether a jupyter connection is active
" Warning: This uses private variable _jupyter_session. Should monitor for changes.
function! python#has_jupyter() abort
  let check = ''
    \ . '"_jupyter_session" in globals() '
    \ . ' and _jupyter_session.kernel_client.check_connection()'
  return str2nr(py3eval('int(' . check . ')'))
endfunction

" Initiate a jupyter-vim connection using the file matching this directory or a parent
" Note: This relies on automatic connection file naming in jupyter_[qt|]console.py
" Note: The jupyter-vim plugin offloads connection file searching to jupyter_client's
" find_connection_file(), which selects the most recently accessed file from the glob
" pattern. Therefore pass the entire pattern to jupyter#Connect() rather than the file.
function! python#start_jupyter() abort
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
function! python#run_win()
  if !exists('$CONDA_PREFIX')
    echohl WarningMsg
    echom 'Cannot find conda prefix.'
    echohl None
  else
    let exe = $CONDA_PREFIX . '/bin/python'
    let proj = $CONDA_PREFIX . '/share/proj'
    let cmd = 'PROJ_LIB=' . shellescape(proj) . ' ' . shellescape(exe) . ' ' . shellescape(@%)
    silent call popup#job_win(cmd)
  endif
endfunction

" Run current file using either popup window or jupyter session
" Note: Running 'cell' in file without cells still works
function! python#run_content() abort
  update
  if !python#has_jupyter()
    call python#run_win()
    echom 'Running file with python.'
  elseif search('^# %%', 'n')  " returns line number if match found, zero if none found
    JupyterSendCell
    echom 'Running block with jupyter.'
  else
    JupyterRunFile
    echom 'Running file with jupyter.'
  endif
endfunction

" Run input motion using jupyter session. Warning is issued if no connection
" Todo: Add generalization for running chunks of arbitrary filetypes?
" Warning: Important that 'count' comes first so range is ignored
function! python#run_motion() range abort
  update
  if v:count
    echom 'Running ' . v:count . ' lines.'
    exe 'JupyterSendCount ' . v:count
  else
    echom 'Running lines ' . a:firstline . ' to ' . a:lastline . '.'
    exe a:firstline . ',' . a:lastline . 'JupyterSendRange'
  endif
endfunction
" For <expr> map accepting motion
function! python#run_motion_expr(...) abort
  return utils#motion_func('python#run_motion', a:000)
endfunction

" Easy conversion between key=value pairs and 'key': value dictionary entries
" Do son on current line, or within visual selection
function! python#kwargs_dict(kw2dc, ...) abort range
  " First get selection columns
  " Warning: Use kludge where lastcol is always at the end of line. Accounts for weird
  " bug where if opening bracket is immediately followed by newline, then 'inner'
  " bracket range incorrectly sets the closing bracket column position to '1'.
  let winview = winsaveview()
  let lines = []
  let marks = a:0 && a:1 ==# 'n' ? '[]' : '<>'
  let firstcol = col("'" . marks[0]) - 1  " in col() single quote ' really means `
  let lastcol = len(getline("'" . marks[1])) - 1
  let [firstline, lastline] = sort([a:firstline, a:lastline])
  for linenum in range(firstline, lastline)
    " Get selection text ignoring unselected parts of first and last line
    let line = getline(linenum)
    let prefix = ''
    let suffix = ''
    if linenum == firstline && linenum == lastline
      let prefix = firstcol >= 1 ? line[:firstcol - 1] : ''
      let suffix = line[lastcol + 1:]
      let line = line[firstcol : lastcol]
    elseif linenum == firstline
      let prefix = firstcol >= 1 ? line[:firstcol - 1] : ''
      let line = line[firstcol :]
    elseif linenum == lastline
      let suffix = line[lastcol + 1:]
      let line = line[:lastcol]
    endif
    " Run fancy translation substitutions
    if !empty(matchstr(line, ':')) && !empty(matchstr(line, '='))
      echohl WarningMsg
      echom 'Warning: Text is both dictionary-like and kwarg-like.'
      echohl None
    endif
    if a:kw2dc == 1  " kwargs to dictionary
      let line = substitute(line, '\<\ze\w\+\s*=', "'", 'g')  " add leading quote first
      let line = substitute(line, '\>\ze\s*=', "'", 'g')
      let line = substitute(line, '\s*=\s*', ': ', 'g')
    else
      let line = substitute(line, "\\>['\"]" . '\ze\s*:', '', 'g')  " remove trailing quote first
      let line = substitute(line, "['\"]\\<" . '\ze\w\+\s*:', '', 'g')
      let line = substitute(line, '\s*:\s*', '=', 'g')
    endif
    call add(lines, prefix . line . suffix)
  endfor
  " Replace lines with fixed lines
  exe firstline . ',' . lastline . 'd _'
  call append(firstline - 1, lines)
  call winrestview(winview)
endfunction
" For <expr> map accepting motion
function! python#kwargs_dict_expr(kw2dc) abort
  return utils#motion_func('python#kwargs_dict', [a:kw2dc, mode()])
endfunction
