"-----------------------------------------------------------------------------"
" Utilities for formatting text
"-----------------------------------------------------------------------------"
" Inserting blank lines
" See: https://github.com/tpope/vim-unimpaired
function! edit#blank_up(count) abort
  put!=repeat(nr2char(10), a:count)
  ']+1
  silent! call repeat#set("\<Plug>BlankUp", a:count)
endfunction
function! edit#blank_down(count) abort
  put =repeat(nr2char(10), a:count)
  '[-1
  silent! call repeat#set("\<Plug>BlankDown", a:count)
endfunction

" Forward delete by tabs
function! edit#forward_delete() abort
  let line = getline('.')
  if line[col('.') - 1:col('.') - 1 + &tabstop - 1] == repeat(' ', &tabstop)
    return repeat("\<Delete>", &tabstop)
  else
    return "\<Delete>"
  endif
endfunction

" Indent multiple times
function! edit#indent_items(dedent, count) range abort
  exe a:firstline . ',' . a:lastline . repeat(a:dedent ? '<' : '>', a:count)
endfunction
" For <expr> map accepting motion
function! edit#indent_items_expr(...) abort
  return utils#motion_func('edit#indent_items', a:000)
endfunction

" Toggle insert and command-mode caps lock
" See: http://vim.wikia.com/wiki/Insert-mode_only_Caps_Lock which uses
" iminsert to enable/disable lnoremap, with iminsert changed from 0 to 1
function! edit#lang_map()
  let b:caps_lock = exists('b:caps_lock') ? 1 - b:caps_lock : 1
  if b:caps_lock
    for s:c in range(char2nr('A'), char2nr('Z'))
      exe 'lnoremap <buffer> ' . nr2char(s:c + 32) . ' ' . nr2char(s:c)
      exe 'lnoremap <buffer> ' . nr2char(s:c) . ' ' . nr2char(s:c + 32)
    endfor
    augroup caps_lock
      au!
      au InsertLeave,CmdwinLeave * setlocal iminsert=0 | let b:caps_lock = 0 | autocmd! caps_lock
    augroup END
  endif
  return "\<C-^>"
endfunction

" Set up temporary paste mode
function! edit#paste_mode() abort
  let s:paste = &paste
  let s:mouse = &mouse
  set paste
  set mouse=
  augroup insert_paste
    au!
    au InsertLeave *
      \ if exists('s:paste') |
      \   let &paste = s:paste |
      \   let &mouse = s:mouse |
      \   unlet s:paste |
      \   unlet s:mouse |
      \ endif |
      \ autocmd! insert_paste
  augroup END
  return ''
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

" Reverse the selected lines
" Note: Adaptation of hard-to-remember :g command shortcut. Adapted
" from super old post: https://vim.fandom.com/wiki/Reverse_order_of_lines
function! edit#reverse_lines() range abort
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  let num = empty(range) ? 0 : a:firstline - 1
  exec 'silent ' . range . 'g/^/m' . num
endfunction

" Correct next misspelled word
" This provides functionality similar to [t and ]s
function! edit#spell_apply(forward)
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

" Swap characters or lines
" Note: This does not affect registers
function! edit#swap_characters(right) abort
  let cnum = col('.')
  let line = getline('.')
  let idx = a:right ? cnum : cnum - 1
  if idx > 0 && idx < len(line)
    let line = line[:idx - 2] . line[idx] . line[idx - 1] . line[idx + 1:]
    call setline('.', line)
  endif
endfunction
function! edit#swap_lines(bottom) abort
  let offset = a:bottom ? 1 : -1
  let lnum = line('.')
  if lnum + offset > 0 && lnum + offset < line('$')
    let line1 = getline(lnum)
    let line2 = getline(lnum + offset)
    call setline(lnum, line2)
    call setline(lnum + offset, line1)
  endif
  exe lnum + offset
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

" Fix all lines that are too long, with special consideration for bullet style lists and
" asterisks (does not insert new bullets and adds spaces for asterisks).
" Note: This is good example of incorporating motion support in custom functions!
" Note: Optional arg values is vim 8.1+ feature; see :help optional-function-argument
" See: https://vi.stackexchange.com/a/7712/8084 and :help g@
" Return regexes for the search
function! s:search_item(optional)
  let head = '^\(\s*\%(' . comment#get_char() . '\s*\)\?\)'  " leading spaces or comment
  let indicator = '\(\%([*-]\|\<\d\.\|\<\a\.\)\s\+\)'  " item indicator plus space
  let tail = '\(.*\)$'  " remainder of line
  if a:optional
    let indicator = indicator . '\?'
  endif
  return head . indicator . tail
endfunction
" Remove the item indicator
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
" Put lines on single bullet
function! edit#wrap_items(...) range abort
  let textwidth = &l:textwidth
  let &l:textwidth = a:0 ? a:1 ? a:1 : textwidth : textwidth
  let prevhist = @/
  let winview = winsaveview()
  let pattern = s:search_item(0)
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
  for linenum in range(lastline, a:firstline, -1)  " wrap accounting for bullet indent
    exe linenum
    let line = getline('.')
    normal! gqgq
    if line =~# pattern && line('.') > linenum  " cursor is at end of wrapping
      call s:remove_item(line, linenum + 1, line('.'))  " remove auto-inserted item indicators
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
