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
function! switch#ale(...) abort
  if !exists(':ALEInfo')
    return
  endif
  if a:0
    let toggle = a:1
  elseif exists('b:ale_enabled')
    let toggle = 1 - b:ale_enabled
  else
    let toggle = 0  " enabled by default, this disables for first time
  endif
  if toggle
    ALEEnableBuffer  " plugin then sets b:ale_enabled
  else
    ALEDisableBuffer
  endif
  let b:ale_enabled = toggle  " ensure always applied
  call s:switch_message('ALE', toggle)
endfunction

" Enable and disable LSP engines
function! switch#lsp(...) abort
  if !exists('*denops#server#start')
    return
  endif
  if a:0
    let toggle = a:1
  elseif exists('b:lsp_enabled')
    let toggle = 1 - b:lsp_enabled
  else
    let toggle = 0  " enabled by default, this disables for first time
  endif
  let b:lsp_enabled = toggle
  if toggle  " note completionMode was removed
    call denops#server#start()
  else
    call denops#server#stop()
  endif
  call s:switch_message('Lsp', toggle)
endfunction

" Autosave toggle (autocommands are local to buffer as with codi)
" We use augroups with buffer-specific names to prevent conflict
function! switch#autosave(...) abort
  if !exists('b:autosave_enabled')
    let b:autosave_enabled = 0
  endif
  if a:0
    let toggle = a:1
  else
    let toggle = 1 - b:autosave_enabled
  endif
  if toggle == b:autosave_enabled
    return
  endif
  if toggle
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
  call s:switch_message('Autosave', toggle)
endfunction

" Toggle directory 
" Note: This can be useful for browsing files
function! switch#localdir() abort
  let root = getcwd(-1)
  let local = expand('%:p:h')
  let toggle = !haslocaldir()
  if !empty(v:this_session)  " enforce in case it changed
    let root = fnamemodify(v:this_session, ':p:h')
    if getcwd(-1) !=# root
      exe 'cd ' . root
      echom "Global directory '" . root . "'"
    endif
  endif
  if toggle
    exe 'lcd ' . local
  else
    exe 'cd ' . root
  endif
  call s:switch_message("Local directory '" . local . "'", toggle)
endfunction

" Toggle conceal characters on and off
" Note: Hide message because result is obvious and for consistency with copy mode
" call s:switch_message('Conceal mode', toggle)
function! switch#conceal(...) abort
  if a:0
    let toggle = a:1
  else
    let toggle = &conceallevel ? 0 : 2  " turn off and on
  endif
  let suppress = a:0 > 1 ? a:2 : 0
  exe 'set conceallevel=' . (toggle ? 2 : 0)
  if !suppress
    call s:switch_message('Conceal mode', toggle)
  endif
endfunction

" Eliminates special chars during copy
" Note: Hide switch message during autoload
function! switch#copy(...) abort
  if a:0
    let toggle = a:1
  else
    let toggle = !exists('b:number')
  endif
  let suppress = a:0 > 1 ? a:2 : 0
  let copyprops = ['list', 'number', 'relativenumber', 'scrolloff']
  if toggle
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
  if a:0
    let &l:expandtab = 1 - a:1  " toggle 'on' means literal tabs are 'on'
  else
    setlocal expandtab!
  endif
  let suppress = a:0 > 1 ? a:2 : 0
  let b:expandtab = &l:expandtab  " override set expandtab in vimrc
  if !suppress
    call s:switch_message('Literal tabs', 1 - b:expandtab)
  endif
endfunction

" Either listen to input, turn on if switch not declared, or do opposite
function! switch#gitgutter(...) abort
  if a:0
    let toggle = a:1
  else
    let toggle = (exists('b:gitgutter_enabled') ? 1 - b:gitgutter_enabled : 1)
  endif
  if toggle
    GitGutterBufferEnable
  else
    GitGutterBufferDisable
  endif
  let b:gitgutter_enabled = toggle
  call s:switch_message('GitGutter', toggle)
endfunction

" Toggle highlighting
function! switch#hlsearch(...) abort
  if a:0
    let toggle = a:1
  else
    let toggle = 1 - v:hlsearch
  endif
  if toggle
    let cmd = 'set hlsearch'
  else
    let cmd = 'nohlsearch'
  endif
  call feedkeys("\<Cmd>" . cmd . "\<CR>")
  call s:switch_message('Highlight search', toggle)
endfunction

" Toggle spell check on and off
function! switch#spellcheck(...)
  if a:0
    let toggle = a:1
  else
    let toggle = 1 - &l:spell
  endif
  let &l:spell = toggle
  call s:switch_message('Spell check', toggle)
endfunction

" Toggle between UK and US English
function! switch#spelllang(...)
  if a:0
    let toggle = a:1
  else
    let toggle = (&l:spelllang ==# 'en_gb' ? 0 : 1)
  endif
  if toggle
    setlocal spelllang=en_gb
  else
    setlocal spelllang=en_us
  endif
  call s:switch_message('UK English', toggle)
endfunction
