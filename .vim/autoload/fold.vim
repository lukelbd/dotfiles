"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Initialize fold close-open status
" Note: This provides 'pseudo-levels' that auto-open when level is at or above
" the first regex and when that regex is not preceded by the second regex. Useful
" e.g. for python classes or tex environments occupying entire document and to
" enforce universal standard default of foldlevel=0 without hiding everything.
scriptencoding utf-8
let s:maxlines = 100  " maxumimum lines to search
let s:initials = [
  \ ['python', '^class\>', '', 1],
  \ ['fortran', '^\s*\(module\|program\)\>', '', 1],
  \ ['javascript', '^\s*\(export\s\+\|default\s\+\)*class\>', '', 1],
  \ ['typescript', '^\s*\(export\s\+\|default\s\+\)*class\>', '', 1],
  \ ['tex', '^\s*\\begin{document}', '', 1],
  \ ['tex', '^\s*\\begin{frame}', '^\s*\\begin{block}', 2],
  \ ['tex', '^\s*\\\(sub\)*section\>', '^\s*\\begin{frame}', 2],
\ ]
function! s:init_folds(...) abort range
  for [ftype, regex1, regex2, level] in s:initials
    if &l:diff || ftype !=# &l:filetype | continue | endif
    if !empty(regex2) && !search(regex2, 'nwc') | continue | endif
    for lnum in range(1, line('$'))  " open default folds
      if foldlevel(lnum) == level && getline(lnum) =~# regex1
        exe foldclosed(lnum) >= 0 ? lnum . 'foldopen' : ''
      endif
    endfor
  endfor
endfunction

" Return fold bounds with level &l:foldlevel + 1
" Note: Use fold#current_fold(0) to include filetype exceptions (e.g. if &foldlevel
" is 0 but we are on python method, return the method bounds). Use 1 to ignore them.
" Note: No native vimscript way to do this if fold is open so we use simple algorithm
" improved from https://stackoverflow.com/a/4776436/4970632 (note [z never raises error)
" Warning: Critical to record foldlevel('.') after pressing [z instead of ]z since
" calling foldlevel('.') on the end of a fold could return the level of its child.
" Warning: The zk/zj/[z/]z motions update jumplist, found out via trial and error
" even though not documented in :help jump-motions
function! fold#current_fold(...) abort  " current &foldlevel fold
  let winview = winsaveview()  " save view
  let minfold = a:0 > 1 ? a:2 : &l:foldlevel
  let ignore = a:0 > 0 ? a:1 : 0
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
  for [ftype, regex1, regex2, level] in ignore ? [] : s:initials
    if ftype !=# &l:filetype || level - 1 != minfold | continue | endif
    if !empty(regex2) && !search(regex2, 'nwc') | continue | endif
    if getline(line1) =~# regex1 | let recurse = 1 | break | endif
  endfor
  let level = foldlevel(line1)
  call winrestview(winview)
  if recurse
    return fold#current_fold(ignore, minfold + 1)
  elseif level > minfold
    return [line1, line2, foldlevel(line1)]
  else  " current fold not found
    return [line('.'), line('.'), 0]
  endif
endfunction

" Find folds within given range
" Note: This ignores folds defined in s:initials, e.g. python classes and tex
" documents. Used to close-open smaller fold blocks ignoring huge blocks.
function! fold#find_folds(...) abort
  let [lnum, lend] = a:0 > 1 ? [a:1, a:2] : [line('.'), line('.')]
  let [lnum, lend] = map([lnum, lend], 'min([max([v:val, 1]), line("$")])')
  let forward = lend >= lnum
  let ignore = a:0 > 2 ? a:3 : 0
  let minfold = a:0 > 3 ? a:4 : &l:foldlevel
  let maxfolds = a:0 > 4 ? a:5 : 0
  let folds = []
  let ignores = ignore ? [0, 1] : [0]
  let winview = winsaveview()
  while forward ? lnum <= lend : lnum >= lend
    exe lnum
    for ignore in ignores
      let [line1, line2, level] = fold#current_fold(ignore, minfold)
      if line2 > line1 | break | endif  " prefer 'current' fold
    endfor
    if line2 > line1
      call add(folds, [line1, line2])
    endif
    if maxfolds > 0 && len(folds) >= maxfolds
      break
    endif
    if forward  " search forward
      let lnum = max([lnum, line2]) + 1
    else  " search backward
      let lnum = min([lnum, line1]) - 1
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
  endif
  return [join(delim1, ''), join(delim2, '')]
endfunction
function! fold#get_label(line, ...) abort
  let char = comment#get_char()()
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

" Return filetype specific fold label
" Note: This concatenates python docstring lines and uses frametitle from
" beamer presentations or labels from tex figures. Should add to this.
function! fold#get_label_python(line, ...) abort
  let regex = '["'']\{3}'  " docstring expression
  let label = fold#get_label(a:line, 0)
  let width = get(g:, 'linelength', 88) - 10  " minimum width
  if label =~# '^try:\s*$\|' . regex . '\s*$'  " append lines
    for lnum in range(a:line + 1, a:0 ? a:1 : a:line + s:maxlines)
      let doc = fold#get_label(lnum, 1)  " remove indent
      let doc = substitute(doc, '[-=]\{3,}', '', 'g')
      let head = label =~# regex . '\s*$'
      let tail = doc =~# '^\s*' . regex
      let label .= repeat(' ', !head && !tail && !empty(doc)) . doc
      if tail || len(label) > width || label =~# '^try:' | break | endif
    endfor
  endif
  let l:subs = []  " see: https://vi.stackexchange.com/a/16491/8084
  let result = substitute(label, regex, '\=add(l:subs, submatch(0))', 'gn')
  let label .= len(l:subs) % 2 ? '···' . substitute(l:subs[0], '^[frub]*', '', 'g') : ''
  return label  " closed docstring
endfunction
function! fold#get_label_tex(line, ...) abort
  let [line, label] = [a:line, fold#get_label(a:line, 0)]
  let indent = substitute(label, '\S.*$', '', 'g')
  if label =~# 'begingroup\|begin\s*{\s*\(frame\|figure\|table\|center\)\*\?\s*}'
    let regex = label =~# '{\s*frame\*\?\s*}' ? '^\s*\\frametitle' : '^\s*\\label'
    for lnum in range(a:line + 1, a:0 ? a:1 : a:line + s:maxlines)
      let bool = getline(lnum) =~# regex
      if bool | let [line, label] = [lnum, fold#get_label(lnum, 0)] | break | endif
    endfor
  endif
  if label =~# '{\s*\(%.*\)\?$'  " append lines
    for lnum in range(line + 1, a:0 ? a:1 : line + s:maxlines)
      let bool = lnum == line + 1 || label[-1:] ==# '{'
      let label .= (bool ? '' : ' ') . fold#get_label(lnum, 1)
    endfor
  endif
  let label = substitute(label, '\\\@<!\\', '', 'g')  " remove backslashes
  let label = substitute(label, '\(textbf\|textit\|emph\){', '', 'g')  " remove style
  let label = indent . substitute(label, '^\s*', '', 'g')
  return label
endfunction

" Generate truncated fold text. In future should include error cound information.
" Note: Since gitgutter signs are not shown over closed folds include summary of
" changes in fold text. See https://github.com/airblade/vim-gitgutter/issues/655
function! fold#fold_text(...) abort
  if a:0  " debugging mode
    let [line1, line2, level] = call('fold#current_fold', a:000)
  else  " internal mode
    let [line1, line2, level] = [v:foldstart, v:foldend, len(v:folddashes)]
  endif
  let level = repeat(':', level)  " fold level
  let lines = string(line2 - line1 + 1)  " number of lines
  let winview = winsaveview()  " translate byte column index to character index
  let leftidx = charidx(getline(winview.lnum), winview.leftcol)
  let maxlen = get(g:, 'linelength', 88) - 1  " default maximum
  let hunk = git#hunk_stats(line1, line2, 1)  " abbreviate with '1'
  let dots = repeat('·', len(string(line('$'))) - len(lines))
  let stats = hunk . level . dots . lines  " default statistics
  if &l:diff  " fill with maximum width
    let [label, stats] = [level . dots . lines, repeat('~', maxlen - strwidth(stats) - 2)]
  elseif exists('*fold#get_label_' . &l:filetype)
    let label = fold#get_label_{&l:filetype}(line1, min([line1 + s:maxlines, line2]))
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
    if foldclosed(lnum) > (a:0 ? a:1 : 0) | return 1 | endif
  endfor
endfunction
function! s:toggle_nested(line1, line2, level, ...) abort
  let parents = []  " closed parent folds
  let nested = []  " fold levels and lines
  for lnum in range(a:line1, a:line2)
    let [level, inum] = [foldlevel(lnum), foldclosed(lnum)]
    if level > a:level
      let item = [level, lnum]  " toggle in reverse level order
      call add(nested, item)
    elseif inum > 0
      let item = [level, inum]  " open before below algorithm
      if index(parents, item) == -1 | call add(parents, item) | endif
    endif
  endfor
  for [_, lnum] in sort(parents) | exe lnum . 'foldopen' | endfor  " temporarily open
  if a:0 ? a:1 : 1 - s:toggle_state(a:line1, a:line2, a:line1)  " close by decreasing level
    for [_, lnum] in reverse(sort(nested))
      if foldclosed(lnum) <= 0 && foldlevel(lnum) > a:level
        exe lnum . 'foldclose'
      endif
    endfor
  else  " open by increasing level
    for [_, lnum] in sort(nested)
      if foldclosed(lnum) > 0 && foldlevel(foldclosed(lnum)) > a:level
        exe lnum . 'foldopen'
      endif
    endfor
  endif
  for [_, lnum] in reverse(sort(parents)) | exe lnum . 'foldclose' | endfor  " restore
  return nested
endfunction

" Toggle nested fold or current fold
" Note: If called on already-toggled 'current' folds the explicit 'foldclose/foldopen'
" toggles the parent. So e.g. 'zCzC' first closes python methods then the class.
function! fold#toggle_current(...) abort
  call fold#update_folds(0)
  for force in [0, 1]
    let [line1, line2, level] = fold#current_fold(force)
    if line2 <= line1 | continue | endif
    let toggle = a:0 ? a:1 : 1 - s:toggle_state(line1, line1)  " custom toggle
    call call('s:toggle_nested', [line1, line2, level, toggle])
    exe line1 . (toggle ? 'foldclose' : 'foldopen') | return
  endfor
  return feedkeys("\<Cmd>echoerr 'E490: No fold found'\<CR>", 'n')
endfunction
function! fold#toggle_nested(...) abort
  call fold#update_folds(0)
  for force in [0, 1]  " whether to ignore filetype exceptions
    let [line1, line2, level] = fold#current_fold(force)
    if line2 <= line1 | continue | endif
    let args = [line1, line2, level] + copy(a:000)
    let folds = call('s:toggle_nested', args)
    if len(folds) > 0 | return | endif
  endfor
  call feedkeys("\<Cmd>echoerr 'E490: No folds found'\<CR>", 'n')
endfunction

" Open or close folds over input range
" Note: Here 'a:toggle' closes folds when 1 and opens when 0 (convention).
" Note: This filters to top-level folds
" Note: This permits using e.g. 'zcc' and 'zoo' even when outside fold and without
" fear of accidentally closing huge block e.g. class or document under cursor.
function! fold#toggle_range(...) range abort
  call fold#update_folds(0)
  let [lmin, lmax] = sort([a:firstline, a:lastline], 'n')
  let force = a:0 > 0 ? a:1 : 0
  let toggle = a:0 > 1 ? a:2 : 1 - s:toggle_state(lmin, lmax)
  let current = a:0 > 2 ? a:3 : line('.')
  let level = max(map(range(lmin, lmax), 'foldlevel(v:val)'))
  let level = max([level - 1, 0])  " run :fold[open|close] on highest levels in range
  let folds = fold#find_folds(lmin, lmax, force, level)
  let parent = fold#find_folds(lmin, lmax, 1, 0, 1)
  let [find1, find2] = empty(parent) ? [1, line('$')] : parent[0]
  if empty(folds) && lmin != lmax && (lmin == current || lmax == current)
    if lmax == current  " search previous folds
      let folds = fold#find_folds(lmin, find1, force, 0, 1)
    else  " search following folds
      let folds = fold#find_folds(lmax, find2, force, 0, 1)
    endif
  endif
  if empty(folds) && !empty(parent)
    let folds = parent
  endif
  if empty(folds)
    return feedkeys("\<Cmd>echoerr 'E490: No folds found'\<CR>", 'n')
  endif
  for [line1, line2] in folds
    if line1 <= lmin && line2 >= lmax
      let line1 = max([line1, lmin])
      let line2 = min([line2, lmax])
    endif
    let state = foldclosed(line1) > 0
    let range = line1 . ',' . line2
    let bang = force ? '!' : ''
    let cmd = toggle ? 'foldclose' : 'foldopen'
    exe line1 . ',' . line2 . cmd . bang
  endfor
  return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_range_expr(...) abort
  return utils#motion_func('fold#toggle_range', a:000 + [line('.')], 1)
endfunction
