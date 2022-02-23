"-----------------------------------------------------------------------------"
" Utilities for formatting text
"-----------------------------------------------------------------------------"
" Build regexes
let s:item_head = '^\(\s*\%(' . Comment() . '\s*\)\?\)'  " leading spaces or comment
let s:item_indicator = '\(\%([*-]\|\d\+\.\|\a\+\.\)\s\+\)'  " item indicator plus space
let s:item_tail = '\(.*\)$'  " remainder of line
let s:item_total = s:item_head . s:item_indicator . s:item_tail

" Utilitify for removing the item indicator
function! s:remove_item(line, firstline_, lastline_) abort
  let match_head = substitute(a:line, s:item_total, '\1', '')
  let match_item = substitute(a:line, s:item_total, '\2', '')
  keepjumps exe a:firstline_ . ',' . a:lastline_
    \ . 's@' . s:item_head . s:item_indicator . '\?' . s:item_tail
    \ . '@' . match_head . repeat(' ', len(match_item)) . '\3'
    \ . '@ge'
  call histdel('/', -1)
endfunction

" Indent multiple times
function! format#indent_items(dedent, count) range abort
  exe a:firstline . ',' . a:lastline . repeat(a:dedent ? '<' : '>', a:count)
endfunction
" For <expr> map accepting motion
function! format#indent_items_expr(...) abort
  return utils#motion_func('format#indent_items', a:000)
endfunction

" Search replace without polluting history
" Undoing this command will move the cursor to the first line in the range of
" lines that was changed: https://stackoverflow.com/a/52308371/4970632
function! format#replace_regexes(message, ...) range abort
  let prevhist = @/
  let winview = winsaveview()
  for i in range(0, a:0 - 2, 2)
    keepjumps exe a:firstline . ',' . a:lastline . 's@' . a:000[i] . '@' . a:000[i + 1] . '@ge'
    call histdel('/', -1)
  endfor
  echom a:message
  let @/ = prevhist
  call winrestview(winview)
endfunction
" For <expr> map accepting motion
function! format#replace_regexes_expr(...) abort
  return utils#motion_func('format#replace_regexes', a:000)
endfunction

" Correct next misspelled word
" This provides functionality similar to [t and ]s
function! format#spell_fix(forward)
  let nospell = 0
  if !&l:spell
    let nospell = 1
    setlocal spell
  endif
  let winview = winsaveview()
  exe 'normal! ' . (a:forward ? 'bh' : 'el')
  exe 'normal! ' . (a:forward ? ']' : '[') . 's'
  normal! 1z=
  call winrestview(winview)
  if nospell
    setlocal nospell
  endif
endfunction

" Wrap the lines to 'count' columns rather than 'textwidth'
" Note: Could put all commands in feedkeys() but then would get multiple
" commands flashing at bottom of screen. Also need feedkeys() because normal
" doesn't work inside an expression mapping.
function! format#wrap_lines(...) range abort
  let textwidth = &l:textwidth
  let &l:textwidth = a:0 ? a:1 ? a:1 : textwidth : textwidth
  let cmd =
    \ a:lastline . 'gggq' . a:firstline . 'gg'
    \ . ':silent let &l:textwidth = ' . textwidth
    \ . " | echom 'Wrapped lines to " . &l:textwidth . " characters.'\<CR>"
  call feedkeys(cmd, 'n')
endfunction
" For <expr> map accepting motion
function! format#wrap_lines_expr(...) abort
  return utils#motion_func('format#wrap_lines', a:000)
endfunction

" Fix all lines that are too long, with special consideration for bullet style lists and
" asterisks (does not insert new bullets and adds spaces for asterisks).
" Note: This is good example of incorporating motion support in custom functions!
" Note: Optional arg values is vim 8.1+ feature; see :help optional-function-argument
" See: https://vi.stackexchange.com/a/7712/8084 and :help g@
function! format#wrap_items(...) range abort
  let textwidth = &l:textwidth
  let &l:textwidth = a:0 ? a:1 ? a:1 : textwidth : textwidth
  let prevhist = @/
  let winview = winsaveview()
  " Put lines on a single bullet
  let linecount = 0
  let lastline = a:lastline
  for linenum in range(a:lastline, a:firstline, -1)
    let line = getline(linenum)
    let linecount += 1
    if line =~# s:item_total
      let tail = substitute(line, s:item_total, '\3', '')
      if tail =~# '^\s*[a-z]'  " remove item indicator if starts with lowercase
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
    if line =~# s:item_total && line('.') > linenum
      call s:remove_item(line, linenum + 1, line('.'))
    endif
  endfor
  let @/ = prevhist
  call winrestview(winview)
  let &l:textwidth = textwidth
endfunction
" For <expr> map accepting motion
function! format#wrap_items_expr(...) abort
  return utils#motion_func('format#wrap_items', a:000)
endfunction
