"-----------------------------------------------------------------------------"
" Text object functions
"-----------------------------------------------------------------------------"
" Helper function
function! s:lines_helper(pnb, nnb)
  let start_line = (a:pnb == 0) ? 1         : a:pnb + 1
  let end_line   = (a:nnb == 0) ? line('$') : a:nnb - 1
  let start_pos = getpos('.') | let start_pos[1] = start_line
  let end_pos   = getpos('.') | let end_pos[1]   = end_line
  return ['V', start_pos, end_pos]
endfunction

" Blacnk line objects
function! textobj#blank_lines()
  normal! 0
  let pnb = prevnonblank(line('.'))
  let nnb = nextnonblank(line('.'))
  if pnb == line('.') " also will be true for nextnonblank, if on nonblank
    return 0
  endif
  return s:lines_helper(pnb,nnb)
endfunction

" New and improved paragraphs
function! textobj#nonblank_lines()
  normal! 0l
  let nnb = search('^\s*\zs$', 'Wnc') " the c means accept current position
  let pnb = search('^\ze\s*$', 'Wnbc') " won't work for backwards search unless to right of first column
  if pnb == line('.')
    return 0
  endif
  return s:lines_helper(pnb,nnb)
endfunction

" Uncommented lines objects
function! textobj#uncommented_lines()
  normal! 0l
  let nnb = search('^\s*'.Comment().'.*\zs$', 'Wnc')
  let pnb = search('^\ze\s*'.Comment().'.*$', 'Wncb')
  if pnb == line('.')
    return 0
  endif
  return s:lines_helper(pnb,nnb)
endfunction

" Functions for current line
function! textobj#current_line_a()
  normal! 0
  let head_pos = getpos('.')
  normal! $
  let tail_pos = getpos('.')
  return ['v', head_pos, tail_pos]
endfunction
function! textobj#current_line_i()
  normal! ^
  let head_pos = getpos('.')
  normal! g_
  let tail_pos = getpos('.')
  let non_blank_char_exists_p = (getline('.')[head_pos[2] - 1] !~# '\s')
  return (non_blank_char_exists_p ? ['v', head_pos, tail_pos] : 0)
endfunction

" Related function for searching blocks
function! textobj#search_block(regex, forward)
  let lnum = line('.')
  let lnum_orig = lnum
  while match(getline(lnum), a:regex) != -1
    if lnum == 1 && !a:forward
      let lnum = line('$')
    elseif lnum == line('$') && a:forward
      let lnum = 1
    else
      let lnum = lnum + (a:forward ? 1 : -1)
    endif
    if lnum == lnum_orig " entire file matches regex
      break
    endif
  endwhile
  let flags = (a:forward ? 'w' : 'bw') " enable wrapping
  let lnum = search(a:regex, flags . 'n') " get line number
  if lnum == 0
    return ''
  else
    return lnum . 'G'
  endif
endfunction

