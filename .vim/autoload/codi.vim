"-----------------------------------------------------------------------------"
" Utilities for codi windows
"-----------------------------------------------------------------------------"
" Setup new codi window
function! codi#new(...) abort
  if a:0 && a:1 !~# '^\s*$'
    let name = a:1
  else
    let name = input('Calculator name (' . getcwd() . '): ', '', 'file')
  endif
  if name !~# '^\s*$'
    exe 'tabe ' . fnamemodify(name, ':r') . '.py'
    Codi!!
  endif
endfunction

" Custom codi window autocommands Want TextChanged,InsertLeave, not
" TextChangedI which is enabled with g:codi#autocmd = 'TextChanged'
" See: https://github.com/metakirby5/codi.vim/issues/90
" Note: This sets up the calculator window not the display window
function! codi#setup(toggle) abort
  if a:toggle
    let cmds = exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave'
    nnoremap <buffer> q <C-w>p<Cmd>Codi!!<CR>
    nnoremap <buffer> <C-w> <C-w>p<Cmd>Codi!!<CR>
    exe 'augroup codi_' . bufnr('%')
      au!
      exe 'au ' . cmds . ' <buffer> call codi#update()'
    augroup END
  else
    exe 'augroup codi_' . bufnr('%')
      au!
    augroup END
  endif
endfunction

" Pre-processor fixes escapes returned by interpreters. For the
" escape issue see: https://github.com/metakirby5/codi.vim/issues/120
" Rephraser to remove comment characters before passing to interpreter. For the
" 1000 char limit issue see: https://github.com/metakirby5/codi.vim/issues/88
" Note: Warning message will be gobbled so don't bother. Just silent failure. Also
" vim substitute() function '.' matches newlines and codi silently fails if the
" rephrased input lines don't match original line count so be careful.
function! codi#preprocess(line) abort
  return substitute(a:line, '�[?2004l', '', '')
endfunction
function! codi#rephrase(text) abort
  let pat = '\s*' . comment#comment_char() . '[^\n]*\(\n\|$\)'  " remove comments
  let text = substitute(a:text, pat, '\1', 'g')
  let pat = '\s\+\([+-=*^|&%;:]\+\)\s\+'  " remove whitespace
  let text = substitute(text, pat, '\1', 'g')
  let pat = '\(\_s*\)\(\k\+\)=\([^\n]*\)'  " append variable defs
  let text = substitute(text, pat, '\1\2=\3;_r("\2")', 'g')
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
