"-----------------------------------------------------------------------------
" Utilities for inserting comments
"-----------------------------------------------------------------------------
" Helper functions
function! s:input_title()
  return input('Title: ', '', 'customlist,utils#null_list')
endfunction
function! s:indent_spaces() abort  " match current indent level
  let col = match(getline('.'), '^\s*\S\zs')  " location of first non-whitespace char
  return repeat(' ', col == -1 ? 0 : col - 1)
endfunction

" Return the comment character
function! comment#comment_char() abort
  let string = substitute(&commentstring, '%s.*', '', '')  " leading comment indicator
  let string = substitute(string, '\s\+', '', 'g')  " ignore spaces
  return escape(string, '[]\.*$~')  " escape magic characters
endfunction

" Begin comment in insert mode
function! comment#comment_insert() abort
  let parts = split(&l:commentstring, '%s')
  return "\<C-g>u" . join(parts, ' ') . repeat("\<Left>", len(parts) > 1 ? len(parts[1]) + 1 : 0) . ' '
endfunction

" Separator of dashes matching current line length
function! comment#section_line(fill, ...) abort
  let cchar = comment#comment_char()
  let indent = s:indent_spaces()
  let nfill = match(getline('.'), '\s*$') - len(indent)  " location of last non-whitespace char
  call append(line('.'), indent . repeat(a:fill, nfill))
  if a:0 && a:1
    call append(line('.') - 1, indent . repeat(a:fill, nfill))
  endif
endfunction

" Separators of arbitrary length
function! comment#header_line(fill, nfill, ...) abort  " inserts above by default
  let cchar = comment#comment_char()
  let indent = s:indent_spaces()
  let nfill = (a:nfill - len(indent)) / len(a:fill) " divide by length of fill character
  let text = indent . cchar . repeat(a:fill, nfill)
  if a:0 && a:1
    let title = s:input_title()
    if empty(title) | return | endif
    let text = [text, indent . cchar . ' ' . title, text]
  endif
  call append(line('.') - 1, text)
endfunction

" Inline style of format '# ---- Hello world! ----'
function! comment#header_inline(ndash) abort
  let cchar = comment#comment_char()
  let indent = s:indent_spaces()
  let title = s:input_title()
  if empty(title) | return | endif
  call append(line('.') - 1, indent . cchar . repeat(' ', a:ndash) . repeat('-', a:ndash) . ' ' . title . ' ' . repeat('-', a:ndash))
endfunction

" Inline style of format '# Hello world! #'
function! comment#header_incomment() abort
  let indent = s:indent_spaces()
  let cchar = comment#comment_char()
  let title = s:input_title()
  if empty(title) | return | endif
  call append(line('.'), indent . cchar . ' ' . title)
endfunction

" Arbtirary message above this line, matching indentation level
function! comment#message(message) abort
  let indent = s:indent_spaces()
  let cchar = comment#comment_char()
  call append(line('.') - 1, indent . cchar . ' ' . a:message)
endfunction
