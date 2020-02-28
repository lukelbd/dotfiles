"-----------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-09-20
" Various settings and macros for python files
" Includes a couple mappings for converting {'a':1} to a=1
"-----------------------------------------------------------------------------"
" Settings
setlocal tabstop=4 softtabstop=4 shiftwidth=4
setlocal indentexpr=s:pyindent(v:lnum)  " new indent expression
setlocal iskeyword-=.  " never include period in word definition
let g:python_highlight_all = 1  " builtin python ftplugin syntax option
" let g:pydiction_location = expand('~') . '/.vim/plugged/Pydiction/complete-dict'  " for pyDiction plugin

" Run current script in shell
nnoremap <silent> <buffer> <C-z> :update<CR>:exec("!clear; set -x; python ".shellescape(@%))<CR><CR>

" Easy conversion between key=value pairs and 'key': value dictionary entries
" Do son on current line, or within visual selection
function! s:kwtrans(mode) range
  " First get columns
  let winview = winsaveview()
  if a:firstline == a:lastline
    let firstcol = 0
    let lastcol  = col('$') - 2  " col('$') is location of newline char, and strings are zero-indexed
  else
    let firstcol = col("'<") - 1  " cause strings are zero-indexed
    let lastcol  = col("'>") - 1
  endif
  let fixed = []
  for line in range(a:firstline, a:lastline)
    " Annoying ugly block for getting visual selection
    " Want to *ignore* stuff not in selection, but on same line as
    " the start/end of selection, because it's more flexible
    let string = getline(line)
    let prefix = ''
    let suffix = ''
    if line == a:firstline && line == a:lastline
      let prefix = (firstcol >= 1 ? string[:firstcol - 1] : '')  " damn negative indexing makes this complicated
      let suffix = string[lastcol + 1:]
      let string = string[firstcol : lastcol]
    elseif line == a:firstline
      let prefix = (firstcol >= 1 ? string[:firstcol - 1] : '')
      let string = string[firstcol:]
    elseif line == a:lastline
      let suffix = string[lastcol + 1:]
      let string = string[:lastcol]
    endif
    if len(matchstr(string, ':')) > 0 && len(matchstr(string, '-')) > 0
      echom 'Error: Ambiguous line.'
      return
    endif

    " Next finally start matching shit
    if a:mode == 1  " kwargs to dictionary
      let string = substitute(string, '\<\ze\w\+\s*=', "'", 'g')  " add leading quote first
      let string = substitute(string, '\>\ze\s*=', "'", 'g')
      let string = substitute(string, '\s*=\s*', ': ', 'g')
    elseif a:mode == 0  " dictionary to kwargs
      let string = substitute(string, "\\>['\"]" . '\ze\s*:', '', 'g')  " remove trailing quote first
      let string = substitute(string, "['\"]\\<" . '\ze\w\+\s*:', '', 'g')
      let string = substitute(string, '\s*:\s*', '=', 'g')
    endif
    call add(fixed, prefix . string . suffix)
  endfor

  " Replace lines with fixed text
  exe a:firstline . ',' . a:lastline . 'd'
  call append(a:firstline - 1, fixed)
  call winrestview(winview)
endfunction

" Mappings
noremap <buffer> <silent> <Plug>kw2dict :call <sid>kwtrans(1)<CR>:call repeat#set("\<Plug>kw2dict")<CR>
noremap <buffer> <silent> <Plug>dict2kw :call <sid>kwtrans(0)<CR>:call repeat#set("\<Plug>dict2kw")<CR>
map <buffer> cd <Plug>kw2dict
map <buffer> cD <Plug>dict2kw
