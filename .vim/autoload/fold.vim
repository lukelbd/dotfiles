"-----------------------------------------------------------------------------"
" Utilities for vim folds
"-----------------------------------------------------------------------------"
" Recursively close or open up to &l:foldlevel
" Note: Current workflow is to set standard minimum fold level then manually open folds
" Note: Error message is more compact if triggered outside function so use feedkeys()
" Note: When called on line below fold level this will still trigger a fold close. So
" pressing e.g. 'zCzC' will first fold up to foldlevel then fold additional levels.
function! fold#close_nested(...) abort
  let nochange = a:0 ? a:1 : 0  " do not change open/close status, only remove nesting
  let isclosed = foldclosed('.') > 0 ? 1 : 0
  let line = line('.')
  if nochange && isclosed
    call feedkeys('zO', 'n')
  endif
  while line > 1 && foldlevel(line - 1) > &l:foldlevel
    let line -= 1  " stop when preceding line matches desired level
  endwhile
  call feedkeys("\<Cmd>" . line . "foldclose\<CR>", 'n')
  if nochange && !isclosed
    call feedkeys('zO', 'n')
  endif
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

" Translate count into fold level
" Note: Native 'zm' and 'zr' accept commands but count is relative to current
" fold level. Could use &l:foldlevel = v:vount but want to keep foldlevel truncated
" to maximum number found in file as native 'zr' does. So use the below
function! fold#set_level(...) abort
  let current = &l:foldlevel
  if a:0  " input direction
    let direc = a:1 ==? 'm' ? -1 : 1
    let cmd = v:count1 . 'z' . a:1
  else  " specific level
    if !v:count
      let cmd = 'zM'
    elseif v:count == current
      let cmd = ''
    elseif v:count > current
      let cmd = (v:count - current) . 'zr'
    else
      let cmd = (current - v:count) . 'zm'
    endif
  endif
  exe 'normal! ' . cmd
  let result = &l:foldlevel
  let msg = current == result ? current : current . ' -> ' . result
  echom 'Fold level: ' . msg
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
function! fold#set_range_expr(...) abort
  let args = add(copy(a:000), winsaveview())
  return utils#motion_func('fold#set_range', args)
endfunction
