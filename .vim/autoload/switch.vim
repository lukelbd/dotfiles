"-----------------------------------------------------------------------------"
" Utilities for switching stuff on and off
"-----------------------------------------------------------------------------"
" Helper function
function! s:echo_state(prefix, toggle, ...)
  if !a:0 || !a:1
    let state = a:toggle ? 'enabled' : 'disabled'
    redraw | echom toupper(a:prefix[0]) . a:prefix[1:] . ' ' . state . '.'
  endif
endfunction

" Toggle ALE syntax checking
" Note: Previously also toggled 'vim-lsp' diagnostics sent to ale by 'vim-lsp-ale' but
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
  call call('s:echo_state', ['ale linters', toggle, suppress])
endfunction

" Autosave toggle (autocommands are local to buffer as with codi)
" We use augroups with buffer-specific names to prevent conflict
" Note: There are also 'autowrite' and 'autowriteall' settings that will automatically
" write before built-in file jumping (e.g. :next, :last, :rewind, ...) and tag jumping
" (e.g. :tag, <C-]>, ...) but they are global, and the below effectively enables
" these settings. So do not bother with them.
function! switch#autosave(...) abort
  let state = get(b:, 'autosave_enabled', 0)
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  elseif toggle
    exe 'augroup autosave_' . bufnr() | exe 'au!'
    exe 'autocmd InsertLeave,TextChanged <buffer> silent call file#update()'
    exe 'augroup END'
  else
    exe 'augroup autosave_' . bufnr() | exe 'au!'
    exe 'augroup END'
  endif
  let b:autosave_enabled = toggle
  call call('s:echo_state', ['Autosave', toggle, suppress])
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
      au InsertLeave,CmdwinLeave * setlocal iminsert=0 | autocmd! caps_lock
    augroup END
  endif | return "\<C-^>"
endfunction

" Toggle conceal characters on and off
" Note: Hide message because result is obvious and for consistency with copy mode
function! switch#conceal(...) abort
  let state = &conceallevel > 0
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  else
    let &l:conceallevel = toggle ? 2 : 0
  endif
  call call('s:echo_state', ['Conceal mode', toggle, suppress])
endfunction

" Tgogle special characters and columns on-off
" Warning: Enforce settings even if state == toggle for consistency
function! switch#copy(...) abort
  let keys = ['list', 'number', 'scrolloff', 'relativenumber', 'signcolumn', 'foldcolumn']
  let props1 = get(b:, 'settings', {})
  let props2 = {} | for key in keys | let props2[key] = eval('&l:' . key) | endfor
  let state = empty(filter(copy(props2), {key, val -> val !=# '0' && val !=# 'no'}))
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if toggle
    let b:settings = props2
    for key in keys
      exe 'let &l:' . key . '=' . string(key ==# 'signcolumn' ? 'no' : 0)
    endfor
  else
    for key in keys
      exe 'let &l:' . key . '=' . string(get(props1, key, eval('&g:' . key)))
    endfor
    let b:settings = {}
  endif
  call call('s:echo_state', ['Copy mode', toggle, suppress])
endfunction

" Toggle ddc on and off
" Note: The ddc docs says ddc#disable() is permanent so just remove sources
function! switch#ddc(...) abort
  let running = []  " 'allowed' means servers applied to this filetype
  let state = denops#server#status() ==? 'running'  " check denops server status
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  elseif toggle  " note completionMode was removed
    call ddc#custom#patch_global('sources', g:ddc_sources)  " restore sources
    call denops#server#start()  " must come after ddc calls
  else
    call denops#server#stop()  " must come before ddc calls
    call ddc#custom#patch_global('sources', [])  " wipe out ddc sources
  endif
  call call('s:echo_state', ['autocomplete', toggle, suppress])
endfunction

" Toggle literal tab characters on and off
" Note: Also enforces initial default width for files with literal tabs
function! switch#expandtab(...) abort
  let state = &l:expandtab
  let toggle = a:0 > 0 ? 1 - a:1 : 1 - state  " 'on' means literal tabs i.e. no expandtab
  let suppress = a:0 > 1 ? a:2 : 0
  if state != toggle
    let &l:expandtab = toggle
  endif
  if !toggle && suppress
    setlocal tabstop=2 softtabstop=2 shiftwidth=2
  endif
  call call('s:echo_state', ['Literal tabs', 1 - toggle, suppress])
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
  call call('s:echo_state', ['GitGutter', toggle, suppress])
endfunction

" Toggle highlighting
" Note: hlsearch reset when reurning from function. See :help function-search-undo
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
  call call('s:echo_state', ['Highlight search', toggle, suppress])
endfunction

" Toggle local directory navigation
" Note: This can be useful for browsing files
function! switch#localdir(...) abort
  let state = haslocaldir()
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  let root = empty(v:this_session) ? getcwd(-1) : fnamemodify(v:this_session, ':p:h')
  let local = expand('%:p:h')
  if getcwd(-1) !=# root  " enforce in case it changed
    exe 'cd ' . root
    echom "Global directory '" . root . "'"
  endif
  if state == toggle
    return
  elseif toggle
    exe 'lcd ' . local
  else
    exe 'cd ' . root
  endif
  call call('s:echo_state', ["Local directory '" . local . "'", toggle, suppress])
endfunction

" Toggle revealing matches in folds
" Note: Auto disable whenever set nohlsearch is restore
function! switch#opensearch(...) abort
  let state = get(b:, 'open_search', 0)
  let toggle = a:0 > 0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  let winview = winsaveview()
  if toggle  " :global previous search
    silent! %foldclose!
    global//silent! normal! zv
    call feedkeys("\<Cmd>set hlsearch\<CR>", 'n')
  else  " keep hlsearch enabled
    silent! %foldclose!
    silent! normal! zv
    call feedkeys("\<Cmd>set hlsearch\<CR>", 'n')
  endif
  call winrestview(winview)
  call call('s:echo_state', ['Open searches', toggle, suppress])
  let b:open_search = toggle
endfunction

" Enable and disable LSP engines
" Note: The server status can lag because takes a while for async server stop
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
  call call('s:echo_state', ['lsp integration', toggle, suppress])
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
  call call('s:echo_state', ['UK English', toggle, suppress])
endfunction

" Toggle temporary paste mode
" Note: Removed automatically when insert mode finishes
function! s:paste_restore() abort
  if exists('s:paste_options')
    echom 'Paste mode disabled.'
    let [&l:paste, &l:mouse] = s:paste_options
    exe 'unlet s:paste_options'
  endif
endfunction
function! switch#paste() abort
  echom 'Paste mode enabled.'
  let s:paste_options = [&l:paste, &l:mouse]
  setlocal paste mouse=
  augroup paste_mode
    au!
    au InsertLeave * call s:paste_restore() | autocmd! paste_mode
  augroup END | return ''
endfunction

" Toggle temporary conceal reveal
" Note: This is similar to switch#conceal() but auto-restores
function! s:reveal_restore() abort
  if exists('s:reveal_option')
    let &l:conceallevel = s:reveal_option
    exe 'unlet s:reveal_option'
  endif
endfunction
function! switch#reveal(...) abort
  let state = exists('s:reveal_option')
  let toggle = a:0 > 0 ? a:1 : 1 - state
  if !toggle && exists('s:reveal_option')
    echom 'Reveal mode disabled.'
    doautocmd reveal_mode TextChanged
  elseif toggle && !exists('s:reveal_option')
    echom 'Reveal mode enabled.'
    let s:reveal_option = &l:conceallevel
    setlocal conceallevel=0  " incsearch only
    augroup reveal_mode
      au!
      au TextChanged,InsertEnter,InsertLeave * call s:reveal_restore() | autocmd! reveal_mode
    augroup END
  endif | return ''
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
  call call('s:echo_state', ['Spell check', toggle, suppress])
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
  call call('s:echo_state', ['Tags', toggle, suppress])
endfunction
