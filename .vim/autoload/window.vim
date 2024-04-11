"-----------------------------------------------------------------------------"
" Utilities for vim windows and sessions
"-----------------------------------------------------------------------------"
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
    silent! exe 'Codi!!'
  endif
  for bnr in tabpagebuflist()
    exe bnr == main ? '' : bufwinnr(bnr) . 'windo quit' . bang
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
function! window#default_width(...) abort
  return call('window#default_size', [1] + a:000)
endfunction
function! window#default_height(...) abort
  return call('window#default_size', [0] + a:000)
endfunction
function! window#default_size(width, ...) abort
  let tabheight = &showtabline > 1 || &showtabline == 1 && tabpagenr('$') > 1
  setlocal cmdheight=1  " hard override
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

" Generate tab source and sink
" Note: This sorts by recent access to help replace :Buffers
" Warning: Critical to keep up-to-date with g:tabline_skip_filetypes name
scriptencoding utf-8
let s:path_roots = {}
function! s:tab_sink(item) abort
  if !type(a:item) | return [a:item, ''] | endif
  let [tnr; parts] = split(a:item, ':')
  let flags = '\s\+\(\[.\]\s*\)*'  " tabline flags
  let stats = '\([+-~]\d\+\)*'  " statusline stats
  let path = join(parts, ':')  " e.g. 'fugitive:path'
  let path = substitute(path, flags . stats . '$', '', 'g')
  let path = substitute(path, '\(^\s\+\|\s\+$\)', '', 'g')
  let path = get(s:path_roots, path, '') . path
  call file#echo_path('tab', path)
  let icloud = 'iCloud'  " actual path is resolved
  if strpart(path, 0, len(icloud)) ==# icloud
    let path = resolve(expand('~/icloud')) . strpart(path, len(icloud))
  endif
  return [str2nr(tnr), path]  " returns zero on error
endfunction
function! s:tab_source() abort
  let s:path_roots = {}
  let nprocess = 20  " maximum tablines to process
  let ndigits = len(string(tabpagenr('$')))
  let values = []
  let pairs = tags#buffer_paths()
  for idx in range(len(pairs))
    let [tnr, path] = pairs[idx]
    let bnr = bufnr(path)
    let staged = getbufvar(bnr, 'tabline_staged_changes', 0)
    let unstaged = getbufvar(bnr, 'tabline_staged_changes', 0)
    let process = idx < nprocess || staged || unstaged
    let base = tag#find_root(path)  " see also vim-tags/autoload/s:path_name()
    let root = fnamemodify(fnamemodify(base, ':h'), ':p')  " trailing slash
    let ibase = !empty(base) && strpart(path, 0, len(base)) ==# base
    let icwd = !empty(base) && strpart(getcwd(), 0, len(base)) ==# base
    if ibase && !icwd
      let name = strpart(path, len(root)) | let s:path_roots[name] = root
    elseif exists('*RelativePath')
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

" Go to or move to selected tab
" Note: This displays a list with the tab number and the file. As with other
" commands sorts by recent access time for ease of use.
function! s:goto_tab(item) abort
  let [tnr, path] = s:tab_sink(a:item)
  exe tnr . 'tabnext'
endfunction
function! s:move_tab(item) abort
  let [tnr, path] = s:tab_sink(a:item)
  if tnr == 0 || tnr == tabpagenr()
    return
  elseif tnr > tabpagenr() && v:version[0] > 7
    exe 'tabmove ' . min([tnr, tabpagenr('$')])
  else
    exe 'tabmove ' . min([tnr - 1, tabpagenr('$')])
  endif
endfunction
function! window#fzf_tabs(...) abort
  if a:0 && a:1
    return s:goto_tab(a:1)
  endif
  call fzf#run(fzf#wrap({
    \ 'source': s:tab_source(),
    \ 'options': '--no-sort --prompt="Tab> "',
    \ 'sink': function('s:goto_tab'),
  \ }))
endfunction
function! window#fzf_move(...) abort
  if a:0 && a:1
    return s:move_tab(a:1)
  endif
  call fzf#run(fzf#wrap({
    \ 'source': s:tab_source(),
    \ 'options': '--no-sort --prompt="Move> "',
    \ 'sink': function('s:move_tab'),
  \ }))
endfunction

" Scroll recent files
" Note: Previously used complicated 'scroll state' method but now just float current
" location to top of stack on CursorHold but always scroll with explicit commands.
" Note: This only triggers after spending time on window instead of e.g. browsing
" across tabs with maps, similar to jumplist. Then can access jumps in each window.
function! window#scroll_stack(...) abort
  let cnt = a:0 ? a:1 : v:count1
  let [iloc, _] = stack#get_loc('tab')  " do not auto-detect index
  call window#update_stack(1, iloc)  " update stack and avoid recursion
  try
    set eventignore=BufEnter,BufLeave
    call stack#push_stack('tab', function('file#open_drop'), cnt)
  finally
    set eventignore=
  endtry
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

" Show helper windows
" Note: These are for managing plugins and viewing directory contents
" Warning: Critical to load vim-vinegar plugin/vinegar.vim before setup_netrw()
let s:map_from = [['n', '<CR>', 't'], ['n', '.', 'gn'], ['n', ',', '-'], ['nx', ';', '.']]
function! window#setup_quickfix() abort
  exe 'nnoremap <buffer> <CR> <CR>zv'
endfunction
function! window#setup_taglist() abort
  for char in 'ud' | silent! exe 'nunmap <buffer> ' . char | endfor
endfunction
function! window#setup_vinegar() abort
  call call('utils#map_from', s:map_from) | for char in 'fbFL' | silent! exe 'unmap <buffer> q' . char | endfor
endfunction
function! window#show_health() abort
  exe 'CheckHealth' | setlocal foldlevel=1 syntax=checkhealth.markdown | doautocmd BufRead
endfunction
function! window#show_netrw(cmd, local) abort
  let base = a:local ? fnamemodify(@%, ':p:h') : tag#find_root(@%)
  let [width, height] = [window#default_width(0), window#default_height(0)]
  exe a:cmd . ' ' . base | goto
  exe a:cmd =~# 'vsplit' ? 'vert resize ' . width : 'resize ' . height 
endfunction
function! window#show_manager() abort
  silent tabnew | if bufexists('lsp-manager')
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

" Setup panel windows
" Note: Handle 'copy toggle' settings from vimrc (although nolist still required e.g.
" for man pages for some reason). Tried setting 'nomodifiable' but causes errors for
" e.g. shell#job_win() logs, so instead manually disable common normal-mode maps.
" Warning: Critical error happens if try to auto-quit when only panel window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with session#close_tab().
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
