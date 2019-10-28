"-----------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-09-20
" Various settings and macros for python files
" Includes a couple mappings for converting {'a':1} to a=1
"-----------------------------------------------------------------------------"
" Tab settings
setlocal tabstop=4 softtabstop=4 shiftwidth=4
" Run current script in shell
nnoremap <silent> <buffer> <C-z> :update<CR>:exec("!clear; set -x; python ".shellescape(@%))<CR><CR>
" Use period (.) as part of iskeyword
" Note: This actually triggers pythonNumberError syntax group to highlight numbers
" with period but no decimal places -- perhaps a good thing, because has poor readability.
setlocal iskeyword-=.
" New indent expression
setlocal indentexpr=s:pyindent(v:lnum)
" Builtin python ftplugin syntax option; these should be provided with VIM by default
let g:python_highlight_all = 1
" For pyDiction plugin
let g:pydiction_location = expand('~').'/.vim/plugged/Pydiction/complete-dict'

"------------------------------------------------------------------------------"
" Pydoc documentation command
" Couldn't really find equivalent tool in python-mode or jedi-vim and
" didn't like their builtin versions, so made this. Deciphers module aliases.
" Note: Works in all situations as long as module alias is followed by '.'
"------------------------------------------------------------------------------"
function! s:pydoc(...)
  " Look up either 1) word (with dots) under cursor or 2) passed argument.
  if a:0 && len(a:1) > 0
    let string = a:1
  else
    setlocal iskeyword+=.
    let string = expand('<cword>')
    setlocal iskeyword-=.
  endif
  " Translate first word according to list of common import aliases
  " Get aliases using system grep (which calls sytem grep, and is builtin)
  let space = "[ \t]" "space or literal tab (double quotes)
  let nonspace = "[^ \t]" "non-space
  let results1 = system("grep '".'^import\b'.space.'*'.nonspace.'*'.space.'*\bas\b'.space.'*\w*'."' ".@%)
  let results2 = split(results1, "\n") "older versions of vim can't write different type to same variable!
  let b:aliases = {} " helpful to add this to list
  for result in results2
    let alias = split(substitute(result, '^import\s*\(\S*\)\s*\<as\>\s*\(\w*\)', '\1:\2', ''), ":")
    if string =~ escape('^'.alias[1].'.', '.')
      let string = substitute(string, '^'.alias[1].'.', alias[0].'.', '')
      break
    endif
    let b:aliases[alias[1]] = alias[0]
  endfor
  " Get aliases using :vimgrep and loclists (dumb idea)
  " translate = {'plt':'matplotlib.pyplot', 'numpy':'np', 'xarray':'xr', 'pandas':'pd'}
  " call setloclist(0,[]) "set location list for current window (0) to empty (not necessary unless use lvimgrepadd)
  " lvimgrep /^import\>\s*\S*\s*\<as\>\s*\zs\w*/ % "add matches to loclist
  " Finally try calling pydoc
  " Note system() will fail because won't bring up interactie prompt
  exe '!clear; pydoc '.string
endfunction
command! -nargs=? PyDoc silent call <sid>pydoc(<q-args>) | redraw!
nnoremap <buffer> <silent> <Leader>p :call <sid>pydoc()<CR>:redraw!<CR>

"------------------------------------------------------------------------------"
" Easy conversion between key=value pairs and 'key':value dictionary entries
" Do son on current line, or within visual selection
"------------------------------------------------------------------------------"
function! s:kwtrans(mode) range
  " Will allow for non-line selections
  " First get columns
  let winview = winsaveview()
  if a:firstline == a:lastline
    let firstcol = 0
    let lastcol  = col('$')-2 " col('$') is location of newline char, and strings are zero-indexed
  else
    let firstcol = col("'<")-1 "cause strings are zero-indexed
    let lastcol  = col("'>")-1
  endif
  let fixed = []
  for line in range(a:firstline,a:lastline)
    " Annoying ugly block for getting visual selection
    " Want to *ignore* stuff not in selection, but on same line as
    " the start/end of selection, because it's more flexible
    let string = getline(line)
    let prefix = ''
    let suffix = ''
    if line == a:firstline && line == a:lastline
      let prefix = (firstcol >= 1 ? string[:firstcol-1] : '') " damn negative indexing makes this complicated
      let suffix = string[lastcol+1:]
      " let string = string[:lastcol] "just plain easier
      " let string = string[firstcol:]
      let string = string[firstcol:lastcol]
    elseif line == a:firstline
      let prefix = (firstcol >= 1 ? string[:firstcol-1] : '')
      let string = string[firstcol:]
    elseif line == a:lastline
      let suffix = string[lastcol+1:]
      let string = string[:lastcol]
    endif
    " Double check
    if len(matchstr(string,':'))>0 && len(matchstr(string,'-'))>0
      echom "Error: Ambiguous line." | return
    endif
    " Next finally start matching shit
    " Turn colons into equals
    " echo 'line:'.a:firstline.'-'.a:lastline.' col:'.firstcol.'-'.lastcol.' string:'.string.' prefix:'.prefix.' suffix:'.suffix | sleep 2
    if a:mode == 1 " kwargs to dictionary
      let string = substitute(string, '\<\ze\w\+\s*=', "'", 'g') "add leading quote first
      let string = substitute(string, '\>\ze\s*=', "'", 'g')
      let string = substitute(string, '=', ':', 'g')
    elseif a:mode == 0 " dictionary to kwargs
      let string = substitute(string, "\\>['\"]".'\ze\s*:', '', 'g') "remove trailing quote first
      let string = substitute(string, "['\"]\\<".'\ze\w\+\s*:', '', 'g')
      let string = substitute(string, ':', '=', 'g')
    endif
    let fixed  = fixed + [prefix.string.suffix]
  endfor
  " Replace lines with fixed text
  exe a:firstline.','a:lastline.'d'
  call append(a:firstline-1,fixed)
  call winrestview(winview)
endfunction
noremap <silent> <Plug>kw2dict :call <sid>kwtrans(1)<CR>:call repeat#set("\<Plug>kw2dict")<CR>
noremap <silent> <Plug>dict2kw :call <sid>kwtrans(0)<CR>:call repeat#set("\<Plug>dict2kw")<CR>
map cd <Plug>kw2dict
map cD <Plug>dict2kw

"------------------------------------------------------------------------------
" Next: Stuff copied from a different plugin
" Todo: Figure out where the hell I downloaded this from.
" Line matching across if/endif, while/finish, et. cetera
" Default matchit fails completely, which is why we have this
"------------------------------------------------------------------------------
" First the remaps
" % for if -> elif -> else -> if, g% for else -> elif -> if -> else
nnoremap <buffer> <silent> %  :<C-U>call  <sid>pymatch('%','n') <CR>
vnoremap <buffer> <silent> %  :<C-U>call  <sid>pymatch('%','v') <CR>m'gv``
onoremap <buffer> <silent> %  v:<C-U>call <sid>pymatch('%','o') <CR>
nnoremap <buffer> <silent> g% :<C-U>call  <sid>pymatch('g%','n') <CR>
vnoremap <buffer> <silent> g% :<C-U>call  <sid>pymatch('g%','v') <CR>m'gv``
onoremap <buffer> <silent> g% v:<C-U>call <sid>pymatch('g%','o') <CR>
" Move to the start ([%) or end (]%) of the current block.
nnoremap <buffer> <silent> [% :<C-U>call  <sid>pymatch('[%', 'n') <CR>
vnoremap <buffer> <silent> [% :<C-U>call  <sid>pymatch('[%','v') <CR>m'gv``
onoremap <buffer> <silent> [% v:<C-U>call <sid>pymatch('[%', 'o') <CR>
nnoremap <buffer> <silent> ]% :<C-U>call  <sid>pymatch(']%',  'n') <CR>
vnoremap <buffer> <silent> ]% :<C-U>call  <sid>pymatch(']%','v') <CR>m'gv``
onoremap <buffer> <silent> ]% v:<C-U>call <sid>pymatch(']%',  'o') <CR>
" The rest of the file needs to be :sourced only once per session.
" if exists("s:loaded_functions") || &cp
"   finish
" endif
" let s:loaded_functions = 1

" One problem with matching in Python is that so many parts are optional.
" I deal with this by matching on any known key words at the start of the
" line, if they have the same indent.
" Recognize try, except, finally and if, elif, else .
" keywords that start a block:
" One problem with matching in Python is that so many parts are optional.
let s:ini1 = 'try\|if'
" These are special, because the matching words may not have the same indent:
let s:ini2 = 'for\|while' 
" keywords that continue or end a block:
let s:tail1 = 'except\|finally'
let s:tail1 = s:tail1 . '\|elif\|else'
" These go with s:ini2 :
let s:tail2 = 'break\|continue'
" all keywords:
let s:all1 = s:ini1 . '\|' . s:tail1
let s:all2 = s:ini2 . '\|' . s:tail2
fun! s:pymatch(type, mode) range
  " I have to do this before the :keepjumps normal gv...
  let cnt = v:count1
  " If this function was called from Visual mode, make sure that the cursor
  " is at the correct end of the Visual range:
  if a:mode == "v"
    execute "keepjumps normal! gv\<Esc>"
  endif
  " Use default behavior if called as % with a count.
  if a:type == "%" && v:count
    exe "keepjumps normal! " . v:count . "%"
    return s:pymatch_cleanup('', a:mode)
  endif

  " Do not change these:  needed for s:pymatch_cleanup()
  let s:startline = line(".")
  let s:startcol = col(".")
  " In case we start on a comment line, ...
  if a:type == '[%' || a:type == ']%'
    let currline = s:pymatch_noncomment(+1, s:startline-1)
  else
    let currline = s:startline
  endif
  let startindent = indent(currline)
  " Set a mark before jumping.
  keepjumps normal! m'

  " If called as [%, find the start of the current block.
  " If called as ]%, find the end of the current block.
  if a:type == '[%' || a:type == ']%'
    while cnt > 0
      let currline = (a:type == '[%') ?
            \ s:pymatch_startofblock(currline) : s:pymatchh_endofblock(currline)
      let cnt = cnt - 1
    endwhile
    execute currline
    return s:pymatch_cleanup('', a:mode, '$')
  endif

  " If called as % or g%, decide whether to bail out.
  if a:type == '%' || a:type == 'g%'
    let text = getline(currline)
    if strpart(text, 0, col(".")) =~ '\S\s'
          \ || text !~ '^\s*\%(' . s:all1 . '\|' . s:all2 . '\)'
      " cursor not on the first WORD or no keyword so bail out
      if a:type == '%'
        keepjumps normal! %
      endif
      return s:pymatch_cleanup('', a:mode)
    endif
    " If it matches s:all2, we need to find the "for" or "while".
    if text =~ '^\s*\%(' . s:all2 . '\)'
      let topline = currline
      while getline(topline) !~ '^\s*\%(' . s:ini2 . '\)'
        let temp = s:pymatch_startofblock(topline)
        if temp == topline " there is no enclosing block.
          return s:pymatch_cleanup('', a:mode)
        endif
        let topline = temp
      endwhile
      let topindent = indent(topline)
    endif
  endif

  " If called as %, look down for "elif" or "else" or up for "if".
  if a:type == '%' && text =~ '^\s*\%('. s:all1 .'\)'
    let next = s:pymatch_noncomment(+1, currline)
    while next > 0 && indent(next) > startindent
      let next = s:pymatch_noncomment(+1, next)
    endwhile
    if next == 0 || indent(next) < startindent
          \ || getline(next) !~ '^\s*\%(' . s:tail1 . '\)'
      " There are no "tail1" keywords below startline in this block.  Go to
      " the start of the block.
      let next = (text =~ '^\s*\%(' . s:ini1 . '\)') ?
            \ currline : s:pymatch_startofblock(currline) 
    endif
    execute next
    return s:pymatch_cleanup('', a:mode, '$')
  endif

  " If called as %, look down for "break" or "continue" or up for
  " "for" or "while".
  if a:type == '%' && text =~ '^\s*\%(' . s:all2 . '\)'
    let next = s:pymatch_noncomment(+1, currline)
    while next > 0 && indent(next) > topindent
          \ && getline(next) !~ '^\s*\%(' . s:tail2 . '\)'
      " Skip over nested "for" or "while" blocks:
      if getline(next) =~ '^\s*\%(' . s:ini2 . '\)'
        let next = s:pymatchh_endofblock(next)
      endif
      let next = s:pymatch_noncomment(+1, next)
    endwhile
    if indent(next) > topindent && getline(next) =~ '^\s*\%(' . s:tail2 . '\)'
      execute next
    else " There are no "tail2" keywords below v:startline, so go to topline.
      execute topline
    endif
    return s:pymatch_cleanup('', a:mode, '$')
  endif

  " If called as g%, look up for "if" or "elif" or "else" or down for any.
  if a:type == 'g%' && text =~ '^\s*\%('. s:all1 .'\)'
    " If we started at the top of the block, go down to the end of the block.
    if text =~ '^\s*\(' . s:ini1 . '\)'
      let next = s:pymatchh_endofblock(currline)
    else
      let next = s:pymatch_noncomment(-1, currline)
    endif
    while next > 0 && indent(next) > startindent
      let next = s:pymatch_noncomment(-1, next)
    endwhile
    if indent(next) == startindent && getline(next) =~ '^\s*\%('.s:all1.'\)'
      execute next
    endif
    return s:pymatch_cleanup('', a:mode, '$')
  endif

  " If called as g%, look up for "for" or "while" or down for any.
  if a:type == 'g%' && text =~ '^\s*\%(' . s:all2 . '\)'
    " Start at topline .  If we started on a "for" or "while" then topline is
    " the same as currline, and we want the last "break" or "continue" in the
    " block.  Otherwise, we want the last one before currline.
    let botline = (topline == currline) ? line("$") + 1 : currline
    let currline = topline
    let next = s:pymatch_noncomment(+1, currline)
    while next < botline && indent(next) > topindent
      if getline(next) =~ '^\s*\%(' . s:tail2 . '\)'
        let currline = next
      elseif getline(next) =~ '^\s*\%(' . s:ini2 . '\)'
        " Skip over nested "for" or "while" blocks:
        let next = s:pymatchh_endofblock(next)
      endif
      let next = s:pymatch_noncomment(+1, next)
    endwhile
    execute currline
    return s:pymatch_cleanup('', a:mode, '$')
  endif

endfun

" Return the line number of the next non-comment, or 0 if there is none.
" Start at the current line unless the optional second argument is given.
" The direction is specified by a:inc (normally +1 or -1 ;
" no test for a:inc == 0, which may lead to an infinite loop).
fun! s:pymatch_noncomment(inc, ...)
  if a:0 > 0
    let next = a:1 + a:inc
  else
    let next = line(".") + a:inc
  endif
  while 0 < next && next <= line("$")
    if getline(next) !~ '^\s*\(#\|$\)'
      return next
    endif
    let next = next + a:inc
  endwhile
  return 0  " If the while loop finishes, we fell off the end of the file.
endfun

" Return the line number of the top of the block containing Line a:start .
" For most lines, this is the first previous line with smaller indent.
" For lines starting with "except", "finally", "elif", or "else", this is the
" first previous line starting with "try" or "if".
fun! s:pymatch_startofblock(start)
  let startindent = indent(a:start)
  let tailflag = (getline(a:start) =~ '^\s*\(' . s:tail1 . '\)')
  let prevline = s:pymatch_noncomment(-1, a:start)
  while prevline > 0
    if indent(prevline) < startindent ||
          \ tailflag && indent(prevline) == startindent &&
          \ getline(prevline) =~ '^\s*\(' . s:ini1 . '\)'
      " Found the start of block!
      return prevline
    endif
    let prevline = s:pymatch_noncomment(-1, prevline)
  endwhile
  " If the loop completes, then s:pymatch_noncomment() returned 0, so we are at the
  " top.
  return a:start
endfun

" Return the line number of the end of the block containing Line a:start .
" For most lines, this is the line before the next line with smaller indent.
" For lines that begin a block, go to the end of that block, with special
" treatment for "if" and "try" blocks.
fun! s:pymatchh_endofblock(start)
  let startindent = indent(a:start)
  let currline = a:start
  let nextline = s:pymatch_noncomment(+1, currline)
  let startofblock = (indent(nextline) > startindent) ||
        \ getline(currline) =~ '^\s*\(' . s:ini1 . '\)'
  while  nextline > 0
    if indent(nextline) < startindent ||
          \ startofblock && indent(nextline) == startindent &&
          \ getline(nextline) !~ '^\s*\(' . s:tail1 . '\)'
      break
    endif
    let currline = nextline
    let nextline = s:pymatch_noncomment(+1, currline)
  endwhile
  " nextline is in the next block or after EOF, so return currline:
  return currline
endfun

" Restore options and do some special handling for Operator-pending mode.
" The optional argument is the tail of the matching group.
fun! s:pymatch_cleanup(options, mode, ...)
  if strlen(a:options)
    execute "set" a:options
  endif
  " Open folds, if appropriate.
  if a:mode != "o"
    if &foldopen =~ "percent"
      keepjumps normal! zv
    endif
    " In Operator-pending mode, we want to include the whole match
    " (for example, d%).
    " This is only a problem if we end up moving in the forward direction.
  elseif s:startline < line(".") ||
        \ s:startline == line(".") && s:startcol < col(".")
    if a:0
      " If we want to include the whole line then a:1 should be '$' .
      silent! call search(a:1)
    endif
  endif " a:mode != "o"
  return 0
endfun

"------------------------------------------------------------------------------"
" Next: Stuff copied from python-mode
" Indentation script first
" Just improves indentation.
"------------------------------------------------------------------------------"
function! s:pyindent(lnum)
  " First line has indent 0
  if a:lnum == 1
    return 0
  endif
  " If we can find an open parenthesis/bracket/brace, line up with it.
  call cursor(a:lnum, 1)
  let parlnum = s:pymode_searchparenspair()
  if parlnum > 0
    let parcol = col('.')
    let closing_paren = match(getline(a:lnum), '^\s*[])}]') != -1
    if match(getline(parlnum), '[([{]\s*$', parcol - 1) != -1
      if closing_paren
        return indent(parlnum)
      else
        return indent(parlnum) + &shiftwidth
      endif
    else
      return parcol
    endif
  endif
  " Examine this line
  let thisline = getline(a:lnum)
  let thisindent = indent(a:lnum)
  " If the line starts with 'elif' or 'else', line up with 'if' or 'elif'
  if thisline =~ '^\s*\(elif\|else\)\ > '
    let bslnum = s:pymode_blockstarter(a:lnum, '^\s*\(if\|elif\)\ > ')
    if bslnum > 0
      return indent(bslnum)
    else
      return -1
    endif
  endif
  " If the line starts with 'except' or 'finally', line up with 'try'
  " or 'except'
  if thisline =~ '^\s*\(except\|finally\)\ > '
    let bslnum = s:pymode_blockstarter(a:lnum, '^\s*\(try\|except\)\ > ')
    if bslnum > 0
      return indent(bslnum)
    else
      return -1
    endif
  endif
  " Examine previous line
  let plnum = a:lnum - 1
  let pline = getline(plnum)
  let sslnum = s:pymode_statementstart(plnum)
  " If the previous line is blank, keep the same indentation
  if pline =~ '^\s*$'
    return -1
  endif
  " If this line is explicitly joined, find the first indentation that is a
  " multiple of four and will distinguish itself from next logical line.
  if pline =~ '\\$'
    let maybe_indent = indent(sslnum) + &sw
    let control_structure = '^\s*\(if\|while\|for\s.*\sin\|except\)\s*'
    if match(getline(sslnum), control_structure) != -1
      " add extra indent to avoid E125
      return maybe_indent + &sw
    else
      " control structure not found
      return maybe_indent
    endif
  endif
  " If the previous line ended with a colon and is not a comment, indent
  " relative to statement start.
  if pline =~ '^[^#]*:\s*\(#.*\)\?$'
    return indent(sslnum) + &sw
  endif
  " If the previous line was a stop-execution statement or a pass
  if getline(sslnum) =~ '^\s*\(break\|continue\|raise\|return\|pass\)\ > '
    " See if the user has already dedented
    if indent(a:lnum) > indent(sslnum) - &sw
      " If not, recommend one dedent
      return indent(sslnum) - &sw
    endif
    " Otherwise, trust the user
    return -1
  endif
  " In all other cases, line up with the start of the previous statement.
  return indent(sslnum)
endfunction

" Find backwards the closest open parenthesis/bracket/brace.
function! s:pymode_searchparenspair() " {{{
  let line = line('.')
  let col = col('.')
  " Skip strings and comments and don't look too far
  let skip = "line('.') < " . (line - 50) . " ? dummy :" .
        \ 'synIDattr(synID(line("."), col("."), 0), "name") =~? ' .
        \ '"string\\|comment\\|doctest"'
  " Search for parentheses
  call cursor(line, col)
  let parlnum = searchpair('(', '', ')', 'bW', skip)
  let parcol = col('.')
  " Search for brackets
  call cursor(line, col)
  let par2lnum = searchpair('\[', '', '\]', 'bW', skip)
  let par2col = col('.')
  " Search for braces
  call cursor(line, col)
  let par3lnum = searchpair('{', '', '}', 'bW', skip)
  let par3col = col('.')
  " Get the closest match
  if par2lnum > parlnum || (par2lnum == parlnum && par2col > parcol)
    let parlnum = par2lnum
    let parcol = par2col
  endif
  if par3lnum > parlnum || (par3lnum == parlnum && par3col > parcol)
    let parlnum = par3lnum
    let parcol = par3col
  endif
  " Put the cursor on the match
  if parlnum > 0
    call cursor(parlnum, parcol)
  endif
  return parlnum
endfunction " }}}

" Find the start of a multi-line statement
function! s:pymode_statementstart(lnum) " {{{
  let lnum = a:lnum
  while 1
    if getline(lnum - 1) =~ '\\$'
      let lnum = lnum - 1
    else
      call cursor(lnum, 1)
      let maybe_lnum = s:pymode_searchparenspair()
      if maybe_lnum < 1
        return lnum
      else
        let lnum = maybe_lnum
      endif
    endif
  endwhile
endfunction " }}}

" Find the block starter that matches the current line
function! s:pymode_blockstarter(lnum, block_start_re) " {{{
  let lnum = a:lnum
  let maxindent = 10000       " whatever
  while lnum > 1
    let lnum = prevnonblank(lnum - 1)
    if indent(lnum) < maxindent
      if getline(lnum) =~ a:block_start_re
        return lnum
      else
        let maxindent = indent(lnum)
        " It's not worth going further if we reached the top level
        if maxindent == 0
          return -1
        endif
      endif
    endif
  endwhile
  return -1
endfunction " }}}

"------------------------------------------------------------------------------"
" Now class/module block support
" Includes support for blocks like functions and classes
" Since idetools.vim uses ctags for [[ and ]] motion those maps aren't necessary
" Todo: The motion commands seem to be broken, not that we need them
" very often. Usually just want to select stuff.
"------------------------------------------------------------------------------"
" Motion remaps
" nnoremap <buffer> ]]  :<C-U>call s:pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
" nnoremap <buffer> [[  :<C-U>call <sid>pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
nnoremap <buffer> ]C  :<C-U>call <sid>pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
nnoremap <buffer> [C  :<C-U>call <sid>pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
nnoremap <buffer> ]F  :<C-U>call <sid>pymode_move('^<Bslash>s*def<Bslash>s', '')<CR>
nnoremap <buffer> [F  :<C-U>call <sid>pymode_move('^<Bslash>s*def<Bslash>s', 'b')<CR>

" onoremap <buffer> ]]  :<C-U>call <sid>pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
" onoremap <buffer> [[  :<C-U>call <sid>pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
onoremap <buffer> ]C  :<C-U>call <sid>pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
onoremap <buffer> [C  :<C-U>call <sid>pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
onoremap <buffer> ]F  :<C-U>call <sid>pymode_move('^<Bslash>s*def<Bslash>s', '')<CR>
onoremap <buffer> [F  :<C-U>call <sid>pymode_move('^<Bslash>s*def<Bslash>s', 'b')<CR>

" vnoremap <buffer> ]]  :call <sid>pymode_vmove('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
" vnoremap <buffer> [[  :call <sid>pymode_vmove('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
vnoremap <buffer> ]C  :call <sid>pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', '')<CR>
vnoremap <buffer> [C  :call <sid>pymode_move('<Bslash>v^(class<bar>def)<Bslash>s', 'b')<CR>
vnoremap <buffer> ]F  :call <sid>pymode_vmove('^<Bslash>s*def<Bslash>s', '')<CR>
vnoremap <buffer> [F  :call <sid>pymode_vmove('^<Bslash>s*def<Bslash>s', 'b')<CR>

" Text objects
onoremap <buffer> C  :<C-U>call <sid>pymode_select('^<Bslash>s*class<Bslash>s', 0)<CR>
onoremap <buffer> aC :<C-U>call <sid>pymode_select('^<Bslash>s*class<Bslash>s', 0)<CR>
onoremap <buffer> iC :<C-U>call <sid>pymode_select('^<Bslash>s*class<Bslash>s', 1)<CR>
vnoremap <buffer> aC :<C-U>call <sid>pymode_select('^<Bslash>s*class<Bslash>s', 0)<CR>
vnoremap <buffer> iC :<C-U>call <sid>pymode_select('^<Bslash>s*class<Bslash>s', 1)<CR>

onoremap <buffer> F  :<C-U>call <sid>pymode_select('^<Bslash>s*def<Bslash>s', 0)<CR>
onoremap <buffer> aF :<C-U>call <sid>pymode_select('^<Bslash>s*def<Bslash>s', 0)<CR>
onoremap <buffer> iF :<C-U>call <sid>pymode_select('^<Bslash>s*def<Bslash>s', 1)<CR>
vnoremap <buffer> aF :<C-U>call <sid>pymode_select('^<Bslash>s*def<Bslash>s', 0)<CR>
vnoremap <buffer> iF :<C-U>call <sid>pymode_select('^<Bslash>s*def<Bslash>s', 1)<CR>

" Python-mode motion functions
fun! s:pymode_move(pattern, flags, ...) " {{{
  let cnt = v:count1 - 1
  let [line, column] = searchpos(a:pattern, a:flags . 'sW')
  let indent = indent(line)
  while cnt && line
    let [line, column] = searchpos(a:pattern, a:flags . 'W')
    if indent(line) == indent
      let cnt = cnt - 1
    endif
  endwhile
  return [line, column]
endfunction " }}}

fun! s:pymode_vmove(pattern, flags) range " {{{
  call cursor(a:lastline, 0)
  let end = s:pymode_move(a:pattern, a:flags)
  call cursor(a:firstline, 0)
  normal! v
  call cursor(end)
endfunction " }}}

fun! s:pos_le(pos1, pos2) " {{{
  return ((a:pos1[0] < a:pos2[0]) || (a:pos1[0] == a:pos2[0] && a:pos1[1] <= a:pos2[1]))
endfunction " }}}

fun! s:pymode_select(pattern, inner) " {{{
  let cnt = v:count1 - 1
  let orig = getpos('.')[1:2]
  let snum = s:pymode_blockstart(orig[0], a:pattern)
  if getline(snum) !~ a:pattern
    return 0
  endif
  let enum = s:pymode_blockend(snum, indent(snum))
  while cnt
    let lnum = search(a:pattern, 'nW')
    if lnum
      let enum = s:pymode_blockend(lnum, indent(lnum))
      call cursor(enum, 1)
    endif
    let cnt = cnt - 1
  endwhile
  if s:pos_le([snum, 0], orig) && s:pos_le(orig, [enum, 1])
    if a:inner
      let snum = snum + 1
      let enum = prevnonblank(enum)
    endif

    call cursor(snum, 1)
    normal! v
    call cursor(enum, len(getline(enum)))
  endif
endfunction " }}}

fun! s:pymode_blockstart(lnum, ...) " {{{
  let pattern = a:0 ? a:1 : '^\s*\(@\|class\s.*:\|def\s\)'
  let lnum = a:lnum + 1
  let indent = 100
  while lnum
    let lnum = prevnonblank(lnum - 1)
    let test = indent(lnum)
    let line = getline(lnum)
    if line =~ '^\s*#' " Skip comments
      continue
    elseif !test " Zero-level regular line
      return lnum
    elseif test >= indent " Skip deeper or equal lines
      continue
      " Indent is strictly less at this point: check for def/class
    elseif line =~ pattern && line !~ '^\s*@'
      return lnum
    endif
    let indent = indent(lnum)
  endwhile
  return 0
endfunction " }}}

fun! s:pymode_blockend(lnum, ...) " {{{
  let indent = a:0 ? a:1 : indent(a:lnum)
  let lnum = a:lnum
  while lnum
    let lnum = nextnonblank(lnum + 1)
    if getline(lnum) =~ '^\s*#' | continue
    elseif lnum && indent(lnum) <= indent
      return lnum - 1
    endif
  endwhile
  return line('$')
endfunction " }}}
" vim: fdm=marker:fdl=0
