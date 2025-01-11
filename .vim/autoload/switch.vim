"-----------------------------------------------------------------------------"
" Utilities for switching stuff on and off
"-----------------------------------------------------------------------------"
" Helper function
function! s:echo_state(text, toggle, ...)
  if !a:0 || !a:1
    let [str1, str2] = a:text =~# 'folds' ? ['open', 'clos'] : ['enabl', 'disabl']
    let state = a:toggle ? str1 . 'ed' : str2 . 'ed'
    redraw | echo toupper(a:text[0]) . a:text[1:] . ' ' . state . '.'
  endif
endfunction

" Toggle ALE syntax checking
" NOTE: Previously also toggled 'vim-lsp' diagnostics sent to ale by 'vim-lsp-ale' but
" this is unnecessary since source code indicates the bridge is only triggered when
" autocmd User ALEWantResults event is raised (i.e. disabling ALE is sufficient).
" call lsp#ale#enable() | call lsp#ale#disable()  " vim-lsp-ale toggles
function! switch#ale(...) abort
  let state = get(b:, 'ale_enabled', 1)  " enabled by default, disable for first time
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle || !exists(':ALEEnableBuffer')
    return
  elseif toggle  " enable and set b:ale_enabled = 1
    ALEEnableBuffer
  else  " remove signs and highlights then disable and set b:ale_enabled = 0
    ALEResetBuffer | ALEDisableBuffer
  endif
  let b:ale_enabled = toggle  " ensure always applied in case API changes
  call s:echo_state('ale linters', toggle, suppress)
endfunction

" Autosave toggle (autocommands are local to buffer as with codi)
" We use augroups with buffer-specific names to prevent conflict
" NOTE: There are also 'autowrite' and 'autowriteall' settings that will automatically
" write before built-in file jumping (e.g. :next, :last, :rewind, ...) and tag jumping
" (e.g. :tag, <C-]>, ...) but they are global, and the below effectively enables
" these settings. So do not bother with them.
function! switch#autosave(...) abort
  let state = get(b:, 'autosave_enabled', 0)
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  elseif !toggle  " remove autocommands
    exe 'au! autosave_' . bufnr()
  else  " add autocommands
    exe 'augroup autosave_' . bufnr() | exe 'au!'
    exe 'autocmd InsertLeave,TextChanged <buffer> silent call file#update()'
    exe 'augroup END'
  endif
  let b:autosave_enabled = toggle
  call s:echo_state('autosave', toggle, suppress)
endfunction

" Toggle insert and command-mode caps lock
" See: http://vim.wikia.com/wiki/Insert-mode_only_Caps_Lock which uses
" iminsert to enable/disable lnoremap, with iminsert changed from 0 to 1
function! switch#caps(...) abort
  let state = &l:iminsert == 1  " toggled by i_<Ctrl-^> and c_<Ctrl-^>
  let toggle = a:0 > 0 ? a:1 : 1 - state
  if toggle
    for nr in range(char2nr('A'), char2nr('Z'))
      exe 'lnoremap <buffer> ' . nr2char(nr + 32) . ' ' . nr2char(nr)
      exe 'lnoremap <buffer> ' . nr2char(nr) . ' ' . nr2char(nr + 32)
    endfor
    augroup caps_lock
      au!
      au InsertLeave,CmdwinLeave * setlocal iminsert=0 | au! caps_lock
    augroup END
  endif | return "\<C-^>"
endfunction

" Toggle conceal characters on and off
" NOTE: Hide message because result is obvious and for consistency with copy mode
function! switch#conceal(...) abort
  let state = &conceallevel > 0
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  else
    let &l:conceallevel = toggle ? 2 : 0
  endif
  call s:echo_state('conceal mode', toggle, suppress)
endfunction

" Tgogle special characters and columns on-off
" NOTE: Enforce settings even if state == toggle for consistency across filetypes
" WARNING: Had issues setting scrolloff automatically so trigger with argument instead
function! switch#copy(scroll, ...) abort
  let keys = ['list', 'number', 'relativenumber', 'signcolumn', 'foldcolumn']
  let opts = {} | for key in keys | let opts[key] = eval('&l:' . key) | endfor
  let keys += a:scroll ? ['scrolloff'] : []  " include scrolloff in toggle
  let state = empty(filter(copy(opts), {key, val -> val !=# '0' && val !=# 'no'}))
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if toggle
    for key in keys
      exe 'let &l:' . key . '=' . string(key ==# 'signcolumn' ? 'no' : 0)
    endfor
  else
    for key in keys
      exe 'let &l:' . key . '=' . string(eval('&g:' . key))
    endfor
  endif
  call s:echo_state('copy mode', toggle, suppress)
endfunction

" Toggle ddc on and off
" NOTE: The ddc docs says ddc#disable() is permanent so just remove sources
function! switch#ddc(...) abort
  let running = []  " 'allowed' means servers applied to this filetype
  let state = denops#server#status() ==? 'running'  " check denops server status
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  elseif toggle  " note completionMode was removed
    call ddc#custom#patch_global('sources', g:ddc_sources)  " restore sources
    call denops#server#restart()  " must come after ddc calls
  else
    call denops#server#stop()  " must come before ddc calls
    call ddc#custom#patch_global('sources', [])  " wipe out ddc sources
  endif
  call s:echo_state('autocomplete', toggle, suppress)
endfunction

" Toggle git gutter and skip if input request matches current state
function! switch#gitgutter(...) abort
  let state = get(get(b:, 'gitgutter', {}), 'enabled', 0)
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  elseif toggle
    GitGutterBufferEnable
  else
    GitGutterBufferDisable
  endif
  call s:echo_state('gitgutter', toggle, suppress)
endfunction

" Toggle highlighting
" NOTE: hlsearch reset when reurning from function. See :help function-search-undo
function! switch#hlsearch(...) abort
  let state = v:hlsearch
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  elseif toggle
    let cmd = 'set hlsearch'
  else
    let cmd = 'nohlsearch'
  endif
  call feedkeys("\<Cmd>" . cmd . "\<CR>", 'n')
  call s:echo_state('highlight search', toggle, suppress)
endfunction

" Toggle local directory navigation
" NOTE: This can be useful for browsing files
function! switch#localdir(...) abort
  let state = haslocaldir()
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  let root = empty(v:this_session) ? getcwd(-1) : fnamemodify(v:this_session, ':p:h')
  let local = expand('%:p:h')
  if getcwd(-1) !=# root  " enforce in case it changed
    exe 'cd ' . root | echo  'Global directory ' . string(root)
  endif
  if state == toggle
    return
  elseif toggle
    exe 'lcd ' . local
  else
    exe 'cd ' . root
  endif
  call s:echo_state('local directory ' . string(local), toggle, suppress)
endfunction

" Enable and disable LSP engines
" NOTE: The server status can lag because takes a while for async server stop
" let servers = lsp#get_server_names()  " servers applied to any filetype
function! switch#lsp(...) abort
  let running = []  " 'allowed' means servers applied to this filetype
  let servers = exists('*lsp#get_allowed_servers') ? lsp#get_allowed_servers() : []
  for server in servers
    if lsp#get_server_status(server) =~? 'running' | call add(running, server) | endif
  endfor
  let state = !empty(running)  " at least one filetype server is running
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle || empty(servers)
    return
  elseif toggle
    call lsp#activate()  " currently can only activate everything
  else
    for server in running | call lsp#stop_server(server) | endfor  " de-activate server
  endif
  call s:echo_state('lsp integration', toggle, suppress)
endfunction

" Toggle between UK and US English
function! switch#lang(...) abort
  let state = &l:spelllang ==# 'en_gb'
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  elseif toggle
    setlocal spelllang=en_gb
  else
    setlocal spelllang=en_us
  endif
  call s:echo_state('UK English', toggle, suppress)
endfunction

" Toggle paste mode
" NOTE: Automatically untoggle when insert mode finishes
function! s:paste_restore() abort
  if exists('s:paste_options')
    echo 'Paste mode disabled.'
    let [&l:paste, &l:mouse] = s:paste_options
    exe 'unlet s:paste_options'
  endif
endfunction
function! switch#paste() abort
  echo 'Paste mode enabled.'
  let s:paste_options = [&l:paste, &l:mouse]
  setlocal paste mouse=
  augroup paste_mode
    au!
    au InsertLeave * call s:paste_restore() | au! paste_mode
  augroup END | return ''
endfunction

" Toggle temporary fold/conceal reveal
" NOTE: Automatically untoggle after editing or inserting
function! s:reveal_restore() abort
  if exists('b:reveal_cache')
    let &g:foldopen = b:reveal_cache[0]  " global only
    let &l:conceallevel = b:reveal_cache[1]
    let &l:relativenumber = b:reveal_cache[2]
  endif | unlet! b:reveal_cache
endfunction
function! switch#reveal(...) abort
  let state = exists('b:reveal_cache')
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if toggle && !exists('b:reveal_cache')
    let b:reveal_folds = 'block,insert,jump,mark,percent,quickfix,search,tag,undo'
    let b:reveal_cache = [&g:foldopen, &l:conceallevel, &l:relativenumber]
    let &g:foldopen = b:reveal_folds  " setting is global only
    let &l:conceallevel = 0  " reveal concealed characters and closed folds
    let &l:relativenumber = 0  " reveal absolute line numbers
    exe 'augroup reveal_' . bufnr() | exe 'au!'
    exe 'au BufEnter <buffer> let &g:foldopen = b:reveal_folds'
    exe 'au BufLeave <buffer> let &g:foldopen = b:reveal_cache[0]'
    exe 'augroup END'
  elseif !toggle  " remove augroup
    call s:reveal_restore() | silent! exe 'au! reveal_' . bufnr()
    unlet! b:reveal_cache
  endif
  call s:echo_state('Reveal mode', toggle, suppress)
endfunction

" Toggle folds with gitgutter hunks
" NOTE: Automatically disable whenever set nohlsearch is restore
function! s:get_changes() abort
  let lines = []
  for [line1, line2, _] in fold#get_folds(-2)
    let flags = git#_get_hunks(line1, line2, 1)
    let flags .= edit#_get_errors(line1, line2)
    if !empty(flags) | call add(lines, line1) | endif
  endfor | return lines
endfunction
function! switch#changes(...) abort
  let winview = winsaveview()
  let lines = s:get_changes()
  let state = empty(filter(copy(lines), 'foldclosed(v:val) > 0'))
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if toggle  " :global previous search
    call fold#update_folds(0, 2)
    for lnum in lines | exe lnum . 'foldopen' | endfor
    call winrestview(winview) | exe 'normal! zzze'
  else  " keep hlsearch enabled
    call winrestview(winview)
    call fold#update_folds(0, 1)
  endif
  call s:echo_state(len(lines) . ' folds', toggle, suppress)
endfunction

" Toggle folds with search matches
" NOTE: Automatically disable whenever set nohlsearch is restore
" WARNING: Vim bug seems to cause exe line1 | call search() to randomly fail when
" search starts on closed fold and match is on first line. Use cursor() instead
function! s:get_matches() abort
  let folds = []
  for [line1, line2, level] in sort(fold#get_folds(-2))
    call cursor(line1, 1) | if search(@/, 'cnW', line2) | call add(folds, [level, line1]) | endif
  endfor | return folds
endfunction
function! switch#matches(...) abort
  let winview = winsaveview()
  let folds = s:get_matches()
  let state = empty(filter(copy(folds), 'foldclosed(v:val[1]) > 0'))
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if toggle  " :global previous search
    call fold#update_folds(0, 2)
    for [_, lnum] in sort(folds) | exe lnum . 'foldopen' | endfor
    call winrestview(winview) | exe 'normal! zzze'
  else  " keep hlsearch enabled
    call winrestview(winview)
    call fold#update_folds(0, 1)
  endif
  call feedkeys("\<Cmd>set hlsearch\<CR>", 'n')
  call s:echo_state(len(folds) . ' folds', toggle, suppress)
endfunction

" Toggle spell check on and off
function! switch#spell(...) abort
  let state = &l:spell
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  else
    let &l:spell = toggle
  endif
  call s:echo_state('Spell check', toggle, suppress)
endfunction

" Toggle literal tab characters on and off
" NOTE: Also enforces initial default width for files with literal tabs
function! switch#tabs(...) abort
  let state = &l:expandtab
  let toggle = a:0 > 0 ? 1 - a:1 : 1 - state  " 'on' means literal tabs i.e. no expandtab
  let suppress = a:0 > 1 ? a:2 : 0
  if state != toggle
    let &l:expandtab = toggle
  endif
  if suppress && !&l:softtabstop  " enforce default
    let [&l:tabstop, &l:softtabstop, &l:shiftwidth] = [2, 2, 2]
  endif
  call s:echo_state('Literal tabs', 1 - toggle, suppress)
endfunction

" Toggle tags on and off
function! switch#tags(...) abort
  let names = ['tags_by_line', 'tags_by_name', 'tags_update_time']
  let state = get(g:, 'gutentags_enabled', 0) && !empty(tagfiles())
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  elseif toggle
    let g:gutentags_enabled = 1  " all that GutentagsToggleEnabled does
    silent! GutentagsUpdate  " update local tags
    silent! UpdateTags  " update local tags
  else
    let g:gutentags_enabled = 0  " all that GutentagsToggleEnabled does
    for name in names
      silent! call remove(b:, name)
    endfor
  endif
  call s:echo_state('Tags', toggle, suppress)
endfunction
