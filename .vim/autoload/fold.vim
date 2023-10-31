"1-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Generate truncated fold text
" Note: Style here is inspired by vim-anyfold. For now stick to native
" per-filetype syntax highlighting becuase still has some useful features.
scriptencoding utf-8
function! fold#fold_text() abort
  " Get fold text
  let level = repeat('+ ', len(v:folddashes))
  let lines = string(v:foldend - v:foldstart + 1)
  let space = repeat(' ', len(string(line('$'))) - len(lines))
  let status = level . space . lines . ' lines'
  let regex = '\s*' . comment#get_char() . '\s\+.*$'
  for line in range(v:foldstart, v:foldend)
    let label = substitute(getline(line), regex, '', 'g')  " remove comments
    let chars = substitute(label, '\s\+', '', 'g')
    if !empty(chars) | break | endif  " non-commented line
  endfor
  " Format fold text
  if &filetype ==# 'tex'  " hide backslashes
    let regex = '\\\@<!\\'
    let label = substitute(label, regex, '', 'g')
  endif
  if &filetype ==# 'python'  " replace docstrings
    let regex = '[frub]*["'']\{3}'
    let label = substitute(label, regex, '<docstring>', 'g')
  endif
  if label =~# '[\[({]\s*$'  " close delimiter
    let label = substitute(label, '\s*$', '', 'g')
    let label = label . '···' . {'[': ']', '(': ')', '{': '}'}[label[-1:]]
  endif
  let width = &textwidth - 1 - strwidth(status)  " at least two spaces
  let label = strwidth(label) > width - 4 ? label[:width - 6] . '···  ' : label
  " Combine components
  let space = repeat(' ', &textwidth - 1 - strwidth(label) - strwidth(status))
  let origin = 0  " string truncation point
  if !foldclosed(line('.'))
    let offset = scrollwrapped#numberwidth() + scrollwrapped#signwidth()
    let origin = col('.') - (wincol() - offset)
  endif
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
  let lstart = a:0 ? a:1 : 0
  let closed = 0
  for lnum in range(a:line1, a:line2)
    let closed = closed || foldclosed(lnum) > lstart
  endfor
  return closed
endfunction
function! fold#get_parent(...) abort
  let line = -1  " default dummy line
  let level = a:0 ? a:1 : &l:foldlevel
  let winview = winsaveview()  " save view
  while line != line('.') && level < foldlevel('.') - 1
    let line = line('.')
    keepjumps normal! [z
  endwhile
  if foldclosed('.') > 0
    let [line1, line2] = [foldclosed('.'), foldclosedend('.')]
  else
    let line = line('.')
    keepjumps normal! zk
    if line('.') == line || foldlevel('.') > foldlevel(line)  " cursor stayed inside fold
      exe string(line) | keepjumps normal! [z
    else  " cursor went outside fold
      keepjumps normal! zj
    endif
    let line1 = line('.')
    keepjumps normal! ]z
    let line2 = line('.')
  endif
  call winrestview(winview)
  if level == 0 && getline(line1) =~# '^class\>'  " ignore 'class'
    return fold#get_parent(1)
  else  " default case
    return [line1, line2, foldlevel(line1)]
  endif
endfunction

" Translate count into fold level
" Note: Native 'zm' and 'zr' accept commands but count is relative to current
" fold level. Could use &l:foldlevel = v:vount but want to keep foldlevel truncated
" to maximum number found in file as native 'zr' does. So use the below
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
  silent! exe 'normal! ' . cmd
  let result = &l:foldlevel
  let msg = current == result ? current : current . ' -> ' . result
  echom 'Fold level: ' . msg
endfunction

" Toggle folds under cursor
" Note: This is required because recursive :foldclose! also closes parent
" and :[range]foldclose does not close children. Have to go one-by-one.
" Note: When called on line below fold level this will close fold. So e.g. 'zCzC' will
" first fold up to foldlevel then fold additional levels.
function! s:toggle_range(line1, line2, level, toggle) abort range
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
function! fold#toggle_children(...) abort
  let [line1, line2, level] = fold#get_parent()
  let toggle = a:0 ? a:1 : -1  " -1 indicates switch
  if toggle < 0  " test folds within range
    let toggle = 1 - fold#get_closed(line1, line2, line1)
  endif
  if line2 > line1
    call s:toggle_range(line1, line2, level, toggle)
  else  " compact error message
    call feedkeys("\<Cmd>echoerr 'E490: No fold found'\<CR>", 'n')
  endif
endfunction
function! fold#toggle_parent(...) abort
  let [line1, line2, level] = fold#get_parent()
  let toggle = a:0 ? a:1 : -1
  if toggle < 0  " test parent fold
    let toggle = 1 - fold#get_closed(line1, line1)
  endif
  if line2 > line1
    call s:toggle_range(line1, line2, level, toggle)
    exe line1 . (toggle ? 'foldclose' : 'foldopen')
  else
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
