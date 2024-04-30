"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Return ignored auto-opened folds matching given regex
" Note: This provides 'pseudo-levels' that auto-open when level is at or above
" the first regex and when that regex is not preceded by the second regex. Useful
" e.g. for python classes or tex environments occupying entire document and to
" enforce universal standard default of foldlevel=0 without hiding everything.
" Return fold under cursor above a given level
scriptencoding utf-8
let s:folds_ignore = [
  \ ['python', '^class\>', '', 1],
  \ ['fortran', '^\s*\(module\|program\)\>', '', 1],
  \ ['javascript', '^\s*\(export\s\+\|default\s\+\)*class\>', '', 1],
  \ ['typescript', '^\s*\(export\s\+\|default\s\+\)*class\>', '', 1],
  \ ['tex', '^\s*\\begin{document}', '', 1],
  \ ['tex', '^\s*\\begin{frame}', '^\s*\\begin{block}', 2],
  \ ['tex', '^\s*\\\(sub\)*section\>', '^\s*\\begin{frame}', 2],
\ ]
function! fold#get_ignores(...) abort range
  let [line1, line2] = a:0 > 1 ? a:000 : a:0 ? [a:1, a:1] : [1, line('$')]
  let ignores = []
  for [ftype, regex1, regex2, level] in s:folds_ignore
    if ftype !=# &l:filetype
      continue  " ignore non-matching filetypes
    endif
    if &l:diff || &l:foldmethod !~# '\<\(manual\|syntax\|expr\)\>'
      continue  " ignore irrelevant documents
    endif
    if !empty(regex2) && !search(regex2, 'nwc')
      continue  " ignore first regex when second missing from document
    endif
    let winview = winsaveview()
    exe line1 | let skip = 'foldlevel(".") != level'
    while search(regex1, 'cW', line2, 0, skip)
      let lnum = line('.') | call add(ignores, lnum)
      exe lnum + 1 | if lnum + 1 >= line('$') | break | endif
    endwhile
    call winrestview(winview)
  endfor
  return ignores
endfunction

" Return bounds and level for any closed fold or open fold of requested level
" Note: No native way to get bounds if fold is open so use normal-mode algorithm.
" Also [z never raises error, but does update jumplist even though not documented
" in :help jump-motions. See: https://stackoverflow.com/a/4776436/4970632 
" Note: This file supports following toggles: non-recursive (highest level in range),
" inner inner (folds within highest-level fold under cursor that hs children), outer
" inner (folds within current 'main' parent fold), outer recursirve (parent fold and
" all its children), and outer force (as with outer but ignoring regexes).
function! fold#get_parent(...) abort
  let toplevel = a:0 ? a:1 : &l:foldlevelstart
  let toplevel = max([toplevel, 0])
  let [lnum, level] = [line('.'), toplevel + 1]
  let result = fold#get_fold(level)
  if empty(result) || foldclosed(result[0]) > 0
    return result
  elseif empty(fold#get_ignores(result[0]))  " does not match regex
    return result
  endif
  let other = fold#get_fold(level + 1)
  return empty(other) ? result : other
endfunction
function! fold#get_fold(...) abort
  if foldlevel('.') <= 0 | return [] | endif
  let winview = winsaveview()
  let level = a:0 ? a:1 : foldlevel('.')
  let level = max([level, 0])
  let [inum, fnum] = [0, foldclosed('.')]
  let fnum = fnum > 0 ? fnum : line('.')  " ignore inaccessible closed folds
  while fnum != inum && foldlevel(fnum) > level
    let inum = line('.')
    exe 'keepjumps normal! [z'
    let fnum = line('.')
  endwhile
  if foldclosed(fnum) > 0  " use even if below requested level
    let level = foldlevel(fnum)
    let line1 = foldclosed(fnum)
    let line2 = foldclosedend(fnum)
    let result = [line1, line2, level]
  else  " return bounds without closing
    let lnum = inum > 0 ? fnum + 1 : fnum
    exe lnum | exe 'keepjumps normal! [z'
    let line1 = line('.')
    let level1 = foldlevel('.')  " head of fold never returns level of child
    let close1 = foldclosed('.')  " possibly closed preceding child fold
    exe 'keepjumps normal! ]z'
    let line2 = line('.')
    if close1 > 0 || line2 < lnum || level1 < level  " jumped to preceding
      let lnum = lnum + 1 | exe lnum
      exe 'keepjumps normal! [z'
      let line1 = line('.')  " corrected fold start
      let level1 = foldlevel('.')
      exe 'keepjumps normal! ]z'
      let line2 = line('.')
    endif
    let valid = line2 >= lnum && level1 == level
    let result = valid ? [line1, line2, level] : []
  endif
  call winrestview(winview) | return result
endfunction

" Return folds and properties across line range
" Note: This ignores folds defined in s:folds_ignore, e.g. python classes and
" tex documents. Used to close-open smaller fold blocks ignoring huge blocks.
function! s:get_folds(func, ...) abort
  let [lmin, lmax] = a:0 ? a:000[:1] : [1, line('$')]
  let winview = winsaveview()
  let nmax = a:0 > 3 ? a:4 : 0
  let lmin = min([max([lmin, 1]), line('$')])
  let lmax = min([max([lmax, 1]), line('$')])
  let lnum = lmin
  let results = []
  while lmax < lmin ? lnum >= lmax : lnum <= lmax
    exe lnum | let result = call(a:func, a:000[2:2])
    if !empty(result)
      call add(results, result)
    endif
    if nmax > 0 && len(results) >= nmax
      break
    elseif lmax < lmin  " search backward
      let lnum = get(result, 0, lnum) - 1
    else  " search forward
      let lnum = get(result, 1, lnum) + 1
    endif
  endwhile
  call winrestview(winview) | return results
endfunction
function! fold#get_folds(...) abort
  return call('s:get_folds', ['fold#get_fold'] + a:000)
endfunction
function! fold#get_parents(...) abort
  return call('s:get_folds', ['fold#get_parent'] + a:000)
endfunction

" Return default fold label
" Note: This filters trailing comments, removes git-diff chunk text following stats,
" and adds following line if the fold line is a single open delimiter (e.g. json).
function! s:fix_delims(line) abort
  let label1 = fold#get_label(a:line, 1)
  let [delim1, outer] = s:get_delims(label1)
  if label1 !=# delim1 | return '' | endif
  let label2 = fold#get_label(a:line + 1, 1)  " after naked delimiter
  let [delim2, _] = s:get_delims(label2)
  if label2 ==# delim2 | return '' | endif  " only open and close
  let inner = substitute(label2, '\s*\([[({<]*\)\s*$', '', 'g')
  return ' ' . inner . ' ··· ' . outer  " e.g. json folds
endfunction
function! s:get_delims(label, ...) abort
  let delims = {'[': ']', '(': ')', '{': '}', '<': '>'}  " delimiter mapping
  let regex = '\([[({<]*\)\s*$'  " opening delimiter regex
  let items = call('matchlist', [a:label, regex] + a:000)
  let delim1 = split(get(items, 1, ''), '\zs', 1)
  let delim2 = map(copy(delim1), {idx, val -> get(delims, val, '')})
  if &l:filetype ==# 'python' && get(delim1, -1, '') ==# ')'
    call add(delim2, a:label =~# '^\s*\(def\|class\)\>' ? ':' : '')
  endif | return [join(delim1, ''), join(delim2, '')]
endfunction
function! fold#get_label(line, ...) abort
  let recursed = a:0 && a:1  " whether already recursed
  let regex = comment#get_regex()
  let char = comment#get_char()
  let head = '^\s*' . regex . '\s*[-=]\{3,}' . regex . '\?\(\s\|$\)'
  let text = getline(a:line)
  if &l:foldmethod ==# 'marker' && text =~# head
    let text = getline(a:line + 1)  " ignore header
  endif
  if &l:foldmethod ==# 'marker'
    let text = substitute(text, split(&l:foldmarker, ',')[0] . '\d*\s*$', '', '')
  endif
  let trim = a:0 && a:1 ? '\(^\s*\|' : '\('  " strip leading space
  let trim .= '\S\@<=\s*' . regex
  let trim .= strwidth(char) == 1 ? '[^' . char . ']*$' : '.*$'
  let trim .= '\|\s*$\)'  " delimiter trim
  let label = substitute(text, trim, '', 'g')
  if !empty(get(b:, 'fugitive_type', '')) || &l:filetype =~# '^git$\|^fugitive$'
    let label = substitute(label, '^\(@@.\{-}@@\).*$', '\1', '')
  endif
  if !recursed && &l:foldmethod !=# 'marker'
    let label .= s:fix_delims(a:line)
  endif
  return label
endfunction

" Generate truncated fold text. In future should include error cound information.
" Note: Since gitgutter signs are not shown over closed folds include summary of
" changes in fold text. See https://github.com/airblade/vim-gitgutter/issues/655
function! fold#fold_text(...) abort
  let winview = winsaveview()  " translate byte column index to character index
  if a:0  " debugging mode
    exe winview.lnum | let [line1, line2, level] = fold#get_fold()
    call winrestview(winview)
  else  " internal mode
    let [line1, line2] = [v:foldstart, v:foldend]
    let level = len(v:folddashes)
  endif
  let level = repeat(':', level)  " fold level
  let lines = string(line2 - line1 + 1)  " number of lines
  let leftidx = charidx(getline(winview.lnum), winview.leftcol)
  let maxlen = get(g:, 'linelength', 88) - 1  " default maximum
  let hunk = git#stat_hunks(line1, line2, 0, 1)  " abbreviate with '1'
  let dots = repeat('·', len(string(line('$'))) - len(lines))
  let stats = level . dots . lines  " default statistics
  if &l:diff  " fill with maximum width
    let [label, stats] = [level . dots . lines, repeat('~', maxlen - strwidth(stats) - 2)]
  elseif exists('*' . &l:filetype . '#fold_text')
    let label = {&l:filetype}#fold_text(line1, line2)
  else  " global default label
    let label = fold#get_label(line1)
  endif
  let [delim1, delim2] = s:get_delims(label)
  let width = maxlen - strwidth(stats) - 1
  let label = empty(delim2) ? label : label . '···' . delim2
  let label = empty(hunk) ? label : hunk . '·' . strpart(label, len(hunk) + 1)
  if strwidth(label) >= width  " truncate fold text
    let dcheck = strpart(label, width - 4 - strwidth(delim2), 1)
    let delim2 = dcheck ==# delim1 ? '' : delim2
    let dcheck = strpart(label, width - 4 - strwidth(delim2))
    let label = strpart(label, 0, width - 5 - strwidth(delim2))
    let label = label . '···' . delim2 . '  '
  endif
  let space = repeat(' ', width - strwidth(label))
  return strcharpart(label . space . stats, leftidx)
endfunction

" Update the fold bounds, level, and open-close status
" Note: Could use e.g. &foldlevel = v:vount but want to keep foldlevel truncated
" to maximum number found in file as native 'zr' does. So use the below instead
" Note: Sometimes run into issue where opening new files or reading updates
" permanently disables 'expr' folds. Account for this by re-applying fold method.
" Warning: Regenerating b:SimPylFold_cache with manual SimpylFold#FoldExpr() call
" can produce strange internal bug. Instead rely on FastFoldUpdate to fill the cache.
function! fold#update_level(...) abort
  let level = &l:foldlevel
  if a:0  " input direction
    let cmd = v:count1 . 'z' . a:1
  elseif !v:count || v:count == level  " preserve level
    let cmd = ''
  else  " apply level
    let cmd = abs(v:count - level) . (v:count > level ? 'zr' : 'zm')
  endif
  if !empty(cmd)
    silent! exe 'normal! ' . cmd
  endif
  echom 'Fold level: ' . &l:foldlevel
endfunction
function! fold#update_folds(force, ...) abort
  let queued = get(b:, 'fastfold_queued', 1)  " changed on TextChanged,TextChangedI
  let cached = get(w:, 'lastfdm', 'manual')  " managed by FastFoldUpdate
  let method = &l:foldmethod
  let winview = winsaveview()
  if queued || a:force
    if &l:diff  " difference mode enabled
      diffupdate | setlocal foldmethod=diff
    elseif &l:filetype ==# 'python'
      setlocal foldmethod=expr  " e.g. in case stuck
      setlocal foldexpr=python#fold_expr(v:lnum)
    elseif &l:filetype ==# 'markdown'
      setlocal foldmethod=expr  " e.g. in case stuck
      setlocal foldexpr=Foldexpr_markdown(v:lnum)
    elseif &l:filetype ==# 'rst'
      setlocal foldmethod=expr  " e.g. in case stuck
      setlocal foldexpr=RstFold#GetRstFold()
    elseif method ==# 'manual' && cached ==# 'manual'
      setlocal foldmethod=syntax
    endif
    call SimpylFold#Recache()
    silent! FastFoldUpdate
    let b:fastfold_queued = 0
  endif
  if a:0  " initialize
    if a:1 > 0  " apply defaults
      let &l:foldlevel = !empty(get(b:, 'fugitive_type', ''))
    endif
    for lnum in fold#get_ignores()
      exe lnum . 'foldopen'
    endfor
    if a:1 <= 1  " open under cursor
      exe 'normal! zv'
    endif
  endif
  setlocal foldtext=fold#fold_text()
  call winrestview(winview)
endfunction

" Toggle inner folds within requested range
" Note: Necessary to temporarily open outer folds before toggling inner folds. No way
" to target them with :fold commands or distinguish adjacent children with same level
function! s:toggle_state(line1, line2, ...) abort range
  let level = a:0 ? a:1 : 0
  for lnum in range(a:line1, a:line2)
    let inum = foldclosed(lnum)
    if inum > 0 && (!level || level == foldlevel(inum))
      return 1
    endif
  endfor
  return 0
endfunction
function! s:toggle_inner(line1, line2, level, ...) abort
  let [outer, inner] = [[], []]
  let [fold1, fold2] = [foldclosed(a:line1), foldclosedend(a:line2)]
  let [line1, line2] = [fold1 > 0 ? fold1 : a:line1, fold2 > 0 ? fold2 : a:line2]
  for lnum in range(line1, line2)
    let ilevel = foldlevel(lnum)
    if !ilevel | continue | endif
    let iline = foldclosed(lnum)
    if ilevel > a:level
      call add(inner, [ilevel, lnum])
    elseif iline > 0 && index(outer, [ilevel, iline]) == -1
      call add(outer, [ilevel, iline])
    endif
  endfor
  for [_, lnum] in sort(outer) | exe lnum . 'foldopen' | endfor
  let level = a:level + 1  " minimum folding level
  let toggle = a:0 ? a:1 : 1 - s:toggle_state(a:line1, a:line2, level)
  let recurse = a:0 > 0 ? a:2 : 0
  let toggled = []
  for [_, lnum] in toggle ? reverse(sort(inner)) : sort(inner)
    let inum = foldclosed(lnum)
    let ilevel = foldlevel(inum > 0 ? inum : lnum)
    if ilevel == level || recurse && ilevel > level
      if toggle && inum <= 0
        exe lnum . 'foldclose'
        call add(toggled, [foldclosed(lnum), foldclosedend(lnum), ilevel])
      elseif !toggle && inum > 0
        call add(toggled, [inum, foldclosedend(lnum), ilevel])
        exe lnum . 'foldopen'
      endif
    endif
  endfor
  for [_, lnum] in reverse(sort(outer)) | exe lnum . 'foldclose' | endfor
  return [toggle, toggled]
endfunction

" Open or close parent fold under cursor and its children
" Note: If called on already-toggled 'current' folds the explicit 'foldclose/foldopen'
" toggles the parent. So e.g. 'zCzC' first closes python methods then the class.
function! s:show_toggle(toggle, count) abort
  let head = a:toggle > 1 ? 'Toggled' : a:toggle ? 'Closed' : 'Opened'
  if a:count > 0  " show fold count
    redraw | echom head . ' ' . a:count . ' fold' . (a:count > 1 ? 's' : '') . '.'
  else  " consistent with native commands
    call feedkeys("\<Cmd>echoerr 'E490: No folds found'\<CR>", 'n')
  endif
endfunction
function! fold#toggle_parents(...) abort range
  let [lmin, lmax] = sort([a:firstline, a:lastline], 'n')
  call fold#update_folds(0)
  let counts = [0, 0]
  for [line1, line2, level] in fold#get_parents(lmin, lmax)
    if line2 <= line1 | continue | endif
    let toggle = a:0 ? a:1 : 1 - s:toggle_state(line1, line1)
    let [_, folds] = s:toggle_inner(line1, line2, level, toggle, 1)
    exe line1 . (toggle ? 'foldclose' : 'foldopen')
    let counts[toggle] += 1 + len(folds)
  endfor
  let toggle = counts[0] && counts[1] ? 2 : counts[1] ? 1 : 0
  call s:show_toggle(toggle, counts[0] + counts[1]) | return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_parents_expr(...) abort
  return utils#motion_func('fold#toggle_parents', a:000, 1)
endfunction

" Open or close current children under cursor
" Note: This is required because recursive :foldclose! also closes parent
" and :[range]foldclose does not close children. Have to go one-by-one.
function! fold#toggle_children(top, ...) abort range
  let [lmin, lmax] = sort([a:firstline, a:lastline], 'n')
  call fold#update_folds(0)
  let counts = [0, 0]
  if a:top  " outer-most inner folds
    let folds = fold#get_parents(lmin, lmax)
  else  " inner-most inner folds
    let level = foldlevel('.')
    let folds = fold#get_folds(lmin, lmax, level)
    let fmin = min(map(copy(folds), 'v:val[0]'))
    let fmax = max(map(copy(folds), 'v:val[1]'))
    let [fmin, fmax] = fmin && fmax ? [fmin, fmax] : [lmin, lmax]
    let levels = map(range(fmin, fmax), 'foldlevel(v:val)')
    let folds = min(levels) == max(levels) ? fold#get_folds(lmin, lmax, level - 1) : folds
  endif
  for [line1, line2, level] in folds
    if line2 <= line1 | continue | endif
    let args = [line1, line2, level] + copy(a:000)
    let [toggle, folds] = call('s:toggle_inner', args)
    let counts[toggle] += len(folds)  " if zero then continue
  endfor
  let toggle = counts[0] && counts[1] ? 2 : counts[1] ? 1 : 0
  call s:show_toggle(toggle, counts[0] + counts[1]) | return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_children_expr(...) abort
  return utils#motion_func('fold#toggle_children', a:000, 1)
endfunction

" Open or close inner folds within range (i.e. maximum fold level)
" Note: Here 'toggle' closes folds when 1 and opens when 0 (follows convention)
" Note: This permits using e.g. 'zck' and 'zok' even when outside fold and without
" fear of accideif ntally closing huge block e.g. class or document under cursor.
function! fold#toggle_folds(...) range abort
  let [lmin, lmax] = sort([a:firstline, a:lastline], 'n')
  let winview = a:0 > 1 && !empty(a:2) ? a:2 : winsaveview()
  call fold#update_folds(0)
  let levels = map(range(lmin, lmax), 'foldlevel(v:val)')
  let folds = fold#get_folds(lmin, lmax, max(levels))
  let state = s:toggle_state(lmin, lmax)
  if lmin == lmax || mode() !=# 'n'
    let motion = 0  " input cursor motion
  else
    let motion = lmin == line('.') ? 1 : lmax == line('.') ? -1 : 0
  endif
  if motion && state == 0 && max(levels) == min(levels)  " search for inner folds
    let fmin = min(map(copy(folds), 'v:val[0]'))
    let fmax = max(map(copy(folds), 'v:val[1]'))
    if motion < 0
      let [imin, imax] = [lmin, fmin ? fmin : winview.topline]
    else
      let [imin, imax] = [lmax, fmax ? fmax : winview.topline + &l:lines]
    endif
    let others = fold#get_folds(imin, imax, max(levels) + 1, 1)  " search for children
    if !empty(others)
      let [folds, ifold] = [others, others[0]]
      if motion < 0  " toggle from the end of line
        let [lmin, lmax] = [ifold[1], ifold[1]]
      else  " toggle from the start of line
        let [lmin, lmax] = [ifold[0], ifold[0]]
      endif
    endif
  endif
  let toggle = a:0 && a:1 >= 0 ? a:1 : 1 - state
  for [line1, line2; rest] in folds
    let line1 = max([line1, lmin])  " possibly select
    let line2 = min([line2, lmax])
    exe line1 . ',' . line2 . (toggle ? 'foldclose' : 'foldopen')
  endfor
  call s:show_toggle(toggle, len(folds)) | return ''
  if empty(folds)
    call feedkeys("\<Cmd>echoerr 'E490: No folds found'\<CR>", 'n')
  endif | return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_folds_expr(...) abort
  return utils#motion_func('fold#toggle_folds', a:000, 1)
endfunction
