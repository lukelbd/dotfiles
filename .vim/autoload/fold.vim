"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Translate count into fold level
" Note: Native 'zm' and 'zr' accept commands but count is relative to current
" fold level. Could use &l:foldlevel = v:vount but want to keep foldlevel truncated
" to maximum number found in file as native 'zr' does. So use the below
function! fold#fold_level(default) abort
  if !v:count  " default command
    let result = '99z' . a:default
  elseif v:count == &l:foldlevel
    let result = ''
  elseif v:count > &l:foldlevel
    let result = (v:count - &l:foldlevel) . 'zr'
  else
    let result = (&l:foldlevel - v:count) . 'zm'
  endif
  return result
endfunction

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
