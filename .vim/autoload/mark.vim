"-----------------------------------------------------------------------------"
" Utilities for handling marks
"-----------------------------------------------------------------------------"
" Author: Tumbler Terrall [TumblerTerrall@gmail.com]
" Forked: Luke Davis [lukelbd@gmail.com]
" Cleaned up and modified to handle mark definitions
" See :help ctemrm-colors and :help gui-colors
let s:sign_id = 1
let s:use_signs = 1
let s:gui_colors = ['DarkYellow', 'DarkCyan', 'DarkMagenta', 'DarkBlue', 'DarkRed', 'DarkGreen']
let s:cterm_colors = ['DarkYellow', 'DarkCyan', 'DarkMagenta', 'DarkBlue', 'DarkRed', 'DarkGreen']

" Override of FZF :Jumps to work with custom utility and navigate with :Drop
" Note: As with :Changes this removes the --bind start:pos:etc flag that triggers
" errors and also implements new sink for navigating to paths with :Drop.
function! s:jump_sink(lines) abort
  let [key; lines] = a:lines  " first item is key binding
  if empty(lines) | return | endif
  let line = lines[-1]  " use final selection passed
  let idx = index(s:jumplist, line)
  if idx == -1 || idx == s:jumploc | return | endif | call s:select_jump(idx)
endfunction
function! s:update_jumps() abort
  let lines = split(execute('silent jumps'), "\n")
  let idx = match(lines, '\v^\s*\>')
  let idx = idx == -1 ? len(lines) - 1 : idx
  let [s:jumploc, s:jumplist] = [idx, lines]
endfunction
function! s:select_jump(loc) abort
  if a:loc == s:jumploc | return | endif
  let jump = s:jumplist[a:loc]
  let tail = substitute(jump, '^\s*\(\d\+\s\+\)\{3}', '', '')
  if bufexists(tail)  " i.e. not text within this buffer but a different buffer
    let cmd = "call file#open_drop('" . tail . "')"
    let keys = "\<Cmd>" . cmd . "\<CR>"
  else
    let key = a:loc > s:jumploc ? "\<C-i>" : "\<C-o>"
    let keys = abs(a:loc - s:jumploc) . key
  endif
  call feedkeys(keys . 'zv', 'n')
endfunction
function! s:echo_location(name, idx, size) abort
  let value = (a:size - a:idx) . '/' . (a:size - 1)
  let label = toupper(a:name[0]) . a:name[1:]
  let cmd = "echom '" . label . ' location: ' . value . "'"
  call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
endfunction
function! mark#goto_jump(count) abort
  call s:update_jumps()
  let idx = s:jumploc + a:count
  let jdx = min([idx, len(s:jumplist) - 1])
  let jdx = max([jdx, 0])
  if abs(a:count) == 1 && idx >= len(s:jumplist)
    echohl WarningMsg | echom 'Error: At end of jumplist' | echohl None
  elseif abs(a:count) == 1 && idx <= 0  " differs from changelist, but empirically tested
    echohl WarningMsg | echom 'Error: At start of jumplist' | echohl None
  else
    call s:select_jump(jdx)
    call s:echo_location('jump', jdx, len(s:jumplist))
  endif
endfunction
function! mark#fzf_jumps(...)
  let snr = utils#find_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  call s:update_jumps()
  let format = snr . 'jump_format'
  let options = {
    \ 'source': extend(s:jumplist[0:0], map(s:jumplist[1:], 'call(format, [v:val])')),
    \ 'sink*': function('s:jump_sink'),
    \ 'options': '+m -x --ansi --tiebreak=index --cycle --scroll-off 999 --sync --tac --header-lines 1 --tiebreak=begin --prompt "Jumps> "',
  \ }
  return call(snr . 'fzf', ['jumps', options, a:000])
endfunction

" Override of FZF :Changes
" Note: This is needed to fix issue where getbufline() output can be empty (filter
" function calls this function and assumes non-empty) and because the default FZF flag
" --bind start:pos:etc was yielding errors. Not sure why but maybe issue with .fzf fork
function! s:update_changes() abort
  let snr = utils#find_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let format1 = snr . 'format_change'
  let format2 = snr . 'format_change_offset'
  let changes = ['buf  offset  line  col  text']
  let paths = map(tags#buffer_paths(), 'resolve(v:val[1])')
  if paths[0] != expand('%:p') | call insert(paths, expand('%:p')) | endif
  for path in paths
    let bnr = bufnr(resolve(path))
    if bnr == -1 | continue | endif
    let active = bufnr() == bnr
    let [opts, loc_or_len] = getchangelist(bnr)
    let cursor = active ? len(opts) - loc_or_len : 0
    let opts = filter(opts, {idx, val -> !empty(getbufline(bnr, val.lnum))})
    let opts = reverse(opts)  " reversed changes
    let opts = map(opts, {idx, val -> call(format1, [bnr, call(format2, [active, idx, cursor]), val])})
    call extend(changes, opts)
  endfor
  return changes
endfunction
function! s:changes_sink(lines) abort
  let [key; lines] = a:lines  " first item is key binding
  if empty(lines) | return | endif
  let line = lines[-1]  " use final selection passed
  let [bnr, offset, lnum, cnum] = split(line)[0:3]
  let path = bufname(str2nr(bnr))
  if offset ==# '-'
    let keys = "\<Cmd>call file#open_drop('" . path . "')\<CR>\<Cmd>call cursor(" . lnum . ', ' . cnum . ")\<CR>"
  else
    let keys .= offset[0] ==# '+' ? offset[1:] . 'g,' : offset . 'g;'
  endif
  call feedkeys(keys . 'zv', 'n')
endfunction
function! mark#goto_change(count) abort
  let [opts, iloc] = getchangelist()
  let idx = iloc + a:count
  let jdx = min([idx, len(opts) - 1])
  let jdx = max([jdx, 0])
  let cnt = jdx - iloc
  let keys = cnt > 0 ? cnt . 'g,' : cnt < 0 ? abs(cnt) . 'g;' : ''
  if abs(a:count) == 1 && idx >= len(opts)
    echohl WarningMsg | echom 'Error: At end of changelist' | echohl None
  elseif abs(a:count) == 1 && idx < 0  " differs from jumplist, but empirically tested
    echohl WarningMsg | echom 'Error: At start of changelist' | echohl None
  else  " echo number
    call feedkeys(keys, 'n')
    call s:echo_location('change', jdx + 1, len(opts) + 1)
  endif
endfunction
function! mark#fzf_changes(...) abort
  let snr = utils#find_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let changes = s:update_changes()
  let options = {
    \ 'source': changes,
    \ 'sink*': function('s:changes_sink'),
    \ 'options': '+m -x --ansi --tiebreak=index --header-lines=1 --cycle --scroll-off 999 --sync --prompt "Changes> "',
  \ }
  return call(snr . 'fzf', ['changes', options, a:000])
endfunction

" Override of FZF :Marks to implement :Drop switching
" Note: Normally the fzf function calls `A-Z, and while vim permits multi-file marks,
" it does not have an option to open in existing tabs like 'showbufs' for loclist.
function! s:mark_sink(lines) abort
  if len(a:lines) < 2 | return | endif
  return mark#goto_mark(matchstr(a:lines[1], '\S'))
endfunction
function! mark#goto_mark(mrk) abort
  let mrks = getmarklist()
  let mrks = filter(mrks, "v:val['mark'] =~ \"'\" . a:mrk")
  if empty(mrks)  " avoid 'press enter' due to register
    let cmd = 'echohl WarningMsg '
    \ . '| echom "Error: Mark ''' . a:mrk . ''' is unset"'
    \ . '| echohl None'
  else
    let opts = mrks[0]
    let cmd = "call setpos('.', " . string(opts['pos']) . ')'
    call file#open_drop(opts['file'])
  endif
  call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
endfunction
function! mark#fzf_marks(...) abort
  let snr = utils#find_snr('/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let lines = split(execute('silent marks'), "\n")
  let format = snr . 'format_mark'
  let options = {
    \ 'source': extend(lines[0:0], map(lines[1:], 'call(format, [v:val])')),
    \ 'sink*': function('s:mark_sink'),
    \ 'options': '+m -x --ansi --tiebreak=index --header-lines 1 --tiebreak=begin --prompt "Marks> "'
  \ }
  return call(snr . 'fzf', ['marks', options, a:000])
endfunction

" Remove the mark and its highlighting
function! s:match_delete(id)
   if !s:use_signs
      call matchdelete(a:id)
   else
      exe 'sign unplace ' . a:id
   endif
endfunction
function! mark#del_marks(...) abort
  let highlights = get(g:, 'mark_highlights', {})
  let recents = get(g:, 'mark_recents', [])
  let g:mark_highlights = highlights
  let g:mark_recents = recents
  let mrks = a:0 ? a:000 : keys(highlights)
  for mrk in mrks
    if has_key(highlights, mrk) && len(highlights[mrk]) > 1
      call s:match_delete(highlights[mrk][1])
    endif
    if has_key(highlights, mrk)
      call remove(highlights, mrk)
    endif
    call filter(recents, 'v:val !=# "' . mrk . '"')
    exe 'delmark ' . mrk
  endfor
  call feedkeys("\<Cmd>echom 'Deleted marks: " . join(mrks, ' ') . "'\<CR>", 'n')
endfunction

" Add the mark and highlight the line
function! mark#set_marks(mrk) abort
  let highlights = get(g:, 'mark_highlights', {})
  let recents = get(g:, 'mark_recents', [])
  let g:mark_highlights = highlights
  let g:mark_recents = recents
  call add(recents, a:mrk)  " quick jumping later
  let name = a:mrk =~# '\u' ? 'upper_'. a:mrk : 'lower_' . a:mrk
  let name = 'mark_'. name  " different name for capital marks
  call feedkeys('m' . a:mrk, 'n')  " apply the mark
  if has_key(highlights, a:mrk)
    call s:match_delete(highlights[a:mrk][1])
    call remove(highlights[a:mrk], 1)
  else  " not previously defined
    let base = a:mrk =~# '\u' ? 65 : 97
    let idx = a:mrk =~# '\a' ? char2nr(a:mrk) - base : 0
    let gui_color = s:gui_colors[idx % len(s:gui_colors)]
    let cterm_color = s:cterm_colors[idx % len(s:cterm_colors)]
    exe 'highlight ' . name . ' ctermbg=' . cterm_color . ' guibg=' . gui_color
    if s:use_signs  " see :help sign define
      call sign_define(name, {'linehl': name, 'text': "'" . a:mrk})
    endif
    let highlights[a:mrk] = [[gui_color, cterm_color]]
  endif
  if !s:use_signs
    call add(highlights[a:mrk], matchadd(name, ".*\\%'" . a:mrk . '.*', 0))
  else
    let sign_id = s:sign_id
    let s:sign_id += 1
    call sign_place(sign_id, '', name, '%', {'lnum': line('.')})  " empty group critical
    call add(highlights[a:mrk], sign_id)
  endif
endfunction
