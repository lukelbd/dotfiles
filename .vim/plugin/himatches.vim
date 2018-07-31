"##############################################################################"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-07-25
" Name: matchhighlight.vim
" This script highlights matching pairs of parentheses and groups.
" It was modified from the ***builtin*** matching pair plugin.
" Features:
"  * Highlights entire line if matches found across lines.
"  * Refrain from highlighting in certain tricky situations -- e.g. don't search
"    for bracket/parentheses pairs across multiple lines, don't search for matches
"    when inside a string literal or comment, etc.
"##############################################################################"
" Shared function
" Define circumstances in which we'd like to disable highlighting
"##############################################################################"
function s:nohighlight()
  " Exit certain filetypes or filenames
  if &ft == "markdown" | return | endif
  " Make sure to exit if we are in any visual mode. Here's a great way way
  " to see results of mode() with a function:
  "  function! Mode()
  "    echom 'Mode: '.mode() | return ''
  "  endfunction
  "  vnoremap <expr> <Leader><Space> ''.Mode()
  if mode()=~"[ivV]"
    return 1
  endif
  " Do not attempt matches when in comments; avoids detecting commented keywords
  if synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")=~?'\(comment\|constant\)'
    return 1
  endif
  " Disable when on top of vim maps
  if &ft=="vim" && ("\n".getline('.')=~'\_s\([a-z]\?map\|[a-z]\=noremap\)')
    return 1
  endif
  " Ignore free brackets/parens; fixes horribly annoying issue with bash case/esac
  if getline('.') =~ '^\([^(]*)\|[^\[]*\]\)'
    return 1
  endif
  if getline('.') =~ '\(([^)]*\|\[[^\]]*\)$'
    return 1
  endif
endfunction

"##############################################################################"
" Bulk of original matchparen.vim plugin
" Highlights matching parentheses, brackets, and whatnot
"##############################################################################"
set showmatch
if !exists("g:matchparen_timeout")
  let g:matchparen_timeout = 300
endif
if !exists("g:matchparen_insert_timeout")
  let g:matchparen_insert_timeout = 60
endif

" Matchparen autocommands
augroup matchparen
  autocmd! CursorMoved,CursorMovedI,WinEnter * call s:hlparen()
  if exists('##TextChanged')
    autocmd! TextChanged,TextChangedI * call s:hlparen()
  endif
augroup END

" The function that is invoked (very often) to define a ":match" highlighting
" for any matching paren.
function! s:hlparen()
  " Remove any previous match.
  if exists('w:paren_hl_on') && w:paren_hl_on
    silent! call matchdelete(3)
    let w:paren_hl_on = 0
  endif
  " Avoid that we remove the popup menu.
  " Return when there are no colors (looks like the cursor jumps).
  if pumvisible() || (&t_Co < 8 && !has("gui_running"))
    return
  endif
  " Disable under various circumstances 
  if s:nohighlight()
    return
  endif
  " Get the character under the cursor and check if it's in 'matchpairs'.
  let c_lnum = line('.')
  let c_col = col('.')
  let before = 0
  let text = getline(c_lnum)
  let matches = matchlist(text, '\(.\)\=\%'.c_col.'c\(.\=\)')
  if empty(matches)
    let [c_before, c] = ['', '']
  else
    let [c_before, c] = matches[1:2]
  endif
  let plist = split(&matchpairs, '.\zs[:,]')
  let i = index(plist, c)
  if i < 0
    " not found, in Insert mode try character before the cursor
    if c_col > 1 && (mode() == 'i' || mode() == 'R')
      let before = strlen(c_before)
      let c = c_before
      let i = index(plist, c)
    endif
    if i < 0
      " not found, nothing to do
      return
    endif
  endif
  " Figure out the arguments for searchpairpos().
  if i % 2 == 0
    let s_flags = 'nW'
    let c2 = plist[i + 1]
  else
    let s_flags = 'nbW'
    let c2 = c
    let c = plist[i - 1]
  endif
  if c == '['
    let c = '\['
    let c2 = '\]'
  endif
  " Find the match.  When it was just before the cursor move it there for a moment.
  if before > 0
    let has_getcurpos = exists("*getcurpos")
    if has_getcurpos
      " getcurpos() is more efficient but doesn't exist before 7.4.313.
      let save_cursor = getcurpos()
    else
      let save_cursor = winsaveview()
    endif
    call cursor(c_lnum, c_col - before)
  endif

  " Build an expression that detects whether the current cursor position is in
  " certain syntax types (string, comment, etc.), for use as searchpairpos()'s skip argument.
  " We match "escape" for special items, such as lispEscapeSpecial.
  let s_skip = '!empty(filter(map(synstack(line("."), col(".")), ''synIDattr(v:val, "name")''), ' .
  \ '''v:val =~? "string\\|character\\|singlequote\\|escape\\|comment"''))'
  " If executing the expression determines that the cursor is currently in
  " one of the syntax types, then we want searchpairpos() to find the pair
  " within those syntax types (i.e., not skip).  Otherwise, the cursor is
  " outside of the syntax types and s_skip should keep its value so we skip any
  " matching pair inside the syntax types.
  execute 'if' s_skip '| let s_skip = 0 | endif'

  " Limit the search to lines visible in the window.
  let stoplinebottom = line('w$')
  let stoplinetop = line('w0')
  if i % 2 == 0
    let stopline = stoplinebottom
  else
    let stopline = stoplinetop
  endif

  " Limit the search time to 300 msec to avoid a hang on very long lines.
  " This fails when a timeout is not supported.
  if mode() == 'i' || mode() == 'R'
    let timeout = exists("b:matchparen_insert_timeout") ? b:matchparen_insert_timeout : g:matchparen_insert_timeout
  else
    let timeout = exists("b:matchparen_timeout") ? b:matchparen_timeout : g:matchparen_timeout
  endif
  try
    let [m_lnum, m_col] = searchpairpos(c, '', c2, s_flags, s_skip, stopline, timeout)
  catch /E118/
    " Can't use the timeout, restrict the stopline a bit more to avoid taking
    " a long time on closed folds and long lines.
    " The "viewable" variables give a range in which we can scroll while
    " keeping the cursor at the same position.
    " adjustedScrolloff accounts for very large numbers of scrolloff.
    let adjustedScrolloff = min([&scrolloff, (line('w$') - line('w0')) / 2])
    let bottom_viewable = min([line('$'), c_lnum + &lines - adjustedScrolloff - 2])
    let top_viewable = max([1, c_lnum-&lines+adjustedScrolloff + 2])
    " one of these stoplines will be adjusted below, but the current values are
    " minimal boundaries within the current window
    if i % 2 == 0
      if has("byte_offset") && has("syntax_items") && &smc > 0
  let stopbyte = min([line2byte("$"), line2byte(".") + col(".") + &smc * 2])
  let stopline = min([bottom_viewable, byte2line(stopbyte)])
      else
  let stopline = min([bottom_viewable, c_lnum + 100])
      endif
      let stoplinebottom = stopline
    else
      if has("byte_offset") && has("syntax_items") && &smc > 0
  let stopbyte = max([1, line2byte(".") + col(".") - &smc * 2])
  let stopline = max([top_viewable, byte2line(stopbyte)])
      else
  let stopline = max([top_viewable, c_lnum - 100])
      endif
      let stoplinetop = stopline
    endif
    let [m_lnum, m_col] = searchpairpos(c, '', c2, s_flags, s_skip, stopline)
  endtry

  if before > 0
    if has_getcurpos
      call setpos('.', save_cursor)
    else
      call winrestview(save_cursor)
    endif
  endif

  " If a match is found setup match highlighting.
  if m_lnum > 0 && m_lnum >= stoplinetop && m_lnum <= stoplinebottom 
    if exists('*matchaddpos')
      call matchaddpos('MatchParen', [[c_lnum, c_col - before], [m_lnum, m_col]], 10, 3)
    else
      exe '3match MatchParen /\(\%' . c_lnum . 'l\%' . (c_col - before) .
      \ 'c\)\|\(\%' . m_lnum . 'l\%' . m_col . 'c\)/'
    endif
    let w:paren_hl_on = 1
  endif
endfunction

"##############################################################################"
" Highlight matching matchit.vim groups on multiple lines
"  * Note it may be impossible to preserve the jumplist when pressing '%'; this generally
"    calls a function that jumps around to the matching delimiter, but according to :keepjumps
"    documentation, running :keepjumps func() on func that jumps around will not preserve jumplist
"  * Note the default '%' press with markdown files results in this weird annoying
"    delay that isn't really related to this plugin; added patch to exit the matching function
"    with markdown filetypes
"##############################################################################"
" Same highlighting as matchit
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
" Used this in an answer at: http://vi.stackexchange.com/q/8707/5229
function! s:get_match_lines(line) abort
  " Loop until `%` returns the original line number; abort if
  " input argument line is the *original* line
  " (1) the % operator keeps us on the same line, or
  " (2) the % operator doesn't return us to the same line after some nubmer of jumps
  let tolerance=10 "keep it small so don't get slowdowns
  let badbreak=1
  let linebefore=-1
  let lines = []
  let b:xyz = [] "FOR TESTING
  for jumpcommand in ['%', '%^'] "try both, depends which is more suitable
    execute "keepjumps normal! ".a:line."gg"
    " if jumpcommand=="%^" | echo "Trying alternate method." | endif
    while tolerance && linebefore != line('.')
      " Do *not* use normal!; need filetype specific maps of %
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
  " Return to original line no matter what, return list of lines to highlight
  " Documentation says keepjumps exe 'command' fails; must use exe 'keepjumps command'
  execute "keepjumps normal! ".a:line."gg"
  if badbreak
    " Better then echoerr because does not pause screen; see help info for echohl
    " echohl WarningMsg | echo "Failed to find match for line ".line('.')."." | echohl None
    echom "Failed to find match for line ".line('.')."."
    return [] "make above echo, not echom; probably slows shit down adding to messages list
  else
    return lines
  endif
endfunction
" Unmatch function
function! s:hl_matching_lines_clear() abort
  let b:hl_ranORcleared = 0
  silent! call matchdelete(12345)
  unlet! b:hl_last_line
endfunction
" The highlight group that's used for highlighting matched lines.  By
function! s:hl_matching_lines() abort
  let b:hl_ranORcleared = 1
  " Disable under various circumstances
  if s:nohighlight()
    call s:hl_matching_lines_clear()
    return
  endif
  " Do not re-run if cursor on same line
  if exists('b:hl_last_line') && b:hl_last_line == line('.')
    return
  endif
  let b:hl_last_line = line('.')
  " Save the window's state.
  let view = winsaveview()
  " Delete a previous match highlight. `12345` is used for the match ID.
  " It can be anything as long as it's unique.
  silent! call matchdelete(12345)
  " Try to get matching lines from the current cursor position.
  let lines = s:get_match_lines(view.lnum)
  " keepjumps let lines = s:get_match_lines(view.lnum)
  if empty(lines)
    " It's possible that the line has another matching line, but can't be
    " matched at the current column.  Move the cursor to column 1 to try
    " one more time.
    call cursor(view.lnum, 1)
    let lines = s:get_match_lines(view.lnum)
    " keepjumps let lines = s:get_match_lines(view.lnum)
  endif
  if len(lines)
    " Add the *current* line to the list; output of line-matching function doesn't do this
    call add(lines, view.lnum)
    if exists('*matchaddpos')
      " If matchaddpos() is availble, use it to highlight the lines since it's
      " faster than using a pattern in matchadd().
      call matchaddpos('MatchLine', lines, 0, 12345)
    else
      " Highlight the matching lines using the \%l atom.
      call matchadd('MatchLine', join(map(lines, '''\%''.v:val.''l'''), '\|'), 0, 12345)
    endif
  endif
  " Edit: save, for debugging
  let b:lines=lines
  " Restore the window's state.
  call winrestview(view)
endfunction
