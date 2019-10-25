"-----------------------------------------------------------------------------"
" Tabularize plugin functions
"-----------------------------------------------------------------------------"
" Function for tabularizing but ignoring lines without delimiters
function! tabularize#smart_table(arg) range
  " Remove the lines without matching regexes
  let dlines = [] " note we **cannot** use dictionary, because subsequent lines without matches will overwrite each other
  let lastline = a:lastline  " no longer read-only
  let firstline = a:firstline
  let searchline = a:firstline
  let regex = split(a:arg, '/')[0] " regex is first part; other arguments are afterward
  while searchline <= lastline
    if getline(searchline) !~# regex " if return value is zero, delete this line
      call add(dlines, [searchline, getline(searchline)])
      let lastline -= 1 " after deletion, the 'last line' of selection has changed
      exe searchline . 'd'
    else " leave it alone, increment search
      let searchline += 1
    endif
  endwhile

  " Execute tabularize function
  if firstline > lastline
    echohl WarningMsg
    echom 'Warning: No matches in selection.'
    echohl None
  else
    exe firstline.','.lastline.'Tabularize '.a:arg
  endif

  " Add back the lines that were deleted
  for pair in reverse(dlines) " insert line of text below where deletion occurred (line '0' adds to first line)
    call append(pair[0]-1, pair[1])
  endfor
endfunction
