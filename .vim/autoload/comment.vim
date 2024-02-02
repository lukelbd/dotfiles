"-----------------------------------------------------------------------------"
" Utilities for inserting comments
"-----------------------------------------------------------------------------"
" Helper functions
function! s:input_title()
  let result = input('Comment block name: ', '', 'customlist,utils#null_list')
  return result
endfunction
function! s:indent_spaces() abort  " match current indent level
  let col = match(getline('.'), '^\s*\S\zs')  " location of first non-whitespace char
  return repeat(' ', col == -1 ? 0 : col - 1)
endfunction

" Return the comment character
function! comment#get_char() abort
  let char = substitute(&commentstring, '%s.*', '', '')  " leading comment indicator
  let char = substitute(char, '\s\+', '', 'g')  " ignore spaces
  return escape(char, '[]\.*$~')  " escape magic characters
endfunction
function! comment#get_regex() abort
  let char = comment#get_char()
  let char = empty(char) ? nr2char(0) : char
  return char
endfunction
function! comment#get_insert() abort
  let parts = split(&l:commentstring, '%s')
  let lefts = repeat("\<Left>", len(parts) > 1 ? len(parts[1]) + 1 : 0)
  return "\<C-g>u" . join(parts, ' ') . lefts . ' '
endfunction

" General comment note matching current indentation (used for author date)
" General dashes current line length (no leading comments, used for python-markdown)
function! comment#append_note(note) abort
  let indent = s:indent_spaces()
  let cchar = comment#get_char()
  let head = indent . cchar
  let append = head . ' ' . a:note
  call append(line('.') - 1, append)
endfunction
function! comment#append_line(fill, ...) abort
  let [col2, col1; double] = a:0 > 1 ? reverse(copy(a:000)) : [0, 0] + a:000
  let [col1, col2] = [type(col1) ? col(col1) : col1, type(col2) ? col(col2) : col2]
  let double = !empty(double) && double[0]
  let cchar = comment#get_char()
  let regex = '\s*\(' . comment#get_regex() . '.*\)\?$'
  if col1 && col2  " columns start at one
    let indent = repeat(' ', col1 - 1)
    let nfill = 1 + abs(col2 - col1)
  else  " default divider
    let indent = s:indent_spaces()
    let nfill = match(getline('.'), regex) - len(indent)  " last non-whitespace loc
  endif
  let append = indent . repeat(a:fill, nfill)
  call append(line('.'), append)  " always append line
  if double | call append(line('.') - 1, append) | endif
endfunction

" Header styles '# Hello world! #' and '# ---- Hello world! ---- #'
" Header line of arbitrary length with fill characters
function! comment#header_inchar() abort
  let indent = s:indent_spaces()
  let cchar = comment#get_char()
  let title = s:input_title()
  if empty(title) | return | endif
  let header = indent . cchar . ' ' . title . ' ' . cchar
  call append(line('.'), header)
endfunction
function! comment#header_inline(ndash) abort
  let indent = s:indent_spaces()
  let cchar = comment#get_char()
  let title = s:input_title()
  if empty(title) | return | endif
  let dashes = repeat('-', a:ndash)
  let header = indent . cchar . ' ' . dashes . ' ' . title . ' ' . dashes . ' ' . cchar
  call append(line('.') - 1, header)
endfunction
function! comment#header_line(fill, nfill, ...) abort  " inserts above by default
  let double = a:0 && a:1
  let indent = s:indent_spaces()
  let cchar = comment#get_char()
  let nfill = (a:nfill - len(indent)) / len(a:fill)  " divide by length of fill character
  let header = indent . cchar . repeat(a:fill, nfill) . cchar
  if double
    let title = s:input_title() | if empty(title) | return | endif
    let header = [header, indent . cchar . ' ' . title, header]
  endif
  call append(line('.') - 1, header)
endfunction

" Jump to next or previous match
" Note: Use this for e.g. [c and ]c comment block jumping
function! comment#next_block(reverse, ...) abort
  let nested = a:0 ? a:1 : 0
  let header = nested ? '\s*' : ''
  let regex = '^' . header . comment#get_char() . '.\+$\n'
  let regex = '\(' . regex . '\)\@<!\(' . regex . '\)\+'
  let flags = a:reverse ? 'bw' : 'w'
  call search(regex, flags)
endfunction

" Toggle comment under cursor accounting for folds
" Note: Required since default 'gcc' maps to g@$ operator function call
function! comment#toggle_motion(...) abort
  call tcomment#ResetOption()
  if v:count > 0 | call tcomment#SetOption('count', v:count) | endif
  let suffix = !a:0 ? 'gcc' : a:1 ? 'Commentc' : 'Uncommentc'
  let w:tcommentPos = getpos('.')
  let &operatorfunc = 'TCommentOpFunc_' . suffix
  let line1 = foldclosed('.')
  let line2 = foldclosedend('.')
  if line1 == line2  " e.g. both -1
    call feedkeys('g@$', 'n')
  else  " toggle fold
    call feedkeys(line1 . 'ggg@' . (line2 - line1) . 'j', 'n')
  endif
endfunction
