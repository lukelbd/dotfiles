"-----------------------------------------------------------------------------"
" Utilities for inserting text
"-----------------------------------------------------------------------------"
" Inserting blank lines
" See: https://github.com/tpope/vim-unimpaired
function! insert#blank_up(count) abort
  put!=repeat(nr2char(10), a:count)
  ']+1
  silent! call repeat#set("\<Plug>BlankUp", a:count)
endfunction
function! insert#blank_down(count) abort
  put =repeat(nr2char(10), a:count)
  '[-1
  silent! call repeat#set("\<Plug>BlankDown", a:count)
endfunction

" Forward delete by tabs
function! insert#forward_delete() abort
  let line = getline('.')
  if line[col('.') - 1:col('.') - 1 + &tabstop - 1] == repeat(' ', &tabstop)
    return repeat("\<Delete>", &tabstop)
  else
    return "\<Delete>"
  endif
endfunction

" Toggle insert and command-mode caps lock
" See: http://vim.wikia.com/wiki/Insert-mode_only_Caps_Lock which uses
" iminsert to enable/disable lnoremap, with iminsert changed from 0 to 1
function! insert#lang_map()
  let b:caps_lock = exists('b:caps_lock') ? b:caps_lock - 1 : 1
  if b:caps_lock
    for s:c in range(char2nr('A'), char2nr('Z'))
      exe 'lnoremap <buffer> ' . nr2char(s:c + 32) . ' ' . nr2char(s:c)
      exe 'lnoremap <buffer> ' . nr2char(s:c) . ' ' . nr2char(s:c + 32)
    endfor
    augroup caps_lock
      au!
      au InsertLeave,CmdwinLeave * setlocal iminsert=0 | autocmd! caps_lock
    augroup END
  endif
  return "\<C-^>"
endfunction

" Set up temporary paste mode
function! insert#paste_mode() abort
  let s:paste = &paste
  let s:mouse = &mouse
  set paste
  set mouse=
  augroup insert_paste
    au!
    au InsertLeave *
      \ if exists('s:paste') |
      \   let &paste = s:paste |
      \   let &mouse = s:mouse |
      \   unlet s:paste |
      \   unlet s:mouse |
      \ endif |
      \ autocmd! insert_paste
  augroup END
  return ''
endfunction

" Special behavior when popup menu is open
" See: https://github.com/lukelbd/dotfiles/blob/master/.vimrc
function! insert#pum_next() abort
  let b:pum_pos += 1 | return "\<C-n>"
endfunction
function! insert#pum_prev() abort
  let b:pum_pos -= 1 | return "\<C-p>"
endfunction
function! insert#pum_reset() abort
  let b:pum_pos = 0 | return ''
endfunction

" Swap characters
function! insert#swap_characters(right) abort
  let cnum = col('.')
  let line = getline('.')
  let idx = a:right ? cnum : cnum - 1
  if idx > 0 && idx < len(line)
    let line = line[:idx - 2] . line[idx] . line[idx - 1] . line[idx + 1:]
    call setline('.', line)
  endif
endfunction

" Swap lines
function! insert#swap_lines(bottom) abort
  let offset = a:bottom ? 1 : -1
  let lnum = line('.')
  if (lnum + offset > 0 && lnum + offset < line('$'))
    let line1 = getline(lnum)
    let line2 = getline(lnum + offset)
    call setline(lnum, line2)
    call setline(lnum + offset, line1)
  endif
  exe lnum + offset
endfunction
