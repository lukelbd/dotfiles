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

" Easy conversion between key=value pairs and 'key': value dictionary entries
" Do son on current line, or within visual selection
function! python#translate_kwargs_dict(kw2dc, ...) abort range
  " First get columns
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
    " Annoying ugly block for getting visual selection
    " Want to *ignore* stuff not in selection, but on same line as
    " the start/end of selection, because it's more flexible
    let line = getline(linenum)
    let prefix = ''
    let suffix = ''
    if linenum == firstline && linenum == lastline
      let prefix = firstcol >= 1 ? line[:firstcol - 1] : ''  " damn negative indexing makes this complicated
      let suffix = line[lastcol + 1:]
      let line = line[firstcol : lastcol]
    elseif linenum == firstline
      let prefix = firstcol >= 1 ? line[:firstcol - 1] : ''
      let line = line[firstcol :]
    elseif linenum == lastline
      let suffix = line[lastcol + 1:]
      let line = line[:lastcol]
    endif
    if !empty(matchstr(line, ':')) && !empty(matchstr(line, '='))
      echoerr 'Error: Ambiguous line.'
      return
    endif

    " Next finally start matching shit
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
function! python#translate_kwargs_dict_expr(kw2dc) abort
  return utils#motion_func('python#translate_kwargs_dict', [a:kw2dc, mode()])
endfunction
