"-----------------------------------------------------------------------------"
" Utilities for formatting text
"-----------------------------------------------------------------------------"
" Utilitify for removing the item indicator
function! s:remove_item(line, first, last) abort
  let pattern = s:search_item(0)
  let pattern_optional = s:search_item(1)
  let match_head = substitute(a:line, pattern, '\1', '')
  let match_item = substitute(a:line, pattern, '\2', '')
  keepjumps exe a:first . ',' . a:last
    \ . 's@' . pattern_optional
    \ . '@' . match_head . repeat(' ', len(match_item)) . '\3'
    \ . '@ge'
  call histdel('/', -1)
endfunction

" Indent multiple times
function! edit#indent_items(dedent, count) range abort
  exe a:firstline . ',' . a:lastline . repeat(a:dedent ? '<' : '>', a:count)
endfunction
" For <expr> map accepting motion
function! edit#indent_items_expr(...) abort
  return utils#motion_func('edit#indent_items', a:000)
endfunction

" Search replace without polluting history
" Undoing this command will move the cursor to the first line in the range of
" lines that was changed: https://stackoverflow.com/a/52308371/4970632
" Warning: Critical to replace line-by-line in reverse order in case substitutions
" have different number of newlines. Cannot figure out how to do this in one command.
function! edit#replace_regex(message, ...) range abort
  let prevhist = @/
  let winview = winsaveview()
  for line in range(a:lastline, a:firstline, -1)
    for i in range(0, a:0 - 2, 2)
      keepjumps exe line . 's@' . a:000[i] . '@' . a:000[i + 1] . '@ge'
      call histdel('/', -1)
    endfor
  endfor
  echom a:message
  let @/ = prevhist
  call winrestview(winview)
endfunction
" For <expr> map accepting motion
function! edit#replace_regex_expr(...) abort
  return utils#motion_func('edit#replace_regex', a:000)
endfunction

" Wrap the lines to 'count' columns rather than 'textwidth'
" Note: Could put all commands in feedkeys() but then would get multiple
" commands flashing at bottom of screen. Also need feedkeys() because normal
" doesn't work inside an expression mapping.
function! edit#wrap_lines(...) range abort
  let textwidth = &l:textwidth
  let &l:textwidth = a:0 ? a:1 ? a:1 : textwidth : textwidth
  let cmd =
    \ a:lastline . 'gggq' . a:firstline . 'gg'
    \ . ':silent let &l:textwidth = ' . textwidth
    \ . " | echom 'Wrapped lines to " . &l:textwidth . " characters.'\<CR>"
  call feedkeys(cmd, 'n')
endfunction
" For <expr> map accepting motion
function! edit#wrap_lines_expr(...) abort
  return utils#motion_func('edit#wrap_lines', a:000)
endfunction

" Return regexes for search
function! s:search_item(optional)
  let head = '^\(\s*\%(' . comment#comment_char() . '\s*\)\?\)'  " leading spaces or comment
  let indicator = '\(\%([*-]\|\<\d\.\|\<\a\.\)\s\+\)'  " item indicator plus space
  let tail = '\(.*\)$'  " remainder of line
  if a:optional
    let indicator = indicator . '\?'
  endif
  return head . indicator . tail
endfunction

" Fix all lines that are too long, with special consideration for bullet style lists and
" asterisks (does not insert new bullets and adds spaces for asterisks).
" Note: This is good example of incorporating motion support in custom functions!
" Note: Optional arg values is vim 8.1+ feature; see :help optional-function-argument
" See: https://vi.stackexchange.com/a/7712/8084 and :help g@
function! edit#wrap_items(...) range abort
  " Initial stuff
  let textwidth = &l:textwidth
  let &l:textwidth = a:0 ? a:1 ? a:1 : textwidth : textwidth
  let prevhist = @/
  let winview = winsaveview()
  let pattern = s:search_item(0)
  " Put lines on a single bullet
  let linecount = 0
  let lastline = a:lastline
  for linenum in range(a:lastline, a:firstline, -1)
    let line = getline(linenum)
    let linecount += 1
    if line =~# pattern
      let upper = '^\s*[*_]*[A-Z]'  " upper case optionally surrounded by emphasis
      let tail = substitute(line, pattern, '\3', '')
      if tail !~# upper  " remove item indicator if starts with lowercase
        call s:remove_item(line, linenum, linenum)
      else  " otherwise join count lines and adjust lastline
        exe linenum . 'join ' . linecount
        let lastline -= linecount - 1
        let linecount = 0
      endif
    endif
  endfor
  " Wrap each line, accounting for bullet indent. If gqgq results in a wrapping, cursor
  " is placed at end of that block. Then must remove auto-inserted item indicators.
  for linenum in range(lastline, a:firstline, -1)
    exe linenum
    let line = getline('.')
    normal! gqgq
    if line =~# pattern && line('.') > linenum
      call s:remove_item(line, linenum + 1, line('.'))
    endif
  endfor
  let @/ = prevhist
  call winrestview(winview)
  let &l:textwidth = textwidth
endfunction
" For <expr> map accepting motion
function! edit#wrap_items_expr(...) abort
  return utils#motion_func('edit#wrap_items', a:000)
endfunction
