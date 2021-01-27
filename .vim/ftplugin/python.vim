"-----------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-09-20
" Various settings and macros for python files
" Includes a couple mappings for converting {'a':1} to a=1
"-----------------------------------------------------------------------------"
" Misc settings
setlocal tabstop=4 softtabstop=4 shiftwidth=4
setlocal indentexpr=s:pyindent(v:lnum)  " new indent expression
setlocal iskeyword-=.  " never include period in word definition
let g:python_highlight_all = 1  " builtin python ftplugin syntax option

" Run current script using anaconda python, not vim python (important for macvim)
function! s:run_python_script() abort
  update
  let python = $HOME . '/miniconda3/bin/python'
  let projlib = $HOME . '/miniconda3/share/proj'
  if !executable(python)
    echohl WarningMsg
    echom "Anaconda python '" . python . "' not found."
    echohl None
  else
    exe
        \ '!clear; set -x; PROJ_LIB=' . shellescape(projlib)
        \ . ' ' . shellescape(python) . ' ' . shellescape(@%)
  endif
endfunction
nnoremap <silent> <buffer> <Plug>Execute :call <sid>run_python_script()<CR>

" Easy conversion between key=value pairs and 'key': value dictionary entries
" Do son on current line, or within visual selection
function! TranslateKwargs(kw2dict, ...) abort range
  " First get columns
  " Note: Motions sent from g@
  let winview = winsaveview()
  if a:0 && a:1 ==# 'n'
    let firstcol = col("'[") - 1  " when calling col(), ' means `
    let lastcol  = col("']") - 1
  else
    let firstcol = col("'<") - 1
    let lastcol  = col("'>") - 1
  endif
  echom 'Range: ' . a:firstline . ':' . firstcol . ', ' . a:lastline . ':' . lastcol
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
      let string = string[firstcol :]
    elseif line == a:lastline
      let suffix = string[lastcol + 1:]
      let string = string[:lastcol]
    endif
    if len(matchstr(string, ':')) > 0 && len(matchstr(string, '=')) > 0
      echoerr 'Error: Ambiguous line.'
      return
    endif

    " Next finally start matching shit
    if a:kw2dict == 1  " kwargs to dictionary
      let string = substitute(string, '\<\ze\w\+\s*=', "'", 'g')  " add leading quote first
      let string = substitute(string, '\>\ze\s*=', "'", 'g')
      let string = substitute(string, '\s*=\s*', ': ', 'g')
    else
      let string = substitute(string, "\\>['\"]" . '\ze\s*:', '', 'g')  " remove trailing quote first
      let string = substitute(string, "['\"]\\<" . '\ze\w\+\s*:', '', 'g')
      let string = substitute(string, '\s*:\s*', '=', 'g')
    endif
    call add(fixed, prefix . string . suffix)
  endfor

  " Replace lines with fixed text
  silent exe a:firstline . ',' . a:lastline . 'd _'
  call append(a:firstline - 1, fixed)
  call winrestview(winview)
endfunction

" For use with <expr> (see utils.vim for examples)
function! s:translate_kwargs_expr(arg) range abort
  return MotionFunc('TranslateKwargs', [a:arg, mode()])
endfunction

" Mappings
noremap <buffer> <expr> cd <sid>translate_kwargs_expr(1)
noremap <buffer> <expr> cD <sid>translate_kwargs_expr(0)

" With repeat (not really necessary now that command accepts motions)
" noremap <buffer> <silent> <Plug>kw2dict :call <sid>translate_kwargs(1)<CR>:call repeat#set("\<Plug>kw2dict")<CR>
" noremap <buffer> <silent> <Plug>dict2kw :call <sid>translate_kwargs(0)<CR>:call repeat#set("\<Plug>dict2kw")<CR>
" map <buffer> cd <Plug>kw2dict
" map <buffer> cD <Plug>dict2kw
