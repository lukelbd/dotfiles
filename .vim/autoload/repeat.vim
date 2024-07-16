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
  autocmd! repeat_custom_motion
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
  augroup repeat_custom_motion
    au!
    au CursorMoved,InsertEnter,TextChanged <buffer>
      \ let g:repeat_tick = b:changedtick | autocmd! repeat_custom_motion
  augroup END
endfunction

" Repair insert mode undo and repeat
" NOTE: Here implement vim-tags support for restoring view after undoing changes
" NOTE: This repairs race condition bug where feedkeys() from vim-repeat repeat#wrap()
" finishes after b:changedtick is updated and sequence during undos/redos is lost.
function! repeat#wrap(key, ...) abort
  let cnt = a:0 && a:1 ? a:1 : ''
  let seq = get(g:, 'repeat_sequence', '')
  let rtick = get(g:, 'repeat_tick', -1)
  let btick = b:changedtick
  exe 'normal! ' . cnt . a:key
  exe &l:foldopen =~# 'undo\|all' ? 'normal! zv' : ''
  if rtick == btick
    let g:repeat_tick = b:changedtick
  endif
  if seq =~# "\<Plug>TagsChangeForce"
    call winrestview(get(g:, 'tags_change_view', {}))
  endif
  if seq =~# "\<Plug>TagsChangeAgain"
    let key = get(g:, 'tags_change_key', 'n')
    let cnt = get(g:, 'repeat_count', 1)
    let sign = a:key ==# "\<C-r>" ? 1 : -1
    let repeat = a:key ==# "\<C-r>" && btick != b:changedtick
    let @/ = tags#sub_scope(@/, cnt * sign)
    call feedkeys(repeat ? key . 'zv' : 'zv', 'n')
  endif
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
