"-----------------------------------------------------------------------------"
" Utilities for formatting text
"-----------------------------------------------------------------------------"
" Call external plugins
" Note: Native delimitMate#ExpandReturn() issues <Esc> then fails to split brackets due
" to InsertLeave autocommand that repositions cursor. Use <C-c> to avoid InsertLeave.
let s:delimit_mate = {'s': 'ExpandSpace', 'r': 'ExpandReturn', 'b': 'BS'}
function! edit#echo_range(msg, num) range abort
  echo a:msg . (a:msg =~# '\s' ? ' on' : '') . ' ' . a:num . ' line(s)'
endfunction
function! edit#how_much(...) abort
  return utils#motion_func('HowMuch#HowMuch', a:000)
endfunction

" Indent or join lines by count
" Note: Native vim indent uses count to move over number of lines, but redundant
" with e.g. 'd2k', so instead use count to denote indentation level.
" Note: Native vim join uses count to join n lines including parent line, so e.g.
" 1J and 2J have the same effect. This adds to count to make join more intuitive
function! edit#conjoin_lines(before, spaces, ...) abort
  let njoin = a:0 ? a:1 : v:count1 + (v:count > 1)
  let nmove = a:0 ? a:1 : v:count1
  let key = a:spaces ? 'gJ' : 'J'
  let head = mode() =~? '^n' ? a:before ? nmove . 'k' . njoin : njoin : ''
  let name = mode() =~? '^n' ? 'Normal' : 'Visual'
  let conjoin = 'call conjoin#join' . name . '(' . string(key) . ')'
  let cursor = "call cursor('.', " . col('.') . ')'
  let range = mode() =~# 'v\|V\|' ? "\<Esc>\<Cmd>'<,'>" : "\<Cmd>"
  call feedkeys(head . range . conjoin . "\<CR>", 'n')
  call feedkeys("\<Cmd>" . cursor . "\<CR>", 'n')
endfunction
" Indent input lines
function! edit#indent_lines(dedent, count) range abort
  exe a:firstline . ',' . a:lastline . repeat(a:dedent ? '<' : '>', a:count)
endfunction
" For <expr> map accepting motion
function! edit#indent_lines_expr(...) abort
  return utils#motion_func('edit#indent_lines', a:000)
endfunction

" Insert mode delete and undo
" Note: This restores cursor position after insert-mode undo. First queue translation
" with edit#insert_mode() then run edit#insert_undo() on InsertLeave (e.g. after 'ciw')
" Note: Remove single tab or up to &tabstop spaces to the right of cursor. This
" enforces consistency with 'softtab' backspace-by-tabs behavior.
function! edit#insert_mode(...) abort
  let imode = a:0 ? a:1 : get(b:, 'insert_mode', '')
  let b:insert_mode = imode  " save character
  return imode
endfunction
function! edit#insert_char(key, ...) abort
  let name = get(s:delimit_mate, a:key, a:key)
  let keys = call('delimitMate#' . name, a:000)
  return substitute(keys, "\<Esc>", "\<C-c>", 'g')
endfunction
function! edit#insert_delete(...) abort  " vint: -ProhibitUsingUndeclaredVariable
  let [idx, text] = [col('.') - 1, getline('.')]
  let text = text[idx:idx + &tabstop - 1]
  let regex = '^\(\t\| \{,' . &tabstop . '}\).*$'
  let pad = substitute(text, regex, '\1', '')
  let cnt = empty(pad) ? a:0 && a:1 : len(pad)
  let head = cnt && pumvisible() ? "\<C-e>" : ''
  return repeat("\<Delete>", cnt)
endfunction
function! edit#insert_undo(...) abort
  let imode = a:0 ? a:1 : get(b:, 'insert_mode', '')  " default to queued
  if imode =~# 'o\|O'
    let iundo = imode
  elseif col('.') < col('$') - 1  " standard restore
    let iundo = 'i'
  else  " end-of-line restore
    let iundo = 'a'
  endif
  let b:insert_mode = iundo | return "\<C-g>u"
endfunction

" Switch adjacent characters or lines
" Note: This keeps existing registers and folds. If calling on line with closed fold
" will transfer entire fold contents and define new FastFold-managed manual folds.
function! edit#move_chars(...) abort
  let idx = a:0 && a:1 ? cnum - 1 : cnum
  let [cnum, line] = [col('.'), getline('.')]
  if idx > 0 && idx < len(line)
    let line = line[:idx - 2] . line[idx] . line[idx - 1] . line[idx + 1:]
    call setline('.', line)
  endif
endfunction
function! edit#move_lines(...) abort
  let [line1, delta] = [line('.'), a:0 && a:1 ? -1 : 1]
  if line1 + delta < 1 || line1 + delta > line('$') | return | endif
  let [line11, line12] = [foldclosed(line1), foldclosedend(line1)]
  let [line11, line12] = line11 > 0 ? [line11, line12] : [line1, line1]
  let line2 = delta > 0 ? line12 + delta : line11 + delta
  let [fold1, fold2] = [foldlevel(line1) > 0, foldlevel(line2) > 0]
  let [close1, close2] = [foldclosed(line1) > 0, foldclosed(line2) > 0]
  let [line21, line22] = [foldclosed(line2), foldclosedend(line2)]
  let [line21, line22] = line21 > 0 ? [line21, line22] : [line2, line2]
  let [line1, line2] = delta > 0 ? [line11, line22] : [line21, line12]
  let [text1, text2] = [getline(line11, line12), getline(line21, line22)]
  call deletebufline(bufnr(), line1, line2)  " delete without register
  call append(line1 - 1, delta > 0 ? text2 + text1 : text1 + text2)
  let range1 = (line11 + delta * len(text2)) . ',' . (line12 + delta * len(text2))
  let range2 = (line21 - delta * len(text1)) . ',' . (line22 - delta * len(text1))
  let manual = &l:foldmethod ==# 'manual'  " e.g. fast fold enabled
  if manual && fold1 | exe range1 . 'fold' | exe range1 . (close1 ? 'foldclose' : 'foldopen') | endif
  if manual && fold2 | exe range2 . 'fold' | exe range2 . (close2 ? 'foldclose' : 'foldopen') | endif
  exe line21 | exe close1 ? '' : 'normal! zv'
endfunction

" Search sort or reverse the input lines
" Note: Adaptation of hard-to-remember :g command shortcut. Adapted
" from super old post: https://vim.fandom.com/wiki/Reverse_order_of_lines
function! edit#sel_lines(...) range abort
  let range = printf('\%%>%dl\%%<%dl', a:firstline - 1, a:lastline + 1)
  call feedkeys((a:0 && a:1 ? '?' : '/') . range, 'n')
  call edit#echo_range('Searching', a:lastline - a:firstline - 1)
endfunction
function! edit#sort_lines() range abort  " vint: -ProhibitUnnecessaryDoubleQuote
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  exe 'silent ' . range . 'sort'
  call edit#echo_range('Sorted', a:lastline - a:firstline + 1)
endfunction
function! edit#reverse_lines() range abort  " vint: -ProhibitUnnecessaryDoubleQuote
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  exe 'silent ' . range . 'g/^/m' . (empty(range) ? 0 : a:firstline - 1)
  call edit#echo_range('Reversed', a:lastline - a:firstline + 1)
endfunction
" For <expr> map accepting motion
function! edit#sel_lines_expr(...) abort
  return utils#motion_func('edit#sel_lines', a:000)
endfunction
function! edit#sort_lines_expr() range abort
  return utils#motion_func('edit#sort_lines', a:000)
endfunction
function! edit#reverse_lines_expr() abort
  return utils#motion_func('edit#reverse_lines', a:000)
endfunction

" Spell check under cursor
" Note: This improves '1z=' to return nothing when called on valid words.
" Note: If nothing passed and no manual count then skip otherwise continue.
function! s:spell_check(...) abort
  let word = a:0 ? a:1 : expand('<cword>')
  let [fixed, which] = spellbadword(word)
  return !empty(fixed)
endfunction
function! edit#spell_next(count) abort
  let keys = a:count < 0 ? '[s' : ']s'
  for _ in range(abs(a:count))
    exe s:spell_check() ? '' : 'keepjumps normal! ' . keys
    call edit#spell_check(1)
  endfor
endfunction
function! edit#spell_check(...) abort
  if a:0 || v:count || s:spell_check()
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

" Search replace without history
" Note: Substitute 'n' would give exact count but then have to repeat twice, too slow
" Note: Critical to replace reverse line-by-line in case substitution has newlines
function! edit#search_replace(msg, ...) range abort
  let nlines = 0  " pattern count
  let search = @/  " hlsearch pattern
  let winview = winsaveview()
  let group = a:0 % 2 ? a:1 : ''
  let pairs = copy(a:000[a:0 % 2:])
  for line in range(a:lastline, a:firstline, -1)
    exe line | for idx in range(0, a:0 - 2, 2)
      let jdx = idx + 1  " replacement index
      let regex = type(pairs[idx]) == 2 ? pairs[idx]() : pairs[idx]
      let replace = jdx >= a:0 ? '' : type(pairs[jdx]) == 2 ? pairs[jdx]() : pairs[jdx]
      if !empty(group) && !search(regex, 'cnW', line, 0, '!tags#get_inside("$", group)')
        continue  " e.g. not inside comment
      endif
      let cmd = 's@' . regex . '@' . replace . '@gel'
      let nlines += !empty(execute('keepjumps ' . cmd))  " or exact with 'n'?
      call histdel('/', -1)  " preserve history
    endfor
  endfor
  call edit#echo_range(a:msg, nlines)
  let @/ = search
  call winrestview(winview)
endfunction
" For <expr> map accepting motion
function! edit#search_replace_expr(...) abort
  return utils#motion_func('edit#search_replace', a:000)
endfunction

" Wrap the lines to 'count' columns rather than 'text width'
" Note: Need feedkeys() because normal mode commands fail inside expression maps.
" Note: Need 'exe keepjumps' instead of 'keepjumps exe' or else keepjumps fails (tried)
function! edit#wrap_lines(...) range abort
  let prevwidth = &l:textwidth
  let textwidth = a:0 ? a:1 ? a:1 : prevwidth : prevwidth
  let &l:textwidth = textwidth
  let cmd = a:lastline . 'gggq' . a:firstline . 'gg'
  let cmd .= "\<Cmd>silent setlocal textwidth=" . prevwidth . "\<CR>"
  let cmd .= "\<Cmd>echom 'Wrapped lines to " . textwidth . " characters.'\<CR>"
  call feedkeys(cmd, 'n')
endfunction
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
  exe 'keepjumps ' . a:first . ',' . a:last
    \ . 's@' . pattern_optional
    \ . '@' . match_head . repeat(' ', len(match_item)) . '\3'
    \ . '@ge' | call histdel('/', -1)
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
