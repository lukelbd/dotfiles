"-----------------------------------------------------------------------------"
" Utilities for handling marks and jumps
"-----------------------------------------------------------------------------"
" Author: Tumbler Terrall [TumblerTerrall@gmail.com]
" Forked: Luke Davis [lukelbd@gmail.com]
" Cleaned up and modified to handle mark definitions
" See :help ctemrm-colors and :help gui-colors
let s:sign_id = 1
let s:use_signs = 1
let s:gui_colors = ['DarkYellow', 'DarkCyan', 'DarkMagenta', 'DarkBlue', 'DarkRed', 'DarkGreen']
let s:cterm_colors = ['DarkYellow', 'DarkCyan', 'DarkMagenta', 'DarkBlue', 'DarkRed', 'DarkGreen']

" Push current location to top of jumplist
" Note: This prevents resetting when navigating backwards and forwards through
" jumplist or when navigating within paragraph of most recently set jump. Also remap
" 'jumping' motions n/N/{/}/(/)/`/[[/]] by prepending :keepjumps to reduce entries.
" Note: Jumplist is managed from the bottom-up by remapping normal-mode 'jumping'
" motions and conditionally updating jumplist on CursorHold. Still navigate the
" actual jumplist using <C-o>/<C-i> navigation keys. Compare to changelist below.
function! mark#push_jump() abort
  let [line1, line2] = [line("'{"), line("'}")]
  let [jlist, jloc] = getjumplist()
  let pline = line("''")  " line of previous jump
  let cline = pline
  if !empty(jlist)
    let opts = get(jlist, jloc, jlist[-1])
    let cline = opts['lnum']
  endif
  if line1 > cline || line2 < cline
    if line1 > pline || line2 < pline
      call feedkeys("\<Cmd>normal! m'\<CR>", 'n')
    endif
  endif
endfunction

" Generate jump and change lists
" Note: Similar to how stack.vim 'floats' recent tab stack entries to the top of the
" stack of the current tab is in the most recent five, this filters jump and change
" list entries to ensure identical line numbers are at least 10 indices apart.
function! s:get_list(changes, ...) abort  " return location list with unique lines
  let [tnr, wnr, bnr] = a:0 ? a:000 : [tabpagenr(), winnr(), bufnr()]
  if a:changes
    let [opts, loc_or_len] = getchangelist(bnr)
  else
    let [opts, loc_or_len] = getjumplist(wnr, tnr)
  endif
  let zero = -1  " position to preserve amid filtering
  let base = bufnr() == bnr ? len(opts) - loc_or_len : 0
  for idx in range(len(opts))
    let iloc = base + idx - len(opts)  " navigation required to arrive at positions
    let zero = iloc == 0 ? 0 : zero
    let opts[idx]['loc'] = iloc  " e.g. base = 0, idx = n - 1, -> loc = -1
  endfor
  let opts = filter(opts,
    \ {idx, val -> val.loc == zero || !empty(join(getbufline(bnr, val.lnum), ''))})
  let opts = filter(copy(opts),
    \ {idx, val -> val.loc == zero || empty(filter(opts[idx + 1:idx + 20], 'v:val.lnum == ' . val.lnum))})
  let iloc = index(map(copy(opts), 'v:val.loc'), 0)
  let iloc = iloc < 0 ? len(opts) : iloc
  return [opts, iloc]
endfunction

" Navigate jump and change lists
" Todo: Make this compatible with 'getmarklist()' and support mark navigation.
" Note: The getjumplist (getchangelist) functions return the length of the list
" instead of the current position for external windows, so when switching from
" current window, navigate to the top of the list before the requested user position.
function! s:feed_list(changes, iloc, ...) abort
  " vint: -ProhibitUnnecessaryDoubleQuote
  let [key1, key2] = a:changes ? ["g;", "g,"] : ["\<C-o>", "\<C-i>"]
  let [tnr, wnr] = a:0 ? a:000 : [tabpagenr(), winnr()]
  let bnr = bufnr()  " ensure buffer has not changed
  exe tnr . 'tabnext' | exe wnr . 'wincmd w'
  let init = bnr == bufnr() ? '' : '1000' . key2  " initialize at end
  let ikey = a:iloc > 0 ? key2 : key1  " motion key
  let keys = init . abs(a:iloc) . ikey  " go to selection
  call feedkeys(keys . 'zv', 'n')
endfunction
function! s:goto_list(changes, ...) abort  " navigate to nth location in list
  let cnt = a:0 ? a:1 : v:count
  if cnt == 0 | return | endif
  let [opts, idx] = s:get_list(a:changes)
  let jdx = idx + cnt
  let name = a:changes ? 'change' : 'jump'
  let direc = cnt < 0 ? 'start' : 'end'
  if abs(cnt) == 1 && (jdx < 0 || jdx >= len(opts))
    echohl WarningMsg
    echom 'Error: At ' . direc . ' of ' . name . 'list'
    echohl None | return
  endif
  let value = (jdx + 1) . '/' . len(opts)
  let name = toupper(name[0]) . name[1:]
  let msg = "echom '" . name . ' location: ' . value . "'"
  call s:feed_list(a:changes, opts[jdx]['loc'])
  call feedkeys("\<Cmd>" . msg . "\<CR>", 'n')
endfunction

" Generate location list
" Note: Here 'loc' indicates the negative <C-o> (g;) or positive <C-i> (g,) presses
" required to arrive at a given position in the location list (change list). If the
" list is from another buffer then getjumplist (getchangelist) only returns the length
" of the list not the position, so will always start at the top of the list after
" switching buffers before navigating to the requested position with key presses.
function! s:fmt_list(snr, tnr, wnr, bnr, item) abort
  let format = '%6s  %3d:%1d %5d %3d  %s'
  let iloc = get(a:item, 'loc', 0)  " should be present
  let head = printf('%4d', -iloc)  " backwards positive
  let head = iloc == 0 ? '>' . head : head
  let tail = get(getbufline(a:bnr, a:item.lnum), 0, '')
  let line = printf(format, head, a:tnr, a:wnr, a:item.lnum, a:item.col, tail)
  let line = substitute(line, '[0-9]\+', '\=' . a:snr . 'yellow(submatch(0), "Number")', '')
  return line
endfunction
function! s:list_sink(changes, line) abort
  if a:line =~# '^\s*>\s*$' | return | endif
  let regex = '^\s*\([+-]\?\d\+\)\s\+\(\d\+\):\(\d\+\)'  " -1 2:1 -> loc 1 tab 2 win 1
  let parts = matchlist(a:line, regex, '', '')
  if empty(parts)
    echohl ErrorMsg
    echom "Error: Invalid selection '" . a:line . "'"
    echohl None | return
  endif
  let [iloc, tnr, wnr; rest] = map(parts[1:], 'str2nr(v:val)')
  return s:feed_list(a:changes, -iloc, tnr, wnr)  " backwards is positive
endfunction
function! s:list_source(changes) abort
  let snr = utils#find_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let name = printf('%6s', a:changes ? 'change' : 'jump')
  let paths = map(tags#buffer_paths(), 'resolve(v:val[1])')  " sorted by recent use
  if paths[0] != expand('%:p') | call insert(paths, expand('%:p')) | endif
  let table = [name . '  tab:w  line col  text/file']
  for path in paths
    let bnr = bufnr(resolve(path))
    if bnr == -1 | continue | endif
    let wid = bnr == bufnr() ? win_getid() : get(win_findbuf(bnr), 0, 0)
    let [tnr, wnr] = win_id2tabwin(wid)  " tab and window number
    let [opts, iloc] = s:get_list(a:changes, tnr, wnr, bnr)
    let items = map(opts, {idx, val -> s:fmt_list(snr, tnr, wnr, bnr, val)})
    let items = slice(items, -min([&l:history - len(table), len(items)]))
    let head = bnr == bufnr() && iloc == len(opts)
    call extend(table, head ? [' >'] : [])
    call extend(table, reverse(items))  " recent changes first
    if len(table) >= &l:history | break | endif  " reached maximum number of items
  endfor
  return table
endfunction

" Overrides of FZF :Jumps and :Changes
" Note: Changelist is managed from the top-down by filtering out double and empty-line
" entries or entries with invalid lines, then navigating using using open_drop and
" setpos('.', ...) instead of the native g,/g; keys. Compare with jumplist above.
" Note: This is needed to fix issue where getbufline() output can be empty (filter
" function calls this function and assumes non-empty) and because the default FZF flag
" --bind start:pos:etc was yielding errors. Not sure why but maybe issue with .fzf fork
function! mark#goto_jump(...) abort
  return call('s:goto_list', [0] + a:000)
endfunction
function! mark#goto_change(...) abort
  return call('s:goto_list', [1] + a:000)
endfunction
function! s:jump_sink(arg) abort  " first item is key binding
  if len(a:arg) > 1 | return s:list_sink(0, a:arg[-1]) | endif
endfunction
function! s:change_sink(arg) abort  " first item is key binding
  if len(a:arg) > 1 | return s:list_sink(1, a:arg[-1]) | endif
endfunction
function! mark#fzf_jumps(...)
  let snr = utils#find_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let options = {
    \ 'source': s:list_source(0),
    \ 'sink*': function('s:jump_sink'),
    \ 'options': '+m -x --ansi --cycle --scroll-off 999 --sync --header-lines 1 --tiebreak=index --prompt "Jumps> "',
  \ }
  return call(snr . 'fzf', ['jumps', options, a:000])
endfunction
function! mark#fzf_changes(...) abort
  let snr = utils#find_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let options = {
    \ 'source': s:list_source(1),
    \ 'sink*': function('s:change_sink'),
    \ 'options': '+m -x --ansi --cycle --scroll-off 999 --sync --header-lines=1 --tiebreak=index --prompt "Changes> "',
  \ }
  return call(snr . 'fzf', ['changes', options, a:000])
endfunction

" Override of FZF :Marks to implement :Drop switching
" Note: Normally the fzf function calls `A-Z, and while vim permits multi-file marks,
" it does not have an option to open in existing tabs like 'showbufs' for loclist,
function! mark#next_mark(...) abort
  let cnt = a:0 ? a:1 : v:count1
  let mrk = get(g:, 'mark_name', '')
  if !empty(mrk) && line('.') != line("'" . mrk)
    let cnt -= cnt > 0 ? 1 : -1
    call mark#goto_mark(mrk)
  endif
  call stack#push_stack('mark', 'mark#goto_mark', cnt)
endfunction
function! mark#goto_mark(...) abort
  if !a:0 || empty(a:1) | return | endif
  let mrk = matchstr(a:1, '\S')
  let mrks = getmarklist()
  let mrks = filter(mrks, {idx, val -> val.mark =~# "'" . mrk})
  if empty(mrks)  " avoid 'press enter' due to register
    let cmd = 'echohl WarningMsg | '
    let cmd .= 'echom "Error: Mark ''' . mrk . ''' is unset" | '
    let cmd .= 'echohl None'
  else  " note this does not affect jumplist
    call file#open_drop(mrks[0]['file'])
    let pos = string(mrks[0]['pos'])  " string list
    let cmd = "call setpos('.', " . pos . ')'
  endif
  let g:mark_name = mrk  " mark stack navigation
  call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
endfunction
function! mark#fzf_marks(...) abort
  let snr = utils#find_snr('/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let lines = split(execute('silent marks'), "\n")
  let options = {
    \ 'source': extend(lines[0:0], map(lines[1:], 'call(' . snr . 'format_mark, [v:val])')),
    \ 'options': '+m -x --ansi --tiebreak=index --header-lines 1 --tiebreak=begin --prompt "Marks> "',
    \ 'sink': function('stack#push_stack', ['mark', 'mark#goto_mark']),
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
    call stack#pop_stack('mark', mrk)
  endfor
  call feedkeys("\<Cmd>echom 'Deleted marks: " . join(mrks, ' ') . "'\<CR>", 'n')
endfunction

" Add the mark and highlight the line
function! mark#set_marks(mrk) abort
  let highlights = get(g:, 'mark_highlights', {})
  let g:mark_name = a:mrk  " mark stack
  let g:mark_highlights = highlights
  call feedkeys('m' . a:mrk, 'n')  " apply the mark
  call stack#pop_stack('mark', a:mrk)  " update mark stack
  call stack#push_stack('mark', '', a:mrk)  " update mark stack
  let name = 'mark_'. (a:mrk =~# '\u' ? 'upper_'. a:mrk : 'lower_' . a:mrk)
  let base = a:mrk =~# '\u' ? 65 : 97
  let idx = a:mrk =~# '\a' ? char2nr(a:mrk) - base : 0
  if has_key(highlights, a:mrk)
    call s:match_delete(highlights[a:mrk][1])
    call remove(highlights[a:mrk], 1)
  else  " sign not defined
    let gui_color = s:gui_colors[idx % len(s:gui_colors)]
    let cterm_color = s:cterm_colors[idx % len(s:cterm_colors)]
    exe 'highlight ' . name . ' ctermbg=' . cterm_color . ' guibg=' . gui_color
    let highlights[a:mrk] = [[gui_color, cterm_color]]
    if s:use_signs | call sign_define(name, {'linehl': name, 'text': "'" . a:mrk}) | endif
  endif
  if s:use_signs
    let sid = s:sign_id | let s:sign_id += 1
    call add(highlights[a:mrk], sid)
    call sign_place(sid, '', name, '%', {'lnum': line('.')})  " empty group critical
  else
    let regex = '.*\%''' . a:mrk . '.*'
    let hlid = matchadd(name, regex, 0)
    call add(highlights[a:mrk], hlid)
  endif
endfunction
