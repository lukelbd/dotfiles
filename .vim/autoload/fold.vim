"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Handle fold text cache and cache indices
" WARNING: TextYankPost fold recache trigger fails for blackhole register
" NOTE: Caching important for syntax#get_concealed() and for python s:is_decorator()
" (also had issues with flag generation but should be quick if we avoid triggering
" gitgutter updates). Tried to index cache by line number, then adjust indices by
" detecting newlines in TextYankPost and newline additions/deletions on InsertCharPre,
" but too complex. Now index cache using fold count from top of file, adjust indices
" when line count changes, and rearrange cache entries when entire fold is deleted.
function! fold#_reindex(...) abort  " TextChanged,TextChangedI
  let cnt = get(b:, 'foldtext_count', line('$'))
  let b:foldtext_count = line('$')
  if !exists('b:foldtext_keys') || cnt != line('$')
    let b:foldtext_keys = {}  " fold text lines to cache keys
    for [line1, line2, level] in sort(fold#fold_source(), {i1, i2 -> i1[0] - i2[0]})
      let b:foldtext_keys[line1] = [len(b:foldtext_keys), line2 - line1 + 1]
    endfor
  endif
endfunction
function! fold#_recache(...) abort  " TextYankPost
  let [lnum, inum] = [line('.'), line('.')]
  let key = get(v:event, 'operator', '')
  let char = get(v:event, 'regtype', 'v')
  if key !~# '^[cd]$' || char !=? 'v' | return | endif
  let cnt = len(get(v:event, 'regcontents', '')) - (char ==# 'v')
  while inum < lnum + cnt
    if has_key(b:foldtext_keys, string(inum))
      let [ikey, icnt] = b:foldtext_keys[inum]
      let inum += icnt - 1 | if inum >= lnum + cnt | break | endif
      for ikey in range(ikey + 1, len(b:foldtext_keys))  " adjust cache indices
        if has_key(b:foldtext_cache, string(ikey))
          let b:foldtext_cache[ikey - 1] = b:foldtext_cache[ikey]  " adjust cache index
        elseif has_key(b:foldtext_cache, string(ikey - 1))
          call remove(b:foldtext_cache, ikey - 1)  " remove cache index
        endif
      endfor
      call remove(b:foldtext_keys, string(lnum))
    endif
    let inum += 1
  endwhile  " then await TextChanged which triggers reindex
endfunction

" Return bounds and level for any closed fold or open fold of requested level
" NOTE: No native way to get bounds if fold is open so use normal-mode motions, and no
" way to detect bounds within closed folds so return lower-level bounds if necessary.
" NOTE: Here [z never raises error but does update jumplist even though not documented
" in :help jump-motions. See: https://stackoverflow.com/a/4776436/4970632 
" NOTE: This helps supports following toggles: non-recursive (highest level in range),
" inner inner (folds within highest-level fold under cursor that has children), outer
" inner (folds within current 'main' parent fold), outer recursive (parent fold and
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

" Return fastfold-managed manual folds with marks
" WARNING: Critical to re-open folds after defining or subsequent fold definitions
" fail. Still want to initialize with closed folds though so do that afterwards.
" NOTE: Previously tried using regions with 'vim-syntaxMarkerFold' but causes major
" issues since either disables highlighting or messes up inner highlight items when
" trying to use e.g. contains=ALL since several use naked 'contained' property.
function! s:get_divider(...) abort
  let regex = '\(' . comment#get_regex(0) . '\)\?'
  let regex = '^' . regex . '\s*[-=]\{3,}' . regex . '\ze\%(\s\|$\)'
  return matchstr(getline(a:0 ? a:1 : '.'), regex)
endfunction
function! fold#get_markers() abort
  let [folds, naked, heads, nmark] = [[], {}, {}, 0]
  let [mark1, mark2] = split(&l:foldmarker, ',')
  let winview = winsaveview()
  let regex = '\(' . mark1 . '\|' . mark2 . '\)'  " open or close markers
  let regex = '\%(^\s*$\|\%(^\|\s\)\zs' . regex . '\(\d*\)\s*$\)'
  keepjumps goto | while v:true  " iterate over markers
    let flag = empty(nmark) ? 'cW' : 'W'
    let [lnum, cnum] = searchpos(regex, flag, "!tags#get_inside(0, 'Comment')")
    if lnum == 0 || cnum == 0 | break | endif
    let parts = matchlist(getline(lnum), regex, cnum - 1)
    if empty(parts) | break | endif
    let [imark, ilevel, nmark] = [parts[1], parts[2], nmark + 1]
    if imark =~# mark1  " open fold after closing previous and inner
      let level = empty(ilevel) ? max(keys(heads)) + 1 : str2nr(ilevel)
      let bool = !empty(s:get_divider(lnum - 1)) && !empty(s:get_divider(lnum + 1))
      let [lnum, inum] = bool ? [lnum + 1, lnum - 2] : [lnum, lnum - 1]
      for nr in range(level, 10)
        if has_key(heads, string(nr))
          call add(folds, [heads[nr], inum, nr])
          call remove(heads, nr) | call remove(naked, nr)
        endif
      endfor
      let heads[level] = lnum | let naked[level] = empty(ilevel)
    else  " close previously defined fold
      let level = empty(ilevel) ? max(keys(heads)) : str2nr(ilevel)
      let lnum -= empty(imark) && get(naked, level, 0)
      let bool = !empty(imark) || get(naked, level, 0)
      if bool && has_key(heads, string(level))
        call add(folds, [heads[level], lnum, level])
        call remove(heads, level) | call remove(naked, level)
      endif
    endif
  endwhile
  for level in keys(heads)
    call add(folds, [heads[level], line('$'), str2nr(level)])
  endfor
  call winrestview(winview)
  return sort(folds, {i1, i2 -> i1[2] - i2[2]})
endfunction

" Return ignored auto-opened folds matching given regex
" NOTE: This provides 'pseudo-levels' that auto-open when level is at or above
" the first regex and when that regex is not preceded by the second regex. Useful
" e.g. for python classes or tex environments occupying entire document and to
" enforce universal standard default of foldlevel=0 without hiding everything.
" Return fold under cursor above a given level
scriptencoding utf-8  " {{{
let s:fold_matches = [
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
  elseif empty(fold#get_matches(result[0]))  " does not match regex
    return result
  endif
  let other = fold#get_fold(level + 1)
  return empty(other) ? result : other
endfunction
function! fold#get_matches(...) abort range
  let [line1, line2] = a:0 > 1 ? a:000 : a:0 ? [a:1, a:1] : [1, line('$')]
  let ignores = []
  for [ftype, regex1, regex2, level] in s:fold_matches
    if ftype !=# &l:filetype
      continue  " ignore non-matching filetypes
    endif
    if &l:diff || &l:foldmethod !~# 'manual\|syntax\|expr'
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

" Return folds and properties across line range
" NOTE: This ignores 'inner' folds within closed folds (see also fold#fold_source)
" NOTE: This ignores folds defined in s:fold_matches, e.g. python classes and
" tex documents. Used to close-open smaller fold blocks ignoring huge blocks.
function! s:get_range(func, ...) abort
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
  return call('s:get_range', ['fold#get_fold'] + a:000)
endfunction
function! fold#get_parents(...) abort
  return call('s:get_range', ['fold#get_parent'] + a:000)
endfunction

" Return default fold label
" NOTE: Python and tex fold text functions both start from fold#fold_label().
" NOTE: This filters trailing comments, removes git-diff chunk text following stats,
" adds next line if the text is a single open delimiter (e.g. json), and replaces
" syntax conceal characters (tex#fold_text() handles backslash matchadd() conceal).
function! s:format_delims(label, ...) abort
  let pairs = {'[': ']', '(': ')', '{': '}', '<': '>'}
  let items = call('matchlist', [a:label, '\([[({<]*\)\s*$'] + a:000)
  let delim1 = split(get(items, 1, ''), '\zs', 0)  " discard empty strings
  let delim2 = map(copy(delim1), {idx, val -> get(pairs, val, '')})
  let append = &l:filetype ==# 'python' && get(delim2, -1, '') ==# ')'
  call add(delim2, append && a:label =~# '^\s*\(def\|class\)\>' ? ':' : '')
  return [join(delim1, ''), join(delim2, '')]
endfunction
function! s:format_inner(label, line) abort
  let regex = '\s*\([[({<]*\)\s*$'
  let label1 = substitute(a:label, '^\s*', '', '')
  let [delim1, outer] = s:format_delims(label1)
  if label1 !=# delim1 | return '' | endif  " not naked delimiter
  let label2 = fold#fold_label(a:line, 1)
  let [delim2, _] = s:format_delims(label2)
  if label2 ==# delim2 | return '' | endif  " no additional info
  let inner = substitute(label2, regex, '', 'g')
  return ' ' . inner . ' ··· ' . outer  " e.g. json folds
endfunction
function! fold#fold_label(line, ...) abort
  let fugitive = !empty(get(b:, 'fugitive_type', '')) || &l:filetype =~# '^git$\|^diff$'
  let marker = split(&l:foldmarker, ',')[0] . '\d*\s*$'
  let delta = '^\(@@.\{-}@@\).*$'  " git hunk difference
  let regex = '\(\S\@<=\s\+' . comment#get_regex(0) . '.*\)\?\s*$'
  let [label, cols] = [getline(a:line), syntax#_matches(a:line)]
  let label = substitute(label, marker, '', '')  " trailing markers
  let label = substitute(label, regex, '', 'g')  " trailing comments
  let label = fugitive ? substitute(label, delta, '\1', '') : label
  let [idxs, chars] = [range(strchars(label)), split(label, '\zs')]
  let items = map(copy(idxs), 'syntax#get_concealed(a:line, v:val + 1, cols, ''n'')')
  let chars = map(copy(idxs), 'type(items[v:val]) ? items[v:val] : items[v:val] ? '''' : chars[v:val]')
  let label = join(chars, '')  " unconcealed characters
  let label = a:0 && a:1 ? substitute(label, '^\s*', '', 'g') : label
  let extra = fugitive || a:0 && a:1 ? '' : s:format_inner(label, a:line + 1)
  return label . extra
endfunction

" Generate fold text label
" NOTE: Since gitgutter signs are not shown over closed folds include summary of
" changes in fold text. See https://github.com/airblade/vim-gitgutter/issues/655
function! s:fold_text(line1, line2, level)
  let lines = string(a:line2 - a:line1 + 1)  " number of lines
  let header = s:get_divider(a:line1)  " fold divider
  let maxlen = get(g:, 'linelength', 88)  " default maximum
  let delta = len(string(line('$'))) - len(lines)
  let flags = edit#_get_errors(a:line1, a:line2)  " quickfix items
  let flags .= git#_get_hunks(a:line1, a:line2, 1)  " gitgutter hunks
  let flags = empty(flags) ? flags : '{' . flags . '} '  " counts
  if exists('*' . &l:filetype . '#fold_text')
    let [name, args] = [&l:filetype . '#fold_text', [a:line1, a:line2]]
  else  " default fold text
    let [name, args] = ['fold#fold_label', [a:line1]]
  endif
  if &l:diff  " fill with maximum width
    let stats = ' -+'
    let label = '+- ' . lines . ' identical '
    let width = maxlen - strchars(stats) - 1
    let space = repeat('·', width - strchars(label))
    return [label, space, stats]
  elseif !empty(header)  " fold is on header divider
    let indent = matchstr(header, '^\s*[^-=]\?')
    let indent .= empty(trim(indent)) ? '' : ' '
    let flags .= lines . ' lines '
    let index = strchars(header . indent . flags) - (maxlen - 1)
    let header = strcharpart(header, max([index, 0]))
    let label = indent . flags . header
    return [label, ' ', '']
  endif
  let [stats, space] = ['(' . lines . ') [' . a:level . ']', ' ']
  let label = call(name, args)
  let [delim1, delim2] = s:format_delims(label)
  let indent = matchstr(label, '^\s*')
  let width = maxlen - strchars(stats) - 1
  let label .= empty(delim2) ? '' : '···' . delim2
  let label = indent . flags . strcharpart(label, strchars(indent))
  if strchars(label) >= width  " truncate fold text
    let delta = max([strwidth(delim2) - 1, 0])
    let ichar = strcharpart(label, width - delta - 4, 1)
    let delim = ichar ==# delim1 ? delim2 : ''
    let label = strcharpart(label, 0, width - delta - 5)
    let label = substitute(label, '\s*$', '', '')
    let label .= empty(delim) ? ' ' : ''
    let label .= '···' . delim
  endif
  let space = repeat(space, width - strchars(label))
  return [label, space, stats]
endfunction

" Generate cached and truncated fold text
" NOTE: Here cache fold text with a cache index of the fold count from the top of the
" file. The cache index is updated when the line count has changed, detected whenever
" fold text called and on TextChanged,TextChangedI. See fold#_reindex()
function! fold#fold_text(...) abort
  call fold#_reindex()  " update line number -> cache key mapping
  let winview = winsaveview()  " translate byte column index to character index
  if !exists('b:foldtext_cache')
    let b:foldtext_cache = {}  " create fold text cache mapping
  endif
  if a:0 && a:1  " debugging mode
    exe winview.lnum | let [line1, line2, level] = fold#get_fold()
    call winrestview(winview)
  else  " internal mode
    let [line1, line2] = [v:foldstart, v:foldend]
    let level = len(v:folddashes)
  endif
  let key = get(b:foldtext_keys, string(line1), [line1])[0]
  let label = get(b:foldtext_cache, string(key), '')
  if empty(label) || !type(label)
    let [label, space, lines] = s:fold_text(line1, line2, level)
    let label = label . space . lines
    let b:foldtext_cache[key] = label
  endif
  let leftidx = charidx(getline(winview.lnum), winview.leftcol)
  return strcharpart(label, leftidx)
endfunction

" Helper functions for fzf folds and caching operations
" NOTE: Here fold#fold_source() generates list of all folds using fold#get_fold()
" algorithm on open folds and temporarily opening closed folds where necessary.
function! s:fold_counts(fold) abort
  let flags = ['!', '\*', '\^', '+', '\~', '-']
  let regex = join(map(flags, '''\%('' . v:val . ''\(\d\+\)\)\?'''), '')
  let nrs = map(matchlist(a:fold, '^\s*{' . regex . '}')[1:6], 'str2nr(v:val)')
  return empty(nrs) ? [0, 0] : [nrs[0] + nrs[1] + nrs[2], nrs[3] + nrs[4] + nrs[5]]
endfunction
function! s:fold_sink(fold) abort
  if empty(a:fold) | return | endif
  let [path, lnum; rest] = split(a:fold, ':')
  exe 'normal! m''' | call cursor(lnum, 0)
  exe 'normal! zvzzze'
endfunction
function! fold#fold_source(...) abort
  let [lmin, lmax, level] = a:0 ? a:000 : [1, line('$'), 1]
  let [folds, closed] = [[], []]
  for [line1, line2, level] in fold#get_folds(lmin, lmax, level)
    call add(folds, [line1, line2, level])
    if foldclosed(line1) > 0  " temporarily open folds
      call add(closed, line1) | exe line1 . 'foldopen'
    endif
    call extend(folds, fold#fold_source(line1, line2, level + 1))
  endfor
  for lnum in reverse(closed) | exe lnum . 'foldclose' | endfor
  return folds
endfunction

" Select buffer folds rendered with foldtext()
" NOTE: Comment scenario is to place markers on first line of code below comment
" blocks, so search for head of comment blocks if possible (more informative).
" NOTE: This was adapted from fzf-folds plugin. This includes folds inside closed
" parent folds and uses custom fold-text function instead of foldtextresult().
" See: https://github.com/roosta/fzf-folds.vim
function! fold#fzf_folds(...) abort
  let bang = a:0 ? a:1 : 0  " fullscreen
  let folds = fold#fold_source()
  let cache = get(b:, 'foldtext_cache', {})
  let mark0 = split(&l:foldmarker, ',')[0]
  let regex0 = '\%(^\|\s\)\zs' . mark0 . '\(\d*\)\s*$'
  let regex1 = '^' . comment#get_regex(0)
  let maxlen = max(map(copy(folds), 'len(string(abs(v:val[1] - v:val[0])))'))
  let [labels0, labels1] = [[], []]
  for [line1, line2, level] in folds
    let [iline, jline, itext] = [line1, line2, getline(line1)]
    if itext =~# regex0 && itext !~# regex1 && getline(iline - 1) =~# regex1
      let [_, pos1, pos2] = comment#object_comment_a(iline - 1)
      if pos2[1] > pos1[1] || pos2[2] == pos1[2] && pos2[2] > pos1[2]
        let iline = pos1[1]  " show comment header
      endif
    endif
    let [label, _, stats] = s:fold_text(iline, jline, level)
    let [icount, jcount] = s:fold_counts(label)
    let stats = substitute(stats, '[^0-9 ]', '', 'g')
    let [lines, level] = map(split(stats), 'str2nr(v:val)')
    let space = repeat(' ', maxlen - strchars(lines) + 1)
    let stats = '[' . level . ']' . ' ' . '(' . lines . ')'
    let label = substitute(label, '\(^\s*\|\s*$\)', '', 'g')
    let label = bufname() . ':' . line1 . ':' . stats . ' ' . label
    if icount || jcount  " ale.vim locations
      call add(labels1, [label, icount, jcount])
    else  " standard label
      call add(labels0, [label, level, lines])
    endif
  endfor
  call sort(labels1, {i1, i2 -> i1[1] == i2[1] ? i2[2] - i1[2] : i2[1] - i1[1]})
  call sort(labels0, {i1, i2 -> i1[1] == i2[1] ? i2[2] - i1[2] : i1[1] - i2[1]})
  let labels = map(labels1, 'v:val[0]') + map(labels0, 'v:val[0]')
  let opts = fzf#vim#with_preview({'placeholder': '{1}:{2}'})
  let opts = join(map(get(opts, 'options', []), 'fzf#shellescape(v:val)'), ' ')
  let opts .= ' -d : --with-nth 3.. --preview-window +{2}-/2'
  let opts .= ' --layout=reverse-list --tiebreak=chunk,index'
  if empty(label) | return | endif
  let options = {
    \ 'source': labels,
    \ 'sink': function('s:fold_sink'),
    \ 'options': opts . " --prompt='Fold> '",
  \ }
  return fzf#run(fzf#wrap('folds', options, bang))
endfunction

" Fold text objects (compare with hunk.vim)
" NOTE: Here, similar to how 'vaw' on last word on line includes preceding spaces
" and elsewhere includes following spaces, have 'vaz' include space below folds of
" same level if available or the space above if not available.
function! fold#object_fold_i() abort
  return s:object_fold(0, 0)
endfunction
function! fold#object_fold_a() abort
  return s:object_fold(1, 0)
endfunction
function! fold#object_parent_i() abort
  return s:object_fold(0, 1)
endfunction
function! fold#object_parent_a() abort
  return s:object_fold(1, 1)
endfunction
function! s:object_fold(outer, ...) abort
  let result = a:0 && a:1 ? fold#get_parent() : fold#get_fold()
  let result = empty(result) ? [line('.'), line('.'), 0] : result
  let [line1, line2, level] = result
  if !level || line2 <= line1
    let msg = 'E490: No fold found'
    redraw | echohl ErrorMsg | echom msg | echohl None
    return ['v', getpos('.'), getpos('.')]
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

" Update buffer-local fold level
" NOTE: Here use zm/zr instead of :set foldlevel in order to truncate at maximum level
" NOTE: Update method is triggered by a FileType autocommand that runs before FastFold
function! fold#update_level(...) abort
  let cnt = v:count
  let key = a:0 ? a:1 : ''
  let keys = ''
  let level = &l:foldlevel
  let ilevel = foldlevel('.')
  call fold#update_folds(0)
  if key ==? 'r' && ilevel > level
    let level = ilevel - 1
  elseif key ==? 'm' && ilevel < level
    let level = ilevel
  endif
  if !empty(key)  " input direction
    let keys = (cnt ? cnt : '') . 'z' . a:1
  elseif cnt && cnt != level  " preserve level
    let keys = abs(cnt - level) . (cnt > level ? 'zr' : 'zm')
  endif
  if !empty(keys)
    let &l:foldlevel = level
    silent! exe 'normal! ' . keys
  endif
  echom 'Fold level: ' . &l:foldlevel
endfunction

" Update buffer-local fold method
" WARNING: Sometimes run into issue where opening new files or reading updates
" permanently disables 'expr' folds. Account for this by re-applying fold method.
" NOTE: Critical to insert the FileType autocommand that calls this before
" FastFold VimEnter, so FastFold converts folds from the correct fold method.
function! fold#update_method(...) abort
  let [type, imethod] = [&l:filetype, get(w:, 'lastfdm', 'manual')]
  let [expr0, method0] = [&l:foldexpr, &l:foldmethod]
  let [expr1, method1] = ['', 'syntax']
  if &l:diff  " difference mode enabled
    silent! diffupdate | let method1 = 'diff'
  elseif method0 ==# 'indent'  " preserve indent method0
    let method1 = method0
  elseif type =~# '^text$\|^taglist$\|^r\?csv\(_\w\+\)\?$'  " initialize 'manual'
    let method1 = 'manual'
  elseif type ==# 'markdown'  " preservim/vim-markdown
    silent! doautocmd Mkd CursorHold | let expr1 = 'Foldexpr_markdown(v:lnum)'
  elseif type ==# 'python'  " autoload/python.vim
    let expr1 = 'python#fold_expr(v:lnum)'
  elseif type ==# 'yaml'  " plugged/pedrohdz/vim-yaml-folds
    let expr1 = 'YamlFolds()'
  elseif type ==# 'rst'  " vim91/autoload/RstFold.vim
    let expr1 = 'RstFold#GetRstFold()'
  endif
  let recache = imethod ==# 'manual' || method1 !=# imethod
  let method1 = empty(expr1) ? method1 : 'expr'
  if !empty(expr1) && expr0 !=# expr1
    call SimpylFold#Recache()
    let &l:foldmethod = 'expr' | let &l:foldexpr = expr1
  elseif method0 ==# 'manual' && recache
  \ || method0 !=# 'manual' && method1 !=# method0
  \ || method0 !=# 'manual' && method1 ==# 'manual'
    let &l:foldmethod = method1
  endif | let &l:foldtext = 'fold#fold_text()'
endfunction

" Update the fold definitions and open-close status
" WARNING: Regenerating b:SimPylFold_cache with manual SimpylFold#FoldExpr() call
" can produce strange internal bug. Instead rely on FastFoldUpdate to fill the cache.
" NOTE: Here simulate 'zx' by passing 1 and 'zX' by passing 2, except consistent with
" 'zC' maps this increases the depth of closed folds under cursor by one at a time
function! fold#update_folds(force, ...) abort
  " Initial stuff
  let markers = []  " manual markers
  let winview = winsaveview()
  let closed0 = foldlevel('.') ? foldclosed('.') : 0  " zero if no folds
  let level0 = foldlevel(closed0 > 0 ? closed0 : '.')  " fold close level
  let method0 = &l:foldmethod  " previous method
  let force = a:force || method0 =~# 'syntax\|expr'
  let queued = get(b:, 'fastfold_queued', -1)  " add markers after fastfold
  let remark = queued < 0 && method0 ==# 'manual'
  let refold = queued > 0 && method0 =~# 'manual\|syntax\|expr'
  let info = get(getwininfo(win_getid()), 0, {})
  let ignore = !&l:foldenable || empty(&l:filetype) || bufname() =~# '^!'
  let nofold = !empty(win_gettype()) || get(info, 'terminal', 0) || get(info, 'quickfix', 0)
  if ignore || nofold | return | endif  " see: https://stackoverflow.com/a/68004054/4970632
  " Optionally update folds
  if force || refold || remark  " re-apply or convert
    for [line1, line2, _] in fold#get_markers()
      let closed = remark || foldclosed(line1) == line1
      call add(markers, [line1, line2, closed])
    endfor
  endif
  if force || refold  " re-apply or convert
    unlet! b:foldtext_cache
    unlet! b:foldtext_keys
    if a:force
      call SimpylFold#Recache()
    endif
    exe 'FastFoldUpdate'
    let b:fastfold_queued = 0
  endif
  if &l:foldmethod ==# 'manual'  " i.e. not skipped
    for [line1, line2, closed] in reverse(markers)
      let level = foldlevel(line1)  " possibly zero
      let lines = range(line1, line2)
      let index = index(map(copy(lines), 'foldlevel(v:val)'), level - 1)
      let line2 = index > 0 ? lines[index - 1] : line2  " possibly truncate
      exe line1 . ',' . line2 . 'fold'
      exe closed ? '' : line1 . 'foldopen'
    endfor
    let b:fastfold_queued = 0
  endif
  " Optionally apply foldlevel
  let level1 = &l:foldlevel
  let closed1 = level0 ? foldclosed(winview.lnum) : 0
  let method1 = &l:foldmethod
  let keys = ''  " normal mode keys
  let reset = a:0 ? a:1 : -1  " reset state
  let level1 = &l:filetype ==# 'json' ? 2 : !empty(get(b:, 'fugitive_type', '')) ? 1 : 0
  let level1 = !level1 && method1 ==# 'manual' ? search('{{{1\s*$', 'wn') > 0 : level1
  let level1 = !level1 && method1 ==# 'marker' ? search('{{{2\s*$', 'wn') > 0 : level1
  if reset >= 0 || method0 !=# method1
    let &l:foldlevel = level1  " update fold level
    for lnum in fold#get_matches() | exe lnum . 'foldopen' | endfor
    let initial = reset > 2 || method0 !=# method1
    let refresh = closed0 == 0 && closed1 !=# winview.lnum
    let reveal = initial || refresh || level0 - level1 > 2
    let status = closed0 < 0 && closed1 > 0 ? -1 : closed0 > 0 && closed1 < 0 ? 1 : 0
    let closes = repeat('zc', foldlevel(winview.lnum) - level0)
    let closes .= closed0 < 0 || refresh ? 'zc' : 'zczc'
    let keys = reset == 0 || reveal ? 'zv' : reset == 1 && status > 0 ? 'zv' : ''
    let keys .= reset == 2 && reveal ? closes : reset == 1 && status < 0 ? 'zc' : ''
  endif
  exe winview.lnum | exe empty(keys) ? '' : 'silent! normal! ' . keys
  call winrestview(winview)
endfunction

" Jump to the previous or next fold
" NOTE: Native fold jumping commands zk/zj jump to the previous fold bottom and next
" fold top (respectively). Here instead always jump between fold tops, and optionally
" only for folds matching the current fold level instead of inner folds.
function! s:prev_fold() abort
  let lnum = foldclosed('.')
  exe lnum > 0 ? lnum : ''
  let winview = winsaveview()
  exe 'keepjumps normal! zk'
  let lnum = foldclosed('.')
  let lnum = lnum > 0 ? lnum : line('.')
  call winrestview(winview)
  exe 'keepjumps normal! [z'
  if lnum == winview.lnum
    return 0  " no preceding folds
  elseif line('.') > lnum && line('.') != winview.lnum
    return 0  " no nested folds
  elseif foldclosed(lnum) > 0
    exe lnum | return 0
  endif
  call winrestview(winview)
  exe 'keepjumps normal! zk'
  return s:prev_fold()
endfunction
function! fold#next_fold(count, ...) abort
  let major = a:0 ? a:1 : 0
  let cmd = a:count < 0 ? 'call s:prev_fold()' : 'keepjumps normal! zj'
  call fold#update_folds(0)
  for _ in range(abs(a:count))
    let lnum = line('.') | exe cmd | let inum = line('.')
    let level = foldlevel('.')
    while a:0 && a:1 ? inum != lnum && level > &l:foldlevel + 1 : 0
      let lnum = line('.') | exe cmd | let inum = line('.')
      let level = foldlevel('.')
    endwhile
  endfor
  let ifold = fold#get_fold()
  if lnum == line('.') || empty(ifold)
    let level = max(map(range(1, line('$')), 'foldlevel(v:val)'))
    let msg = 'Warning: ' . (level ? 'No more folds' : 'Folds not available')
    redraw | echohl WarningMsg | echom msg | echohl None | return
  else
    let range = ifold[0] . '-' . ifold[1]
    let info = '(level ' . ifold[2] . ')'
    redraw | echo 'Fold: ' . range . '  ' . info
  endif
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
function! s:toggle_message(toggle, nr) abort
  let msg = a:toggle > 1 ? 'Toggled' : a:toggle ? 'Closed' : 'Opened'
  if a:nr > 0
    let [cmd, msg] = ['echo', msg . ' ' . a:nr . ' fold' . (a:nr > 1 ? 's' : '')]
  else
    let [cmd, msg] = ['echoerr', 'E490: No folds found']
  endif
  let keys = a:nr && !a:toggle ? 'zzze' : ''
  let feed = "\<Cmd>redraw\<CR>\<Cmd>" . cmd . ' ' . string(msg) . "\<CR>"
  call feedkeys(keys . feed, 'n')
endfunction
function! s:toggle_inner(line1, line2, level, ...)
  let [closed, hidden] = [[], []]
  let [lmin, lmax] = [foldclosed(a:line1), foldclosedend(a:line2)]
  let [lmin, lmax] = [lmin > 0 ? lmin : a:line1, lmax > 0 ? lmax : a:line2]
  for lnum in range(lmin, lmax)
    let ilevel = foldlevel(lnum)
    if !ilevel | continue | endif
    let inum = foldclosed(lnum)
    if ilevel > a:level
      call add(hidden, [ilevel, lnum])
    elseif inum == lnum || lnum == lmin && inum > 0
      call add(closed, inum)
    endif
  endfor
  for lnum in closed | exe lnum . 'foldopen' | endfor
  let toggle = a:0 ? a:1 : 1 - s:toggle_state(a:line1, a:line2, a:level + 1)
  let [recurse, folds] = [a:0 > 0 ? a:2 : 0, []]
  for [_, lnum] in toggle ? reverse(sort(hidden)) : sort(hidden)
    let inum = foldclosed(lnum) | let ilevel = foldlevel(inum > 0 ? inum : lnum)
    if ilevel == a:level + 1 || recurse && ilevel > a:level + 1
      if toggle && inum <= 0
        exe lnum . 'foldclose'
        call add(folds, [foldclosed(lnum), foldclosedend(lnum), ilevel])
      elseif !toggle && inum > 0
        call add(folds, [inum, foldclosedend(lnum), ilevel])
        exe lnum . 'foldopen'
      endif
    endif
  endfor
  for lnum in reverse(closed) | exe lnum . 'foldclose' | endfor
  return [toggle, folds]
endfunction

" Open or close current children under cursor
" NOTE: This is required because recursive :foldclose! also closes parent
" and :[range]foldclose does not close children. Have to go one-by-one.
function! fold#_toggle_children(line1, line2, ...) abort range
  let counts = [0, 0]
  call fold#update_folds(0)
  if a:0 && a:1  " immediate children of top-level folds
    let folds = fold#get_parents(a:line1, a:line2)
  else  " inner-most children of current folds
    let level = foldlevel('.')
    let folds = fold#get_folds(a:line1, a:line2, level)
    let [lmin, lmax] = [min(map(copy(folds), 'v:val[0]')), max(map(copy(folds), 'v:val[1]'))]
    let [lmin, lmax] = lmin && lmax ? [lmin, lmax] : [a:line1, a:line2]
    let levels = map(range(lmin, lmax), 'foldlevel(v:val)')
    let folds = min(levels) == max(levels) ? fold#get_folds(a:line1, a:line2, level - 1) : folds
  endif
  for [line1, line2, level] in folds
    if line2 <= line1 | continue | endif
    let [toggle, folds] = call('s:toggle_inner', [line1, line2, level] + a:000[1:])
    let counts[toggle] += len(folds)  " if zero then continue
  endfor
  let toggle = counts[0] && counts[1] ? 2 : counts[1] ? 1 : 0
  call s:toggle_message(toggle, counts[0] + counts[1])
endfunction
" For optional range arguments
function! fold#toggle_children(...) range abort
  return call('fold#_toggle_children', [a:firstline, a:lastline] + a:000)
endfunction
" For <expr> map accepting motion
function! fold#toggle_children_expr(...) abort
  return utils#motion_func('fold#toggle_children', a:000, 1)
endfunction

" Open or close parent fold under cursor and its children
" NOTE: If called on already-toggled 'current' folds the explicit 'foldclose/foldopen'
" toggles the parent. So e.g. 'zCzC' first closes python methods then the class.
function! fold#_toggle_parents(line1, line2, ...) abort
  let counts = [0, 0]
  let winview = winsaveview()
  call fold#update_folds(0)
  for [line1, line2, level] in fold#get_parents(a:line1, a:line2)
    if line2 <= line1 | continue | endif
    let toggle = a:0 ? a:1 : 1 - s:toggle_state(line1, line1)
    let line1 = max([a:line1, line1])  " truncate range
    let line2 = min([a:line2, line2])  " truncate range
    let [_, folds] = call('s:toggle_inner', [line1, line2, level, toggle, 1])
    let counts[toggle] += 1 + len(folds)
    exe line1 . (toggle ? 'foldclose' : 'foldopen')
  endfor
  call winrestview(winview)
  let cnt = a:0 > 1 ? a:2 : v:count1
  if cnt > 1
    let cnts = fold#_toggle_parents(a:line1, a:line2, toggle, cnt - 1)
    let counts[0] += cnts[0] | let counts[1] += cnts[1]
  endif
  let toggle = counts[0] && counts[1] ? 2 : counts[1] ? 1 : 0
  call s:toggle_message(toggle, counts[0] + counts[1])
endfunction
" For optional range arguments
function! fold#toggle_parents(...) range abort
  return call('fold#_toggle_parents', [a:firstline, a:lastline] + a:000)
endfunction
" For <expr> map accepting motion
function! fold#toggle_parents_expr(...) abort
  return utils#motion_func('fold#toggle_parents', a:000, 1)
endfunction

" Open or close inner folds within range (i.e. maximum fold level)
" WARNING: Critical to get state before updating in case fold under cursor auto-closes
" NOTE: This permits using e.g. 'zck' and 'zok' even when outside fold and without
" fear of accideif ntally closing huge block e.g. class or document under cursor.
function! fold#_toggle_folds(line1, line2, ...) abort
  let winview = winsaveview()
  let state = s:toggle_state(a:line1, a:line2)
  call fold#update_folds(0)
  let levels = map(range(a:line1, a:line2), 'foldlevel(v:val)')
  let folds = fold#get_folds(a:line1, a:line2, max(levels))
  let toggle = a:0 > 0 && a:1 >= 0 ? a:1 : 1 - state
  let cnt = a:0 > 1 ? a:2 : v:count1
  for [line1, line2; rest] in folds
    let line1 = max([line1, a:line1])  " possibly select
    let line2 = min([line2, a:line2])
    exe line1 . ',' . line2 . (toggle ? 'foldclose' : 'foldopen')
  endfor
  call winrestview(winview)
  let cnt = a:0 > 1 ? a:2 : v:count1
  let nr = len(folds)
  if cnt > 1
    let nr += fold#_toggle_folds(a:line1, a:line2, toggle, cnt - 1)
  endif
  call s:toggle_message(toggle, nr)
  return nr
endfunction
" For optional range arguments
function! fold#toggle_folds(...) range abort
  return call('fold#_toggle_folds', [a:firstline, a:lastline] + a:000)
endfunction
" For <expr> map accepting motion
function! fold#toggle_folds_expr(...) abort
  return utils#motion_func('fold#toggle_folds', a:000, 1)
endfunction
