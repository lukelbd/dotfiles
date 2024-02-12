"-----------------------------------------------------------------------------"
" Utilities for handling marks
"-----------------------------------------------------------------------------"
" Author: Tumbler Terrall [TumblerTerrall@gmail.com]
" Forked: Luke Davis [lukelbd@gmail.com]
" Cleaned up and modified to handle mark definitions
" See :help ctemrm-colors and :help gui-colors
let s:idx = 0
let s:idx_cterm = 0
let s:next_id = 1
let s:use_signs = 1
let s:gui_colors = ['DarkYellow', 'DarkCyan', 'DarkMagenta', 'DarkBlue', 'DarkRed', 'DarkGreen']
let s:cterm_colors = ['DarkYellow', 'DarkCyan', 'DarkMagenta', 'DarkBlue', 'DarkRed', 'DarkGreen']

" Navigating jump list across windows with :Drop
" Note: Vim natively extends jumplist when switching tabs but does not switch between
" existing tabs. Here override default <C-o> and <C-i> by running :Drop before switch.
function! s:goto_jump(loc) abort
  if a:loc == s:jumploc | return | endif
  let keys = ''
  let jump = s:jumplist[a:loc]
  let tail = substitute(jump, '^\s*\(\d\+\s\+\)\{3}', '', '')
  if bufexists(tail)  " i.e. not text within this buffer but a different buffer
    let cmd = "\<Cmd>Drop " . fnameescape(tail) . "\<CR>"
    let keys .= cmd
  endif
  let key = a:loc > s:jumploc ? "\<C-i>" : "\<C-o>"
  let keys .= abs(a:loc - s:jumploc) . key
  let keys .= 'zv'
  call feedkeys(keys, 'n')
endfunction
function! s:update_jumps() abort
  redir => cout | silent jumps | redir END
  let lines = split(cout, '\n')
  let idx = match(lines, '\v^\s*\>')
  let idx = idx == -1 ? len(lines) - 1 : idx
  let [s:jumploc, s:jumplist] = [idx, lines]
endfunction
function! mark#add_jump() abort
endfunction
function! mark#goto_jump(count) abort
  call s:update_jumps()
  let idx = s:jumploc + a:count
  let idx = min([idx, len(s:jumplist) - 1])
  let idx = max([idx, 0])
  call s:goto_jump(idx)
endfunction

" Override of FZF :Jumps to work with custom utility
" Note: This is only needed because the default FZF flag --bind start:pos:etc
" was yielding errors. Not sure why but maybe an issue with bash fzf fork?
function! s:jump_sink(lines) abort
  let [key; lines] = a:lines  " first item is key binding for some reason
  if empty(lines) | return | endif
  let line = lines[-1]  " use final selection passed
  let idx = index(s:jumplist, line)
  if idx == -1 || idx == s:jumploc | return | endif
  call s:goto_jump(idx)
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
      \ . '| echom "Error: Mark ''' . a:mrk . ''' is unset" '
      \ . '| echohl None'
    call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')  " bars don't need to be escaped
  else
    let opts = mrks[0]
    call file#open_drop(opts['file'])
    call setpos('.', opts['pos'])  " can also use this to set marks
  endif
endfunction
function! mark#fzf_marks(...) abort
  let snr = utils#find_snr('/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  redir => cout
  silent marks
  redir END
  let list = split(cout, "\n")
  let format = snr . 'format_mark'
  let options = {
    \ 'source': extend(list[0:0], map(list[1:], 'call(format, [v:val])')),
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
  let g:mark_highlights = highlights
  let mrks = a:0 ? a:000 : keys(highlights)
  for mrk in mrks
    if has_key(highlights, mrk) && len(highlights[mrk]) > 1
      call s:match_delete(highlights[mrk][1])
    endif
    if has_key(highlights, mrk)
      call remove(highlights, mrk)
    endif
    exe 'delmark ' . mrk
    silent! unlet g:mark_recent
  endfor
  echom 'Deleted marks: ' . join(mrks, ' ')
endfunction

" Add the mark and highlight the line
function! mark#set_marks(mrk) abort
  let highlights = get(g:, 'mark_highlights', {})
  let g:mark_highlights = highlights
  let g:mark_recent = a:mrk  " quick jumping later
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
    let id = s:next_id
    let s:next_id += 1
    call sign_place(id, '', name, '%', {'lnum': line('.')})  " empty group critical
    call add(highlights[a:mrk], id)
  endif
endfunction
