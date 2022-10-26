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
  if a:0
    let toggle = a:1
  else
    let toggle = exists('b:ale_enabled') ? 1 - b:ale_enabled : 1
  endif
  if toggle
    ALEEnableBuffer
  else
    ALEDisableBuffer
  endif
  let b:ale_enabled = toggle  " also done by plugin but do this just in case
  call s:switch_message('ALE', toggle)
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
    echom 'Autosave enabled.'
  else
    exe 'augroup autosave_' . bufnr('%')
      au!
    augroup END
    echom 'Autosave disabled.'
  endif
  let b:autosave_enabled = toggle
  call s:switch_message('Autosave', toggle)
endfunction

" Enable and disable autocomplete engines
function! switch#autocomp(...) abort
  if a:0
    let toggle = a:1
  elseif exists('b:lsp_enabled')
    let toggle = 1 - b:lsp_enabled
  else
    let toggle = 1
  endif
  let b:lsp_enabled = toggle
  if exists('*ddc#custom#patch_buffer')
    call ddc#custom#patch_buffer('completionMode', toggle ? 'popupmenu' : 'manual')
  endif
  if exists('*jedi#configure_call_signatures')
    let b:jedi#show_call_signatures = toggle
    call jedi#configure_call_signatures()
  endif
  call s:switch_message('Autocomplete', toggle)
endfunction

" Toggle conceal characters on and off
function! switch#conceal(...) abort
  if a:0
    let toggle = a:1
  else
    let toggle = &conceallevel ? 0 : 2 " turn off and on
  endif
  exe 'set conceallevel=' . (toggle ? 2 : 0)
  call s:switch_message('Conceal mode', toggle)
endfunction

" Eliminates special chars during copy
function! switch#copy(...) abort
  if a:0
    let toggle = a:1
  else
    let toggle = !exists('b:number')
  endif
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
  call s:switch_message('Copy mode', toggle)
endfunction

" Toggle literal tab characters on and off
function! switch#expandtab(...) abort
  if a:0
    let &l:expandtab = 1 - a:1  " toggle 'on' means literal tabs are 'on'
  else
    setlocal expandtab!
  endif
  let toggle = &l:expandtab
  let b:expandtab = &l:expandtab  " this overrides set expandtab in vimrc
  call s:switch_message('Literal tabs', 1 - toggle)
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
