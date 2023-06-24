"-----------------------------------------------------------------------------"
" Utilities for switching stuff on and off
"-----------------------------------------------------------------------------"
" Helper function
function! s:switch_message(prefix, toggle)
  if a:toggle
    let state = 'enabled'
  else
    let state = 'disabled'
  endif
  echom toupper(a:prefix[0]) . a:prefix[1:] . ' ' . state . '.'
endfunction

" Toggle ALE syntax checking
" Note: Could automatically disable errors sent from 'vim-lsp' but do explicitly
function! switch#ale(...) abort
  let state = get(b:, 'ale_enabled', 1)  " enabled by default, disable for first time
  let toggle = a:0 ? a:1 : 1 - state
  if state == toggle || !exists(':ALEEnableBuffer')
    return
  elseif toggle
    ALEEnableBuffer  " disable and set b:ale_enabled = 1
    call lsp#ale#enable()  " stop sending lsp diagnostics to ale
  else
    ALEDisableBuffer  " enable and set b:ale_enabled = 0
    call lsp#ale#disable()  " start sending lsp diagnostics to ale
  endif
  let b:ale_enabled = toggle  " ensure always applied in case API changes
  call s:switch_message('ale and lsp integration', toggle)
endfunction

" Autosave toggle (autocommands are local to buffer as with codi)
" We use augroups with buffer-specific names to prevent conflict
function! switch#autosave(...) abort
  let state = get(b:, 'autosave_enabled', 0)
  let toggle = a:0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  elseif toggle
    let cmds = exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave'
    exe 'augroup autosave_' . bufnr('%')
      au!
      exe 'au ' . cmds . ' <buffer> silent call tabline#write()'
    augroup END
  else
    exe 'augroup autosave_' . bufnr('%')
      au!
    augroup END
  endif
  let b:autosave_enabled = toggle
  if !suppress
    call s:switch_message('Autosave', toggle)
  endif
endfunction

" Toggle conceal characters on and off
" Note: Hide message because result is obvious and for consistency with copy mode
" call s:switch_message('Conceal mode', toggle)
function! switch#conceal(...) abort
  let state = &conceallevel > 0
  let toggle = a:0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  else
    let &l:conceallevel = toggle ? 2 : 0
  endif
  if !suppress
    call s:switch_message('Conceal mode', toggle)
  endif
endfunction

" Eliminates special chars during copy
" Note: Hide switch message during autoload
function! switch#copy(...) abort
  let state = exists('b:number')
  let toggle = a:0 ? a:1 : 1 - state
  let suppress = a:0 > 1 ? a:2 : 0
  let copyprops = ['list', 'number', 'relativenumber', 'scrolloff']
  if state == toggle
    return
  elseif toggle
    for prop in copyprops
      if !exists('b:' . prop) "do not overwrite previously saved settings
        exe 'let b:' . prop . ' = &l:' . prop
      endif
      exe 'let &l:' . prop . ' = 0'
    endfor
  else
    for prop in copyprops
      exe 'silent! let &l:' . prop . ' = b:' . prop
      exe 'silent! unlet b:' . prop
    endfor
  endif
  if !suppress
    call s:switch_message('Copy mode', toggle)
  endif
endfunction

" Toggle literal tab characters on and off
function! switch#expandtab(...) abort
  let state = &l:expandtab
  let toggle = a:0 ? 1 - a:1 : 1 - state  " 'on' means literal tabs i.e. no expandtab
  let suppress = a:0 > 1 ? a:2 : 0
  if state == toggle
    return
  else
    let &l:expandtab = toggle
  endif
  if !suppress
    call s:switch_message('Literal tabs', 1 - toggle)
  endif
endfunction

" Toggle git gutter and skip if input request matches current state
function! switch#gitgutter(...) abort
  let state = get(get(b:, 'gitgutter', {}), 'enabled', 0)
  let toggle = a:0 ? a:1 : 1 - state
  if state == toggle
    return
  elseif toggle
    GitGutterBufferEnable
  else
    GitGutterBufferDisable
  endif
  call s:switch_message('GitGutter', toggle)
endfunction

" Toggle highlighting
function! switch#hlsearch(...) abort
  let state = v:hlsearch
  let toggle = a:0 ? a:1 : 1 - state
  if state == toggle
    return
  elseif toggle
    let cmd = 'set hlsearch'
  else
    let cmd = 'nohlsearch'
  endif
  call feedkeys("\<Cmd>" . cmd . "\<CR>")
  call s:switch_message('Highlight search', toggle)
endfunction

" Toggle directory 
" Note: This can be useful for browsing files
function! switch#localdir(...) abort
  let state = haslocaldir()
  let toggle = a:0 ? a:1 : 1 - state
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
  call s:switch_message("Local directory '" . local . "'", toggle)
endfunction

" Enable and disable LSP engines
" Note: The ddc docs says ddc#disable() is permanent so just remove sources
" Note: The server status can lag because takes a while for async server stop
" let state = denops#server#status() ==? 'running'  " check denops server status
" let servers = lsp#get_server_names()  " servers applied to any filetype
function! switch#lsp(...) abort
  let running = []  " 'allowed' means servers applied to this filetype
  let servers = exists('*lsp#get_allowed_servers') ? lsp#get_allowed_servers() : []
  for server in servers
    if lsp#get_server_status(server) =~? 'running' | call add(running, server) | endif
  endfor
  let state = !empty(running)  " at least one filetype server is running
  let toggle = a:0 ? a:1 : 1 - state
  if state == toggle || empty(servers)
    return
  elseif toggle  " note completionMode was removed
    call lsp#activate()  " currently can only activate everything
    call ddc#custom#patch_global(g:ddc_sources)  " restore sources
    call denops#server#start()  " must come after ddc call
  else
    for server in running | call lsp#stop_server(server) | endfor  " de-activate server
    call ddc#custom#patch_global({'sources': []})  " wipe out ddc sources
    call denops#server#stop()  " must come before ddc call
  endif
  call s:switch_message('lsp and autocomplete', toggle)
endfunction

" Toggle spell check on and off
function! switch#spellcheck(...) abort
  let state = &l:spell
  let toggle = a:0 ? a:1 : 1 - state
  if state == toggle
    return
  else
    let &l:spell = toggle
  endif
  call s:switch_message('Spell check', toggle)
endfunction

" Toggle between UK and US English
function! switch#spelllang(...) abort
  let state = &l:spelllang ==# 'en_gb'
  let toggle = a:0 ? a:1 : 1 - state
  if state == toggle
    return
  elseif toggle
    setlocal spelllang=en_gb
  else
    setlocal spelllang=en_us
  endif
  call s:switch_message('UK English', toggle)
endfunction

" Toggle tags on and off
function! switch#tags(...) abort
  let names = ['tags_by_line', 'tags_by_name', 'tags_scope_by_line', 'tags_top_by_line']
  let state = get(g:, 'gutentags_enabled', 0) && !empty(tagfiles())
  let toggle = a:0 ? a:1 : 1 - state
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
  call s:switch_message('Tags', toggle)
endfunction
