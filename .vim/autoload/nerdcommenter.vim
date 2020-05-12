"-----------------------------------------------------------------------------"
" Defines functions used with NERDCommenter plugin
"-----------------------------------------------------------------------------"
" Helper function for matching current indent level
function! s:comment_indent() abort
  let col = match(getline('.'), '^\s*\S\zs') " location of first non-whitespace char
  return (col == -1 ? 0 : col-1)
endfunction

" Function for toggling comment while in insert mode
function! nerdcommenter#comment_insert() abort
  if exists('b:NERDCommenterDelims')
    let left = b:NERDCommenterDelims['left']
    let right = b:NERDCommenterDelims['right']
    let left_alt = b:NERDCommenterDelims['leftAlt']
    let right_alt = b:NERDCommenterDelims['rightAlt']
    if (left !=# '' && right !=# '')
      return (left . '  ' . right . repeat("\<Left>", len(right) + 1))
    elseif (left_alt !=# '' && right_alt !=# '')
      return (left_alt . '  ' . right_alt . repeat("\<Left>", len(right_alt) + 1))
    else
      return (left . ' ')
    endif
  else
    return ''
  endif
endfunction

" Next separators of arbitrary length
function! nerdcommenter#comment_bar(fill, nfill, suffix) abort " inserts above by default; most common use
  let cchar = Comment()
  let nspace = s:comment_indent()
  let suffix = (a:suffix ? cchar : '')
  let nfill = (a:nfill - nspace)/len(a:fill) " divide by length of fill character
  normal! k
  call append(line('.'), repeat(' ', nspace) . cchar . repeat(a:fill, nfill) . suffix)
  normal! jj
endfunction
function! nerdcommenter#comment_bar_surround(fill, nfill, suffix) abort
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
function! nerdcommenter#comment_header(fill) abort
  let cchar = Comment()
  let nspace = s:comment_indent()
  let nfill = match(getline('.'), '\s*$') - nspace " location of last non-whitespace char
  call append(line('.'), repeat(' ', nspace) . repeat(a:fill, nfill))
endfunction
function! nerdcommenter#comment_header_surround(fill) abort
  let cchar = Comment()
  let nspace = s:comment_indent()
  let nfill = match(getline('.'), '\s*$') - nspace " location of last non-whitespace char
  call append(line('.'), repeat(' ', nspace) . repeat(a:fill, nfill))
  call append(line('.') - 1, repeat(' ', nspace) . repeat(a:fill, nfill))
endfunction

" Inline style of format '# ---- Hello world! ----' and '# Hello world! #'
function! nerdcommenter#comment_inline(ndash) abort
  let nspace = s:comment_indent()
  let cchar = Comment()
  normal! k
  call append(line('.'), repeat(' ', nspace) . cchar . repeat(' ', a:ndash) . repeat('-', a:ndash) . '  ' . repeat('-', a:ndash))
  normal! j^
  call search('- \zs', '', line('.')) " search, and stop on this line (should be same one); no flags
endfunction
function! nerdcommenter#comment_double() abort
  let nspace = s:comment_indent()
  let cchar = Comment()
  normal! k
  call append(line('.'), repeat(' ', nspace) . cchar . '  ' . cchar)
  normal! j$h
endfunction

" Arbtirary message above this line, matching indentation level
function! nerdcommenter#comment_message(message) abort
  let nspace = s:comment_indent()
  let cchar = Comment()
  normal! k
  call append(line('.'), repeat(' ', nspace) . cchar . ' ' . a:message)
  normal! jj
endfunction

" Docstring
function! nerdcommenter#insert_docstring(char) abort
  let nspace = (s:comment_indent() + &l:tabstop)
  call append(line('.'), [repeat(' ', nspace) . repeat(a:char, 3), repeat(' ', nspace), repeat(' ', nspace) . repeat(a:char, 3)])
  normal! jj$
endfunction
