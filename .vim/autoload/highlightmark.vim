" Highlight Marks plugin
" Author: Tumbler Terrall [TumblerTerrall@gmail.com]
" Forked By: Luke Davis [lukelbd@gmail.com]

" Options
if !exists('g:highlightmark_colors')
   let g:highlightmark_colors = ['orange', 'yellow', 'green', 'blue', 'purple', '#00BB33']
endif
if !exists('g:highlightmark_cterm_colors')
   let g:highlightmark_cterm_colors = [3, 2, 4, 1]
endif
if !exists('g:highlightmark_use_signs')  " highlight to left end of screen?
   let g:highlightmark_use_signs = 0
endif

" Buffer variable containing marks. Must be buffer local or get ID not found errors,
" because originally scripts was designed for file-global marks
augroup highlight_marks
  au!
  au BufRead * let b:highlightmark = {}  " when reading for first time, set
augroup END

" Script variables
let s:index = 0
let s:cterm_index = 0
let s:nextID = 1

" Find and return the next unique ID
function! s:get_next()
   let retVal = s:nextID
   let s:nextID += 1
   return retVal
endfunction
" Delete a highlight match, but take into account whether signs

" are being used or not.
function! s:match_delete(ID)
   if g:highlightmark_use_signs
      exe 'sign unplace ' . a:ID
   else
      call matchdelete(a:ID)
   endif
endfunction

" Highlight the line of the specified mark with colors from g:highlightmark_colors
function! highlightmark#highlight_mark(mark) abort
  " Need to be able to differentiate capitals from lowercases.
  if !exists('b:highlightmark')
    let b:highlightmark = {}
  endif
  let highlights = b:highlightmark
  echo 'Mark: ' . a:mark
  let name = 'highlightmark_'. (a:mark =~# '\u' ? 'C'. a:mark :a:mark)
  if has_key(highlights, a:mark) && len(highlights[a:mark]) == 2
    " If mark has been defined before, remove the reference to the highlight,
    " but leave the color intact
    call s:match_delete(highlights[a:mark][1])
    call remove(highlights[a:mark], 1)
  elseif (has_key(highlights, a:mark))
    " Mark has been defined but removed
    let color = highlights[a:mark][0][0]
    let cterm_color = highlights[a:mark][0][1]
    exe 'highlight ' . name . ' ctermbg=' . cterm_color . ' guibg=' . color
    if g:highlightmark_use_signs
      exe 'sign define ' . name . ' linehl=' . name
    endif
  else
    " Not previously defined
    let color = g:highlightmark_colors[s:index]
    let cterm_color = g:highlightmark_cterm_colors[s:cterm_index]
    let s:index = (s:index + 1) % len(g:highlightmark_colors)
    let s:cterm_index = (s:cterm_index + 1) % len(g:highlightmark_cterm_colors)
    exe 'highlight ' . name . ' ctermbg=' . cterm_color . ' guibg=' . color
    if g:highlightmark_use_signs
      exe 'sign define ' . name . ' linehl=' . name
    endif
    let highlights[a:mark] = [[color, cterm_color]]
  endif
  if g:highlightmark_use_signs
    let ID = s:get_next()
    exe 'sign place ' . ID . ' line=' . line('.') . ' name=' . name . ' file=' . expand('%:p')
    call add(highlights[a:mark], ID)
  else
    call add(highlights[a:mark], matchadd(name, ".*\\%'" . a:mark . '.*', 0))
  endif
endfunction

" Remove the highlighting of the specified mark(s). If input present, only
" remove highlights for input marks.
function! highlightmark#remove_highlights(...) abort
  let highlights = exists('b:highlightmark') ? b:highlightmark : {}
  if a:0
    for mark in a:000
      if (has_key(highlights, mark) && len(highlights[mark]) > 1)
        call s:match_delete(highlights[mark][1])
        call remove(highlights[mark], 1)
      endif
    endfor
  else
    for mark in values(highlights)
      if (len(mark) > 1)
        call s:match_delete(mark[1])
        call remove(mark, 1)
      endif
    endfor
  endif
endfunction
