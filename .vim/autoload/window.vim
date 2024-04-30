"-----------------------------------------------------------------------------"
" Utilities for vim windows and sessions
"-----------------------------------------------------------------------------"
" Close general windows and tabs
" Note: Currently codi emits annoying error messages when turning on/off but
" still works so suppress messages here.
" Note: Calling quit inside codi buffer triggers 'attempt to close buffer
" that is in use' error so instead return to main window and toggle codi.
scriptencoding utf-8
function! s:close_codi() abort
  let ftypes = map(tabpagebuflist(), "getbufvar(v:val, '&filetype', '')")
  if &filetype ==# 'codi'
    wincmd p | silent! Codi!!
  elseif index(ftypes, 'codi') != -1
    silent! Codi!!
  endif
endfunction
function! window#close_panes(...) abort
  let bang = a:0 && a:1 ? '!' : ''
  let main = get(b:, 'tabline_bufnr', bufnr())
  call map(popup_list(), 'popup_close(v:val)')
  call s:close_codi()
  for bnr in tabpagebuflist()
    exe bnr == main ? '' : bufwinnr(bnr) . 'windo quit' . bang
  endfor
  call feedkeys("\<Cmd>normal! zvzzze\<CR>", 'n')
endfunction
function! window#close_pane(...) abort
  let bang = a:0 && a:1 ? '!' : ''
  let [cnt, tnr] = [tabpagenr('$'), tabpagenr()]
  let islast = cnt == tabpagenr()
  let iscodi = &l:filetype ==# 'codi'
  call s:close_codi()
  exe iscodi ? '' : 'quit' . bang
  if tnr != cnt && cnt != tabpagenr('$') | silent! tabprevious | endif
  call feedkeys("\<Cmd>normal! zzze\<CR>", 'n')
endfunction
function! window#close_tab(...) abort
  let bang = a:0 && a:1 ? '!' : ''
  let [cnt, tnr] = [tabpagenr('$'), tabpagenr()]
  call s:close_codi()
  if cnt == 1 | quitall | else
    exe 'tabclose' . bang | if tnr != cnt | silent! tabprevious | endif
  endif
  call feedkeys("\<Cmd>normal! zvzzze\<CR>", 'n')
endfunction

" Perform action conditional on insert-mode popup or cmdline wild-menu state
" Note: This supports hiding complete-mode options or insert-mode popup menu
" before proceeding with other actions. See vimrc for details
function! window#close_popup(map, ...) abort
  let s = a:0 > 1 && a:2 ? '' : a:map
  if a:0 && a:1 > 1  " select item or perform action
    let [map1, map2, map3] = ["\<C-y>" . s, "\<C-n>\<C-y>" . s, a:map]
  elseif a:0 && a:1 > 0  " select item only if scrolled
    let [map1, map2, map3] = ["\<C-y>" . s, a:map, a:map]
  else  " exit popup or perform action
    let [map1, map2, map3] = ["\<C-e>" . s, "\<C-e>" . s, a:map]
  endif
  let state = get(b:, 'scroll_state', 0) | let b:scroll_state = 0
  return state && pumvisible() ? map1 : pumvisible() ? map2 : map3
endfunction
function! window#close_wild(map, ...) abort
  let state = get(b:, 'complete_state', 0)  " tabbed through entries
  if a:0 && a:1 || !state && !wildmenumode()
    let [keys1, keys2] = ['', a:map]
    let b:complete_state = state
  else  " e.g. cursor motions
    let [pos, line] = [getcmdpos(), getcmdline()]  " pos 1 is string index 0
    let keys1 = "\<C-c>\<Cmd>redraw\<CR>:" . line . a:map
    let keys2 = pos >= len(line) && a:map ==# "\<Right>" ? "\<Tab>" : ''
    let b:complete_state = 0  " manually disabled
  endif
  call feedkeys(keys1, 'n') | call feedkeys(keys2, 'tn') | return ''
endfunction

" Change window size in given direction
" Note: Vim :resize and :vertical resize expand the bottom side and right side of the
" panel by default (respectively) unless we are on the rightmost or bottommost panel.
" This counts the panels in each direction to figure out the correct sign for mappings
function! window#count_panes(...) abort
  let panes = 1
  for direc in a:000
    let wnum = 1
    let prev = winnr()
    while prev != winnr(wnum . direc)
      let prev = winnr(wnum . direc)
      let wnum += 1
      let panes += 1
      if panes > 50
        echohl WarningMsg
        echom 'Error: Failed to count window panes'
        echohl None
        let panes = 1
        break
      endif
    endwhile
  endfor
  return panes
endfunction
function! window#change_width(count) abort
  let wnum = window#count_panes('l') == 1 ? winnr('h') : winnr()
  call win_move_separator(wnum, a:count)
endfunction
function! window#change_height(count) abort
  let wnum = window#count_panes('j') == 1 ? winnr('k') : winnr()
  call win_move_statusline(wnum, a:count)
endfunction

" Return standard window width and height
" Note: Numbers passed to :resize exclude tab and cmd lines but numbers passed to
" :vertical resize include entire window (i.e. ignoring sign and number columns).
function! window#get_width(...) abort
  return call('s:get_size', [1] + a:000)
endfunction
function! window#get_height(...) abort
  return call('s:get_size', [0] + a:000)
endfunction
function! window#default_width(...) abort
  exe 'vertical resize ' . call('s:get_size', [1] + a:000)
endfunction
function! window#default_height(...) abort
  exe 'resize ' . call('s:get_size', [0] + a:000)
endfunction
function! window#default_size(...) abort
  call call('window#default_width', a:000) | call call('window#default_height', a:000)
endfunction
function! s:get_size(width, ...) abort
  setlocal cmdheight=1  " hard override
  let tabheight = &showtabline > 1 || &showtabline == 1 && tabpagenr('$') > 1
  if a:width  " window width
    let direcs = ['l', 'h']
    let size = &columns
  else  " window height
    let direcs = ['j', 'k']
    let size = &lines - tabheight - 2  " statusline and commandline
  endif
  let panel = bufnr() != get(b:, 'tabline_bufnr', bufnr())
  let panes = call('window#count_panes', direcs)
  let size1 = size - panes + 1  " e.g. 2 panes == 1 divider
  let size2 = float2nr(ceil(0.23 * size1))
  if !a:0  " inferred size
    if !panel || panes == 1
      return size1
    else
      return size2
    endif
  else  " scaling or default
    if type(a:1)  " scaled window
      return a:1 * size1
    elseif a:1  " main window
      return size1 - size2
    else  " panel window
      return size2
    endif
  endif
endfunction

" Generate table of tabs and paths
" Note: This sorts by recent access to help replace :Buffers
function! s:tab_source(...) abort
  let nprocess = 20  " maximum tablines to process
  let ndigits = len(string(tabpagenr('$')))
  let lines = []
  for path in tags#get_paths()
    let bnr = bufnr(path)
    let winids = win_findbuf(bnr)  " iterate tabs
    if empty(winids) | continue | endif
    let staged = getbufvar(bnr, 'tabline_staged_changes', 0)
    let unstaged = getbufvar(bnr, 'tabline_staged_changes', 0)
    let process = len(lines) < nprocess || staged || unstaged
    let base = parse#get_root(path)  " see also vim-tags/autoload/s:path_name()
    let head = fnamemodify(fnamemodify(base, ':h'), ':p')  " trailing slash
    let ibase = !empty(base) && strpart(path, 0, len(base)) ==# base
    let icwd = !empty(base) && strpart(getcwd(), 0, len(base)) ==# base
    if a:0 && a:1 && ibase && !icwd
      let name = strpart(path, len(head))
    else  " show relative path
      let name = RelativePath(path)
    endif
    let flags = TablineFlags(path, process) . ' '  " limit processing
    let hunks = getbufvar(bnr, 'gitgutter', {})
    let [acnt, mcnt, rcnt] = get(hunks, 'summary', [0, 0, 0])
    for [key, cnt] in [['+', acnt], ['~', mcnt], ['-', rcnt]]
      if !empty(cnt) | let flags .= key . cnt | endif
    endfor
    for winid in winids  " iterate windows
      let [tnr, wnr] = win_id2tabwin(winid)
      let lnr = line('.', winid)
      let pad = repeat(' ', ndigits - len(string(tnr)))
      let head = pad . tnr . ':' . wnr . ':' . lnr . ':' . path . ': '
      call add(lines, head . name . flags)
    endfor
  endfor | return lines
endfunction

" Helper functions for selecting tabs
" Note: This handles fzf output lines
function! window#goto_tab(item) abort
  if empty(a:item) | return | endif
  let [tnr, wnr] = s:tab_sink(a:item)
  if tnr == 0 || wnr == 0 | return | endif
  exe tnr ? tnr . 'tabnext' : ''
  exe wnr ? wnr . 'wincmd w' : ''
endfunction
function! window#move_tab(item) abort
  if empty(a:item) | return | endif
  let [tnr, _] = s:tab_sink(a:item)
  if tnr == tabpagenr() | return | endif
  let tnr = tnr > tabpagenr() ? tnr : tnr - 1
  let tnr = min([max([tnr, 0]), tabpagenr('$')])
  exe 'tabmove ' . tnr
endfunction
function! s:tab_sink(item) abort
  if !type(a:item) | return [a:item, 0] | endif
  let parts = split(a:item, '\(\d\@<=:\|:\s\@=\)')
  if len(parts) < 5 | return [0, 0] | endif
  let [tnr, wnr, lnr, path; rest] = parts
  let flags = '\s\+\(\[.\]\s*\)*'  " tabline flags
  let stats = '\([+-~]\d\+\)*'  " statusline stats
  let name = substitute(trim(join(rest, ':')), flags . stats . '$', '', 'g')
  redraw | echom 'Tab: ' . name
  return [str2nr(tnr), str2nr(wnr)]  " str2nr() returns 0 on error
endfunction

" Go to or move to selected tab
" Note: This displays a list with the tab number file and git status, then positions
" preview window on cursor line.
function! window#fzf_goto(...) abort
  let bang = a:0 ? a:1 : 0
  let opts = fzf#vim#with_preview({'placeholder': '{4}:{3..}'})
  let opts = join(map(get(opts, 'options', []), 'fzf#shellescape(v:val)'), ' ')
  let opts .= " -d : --with-nth 1,5.. --preview-window '+{3}-/2' --no-sort"
  let options = {
    \ 'sink': function('window#goto_tab'),
    \ 'source' : s:tab_source(1),
    \ 'options': opts . ' --prompt="Goto> "',
  \ }
  return fzf#run(fzf#wrap('goto', options, bang)) | return ''
endfunction
function! window#fzf_move(...) abort
  let bang = a:0 ? a:1 : 0
  let opts = fzf#vim#with_preview({'placeholder': '{4}:{3..}'})
  let opts = join(map(get(opts, 'options', []), 'fzf#shellescape(v:val)'), ' ')
  let opts .= " -d : --with-nth 1,5.. --preview-window '+{3}-/2' --no-sort"
  let options = {
    \ 'sink': function('window#move_tab'),
    \ 'source' : s:tab_source(1),
    \ 'options': opts . ' --prompt="Move> "',
  \ }
  return fzf#run(fzf#wrap('move', options, bang)) | return ''
endfunction

" Scroll recent files
" Note: Previously used complicated 'scroll state' method but now just float current
" location to top of stack on CursorHold but always scroll with explicit commands.
" Note: This only triggers after spending time on window instead of e.g. browsing
" across tabs with maps, similar to jumplist. Then can access jumps in each window.
function! window#scroll_stack(count) abort
  let [iloc, _] = stack#get_loc('tab')  " do not auto-detect index
  call window#update_stack(1, iloc)  " update stack and avoid recursion
  call stack#push_stack('tab', function('file#goto_file'), a:count)
  let [iloc, _] = stack#get_loc('tab')  " do not auto-detect index
  call window#update_stack(1, iloc)
endfunction  " possibly not a file
function! window#update_stack(scroll, ...) abort  " set current buffer
  if !v:vim_did_enter
    return
  endif
  let iloc = a:0 > 0 ? a:1 : -1  " location to use
  let verb = a:0 > 1 ? a:2 : 0  " disable message by default
  let skip = index(g:tags_skip_filetypes, &filetype)
  let bname = bufname()  " possibly not a file
  if skip != -1 || line('$') <= 1 || empty(&filetype) || bname =~# '^[![]'
    if len(tabpagebuflist()) > 1 | return | endif
  endif
  let exist = filereadable(bname) || isdirectory(bname)
  let name = exist && !empty(bname) ? fnamemodify(bname, ':p') : bname
  for bnr in tabpagebuflist()
    if !empty(name) | call setbufvar(bnr, 'tab_name', name) | endif
  endfor
  call stack#update_stack('tab', a:scroll, iloc, verb)
  let g:tab_time = localtime()  " previous update time
endfunction

" Insert complete menu items and scroll complete or preview windows (whichever open).
" Note: Used 'verb function! lsp#scroll' to figure out how to detect preview windows
" (also verified lsp#scroll l:window.find does not return popup completion windows)
function! s:scroll_popup(scroll, ...) abort
  let size = a:0 ? a:1 : get(pum_getpos(), 'size', 1)
  let state = get(b:, 'scroll_state', 0)
  let cnt = type(a:scroll) ? float2nr(a:scroll * size) : a:scroll
  let cnt = a:scroll > 0 ? max([cnt, 1]) : min([cnt, -1])
  if type(a:scroll) && state != 0   " disable circular scroll
    let cnt = max([0 - state + 1, cnt])
    let cnt = min([size - state, cnt])
  endif
  let cmax = size + 1  " i.e. nothing selected
  let state += cnt + cmax * (1 + abs(cnt) / cmax)
  let state %= cmax  " only works with positive integers
  let keys = repeat(cnt > 0 ? "\<C-n>" : "\<C-p>", abs(cnt))
  let b:scroll_state = state | return keys
endfunction
function! s:scroll_preview(scroll, ...) abort
  for winid in a:000  " iterate previews
    let info = popup_getpos(winid)
    if !info.visible | continue | endif
    let width = info.core_width  " excluding borders (as with minwidth)
    let height = info.core_height  " excluding borders (as with minheight)
    let cnt = type(a:scroll) ? float2nr(a:scroll * height) : a:scroll
    let cnt = a:scroll > 0 ? max([cnt, 1]) : min([cnt, -1])
    let lmax = max([line('$', winid) - height + 2, 1])  " up to one after end
    let lnum = info.firstline + cnt
    let lnum = min([max([lnum, 1]), lmax])
    let opts = {'firstline': lnum, 'minwidth': width, 'minheight': height}
    call popup_setoptions(winid, opts)
  endfor
  return "\<Cmd>doautocmd User lsp_float_opened\<CR>"
endfunction

" Scroll complete menu or preview popup windows
" Note: This prevents vim's baked-in circular complete menu scrolling.
" Scroll normal mode lines
function! window#scroll_normal(scroll, ...) abort
  let height = a:0 ? a:1 : winheight(0)
  let cnt = type(a:scroll) ? float2nr(a:scroll * height) : a:scroll
  let rev = a:scroll > 0 ? 0 : 1  " forward or reverse scroll
  let cmd = 'call scrollwrapped#scroll(' . abs(cnt) . ', ' . rev . ')'
  return mode() =~? '^[ir]' ? '' : "\<Cmd>" . cmd . "\<CR>"  " only normal mode
endfunction
" Scroll and update the count
function! window#scroll_infer(scroll, ...) abort
  let popup_pos = pum_getpos()
  let preview_ids = popup_list()
  if a:0 && a:1 || !empty(popup_pos)  " automatically returns empty if not present
    return call('s:scroll_popup', [a:scroll])
  elseif !empty(preview_ids)
    return call('s:scroll_preview', [a:scroll] + preview_ids)
  elseif a:0 && !a:1
    return call('window#scroll_normal', [a:scroll])
  else  " default fallback is arrow press
    return a:scroll > 0 ? "\<Down>" : a:scroll < 0 ? "\<Up>" : ''
  endif
endfunction

" Setup preview windows
" Note: Here use a border for small popup windows and no border by default for
" autocomplete. See: https://github.com/prabirshrestha/vim-lsp/issues/594
function! window#setup_preview(...) abort
  for winid in popup_list()
    let info = popup_getpos(winid)
    if !info.visible | continue | endif
    let scroll = line('$', winid) > info.core_height
    let opts = {'dragall': 1, 'scrollbar': scroll}
    if a:0 && a:1  " previously if empty(pum_getpos())
      let opts.border  = [0, 1, 0, 1]
      let opts.borderchars  = [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ']
    else
      let opts.border  = [1, 1, 1, 1]
      let opts.borderchars  = ['──', '│', '──', '│', '┌', '┐', '┘', '└']
    endif
    call popup_setoptions(winid, opts)
  endfor
endfunction

" Setup panel windows
" Note: Tried setting 'nomodifiable' but causes errors for e.g. shell#job_win()
" logs. Handle switch#copy(1) from vimrc (but set nolist required for e.g. man)
function! window#setup_panel(...) abort
  setlocal nolist nocursorline colorcolumn=
  let g:ft_man_folding_enable = 1  " see :help Man
  let [nleft, nright] = [window#count_panes('h'), window#count_panes('l')]
  nnoremap <buffer> q <Cmd>silent! call window#close_pane()<CR>
  nnoremap <buffer> <C-w> <Cmd>silent! call window#close_pane()<CR>
  if a:0 && a:1  " editable window
    return
  endif
  for [char, frac] in [['d', 0.5], ['u', -0.5]]
    exe 'noremap <expr> <nowait> <buffer> ' . char . ' window#scroll_normal(' . frac . ')'
  endfor
  for char in 'uUrRxXpPdDcCaAiIoO'  " in lieu of set nomodifiable
    if !get(maparg(char, 'n', 0, 1), 'buffer', 0)  " preserve buffer-local maps
      exe 'nmap <buffer> ' char . ' <Nop>'
    endif
    if char =~? '[aioc]' && !get(maparg('g' . char, 'n', 0, 1), 'buffer', 0)
      exe 'nmap <buffer> g' . char . ' <Nop>'
    endif
  endfor
endfunction

" Setup or show specific panel windows
" Note: These are for managing plugins and viewing directory contents
function! window#show_health() abort
  exe 'CheckHealth' | setlocal foldlevel=1 syntax=checkhealth.markdown | doautocmd BufRead
endfunction
function! window#show_manager() abort
  silent tabnew | if bufexists('lsp-manager')
    buffer lsp-manager
  else  " new manager
    silent exe 'LspManage' | call window#setup_panel(0) | silent file lsp-manage
  endif
  redraw | echom 'Type i to install, or x to uninstall, b to open browser, ? to show description'
endfunction
