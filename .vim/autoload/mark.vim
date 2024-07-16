"-----------------------------------------------------------------------------"
" Utilities for handling jump, change, mark lists
"-----------------------------------------------------------------------------"
" Author: Tumbler Terrall [TumblerTerrall@gmail.com]
" Forked: Luke Davis [lukelbd@gmail.com]
" Cleaned up and modified to handle mark definitions
" See :help ctemrm-colors and :help gui-colors
let [s:sign_id, s:sign_marks] = [1, 1]
let s:sign_colors = ['DarkYellow', 'DarkCyan', 'DarkMagenta', 'DarkBlue', 'DarkRed', 'DarkGreen']

" Override fzf :Marks to implement :Drop switching
" NOTE: Normally the fzf function calls `A-Z, and while vim permits multi-file marks,
" it does not have an option to open in existing tabs like 'showbufs' for loclist,
function! mark#goto_mark(...) abort
  if !a:0 || empty(a:1) | return | endif
  let mrk = matchstr(a:1, '\S')
  let mrks = getmarklist()  " list of dictionaries
  let mrks = filter(mrks, {idx, val -> val.mark =~# "'" . mrk})
  let missing = !empty(mrks) && mrks[0].pos[0] && !bufexists(mrks[0].pos[0])
  if missing || empty(mrks)  " avoid 'press enter' due to register
    let msg = string('Error: Mark ' . string(mrk) . ' is unset')
    let cmd = 'redraw | echohl WarningMsg | echom ' . msg . ' | echohl None'
    call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
  else  " note this does not affect jumplist
    silent call file#drop_file(mrks[0].file)
    call setpos('.', mrks[0].pos)
    exe 'normal! ' . (&l:foldopen =~# 'mark\|all' ? 'zv' : '') . 'zzze'
  endif
  let g:mark_name = mrk  " mark stack navigation
endfunction
function! mark#fzf_marks(...) abort
  let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let source = split(execute('silent marks'), "\n")
  call extend(source[0:0], map(source[1:], {idx, val -> call(snr . 'format_mark', [v:val])}))
  let opts = '+m -x --ansi --header-lines 1 --tiebreak=begin '
  let options = {
    \ 'source': source,
    \ 'options': opts . ' --prompt "Marks> "',
    \ 'sink': function('stack#push_stack', ['mark', 'mark#goto_mark']),
  \ }
  return fzf#run(fzf#wrap('marks', options, a:0 ? a:1 : 0))
endfunction

" Iterate over marks (see also tag#next_tag)
" NOTE: This skips over marks with non-existent buffers and does an initial jump
" to the 'current' mark if cursor is not on the same line.
function! mark#next_mark(...) abort
  let stack = get(g:, 'mark_stack', [])
  let name = get(g:, 'mark_name', '')
  let cnt = a:0 ? a:1 : v:count1
  if !empty(name)
    let pos = getpos("'" . name)
    let [bnum, lnum] = [bufnr(), line('.')]
    if !pos[0] && pos[0] != bnum || pos[1] != lnum
      let offset = cnt > 0 ? -1 : 1
      if abs(cnt) <= 1
        call mark#goto_mark(name)
      else  " suppress message
        silent call mark#goto_mark(name)
      endif
      if pos[0] && pos[0] != bnum  " include in scroll if successful
        if pos[0] == bufnr() | let cnt += offset | endif
      else  " include in scroll if successful
        if pos[1] == line('.') | let cnt += offset | endif
      endif
    endif
  endif
  call call('stack#push_stack', ['mark', 'mark#goto_mark', cnt, 2])
endfunction

" Remove marks and highlighting
" NOTE: Here g:mark_name is not managed by stack utilities
function! s:match_delete(id)
  if s:sign_marks
    exe 'sign unplace ' . a:id
  else  " remove match
    call matchdelete(a:id)
  endif
endfunction
function! mark#del_marks(...) abort
  let highlights = get(g:, 'mark_highlights', {})
  let g:mark_highlights = highlights
  let mrks = a:0 ? filter(copy(a:000), '!empty(v:val)') : keys(highlights)
  if empty(mrks)
    redraw | echohl WarningMsg
    echom 'Error: No marks found'
    echohl None | return
  endif
  for mrk in mrks
    if has_key(highlights, mrk) && len(highlights[mrk]) > 1
      call s:match_delete(highlights[mrk][1])
    endif
    if has_key(highlights, mrk)
      call remove(highlights, mrk)
    endif
    call stack#pop_stack('mark', mrk)
    exe 'delmark ' . mrk
  endfor
  let cmd = "redraw | echom 'Deleted marks: " . join(mrks, ' ') . "'"
  let g:mark_name = get(get(g:, 'mark_stack', []), -1, '')
  call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
endfunction

" Add marks and sign column highlighting
" NOTE: This also runs on vim startup using marks saved to viminfo
function! mark#init_marks() abort
  let highlights = get(g:, 'mark_highlights', {})
  for imark in getmarklist()
    let ipos = imark['pos']  " buffer position
    let iname = imark['mark'][1]  " excluding quote
    if iname =~# '\u' && !has_key(highlights, iname)
      call mark#set_marks(iname, ipos)
    endif
  endfor  " WARNING: following lines must be last
  let default = get(get(g:, 'mark_stack', []), -1, 'A')
  let g:mark_name = get(g:, 'mark_name', default)
endfunction
function! mark#set_marks(mrk, ...) abort
  let highlights = get(g:, 'mark_highlights', {})
  let pos = a:0 ? a:1 : [0, line('.'), col('.'), 0]  " buffer required
  let pos[0] = pos[0] ? pos[0] : bufnr()  " replace zero
  call setpos("'" . a:mrk, pos)  " apply the mark
  call stack#pop_stack('mark', a:mrk)  " remove previous
  let g:mark_name = a:mrk  " required for push
  call stack#push_stack('mark', '', '', 0)  " apply g:mark_name
  let name = 'mark_' . (a:mrk =~# '\u' ? 'upper_' . a:mrk : 'lower_' . a:mrk)
  let base = a:mrk =~# '\u' ? 65 : 97
  let idx = a:mrk =~# '\a' ? char2nr(a:mrk) - base : 0
  if has_key(highlights, a:mrk)
    call s:match_delete(highlights[a:mrk][1])
    call remove(highlights[a:mrk], 1)
  else  " sign not defined
    let cterm_color = s:sign_colors[idx % len(s:sign_colors)]
    let gui_color = s:sign_colors[idx % len(s:sign_colors)]
    exe 'highlight ' . name . ' ctermbg=' . cterm_color . ' guibg=' . gui_color
    let highlights[a:mrk] = [[gui_color, cterm_color]]
    if s:sign_marks | call sign_define(name, {'texthl': name, 'linehl': 'None', 'text': "'" . a:mrk}) | endif
  endif
  if s:sign_marks
    let sid = s:sign_id | let s:sign_id += 1
    call add(highlights[a:mrk], sid)
    call sign_place(sid, '', name, pos[0], {'lnum': pos[1]})  " empty group critical
  else
    let regex = '.*\%''' . a:mrk . '.*'
    let hlid = matchadd(name, regex, 0)
    call add(highlights[a:mrk], hlid)
  endif
  let g:mark_highlights = highlights
endfunction
