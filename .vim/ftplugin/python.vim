"------------------------------------------------------------------------------"
"Various settings and macros for python files
"Includes a couple nice features for converting {'a':1} to a=1 
"easily; can do this line by line, or for a whole dictionary.
"------------------------------------------------------------------------------"
"Tab settings; normally keep it to just 2 spaces
setlocal tabstop=4 softtabstop=4 shiftwidth=4
"Run current script in shell
nnoremap <silent> <buffer> <C-b> :w<CR>:exe '!clear; set -x; python '.shellescape(expand('%:p'))<CR>
"Builtin python ftplugin syntax option; these should be provided with VIM by default
let g:python_highlight_all=1
"Convert key=value to 'key':value, and vice versa, on current line or within selection
function! s:kwtrans(mode) range "For searches with :normal command, see:
  "Will allow for non-line selections
  "First get columns
  let winview=winsaveview()
  if a:firstline==a:lastline
    let firstcol = 0
    let lastcol  = col('$')-2 "col('$') is location of newline char, and strings are zero-indexed
  else
    let firstcol = col("'<")-1 "cause strings are zero-indexed
    let lastcol  = col("'>")-1
  endif
  let fixed=[]
  for line in range(a:firstline,a:lastline)
    "Annoying ugly block for getting visual selection
    "Want to *ignore* stuff not in selection, but on same line as
    "the start/end of selection, because it's more flexible
    let string = getline(line)
    let prefix = ''
    let suffix = ''
    if line==a:firstline && line==a:lastline
      let prefix = (firstcol>=1 ? string[:firstcol-1] : '') "damn negative indexing makes this complicated
      let suffix = string[lastcol+1:]
      let string = string[firstcol:lastcol] "just plain easier
    elseif line==a:firstline
      let prefix = (firstcol>=1 ? string[:firstcol-1] : '')
      let string = string[firstcol:]
    elseif line==a:lastline
      let suffix = string[lastcol+1:]
      let string = string[:lastcol]
    endif
    "Double check
    if len(matchstr(string,':'))>0 && len(matchstr(string,'-'))>0
      echom "Error: Ambiguous line." | return
    endif
    "Next finally start matching shit
    "Turn colons into equals
    " echo 'line:'.a:firstline.'-'.a:lastline.' col:'.firstcol.'-'.lastcol.' string:'.string.' prefix:'.prefix.' suffix:'.suffix | sleep 2
    if a:mode==1 "kwargs to dictionary
      let string = substitute(string, '\<\ze\w\+\s*=', "'", 'g') "add leading quote first
      let string = substitute(string, '\>\ze\s*=', "'", 'g')
      let string = substitute(string, '=', ':', 'g')
    elseif a:mode==0 "dictionary to kwargs
      let string = substitute(string, "\\>['\"]".'\ze\s*:', '', 'g') "remove trailing quote first
      let string = substitute(string, "['\"]\\<".'\ze\w\+\s*:', '', 'g')
      let string = substitute(string, ':', '=', 'g')
    endif
    let fixed  = fixed + [prefix.string.suffix]
  endfor
  "Replace lines with fixed text
  exe a:firstline.','a:lastline.'d'
  call append(a:firstline-1,fixed)
  call winrestview(winview)
endfunction
noremap <silent> <Plug>kw2dict :call <sid>kwtrans(1)<CR>:call repeat#set("\<Plug>kw2dict")<CR>
noremap <silent> <Plug>dict2kw :call <sid>kwtrans(0)<CR>:call repeat#set("\<Plug>dict2kw")<CR>
map cd <Plug>kw2dict
map cD <Plug>dict2kw

"------------------------------------------------------------------------------
" Matching pairs in python; default matchit plugin fails completely, so below
" defines useful PyMatch function
" TODO: Figure out where the hell I downloaded this from.
"------------------------------------------------------------------------------
" % for if -> elif -> else -> if, g% for else -> elif -> if -> else
nnoremap <buffer> <silent> %  :<C-U>call <SID>PyMatch('%','n') <CR>
vnoremap <buffer> <silent> %  :<C-U>call <SID>PyMatch('%','v') <CR>m'gv``
onoremap <buffer> <silent> %  v:<C-U>call <SID>PyMatch('%','o') <CR>
nnoremap <buffer> <silent> g% :<C-U>call <SID>PyMatch('g%','n') <CR>
vnoremap <buffer> <silent> g% :<C-U>call <SID>PyMatch('g%','v') <CR>m'gv``
onoremap <buffer> <silent> g% v:<C-U>call <SID>PyMatch('g%','o') <CR>
" Move to the start ([%) or end (]%) of the current block.
nnoremap <buffer> <silent> [% :<C-U>call <SID>PyMatch('[%', 'n') <CR>
vnoremap <buffer> <silent> [% :<C-U>call <SID>PyMatch('[%','v') <CR>m'gv``
onoremap <buffer> <silent> [% v:<C-U>call <SID>PyMatch('[%', 'o') <CR>
nnoremap <buffer> <silent> ]% :<C-U>call <SID>PyMatch(']%',  'n') <CR>
vnoremap <buffer> <silent> ]% :<C-U>call <SID>PyMatch(']%','v') <CR>m'gv``
onoremap <buffer> <silent> ]% v:<C-U>call <SID>PyMatch(']%',  'o') <CR>
" The rest of the file needs to be :sourced only once per session.
if exists("s:loaded_functions") || &cp
  finish
endif
let s:loaded_functions = 1

"------------------------------------------------------------------------------"
" One problem with matching in Python is that so many parts are optional.
" I deal with this by matching on any known key words at the start of the
" line, if they have the same indent.
" Recognize try, except, finally and if, elif, else .
" keywords that start a block:
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
fun! s:PyMatch(type, mode) range
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
    return s:CleanUp('', a:mode)
  endif

  " Do not change these:  needed for s:CleanUp()
  let s:startline = line(".")
  let s:startcol = col(".")
  " In case we start on a comment line, ...
  if a:type == '[%' || a:type == ']%'
    let currline = s:NonComment(+1, s:startline-1)
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
    \ s:StartOfBlock(currline) : s:EndOfBlock(currline)
      let cnt = cnt - 1
    endwhile
    execute currline
    return s:CleanUp('', a:mode, '$')
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
      return s:CleanUp('', a:mode)
    endif
    " If it matches s:all2, we need to find the "for" or "while".
    if text =~ '^\s*\%(' . s:all2 . '\)'
      let topline = currline
      while getline(topline) !~ '^\s*\%(' . s:ini2 . '\)'
let temp = s:StartOfBlock(topline)
if temp == topline " there is no enclosing block.
  return s:CleanUp('', a:mode)
endif
let topline = temp
      endwhile
      let topindent = indent(topline)
    endif
  endif

  " If called as %, look down for "elif" or "else" or up for "if".
  if a:type == '%' && text =~ '^\s*\%('. s:all1 .'\)'
    let next = s:NonComment(+1, currline)
    while next > 0 && indent(next) > startindent
      let next = s:NonComment(+1, next)
    endwhile
    if next == 0 || indent(next) < startindent
  \ || getline(next) !~ '^\s*\%(' . s:tail1 . '\)'
      " There are no "tail1" keywords below startline in this block.  Go to
      " the start of the block.
      let next = (text =~ '^\s*\%(' . s:ini1 . '\)') ?
    \ currline : s:StartOfBlock(currline) 
    endif
    execute next
    return s:CleanUp('', a:mode, '$')
  endif

  " If called as %, look down for "break" or "continue" or up for
  " "for" or "while".
  if a:type == '%' && text =~ '^\s*\%(' . s:all2 . '\)'
    let next = s:NonComment(+1, currline)
    while next > 0 && indent(next) > topindent
  \ && getline(next) !~ '^\s*\%(' . s:tail2 . '\)'
      " Skip over nested "for" or "while" blocks:
      if getline(next) =~ '^\s*\%(' . s:ini2 . '\)'
let next = s:EndOfBlock(next)
      endif
      let next = s:NonComment(+1, next)
    endwhile
    if indent(next) > topindent && getline(next) =~ '^\s*\%(' . s:tail2 . '\)'
      execute next
    else " There are no "tail2" keywords below v:startline, so go to topline.
      execute topline
    endif
    return s:CleanUp('', a:mode, '$')
  endif

  " If called as g%, look up for "if" or "elif" or "else" or down for any.
  if a:type == 'g%' && text =~ '^\s*\%('. s:all1 .'\)'
    " If we started at the top of the block, go down to the end of the block.
    if text =~ '^\s*\(' . s:ini1 . '\)'
      let next = s:EndOfBlock(currline)
    else
      let next = s:NonComment(-1, currline)
    endif
    while next > 0 && indent(next) > startindent
      let next = s:NonComment(-1, next)
    endwhile
    if indent(next) == startindent && getline(next) =~ '^\s*\%('.s:all1.'\)'
      execute next
    endif
    return s:CleanUp('', a:mode, '$')
  endif

  " If called as g%, look up for "for" or "while" or down for any.
  if a:type == 'g%' && text =~ '^\s*\%(' . s:all2 . '\)'
    " Start at topline .  If we started on a "for" or "while" then topline is
    " the same as currline, and we want the last "break" or "continue" in the
    " block.  Otherwise, we want the last one before currline.
    let botline = (topline == currline) ? line("$") + 1 : currline
    let currline = topline
    let next = s:NonComment(+1, currline)
    while next < botline && indent(next) > topindent
      if getline(next) =~ '^\s*\%(' . s:tail2 . '\)'
let currline = next
      elseif getline(next) =~ '^\s*\%(' . s:ini2 . '\)'
" Skip over nested "for" or "while" blocks:
let next = s:EndOfBlock(next)
      endif
      let next = s:NonComment(+1, next)
    endwhile
    execute currline
    return s:CleanUp('', a:mode, '$')
  endif

endfun

"------------------------------------------------------------------------------"
" Return the line number of the next non-comment, or 0 if there is none.
" Start at the current line unless the optional second argument is given.
" The direction is specified by a:inc (normally +1 or -1 ;
" no test for a:inc == 0, which may lead to an infinite loop).
fun! s:NonComment(inc, ...)
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

"------------------------------------------------------------------------------"
" Return the line number of the top of the block containing Line a:start .
" For most lines, this is the first previous line with smaller indent.
" For lines starting with "except", "finally", "elif", or "else", this is the
" first previous line starting with "try" or "if".
fun! s:StartOfBlock(start)
  let startindent = indent(a:start)
  let tailflag = (getline(a:start) =~ '^\s*\(' . s:tail1 . '\)')
  let prevline = s:NonComment(-1, a:start)
  while prevline > 0
    if indent(prevline) < startindent ||
  \ tailflag && indent(prevline) == startindent &&
  \ getline(prevline) =~ '^\s*\(' . s:ini1 . '\)'
      " Found the start of block!
      return prevline
    endif
    let prevline = s:NonComment(-1, prevline)
  endwhile
  " If the loop completes, then s:NonComment() returned 0, so we are at the
  " top.
  return a:start
endfun

"------------------------------------------------------------------------------"
" Return the line number of the end of the block containing Line a:start .
" For most lines, this is the line before the next line with smaller indent.
" For lines that begin a block, go to the end of that block, with special
" treatment for "if" and "try" blocks.
fun! s:EndOfBlock(start)
  let startindent = indent(a:start)
  let currline = a:start
  let nextline = s:NonComment(+1, currline)
  let startofblock = (indent(nextline) > startindent) ||
\ getline(currline) =~ '^\s*\(' . s:ini1 . '\)'
  while  nextline > 0
    if indent(nextline) < startindent ||
  \ startofblock && indent(nextline) == startindent &&
  \ getline(nextline) !~ '^\s*\(' . s:tail1 . '\)'
      break
    endif
    let currline = nextline
    let nextline = s:NonComment(+1, currline)
  endwhile
  " nextline is in the next block or after EOF, so return currline:
  return currline
endfun

"------------------------------------------------------------------------------"
" Restore options and do some special handling for Operator-pending mode.
" The optional argument is the tail of the matching group.
fun! s:CleanUp(options, mode, ...)
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
"let &cpo = s:save_cpo
" vim:sts=2:sw=2:ff=unix:
