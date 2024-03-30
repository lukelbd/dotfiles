"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Initialize fold state with some patterns open
" Note: This provides 'pseudo-levels' that auto-open when level is at or above
" the first regex and when that regex is not preceded by the second regex. Useful
" e.g. for python classes or tex environments occupying entire document and to
" enforce universal standard default of foldlevel=0 without hiding everything.
scriptencoding utf-8
let s:defaults = [
  \ ['python', '^class\>', '', 1],
  \ ['fortran', '^\s*\(module\|program\)\>', '', 1],
  \ ['fugitive', '^\(Staged\|Unstaged\|Unpushed\)\>', '', 1],
  \ ['tex', '^\s*\\begin{document}', '', 1],
  \ ['tex', '^\s*\\begin{frame}', '^\s*\\begin{block}', 2],
  \ ['tex', '^\s*\\\(sub\)*section\>', '^\s*\\begin{frame}', 2],
\ ]
function! fold#init(...) abort
  for [ftype, regex1, regex2, level] in s:defaults
    if &l:diff || ftype !=# &l:filetype | continue | endif
    if !empty(regex2) && !search(regex2, 'nwc') | continue | endif
    for lnum in range(1, line('$'))  " open default folds
      if foldclosed(lnum) > 0 && foldlevel(lnum) == level
        exe getline(lnum) =~# regex1 ? lnum . 'foldopen' : ''
      endif
    endfor
  endfor
endfunction

" Return line of fold under cursor matching &l:foldlevel + 1
" Warning: Critical to record foldlevel('.') after pressing [z instead of ]z since
" calling foldlevel('.') on the end of a fold could return the level of its child.
" Warning: The zk/zj/[z/]z motions update jumplist, found out via trial and error
" even though not documented in :help jump-motions
" Note: No native vimscript way to do this if fold is open so we use simple algorithm
" improved from https://stackoverflow.com/a/4776436/4970632 (note [z never raises error)
function! fold#current(...) abort  " current &foldlevel fold
  let toplevel = a:0 ? a:1 : &l:foldlevel
  let winview = winsaveview()  " save view
  let prev = 'keepjumps normal! [z'
  let next = 'keepjumps normal! ]z'
  let lnum = -1
  while line('.') != lnum && foldlevel('.') > toplevel + 1
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
  for [ftype, regex1, regex2, level] in s:defaults
    if ftype !=# &l:filetype || level - 1 != toplevel | continue | endif
    if !empty(regex2) && !search(regex2, 'nwc') | continue | endif
    if getline(line1) =~# regex1 | let recurse = 1 | break | endif
  endfor
  call winrestview(winview)
  if recurse
    return fold#current(toplevel + 1)
  else
    return [line1, line2, foldlevel(line1)]
  endif
endfunction

" Helper functions for fold text
" Note: This applies closing delimiters e.g. if line ends with parentheses
" Note: This concatenates python docstring lines and uses frametitle from
" beamer presentations or labels from tex figures. Should add to this.
let s:nmax = 100  " maxumimum number of lines to search
let s:closes = {'[': ']', '(': ')', '{': '}', '<': '>'}
let s:docstring = '["'']\{3}'  " docstring expression
function! fold#get_text(line, ...) abort
  let regex = a:0 && a:1 ? '\(^\s*\|\s*$\)' : '\s*$'
  let label = substitute(getline(a:line), regex, '', 'g')
  let regex = '\S\@<=\s*' . comment#get_regex()
  let regex .= len(comment#get_char()) == 1 ? '[^' . comment#get_char() . ']*$' : '.*$'
  let label = substitute(label, regex, '', 'g')
  return label
endfunction
function! fold#get_text_python(line, ...) abort
  let label = fold#get_text(a:line)
  let width = get(g:, 'linelength', 88) - 10  " minimum width
  if label =~# '^try:\s*$\|' . s:docstring . '\s*$'  " append lines
    for lnum in range(a:line + 1, a:0 ? a:1 : a:line + s:nmax)
      let doc = fold#get_text(lnum, 1)  " remove indent
      let doc = substitute(doc, '[-=]\{3,}', '', 'g')
      let head = label =~# s:docstring . '\s*$'
      let tail = doc =~# '^\s*' . s:docstring
      let label .= repeat(' ', !head && !tail && !empty(doc)) . doc
      if tail || len(label) > width || label =~# '^try:' | break | endif
    endfor
  endif
  let l:subs = []  " see: https://vi.stackexchange.com/a/16491/8084
  let result = substitute(label, s:docstring, '\=add(l:subs, submatch(0))', 'gn')
  let label .= len(l:subs) % 2 ? '···' . substitute(l:subs[0], '^[frub]*', '', 'g') : ''
  return label  " closed docstring
endfunction
function! fold#get_text_tex(line, ...)
  let [line, label] = [a:line, fold#get_text(a:line)]
  let indent = substitute(label, '\S.*$', '', 'g')
  if label =~# 'begingroup\|begin\s*{\s*\(frame\|figure\|table\|center\)\*\?\s*}'
    let regex = label =~# '{\s*frame\*\?\s*}' ? '^\s*\\frametitle' : '^\s*\\label'
    for lnum in range(a:line + 1, a:0 ? a:1 : a:line + s:nmax)
      let bool = getline(lnum) =~# regex
      if bool | let [line, label] = [lnum, fold#get_text(lnum)] | break | endif
    endfor
  endif
  if label =~# '{\s*\(%.*\)\?$'  " append lines
    for lnum in range(line + 1, a:0 ? a:1 : line + s:nmax)
      let bool = lnum == line + 1 || label[-1:] ==# '{'
      let label .= (bool ? '' : ' ') . fold#get_text(lnum, 1)
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
function! s:get_delims(label, ...) abort
  let regex = '\([[({<]*\)\s*$'  " opening delimiter
  let items = call('matchlist', [a:label, regex] + a:000)
  let dopen = split(get(items, 1, ''), '\zs', 1)
  let dclose = map(copy(dopen), {idx, val -> get(s:closes, val, '')})
  if &l:filetype ==# 'python' && get(dopen, -1, '') ==# ')'
    call add(dclose, a:label =~# '^\s*\(def\|class\)\>' ? ':' : '')
  endif
  return [join(dopen, ''), join(dclose, '')]
endfunction
function! fold#fold_text(...) abort
  if a:0 && a:1  " debugging mode
    let [line1, line2, level] = fold#current()
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
  elseif !exists('*fold#get_text_' . &l:filetype)
    let label = fold#get_text(line1)
  else  " filetype specific label
    let label = fold#get_text_{&l:filetype}(line1, min([line1 + s:nmax, line2]))
  endif
  let [dopen, dclose] = s:get_delims(label)
  let width = maxlen - strwidth(stats) - 1
  let label = empty(dclose) ? label : label . '···' . dclose
  if strwidth(label) >= width  " truncate fold text
    let dcheck = strpart(label, width - 4 - strwidth(dclose), 1)
    let dclose = dcheck ==# dopen ? '' : dclose
    let dcheck = strpart(label, width - 4 - strwidth(dclose))
    let label = strpart(label, 0, width - 5 - strwidth(dclose))
    let label = label . '···' . dclose . '  '
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
  if &l:foldmethod =~# '^diff\|^marker'
    return
  endif
  let winview = winsaveview()
  if queued || a:force
    if &l:diff  " difference mode enabled
      diffupdate
      setlocal foldmethod=diff
    elseif &l:filetype ==# 'python'
      setlocal foldmethod=expr  " e.g. in case stuck, then FastFoldUpdate sets to manual
      setlocal foldexpr=python#fold_expr(v:lnum)
      call SimpylFold#Recache()
    elseif &l:filetype ==# 'markdown'
      setlocal foldmethod=expr  " e.g. in case stuck, then FastFoldUpdate sets to manual
      setlocal foldexpr=Foldexpr_markdown(v:lnum)
      setlocal foldtext=fold#fold_text()
    endif
    silent! FastFoldUpdate
    let b:fastfold_queued = 0
  endif
  if a:0
    if a:1 > 0  " apply defaults
      let &l:foldlevel = &l:foldlevelstart
    endif
    call fold#init()
    if a:1 <= 1  " open under cursor
      exe 'normal! zv'
    endif
  endif
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
  let parents = []
  let nested = []  " fold levels and lines
  for lnum in range(a:line1, a:line2)
    if foldlevel(lnum) > a:level
      let item = [foldlevel(lnum), lnum]  " run in reverse level order
      call add(nested, item)  " queue fold level and line
    elseif foldclosed(lnum) > 0  " open before nested toggle
      let item = [foldlevel(lnum), foldclosed(lnum)]
      if index(parents, item) == -1 | call add(parents, item) | endif
    endif
  endfor
  for [_, lnum] in sort(parents) | exe lnum . 'foldopen' | endfor  " temporary
  let toggle = a:0 ? a:1 : 1 - s:toggle_state(a:line1, a:line2, a:line1)
  for [_, lnum] in sort(nested)  " open nested folds by increasing level
    if foldclosed(lnum) > 0 && !toggle
      if foldlevel(foldclosed(lnum)) > a:level  " avoid parent fold
        exe lnum . 'foldopen'
      endif
    endif
  endfor
  for [_, lnum] in reverse(sort(nested))  " close nested folds by decreasing level
    if foldclosed(lnum) <= 0 && toggle
      exe lnum . 'foldclose' | if foldlevel(foldclosed(lnum)) <= a:level  " skip parent
        exe foldclosed(lnum) . 'foldopen'
      endif
    endif
  endfor
  for [_, lnum] in reverse(sort(parents)) | exe lnum . 'foldclose' | endfor  " restore
endfunction

" Toggle nested fold or current fold
" Note: When called on line below fold level this will close fold. So e.g.
" 'zCzC' will first fold up to foldlevel then fold additional levels.
function! fold#toggle_nested(...) abort
  call fold#update_folds(0)
  let [line1, line2, level] = fold#current()
  let toggle = copy(a:000)  " use default arguments
  let args = extend([line1, line2, level], toggle)  " default s:toggle_nested
  if line2 > line1
    call call('s:toggle_nested', args)
  else  " compact error message
    call feedkeys("\<Cmd>echoerr 'E490: No fold found'\<CR>", 'n')
  endif
endfunction
function! fold#toggle_current(...) abort
  call fold#update_folds(0)
  let [line1, line2, level] = fold#current()
  let toggle = a:0 ? a:1 : 1 - s:toggle_state(line1, line1)  " custom toggle
  let args = add([line1, line2, level], toggle)
  if line2 > line1
    call call('s:toggle_nested', args) | exe line1 . (toggle ? 'foldclose' : 'foldopen')
  else
    call feedkeys("\<Cmd>echoerr 'E490: No fold found'\<CR>", 'n')
  endif
endfunction

" Open or close folds over input range
" Note: Here 'a:toggle' closes folds when 1 and opens when 0. Also update folds
" before toggling as with other toggle commands.
function! fold#toggle_range(bang, ...) range abort
  call fold#update_folds(0)
  let [line1, line2] = sort([a:firstline, a:lastline], 'n')
  let toggle = a:0 ? a:1 : 1 - s:toggle_state(line1, line2)
  let bang = a:bang ? '!' : ''
  if toggle  " close folds (no bang = single level)
    silent! exe line1 . ',' . line2 . 'foldclose' . bang
  else  " open folds (no bang = single level)
    silent! exe line1 . ',' . line2 . 'foldopen' . bang
  endif
  return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_range_expr(...) abort
  return utils#motion_func('fold#toggle_range', a:000, 1)
endfunction
