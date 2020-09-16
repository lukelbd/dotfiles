"-----------------------------------------------------------------------------"
" Functions related to spell checking
"-----------------------------------------------------------------------------"
" Toggle spell check on and off
function! spell#spell_toggle(...)
  if a:0
    let toggle = a:1
  else
    let toggle = 1 - &l:spell
  endif
  let &l:spell = toggle
endfunction

" Toggle between UK and US English
function! spell#lang_toggle(...)
  if a:0
    let uk = a:1
  else
    let uk = (&l:spelllang ==# 'en_gb' ? 0 : 1)
  endif
  if uk
    setlocal spelllang=en_gb
    echo 'Current language: UK english'
  else
    setlocal spelllang=en_us
    echo 'Current language: US english'
  endif
endfunction

" Correct next misspelled word
function! spell#spell_change(direc)
  let nospell = 0
  if !&l:spell
    let nospell = 1
    setlocal spell
  endif
  let winview = winsaveview()
  exe 'normal! ' . (a:direc ==# ']' ? 'bh' : 'el')
  exe 'normal! ' . a:direc . 's'
  normal! 1z=
  call winrestview(winview)
  if nospell
    setlocal nospell
  endif
endfunction

