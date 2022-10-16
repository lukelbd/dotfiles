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
  let b:caps_lock = exists('b:caps_lock') ? 1 - b:caps_lock : 1
  echom 'Caps lock! ' . b:caps_lock
  if b:caps_lock
    for s:c in range(char2nr('A'), char2nr('Z'))
      exe 'lnoremap <buffer> ' . nr2char(s:c + 32) . ' ' . nr2char(s:c)
      exe 'lnoremap <buffer> ' . nr2char(s:c) . ' ' . nr2char(s:c + 32)
    endfor
    augroup caps_lock
      au!
      au InsertLeave,CmdwinLeave * setlocal iminsert=0 | let b:caps_lock = 0 | autocmd! caps_lock
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

" Insert complete menu items and scroll complete or preview windows (whichever is open).
" Note: This prevents vim's baked-in circular complete menu scrolling. It
" also prefers scrolling complete menus over preview windows.
" Note: Used 'verb function! lsp#scroll' to figure out how to detect
" preview windows for a reference scaling (also verified that l:window.find
" and therefore lsp#scroll do not return popup completion windows).
function! insert#popup_reset() abort
  let b:popup_scroll = 0
  return ''
endfunction
function! insert#popup_scroll(scroll) abort
  let l:methods = vital#lsp#import('VS.Vim.Window')  " scope is necessary
  let ids = l:methods.find({id -> l:methods.is_floating(id)})
  let complete_info = pum_getpos()  " automatically returns empty if not present
  let preview_info = empty(ids) ? {} : l:methods.info(ids[0])
  if !empty(complete_info)
    let nr = type(a:scroll) == 5 ? float2nr(a:scroll * complete_info['height']) : a:scroll
    let nr = a:scroll > 0 ? max([nr, 1]) : min([nr, -1])
    let nr = max([0 - b:popup_scroll, nr])
    let nr = min([complete_info['size'] - b:popup_scroll, nr])
    let b:popup_scroll += nr  " complete menu offset
    return repeat(nr > 0 ? "\<C-n>" : "\<C-p>", abs(nr))
  elseif !empty(preview_info)
    let nr = type(a:scroll) == 5 ? float2nr(a:scroll * preview_info['height']) : a:scroll
    let nr = a:scroll > 0 ? max([nr, 1]) : min([nr, -1])
    return lsp#scroll(nr)
  else
    return ''
  endif
endfunction

" Correct next misspelled word
" This provides functionality similar to [t and ]s
function! insert#spell_apply(forward)
  let nospell = 0
  if !&l:spell
    let nospell = 1
    setlocal spell
  endif
  let winview = winsaveview()
  exe 'normal! ' . (a:forward ? 'bh' : 'el')
  exe 'normal! ' . (a:forward ? ']' : '[') . 's'
  normal! 1z=
  call winrestview(winview)
  if nospell
    setlocal nospell
  endif
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
