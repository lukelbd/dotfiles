"-----------------------------------------------------------------------------"
" Text object functions
"-----------------------------------------------------------------------------"
" Helper function
function! s:lines_helper(pnb, nnb) abort
  let start_line = (a:pnb == 0) ? 1         : a:pnb + 1
  let end_line   = (a:nnb == 0) ? line('$') : a:nnb - 1
  let start_pos = getpos('.') | let start_pos[1] = start_line
  let end_pos   = getpos('.') | let end_pos[1]   = end_line
  return ['V', start_pos, end_pos]
endfunction

" Blank line objects
function! textobj#blank_lines() abort
  normal! 0
  let pnb = prevnonblank(line('.'))
  let nnb = nextnonblank(line('.'))
  if pnb == line('.') " also will be true for nextnonblank, if on nonblank
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" New and improved paragraphs
function! textobj#nonblank_lines() abort
  normal! 0l
  let nnb = search('^\s*\zs$', 'Wnc') " the c means accept current position
  let pnb = search('^\ze\s*$', 'Wnbc') " won't work for backwards search unless to right of first column
  if pnb == line('.')
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" Uncommented lines objects
function! textobj#uncommented_lines() abort
  normal! 0l
  let nnb = search('^\s*' . Comment() . '.*\zs$', 'Wnc')
  let pnb = search('^\ze\s*' . Comment() . '.*$', 'Wncb')
  if pnb == line('.')
    return 0
  endif
  return s:lines_helper(pnb, nnb)
endfunction

" Functions for current line
function! textobj#current_line_a() abort
  normal! 0
  let head_pos = getpos('.')
  normal! $
  let tail_pos = getpos('.')
  return ['v', head_pos, tail_pos]
endfunction
function! textobj#current_line_i() abort
  normal! ^
  let head_pos = getpos('.')
  normal! g_
  let tail_pos = getpos('.')
  let non_blank_char_exists_p = (getline('.')[head_pos[2] - 1] !~# '\s')
  return (non_blank_char_exists_p ? ['v', head_pos, tail_pos] : 0)
endfunction

" Related function for searching blocks
function! textobj#search_block(regex, forward) abort
  let range = '\%' . (a:forward ? '>' : '<')  . line('.') . 'l'
  if match(a:regex, '\\ze') != -1
    let regex = substitute(a:regex, '\\ze', '\\ze\' . range, '')
  else
    let regex = a:regex . range
  endif
  let lnum = search(regex, 'n' . repeat('b', 1 - a:forward)) " get line number
  if lnum == 0
    return ''
  else
    return lnum . 'G'
  endif
endfunction

" Function that returns regexes used in navigation
" This helps us define navigation maps for "the first line in a contiguous
" block of matching lines".
function! textobj#regex_comment() abort
  return '\s*' . Comment()
endfunction

function! textobj#regex_current_indent() abort
  return '[ ]\{0,'
    \ . len(substitute(getline('.'), '^\(\s*\).*$', '\1', ''))
    \ . '}\S\+'
endfunction

function! textobj#regex_parent_indent() abort
  return '[ ]\{0,'
    \ . max([0, len(substitute(getline('.'), '^\(\s*\).*$', '\1', '')) - &l:tabstop])
    \ . '}\S\+'
endfunction
