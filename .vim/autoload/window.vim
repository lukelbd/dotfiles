"-----------------------------------------------------------------------------"
" Utilities for vim windows and sessions
"-----------------------------------------------------------------------------"
" Return main buffers in each tab
" Note: This sorts by recent access to help replace :Buffers
" Warning: Critical to keep up-to-date with g:tabline_skip_filetypes name
scriptencoding utf-8
function! window#buffer_source() abort
  let nprocess = 20  " maximum tablines to process
  let ndigits = len(string(tabpagenr('$')))
  let tabskip = get(g:, 'tabline_skip_filetypes', [])  " keep up to date
  let values = []
  let pairs = tags#buffer_paths()
  for idx in range(len(pairs))
    let [tnr, path] = pairs[idx]
    let bnr = bufnr(path)
    let staged = getbufvar(bnr, 'tabline_staged_changes', 0)
    let unstaged = getbufvar(bnr, 'tabline_staged_changes', 0)
    let process = idx < nprocess || staged || unstaged
    if exists('*RelativePath')
      let name = RelativePath(path)
    else
      let name = fnamemodify(path, ':~:.')
    endif
    let pad = repeat(' ', ndigits - len(string(tnr)))
    let flags = TablineFlags(path, process) . ' '  " limit processing
    let hunks =  getbufvar(bnr, 'gitgutter', {})
    let [acnt, mcnt, rcnt] = get(hunks, 'summary', [0, 0, 0])
    for [key, cnt] in [['+', acnt], ['~', mcnt], ['-', rcnt]]
      if !empty(cnt) | let flags .= key . cnt | endif
    endfor
    let value = pad . tnr . ': ' . name . flags  " displayed string
    call add(values, value)
  endfor
  return values
endfunction

" Safely closing tabs and windows
" Note: Currently codi emits annoying error messages when turning on/off but
" still works so suppress messages here.
" Note: Calling quit inside codi buffer triggers 'attempt to close buffer
" that is in use' error so instead return to main window and toggle codi.
function! window#close_panes(...) abort
  let bang = a:0 && a:1 ? '!' : ''
  let main = get(b:, 'tabline_bufnr', bufnr())
  let ftypes = map(tabpagebuflist(), "getbufvar(v:val, '&filetype', '')")
  call map(popup_list(), 'popup_close(v:val)')
  if index(ftypes, 'codi') != -1
    silent! Codi!!
  endif
  for bnr in tabpagebuflist()
    if bnr != main
      exe bufwinnr(bnr) . 'windo quit' . bang
    endif
  endfor
  if index(ftypes, 'gitcommit') == -1 | call feedkeys('zezv', 'n') | endif
endfunction
function! window#close_pane(...) abort
  let bang = a:0 && a:1 ? '!' : ''
  let ntabs = tabpagenr('$')
  let islast = ntabs == tabpagenr()
  let ftypes = map(tabpagebuflist(), "getbufvar(v:val, '&filetype', '')")
  if &filetype ==# 'codi'
    wincmd p | silent! Codi!!
  elseif index(ftypes, 'codi') != -1
    silent! Codi!! | exe 'quit' . bang
  else
    exe 'quit' . bang
  endif
  if ntabs != tabpagenr('$') && !islast
    silent! tabprevious
  endif
  if index(ftypes, 'gitcommit') == -1 | call feedkeys('zv', 'n') | endif
endfunction
function! window#close_tab(...) abort
  let bang = a:0 && a:1 ? '!' : ''
  let ntabs = tabpagenr('$')
  let islast = ntabs == tabpagenr()
  let ftypes = map(tabpagebuflist(), "getbufvar(v:val, '&filetype', '')")
  if &filetype ==# 'codi'
    wincmd p | silent! Codi!!
  elseif index(ftypes, 'codi') != -1
    silent! Codi!!
  endif
  if ntabs == 1 | quitall | else
    exe 'tabclose' . bang | if !islast | silent! tabprevious | endif
  endif
  if index(ftypes, 'gitcommit') == -1 | call feedkeys('zv', 'n') | endif
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
function! window#default_size(width, ...) abort
  if a:width  " window width
    let direcs = ['l', 'h']
    let size = &columns
  else  " window height
    setlocal cmdheight=1  " override in case changed
    let tabheight = &showtabline > 1 || &showtabline == 1 && tabpagenr('$') > 1
    let direcs = ['j', 'k']
    let size = &lines - tabheight - 2  " statusline and commandline
  endif
  let panel = bufnr() != get(b:, 'tabline_bufnr', bufnr())
  let panes = call('window#count_panes', direcs)
  let size = size - panes + 1  " e.g. 2 panes == 1 divider
  let space = float2nr(ceil(0.23 * size))
  if panes == 1
    return size
  elseif a:0 && type(a:1) == 5
    return a:1 * size
  elseif a:0 && a:1 || !a:0 && panel
    return space
  else  " main window
    return size - space
  endif
endfunction
function! window#default_width(...) abort
  return call('window#default_size', [1] + a:000)
endfunction
function! window#default_height(...) abort
  return call('window#default_size', [0] + a:000)
endfunction

" Select from open tabs
" Note: This displays a list with the tab number and the file. As with other
" commands sorts by recent access time for ease of use.
function! s:jump_tab(item) abort
  let [tnr, path] = s:parse_tab(a:item)
  exe tnr . 'tabnext'
endfunction
function! s:parse_tab(item) abort
  if !type(a:item) | return [a:item, ''] | endif
  let [tnr; path] = split(a:item, ':')
  let flags = '\s\+\(\[.\]\s*\)*'  " tabline flags
  let stats = '\([+-~]\d\+\)*'  " statusline stats
  let path = join(path, ':')
  let path = substitute(path, flags . stats . '$', '', 'g')
  let path = substitute(path, '\(^\s\+\|\s\+$\)', '', 'g')
  call file#echo_path('tab', path)
  return [str2nr(tnr), path]  " returns zero on error
endfunction
function! window#jump_tab(...) abort
  if a:0 && a:1
    return s:jump_tab(a:1)
  endif
  call fzf#run(fzf#wrap({
    \ 'source': window#buffer_source(),
    \ 'options': '--no-sort --prompt="Tab> "',
    \ 'sink': function('s:jump_tab'),
  \ }))
endfunction

" Move to selected tab
" Note: This also displays the tab names in case user wants to
" group this file appropriately amongst similar open files.
function! s:move_tab(item) abort
  let [tnr, path] = s:parse_tab(a:item)
  if tnr == 0 || tnr == tabpagenr()
    return
  elseif tnr > tabpagenr() && v:version[0] > 7
    exe 'tabmove ' . min([tnr, tabpagenr('$')])
  else
    exe 'tabmove ' . min([tnr - 1, tabpagenr('$')])
  endif
endfunction
function! window#move_tab(...) abort
  if a:0 && a:1
    return s:move_tab(a:1)
  endif
  call fzf#run(fzf#wrap({
    \ 'source': window#buffer_source(),
    \ 'options': '--no-sort --prompt="Move> "',
    \ 'sink': function('s:move_tab'),
  \ }))
endfunction

" Show helper windows
" Note: These are for lsp management and viewing directory contents
function! window#setup_dir() abort
  call utils#switch_maps(['<CR>', 't', 'n'], ['t', '<CR>', 'n'])
  for char in 'fbFL' | silent! exe 'unmap <buffer> q' . char | endfor
endfunction
function! window#show_dir(cmd, local) abort
  let base = a:local ? fnamemodify(resolve(@%), ':p:h') : tag#find_root(@%)
  exe a:cmd . ' ' . base | exe 'vert resize ' . window#default_width(1)
  exe 'resize ' . window#default_height(1) | goto
endfunction
function! window#show_health() abort
  exe 'CheckHealth'
  setlocal foldlevel=1 syntax=checkhealth.markdown
  doautocmd BufRead
endfunction
function! window#show_manager() abort
  silent tabnew
  if bufexists('lsp-manager')
    buffer lsp-manager
  else  " new manager
    silent exe 'LspManage' | call window#setup_panel(0) | silent file lsp-manage
  endif
  redraw | echom 'Type i to install, or x to uninstall, b to open browser, ? to show description'
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

" Setup panel windows. Mode can be 0 (not editable) or 1 (editable).
" Warning: Setting 'modifiable' tends to cause errors e.g. for log files run with
" shell#job_win() or other internal stuff. So instead just disable normal mode
" commands that could accidentally modify text (aside from d used for scrolling).
" Warning: Critical error happens if try to auto-quit when only panel window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with session#close_tab().
function! window#setup_panel(...) abort
  setlocal nonumber norelativenumber nocursorline signcolumn=yes 
  let g:ft_man_folding_enable = 1  " see :help Man
  let [nleft, nright] = [window#count_panes('h'), window#count_panes('l')]
  nnoremap <buffer> q <Cmd>silent! call window#close_pane()<CR>
  nnoremap <buffer> <C-w> <Cmd>silent! call window#close_pane()<CR>
  if a:0 && a:1  " editable window
    return
  else  " standard window
    setlocal nolist colorcolumn=
  endif
  for [char, frac] in [['d', 0.5], ['u', -0.5]]
    exe 'noremap <expr> <nowait> <buffer> ' . char . ' iter#scroll_normal(' . frac . ')'
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
