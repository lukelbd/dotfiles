"-----------------------------------------------------------------------------"
" Utilities for handling marks
"-----------------------------------------------------------------------------"
" Author: Tumbler Terrall [TumblerTerrall@gmail.com]
" Forked: Luke Davis [lukelbd@gmail.com]
" Cleaned up and modified to handle mark definitions
" See :help ctemrm-colors and :help gui-colors
let s:idx = 0
let s:idx_cterm = 0
let s:next_id = 1
let s:use_signs = 1
let s:gui_colors = ['DarkYellow', 'DarkCyan', 'DarkMagenta', 'DarkBlue', 'DarkRed', 'DarkGreen']
let s:cterm_colors = ['DarkYellow', 'DarkCyan', 'DarkMagenta', 'DarkBlue', 'DarkRed', 'DarkGreen']

" Delete a highlight match, but take into account whether signs are used or not
function! s:match_delete(id)
   if !s:use_signs
      call matchdelete(a:id)
   else
      exe 'sign unplace ' . a:id
   endif
endfunction

" Remove the mark and its highlighting
function! mark#del_marks(...) abort
  let highlights = get(g:, 'mark_highlights', {})
  let g:mark_highlights = highlights
  let mrks = a:0 ? a:000 : keys(highlights)
  for mrk in mrks
    if has_key(highlights, mrk) && len(highlights[mrk]) > 1
      call s:match_delete(highlights[mrk][1])
    endif
    if has_key(highlights, mrk)
      call remove(highlights, mrk)
    endif
    exe 'delmark ' . mrk
  endfor
endfunction

" Add the mark and highlight the line
function! mark#set_marks(mrk) abort
  let highlights = get(g:, 'mark_highlights', {})
  let g:mark_highlights = highlights
  let g:mark_recent = a:mrk  " quick jumping later
  let name = a:mrk =~# '\u' ? 'upper_'. a:mrk : 'lower_' . a:mrk
  let name = 'mark_'. name  " different name for capital marks
  call feedkeys('m' . a:mrk, 'n')  " apply the mark
  if has_key(highlights, a:mrk)
    call s:match_delete(highlights[a:mrk][1])
    call remove(highlights[a:mrk], 1)
  else  " not previously defined
    let base = a:mrk =~# '\u' ? 65 : 97
    let idx = a:mrk =~# '\a' ? char2nr(a:mrk) - base : 0
    let gui_color = s:gui_colors[idx % len(s:gui_colors)]
    let cterm_color = s:cterm_colors[idx % len(s:cterm_colors)]
    exe 'highlight ' . name . ' ctermbg=' . cterm_color . ' guibg=' . gui_color
    if s:use_signs  " see :help sign define
      call sign_define(name, {'linehl': name, 'text': "'" . a:mrk})
    endif
    let highlights[a:mrk] = [[gui_color, cterm_color]]
  endif
  if !s:use_signs
    call add(highlights[a:mrk], matchadd(name, ".*\\%'" . a:mrk . '.*', 0))
  else
    let id = s:next_id
    let s:next_id += 1
    call sign_place(id, '', name, '%', {'lnum': line('.')})  " empty group critical
    call add(highlights[a:mrk], id)
  endif
endfunction
