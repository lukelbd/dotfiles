"-----------------------------------------------------------------------------"
" Various utils defined here
"-----------------------------------------------------------------------------"
" Refresh file
function! utils#refresh() abort " refresh sesssion, sometimes ~/.vimrc settings are overridden by ftplugin stuff
  filetype detect " if started with empty file, but now shebang makes filetype clear
  filetype plugin indent on
  let loaded = []
  let files = [
    \ '~/.vimrc',
    \ '~/.vim/ftplugin/' . &ft . '.vim',
    \ '~/.vim/syntax/' . &ft . '.vim',
    \ '~/.vim/after/ftplugin/' . &ft . '.vim',
    \ '~/.vim/after/syntax/' . &ft . '.vim']
  for file in files
    if !empty(glob(file))
      exe 'so '.file
      call add(loaded, file)
    endif
  endfor
  echom 'Loaded ' . join(map(loaded, 'fnamemodify(v:val, ":~")[2:]'), ', ') . '.'
endfunction

" Vim help information
function! utils#show_vim_help(...) abort
  if a:0
    let item = a:1
  else
    let item = input('Vim help item: ', '', 'help')
  endif
  if len(item)
    exe 'vert help ' . item
  endif
endfunction

" --help information
function! utils#show_cmd_help(...) abort
  if a:0
    let cmd = a:1
  else
    let cmd = input('Get --help info: ', '', 'shellcmd')
  endif
  if len(cmd)
    silent! exe '!clear; '
      \ . 'search=' . cmd . '; '
      \ . 'if [ -n $search ] && builtin help $search &>/dev/null; then '
      \ . '  builtin help $search 2>&1 | less; '
      \ . 'elif $search --help &>/dev/null; then '
      \ . '  $search --help 2>&1 | less; '
      \ . 'fi'
    if v:shell_error != 0
      echohl WarningMsg
      echom 'Warning: "man ' . cmd . '" failed.'
      echohl None
    endif
  endif
endfunction

" Man page information
function! utils#show_cmd_man(...) abort
  if a:0
    let cmd = a:1
  else
    let cmd = input('Get man page: ', '', 'shellcmd')
  endif
  silent! exe '!clear; '
    \ . 'search=' . cmd . '; '
    \ . 'if [ -n $search ] && command man $search &>/dev/null; then '
    \ . '  command man $search; '
    \ . 'fi'
  if len(cmd)
    if v:shell_error != 0
      echohl WarningMsg
      echom 'Warning: "' . cmd . ' --help" failed.'
      echohl None
    endif
  endif
endfunction

" Command mode mappings
function! utils#wild_tab(forward) abort
  if a:forward
    call feedkeys("\<Tab>", 't')
  else
    call feedkeys("\<S-Tab>", 't')
  endif
  return ''
endfunction

" Insert mode mappings
function! utils#forward_delete() abort
  let line = getline('.')
  if line[col('.') - 1:col('.') - 1 + &tabstop - 1] == repeat(' ', &tabstop)
    return repeat("\<Delete>", &tabstop)
  else
    return "\<Delete>"
  endif
endfunction

" Toggle conceal characters on and off
function! utils#conceal_toggle(...) abort
  if a:0
    let conceal_on = a:1
  else
    let conceal_on = (&conceallevel ? 0 : 2) " turn off and on
  endif
  exe 'set conceallevel=' . (conceal_on ? 2 : 0)
endfunction

" Toggle literal tab characters on and off
function! utils#tab_toggle(...) abort
  if a:0
    let &l:expandtab = 1 - a:1 " toggle 'on' means literal tabs are 'on'
  else
    setlocal expandtab!
  endif
  let b:tab_mode = &l:expandtab
endfunction

" Eliminates special chars during copy
function! utils#copy_toggle(...) abort
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

" Autosave toggle
function! utils#autosave_toggle(...) abort
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
    let cmds = (exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave')
    exe 'augroup autosave_' . bufnr('%')
      au! *
      exe 'au ' . cmds . ' <buffer> silent w'
    augroup END
    echom 'Autosave enabled.'
    let b:autosave_on = 1
  else
    exe 'augroup autosave_' . bufnr('%')
      au! *
    augroup END
    echom 'Autosave disabled.'
    let b:autosave_on = 0
  endif
endfunction

" Either listen to input, turn on if switch not declared, or do opposite
function! utils#gitgutter_toggle(...) abort
  if a:0
    let toggle = a:1
  else
    let toggle = (exists('b:gitgutter_enabled') ? 1-b:gitgutter_enabled : 1)
  endif
  if toggle
    GitGutterEnable
    silent! set signcolumn=yes
    let b:gitgutter_enabled = 1
  else
    GitGutterDisable
    silent! set signcolumn=no
    let b:gitgutter_enabled = 0
  endif
endfunction

" Custom codi autocommands
function! utils#codi_setup(toggle) abort
  if a:toggle
    let cmds = (exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave')
    exe 'augroup codi_' . bufnr('%')
      au!
      exe 'au ' . cmds . ' <buffer> call codi#update()'
    augroup END
  else
    exe 'augroup codi_' . bufnr('%')
      au!
    augroup END
  endif
endfunction

" New codi window
function! utils#codi_new(...) abort
  if a:0 && a:1 !~# '^\s*$'
    let name = a:1
  else
    let name = input('Calculator name (' . getcwd() . '): ', '', 'file')
  endif
  if name !~# '^\s*$'
    exe 'tabe ' . fnamemodify(name, ':r') . '.py'
    Codi!!
  endif
endfunction

" Set up tagbar window and make sure NerdTREE is flushed to right
function! utils#tagbar_setup() abort
  if &ft ==# 'nerdtree'
    wincmd h
    wincmd h " move two places in case e.g. have help menu + nerdtree already
  endif
  let tabfts = map(tabpagebuflist(),'getbufvar(v:val, "&ft")')
  if In(tabfts,'tagbar')
    TagbarClose
  else
    TagbarOpen
    if In(tabfts,'nerdtree')
      wincmd l
      wincmd L
      wincmd p
    endif
  endif
endfunction

" Closing tabs and windows
function! utils#vim_close() abort
  qa
  " tabdo windo if &ft == 'log' | q! | else | q | endif
endfunction
function! utils#tab_close() abort
  let ntabs = tabpagenr('$')
  let islast = (tabpagenr('$') - tabpagenr())
  if ntabs == 1
    qa
  else
    tabclose
    if !islast
      silent! tabp
    endif
  endif
endfunction
function! utils#window_close() abort
  let ntabs = tabpagenr('$')
  let islast = (tabpagenr('$') == tabpagenr())
  q
  if ntabs != tabpagenr('$') && !islast
    silent! tabp
  endif
endfunction

" Move current tab to the exact place of tab number N
function! utils#tab_list(A, L, P) abort
  return map(range(1, tabpagenr('$')), 'string(v:val)')
endfunction
function! utils#tab_move(...) abort
  if a:0
    let nr = a:1
  else
    let nr = input('Move tab: ', '', 'customlist,utils#tab_list')
  endif
  if nr == tabpagenr() || nr == 0 || nr ==# ''
    return
  elseif nr > tabpagenr() && v:version[0] > 7
    exe 'tabmove ' . nr
  else
    exe 'tabmove ' . (nr - 1)
  endif
endfunction

" Function that generates lists of tabs and their numbers
function! utils#tab_select() abort
  if !exists('g:tabline_bufignore')
    let g:tabline_bufignore = ['qf', 'vim-plug', 'help', 'diff', 'man', 'fugitive', 'nerdtree', 'tagbar', 'codi'] " filetypes considered 'helpers'
  endif
  let items = []
  for t in range(tabpagenr('$')) " iterate through each tab
    let tabnr = t + 1 " the tab number
    let buflist = tabpagebuflist(tabnr)
    for b in buflist " get the 'primary' panel in a tab, ignore 'helper' panels even if they are in focus
      if !In(g:tabline_bufignore, getbufvar(b, '&ft'))
        let bufnr = b " we choose this as our 'primary' file for tab title
        break
      elseif b == buflist[-1] " occurs if e.g. entire tab is a help window; exception, and indeed use it for tab title
        let bufnr = b
      endif
    endfor
    if tabnr == tabpagenr()
      continue
    endif
    let items += [tabnr . ': ' . fnamemodify(bufname(bufnr), '%:t')] " actual name
  endfor
  return items
endfunction

" Function that jumps to the tab number from a line generated by tabselect
function! utils#tab_jump(item) abort
  exe 'normal! ' . split(a:item, ':')[0] . 'gt'
endfunction

" For popup windows
" For location lists, enter jumps to location. Restore this behavior.
function! utils#popup_setup(nofile) abort
  nnoremap <silent> <buffer> <CR> <CR>
  nnoremap <silent> <buffer> <C-w> :q!<CR>
  nnoremap <silent> <buffer> q :q!<CR>
  setlocal nolist nonumber norelativenumber nospell modifiable nocursorline colorcolumn=
  if a:nofile | setlocal buftype=nofile | endif
  if len(tabpagebuflist()) == 1 | q | endif " exit if only one left
endfunction

" For help windows
function! utils#help_setup() abort
  call utils#popup_setup(0) " argument means we do not set buftype=nofile
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  if g:has_nowait
    nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
    nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
  else
    nnoremap <nowait> <buffer> <silent> [[ :<C-u>pop<CR>
    nnoremap <nowait> <buffer> <silent> ]] :<C-u>tag<CR>
  endif
endfunction

" For command windows, make sure local maps work
function! utils#cmdwin_setup() abort
  silent! unmap <CR>
  silent! unmap <C-c>
  nnoremap <buffer> <silent> q :q<CR>
  nnoremap <buffer> <C-z> <C-c><CR>
  inoremap <buffer> <C-z> <C-c><CR>
  inoremap <buffer> <expr> <CR> ""
  setlocal nonumber norelativenumber nolist laststatus=0
endfunction

" Miscellaneous popup windows
" Current syntax names and regex
function! utils#current_group() abort
  echo ''
   \ . 'actual <' . synIDattr(synID(line('.'), col('.'), 1), 'name') . '> '
   \ . 'appears <' . synIDattr(synID(line('.'), col('.'), 0), 'name') . '> '
   \ . 'group <' . synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name') . '>'
endfunction
function! utils#current_syntax(name) abort
  if a:name
    exe 'verb syntax list ' . a:name
  else
    exe 'verb syntax list ' . synIDattr(synID(line('.'), col('.'), 0), 'name')
  endif
endfunction

" Popup windows with default ftplugin and syntax files
function! utils#show_ftplugin() abort
  execute 'split $VIMRUNTIME/ftplugin/' . &ft . '.vim'
  silent call utils#popup_setup(1)
endfunction
function! utils#show_syntax() abort
  execute 'split $VIMRUNTIME/syntax/' . &ft . '.vim'
  silent call utils#popup_setup(1)
endfunction

" Popup window with color display
function! utils#show_colors() abort
  source $VIMRUNTIME/syntax/colortest.vim
  silent call utils#popup_setup(1)
endfunction
