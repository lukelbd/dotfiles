"-----------------------------------------------------------------------------"
" Custom text objects
"-----------------------------------------------------------------------------"
" The leading comment character (with stripped whitespace)
function! s:comment_char()
  let string = substitute(&commentstring, '%s.*', '', '')
  return substitute(string, '\s\+', '', 'g')
endfunction

" Helper function returning lines
function! s:lines_helper(pnb, nnb) abort
  let start_line = a:pnb == 0 ? 1         : a:pnb + 1
  let end_line   = a:nnb == 0 ? line('$') : a:nnb - 1
  let start_pos = getpos('.') | let start_pos[1] = start_line
  let end_pos   = getpos('.') | let end_pos[1]   = end_line
  return ['V', start_pos, end_pos]
endfunction

" Blank line object
function! textobj#blank_lines() abort
  normal! 0
  let pnb = prevnonblank(line('.'))
  let nnb = nextnonblank(line('.'))
  if pnb == line('.')  " also will be true for nextnonblank, if on nonblank
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" Uncommented line object
function! textobj#uncommented_lines() abort
  normal! 0l
  let nnb = search('^\s*' . s:comment_char() . '.*\zs$', 'Wnc')
  let pnb = search('^\ze\s*' . s:comment_char() . '.*$', 'Wncb')
  if pnb == line('.')
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction
