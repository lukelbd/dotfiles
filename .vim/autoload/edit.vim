"-----------------------------------------------------------------------------"
" Utilities for formatting text
"-----------------------------------------------------------------------------"
" Auto-format with external plugin
" NOTE: Not all servers support auto formtting. Seems 'pylsp' uses autopep8 consistent
" with flake8 warnings. Use below function to print active servers.
function! s:auto_servers() abort
  let servers = lsp#get_allowed_servers()
  let table = split(lsp#get_server_status(), "\n")
  let lines = map(table, 'split(v:val, '':\s*'')')
  let names = map(filter(table, 'v:val[1] ==# ''running'''), 'v:val[0]')
  return filter(servers, 'index(names, v:val) >= 0')
endfunction
function! edit#auto_format(...) abort
  let formatters = get(g:, 'formatters_' . &l:filetype, [])
  let servers = s:auto_servers()
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

" Change order of adjacent characters
" NOTE: This accounts for multi-byte characters and preserves current column. Common
" touch-typing error is to hit keys in wrong order so this is really helpful.
function! edit#change_chars(...) abort
  let winview = winsaveview()
  let text = getline('.')
  let cnt = a:0 && a:1 ? -1 : 1
  let idx = charidx(text, col('.') - 1)
  let idx = cnt > 0 ? idx + 1 : idx
  if idx > 0 && idx < strchars(text)
    let char1 = strcharpart(text, idx - 1, 1)
    let char2 = strcharpart(text, idx, 1)
    let head = strcharpart(text, 0, idx - 1)
    let tail = strcharpart(text, idx + 1)
    let winview.col = len(head) + len(char2) * (cnt > 0)
    call setline('.', head . char2 . char1 . tail)
  endif
  call winrestview(winview) | redraw
endfunction

" Change order of adjacent lines
" NOTE: This keeps existing registers and folds. If calling on line with closed fold
" will transfer entire fold contents and define new FastFold-managed manual folds.
function! edit#change_lines(...) abort
  let winview = winsaveview()  " save view
  let line1 = winview.lnum
  let cnt = a:0 && a:1 ? -1 : 1
  if line1 + cnt < 1 || line1 + cnt > line('$') | return | endif
  let [level1, close1] = [foldlevel(line1) > 0, foldclosed(line1) > 0]
  let [line11, line12] = close1 ? [foldclosed(line1), foldclosedend(line1)] : [line1, line1]
  let lines1 = getline(line11, line12)  " lines to swap
  let line2 = cnt > 0 ? line12 + cnt : line11 + cnt
  let [level2, close2] = [foldlevel(line2) > 0, foldclosed(line2) > 0]
  let [line21, line22] = close2 ? [foldclosed(line2), foldclosedend(line2)] : [line2, line2]
  let lines2 = getline(line21, line22)  " lines to swap
  call deletebufline(bufnr(), min([line11, line21]), max([line12, line22]))
  call append(min([line11, line21]) - 1, cnt > 0 ? lines2 + lines1 : lines1 + lines2)
  if level1 && &l:foldmethod ==# 'manual'
    let [fold1, fold2] = [line11 + cnt * len(lines2), line12 + cnt * len(lines2)]
    exe fold1 . ',' . fold2 . 'fold'
    exe fold1 . (close1 ? '' : 'foldopen')
  endif
  if level2 && &l:foldmethod ==# 'manual'
    let [fold1, fold2] = [line21 - cnt * len(lines1), line22 - cnt * len(lines1)]
    exe fold1 . ',' . fold2 . 'fold'
    exe fold1 . (close2 ? '' : 'foldopen')
  endif
  let winview.lnum = line21
  call winrestview(winview) | redraw
endfunction

" Format using &formatoptions setting
" NOTE: This implements line wrapping and joining settings, and accounts for comment
" continuation and automatic indentation based on shiftwidth or formatlistpat.
" NOTE: This wraps to optional input count column rather than text width, and
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

" Indent or join lines by count
" NOTE: Native vim indent uses count to move over number of lines, but redundant
" with e.g. 'd2k', so instead use count to denote indentation level.
" NOTE: Native vim join uses count to join n lines including parent line, so e.g.
" 1J and 2J have the same effect. This adds to count to make join more intuitive
function! edit#join_lines(backward, ...) range abort
  let [line1, line2, cnum] = [a:firstline, a:lastline, col('.')]
  if a:backward  " reverse join
    let line1 -= line2 > line1 ? v:count : v:count1
  else  " forward join
    let line2 += line2 > line1 ? v:count : v:count1
  endif
  let regex = '\S\zs\s\(' . comment#get_regex() . '\)'
  let args = [regex, 'cnW', line1, 0, "!tags#get_skip(0, 'Comment')"]
  call cursor(line1, 1) | let [_, col1] = call('searchpos', args)
  let bang = a:0 && a:1 ? '!' : ''
  let cmd = exists(':Join') ? 'Join' : 'join'
  exe line1 . ',' . line2 . cmd . bang
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

" Insert mode delete-by-tabs and delimit-mate keys
" NOTE: Native delimitMate#ExpandReturn() issues <Esc> then fails to split brackets due
" to InsertLeave autocommand that repositions cursor. Use <C-c> to avoid InsertLeave.
let s:insert_delims = {'s': 'ExpandSpace', 'r': 'ExpandReturn', 'b': 'BS'}
function! edit#insert_init(...) abort
  let key = a:0 ? a:1 : get(b:, 'insert_mode', '')
  let b:insert_mode = key  " see above
  return key
endfunction
function! edit#insert_undo(...) abort
  let key = a:0 ? a:1 : get(b:, 'insert_mode', '')  " default to queued
  let b:insert_mode = key ==? 'o' ? key : col('.') < col('$') - 1 ? 'i' : 'a'
  return "\<C-g>u"
endfunction
function! edit#insert_delims(key, ...) abort
  let name = get(s:insert_delims, a:key, a:key)
  let keys = call('delimitMate#' . name, a:000)
  let keys = substitute(keys, "\<Esc>", "\<C-c>", 'g') | return keys
endfunction
function! edit#insert_delete(...) abort  " vint: -ProhibitUsingUndeclaredVariable
  let [idx, text] = [col('.') - 1, getline('.')]
  let text = text[idx:idx + shiftwidth() - 1]  " forward-delete-by-tab
  let regex = '^\(\t\| \{,' . shiftwidth() . '}\).*$'
  let pad = substitute(text, regex, '\1', '')
  let cnt = empty(pad) ? a:0 && a:1 : len(pad)
  let head = cnt && pumvisible() ? "\<C-e>" : ''
  let keys = repeat("\<Delete>", cnt) | return keys
endfunction

" Return error messages and replacement message
" NOTE: This is used to show error messages on closed folds similar
" to method used to show git-gutter hunk summaries on closed folds.
function! s:stat_range(msg, num, ...) range abort
  let head = a:msg =~# '\s' ? ' on ' : ' '
  let tail = join(a:000, '')
  let tail = empty(tail) ? '' : ' (args ' . tail . ')'
  redraw | echom a:msg . head  . a:num . ' line(s)' . tail
endfunction
function! edit#stat_errors(...) range abort
  let [line1, line2] = a:0 ? a:000 : [a:firstline, a:lastline]
  let [info, cnts, flags] = ['', {}, {'E': '!', 'W': '@', 'I': '#'}]
  for item in get(b:, 'ale_highlight_items', {})
    if item.bufnr == bufnr() && item.lnum >= line1 && item.lnum <= line2
      let flag = get(flags, item.type, '?')
      let cnts[flag] = get(cnts, flag, 0) + 1
    endif
  endfor | return join(map(items(cnts), 'v:val[0] . v:val[1]'), '')
endfunction

" Search sort or reverse the input lines
" NOTE: Adaptation of hard-to-remember :g command shortcut. Adapted
" from super old post: https://vim.fandom.com/wiki/Reverse_order_of_lines
function! edit#sel_lines(...) range abort
  let range = printf('\%%>%dl\%%<%dl', a:firstline - 1, a:lastline + 1)
  call feedkeys((a:0 && a:1 ? '?' : '/') . range, 'n')
  call s:stat_range('Searching', a:lastline - a:firstline - 1)
endfunction
function! edit#sort_lines(...) range abort  " vint: -ProhibitUnnecessaryDoubleQuote
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  exe 'silent ' . range . 'sort ' . join(a:000, '')
  call s:stat_range('Sorted', a:lastline - a:firstline + 1)
endfunction
function! edit#reverse_lines() range abort  " vint: -ProhibitUnnecessaryDoubleQuote
  let range = a:firstline == a:lastline ? '' : a:firstline . ',' . a:lastline
  exe 'silent ' . range . 'g/^/m' . (empty(range) ? 0 : a:firstline - 1)
  call s:stat_range('Reversed', a:lastline - a:firstline + 1)
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
" NOTE: This improves '1z=' to return nothing when called on valid words.
" NOTE: If nothing passed and no manual count then skip otherwise continue.
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
" NOTE: Using substitute(..., 'n') alsogives count but have to repeat twice, too slow
" NOTE: Critical to replace reverse line-by-line in case substitution has newlines
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
  call s:stat_range(a:msg, cnt)
endfunction
" For <expr> map accepting motion
function! edit#search_replace_expr(...) abort
  return utils#motion_func('edit#search_replace', a:000)
endfunction
