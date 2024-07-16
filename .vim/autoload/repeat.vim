"-----------------------------------------------------------------------------"
" Repeat utilities (forked from tpope/repeat.vim)
"-----------------------------------------------------------------------------"
" Helper functions
" NOTE: This repairs vim-repeat bug where repeat tick spuriously not incremented
" NOTE: Here repeat#invalidate() avoids spurious repeats in a related, naturally
" repeating mapping when your repeatable mapping doesn't increase b:changedtick.
let g:repeat_tick = -1
let g:repeat_reg = ['', '']
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
function! repeat#errmsg()
  return s:errmsg
endfunction
function! repeat#run(count)
  let s:errmsg = ''
  try
    if g:repeat_tick == b:changedtick
      let keys = ''
      if g:repeat_reg[0] ==# g:repeat_sequence && !empty(g:repeat_reg[1])
        let regname = v:register ==# repeat#getreg() ? g:repeat_reg[1] : v:register
        if regname ==# '='  " re-evaluate register
          let keys = '"=' . getreg('=', 1) . "\<CR>"
        else  " return register
          let keys = '"' . regname
        endif
      endif
      let cnt = g:repeat_count
      let seq = g:repeat_sequence
      let cnt = cnt == -1 ? '' : (a:count ? a:count : (cnt ? cnt : ''))
      call feedkeys(seq, 'i')
      call feedkeys(keys . cnt, 'ni')
    else
      let cnt = a:count ? a:count : ''
      call feedkeys(cnt . '.', 'ni')
    endif
  catch /^Vim(normal):/
    let s:errmsg = v:errmsg
    return 0
  endtry
  return 1
endfunction

" Repair insert mode undo and repeat
" WARNING: Running 'normal!' instead of feedkeys() suppresses built-in undo message
" so use temporary augroup. Must avoid CursorMoved (can trigger before TextChanged).
" NOTE: Here implement vim-tags support for restoring view after undoing changes and
" preserve vim messages about number of lines added/removed (normal! commands fail)
" finishes after b:changedtick is updated and sequence during undos/redos is lost.
function! repeat#undo(redo, ...) abort
  let tick = b:changedtick
  let tick0 = get(g:, 'repeat_tick', -1)
  let seq = get(g:, 'repeat_sequence', '')
  let key = get(g:, 'tags_change_key', 'n')
  let s:arg = (a:redo ? 1 : -1) * get(g:, 'repeat_count', 1)
  let s:key = key . (&l:foldopen =~# 'undo\|all' ? 'zv' : '')
  augroup repeat_undo
    au!
    if &l:foldopen =~# 'undo\|all'
      au TextChanged <buffer> exe 'normal! zv'
    endif
    if tick == tick0  " ensure repeat status preserved
      au TextChanged <buffer> let g:repeat_tick = b:changedtick
      if seq =~# "\<Plug>TagsChangeForce"
        au TextChanged <buffer> call winrestview(get(g:, 'tags_change_view', {}))
      elseif a:redo && seq =~# "\<Plug>TagsChangeAgain"
        au TextChanged <buffer> exe 'normal! ' . s:key | let @/ = tags#rescope(@/, s:arg)
      endif
    endif
    au CursorHold,InsertEnter,TextChanged <buffer> autocmd! repeat_undo
  augroup END
  let cnt = a:0 && a:1 ? a:1 : ''
  let keys = a:redo ? cnt . "\<C-r>" : cnt . 'u'
  call feedkeys(keys, 'n')
endfunction
