"-----------------------------------------------------------------------------"
" Comment string presets
"-----------------------------------------------------------------------------"
" Helper function for matching current indent level
function! s:comment_indent() abort
  let col = match(getline('.'), '^\s*\S\zs') " location of first non-whitespace char
  return col == -1 ? 0 : col - 1
endfunction

" Begin comment in insert mode
function! comments#comment_insert() abort
  let parts = split(&l:commentstring, '%s')
  return "\<C-g>u" . join(parts, ' ') . repeat("\<Left>", len(parts) > 1 ? len(parts[1]) + 1 : 0) . ' '
endfunction

" Separators of arbitrary length
function! comments#comment_bar(fill, nfill, suffix) abort " inserts above by default; most common use
  let cchar = Comment()
  let nspace = s:comment_indent()
  let suffix = (a:suffix ? cchar : '')
  let nfill = (a:nfill - nspace)/len(a:fill) " divide by length of fill character
  normal! k
  call append(line('.'), repeat(' ', nspace) . cchar . repeat(a:fill, nfill) . suffix)
  normal! jj
endfunction
function! comments#comment_bar_surround(fill, nfill, suffix) abort
  let cchar = Comment()
  let nspace = s:comment_indent()
  let suffix = (a:suffix ? cchar : '')
  let nfill = (a:nfill - nspace)/len(a:fill) " divide by length of fill character
  let lines = [
    \ repeat(' ', nspace) . cchar . repeat(a:fill, nfill) . suffix,
    \ repeat(' ', nspace) . cchar . ' ',
    \ repeat(' ', nspace) . cchar . repeat(a:fill, nfill) . suffix
    \ ]
  normal! k
  call append(line('.'), lines)
  normal! jj$
endfunction

" Separator of dashes matching current line length
function! comments#comment_header(fill) abort
  let cchar = Comment()
  let nspace = s:comment_indent()
  let nfill = match(getline('.'), '\s*$') - nspace " location of last non-whitespace char
  call append(line('.'), repeat(' ', nspace) . repeat(a:fill, nfill))
endfunction
function! comments#comment_header_surround(fill) abort
  let cchar = Comment()
  let nspace = s:comment_indent()
  let nfill = match(getline('.'), '\s*$') - nspace " location of last non-whitespace char
  call append(line('.'), repeat(' ', nspace) . repeat(a:fill, nfill))
  call append(line('.') - 1, repeat(' ', nspace) . repeat(a:fill, nfill))
endfunction

" Inline style of format '# ---- Hello world! ----' and '# Hello world! #'
function! comments#comment_inline(ndash) abort
  let nspace = s:comment_indent()
  let cchar = Comment()
  normal! k
  call append(line('.'), repeat(' ', nspace) . cchar . repeat(' ', a:ndash) . repeat('-', a:ndash) . '  ' . repeat('-', a:ndash))
  normal! j^
  call search('- \zs', '', line('.')) " search, and stop on this line (should be same one); no flags
endfunction
function! comments#comment_double() abort
  let nspace = s:comment_indent()
  let cchar = Comment()
  normal! k
  call append(line('.'), repeat(' ', nspace) . cchar . '  ' . cchar)
  normal! j$h
endfunction

" Arbtirary message above this line, matching indentation level
function! comments#comment_message(message) abort
  let nspace = s:comment_indent()
  let cchar = Comment()
  normal! k
  call append(line('.'), repeat(' ', nspace) . cchar . ' ' . a:message)
  normal! jj
endfunction

" Docstring
function! comments#insert_docstring(char) abort
  let nspace = (s:comment_indent() + &l:tabstop)
  call append(line('.'), [repeat(' ', nspace) . repeat(a:char, 3), repeat(' ', nspace), repeat(' ', nspace) . repeat(a:char, 3)])
  normal! jj$
endfunction
