"-----------------------------------------------------------------------------"
" Python indenting. Adapted from jeetsukumaran/vim-python-indent-black  {{{1
"-----------------------------------------------------------------------------"
" Initial stuff
" NOTE: Using filetype detect unsets b:did_indent
if exists('b:did_indent')
  finish
endif
let b:did_indent = 1
let s:delim1 = '(\|{\|\['
let s:delim2 = ')\|}\|\]'

" Configure vim settings
" NOTE: Here 'undo_indent' restores default settings after disabling filetype
let b:undo_indent = 'setl ai< inde< indk< lisp<'
setlocal nolisp  " make sure lisp indenting doesn't supersede us
setlocal autoindent  " indentexpr isn't much help otherwise
setlocal indentexpr=GetPythonIndent(v:lnum)
setlocal indentkeys+=<:>,=elif,=except

" Remove outdated settings
" NOTE: Previously used evals but now use multiples of shiftwidth
if type(get(g:, 'pyindent_continue', 0)) | unlet g:pyindent_continue | endif
if type(get(g:, 'pyindent_open_paren', 0)) | unlet g:pyindent_open_paren | endif
if type(get(g:, 'pyindent_nested_paren', 0)) | unlet g:pyindent_nested_paren | endif
if type(get(g:, 'pyindent_close_paren', 0)) | unlet g:pyindent_close_paren | endif

" Configure indent settings
" Use [black](https://github.com/psf/black) convention unless overridden
let g:pyindent_continue = get(g:, 'pyindent_continue', 1)
let g:pyindent_open_paren = get(g:, 'pyindent_open_paren', 1)
let g:pyindent_nested_paren = get(g:, 'pyindent_nested_paren', 1)
let g:pyindent_close_paren = get(g:, 'pyindent_close_paren', -1)
let g:pyindent_disable_paren = get(g:, 'pyindent_disable_paren', 0)
let g:pyindent_search_timeout = get(g:, 'pyindent_search_timeout', 150)

" Helper functions
" NOTE: Here use the non-existing 'stop' variable to break out of the loop
function! s:dedented(lnum, indent) abort
  let dedent = a:indent - shiftwidth()
  return indent(a:lnum) <= dedent
endfunction
function! s:searchpair(lnum, flags) abort
  let skip = "line('.') < a:lnum - 50  ? stop : tags#get_inside(0, 'Comment', 'String')"
  return searchpair('(\|{\|\[', '', ')\|}\|\]', a:flags, skip, 0, g:pyindent_search_timeout)
endfunction

" Return indentation
" NOTE: This is adapated from jeetsukumaran/vim-python-indent-black
function! GetPythonIndent(lnum) abort
  " Indent continuation lines
  if getline(a:lnum - 1) =~# '\\$'
    if a:lnum > 1 && getline(a:lnum - 2) =~# '\\$'
      return indent(a:lnum - 1)  " preserve previous indentation
    else
      return indent(a:lnum - 1) + g:pyindent_continue * shiftwidth()
    endif
  endif

  " Ignore strings and file starts
  let pnum = prevnonblank(v:lnum - 1)
  if synIDattr(synID(a:lnum, 1, 1), 'name') =~# 'String$'
    return -1  " no change if started with string
  elseif empty(pnum)  " first non-empty line
    return 0
  else  " position before search
    call cursor(pnum, 1)
  endif

  " Indent inside parentheses (can be slow)
  if g:pyindent_disable_paren
    let dnum = 0
    let pindent = indent(pnum)
    let pstart = pnum
  else
    let dnum = s:searchpair(pnum, 'nbW')
    if dnum > 0  " opening parenthesis of previous line
      let pindent = indent(dnum)
      let pstart = dnum
    else  " previous non-blank line
      let pindent = indent(pnum)
      let pstart = pnum
    endif
    call cursor(a:lnum, 1)
    let inum = s:searchpair(a:lnum, 'bW')
    if inum > 0
      if inum == pnum
        if s:searchpair(a:lnum, 'bW') > 0  " start is inside parenthesis
          return indent(pnum) + g:pyindent_nested_paren * shiftwidth()
        else  " double indent
          return indent(pnum) + g:pyindent_open_paren * shiftwidth()
        endif
      elseif inum == pstart  " closing parentheses
        if getline(a:lnum) =~# '^\s*[)}\]]'
          return indent(pnum) + g:pyindent_close_paren * shiftwidth()
        else
          return indent(pnum)
        endif
      else
        return pindent
      endif
    endif
  endif

  " Efficient search for comment start
  let cnum = col([pnum, '$'])
  if tags#get_inside([pnum, cnum], 'Comment')
    let [cnum, inum] = [1, cnum - 1]
    while cnum < inum  " efficient search
      let icol = (cnum + inum) / 2
      if tags#get_inside([pnum, icol], 'Comment')
        let inum = icol
      else
        let cnum = icol + 1
      endif
    endwhile
  endif
  if strpart(getline(pnum), 0, cnum - 1) =~# ':\s*$'
    return pindent + shiftwidth()
  endif
  if getline(pnum) =~# '^\s*\(break\|continue\|raise\|return\|pass\)\>'
    return s:dedented(a:lnum, indent(pnum)) ? -1 : indent(pnum) - shiftwidth()
  endif

  " Indent try-except clauses
  if getline(a:lnum) =~# '^\s*\(except\|finally\)\>'
    let lnum = a:lnum - 1
    while lnum >= 1
      if getline(lnum) =~# '^\s*\(try\|except\)\>'
        return indent(lnum) >= indent(a:lnum) ? -1 : indent(lnum)
      endif
      let lnum -= 1
    endwhile | return -1    " no matching 'try'
  endif

  " Indent other header keywords
  if getline(a:lnum) =~# '^\s*\(elif\|else\)\>'  " dedent unless previous is one-liner
    if getline(pstart) =~# '^\s*\(for\|if\|elif\|try\)\>'
      return pindent
    else
      return s:dedented(a:lnum, pindent) ? -1 : pindent - shiftwidth()
    endif
  endif

  " Indent after parentheses
  if dnum > 0  " after delim pair restore opening indent
    return s:dedented(a:lnum, pindent) ? -1 : pindent
  elseif getline(a:lnum) =~# '^\s*[)]\>'  " dedent closing to initial
    return s:dedented(a:lnum, pindent) ? -1 : pindent - shiftwidth()
  else  " no indent change
    return -1
  endif
endfunction
