"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Format fold for specific filetypes
" Note: This concatenates python docstring lines and uses frame title
" for beamer presentations. In future should expand for other filetypes.
scriptencoding utf-8
let s:maxlines = 100  " maxumimum number of lines to search
let s:docstring = '["'']\{3}'  " docstring expression
function! fold#get_label(line, ...) abort
  let regex = a:0 && a:1 ? '\(^\s*\|\s*$\)' : '\s*$'
  let label = substitute(getline(a:line), regex, '', 'g')
  let regex = '\S\@<=\s*' . comment#get_regex()
  let regex .= len(comment#get_char()) == 1 ? '[^' . comment#get_char() . ']*$' : '.*$'
  let label = substitute(label, regex, '', 'g')
  return label
endfunction
function! fold#get_label_python(line, ...) abort
  let label = fold#get_label(a:line)
  let width = get(g:, 'linelength', 88) - 10  " minimum width
  if label =~# '^try:\s*$\|' . s:docstring . '\s*$'  " append lines
    for lnum in range(a:line + 1, a:0 ? a:1 : a:line + s:maxlines)
      let doc = fold#get_label(lnum, 1)  " remove indent
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
function! fold#get_label_tex(line, ...)
  let [line, label] = [a:line, fold#get_label(a:line)]
  let indent = substitute(label, '\S.*$', '', 'g')
  if label =~# 'begingroup\|begin\s*{\s*\(frame\|figure\|table\|center\)\*\?\s*}'
    let regex = label =~# '{\s*frame\*\?\s*}' ? '^\s*\\frametitle' : '^\s*\\label'
    for lnum in range(a:line + 1, a:0 ? a:1 : a:line + s:maxlines)
      let bool = getline(lnum) =~# regex
      if bool | let [line, label] = [lnum, fold#get_label(lnum)] | break | endif
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
" Note: Since sign column is empty within folds include summary of changes
" in fold text. See https://github.com/airblade/vim-gitgutter/issues/655
" Note: Created below by studying s:process_hunk() and e.g. s:is_added() s:is_removed()
" in autoload/gitgutter/diff.vim. Hunks are stored in g:gitgutter['hunks'] list of
" 4-item [from_start, from_count, to_start, to_count] lists i.e. the starting line
" and counts before and after changes. Copy internal method here for fold statistics.
let s:hunk_types = 0  " whether to split hunk types
let s:delim_open = {']': '[', ')': '(', '}': '{', '>': '<'}
let s:delim_close = {'[': ']', '(': ')', '{': '}', '<': '>'}
function! s:close_label(label, ...)
  let regex = '\([[({<]*\)\s*$'
  let items = call('matchlist', [a:label, regex] + a:000)
  let delim = split(get(items, 1, ''), '\zs')
  let delim = join(map(delim, {idx, val -> s:delim_close[val]}), '')
  if delim =~# ')$' && &l:filetype ==# 'python'
    return a:label =~# '^\s*\(def\|class\)\>' ? delim . ':' : delim
  else  " closing delimiters
    return delim
  endif
endfunction
function! fold#fold_text(...) abort
  " Get standard fold label
  if a:0 && a:0 != 3
    echohl WarningMsg
    echom 'Warning: Fold text requires zero arguments or exactly three arguments.'
    echohl None
  endif
  let current = [v:foldstart, v:foldend, len(v:folddashes)]
  let [line1, line2, level] = a:0 == 3 ? a:000 : current
  if &filetype ==# 'python'  " python formatting
    let label = fold#get_label_python(line1, min([line1 + s:maxlines, line2]))
  elseif &filetype ==# 'tex'  " tex formatting
    let label = fold#get_label_tex(line1, min([line1 + s:maxlines, line2]))
  else  " default formatting
    let label = fold#get_label(line1)
  endif
  let delim = s:close_label(label)
  let label = empty(delim) ? label : label . '···' . delim
  " Get git gutter statistics
  let [hunks, idxs] = [[0, 0, 0], s:hunk_types ? [0, 1, 2] : [1, 1, 1]]
  let [delta; signs] = ['', '+', '~', '-']
  for [hunk0, count0, hunk1, count1] in gitgutter#hunk#hunks(bufnr())
    let hunk2 = count1 ? hunk1 + count1 - 1 : hunk1
    let [clip1, clip2] = [max([hunk1, line1]), min([hunk2, line2])]
    if clip2 < clip1 | continue | endif
    let offset = (hunk2 - clip2) + (clip1 - hunk1)  " count change
    let count0 = max([count0 - offset, 0])
    let count1 = max([count1 - offset, 0])
    let hunks[idxs[0]] += max([count1 - count0, 0])  " added
    let hunks[idxs[1]] += min([count0, count1])  " modified
    let hunks[idxs[2]] += max([count0 - count1, 0])  " removed
  endfor
  for idx in range(len(hunks))
    if !hunks[idx] | continue | endif
    let nline = string(hunks[idx])
    let delta .= signs[idx] . nline
  endfor
  " Combine label and statistics
  let level = repeat('|', level)  " identical to foldcolumn
  let nline = string(line2 - line1 + 1)
  let nmax = len(string(line('$')))
  let dots = repeat('·', nmax - len(nline))
  let stats = delta . level . dots . nline
  let width = get(g:, 'linelength', 88) - 1 - strwidth(stats)
  if strwidth(label) > width - 1  " truncate fold text
    let dclose = trim(matchstr(label, '[\])}>]*:\?\s*$'))
    let dcheck = get(s:delim_open, strpart(dclose, 0, 1), '')  " handle edge case
    let dclose = strpart(label, width - 4 - strwidth(dclose)) =~# dcheck ? '' : dclose
    let label = strpart(label, 0, width - 5 - strwidth(dclose))
    let label = label . '···' . dclose . '  '
  endif
  let space = repeat(' ', width - strwidth(label))
  let text = label . space . stats
  " vint: next-line -ProhibitUsingUndeclaredVariable
  return text[winsaveview()['leftcol']:]
endfunction

" Return line of fold under cursor matching &l:foldlevel + 1
" Warning: Critical to record foldlevel('.') after pressing [z instead of ]z since
" calling foldlevel('.') on the end of a fold could return the level of its child.
" Warning: The zk/zj/[z/]z motions update jumplist, found out via trial and error
" even though not documented in :help jump-motions
" Note: No native vimscript way to do this if fold is open so we use simple algorithm
" improved from https://stackoverflow.com/a/4776436/4970632 (note [z never raises error)
let s:regex_levels = [
  \ ['python', '^class\>', '', 1],
  \ ['fortran', '^\s*\(module\|program\)\>', '', 1],
  \ ['fugitive', '^\(Unstaged\|Staged\)\>', '', 1],
  \ ['tex', '^\s*\\begin{document}', '', 1],
  \ ['tex', '^\s*\\begin{frame}', '^\s*\\begin{block}', 2],
  \ ['tex', '^\s*\\\(sub\)*section\>', '^\s*\\begin{frame}', 2],
\ ]
function! fold#get_current(...) abort  " current &foldlevel fold
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
  let recurse = 0  " recursive call
  for [ftype, regex1, regex2, level] in s:regex_levels
    if ftype !=# &l:filetype || level - 1 != toplevel
      continue
    endif
    if !empty(regex2) && !search(regex2, 'nwc')
      continue  " e.g. not talk or poster
    endif
    if getline(line1) =~# regex1
      let recurse = 1 | break
    endif
  endfor
  call winrestview(winview)
  if recurse
    return fold#get_current(toplevel + 1)
  else
    return [line1, line2, foldlevel(line1)]
  endif
endfunction

" Update the fold bounds, level, and open-close status
" Warning: Sometimes run into issue where opening new files or reading updates
" permanently disables 'expr' folds. Account for this by re-applying fold method.
" Warning: Regenerating b:SimPylFold_cache with manual SimpylFold#FoldExpr() call
" can produce strange internal bug. Instead rely on FastFoldUpdate to fill the cache.
" Note: Python block overrides b:SimPylFold_cache while markdown block overwrites
" foldtext from $RUNTIME/syntax/[markdown|javascript] and re-applies vim-markdown.
" Note: Native 'zm' and 'zr' accept commands but count is relative to current
" fold level. Could use &foldlevel = v:vount but want to keep foldlevel truncated
" to maximum number found in file as native 'zr' does. So use the below instead
function! fold#update_folds(...) abort
  let force = a:0 && a:1
  let queued = get(b:, 'fastfold_queued', 1)  " changed on TextChanged,TextChangedI
  if !force && !queued || !v:vim_did_enter | return | endif
  if &filetype ==# 'python'
    setlocal foldmethod=expr  " e.g. in case stuck, then FastFoldUpdate sets to manual
    setlocal foldexpr=python#fold_expr(v:lnum)
    call SimpylFold#Recache()
  endif
  if &filetype ==# 'markdown'
    setlocal foldmethod=expr  " e.g. in case stuck, then FastFoldUpdate sets to manual
    setlocal foldexpr=Foldexpr_markdown(v:lnum)
    setlocal foldtext=fold#fold_text()
  endif
  silent! FastFoldUpdate
  let b:fastfold_queued = 0
endfunction
function! fold#update_level(...) abort
  let level = &l:foldlevel
  if a:0  " input direction
    let cmd = v:count1 . 'z' . a:1
  elseif !v:count || v:count == level
    let cmd = ''  " already on level
  elseif v:count > level
    let cmd = (v:count - level) . 'zr'
  else
    let cmd = (level - v:count) . 'zm'
  endif
  if !empty(cmd)
    silent! exe 'normal! ' . cmd
  endif
  echom 'Fold level: ' . &l:foldlevel
endfunction
function! fold#regex_levels() abort
  for [ftype, regex1, regex2, level] in s:regex_levels
    if ftype !=# &l:filetype
      continue
    endif
    if !empty(regex2) && !search(regex2, 'nwc')
      continue  " e.g. not talk or poster
    endif
    for lnum in range(1, line('$'))
      if foldclosed(lnum) <= 0 || foldlevel(lnum) != level
        continue
      endif
      if getline(lnum) =~# regex1
        exe lnum . 'foldopen'
      endif
    endfor
  endfor
endfunction

" Toggle folds under cursor
" Note: This is required because recursive :foldclose! also closes parent
" and :[range]foldclose does not close children. Have to go one-by-one.
function! s:get_closed(line1, line2, ...) abort range
  for lnum in range(a:line1, a:line2)
    if foldclosed(lnum) > (a:0 ? a:1 : 0)
      return 1
    endif
  endfor
  return 0
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
  " echom 'Closed: ' . a:line1 . ' ' . a:line2 . ' ' . a:line1
  let toggle = a:0 ? a:1 : 1 - s:get_closed(a:line1, a:line2, a:line1)
  " echom 'Toggle: ' . toggle
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
  call fold#update_folds()
  let [line1, line2, level] = fold#get_current()
  let toggle = copy(a:000)  " use default arguments
  let args = extend([line1, line2, level], toggle)  " default s:toggle_nested
  if line2 > line1
    call call('s:toggle_nested', args)
  else  " compact error message
    call feedkeys("\<Cmd>echoerr 'E490: No fold found'\<CR>", 'n')
  endif
endfunction
function! fold#toggle_current(...) abort
  call fold#update_folds()
  let [line1, line2, level] = fold#get_current()
  let toggle = a:0 ? a:1 : 1 - s:get_closed(line1, line1)  " custom toggle
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
  call fold#update_folds()
  let [line1, line2] = sort([a:firstline, a:lastline], 'n')
  let winview = a:0 > 1 ? a:2 : {}
  let toggle = a:0 > 0 ? a:1 : 1 - s:get_closed(line1, line2)
  let bang = a:bang ? '!' : ''
  if toggle  " close folds (no bang = single level)
    silent! exe line1 . ',' . line2 . 'foldclose' . bang
  else  " open folds (no bang = single level)
    silent! exe line1 . ',' . line2 . 'foldopen' . bang
  endif
  if !empty(winview)
    call winrestview(winview)
  endif
  return ''
endfunction
" For <expr> map accepting motion
function! fold#toggle_range_expr(...) abort
  let args = add(copy(a:000), winsaveview())
  return utils#motion_func('fold#toggle_range', args)
endfunction
