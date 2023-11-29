"1-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Generate truncated fold text
" Note: Style here is inspired by vim-anyfold. For now stick to native
" per-filetype syntax highlighting becuase still has some useful features.
scriptencoding utf-8
let s:delim_starts = {']': '[', ')': '(', '}': '{', '>': '<'}
let s:delim_ends = {'[': ']', '(': ')', '{': '}', '<': '>'}
function! fold#fold_text() abort
  " General fold formatting
  let comment = '\(^\s*\)\@<!' . comment#get_char() . '.*$'
  let label = getline(v:foldstart)
  let label = substitute(label, comment, '', 'g')  " remove trailing comment
  let label = substitute(label, '\s*$', '', 'g')  " remove trailing spaces
  if label =~# '[\[({<]\s*$'  " close delimiter
    let label = substitute(label, '\s*$', '', 'g')
    let label = label . '···' . s:delim_ends[label[-1:]]
  endif
  if &filetype ==# 'tex'  " hide backslashes
    let remove = '\\\@<!\\'
    let label = substitute(label, remove, '', 'g')
  endif
  " Docstring fold formatting
  if &filetype ==# 'python'
    let l:subs = []  " capture matches
    if label =~# '["'']\{3}\s*$'  " append afterward
      for lnum in range(v:foldstart + 1, v:foldstart + 2)
        let label .= substitute(getline(lnum), '\(^\s*\|\s*$\|-\{3,}\)', '', 'g')
      endfor
    endif
    let append = '\=add(l:subs, submatch(0))'  " see: https://vi.stackexchange.com/a/16491/8084
    call substitute(label, '["'']\{3}', append, 'gn')
    let label .= len(l:subs) % 2 ? '···' . substitute(l:subs[0], '^[frub]*', '', 'g') : ''
  endif
  " Combine fold components
  let level = repeat('+ ', len(v:folddashes))
  let lines = string(v:foldend - v:foldstart + 1)
  let space = repeat(' ', len(string(line('$'))) - len(lines))
  let status = level . space . lines . ' lines'
  let width = &textwidth - 1 - strwidth(status)  " at least two spaces
  let origin = 0  " string truncation point
  if !foldclosed(line('.'))
    let offset = scrollwrapped#numberwidth() + scrollwrapped#signwidth()
    let origin = col('.') - (wincol() - offset)
  endif
  if strwidth(label) > width - 4
    let dend = trim(matchstr(label, '[\])}>]:\?\s*$'))
    let dstr = empty(dend) ? '' : s:delim_starts[dend[0]]
    let dend = label[width - 5 - len(dend):] =~# dstr ? '' : dend
    let label = label[:width - 6 - len(dend)] . '···' . dend . '  '
  endif
  let space = repeat(' ', &textwidth - 1 - strwidth(label) - strwidth(status))
  let text = label . space . status
  " vint: next-line -ProhibitUsingUndeclaredVariable
  return text[origin:]
endfunction

" Return line of fold under cursor matching &l:foldlevel + 1
" See: https://stackoverflow.com/a/4776436/4970632 (note [z never raises error)
" Note: This is based on workflow of setting standard minimum fold level then manually
" opening other folds. Previously tried ad hoc method using foldlevel() and scrolling
" up lines preceding line is lower-level but this fails for adjacent same-level folds.
function! fold#get_closed(line1, line2, ...) abort range
  let minline = a:0 ? a:1 : 0
  let closed = 0
  for lnum in range(a:line1, a:line2)
    let closed = closed || foldclosed(lnum) > minline
  endfor
  return closed
endfunction
function! fold#get_current(...) abort
  let line = -1  " default dummy line
  let level = a:0 ? a:1 : &l:foldlevel
  let winview = winsaveview()  " save view
  while line('.') != line && foldlevel('.') - 1 > level
    let line = line('.')
    keepjumps normal! [z
  endwhile
  if foldclosed('.') > 0
    let [line1, line2] = [foldclosed('.'), foldclosedend('.')]
  else  " account for '[z' behavior when inside nested folds
    let line = line('.')
    keepjumps normal! zk
    if line('.') == line || foldlevel('.') > foldlevel(line)  " cursor inside fold
      exe line | keepjumps normal! [z
    else  " cursor went outside fold
      keepjumps normal! zj
    endif
    let line1 = line('.')
    keepjumps normal! ]z
    let line2 = line('.')
  endif
  call winrestview(winview)
  if !a:0 && !level && getline(line1) =~# '^\s*\(\\begin{document}\|class\>\)'
    return fold#get_current(1)  " ignore special folds
  else  " default case
    return [line1, line2, foldlevel(line1)]
  endif
endfunction

" Set the file fold level and optional default toggles
" Note: Native 'zm' and 'zr' accept commands but count is relative to current
" fold level. Could use &l:foldlevel = v:vount but want to keep foldlevel truncated
" to maximum number found in file as native 'zr' does. So use the below
" Warning: Regenerating SimpylFold cache with manual SimpylFold#FoldExpr() call can
" produce strange bug. Instead rely on FastFoldUpdate to fill the cache.
function! fold#update_folds() abort
  silent! unlet! b:SimpylFold_cache
  FastFoldUpdate
endfunction
function! fold#set_defaults(...) abort
  let pairs = {
    \ 'tex': ['^\s*\\begin{document}', 0],
    \ 'python': ['^class\>', 0],
    \ 'fortran': ['^\s*\(module\|program\)\>', 0],
  \ }
  if has_key(pairs, &filetype)
    let [regex, toggle] = pairs[&l:filetype]
    let winview = winsaveview()
    silent! exe 'global/' . regex . '/' . (toggle ? 'foldclose' : 'foldopen')
    call winrestview(winview)
    silent! exe a:0 && a:1 ? '' : 'normal! zv'
  endif
endfunction
function! fold#set_level(...) abort
  let current = &l:foldlevel
  if a:0  " input direction
    let cmd = v:count1 . 'z' . a:1
  else  " specific level
    if !v:count
      let cmd = ''
    elseif v:count == current
      let cmd = ''
    elseif v:count > current
      let cmd = (v:count - current) . 'zr'
    else
      let cmd = (current - v:count) . 'zm'
    endif
  endif
  if !empty(cmd)
    silent! exe 'normal! ' . cmd
  endif
  let result = &l:foldlevel
  let msg = current == result ? current : current . ' -> ' . result
  echom 'Fold level: ' . msg
endfunction

" Toggle folds under cursor
" Note: This is required because recursive :foldclose! also closes parent
" and :[range]foldclose does not close children. Have to go one-by-one.
" Note: When called on line below fold level this will close fold. So e.g. 'zCzC' will
" first fold up to foldlevel then fold additional levels.
function! s:toggle_nested(line1, line2, level, toggle) abort
  let pairs = []  " fold levels and lines
  for lnum in range(a:line1, a:line2)
    let lev = foldlevel(lnum)
    if lev && lev > a:level
      call add(pairs, [lev, lnum])
    endif
  endfor
  for [lev, lnum] in reverse(sort(pairs))
    if foldclosed(lnum) > 0 && !a:toggle
      exe lnum . 'foldopen'
    endif
    if foldclosed(lnum) <= 0 && a:toggle
      exe lnum . 'foldclose'
    endif
  endfor
endfunction
function! fold#toggle_current(...) abort
  let [line1, line2, level] = fold#get_current()
  let toggle = a:0 ? a:1 : -1
  if toggle < 0  " open if current fold is closed
    let toggle = 1 - fold#get_closed(line1, line1)
  endif
  if line2 > line1
    call s:toggle_nested(line1, line2, level, toggle)
    exe line1 . (toggle ? 'foldclose' : 'foldopen')
  else
    call feedkeys("\<Cmd>echoerr 'E490: No fold found'\<CR>", 'n')
  endif
endfunction
function! fold#toggle_nested(...) abort
  let [line1, line2, level] = fold#get_current()
  let toggle = a:0 ? a:1 : -1  " -1 indicates switch
  if toggle < 0  " open if any nested folds are closed
    let toggle = 1 - fold#get_closed(line1, line2, line1)
  endif
  if line2 > line1
    call s:toggle_nested(line1, line2, level, toggle)
  else  " compact error message
    call feedkeys("\<Cmd>echoerr 'E490: No fold found'\<CR>", 'n')
  endif
endfunction

" Open or close folds over input range
" Note: Here 'a:toggle' closes folds when 1 and opens when 0.
function! fold#toggle_range(...) range abort
  let [line1, line2] = sort([a:firstline, a:lastline], 'n')
  let winview = a:0 > 2 ? a:3 : {}
  let bang = a:0 > 1 ? a:2 : 0
  let bang = bang ? '!' : ''
  let toggle = a:0 > 0 ? a:1 : -1  " -1 indicates switch
  let toggle = toggle < 0 ? 1 - fold#get_closed(line1, line2) : toggle
  if toggle  " close folds (no bang = single level)
    exe line1 . ',' . line2 . 'foldclose' . bang
  else  " open folds (no bang = single level)
    exe line1 . ',' . line2 . 'foldopen' . bang
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
