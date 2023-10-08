"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Generate truncated fold text
" Note: Style here is inspired by vim-anyfold. For now stick to native
" per-filetype syntax highlighting becuase still has some useful features.
scriptencoding utf-8
function! fold#fold_text() abort
  " Get fold text
  let status = string(v:foldend - v:foldstart + 1)
  let status = repeat(' ', len(string(line('$'))) - len(status)) . status
  let status = repeat('+ ', len(v:folddashes)) . status . ' lines'
  let regex = '\s*' . comment#get_char() . '\s\+.*$'
  for line in range(v:foldstart, v:foldend)
    let label = substitute(getline(line), regex, '', 'g')
    let chars = substitute(label, '\s\+', '', 'g')
    if !empty(chars) | break | endif
  endfor
  " Format fold text
  if &filetype ==# 'tex'  " hide backslashes
    let regex = '\\\@<!\\'
    let label = substitute(label, regex, '', 'g')
  endif
  if &filetype ==# 'python'  " replace docstrings
    let regex = '\("""\|' . "'''" . '\)'
    let label = substitute(label, regex, '<docstring>', 'g')
  endif
  let width = &textwidth - 1 - len(status)  " at least two spaces
  let label = len(label) > width - 4 ? label[:width - 6] . '···  ' : label
  " Combine components
  let space = repeat(' ', &textwidth - 1 - len(label) - len(status))
  let origin = 0  " string truncation point
  if !foldclosed(line('.'))
    let offset = scrollwrapped#numberwidth() + scrollwrapped#signwidth()
    let origin = col('.') - (wincol() - offset)
  endif
  let text = label . space . status
  " vint: next-line -ProhibitUsingUndeclaredVariable
  return text[origin:]
endfunction

" Translate count into fold level
" Note: Native 'zm' and 'zr' accept commands but count is relative to current
" fold level. Could use &l:foldlevel = v:vount but want to keep foldlevel truncated
" to maximum number found in file as native 'zr' does. So use the below
function! fold#set_level(level, ...) abort
  let default = a:0 ? a:1 : 'm'  " default command
  if !a:level  " no count specified
    let result = '99z' . default
  elseif a:level == &l:foldlevel
    let result = ''
  elseif a:level > &l:foldlevel
    let result = (a:level - &l:foldlevel) . 'zr'
  else
    let result = (&l:foldlevel - a:level) . 'zm'
  endif
  return result
endfunction

" Open or close folds over input range
" Note: Here 'a:toggle' closes folds when 1 and opens when 0.
function! fold#set_range(toggle, recurse, ...) range abort
  let command = a:toggle ? 'foldclose' : 'foldopen'
  let bang = a:recurse ? '!' : ''
  let view = a:0 ? a:1 : ''
  let winview = winsaveview()
  exe a:firstline . ',' . a:lastline . command . bang
  if a:0  " restore window view
    call winrestview(a:1)
  endif
  return ''
endfunction
" For <expr> map accepting motion
" Todo: Also use winsaveview for other functions?
function! fold#set_range_expr(...) abort
  let args = add(copy(a:000), winsaveview())
  return utils#motion_func('fold#set_range', args)
endfunction
