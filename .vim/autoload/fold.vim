"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Return bounds and level for any closed fold or open fold of requested level
" NOTE: No native way to get bounds if fold is open so use normal-mode algorithm.
" Also [z never raises error, but does update jumplist even though not documented
" in :help jump-motions. See: https://stackoverflow.com/a/4776436/4970632 
" NOTE: This helps supports following toggles: non-recursive (highest level in range),
" inner inner (folds within highest-level fold under cursor that hs children), outer
" inner (folds within current 'main' parent fold), outer recursirve (parent fold and
" all its children), and outer force (as with outer but ignoring regexes).
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

" Return ignored auto-opened folds matching given regex
" NOTE: This provides 'pseudo-levels' that auto-open when level is at or above
" the first regex and when that regex is not preceded by the second regex. Useful
" e.g. for python classes or tex environments occupying entire document and to
" enforce universal standard default of foldlevel=0 without hiding everything.
" Return fold under cursor above a given level
scriptencoding utf-8  " {{{
let s:folds_ignore = [
  \ ['python', '^class\>', '', 1],
  \ ['fortran', '^\s*\(module\|program\)\>', '', 1],
  \ ['javascript', '^\s*\(export\s\+\|default\s\+\)*class\>', '', 1],
  \ ['typescript', '^\s*\(export\s\+\|default\s\+\)*class\>', '', 1],
  \ ['tex', '^\s*\\begin{document}', '', 1],
  \ ['tex', '^\s*\\begin{frame}', '^\s*\\begin{block}', 2],
  \ ['tex', '^\s*\\\(sub\)*section\>', '^\s*\\begin{frame}', 2],
\ ]  " }}}
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

" Return text object ranges
" NOTE: Here, similar to how 'vaw' on last word on line includes preceding spaces
" and elsewhere includes following spaces, have 'vaz' include space below folds of
" same level if available or the space above if not available.
function! s:get_range(outer, ...) abort
  let result = a:0 && a:1 ? fold#get_parent() : fold#get_fold()
  let result = empty(result) ? [line('.'), line('.'), 0] : result
  let [line1, line2, level] = result
  if line2 > line1 && level > 0
    let range = 'lines ' . line1 . ' to ' . line2
    let paren = '(level ' . level . ')'
    redraw | echom 'Selected ' . range . ' ' . paren
  else
    redraw | echohl ErrorMsg
    echom 'E490: No fold found'
    echohl None | return ['v', getpos('.'), getpos('.')]
  endif
  if a:outer  " include lines below or above
    let winview = winsaveview()
    exe line2 | exe 'keepjumps normal! zj'
    if line('.') > line2  " top of next fold
      if foldlevel('.') == level
        let line2 = line('.') - 1
      endif
    else  " bottom of previous fold
      exe line1 | exe 'keepjumps normal! zk'
      if line('.') < line1 && foldlevel('.') == level
        let line1 = line('.') + 1
      endif
    endif
    call winrestview(winview)
  endif
  let pos1 = [0, line1, 1, 0]
  let pos2 = [0, line2, col([line2, '$']), 0]
  return ['V', pos1, pos2]
endfunction
function! fold#get_fold_i() abort
  return s:get_range(0, 0)
endfunction
function! fold#get_fold_a() abort
  return s:get_range(1, 0)
endfunction
function! fold#get_parent_i() abort
  return s:get_range(0, 1)
endfunction
function! fold#get_parent_i() abort
  return s:get_range(1, 1)
endfunction

" Return folds and properties across line range
" NOTE: This ignores folds defined in s:folds_ignore, e.g. python classes and
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

" Return fastfold-managed manual folds with marks
" WARNING: Critical to re-open folds after defining or subsequent fold definitions
" fail. Still want to initialize with closed folds though so do that afterwards.
" NOTE: Previously tried using regions with 'vim-syntaxMarkerFold' but causes major
" issues since either disables highlighting or messes up inner highlight items when
" trying to use e.g. contains=ALL since several use naked 'contained' property.
function! s:is_divider(...) abort
  let regex = '\(' . comment#get_regex(0) . '\)\?'
  let regex = '^' . regex . '\s*[-=]\{3,}' . regex . '\(\s\|$\)'
  return getline(a:0 ? a:1 : '.') =~# regex
endfunction
function! fold#get_markers() abort
  let winview = winsaveview()
  let [mark1, mark2] = split(&l:foldmarker, ',')
  let [head, tail] = ['\%(^\|\s\)\zs', '\(\d*\)\s*$']  " end of line only
  let regex = head . '\(' . mark1 . '\|' . mark2 . '\)' . tail
  let folds = []  " fold queue
  let heads = {}  " mark lines
  goto | while v:true
    let flags = line('.') == 1 && col('.') == 1 ? 'cW' : 'W'
    let [lnum, cnum] = searchpos(regex, flags, "tags#get_skip(0, 'Comment')")
    if lnum == 0 || cnum == 0 | break | endif
    let line = getline(lnum)
    let parts = matchlist(line, regex, cnum - 1)
    if empty(parts)
      echohl WarningMsg
      echom 'Warning: Failed to setup mark folds.'
      echohl None | break
    endif
    let lnum -= s:is_divider(lnum - 1) && s:is_divider(lnum + 1)
    let [mark, level] = parts[1:2]
    if parts[1] =~# mark2  " close previously defined fold
      let level = empty(level) ? max(keys(heads)) : str2nr(level)
      if has_key(heads, string(level))
        call add(folds, [heads[level], lnum, level])
        call remove(heads, level)
      endif
    else  " open fold after deleting previous and closing inner
      let level = empty(level) ? max(keys(heads)) + 1 : str2nr(level)
      for ilevel in range(level, 10)
        if has_key(heads, string(ilevel))
          call add(folds, [heads[ilevel], lnum - 1, ilevel])
          call remove(heads, ilevel)
        endif
      endfor
      let heads[level] = lnum
    endif
  endwhile
  for level in keys(heads)
    call add(folds, [heads[level], line('$'), str2nr(level)])
  endfor
  call winrestview(winview)
  return sort(folds, {i1, i2 -> i1[2] - i2[2]})
endfunction

" Return default fold label
" NOTE: This filters trailing comments, removes git-diff chunk text following stats,
" and adds following line if the fold line is a single open delimiter (e.g. json).
function! s:get_delims(label, ...) abort
  let pairs = {'[': ']', '(': ')', '{': '}', '<': '>'}
  let items = call('matchlist', [a:label, '\([[({<]*\)\s*$'] + a:000)
  let delim1 = split(get(items, 1, ''), '\zs', 1)
  let delim2 = map(copy(delim1), {idx, val -> get(pairs, val, '')})
  let append = &l:filetype ==# 'python' && get(delim1, -1, '') ==# ')'
  call add(delim2, append && a:label =~# '^\s*\(def\|class\)\>' ? ':' : '')
  return [join(delim1, ''), join(delim2, '')]
endfunction
function! s:get_inner(label, line) abort
  let label1 = substitute(a:label, '^\s*', '', '')
  let [delim1, outer] = s:get_delims(label1)
  if label1 !=# delim1 | return '' | endif  " not naked delimiter
  let label2 = fold#fold_label(a:line, 1)
  let [delim2, _] = s:get_delims(label2)
  if label2 ==# delim2 | return '' | endif  " no additional info
  let inner = substitute(label2, '\s*\([[({<]*\)\s*$', '', 'g')
  return ' ' . inner . ' ··· ' . outer  " e.g. json folds
endfunction
function! fold#fold_label(line, ...) abort
  let initial = getline(a:line + s:is_divider(a:line))
  let fugitive = !empty(get(b:, 'fugitive_type', '')) || &l:filetype =~# '^git$\|^diff$'
  let marker = split(&l:foldmarker, ',')[0] . '\d*\s*$'
  let regex = '\(\S\@<=\s\+' . comment#get_regex(0) . '.*\)\?\s*$'
  let regex = a:0 && a:1 ? '\(^\s*\|' . regex . '\)' : regex
  let label = substitute(initial, marker, '', '')
  let label = substitute(label, regex, '', 'g')
  if fugitive  " remove context information following delta
    let label = substitute(label, '^\(@@.\{-}@@\).*$', '\1', '')
  elseif !a:0 || !a:1  " append next line for naked open delimiters
    let label .= s:get_inner(label, a:line + 1)
  endif | return label
endfunction

" Generate truncated fold text. In future should include error cound information.
" NOTE: Since gitgutter signs are not shown over closed folds include summary of
" changes in fold text. See https://github.com/airblade/vim-gitgutter/issues/655
function! fold#fold_text(...) abort
  let winview = winsaveview()  " translate byte column index to character index
  if a:0 && a:1  " debugging mode
    exe winview.lnum | let [line1, line2, level] = fold#get_fold()
    call winrestview(winview)
  else  " internal mode
    let [line1, line2] = [v:foldstart, v:foldend]
    let level = len(v:folddashes)
  endif
  let leftidx = charidx(getline(winview.lnum), winview.leftcol)
  let [label, space, stats] = s:fold_text(line1, line2, level)
  return strcharpart(label . space . stats, leftidx)
endfunction
function! s:fold_text(line1, line2, level)
  let level = a:level . repeat(':', a:level)  " fold level
  let lines = string(a:line2 - a:line1 + 1)  " number of lines
  let maxlen = get(g:, 'linelength', 88) - 1  " default maximum
  let flags = edit#stat_errors(a:line1, a:line2)  " lintint messages
  let flags .= git#stat_hunks(a:line1, a:line2, 0, 1)  " abbreviate with '1'
  let dots = repeat('·', len(string(line('$'))) - len(lines))
  let stats = level . dots . lines  " default statistics
  if &l:diff  " fill with maximum width
    let [label, stats] = [level . dots . lines, repeat('~', maxlen - strwidth(stats) - 2)]
  elseif exists('*' . &l:filetype . '#fold_text')
    let label = {&l:filetype}#fold_text(a:line1, a:line2)
  else  " global default label
    let label = fold#fold_label(a:line1)
  endif
  let [delim1, delim2] = s:get_delims(label)
  let indent = matchstr(label, '^\s*')
  let width = maxlen - strwidth(stats) - 1
  let label = empty(delim2) ? label : label . '···' . delim2
  let label = empty(flags) ? label : indent . flags . ' ' . strpart(label, len(indent))
  if strwidth(label) >= width  " truncate fold text
    let dcheck = strpart(label, width - 4 - strwidth(delim2), 1)
    let delim2 = dcheck ==# delim1 ? '' : delim2
    let dcheck = strpart(label, width - 4 - strwidth(delim2))
    let label = strpart(label, 0, width - 5 - strwidth(delim2))
    let label = label . '···' . delim2 . '  '
  endif
  let space = repeat(' ', width - strwidth(label))
  return [label, space, stats]
endfunction

" Helper functions for returning all folds
" NOTE: Necessary to temporarily open outer folds before toggling inner folds. No way
" to target them with :fold commands or distinguish adjacent children with same level
function! s:fold_source(line1, line2, level, ...) abort
  let [outer, inner] = [[], []]
  for lnum in range(a:line1, a:line2)
    let ilevel = foldlevel(lnum)
    if !ilevel | continue | endif
    let iline = foldclosed(lnum)
    if ilevel > a:level
      call add(inner, [ilevel, lnum])
    elseif iline > 0 && index(outer, [ilevel, iline]) == -1
      call add(outer, [ilevel, iline])
    endif
  endfor | return [sort(outer), sort(inner)]
endfunction
function! fold#fold_source(...) abort
  let [lmin, lmax, level] = a:0 ? a:000 : [1, line('$'), 1]
  let [outer, inner] = s:fold_source(lmin, lmax, level)
  let [folds, ifolds] = [[], fold#get_folds(lmin, lmax, level)]
  for [_, lnum] in outer | exe lnum . 'foldopen' | endfor
  for [line1, line2, level] in ifolds  " guaranteed to match level
    let ifold = [line1, line2, level]
    call add(folds, ifold)
    if !empty(filter(copy(inner), 'v:val[1] >= line1 && v:val[1] <= line2'))
      let ifolds = fold#fold_source(line1, line2, level + 1)
      call extend(folds, ifolds)
    endif
  endfor
  for [_, lnum] in reverse(outer) | exe lnum . 'foldclose' | endfor
  return folds
endfunction

" Select buffer folds rendered with foldtext()
" NOTE: This was adapted from fzf-folds plugin. This includes folds inside closed
" parent folds and uses custom fold-text function instead of foldtextresult().
" See: https://github.com/roosta/fzf-folds.vim
function! s:goto_fold(fold) abort
  if empty(a:fold) | return | endif
  let [path, lnum; rest] = split(a:fold, ':')
  exe 'normal! m''' | call cursor(lnum, 0)
  exe 'normal! zvzzze'
endfunction
function! s:get_flags(fold) abort
  let hunk = '\%(%s\(\d\+\)\)\?'  " hunk regex
  let regex = join(map(['!', '+', '\~', '-'], 'printf(hunk, v:val)'), '')
  let parts = map(matchlist(a:fold, regex)[1:4], 'str2nr(v:val)')
  return [parts[0], parts[1] + parts[2] + parts[3]]  " note str2nr('') is zero
endfunction
function! fold#fzf_folds(...) abort
  let bang = a:0 ? a:1 : 0  " fullscreen
  let folds = fold#fold_source()
  let [texts1, texts2, texts] = [[], [], []]
  for [line1, line2, level] in folds
    let [count1, count2] = s:get_flags(text)
    let [text, _, stats] = s:fold_text(line1, line2, level)
    let stats = substitute(stats, '^\(\d\):\+', '\1:', '')
    let stats = substitute(stats, '·', ' ', 'g')
    let text = substitute(text, '^\s*', '', '')
    let text = bufname() . ':' . line1 . ':' . stats . ' ' . text
    if count1  " ale.vim locations
      call add(texts1, [text, count1])
    elseif count2  " gitgutter changes
      call add(texts2, [text, count2])
    else  " standard label
      call add(texts, text)
    endif
  endfor
  let texts1 = sort(texts1, {i1, i2 -> i2[1] - i1[1]})
  let texts2 = sort(texts2, {i1, i2 -> i2[1] - i1[1]})
  let texts = map(texts1, 'v:val[0]') + map(texts2, 'v:val[0]') + texts
  let opts = fzf#vim#with_preview({'placeholder': '{1}:{2}'})
  let opts = join(map(get(opts, 'options', []), 'fzf#shellescape(v:val)'), ' ')
  let opts .= ' -d : --with-nth 3.. --preview-window +{2}-/2 --layout=reverse-list'
  if empty(text) | return | endif
  let options = {
    \ 'source': texts,
    \ 'sink': function('s:goto_fold'),
    \ 'options': opts . " --prompt='Fold> '",
  \ }
  return fzf#run(fzf#wrap('folds', options, bang))
endfunction

" Update the default fold options
" NOTE: This is called by after/common.vim following Syntax autocommand
" WARNING: Sometimes run into issue where opening new files or reading updates
" permanently disables 'expr' folds. Account for this by re-applying fold method.
function! fold#update_method(...) abort
  let [method, expr] = ['syntax', '']  " default values
  let current = &l:foldmethod  " active method
  let cached = get(w:, 'lastfdm', 'manual')
  if &l:filetype ==# 'csv'  " initialize with 'manual'
    let method = 'manual'
  elseif &l:diff  " difference mode enabled
    silent! diffupdate | let method = 'diff'
  elseif &l:filetype ==# 'markdown'
    silent! doautocmd Mkd CursorHold | let expr = 'Foldexpr_markdown(v:lnum)'
  elseif &l:filetype ==# 'python'
    let expr = 'python#fold_expr(v:lnum)'
  elseif &l:filetype ==# 'rst'
    let expr = 'RstFold#GetRstFold()'
  endif
  let method = !empty(expr) ? 'expr' : method
  let recache = cached ==# 'manual' || method !=# cached
  let &l:foldtext = 'fold#fold_text()'
  if !empty(expr) && &l:foldexpr !=# expr
    call SimpylFold#Recache()
    let &l:foldmethod = 'expr' | let &l:foldexpr = expr
  elseif current ==# 'manual' && recache
  \ || current !=# 'manual' && current !=# method
    let &l:foldmethod = method
  endif
endfunction

" Update the fold bound, level, and open-close status
" NOTE: Use normal mode zm/zr instead of :set foldlevel to truncate at maximum level
" NOTE: Here 'zX' will show at most one nested fold underneath cursor
" WARNING: Regenerating b:SimPylFold_cache with manual SimpylFold#FoldExpr() call
" can produce strange internal bug. Instead rely on FastFoldUpdate to fill the cache.
function! fold#update_level(...) abort
  let level = &l:foldlevel
  if a:0  " input direction
    silent! exe 'normal! ' . v:count1 . 'z' . a:1
  elseif v:count && v:count != level  " preserve level
    silent! exe 'normal! ' . abs(v:count - level) . (v:count > level ? 'zr' : 'zm')
  endif
  echom 'Fold level: ' . &l:foldlevel
endfunction
function! fold#update_folds(force, ...) abort
  " Initial stuff
  let markers = []  " manual markers
  let winview = winsaveview()
  let method0 = &l:foldmethod  " previous method
  let level0 = &l:foldlevel
  let closed0 = foldlevel('.') ? foldclosed('.') : 0
  let init = a:force || method0 =~# 'syntax\|expr'
  let queued = get(b:, 'fastfold_queued', 0)
  let remark = queued == 1 && method0 ==# 'manual'
  let refold = queued >= 1 && method0 =~# 'manual\|syntax\|expr'
  if init || refold || remark  " re-apply or convert
    for [line1, line2, _] in fold#get_markers()
      let iclose = foldclosed(line1) == line1
      call add(markers, [line1, line2, iclose])
    endfor
  endif
  " Optionally update folds
  if init || refold  " re-apply or convert
    if a:force
      call SimpylFold#Recache()
    endif
    exe 'FastFoldUpdate'
    let b:fastfold_queued = 0
  endif
  if &l:foldmethod ==# 'manual'  " i.e. not skipped
    for [line1, line2, iclose] in reverse(markers)
      exe line1 . ',' . line2 . 'fold'
      exe iclose ? '' : line1 . 'foldopen'
    endfor
    let b:fastfold_queued = 0
  endif
  " Optionally apply foldlevel
  let keys = winview.lnum . 'G'  " additional resets
  let reset = a:0 ? a:1 : -1  " fold level reset state
  let method1 = &l:foldmethod
  let level1 = &l:filetype ==# 'json' ? 2 : empty(get(b:, 'fugitive_type', '')) ? 0 : 1
  let level1 = !level1 && method1 ==# 'manual' ? search('{{{1\s*$', 'wn') > 0 : level1
  let level1 = !level1 && method1 ==# 'marker' ? search('{{{2\s*$', 'wn') > 0 : level1
  let closed1 = foldlevel(winview.lnum) ? foldclosed(winview.lnum) : 0
  if reset >= 0 || method0 !=# method1  " update fold level
    let &l:foldlevel = a:0 ? level1 : level0
    for lnum in fold#get_ignores() | exe lnum . 'foldopen' | endfor
    let reopen = closed0 < 0 && closed1 > 0 || closed0 == 0 && closed1 !=# winview.lnum
    let reclose = reset > 0 && closed0 > 0 && closed1 < 0
    let keys .= reopen || reset == 0 ? 'zv' : ''  " restore open
    let keys .= reclose || reopen && reset == 2 ? 'zc' : ''  " restore close
  endif
  exe 'keepjumps silent! normal! ' . keys
  call winrestview(winview)
endfunction

" Toggle inner folds within requested range
" NOTE: Necessary to temporarily open outer folds before toggling inner folds. No way
" to target them with :fold commands or distinguish adjacent children with same level
function! s:toggle_state(line1, line2, ...) abort range
  let level = a:0 ? a:1 : 0
  for lnum in range(a:line1, a:line2)
    let inum = foldclosed(lnum) | let ilevel = foldlevel(inum)
    if inum > 0 && (!level || level == ilevel) | return 1 | endif
  endfor
endfunction
function! s:toggle_show(toggle, count) abort
  exe a:toggle ? '' : 'normal! zzze'
  let head = a:toggle > 1 ? 'Toggled' : a:toggle ? 'Closed' : 'Opened'
  let msg = head . ' ' . a:count . ' fold' . (a:count > 1 ? 's' : '') . '.'
  let cmd = a:count > 0 ? 'echom ' . string(msg) : "echoerr 'E490: No folds found'"
  call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
endfunction
function! s:toggle_inner(line1, line2, level, ...)
  let [fold1, fold2] = [foldclosed(a:line1), foldclosedend(a:line2)]
  let [line1, line2] = [fold1 > 0 ? fold1 : a:line1, fold2 > 0 ? fold2 : a:line2]
  let [outer, inner] = s:fold_source(line1, line2, a:level)
  for [_, lnum] in outer | exe lnum . 'foldopen' | endfor
  let toggle = a:0 ? a:1 : 1 - s:toggle_state(a:line1, a:line2, a:level + 1)
  let [recurse, toggled] = [a:0 > 0 ? a:2 : 0, []]
  for [_, lnum] in toggle ? reverse(inner) : inner
    let inum = foldclosed(lnum) | let ilevel = foldlevel(inum > 0 ? inum : lnum)
    if ilevel == a:level + 1 || recurse && ilevel > a:level + 1
      if toggle && inum <= 0
        exe lnum . 'foldclose'
        call add(toggled, [foldclosed(lnum), foldclosedend(lnum), ilevel])
      elseif !toggle && inum > 0
        call add(toggled, [inum, foldclosedend(lnum), ilevel])
        exe lnum . 'foldopen'
      endif
    endif
  endfor
  for [_, lnum] in reverse(outer) | exe lnum . 'foldclose' | endfor
  return [toggle, toggled]
endfunction

" Open or close parent fold under cursor and its children
" NOTE: If called on already-toggled 'current' folds the explicit 'foldclose/foldopen'
" toggles the parent. So e.g. 'zCzC' first closes python methods then the class.
function! fold#toggle_parents(...) abort range
  let [lmin, lmax] = sort([a:firstline, a:lastline], 'n')
  call fold#update_folds(0)
  let counts = [0, 0]
  for [line1, line2, level] in fold#get_parents(lmin, lmax)
    if line2 <= line1 | continue | endif
    let toggle = a:0 ? a:1 : 1 - s:toggle_state(line1, line1)
    let line1 = max([lmin, line1])  " truncate range
    let line2 = min([lmax, line2])  " truncate range
    let args = [line1, line2, level, toggle, 1]
    let result = call('s:toggle_inner', args)
    exe line1 . (toggle ? 'foldclose' : 'foldopen')
    let counts[toggle] += 1 + len(result[1])
  endfor
  let toggle = counts[0] && counts[1] ? 2 : counts[1] ? 1 : 0
  call s:toggle_show(toggle, counts[0] + counts[1]) | return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_parents_expr(...) abort
  return utils#motion_func('fold#toggle_parents', a:000, 1)
endfunction

" Open or close current children under cursor
" NOTE: This is required because recursive :foldclose! also closes parent
" and :[range]foldclose does not close children. Have to go one-by-one.
function! fold#toggle_children(top, ...) abort range
  let [lmin, lmax] = sort([a:firstline, a:lastline], 'n')
  call fold#update_folds(0)
  let counts = [0, 0]
  let level = foldlevel('.')
  let folds = a:top ? fold#get_parents(lmin, lmax) : fold#get_folds(lmin, lmax, level)
  if !a:top  " inner-most inner folds
    let [fmin, fmax] = [min(map(copy(folds), 'v:val[0]')), max(map(copy(folds), 'v:val[1]'))]
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
  call s:toggle_show(toggle, counts[0] + counts[1]) | return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_children_expr(...) abort
  return utils#motion_func('fold#toggle_children', a:000, 1)
endfunction

" Open or close inner folds within range (i.e. maximum fold level)
" NOTE: This permits using e.g. 'zck' and 'zok' even when outside fold and without
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
  call s:toggle_show(toggle, len(folds)) | return ''
  if empty(folds)
    call feedkeys("\<Cmd>echoerr 'E490: No folds found'\<CR>", 'n')
  endif | return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_folds_expr(...) abort
  return utils#motion_func('fold#toggle_folds', a:000, 1)
endfunction
