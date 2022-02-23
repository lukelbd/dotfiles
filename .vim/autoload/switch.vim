"-----------------------------------------------------------------------------"
" Utilities for switching stuff on and off
"-----------------------------------------------------------------------------"
" Toggle ALE syntax checking
function! switch#ale(...) abort
  if a:0
    let toggle = a:1
  else
    let toggle = (exists('b:ale_enabled') ? 1 - b:ale_enabled : 1)
  endif
  if toggle
    ALEEnableBuffer
    silent! set signcolumn=yes
    let b:ale_enabled = 1  " also done by plugin but do this just in case
  else
    ALEDisableBuffer
    if !(exists('b:gitgutter_enabled') && b:gitgutter_enabled)
      silent! set signcolumn=no
    endif
    let b:ale_enabled = 0
  endif
endfunction

" Autosave toggle
function! switch#autosave(...) abort
  if !exists('b:autosave_on')
    let b:autosave_on = 0
  endif
  if a:0
    let toggle = a:1
  else
    let toggle = 1 - b:autosave_on
  endif
  if toggle == b:autosave_on
    return
  endif
  " Toggle autocommands local to buffer as with codi
  " We use augroups with buffer-specific names to prevent conflict
  if toggle
    let cmds = exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave'
    exe 'augroup autosave_' . bufnr('%')
      au!
      exe 'au ' . cmds . ' <buffer> silent call tabline#write()'
    augroup END
    echom 'Autosave enabled.'
    let b:autosave_on = 1
  else
    exe 'augroup autosave_' . bufnr('%')
      au!
    augroup END
    echom 'Autosave disabled.'
    let b:autosave_on = 0
  endif
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
    echo 'Copy mode enabled.'
  else
    for prop in copyprops
      exe 'silent! let &l:' . prop . ' = b:' . prop
      exe 'silent! unlet b:' . prop
    endfor
    echo 'Copy mode disabled.'
  endif
endfunction

" Toggle conceal characters on and off
function! switch#conceal(...) abort
  if a:0
    let conceal_on = a:1
  else
    let conceal_on = (&conceallevel ? 0 : 2) " turn off and on
  endif
  exe 'set conceallevel=' . (conceal_on ? 2 : 0)
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
    silent! setlocal signcolumn=yes
    let b:gitgutter_enabled = 1
  else
    GitGutterBufferDisable
    if !exists('b:ale_enabled') || !b:ale_enabled
      silent! setlocal signcolumn=no
    endif
    let b:gitgutter_enabled = 0
  endif
endfunction

" Enable and disable jedi and autocomplete popups
function! switch#popup(...) abort
  if a:0
    let toggle = a:1
  elseif exists('g:popup_active')
    let toggle = 1 - g:popup_active
  else
    let toggle = 1
  endif
  let g:popup_active = toggle
  if exists('*ddc#custom#patch_global')
    call ddc#custom#patch_global('completionMode', toggle ? 'manual' : 'popupmenu')
  endif
  if exists('*jedi#configure_call_signatures')
    let g:jedi#show_call_signatures = toggle
    call jedi#configure_call_signatures()
  endif
endfunction

" Toggle between UK and US English
function! switch#lang(...)
  if a:0
    let uk = a:1
  else
    let uk = (&l:spelllang ==# 'en_gb' ? 0 : 1)
  endif
  if uk
    setlocal spelllang=en_gb
    echo 'Current language: UK english'
  else
    setlocal spelllang=en_us
    echo 'Current language: US english'
  endif
endfunction

" Toggle spell check on and off
function! switch#spell(...)
  if a:0
    let toggle = a:1
  else
    let toggle = 1 - &l:spell
  endif
  let &l:spell = toggle
endfunction

" Toggle literal tab characters on and off
function! switch#tab(...) abort
  if a:0
    let &l:expandtab = 1 - a:1 " toggle 'on' means literal tabs are 'on'
  else
    setlocal expandtab!
  endif
  let b:expandtab = &l:expandtab  " this overrides set expandtab in vimrc
endfunction
