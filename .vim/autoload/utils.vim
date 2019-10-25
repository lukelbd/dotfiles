"-----------------------------------------------------------------------------"
" Various utils defined here
"-----------------------------------------------------------------------------"
" Refresh file
function! utils#refresh() " refresh sesssion, sometimes ~/.vimrc settings are overridden by ftplugin stuff
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
  echom "Loaded ".join(map(loaded, 'fnamemodify(v:val, ":~")[2:]'), ', ').'.'
endfunction

" Toggle conceal characters on and off
function! utils#conceal_toggle(...)
  if a:0
    let conceal_on = a:1
  else
    let conceal_on = (&conceallevel ? 0 : 2) " turn off and on
  endif
  exe 'set conceallevel=' . (conceal_on ? 2 : 0)
endfunction

" Toggle literal tab characters on and off
function! utils#tab_toggle(...)
  if a:0
    let &l:expandtab = 1 - a:1 " toggle 'on' means literal tabs are 'on'
  else
    setlocal expandtab!
  endif
  let b:tab_mode = &l:expandtab
endfunction

" Eliminates special chars during copy
function! utils#copy_toggle(...)
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
function! utils#autosave_toggle(...)
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
function! utils#gitgutter_toggle(...)
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
function! utils#codi_setup(toggle)
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
function! s:strip(text) " strip leading and trailing whitespace
  return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction
function! utils#codi_new(name)
  if a:name !~ '^\s*$'
    let name = a:name
  else
    let name = input('Calculator name (' . getcwd() . '): ', '', 'file')
  endif
  if name !~ '^\s*$'
    exe 'tabe ' . fnamemodify(name, ':r') . '.py'
    Codi!!
  endif
endfunction

" Set up tagbar window and make sure NerdTREE is flushed to right
function! utils#tagbar_setup()
  if &ft=="nerdtree"
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
function! utils#vim_close()
  qa
  " tabdo windo
  "   \ if &ft == 'log' | q! | else | q | endif
endfunction
function! utils#tab_close()
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
function! utils#window_close()
  let ntabs = tabpagenr('$')
  let islast = (tabpagenr('$') == tabpagenr())
  q
  if ntabs != tabpagenr('$') && !islast
    silent! tabp
  endif
endfunction

" Move current tab to the exact place of tab number N
function! utils#tab_move(n)
  if a:n == tabpagenr() || a:n == 0 || a:n == ''
    return
  elseif a:n > tabpagenr() && version[0] > 7
    echo 'Moving tab...'
    execute 'tabmove '.a:n
  else
    echo 'Moving tab...'
    execute 'tabmove '.eval(a:n-1)
  endif
endfunction

" Function that generates lists of tabs and their numbers
function! utils#tab_select()
  if !exists('g:tabline_bufignore')
    let g:tabline_bufignore = ['qf', 'vim-plug', 'help', 'diff', 'man', 'fugitive', 'nerdtree', 'tagbar', 'codi'] " filetypes considered 'helpers'
  endif
  let items = []
  for i in range(tabpagenr('$')) " iterate through each tab
    let tabnr = i+1 " the tab number
    let buflist = tabpagebuflist(tabnr)
    for b in buflist " get the 'primary' panel in a tab, ignore 'helper' panels even if they are in focus
      if !In(g:tabline_bufignore, getbufvar(b, "&ft"))
        let bufnr = b " we choose this as our 'primary' file for tab title
        break
      elseif b==buflist[-1] " occurs if e.g. entire tab is a help window; exception, and indeed use it for tab title
        let bufnr = b
      endif
    endfor
    if tabnr == tabpagenr()
      continue
    endif
    let items += [tabnr.': '.fnamemodify(bufname(bufnr),'%:t')] " actual name
  endfor
  return items
endfunction

" Function that jumps to the tab number from a line generated by tabselect
function! utils#tab_jump(item)
  exe 'normal! '.split(a:item,':')[0].'gt'
endfunction

" For popup windows
" For location lists, enter jumps to location. Restore this behavior.
function! utils#popup_setup(...)
  nnoremap <silent> <buffer> <CR> <CR>
  nnoremap <silent> <buffer> <C-w> :q!<CR>
  nnoremap <silent> <buffer> q :q!<CR>
  setlocal nolist nonumber norelativenumber nospell modifiable nocursorline colorcolumn=
  if !a:0 | setlocal buftype=nofile | endif
  if len(tabpagebuflist()) == 1 | q | endif " exit if only one left
endfunction

" For help windows
function! utils#help_setup()
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
function! utils#cmdwin_setup()
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
function! utils#current_group()
  echo ""
   \ . "actual <" . synIDattr(synID(line("."), col("."), 1), "name") . "> "
   \ . "appears <" . synIDattr(synID(line("."), col("."), 0), "name") . "> "
   \ . "group <" . synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name") . ">"
endfunction
function! utils#current_syntax(name)
  if a:name
    exe "verb syntax list " . a:name
  else
    exe "verb syntax list " . synIDattr(synID(line("."), col("."), 0), "name")
  endif
endfunction

" Popup windows with default ftplugin and syntax files
function! utils#show_ftplugin()
  execute 'split $VIMRUNTIME/ftplugin/' . &ft . '.vim'
  silent call utils#popup_setup()
endfunction
function! utils#show_syntax()
  execute 'split $VIMRUNTIME/syntax/' . &ft . '.vim'
  silent call utils#popup_setup()
endfunction

" Popup window with color display
function! utils#show_colors()
  source $VIMRUNTIME/syntax/colortest.vim
  silent call utils#popup_setup()
endfunction
