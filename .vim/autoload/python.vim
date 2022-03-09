"-----------------------------------------------------------------------------"
" Python utils defined here
"-----------------------------------------------------------------------------"
" Sort lines
function! s:sort_lines(line1, line2) abort
  let line1 = a:line1
  let line2 = a:line2
  if line1 > line2
    let [line2, line1] = [line1, line2]
  endif
  return [line1, line2]
endfunction

" Return indication whether a jupyter connection is active
" Warning: Monitor private variable _jupyter_session for changes
function! python#has_jupyter() abort
  let check = ''
    \ . '"_jupyter_session" in globals() '
    \ . ' and _jupyter_session.kernel_client.check_connection()'
  return str2nr(py3eval('int(' . check . ')'))
endfunction

" Run with popup window using conda python, not vim python (important for macvim)
" Todo: More robust checking for anaconda python in other places.
function! python#run_win()
  let exe = $HOME . '/miniconda3/bin/python'
  let proj = $HOME . '/miniconda3/share/proj'
  let cmd = 'PROJ_LIB=' . shellescape(proj) . ' ' . shellescape(exe) . ' ' . shellescape(@%)
  call popup#job_win(cmd)
endfunction

" Run current file using either popup window or jupyter session
function! python#run_file() abort
  update
  echom 'Running entire file.'
  if python#has_jupyter()
    JupyterRunFile
  else
    call python#run_win()
  endif
endfunction

" Run input motion using jupyter session
" Note: Warning will be issued if connection not established.
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
  let firstcol = col("'" . marks[0]) - 1  " when calling col(), ' means `
  let lastcol = len(getline("'" . marks[1])) - 1
  let [firstline, lastline] = s:sort_lines(a:firstline, a:lastline)
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
      echoerr 'Error: Text is both dictionary-like and kwarg-like.'
      return
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
  silent exe firstline . ',' . lastline . 'd _'
  call append(firstline - 1, lines)
  call winrestview(winview)
endfunction

" For <expr> map accepting motion
function! python#kwargs_dict_expr(kw2dc) abort
  return utils#motion_func('python#kwargs_dict', [a:kw2dc, mode()])
endfunction
