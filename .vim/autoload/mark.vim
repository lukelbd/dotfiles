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

" Get the fzf.vim/autoload/fzf/vim.vim script id for overriding
" See: https://stackoverflow.com/a/49447600/4970632
function! s:fzf_snr() abort
  silent! call fzf#vim#with_preview()  " trigger autoload if not already done
  let [paths, sids] = vim#config_scripts(1)
  let path = filter(copy(paths), "v:val =~# '/autoload/fzf/vim.vim'")
  let idx = index(paths, get(path, 0, ''))
  if !empty(path) && idx >= 0
    return "\<snr>" . sids[idx] . '_'
  else
    echohl WarningMsg
    echom 'Warning: FZF autoload script not found.'
    echohl None
    return ''
  endif
endfunction

" Override of FZF :Jumps
" Note: This is only needed because the default FZF flag --bind start:pos:etc
" was yielding errors. Not sure why but maybe an issue with bash fzf fork?
function! s:jump_sink(lines) abort
  if len(a:lines) < 2 | return | endif
  let idx = index(s:jumplist, a:lines[1])
  if idx == -1 | return | endif
  let current = match(s:jumplist, '\v^\s*\>')
  let delta = idx - current
  let cmd = delta < 0 ? -delta . "\<C-o>" : delta . "\<C-i>"
  exe 'normal! ' . cmd
endfunction
function! mark#fzf_jumps(...)
  let snr = s:fzf_snr()
  if empty(snr) | return | endif
  redir => cout
  silent jumps
  redir END
  let s:jumplist = split(cout, '\n')
  let format = snr . 'jump_format'
  let current = -match(s:jumplist, '\v^\s*\>')
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
  if empty(mrks)
    echohl WarningMsg
    echom "Warning: Mark '" . a:mrk . "' not defined."
    echohl None
  else
    let opts = mrks[0]
    call file#open_drop(opts['file'])
    call setpos('.', opts['pos'])  " can also use this to set marks
  endif
endfunction
function! mark#fzf_marks(...) abort
  let snr = s:fzf_snr()
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
  endfor
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
