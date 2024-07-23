"-----------------------------------------------------------------------------"
" Utilities for codi windows
"-----------------------------------------------------------------------------"
" Codi processors and interpreters
" NOTE: These act on main window not the codi display window. Configure on text change
" instead of cursor hold. See https://github.com/metakirby5/codi.vim/issues/90
" NOTE: Vim substitute() function '.' matches newlines and codi silently fails
" if the rephrased input lines don't match original line count so be careful.
function! calc#setup_codi(toggle) abort
  if a:toggle  " add autocommands
    exe 'augroup codi_' . bufnr()
    exe 'au!'
    exe 'au InsertLeave,TextChanged <buffer> call codi#update()'
    exe 'augroup END'
  else  " remove autocommands
    silent! exe 'au! codi_' . bufnr()
  endif
endfunction
function! calc#show_codi(...) abort
  let prompt = 'Calculator path'
  let path = a:0 ? a:1 : ''
  if empty(path)
    let base = fnamemodify(resolve(@%), ':p:h')
    let base = file#get_base(base, 1)  " trailing slash
    let path = file#input_path('Calculator', 'calc.py', base)
  endif
  if isdirectory(path)  " fails if empty
    let path = substitute(path, '/$', '', '') . '/calc.py'
  endif
  if !empty(path)  " open calculator
    let path = fnamemodify(path, ':r') . '.py'
    call file#drop_file(path)
    call feedkeys("\<Cmd>Codi!!\<CR>", 'n')
  endif
endfunction

" Codi processors and interpreters
" NOTE: Pre-processor fixes escapes returned by interpreters. For the
" escape issue see: https://github.com/metakirby5/codi.vim/issues/120
" Rephraser to remove comment characters before passing to interpreter. For the
" 1000 char limit issue see: https://github.com/metakirby5/codi.vim/issues/88
scriptencoding utf-8
function! calc#preprocess_codi(line) abort
  return substitute(a:line, '�[?2004l', '', '')
endfunction
function! calc#rephrase_codi(text) abort
  let regex = '\s*' . comment#get_regex() . '[^\n]*\(\n\|$\)'  " remove comments
  let text = substitute(a:text, regex, '\1', 'g')
  let regex = '\s\+\([+-=*^|&%;:]\+\)\s\+'  " remove whitespace
  let text = substitute(text, regex, '\1', 'g')
  let regex = '\(\_s\+\)\(\k\+\)=\([^\n]*\)'  " append variable defs
  let text = substitute(text, regex, '\1\2=\3;_r("\2")', 'g')
  if &filetype ==# 'julia'  " prepend repr functions
    let text = '_r=s->print(s*" = "*string(eval(s)));' . text
  else
    let text = '_r=lambda s:print(s+" = "+str(eval(s)));' . text
  endif
  let maxlen = 950  " too close to 1000 gets risky even if under 1000
  let cutoff = maxlen
  while len(text) > maxlen && (!exists('prevlen') || prevlen != len(text))
    " vint: next-line -ProhibitUsingUndeclaredVariable
    let prevlen = len(text)
    let cutoff -= count(text[cutoff:], "\n")
    let text = ''
      \ . substitute(text[:cutoff - 1], '\(^\|\n\)[^\n]*$', '\n', '')
      \ . substitute(text[cutoff:], '[^\n]', '', 'g')
  endwhile
  return text
endfunction
