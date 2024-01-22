"-----------------------------------------------------------------------------"
" Utilities for formatting text
"-----------------------------------------------------------------------------"
" Indent and calculator motion functions
" Note: Native calculator only supports visual-mode but here add motions.
" See: https://github.com/sk1418/HowMuch/blob/master/autoload/HowMuch.vim
function! edit#how_much_expr(...) abort
  return utils#motion_func('HowMuch#HowMuch', a:000)
endfunction
function! edit#indent_items(dedent, count) range abort
  exe a:firstline . ',' . a:lastline . repeat(a:dedent ? '<' : '>', a:count)
endfunction
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
" Note: Removed automatically when insert mode is abandoned
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

" Search replace without history. Undo will move the cursor to the first line in the
" range of lines that was changed: https://stackoverflow.com/a/52308371/4970632
" Warning: Critical to replace line-by-line in reverse order in case substitutions
" have different number of newlines. Cannot figure out how to do this in one command.
function! edit#replace_regex(message, ...) range abort
  let search = @/  " hlsearch pattern
  let winview = winsaveview()
  for line in range(a:lastline, a:firstline, -1)
    for idx in range(0, a:0 - 2, 2)
      " vint: -ProhibitUsingUndeclaredVariable
      let [regex, string] = a:000[idx:idx + 1]
      keepjumps exe line . 's@' . regex . '@' . string . '@ge'
      call histdel('/', -1)
    endfor
  endfor
  echom a:message
  let @/ = search
  call winrestview(winview)
endfunction
" For <expr> map accepting motion
function! edit#replace_regex_expr(...) abort
  return utils#motion_func('edit#replace_regex', a:000)
endfunction

" Reverse or sort the input lines
" Note: Adaptation of hard-to-remember :g command shortcut. Adapted
" from super old post: https://vim.fandom.com/wiki/Reverse_order_of_lines
function! edit#sort_lines() range abort
  let [line1, line2] = sort([a:firstline, a:lastline], 'n')
  exe 'silent ' . line1 . ',' . line2 . 'sort'
endfunction
function! edit#reverse_lines() range abort
  let [line1, line2] = sort([a:firstline, a:lastline], 'n')
  let range = line1 == line2 ? '' : line1 . ',' . line2
  let num = empty(range) ? 0 : line1 - 1
  exe 'silent ' . range . 'g/^/m' . num
endfunction
" For <expr> map accepting motion
function! edit#sort_lines_expr() range abort
  return utils#motion_func('edit#sort_lines', a:000)
endfunction
function! edit#reverse_lines_expr(...) abort
  return utils#motion_func('edit#reverse_lines', a:000)
endfunction

" Spell check under cursor
" Note: This improves '1z=' to return nothing when called on valid words.
" Note: If nothing passed and no manual count then skip otherwise continue.
function! edit#spell_bad(...) abort
  let word = a:0 ? a:1 : expand('<cword>')
  let [fixed, which] = spellbadword(word)
  return !empty(fixed)
endfunction
function! edit#spell_next(...) abort
  let reverse = a:0 ? a:1 : 0
  if !edit#spell_bad()
    exe 'normal! ' . (reverse ? '[s' : ']s')
  endif
  call edit#spell_check(1)
endfunction
function! edit#spell_check(...) abort
  if a:0 || v:count || edit#spell_bad()
    let nr = a:0 ? a:1 : v:count1
    let nr = nr ? string(nr) : ''
    echom 'Spell check: ' . expand('<cword>')
    if empty(nr)
      call feedkeys('z=', 'n')
    else
      exe 'normal! ' . nr . 'z='
    endif
  endif
endfunction

" Swap characters or lines
" Note: This does not affect registers
function! edit#swap_chars(...) abort
  let cnum = col('.')
  let text = getline('.')
  let idx = a:0 && a:1 ? cnum - 1 : cnum
  if idx > 0 && idx < len(text)
    let text = text[:idx - 2] . text[idx] . text[idx - 1] . text[idx + 1:]
    call setline('.', text)
  endif
endfunction
function! edit#swap_lines(...) abort
  let delta = a:0 && a:1 ? -1 : 1
  let line1 = line('.')
  if line1 + delta < 1 || line1 + delta > line('$')
    return
  endif
  if foldclosed(line1) > 0
    let [line11, line12] = [foldclosed(line1), foldclosedend(line1)]
  else
    let [line11, line12] = [line1, line1]
  endif
  let line2 = delta > 0 ? line12 + delta : line11 + delta
  let [fold1, fold2] = [foldlevel(line1) >= 0, foldlevel(line2) >= 0]
  let [close1, close2] = [foldclosed(line1) > 0, foldclosed(line2) > 0]
  if foldclosed(line2) > 0
    let [line21, line22] = [foldclosed(line2), foldclosedend(line2)]
  else
    let [line21, line22] = [line2, line2]
  endif
  let [line1, line2] = delta > 0 ? [line11, line22] : [line21, line12]
  let [text1, text2] = [getline(line11, line12), getline(line21, line22)]
  call deletebufline(bufnr(), line1, line2)  " delete without register
  call append(line1 - 1, delta > 0 ? text2 + text1 : text1 + text2)
  let range1 = (line11 + delta * len(text2)) . ',' . (line12 + delta * len(text2))
  let range2 = (line21 - delta * len(text1)) . ',' . (line22 - delta * len(text1))
  if fold1 | exe range1 . 'fold' | exe range1 . (close1 ? 'foldclose' : 'foldopen') | endif
  if fold2 | exe range2 . 'fold' | exe range2 . (close2 ? 'foldclose' : 'foldopen') | endif
  exe line21
  exe close1 ? '' : 'normal! zv'
endfunction

" Wrap the lines to 'count' columns rather than 'text width'
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
      let upper = '^\s*\(<[^>]\+>\|[*_]*\)*[A-Z]'
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
