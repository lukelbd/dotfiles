"-----------------------------------------------------------------------------"
" Repeat utilities (forked from tpope/repeat.vim)
"-----------------------------------------------------------------------------"
" Helper functions
" NOTE: This repairs vim-repeat bug where repeat tick spuriously not incremented
" NOTE: Here repeat#invalidate() avoids spurious repeats in a related, naturally
" repeating mapping when your repeatable mapping doesn't increase b:changedtick.
function! repeat#invalidate()
  autocmd! repeat_set
  let g:repeat_tick = -1
endfunction
function! repeat#getreg()
  let vals = split(&clipboard, ',')
  return index(vals, 'unnamedplus') >= 0 ? '+' : index(vals, 'unnamed') >= 0 ? '*' : '"'
endfunction
function! repeat#setreg(sequence, register)
  let items = [a:sequence, a:register]
  let g:repeat_reg = items
endfunction
function! repeat#set(sequence, ...)
  let g:repeat_sequence = a:sequence
  let g:repeat_count = a:0 ? a:1 : v:count
  let g:repeat_tick = b:changedtick
  augroup repeat_set
    au!
    au CursorHold,CursorMoved,InsertEnter,TextChanged <buffer>
      \ let g:repeat_tick = b:changedtick | autocmd! repeat_set
  augroup END
endfunction

" Run repeat and wrap undo
" WARNING: Cannot set repeat counter in repeat#set() because sequences themselves
" might re-invoke repeat#set() for safety. Use default repeat_nr '1' below.
" NOTE: Here take the original register, unless another (non-default) register has
" been supplied to the repeat command (as an explicit override).
function! repeat#run(...)
  let s:errmsg = ''
  let tick = get(g:, 'repeat_tick', -1)
  let itick = b:changedtick
  let sequence = get(g:, 'repeat_sequence', '')
  let [isequence, iregister] = get(g:, 'repeat_reg', ['', ''])
  try
    if tick == itick
      let nr = get(g:, 'repeat_nr', 1)
      let cnt = get(g:, 'repeat_count', 0)
      let cnt = cnt < 0 ? '' : a:0 && a:1 ? a:1 : cnt ? cnt : ''
      let reg = ''
      if sequence ==# isequence && !empty(iregister)
        let name = v:register ==# repeat#getreg() ? iregister : v:register
        let reg = '"' . name . (name ==# '=' ? getreg('=', 1) . "\<CR>" : '')
      endif
      let g:repeat_nr = nr + 1
      call feedkeys(sequence, 'i')
      call feedkeys(reg . cnt, 'ni')
    else
      let cnt = a:0 && a:1 ? a:1 : ''
      call feedkeys(cnt . '.', 'ni')
      unlet! g:repeat_nr
    endif
  catch /^Vim(normal):/
    let feed = "\<Cmd>echoerr " . v:errmsg . "\<CR>"
    call feedkeys(feed, 'n')  " avoid function message
    unlet! g:repeat_nr
  endtry
endfunction

" Repair insert mode undo and repeat
" WARNING: Running 'normal!' instead of feedkeys() suppresses built-in undo message
" so use temporary augroup. Must avoid CursorMoved (can trigger before TextChanged).
" NOTE: Here implement vim-tags support for workflow 'c*<text><Esc>...uuuUUUuuUU' i.e.
" repeating then undoing then redoing the repeats. Only works as long as repeat is
" still active and relies on tracking consecutive repeat counts. Requires to ensure
" global replacements remember winview and itemwise changes update folds/scopes.
function! repeat#undo(redo, ...) abort
  let tick = get(g:, 'repeat_tick', -1)  " sequence change tick
  let itick = b:changedtick
  let nr = get(g:, 'repeat_nr', 1)  " unset if '.' not called
  let inr = a:redo ? nr + 1 : nr - 1
  let sequence = get(g:, 'repeat_sequence', '')
  let isequence = tick == itick ? a:redo ? nr >= 0 : nr > 0 : 0
  if tick == itick  " increment
    let g:repeat_nr = inr
  else  " sequence inactive
    unlet! g:repeat_nr
  endif
  augroup repeat_undo
    au!
    if &l:foldopen =~# 'undo\|all'
      au TextChanged <buffer> exe 'normal! zv'
    endif
    if tick == itick  " ensure repeat status preserved
      au TextChanged <buffer> let g:repeat_tick = b:changedtick
    endif
    if isequence && sequence ==# "\<Plug>TagsChangeAgain"
      au TextChanged <buffer> let @/ = tags#rescope(@/, s:count) | exe s:post
    endif
    if isequence && sequence ==# "\<Plug>TagsChangeForce"
      au TextChanged <buffer> call winrestview(get(b:, 'tags_change_winview', {}))
    endif
    au CursorHold,InsertEnter,TextChanged <buffer> autocmd! repeat_undo
  augroup END
  let cnt = get(g:, 'repeat_count', 0)
  let cnt = cnt < 0 ? 0 : a:0 && a:1 ? a:1 : cnt
  let s:count = a:redo ? cnt : -cnt
  let post = get(g:, 'tags_change_key', 'n')
  let post .= &l:foldopen =~# 'undo\|all' ? 'zv' : ''
  let s:post = a:redo ? 'normal! ' . post : ''
  let keys = a:0 && a:1 ? a:1 : ''  " input count
  let keys .= a:redo ? "\<C-r>" : 'u'
  call feedkeys(keys, 'n')
endfunction
