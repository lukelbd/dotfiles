"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
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
function! s:has_divider(...) abort
  let regex = '\(' . comment#get_regex(0) . '\)\?'
  let regex = '^' . regex . '\s*[-=]\{3,}' . regex . '\(\s\|$\)'
  return getline(a:0 ? a:1 : '.') =~# regex
endfunction
function! fold#get_markers() abort
  let winview = winsaveview()
  let [mark1, mark2] = split(&l:foldmarker, ',')
  let [head, tail] = ['\%(^\|\s\)\zs', '\(\d*\)\s*$']
  let regex = '\(' . mark1 . '\|' . mark2 . '\)'  " open or close markers
  let regex = '\%(^\s*$\|' . head . regex . tail . '\)'  " empty line or markers
  let [folds, naked, heads] = [[], {}, {}]  " fold opening lines
  keepjumps goto | while v:true
    let flags = line('.') == 1 && col('.') == 1 ? 'cW' : 'W'
    let [lnum, cnum] = searchpos(regex, flags, "!tags#get_inside(0, 'Comment')")
    if lnum == 0 || cnum == 0 | break | endif
    let parts = matchlist(getline(lnum), regex, cnum - 1)
    if empty(parts)
      let msg = 'Warning: Failed to setup mark folds'
      redraw | echohl WarningMsg | echom msg | echohl None | break
    endif
    let [imark, ilevel] = parts[1:2]
    if imark =~# mark1  " open fold after closing previous and inner
      let level = empty(ilevel) ? max(keys(heads)) + 1 : str2nr(ilevel)
      let bool = s:has_divider(lnum - 1) && s:has_divider(lnum + 1)
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
  let label = getline(a:line)
  let label = substitute(label, marker, '', '')  " trailing markers
  let label = substitute(label, regex, '', 'g')  " trailing comments
  let label = fugitive ? substitute(label, delta, '\1', '') : label
  let chars = split(label, '\zs')  " remaining characters
  let items = map(range(len(chars)), 'syntax#_concealed(a:line, v:val + 1, ''n'')')
  let chars = map(range(len(chars)), 'type(items[v:val]) ? items[v:val] : chars[v:val]')
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
    let [stats, space] = [' -+', '·']
    let label = '+- ' . lines . ' identical '
  elseif s:has_divider(a:line1)  " header divider
    let [label, space] = [call(name, args), ' ']
    let [stats, flags] = [flags, '']
  else  " global default label
    let [label, space] = [call(name, args), ' ']
    let stats = '(' . lines . ') [' . a:level . ']'
  endif
  let [delim1, delim2] = s:format_delims(label)
  let indent = matchstr(label, '^\s*')
  let label = empty(delim2) ? label : label . '···' . delim2
  let label = strcharpart(label, strchars(indent))
  let label = indent . flags . label
  let width = maxlen - strchars(stats) - 1
  if strchars(label) >= width  " truncate fold text
    let delta = max([strwidth(delim2) - 1, 0])
    let ichar = strcharpart(label, width - delta - 4, 1)
    let delim = ichar ==# delim1 ? delim2 : ''
    let label = strcharpart(label, 0, width - delta - 5)
    let label = substitute(label, '\s*$', '', '')
    let label = empty(delim) ? label . ' ···' : label . '···' . delim
  endif
  let space = repeat(space, width - strchars(label))
  return [label, space, stats]
endfunction

" Generate cached and truncated fold text
" NOTE: Have to call this manually if insert keys are mapped. See edit#insert_delims 
" WARNING: Caching important for syntax#_concealed() and for python s:is_decorator()
" (also had issues with flag generation but should be quick if we avoid triggering
" gitgutter updates). Update cache indices on InsertCharPre when v:char ==# '\r' and
" on TextYankPost using v:event.operator and v:event.regtype
" but too complex, instead and TextChanged is not quite as common as TextChangedI.
function! fold#_recache(...) abort
  let queued = get(b:, 'foldtext_queued', 1)
  unlet! b:foldtext_queued
  if a:0 ? a:1 : queued  " trigger foldtext() generation
    unlet! b:foldtext_cache
    unlet! b:foldtext_delta
  endif
endfunction
function! fold#_recache_insert(...) abort  " from InsertCharPre
  let col1 = col('.') == 1 && line('.') > 1
  let col2 = col('.') == col('$') && line('.') < line('$')
  let char = a:0 ? a:1 : v:char  " see edit#insert_delims()
  let bool = char ==# "\<CR>" || col1 && char ==# "\<BS>" || col2 && char ==# "\<Delete>"
  call fold#_recache(bool)
endfunction
function! fold#_recache_normal(...) abort  " from TextYankPost
  let key = get(v:event, 'operator', '')
  if key !~# '^[cd]$' | return | endif
  let char = get(v:event, 'regtype', 'v')
  let text = getreg(get(v:event, 'regname', ''))
  let bool = char ==# 'V' || text =~# "\n"
  let b:foldtext_queued = bool  " then await TextChanged
endfunction
function! fold#fold_text(...) abort
  let winview = winsaveview()  " translate byte column index to character index
  if !exists('b:foldtext_cache')
    let b:foldtext_cache = {}
  endif
  if a:0 && a:1  " debugging mode
    exe winview.lnum | let [line1, line2, level] = fold#get_fold()
    call winrestview(winview)
  else  " internal mode
    let [line1, line2] = [v:foldstart, v:foldend]
    let level = len(v:folddashes)
  endif
  let index = string(line1)
  let label = get(b:foldtext_cache, index, '')
  if empty(label) || !type(label)
    let [label, space, lines] = s:fold_text(line1, line2, level)
    let label = label . space . lines
    let b:foldtext_cache[index] = label
  endif
  let leftidx = charidx(getline(winview.lnum), winview.leftcol)
  return strcharpart(label, leftidx)
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
function! s:fold_sink(fold) abort
  if empty(a:fold) | return | endif
  let [path, lnum; rest] = split(a:fold, ':')
  exe 'normal! m''' | call cursor(lnum, 0)
  exe 'normal! zvzzze'
endfunction
function! s:fold_counts(fold) abort
  let flags = ['!', '\*', '\^', '+', '\~', '-']
  let regex = join(map(flags, '''\%('' . v:val . ''\(\d\+\)\)\?'''), '')
  let nrs = map(matchlist(a:fold, '^\s*{' . regex . '}')[1:6], 'str2nr(v:val)')
  return empty(nrs) ? [0, 0] : [nrs[0] + nrs[1] + nrs[2], nrs[3] + nrs[4] + nrs[5]]
endfunction
function! fold#fzf_folds(...) abort
  let bang = a:0 ? a:1 : 0  " fullscreen
  let folds = fold#fold_source()
  let maxlen = max(map(copy(folds), 'len(string(abs(v:val[1] - v:val[0])))'))
  let [labels0, labels1] = [[], []]
  for [line1, line2, level] in folds
    let [label, _, stats] = s:fold_text(line1, line2, level)
    let [icount, jcount] = s:fold_counts(label)
    let stats = substitute(stats, '[^0-9 ]', '', 'g')
    let [lines, level] = map(split(stats), 'str2nr(v:val)')
    let space = repeat(' ', maxlen - strchars(lines) + 1)
    let stats = '[' . level . ']' . ' ' . '(' . lines . ')'
    let label = substitute(label, '^\s*', '', '')
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
    call fold#_recache(1)
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
  call s:toggle_message(toggle, counts[0] + counts[1])
endfunction
" For <expr> map accepting motion
function! fold#toggle_children_expr(...) abort
  return utils#motion_func('fold#toggle_children', a:000, 1)
endfunction

" Open or close parent fold under cursor and its children
" NOTE: If called on already-toggled 'current' folds the explicit 'foldclose/foldopen'
" toggles the parent. So e.g. 'zCzC' first closes python methods then the class.
function! fold#_toggle_parents(line1, line2, ...) abort
  call fold#update_folds(0)
  let winview = winsaveview()
  let nrs = [0, 0]
  for [line1, line2, level] in fold#get_parents(a:line1, a:line2)
    if line2 <= line1 | continue | endif
    let toggle = a:0 ? a:1 : 1 - s:toggle_state(line1, line1)
    let line1 = max([a:line1, line1])  " truncate range
    let line2 = min([a:line2, line2])  " truncate range
    let args = [line1, line2, level, toggle, 1]
    let result = call('s:toggle_inner', args)
    exe line1 . (toggle ? 'foldclose' : 'foldopen')
    let nrs[toggle] += 1 + len(result[1])
  endfor
  call winrestview(winview)
  let cnt = a:0 > 1 ? a:2 : v:count1
  if cnt > 1
    let inrs = fold#_toggle_parents(a:line1, a:line2, toggle, cnt - 1)
    let nrs[0] += inrs[0] | let nrs[1] += inrs[1]
  endif
  let toggle = nrs[0] && nrs[1] ? 2 : nrs[1] ? 1 : 0
  call s:toggle_message(toggle, nrs[0] + nrs[1])
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
" NOTE: This permits using e.g. 'zck' and 'zok' even when outside fold and without
" fear of accideif ntally closing huge block e.g. class or document under cursor.
function! fold#_toggle_folds(line1, line2, ...) abort
  call fold#update_folds(0)
  let winview = winsaveview()
  let levels = map(range(a:line1, a:line2), 'foldlevel(v:val)')
  let folds = fold#get_folds(a:line1, a:line2, max(levels))
  let state = s:toggle_state(a:line1, a:line2)
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
  return utils#motion_func('fold#toggle_folds', a:000)
endfunction
