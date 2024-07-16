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
" NOTE: Here take the original register, unless another (non-default) register has
" been supplied to the repeat command (as an explicit override).
function! repeat#run(...)
  let tick = b:changedtick
  let tick0 = get(g:, 'repeat_tick', -1)
  let seq = get(g:, 'repeat_sequence', '')
  let [seq0, reg0] = get(g:, 'repeat_reg', ['', ''])
  let s:errmsg = ''
  try
    if tick == tick0
      let cnt = get(g:, 'repeat_count', 1)
      let cnt = cnt < 0 ? '' : a:0 && a:1 ? a:1 : cnt ? cnt : ''
      let reg = ''
      if seq ==# seq0 && !empty(reg0)
        let name = v:register ==# repeat#getreg() ? reg0 : v:register
        let reg = '"' . name . (name ==# '=' ? getreg('=', 1) . "\<CR>" : '')
      endif
      call feedkeys(seq, 'i')
      call feedkeys(reg . cnt, 'ni')
    else
      let cnt = a:0 && a:1 ? a:1 : ''
      call feedkeys(cnt . '.', 'ni')
    endif
  catch /^Vim(normal):/
    let feed = "\<Cmd>echoerr " . v:errmsg . "\<CR>"
    call feedkeys(feed, 'n')  " avoid function message
  endtry
endfunction

" Repair insert mode undo and repeat
" WARNING: Running 'normal!' instead of feedkeys() suppresses built-in undo message
" so use temporary augroup. Must avoid CursorMoved (can trigger before TextChanged).
" NOTE: Here implement vim-tags support for restoring view after undoing changes and
" preserve vim messages about number of lines added/removed (normal! commands fail)
" finishes after b:changedtick is updated and sequence during undos/redos is lost.
function! repeat#undo(redo, ...) abort
  let sign = a:redo ? 1 : -1
  let tick = b:changedtick
  let tick0 = get(g:, 'repeat_tick', -1)
  let cnt = get(g:, 'repeat_count', 1)
  let seq = get(g:, 'repeat_sequence', '')
  let key1 = get(g:, 'tags_change_key', 'n')
  let key2 = &l:foldopen =~# 'undo\|all' ? 'zv' : ''
  let s:expr = a:redo ? 'normal! ' . key1 . key2 : ''
  let s:count = (a:redo ? 1 : -1) * (cnt < 0 ? 0 : a:0 && a:1 ? a:1 : cnt)
  augroup repeat_undo
    au!
    if &l:foldopen =~# 'undo\|all'
      au TextChanged <buffer> exe 'normal! zv'
    endif
    if tick == tick0  " ensure repeat status preserved
      au TextChanged <buffer> let g:repeat_tick = b:changedtick
      if seq ==# "\<Plug>TagsChangeForce"
        au TextChanged <buffer> call winrestview(get(g:, 'tags_change_view', {}))
      elseif seq ==# "\<Plug>TagsChangeAgain"
        au TextChanged <buffer> let @/ = tags#rescope(@/, s:count) | exe s:expr
      endif
    endif
    au CursorHold,InsertEnter,TextChanged <buffer> autocmd! repeat_undo
  augroup END
  let cnt = a:0 && a:1 ? a:1 : ''
  let key = a:redo ? "\<C-r>" : 'u'
  call feedkeys(cnt . key, 'n')
endfunction
