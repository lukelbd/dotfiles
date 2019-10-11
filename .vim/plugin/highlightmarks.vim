" Highlight Marks plugin
" Author: Tumbler Terrall [TumblerTerrall@gmail.com]
" Edited By: Luke Davis [lukelbd@gmail.com]

" Anti-inclusion guard
" if exists("g:loaded_highlightMarks")
"    finish
" endif
let g:loaded_highlightMarks = 1

" Options
if (!exists('g:highlightMarks_colors')) " raw colors
  let g:highlightMarks_colors = ['magenta']
endif
if (!exists('g:highlightMarks_cterm_colors')) " used for cterm colors
  " let g:highlightMarks_cterm_colors = [5]
  let g:highlightMarks_cterm_colors = [5] " 5 is magenta, 4 is blue, etc.
endif
if (!exists('g:highlightMarks_useSigns')) " use signs or not
  let g:highlightMarks_useSigns = 0
endif

" Dictionary containing marks, make buffer local or get ID not found errors,
" because originally scripts was designed for file-global marks
augroup highlight_marks
  au!
  au BufRead * let b:highlights = {} " when reading for first time, set
  " au BufRead * if !exists('b:highlights') | let b:highlights = {} | endif
augroup END

" Script variables
let s:index = 0
let s:cterm_index = 0
let s:nextID = 1

" Useful commands
command! -nargs=* RemoveHighlights call RemoveHighlights(<f-args>)
command! -nargs=1 HighlightMark call HighlightMark(<q-args>)

" HighlightMark <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
"   brief: Highlights the line of the specified mark with colors from
"          g:highlightMarks_colors
"     input   - mark: [char] The mark to highlight
"     returns - void
"   make this *global* function so can call it in own macros
function! HighlightMark(mark)
  " Need to be able to differentiate capitals from lowercases.
  echo "Mark ".a:mark
  let name = 'highlightMarks_'. ((a:mark =~ '\u') ? 'C'. a:mark :a:mark)
  if (has_key(b:highlights, a:mark) && len(b:highlights[a:mark]) == 2)
    " If mark has been defined before, remove the reference to the highlight,
    " but leave the color intact
    call <SID>MatchDelete(b:highlights[a:mark][1])
    call remove(b:highlights[a:mark], 1)
  elseif (has_key(b:highlights, a:mark))
    " Mark has been defined but removed
    let color = b:highlights[a:mark][0][0]
    let cterm_color = b:highlights[a:mark][0][1]
    exe "highlight ". name ." ctermbg=". cterm_color ." guibg=". color
    if (g:highlightMarks_useSigns)
      exe "sign define ". name ." linehl=". name
    endif
  else
    " Not previously defined
    let color = g:highlightMarks_colors[s:index]
    let cterm_color = g:highlightMarks_cterm_colors[s:cterm_index]
    let s:index = (s:index + 1) % len(g:highlightMarks_colors)
    let s:cterm_index = (s:cterm_index + 1) % len(g:highlightMarks_cterm_colors)
    exe "highlight ". name ." ctermbg=". cterm_color ." guibg=". color
    if (g:highlightMarks_useSigns)
      exe "sign define ". name ." linehl=". name
    endif
    let b:highlights[a:mark] = [[color, cterm_color]]
  endif
  if (g:highlightMarks_useSigns)
    let ID = <SID>GetNextID()
    exe "sign place ". ID ." line=". line('.') ." name=". name ." file=". expand('%:p')
    call add(b:highlights[a:mark], ID)
  else
    call add(b:highlights[a:mark], matchadd(name, ".*\\%'".a:mark.'.*', 0))
  endif
endfunction

" RemoveHighlights ><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
"   brief: Removes the highlighting of the specified mark(s)
"     input   - optional: [[char]] If present, will remove highlighting for all
"               specified marks. If empty, removes highlighting for all marks.
"     returns - void
function! RemoveHighlights(...)
  if (a:0)
    " Only delete highlighting for specified marks
    for mark in a:000
      if (has_key(b:highlights, mark) && len(b:highlights[mark]) > 1)
        call <SID>MatchDelete(b:highlights[mark][1])
        call remove(b:highlights[mark], 1)
      endif
    endfor
  else
    " No arguments, delete all
    for mark in values(b:highlights)
      if (len(mark) > 1)
        call <SID>MatchDelete(mark[1])
        call remove(mark, 1)
      endif
    endfor
  endif
endfunction

" MatchDelete <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
"   brief: Deletes a highlight match, but takes into account weather signs
"          are being used or not.
"     input   - ID: [int] The ID of the match to delete
"     returns - void
function! s:MatchDelete(ID)
   if (g:highlightMarks_useSigns)
      exe "sign unplace ". a:ID
   else
      call matchdelete(a:ID)
   endif
endfunction

" GetNextID <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
"   brief: Finds the next unique ID and returns it
"     returns - The next unique ID
function! s:GetNextID()
   let retVal = s:nextID
   let s:nextID += 1
   return retVal
endfunction

