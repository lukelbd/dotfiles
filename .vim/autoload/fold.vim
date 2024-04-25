"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Initialize fold close-open status
" Note: This provides 'pseudo-levels' that auto-open when level is at or above
" the first regex and when that regex is not preceded by the second regex. Useful
" e.g. for python classes or tex environments occupying entire document and to
" enforce universal standard default of foldlevel=0 without hiding everything.
scriptencoding utf-8
let s:init_regex = [
  \ ['python', '^class\>', '', 1],
  \ ['fortran', '^\s*\(module\|program\)\>', '', 1],
  \ ['javascript', '^\s*\(export\s\+\|default\s\+\)*class\>', '', 1],
  \ ['typescript', '^\s*\(export\s\+\|default\s\+\)*class\>', '', 1],
  \ ['tex', '^\s*\\begin{document}', '', 1],
  \ ['tex', '^\s*\\begin{frame}', '^\s*\\begin{block}', 2],
  \ ['tex', '^\s*\\\(sub\)*section\>', '^\s*\\begin{frame}', 2],
\ ]
function! s:init_folds(...) abort range
  for [ftype, regex1, regex2, level] in s:init_regex
    if &l:diff || ftype !=# &l:filetype | continue | endif
    if !empty(regex2) && !search(regex2, 'nwc') | continue | endif
    for lnum in range(1, line('$'))  " open default folds
      if foldlevel(lnum) == level && getline(lnum) =~# regex1
        exe foldclosed(lnum) >= 0 ? lnum . 'foldopen' : ''
      endif
    endfor
  endfor
endfunction

" Return parent fold under cursor (i.e. lowest-level fold above &foldlevel)
" Note: Use fold#get_fold(0) to include filetype exceptions (e.g. if &foldlevel
" is 0 but we are on python method, return the method bounds). Use 1 to ignore them.
" Note: No native vimscript way to do this if fold is open so we use simple algorithm
" improved from https://stackoverflow.com/a/4776436/4970632 (note [z never raises error)
" Warning: Critical to record foldlevel('.') after pressing [z instead of ]z since
" calling foldlevel('.') on the end of a fold could return the level of its child.
" Warning: The zk/zj/[z/]z motions update jumplist, found out via trial and error
" even though not documented in :help jump-motions
function! fold#get_fold(...) abort
  let ignore = a:0 > 0 ? a:1 : 0
  let minfold = a:0 > 1 ? a:2 : &l:foldlevel
  let minfold = max([minfold, 0])
  let winview = winsaveview()  " save view
  let prev = 'keepjumps normal! [z'
  let next = 'keepjumps normal! ]z'
  let lnum = -1
  while line('.') != lnum && foldlevel('.') > minfold + 1
    let lnum = line('.') | exe prev
    exe lnum == line('.') ? 'normal! j' : ''
  endwhile
  let [lnum, llev] = [line('.'), foldlevel('.')]
  let line1 = foldclosed('.')
  let line2 = foldclosedend('.')
  if line1 <= 0  " infer start and end from cursor motions (see above)
    exe prev | let ilev = foldlevel('.') | exe next
    let head = line('.') < lnum || ilev != llev
    exe lnum | exe head ? '' : prev | let line1 = line('.')
    exe next | let line2 = line('.')
  endif
  let recurse = 0  " detect recursive call
  for [ftype, regex1, regex2, level] in ignore ? [] : s:init_regex
    if ftype !=# &l:filetype || level - 1 != minfold | continue | endif
    if !empty(regex2) && !search(regex2, 'nwc') | continue | endif
    if getline(line1) =~# regex1 | let recurse = 1 | break | endif
  endfor
  let level = foldlevel(line1)
  call winrestview(winview)
  if recurse
    return fold#get_fold(ignore, minfold + 1)
  elseif level > minfold
    return [line1, line2, foldlevel(line1)]
  else  " current fold not found
    return [line('.'), line('.'), 0]
  endif
endfunction

" Return parent folds across range (i.e. lowest-level fold above &foldlevel)
" Note: This ignores folds defined in s:init_regex, e.g. python classes and
" tex documents. Used to close-open smaller fold blocks ignoring huge blocks.
function! fold#get_folds(...) abort
  let [imin, imax] = a:0 > 1 ? [a:1, a:2] : [line('.'), line('.')]
  let [imin, imax] = map([imin, imax], 'min([max([v:val, 1]), line("$")])')
  let winview = winsaveview()
  let ignore = a:0 > 2 ? a:3 : 0
  let minfold = a:0 > 3 ? a:4 : &l:foldlevel
  let maxfolds = a:0 > 4 ? a:5 : 0
  let [lnum, folds] = [imin, []]
  while imax < imin ? lnum >= imax : lnum <= imax
    exe lnum
    for ignore in ignore ? [0, 1] : [0]
      let [line1, line2, level] = fold#get_fold(ignore, minfold)
      if line2 > line1 | break | endif  " prefer 'current' fold
    endfor
    if line2 > line1
      call add(folds, [line1, line2, level])
    endif
    if maxfolds > 0 && len(folds) >= maxfolds
      break
    endif
    if imax < imin  " search backward
      let lnum = min([lnum, line1]) - 1
    else  " search forward
      let lnum = max([lnum, line2]) + 1
    endif
  endwhile
  call winrestview(winview) | return folds
endfunction

" Return default fold label
" Note: This filters trailing comments, removes git-diff chunk text following stats,
" and adds following line if the fold line is a single open delimiter (e.g. json).
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
  let char = comment#get_char()
  let ftype = get(b:, 'fugitive_type', '')
  let regex = a:0 && a:1 ? '\(^\s*\|' : '\('  " strip leading space
  let regex .= '\S\@<=\s*' . comment#get_regex()
  let regex .= strwidth(char) == 1 ? '[^' . char . ']*$' : '.*$'
  let regex .= '\|\s*$\)'  " delimiter trim
  let label = substitute(getline(a:line), regex, '', 'g')
  if &l:filetype =~# '^git$\|^fugitive$'  " show only statistics
    let label = substitute(label, '^\(@@.\{-}@@\).*$', '\1', '')
  endif
  if !a:0  " avoid recursion
    let label1 = fold#get_label(a:line, 1)
    let [delim1, outer] = s:get_delims(label1)
    if label1 ==# delim1  " naked delimiter
      let label2 = fold#get_label(a:line + 1, 1)
      let [delim2, _] = s:get_delims(label2)
      if label2 !=# delim2  " append closing
        let inner = substitute(label2, '\s*\([[({<]*\)\s*$', '', 'g')
        let label = label . ' ' . inner . ' ··· ' . outer  " e.g. json folds
      endif
    endif
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
  let hunk = git#hunk_stats(line1, line2, 1, 1)  " abbreviate with '1'
  let dots = repeat('·', len(string(line('$'))) - len(lines))
  let stats = hunk . level . dots . lines  " default statistics
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
" Warning: Sometimes run into issue where opening new files or reading updates
" permanently disables 'expr' folds. Account for this by re-applying fold method.
" Warning: Regenerating b:SimPylFold_cache with manual SimpylFold#FoldExpr() call
" can produce strange internal bug. Instead rely on FastFoldUpdate to fill the cache.
" Note: Python block overrides b:SimPylFold_cache while markdown block overwrites
" foldtext from $RUNTIME/syntax/[markdown|javascript] and re-applies vim-markdown.
" Note: Could use e.g. &foldlevel = v:vount but want to keep foldlevel truncated
" to maximum number found in file as native 'zr' does. So use the below instead
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
  if a:0
    if a:1 > 0  " apply defaults
      let &l:foldlevel = !empty(get(b:, 'fugitive_type', ''))
    endif
    call s:init_folds()
    if a:1 <= 1  " open under cursor
      exe 'normal! zv'
    endif
  endif
  setlocal foldtext=fold#fold_text()
  call winrestview(winview)
endfunction

" Helper functions to toggle folds under cursor
" Note: This is required because recursive :foldclose! also closes parent
" and :[range]foldclose does not close children. Have to go one-by-one.
function! s:toggle_state(line1, line2, ...) abort range
  for lnum in range(a:line1, a:line2)
    if foldclosed(lnum) > get(a:000, 0, 0) | return 1 | endif
  endfor | return 0
endfunction
function! s:toggle_children(line1, line2, level, ...) abort
  let parents = []  " closed parent folds
  let nested = []  " fold levels and lines
  for lnum in range(a:line1, a:line2)
    let [level, ifold] = [foldlevel(lnum), foldclosed(lnum)]
    if level > a:level
      let item = [level, lnum]  " toggle in reverse level order
      call add(nested, item)
    elseif ifold > 0
      let item = [level, ifold]  " open before below algorithm
      if index(parents, item) == -1 | call add(parents, item) | endif
    endif
  endfor
  for [_, lnum] in sort(parents) | exe lnum . 'foldopen' | endfor  " temporarily open
  if a:0 && a:1 >= 0 ? a:1 : !s:toggle_state(a:line1, a:line2, a:line1)
    for [_, lnum] in reverse(sort(nested))  " effective recursion
      exe foldclosed(lnum) <= 0 && foldlevel(lnum) > a:level ? lnum . 'foldclose' : ''
    endfor
  else  " open by increasing level
    for [_, lnum] in sort(nested)  " effective recursion
      exe foldclosed(lnum) && foldlevel(foldclosed(lnum)) > a:level ? lnum . 'foldopen' : ''
    endfor
  endif
  for [_, lnum] in reverse(sort(parents)) | exe lnum . 'foldclose' | endfor  " restore
  return nested
endfunction

" Open or close current parent fold or its children
" Note: If called on already-toggled 'current' folds the explicit 'foldclose/foldopen'
" toggles the parent. So e.g. 'zCzC' first closes python methods then the class.
function! fold#toggle_children(...) abort range
  call fold#update_folds(0)
  for ignore in [0, 1]  " whether to ignore filetype exceptions
    for [line1, line2, level] in fold#get_folds(ignore)
      if line2 <= line1 | continue | endif
      let args = [line1, line2, level] + copy(a:000)
      let folds = call('s:toggle_children', args)
      if len(folds) > 0 | return '' | endif
    endfor
  endfor
  call feedkeys("\<Cmd>echoerr 'E490: No folds found'\<CR>", 'n') | return ''
endfunction
function! fold#toggle_parent(...) abort range
  call fold#update_folds(0)
  for ignore in [0, 1]
    for [line1, line2, level] in fold#get_folds(ignore)
      if line2 <= line1 | continue | endif
      let toggle = a:0 && a:1 >= 0 ? a:1 : 1 - s:toggle_state(line1, line1)
      call call('s:toggle_children', [line1, line2, level, toggle])
      exe line1 . (toggle ? 'foldclose' : 'foldopen') | return ''
    endfor
  endfor
  call feedkeys("\<Cmd>echoerr 'E490: No fold found'\<CR>", 'n') | return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_children_expr(...) abort
  return utils#motion_func('fold#toggle_children', a:000, 1)
endfunction
function! fold#toggle_parent_expr(...) abort
  return utils#motion_func('fold#toggle_parent', a:000, 1)
endfunction

" Open or close inner folds within range (i.e. maximum fold level)
" Note: Here 'toggle' closes folds when 1 and opens when 0 (follows convention)
" Note: This permits using e.g. 'zck' and 'zok' even when outside fold and without
" fear of accidentally closing huge block e.g. class or document under cursor.
function! fold#toggle_inner(...) range abort
  if a:0 | call fold#update_folds(0) | endif | let folds = []
  let [lmin, lmax] = sort([a:firstline, a:lastline], 'n')
  let winview = a:0 > 1 ? a:2 : winsaveview()
  let levels = map(range(lmin, lmax), 'foldlevel(v:val)')
  let direc = lmin == lmax ? 0 : lmin == winview.lnum ? 1 : lmax == winview.lnum ? -1 : 0
  if direc && max(levels) == min(levels)
    let parent = fold#get_folds(lmin, lmax, 1, max(levels) - 1, 1)
    let cursor = get(parent, 0, [winview.topline, winview.topline + &lines, 0])
    let [imin, imax] = direc < 0 ? [lmin, cursor[0]] : [lmax, cursor[1]]
    let folds = fold#get_folds(imin, imax, 1, cursor[2], 1)
    let [lmin, lmax; rest] = get(folds, 0, [lmin, lmax])
  endif
  let folds = empty(folds) ? fold#get_folds(lmin, lmax, 1, max(levels) - 1) : folds
  let toggle = a:0 && a:1 >= 0 ? a:1 : 1 - s:toggle_state(lmin, lmax)
  for [line1, line2; rest] in folds
    let line1 = max([line1, lmin])  " possibly select
    let line2 = min([line2, lmax])
    exe line1 . ',' . line2 . (toggle ? 'foldclose' : 'foldopen')
  endfor
  if empty(folds)
    call feedkeys("\<Cmd>echoerr 'E490: No folds found'\<CR>", 'n')
  endif | return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_inner_expr(...) abort
  let args = a:0 ? a:000 + [winsaveview()] : []
  return utils#motion_func('fold#toggle_inner', args, 1)
endfunction
