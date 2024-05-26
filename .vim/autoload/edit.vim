"-----------------------------------------------------------------------------"
" Utilities for formatting text
"-----------------------------------------------------------------------------"
" Helper function
" Note: Native delimitMate#ExpandReturn() issues <Esc> then fails to split brackets due
" to InsertLeave autocommand that repositions cursor. Use <C-c> to avoid InsertLeave.
function! edit#echo_range(msg, num, ...) range abort
  let head = a:msg =~# '\s' ? ' on ' : ' '
  let tail = join(a:000, '')
  let tail = empty(tail) ? '' : ' (args ' . tail . ')'
  redraw | echom a:msg . head  . a:num . ' line(s)' . tail
endfunction

" Auto formatting utilities
" Note: Not all servers support auto formtting. Seems 'pylsp' uses autopep8 consistent
" with flake8 warnings. Use below function to print active servers.
function! edit#get_servers() abort
  let servers = lsp#get_allowed_servers()
  let table = split(lsp#get_server_status(), "\n")
  let lines = map(table, 'split(v:val, '':\s*'')')
  let names = map(filter(table, 'v:val[1] ==# ''running'''), 'v:val[0]')
  return filter(servers, 'index(names, v:val) >= 0')
endfunction
function! edit#auto_format(...) abort
  let formatters = get(g:, 'formatters_' . &l:filetype, [])
  let servers = edit#get_servers()
  if a:0 && a:1 && !empty(servers)  " possibly aborts
    exe 'LspDocumentFormat' | call fold#update_folds(1)
  elseif !empty(formatters)
    exe 'Autoformat' | call fold#update_folds(1)
    redraw | echom 'Autoformatted with ' . string(formatters[0])
  else
    redraw | echohl WarningMsg
    echom 'Error: No formatters available'
    echohl None
  endif
endfunction

" Indent or join lines by count
" Note: Native vim indent uses count to move over number of lines, but redundant
" with e.g. 'd2k', so instead use count to denote indentation level.
" Note: Native vim join uses count to join n lines including parent line, so e.g.
" 1J and 2J have the same effect. This adds to count to make join more intuitive
function! edit#join_lines(key, back) range abort
  let [line1, line2, cnum] = [a:firstline, a:lastline, col('.')]
  let line2 += line2 > line1 ? v:count : v:count1
  let regex = '\S\zs\s\(' . comment#get_regex() . '\)'
  let args = [regex, 'cnW', line1, 0, "!tags#get_skip(0, 'Comment')"]
  call cursor(line1, 1) | let [_, col1] = call('searchpos', args)
  exe line1 . ',' . line2 . (exists(':Join') ? 'Join' : 'join')
  call cursor(line1, 1) | let [_, col2] = call('searchpos', args)
  exe !col1 && col2 ?  line1 . 'substitute/' . regex . '/  \1/e' : ''
  call cursor(line1, cnum)
endfunction
" Indent input lines
function! edit#indent_lines(dedent, count) range abort
  exe a:firstline . ',' . a:lastline . repeat(a:dedent ? '<' : '>', a:count)
endfunction
" For <expr> map accepting motion
function! edit#indent_lines_expr(...) abort
  return utils#motion_func('edit#indent_lines', a:000)
endfunction
" For <expr> map accepting motion
function! edit#join_lines_expr(...) abort
  return utils#motion_func('edit#join_lines', a:000)
endfunction

" Insert mode delete and undo
" Note: This restores cursor position after insert-mode undo. First queue translation
" with edit#insert_mode() then run edit#insert_undo() on InsertLeave (e.g. after 'ciw')
" Note: Remove single tab or up to &tabstop spaces to the right of cursor. This
" enforces consistency with 'softtab' backspace-by-tabs behavior.
let s:insert_keys = {'s': 'ExpandSpace', 'r': 'ExpandReturn', 'b': 'BS'}
function! edit#insert_mode(...) abort
  let imode = a:0 ? a:1 : get(b:, 'insert_mode', '')
  let b:insert_mode = imode  " save character
  return imode
endfunction
function! edit#insert_char(key, ...) abort
  let name = get(s:insert_keys, a:key, a:key)
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
  let [cnum, line] = [col('.'), getline('.')]
  let idx = a:0 && a:1 ? cnum - 1 : cnum
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
function! edit#sort_lines(...) range abort  " vint: -ProhibitUnnecessaryDoubleQuote
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  exe 'silent ' . range . 'sort ' . join(a:000, '')
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
function! edit#sort_lines_expr(...) range abort
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
  let winview = winsaveview()
  let pairs = copy(a:000[a:0 % 2:])
  let skip = a:0 % 2 ? a:1 : ''
  let cnt = 0  " pattern count
  let pattern = @/  " previous pattern
  for line in range(a:lastline, a:firstline, -1)
    exe line | for idx in range(0, a:0 - 2, 2)
      let jdx = idx + 1  " replacement index
      let regex = type(pairs[idx]) == 2 ? pairs[idx]() : pairs[idx]
      let replace = jdx >= a:0 ? '' : type(pairs[jdx]) == 2 ? pairs[jdx]() : pairs[jdx]
      if !empty(skip) && !search(regex, 'cnW', line, 0, "tags#get_skip('$', skip)")
        continue  " e.g. not inside comment
      endif
      let cmd = 's@' . regex . '@' . replace . '@gel'
      let cnt += !empty(execute('keepjumps ' . cmd))  " or exact with 'n'?
      call histdel('/', -1)  " preserve history
    endfor
  endfor
  let @/ = pattern
  call winrestview(winview)
  call edit#echo_range(a:msg, cnt)
endfunction
" For <expr> map accepting motion
function! edit#search_replace_expr(...) abort
  return utils#motion_func('edit#search_replace', a:000)
endfunction

" Format using &formatoptions,
" Note: This implements line wrapping and joining settings, and accounts for comment
" continuation and automatic indentation based on shiftwidth or formatlistpat.
" Note: This wraps to optional input count column rather than text width, and
" disables vim-markdown hack that enforces bullet continuations via &comments entries
" See: https://vi.stackexchange.com/a/7712/8084 and :help g@
function! edit#format_lines(...) range abort
  let regex = substitute(&l:formatlistpat, '^\^', '', '')  " include comments
  let regex = '^\(' . comment#get_regex(0) . '\)\?' . regex
  let width1 = &l:textwidth  " previous text wdith
  let width2 = a:0 && a:1 ? a:1 : width1
  let comments1 = split(&l:comments, '\\\@<!,')
  let comments2 = filter(copy(comments1), {_, val -> val !~# ':[*>+-]$'})
  exe a:firstline | let lnums = [a:firstline]
  while v:true
    let lnum = search(regex, 'W', a:lastline)
    if lnum <= 0 | break | endif
    if lnum == a:firstline | continue | endif
    call add(lnums, lnum)
  endwhile
  for idx in reverse(range(len(lnums)))
    let line1 = lnums[idx]
    let line2 = get(lnums, idx + 1, a:lastline + 1) - 1
    let cnt = line2 - line1 + 1
    try
      let &l:textwidth = width2
      let &l:comments = join(comments2, ',')
      exe line1 | exe 'normal! ' . cnt . 'gqq'
    finally
      let &l:textwidth = width1
      let &l:comments = join(comments1, ',')
    endtry
  endfor
  let cnt = a:lastline - a:firstline + 1
  let range = cnt > 1 ? cnt . ' lines' : cnt . ' line'
  redraw | echom 'Wrapped ' . range . ' to ' . width2 . ' characters'
endfunction
" For <expr> map accepting motion
function! edit#format_lines_expr(...) abort
  return utils#motion_func('edit#format_lines', a:000)
endfunction
