"-----------------------------------------------------------------------------"
" Utilities for codi windows
"-----------------------------------------------------------------------------"
" Helper functions
" Note: Pre-processor fixes escapes returned by interpreters. For the
" escape issue see: https://github.com/metakirby5/codi.vim/issues/120
" Rephraser to remove comment characters before passing to interpreter. For the
" 1000 char limit issue see: https://github.com/metakirby5/codi.vim/issues/88
scriptencoding utf-8
function! calc#codi_preprocess(line) abort
  return substitute(a:line, '�[?2004l', '', '')
endfunction
function! calc#codi_rephrase(text) abort
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
    " vint: next-line -ProhibitUsingUndeclaredVariable  " erroneous warning
    let prevlen = len(text)
    let cutoff -= count(text[cutoff:], "\n")
    let text = ''
      \ . substitute(text[:cutoff - 1], '\(^\|\n\)[^\n]*$', '\n', '')
      \ . substitute(text[cutoff:], '[^\n]', '', 'g')
  endwhile
  return text
endfunction

" Initialize codi window
" Note: Vim substitute() function '.' matches newlines and codi silently fails
" if the rephrased input lines don't match original line count so be careful.
function! calc#init_codi(...) abort
  let prompt = 'Calculator path'
  if a:0 && !empty(a:1)
    let path = a:1
  else
    let base = fnamemodify(resolve(@%), ':p:h')
    let base = file#format_dir(base, 1)  " trailing slash
    let path = file#input_path('Calculator', 'calc.py', base)
  endif
  if !empty(path)
    let path = fnamemodify(path, ':r') . '.py'
    call file#drop_file(path)
    silent! exe 'Codi!!'
  endif
endfunction

" Set up codi window autocommands
" See: https://github.com/metakirby5/codi.vim/issues/90
" Note: This sets up the calculator window not the display window
function! calc#setup_codi(toggle) abort
  let name = 'codi_' . bufnr()
  silent! exe 'autocmd! ' . name
  if a:toggle
    exe 'augroup ' . name
    exe 'autocmd!'
    exe 'au InsertLeave,TextChanged <buffer> call codi#update()'
    exe 'augroup END'
    call feedkeys("\<Cmd>call window#default_width(0)\<CR>", 'n')
  endif
endfunction
