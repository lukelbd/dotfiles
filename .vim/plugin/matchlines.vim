"------------------------------------------------------------------------------
"HIGHLIGHT MATCHING MATCHIT.VIM GROUPS
" * Note it may be impossible to preserve the jumplist when pressing '%'; this generally
"   calls a function that jumps around to the matching delimiter, but according to :keepjumps
"   documentation, running :keepjumps func() on func that jumps around will not preserve jumplist
" * Note the default '%' press with markdown files results in this weird annoying
"   delay that isn't really related to this plugin; added patch to exit the matching function
"   with markdown filetypes
"------------------------------------------------------------------------------
"Matching % codes (loads macros with default matching REG-EXPs)
"runtime macros/matchit.vim
set showmatch

"Used this in an answer at: http://vi.stackexchange.com/q/8707/5229
function! s:get_match_lines(line) abort
  "Loop until `%` returns the original line number; abort if
  "input argument line is the *original* line
  "(1) the % operator keeps us on the same line, or
  "(2) the % operator doesn't return us to the same line after some nubmer of jumps
  let tolerance=5 "keep it small so don't get slowdowns
  let badbreak=1
  let linebefore=-1
  let lines = []
  let b:xyz = [] "FOR TESTING
  for jumpcommand in ["%", "%^"] "try both, depends which is more suitable
    execute "keepjumps normal! ".a:line."gg"
    " if jumpcommand=="%^" | echo "Trying alternate method." | endif
    while tolerance && linebefore != line('.')
      "Do *not* use normal!; need filetype specific maps of %
      let linebefore=line('.')
      let tolerance-=1
      execute "keepjumps normal ".jumpcommand
      if line('.')==a:line "note that the current line number is never added to the `lines` list.
        let badbreak=0
        break
      endif
      call add(lines, line('.'))
    endwhile
    if badbreak==0
      break "otherwise try again with the new jumpcommand
    endif
  endfor
  "Return to original line no matter what, return list of lines to highlight
  "Documentation says keepjumps exe 'command' fails; must use exe 'keepjumps command'
  execute "keepjumps normal! ".a:line."gg"
  if badbreak
    " echohl WarningMsg | echo "Failed to find match for line ".line('.')."." | echohl None
      "better then echoerr because does not pause screen; see help info for echohl
    echom "Failed to find match for line ".line('.')."."
    return [] "make above echo, not echom; probably slows shit down adding to messages list
  else
    return lines
  endif
endfunction
"Unmatch function
function! s:hl_matching_lines_clear() abort
  let b:hl_ranORcleared = 0
  silent! call matchdelete(12345)
  unlet! b:hl_last_line
endfunction
"The highlight group that's used for highlighting matched lines.  By
function! s:hl_matching_lines() abort
  let b:hl_ranORcleared = 1
  "Exit certain filetypes or filenames
  if &ft == "markdown" | return | endif
  "Make sure to exit if we are in any visual mode. Here's a great way way
  "to see results of mode() with a function:
  "  function! Mode()
  "    echom 'Mode: '.mode() | return ''
  "  endfunction
  "  vnoremap <expr> <Leader><Space> ''.Mode()
  if mode()=~"[ivV]"
    call s:hl_matching_lines_clear()
    return
  endif
  "Do not attempt matches when in comments; avoids detecting commented keywords
  if synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")=~?'\(comment\|constant\)'
    call s:hl_matching_lines_clear()
    return
  endif
  "Disable when on top of vim maps
  if &ft=="vim" && ("\n".getline('.')=~'\_s\([a-z]\?map\|[a-z]\=noremap\)')
    call s:hl_matching_lines_clear()
    return
  endif
  "Do not re-run if cursor on same line
  if exists('b:hl_last_line') && b:hl_last_line == line('.')
    return
  endif
  let b:hl_last_line = line('.')
  "Save the window's state.
  let view = winsaveview()
  "Delete a previous match highlight. `12345` is used for the match ID.
  "It can be anything as long as it's unique.
  silent! call matchdelete(12345)
  "Try to get matching lines from the current cursor position.
  let lines = s:get_match_lines(view.lnum)
  " keepjumps let lines = s:get_match_lines(view.lnum)
  if empty(lines)
    "It's possible that the line has another matching line, but can't be
    "matched at the current column.  Move the cursor to column 1 to try
    "one more time.
    call cursor(view.lnum, 1)
    let lines = s:get_match_lines(view.lnum)
    " keepjumps let lines = s:get_match_lines(view.lnum)
  endif
  if len(lines)
    "Add the *current* line to the list; output of line-matching function doesn't do this
    call add(lines, view.lnum)
    if exists('*matchaddpos')
      "If matchaddpos() is availble, use it to highlight the lines since it's
      "faster than using a pattern in matchadd().
      call matchaddpos('MatchLine', lines, 0, 12345)
    else
      "Highlight the matching lines using the \%l atom.
      call matchadd('MatchLine', join(map(lines, '''\%''.v:val.''l'''), '\|'), 0, 12345)
    endif
  endif
  "EDIT: SAVE, for DEBUGGING
  let b:lines=lines
  "Restore the window's state.
  call winrestview(view)
endfunction
" default, it will be the same as the `MatchParen` group.
highlight link MatchLine MatchParen
augroup matchlines
  autocmd!
  " Highlight lines as the cursor moves.
  autocmd CursorMoved * call s:hl_matching_lines()
  " Remove the highlight while in insert mode.
  autocmd InsertEnter * call s:hl_matching_lines_clear()
  " Remove the highlight after TextChanged.
  if v:version>703
    autocmd TextChanged,TextChangedI * call s:hl_matching_lines_clear()
  endif " 703 versions seem to fail here
augroup END
" Shortcut -- 'm' for 'match'
"Pretty much never use this, because i like CursorMoved behavior
" function! s:match_toggle()
"   if exists('b:hl_ranORcleared')
"     if b:hl_ranORcleared
"       call s:hl_matching_lines_clear()
"     else
"       call s:hl_matching_lines()
"     endif
"   else
"     call s:hl_matching_lines()
"   endif
" endfunction
" nnoremap <Leader>m :call <sid>match_toggle()<CR>

