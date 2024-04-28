"-----------------------------------------------------------------------------"
" Utilities for scrolling and iterating
"-----------------------------------------------------------------------------"
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
    \ {idx, val -> val.loc == zero || !a:changes && val.bufnr != bnr || !empty(join(getbufline(bnr, val.lnum), ''))})
  let opts = filter(copy(opts),
    \ {idx, val -> val.loc == zero || empty(filter(opts[idx + 1:idx + 20], 'v:val.lnum == ' . val.lnum))})
  let iloc = index(map(copy(opts), 'v:val.loc'), 0)
  let iloc = iloc < 0 ? len(opts) : iloc
  return [opts, iloc]
endfunction

" Navigate jump and change lists
" Note: This improves on native bug where e.g. going backwards in jumplist (changelist)
" from top of changelist (jumplist) keeps the 'current position' at top of stack so
" cannot return with forward press. Note 'col' stored in lists is relative to zero.
" Note: The getjumplist (getchangelist) functions return the length of the list
" instead of the current position for external windows, so when switching from
" current window, jump to top of the list before the requested user position. Also
" scroll additionally by minus 1 if 'current' position is beyond end of the list.
function! s:feed_list(changes, iloc, ...) abort
  " vint: -ProhibitUnnecessaryDoubleQuote
  let [key1, key2] = a:changes ? ["g;", "g,"] : ["\<C-o>", "\<C-i>"]
  let [tnr, wnr; rest] = a:0 ? a:000 : [tabpagenr(), winnr(), 0]
  silent exe tnr . 'tabnext'
  silent exe wnr . 'wincmd w'
  let init = tnr == tabpagenr() && wnr == winnr() ? '' : '1000' . key2
  let ikey = a:iloc > 0 ? key2 : key1  " motion key
  let ikeys = a:iloc == 0 ? '' : abs(a:iloc) . ikey
  call feedkeys(init . ikeys . 'zvzzze', 'n')
endfunction
function! s:next_list(changes, count) abort  " navigate to nth location in list
  let [opts, idx] = s:get_list(a:changes)
  let lnum = get(get(opts, -1, {}), 'lnum', 0)
  let cnum = get(get(opts, -1, {}), 'col', 0)
  let bnum = get(get(opts, -1, {}), 'bufnr', bufnr())
  let iend = bnum == bufnr() && lnum == line('.') && cnum + 1 == col('.')
  let idel = iend && idx == len(opts) && a:count < 0 ? -1 : 0
  let jdx = idx + a:count + idel  " jump from e.g. '11'/10 to 9/10
  let name = a:changes ? 'change' : 'jump'
  let head = toupper(name[0]) . name[1:] . ' location: '
  if jdx >= 0 && jdx < len(opts)  " jump to location
    call s:feed_list(a:changes, opts[jdx]['loc'], tabpagenr(), winnr())
    call feedkeys("\<Cmd>redraw | echom '" . head . (jdx + 1) . '/' . len(opts) . "'\<CR>", 'n')
  elseif !iend && a:count == 1 && jdx == len(opts)  " silently restore position
    if bnum != bufnr() | exe bnum . 'buffer' | endif | call cursor(lnum, cnum + 1)
    call feedkeys("\<Cmd>redraw | echom '" . head . jdx . '/' . len(opts) . "'\<CR>", 'n')
  else  " no-op warning message
    redraw | let direc = a:count < 0 ? 'start' : 'end'
    echohl WarningMsg | echom 'Error: At ' . direc . ' of ' . name . 'list' | echohl None
  endif
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
  let ibuf = get(a:item, 'bufnr', a:bnr)  " item buffer
  let head = printf('%4d', -iloc)  " backwards positive
  let head = iloc == 0 ? '>' . head : head
  if ibuf == a:bnr  " show the text
    let tail = get(getbufline(ibuf, a:item.lnum), 0, '')
  else  " show the path as with :jumps
    let tail = expand('#' . ibuf . ':p')
  endif
  let line = printf(format, head, a:tnr, a:wnr, a:item.lnum, a:item.col, tail)
  let line = substitute(line, '[0-9]\+', '\=' . a:snr . 'yellow(submatch(0), "Number")', '')
  return line
endfunction
function! s:list_sink(changes, line) abort
  if a:line =~# '^\s*>\s*$' | return | endif
  let regex = '^\s*\([+-]\?\d\+\)\s\+\(\d\+\):\(\d\+\)'  " -1 2:1 -> loc 1 tab 2 win 1
  let regex .= '\s\+\(\d\+\)\s\+\(\d\+\)\s\+\(.*\)$'  " lnum cnum <text_or_file>
  let parts = matchlist(a:line, regex, '', '')
  let g:length = len(parts)
  if empty(parts)
    redraw | echohl ErrorMsg
    echom "Error: Invalid selection '" . a:line . "'"
    echohl None | return
  endif
  let [iloc, tnr, wnr, _, _, item; rest] = map(parts[1:], 'str2nr(v:val)')
  return s:feed_list(a:changes, -iloc, tnr, wnr)
endfunction
function! s:list_source(changes) abort
  let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let name = printf('%6s', a:changes ? 'change' : 'jump')
  let paths = map(tags#get_paths(), 'resolve(v:val)')  " sorted by recent use
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
    call extend(table, bnr == bufnr() && iloc == len(opts) ? [' >'] : [])
    call extend(table, reverse(items))  " recent changes first
    if len(table) >= &l:history | break | endif  " reached maximum number of items
  endfor
  return table
endfunction

" Override fzf :Jumps and :Changes
" Note: This implements :Lines navigation across existing open windows and tabs. Native
" version handles buffer switching separately from s:action_for() invocation.
" Note: This fixes :Jumps issue where getbufline() output can be empty (filter assumes
" this is non-empty) and because default flag --bind start:post:etc caused error.
" Note: Changelist is managed from the top-down by filtering out double and empty-line
" entries or entries with invalid lines, then navigating using using drop_file and
" setpos('.', ...) instead of the native g,/g; keys. Compare with jumplist above.
function! s:jump_sink(arg) abort  " first item is key binding
  return empty(a:arg) ? 1 : s:list_sink(0, a:arg[0])
endfunction
function! s:change_sink(arg) abort  " first item is key binding
   return empty(a:arg) ? 1 : s:list_sink(1, a:arg[0])
endfunction
function! s:lines_sink(arg) abort
  if empty(a:arg) | return | endif
  let parts = split(a:arg[0], "\t", 1)
  silent call file#drop_file(str2nr(parts[0]))
  exe parts[2] | exe 'normal! zvzzze'
endfunction
function! jump#fzf_jumps(...)
  let opts = '+m -x --ansi --cycle --scroll-off 999'
  let opts .= ' --sync --header-lines 1 --tiebreak=index'
  let options = {
    \ 'source': s:list_source(0),
    \ 'sink*': function('s:jump_sink'),
    \ 'options': opts . ' --prompt "Jumps> "',
  \ }
  return fzf#run(fzf#wrap('jumps', options, a:0 ? a:1 : 0))
endfunction
function! jump#fzf_changes(...) abort
  let opts = '+m -x --ansi --cycle --scroll-off 999'
  let opts .= ' --sync --header-lines=1 --tiebreak=index'
  let options = {
    \ 'source': s:list_source(1),
    \ 'sink*': function('s:change_sink'),
    \ 'options': opts . ' --prompt "Changes> "',
  \ }
  return fzf#run(fzf#wrap('changes', options, a:0 ? a:1 : 0))
endfunction
function! jump#fzf_lines(query, ...) abort
  let [show, lines] = fzf#vim#_lines(1)
  let opts = ' --nth ' . (show ? 3 : 2) . '..'
  let opts .= ' --layout=reverse-list --tiebreak=index --extended'
  let opts .= ' --query ' . shellescape(a:query) . ' --ansi --tabstop=1'
  let options = {
    \ 'source': lines,
    \ 'sink*': function('s:lines_sink'),
    \ 'options': opts . ' --prompt "Lines> "',
  \ }
  return fzf#run(fzf#wrap('lines', options, a:0 ? a:1 : 0))
endfunction

" Push current location to top of jumplist
" Warning: The zk/zj/[z/]z motions update jumplist, found out via trial and error
" even though not in :help jump-motions. And note setpos() does not change jumplist
" Note: This prevents resetting when navigating backwards and forwards through
" jumplist or when navigating within paragraph of most recently set jump. Also remap
" 'jumping' motions n/N/{/}/(/)/`/[[/]] by prepending :keepjumps to reduce entries.
" Note: Jumplist is managed from the bottom-up by remapping normal-mode 'jumping'
" motions and conditionally updating jumplist on CursorHold. Still navigate the
" actual jumplist using <C-o>/<C-i> navigation keys. Compare to changelist below.
function! s:range_keepjumps() abort  " used to update jumplist on CursorHold
  let line = line('.')  " cursor line
  let winview = winsaveview()
  let text1 = line == 1 ? 1 : line("'{'") + 1
  let text2 = line == line('$') ? line('$') : line("'}")
  exe 'keepjumps normal! [z' | let fold1 = line('.')
  exe 'keepjumps normal! ]z' | let fold2 = line('.')
  if fold1 == line && fold2 == line  " try outer folds
    exe line | exe 'keepjumps normal! zk'
    let fold1 = line('.') == line ? 1 : line('.') + 1
    exe line | exe 'keepjumps normal! zj'
    let fold2 = line('.') == line ? line('$') : line('.') - 1
  endif
  call winrestview(winview)
  let line1 = max([text1, fold1])
  let line2 = min([text2, fold2])
  return [line1, line2]
endfunction
function! jump#push_jump() abort
  let [keep1, keep2] = s:range_keepjumps()  " current cursor bounds
  let [jumps, jloc] = getjumplist()
  let jprev = line("''")
  if empty(jumps) || empty(jprev)  " force update current jump
    let jlines = []
  else  " previous jump and stack position
    let jlines = [jprev, get(jumps, jloc, jumps[-1])['lnum']]
  endif
  if empty(filter(jlines, {idx, val -> val >= keep1 && val <= keep2}))
    call feedkeys("\<Cmd>normal! m'\<CR>", 'n')
  endif
endfunction

" Navigate words with restricted &iskeyword
" Note: This implements 'g' and 'h' text object motions using word jump mappings.
" Use gw/ge/gb/gm for snake_case and zw/ze/zb/zm for CapitalCaseFooBar or camelCase.
function! jump#next_alpha(motion, mode, ...) abort
  let cmd = 'setlocal iskeyword=' . &l:iskeyword  " vint: next-line -ProhibitUnnecessaryDoubleQuote
  let &l:iskeyword = a:mode ? "a-z,48-57" : "@,48-57,192-255"
  let cnt = a:mode ? s:adjust_count(a:motion) : v:count1
  let action = a:0 ? a:1 ==# 'c' ? "\<Esc>c" : a:1 : ''
  call feedkeys(action . cnt . a:motion . "\<Cmd>" . cmd . "\<CR>", 'n')
endfunction
function! s:adjust_count(motion) abort
  let [line, idx, cnt] = [getline('.'), col('.') - 1, v:count1]
  for _ in range(v:count1)
    if a:motion =~# '^[we]$'  " vint: next-line -ProhibitUsingUndeclaredVariable
      let text = line[idx:]
    else  " reverse search
      let text = join(reverse(split(line[:idx], '\zs')), '')
    endif
    let [_, _, jdx] = matchstrpos(text, '^\s\+')
    if jdx > 0  " leading space
      let idx += a:motion =~# '^[we]$' ? jdx : -jdx | continue
    elseif a:motion ==# 'w'  " forward start of word
      let regex = '^\C[A-Z]\+[a-z]\+'
    elseif a:motion ==# 'b'  " backward start of word
      let regex = '^\C[A-Za-z][a-z]\+[A-Z]\+'
    else  " end of word
      let regex = '^\C[a-z]\+[A-Z]\+'
    endif
    let [_, _, jdx] = matchstrpos(text, regex)
    if jdx < 0 | break | endif
    let cnt += 1  " note jdx is end byte of match end plus 1
    let idx += a:motion =~# '^[we]$' ? jdx : -jdx
  endfor | return cnt
endfunction

" Navigate matches and lists without editing jumplist
" Note: This implements indexed-search directional consistency
" and avoids adding to the jumplist to prevent overpopulation
function! jump#next_jump(...) abort
  return call('s:next_list', [0] + a:000)
endfunction
function! jump#next_change(...) abort
  return call('s:next_list', [1] + a:000)
endfunction
function! jump#next_match(count) abort
  let forward = get(g:, 'indexed_search_n_always_searches_forward', 0)  " default
  if forward && !v:searchforward  " implement 'always forward'
    let map = a:count > 0 ? 'N' : 'n'
  else  " standard direction
    let map = a:count > 0 ? 'n' : 'N'
  endif
  let b:curpos = getcurpos()
  if !empty(@/)
    call feedkeys("\<Cmd>keepjumps normal! " . abs(a:count) . map . "\<CR>", 'n')
  else
    echohl ErrorMsg | echom 'Error: Pattern not set' | echohl None
  endif
  if !empty(@/)
    call feedkeys("\<Cmd>exe b:curpos == getcurpos() ? '' : 'ShowSearchIndex'\<CR>", 'n')
  endif
endfunction

" Navigate location list errors cyclically
" Adding '+ 1 - reverse' fixes vint issue where ]x does not move from final error
" See: https://vi.stackexchange.com/a/14359
function! jump#setup_list() abort
  exe 'nnoremap <buffer> <CR> <CR>zv'
endfunction
function! jump#next_list(count, list, ...) abort
  let cmd = a:list ==# 'loc' ? 'll' : 'cc'
  let func = 'get' . a:list . 'list'
  let reverse = a:0 && a:1
  let params = a:list ==# 'loc' ? [0] : []
  let items = call(func, params)
  call map(items, "extend(v:val, {'idx': v:key + 1})")
  if reverse | call reverse(items) | endif
  if empty(items)
    redraw | echohl ErrorMsg
    echom 'Error: No locations'
    echohl None | return
  endif
  let [lnum, cnum] = [line('.'), col('.')]
  let [cmps, oper] = [[], reverse ? '<' : '>']
  call add(cmps, 'v:val.lnum ' . oper . ' lnum')
  call add(cmps, 'v:val.col ' . oper . ' cnum + 1 - reverse')
  call filter(items, join(cmps, ' || '))
  let idx = get(get(items, 0, {}), 'idx', '')
  if type(idx) != 0
    exe reverse ? line('$') : 1 | call jump#next_list(a:count, a:list, reverse)
  elseif a:count > 1
    exe cmd . ' ' . idx | call jump#next_list(a:count - 1, a:list, reverse)
  else  " jump to error
    exe cmd . ' ' . idx
  endif
  if &l:foldopen =~# 'quickfix' | exe 'normal! zv' | endif
endfunction
