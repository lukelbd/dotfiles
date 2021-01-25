"-----------------------------------------------------------------------------"
" Various utils defined here
"-----------------------------------------------------------------------------"
" Swap characters
function! utils#swap_characters(right)
  let cnum = col('.')
  let line = getline('.')
  let idx = a:right ? cnum : cnum - 1
  if (idx > 0 && idx < len(line))
    let line = line[:idx - 2] . line[idx] . line[idx - 1] . line[idx + 1:]
    call setline('.', line)
  endif
endfunction

" Swap lines
function! utils#swap_lines(bottom)
  let offset = a:bottom ? 1 : -1
  let lnum = line('.')
  if (lnum + offset > 0 && lnum + offset < line('$'))
    let line1 = getline(lnum)
    let line2 = getline(lnum + offset)
    call setline(lnum, line2)
    call setline(lnum + offset, line1)
  endif
  exe lnum + offset
endfunction

" Iterate colorschemes
function! utils#iter_colorschemes(reverse)
  let step = (a:reverse ? 1 : -1)
  if !exists('g:all_colorschemes')
    let g:all_colorschemes = getcompletion('', 'color')
  endif
  let active_colorscheme = get(g:, 'colors_name', 'default')
  let idx = index(g:all_colorschemes, active_colorscheme)
  let idx = (idx < 0 ? -step : idx) + step  " if idx < 0, set to 0 by default
  if idx < 0
    let idx += len(g:all_colorschemes)
  elseif idx >= len(g:all_colorschemes)
    let idx -= len(g:all_colorschemes)
  endif
  let colorscheme = g:all_colorschemes[idx]
  exe 'colorscheme ' . colorscheme
  silent redraw
  echom 'Colorscheme: ' . colorscheme
  let g:colors_name = colorscheme  " many plugins do this, but this is a backstop
endfunction

" Search for mapping
function! utils#search_maps(regex, ...)
  let mode = a:0 ? a:1 : ''
  redir @z
  exe 'silent ' . mode . 'map'
  redir END
  let regex = '\c' . substitute(a:regex, '\cLeader', 'Space', 'g')
  let maps = split(@z, "\n")
  let maps = filter(maps, "v:val =~# '" . regex . "'")
  return join(maps, "\n")
endfunction

" Enable/disable autocomplete and jedi popups. Very useful on servers slowed to
" a crawl by certain Slovenian postdocs.
function! utils#popup_toggle(...) abort
  if a:0
    let toggle = a:1
  elseif exists('g:popup_toggle')
    let toggle = 1 - g:popup_toggle
  else
    let toggle = 1
  endif
  let g:popup_toggle = toggle
  if exists('*deoplete#custom#option')
    call deoplete#custom#option('auto_complete', toggle ? v:true : v:false)
  endif
  if exists('*jedi#configure_call_signatures')
    let g:jedi#show_call_signatures = toggle
    call jedi#configure_call_signatures()
  endif
endfunction

" Search replace without polluting history
" Undoing this command will move the cursor to the first line in the range of
" lines that was changed: https://stackoverflow.com/a/52308371/4970632
function! utils#replace(global, ...) range abort
  let prevhist = @/
  let winview = winsaveview()
  let region = (a:global ? '%' : a:firstline . ',' . a:lastline)
  echom join(a:000, ', ')
  for i in range(0, a:0 - 2, 2)
    let search = a:000[i]
    let replace = a:000[i + 1]
    keepjumps exe region . 's@' . search . '@' . replace . '@ge'
    call histdel('/', -1)
    let @/ = prevhist
  endfor
  call winrestview(winview)
endfunction

" Current directory change
function! utils#directory_descend() abort
  let cd_prev = getcwd()
  if !exists('b:cd_prev') || b:cd_prev != cd_prev
    let b:cd_prev = cd_prev
  endif
  lcd %:p:h
  echom 'Descended into file directory.'
endfunction
function! utils#directory_return() abort
  if exists('b:cd_prev')
    exe 'lcd ' . b:cd_prev
    unlet b:cd_prev
    echom
  endif
  echom 'Returned to previous directory.'
endfunction

" Tab functions
function! utils#tab_increase() abort  " use this inside <expr> remaps
  let b:menupos += 1 | return ''
endfunction
function! utils#tab_decrease() abort
  let b:menupos -= 1 | return ''
endfunction
function! utils#tab_reset() abort
  let b:menupos = 0 | return ''
endfunction

" Test if file exists
function! utils#file_exists() abort
  let files = glob(expand('<cfile>'))
  if len(files) > 0
    echom 'File(s) ' . join(map(a:0, '"''".v:val."''"'), ', ') . ' exist.'
  else
    echom "File or pattern '" . expand('<cfile>') . "' does not exist."
  endif
endfunction

" Refresh file
function! utils#refresh() abort " refresh sesssion, sometimes ~/.vimrc settings are overridden by ftplugin stuff
  filetype detect " if started with empty file, but now shebang makes filetype clear
  filetype plugin indent on
  let loaded = []
  let files = [
    \ '~/.vimrc',
    \ '~/.vim/ftplugin/' . &filetype . '.vim',
    \ '~/.vim/syntax/' . &filetype . '.vim',
    \ '~/.vim/after/ftplugin/' . &filetype . '.vim',
    \ '~/.vim/after/syntax/' . &filetype . '.vim'
    \ ]
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
  let b:expandtab = &l:expandtab  " this overrides set expandtab in vimrc
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
      au!
      exe 'au ' . cmds . ' <buffer> silent w'
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

" Either listen to input, turn on if switch not declared, or do opposite
function! utils#gitgutter_toggle(...) abort
  if a:0
    let toggle = a:1
  else
    let toggle = (exists('b:gitgutter_enabled') ? 1 - b:gitgutter_enabled : 1)
  endif
  if toggle
    GitGutterEnable
    silent! set signcolumn=yes
    let b:gitgutter_enabled = 1
  else
    GitGutterDisable
    if !(exists('b:syntastic_on') && b:syntastic_on) && !(exists('b:ale_enabled') && b:ale_enabled)
      silent! set signcolumn=no
    endif
    let b:gitgutter_enabled = 0
  endif
endfunction

" Toggle ALE syntax checking
function! utils#ale_toggle(...) abort
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

" Syntastic helper functions
function! s:syntastic_status() abort
  return (exists('b:syntastic_on') && b:syntastic_on)
endfunction
function! s:cmp(a, b) abort
  for i in range(len(a:a))
    if a:a[i] < a:b[i]
      return -1
    elseif a:a[i] > a:b[i]
      return 1
    endif
  endfor
  return 0
endfunction

" Determine checkers from annoying human-friendly output; version suitable
" for scripting does not seem available. Weirdly need 'silent' to avoid
" printint to vim menu. The *last* value in array will be checker.
" Note: For files not written to disk, last line of SyntasticInfo is warning
" message that the file cannot be checked. Below filter ignores this line.
function! utils#syntastic_checkers(...) abort
  " Get available and activated checkers
  redir => output
  silent SyntasticInfo
  redir END
  let result = filter(split(output, "\n"), 'v:val =~# ":"')
  let checkers_avail = split(split(result[-2], ':')[-1], '\s\+')
  let checkers_active = split(split(result[-1], ':')[-1], '\s\+')
  if checkers_avail[0] ==# '-'
    let checkers_avail = []
  endif
  if checkers_active[0] ==# '-'
    let checkers_active = []
  endif

  " Return active checkers and print useulf message
  let checkers_avail = map(
    \ checkers_avail,
    \ 'index(checkers_active, v:val) == -1 ? v:val : "[" . v:val . "]"'
    \ )
  echom 'Available checker(s): ' . join(checkers_avail, ', ')
  return checkers_active
endfunction

" Run checker
function! utils#syntastic_enable() abort
  let nbufs = len(tabpagebuflist())
  let checkers = utils#syntastic_checkers()
  if len(checkers) == 0
    echom 'No checkers activated.'
  else
    SyntasticCheck
    if (len(tabpagebuflist()) > nbufs && !s:syntastic_status())
        \ || (len(tabpagebuflist()) == nbufs && s:syntastic_status())
      wincmd k " jump to main
      let b:syntastic_on = 1
      if !(exists('b:gitgutter_enabled') && b:gitgutter_enabled)
        silent! set signcolumn=no
      endif
    else
      echom 'No errors found.'
      let b:syntastic_on = 0
    endif
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
  if &filetype ==# 'nerdtree'
    wincmd h
    wincmd h " move two places in case e.g. have help menu + nerdtree already
  endif
  let tabfts = map(tabpagebuflist(),'getbufvar(v:val, "&filetype")')
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
  Obsession .vimsession
  qa
  " tabdo windo if &filetype == 'log' | q! | else | q | endif
endfunction
function! utils#tab_close() abort
  let ntabs = tabpagenr('$')
  let islast = (tabpagenr('$') == tabpagenr())
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

" For popup windows
" For location lists, enter jumps to location. Restore this behavior.
function! utils#popup_setup(nofile) abort
  nnoremap <silent> <buffer> <CR> <CR>
  nnoremap <silent> <buffer> <C-w> :q!<CR>
  nnoremap <silent> <buffer> q :q!<CR>
  setlocal nolist nonumber norelativenumber nospell modifiable nocursorline colorcolumn=
  if a:nofile | setlocal buftype=nofile | endif
  if len(tabpagebuflist()) == 1 | q | endif
  exe 'augroup popup_' . bufnr('%')
    au!
    exe 'au BufEnter <buffer> if len(tabpagebuflist()) == 1 | q | endif'
  augroup END
endfunction

" For pager windows
function! utils#pager_setup() abort
  call utils#popup_setup(0) " argument means we do not set buftype=nofile
  nnoremap <buffer> u <C-u>
  nnoremap <nowait> <buffer> d <C-d>
  nnoremap <buffer> b <C-b>
  nnoremap <nowait> <buffer> f <C-f>
endfunction

" For help windows
function! utils#help_setup() abort
  call utils#popup_setup(0) " argument means we do not set buftype=nofile
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
endfunction

" For command windows, make sure local maps work
function! utils#cmdwin_setup() abort
  silent! unmap <CR>
  silent! unmap <C-c>
  nnoremap <buffer> <silent> q :q<CR>
  nnoremap <buffer> <Plug>Execute <C-c><CR>
  inoremap <buffer> <Plug>Execute <C-c><CR>
  inoremap <buffer> <expr> <CR> ""
  setlocal nonumber norelativenumber nolist laststatus=0
endfunction

" Miscellaneous popup windows
" Current syntax names and regex
function! utils#current_group() abort
  let names = []
  for id in synstack(line('.'), col('.'))
    let name = synIDattr(id, 'name')
    let group = synIDattr(synIDtrans(id), 'name')
    if name != group
      let name .= ' (' . group . ')'
    endif
    let names += [name]
  endfor
  echo join(names, ', ')
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
  execute 'split $VIMRUNTIME/ftplugin/' . &filetype . '.vim'
  silent call utils#popup_setup(1)
endfunction
function! utils#show_syntax() abort
  execute 'split $VIMRUNTIME/syntax/' . &filetype . '.vim'
  silent call utils#popup_setup(1)
endfunction

" Popup window with color display
function! utils#color_test() abort
  source $VIMRUNTIME/syntax/colortest.vim
  silent call utils#popup_setup(1)
endfunction

" Cyclic next error in location list
" Copied from: https://vi.stackexchange.com/a/14359
function! utils#cyclic_next(count, list, ...) abort abort
  let reverse = a:0 && a:1
  let func = 'get' . a:list . 'list'
  let params = a:list ==# 'loc' ? [0] : []
  let cmd = a:list ==# 'loc' ? 'll' : 'cc'
  let items = call(func, params)
  if len(items) == 0
    return 'echoerr ' . string('E42: No Errors')
  endif

  " Build up list of loc dictionaries
  call map(items, 'extend(v:val, {"idx": v:key + 1})')
  if reverse
    call reverse(items)
  endif
  let [bufnr, cmp] = [bufnr('%'), reverse ? 1 : -1]
  let context = [line('.'), col('.')]
  if v:version > 800 || has('patch-8.0.1112')
    let current = call(func, extend(copy(params), [{'idx':1}])).idx
  else
    redir => capture | execute cmd | redir END
    let current = str2nr(matchstr(capture, '(\zs\d\+\ze of \d\+)'))
  endif
  call add(context, current)

  " Jump to next loc circularly
  call filter(items, 'v:val.bufnr == bufnr')
  let nbuffer = len(get(items, 0, {}))
  call filter(items, 's:cmp(context, [v:val.lnum, v:val.col, v:val.idx]) == cmp')
  let inext = get(get(items, 0, {}), 'idx', 'E553: No more items')
  if type(inext) == type(0)
    return cmd . inext
  elseif nbuffer != 0
    exe '' . (reverse ? line('$') : 0)
    return utils#cyclic_next(a:count, a:list, reverse)
  else
    return 'echoerr' . string(inext)
  endif
endfunction

" Formatting tools
" This one fixes all lines that are too long, with special consideration for bullet
" style lists and asterisks (does not insert new bullets and adds spaces for asterisks).
function! utils#wrap_item_lines() range abort
  " Build reges
  let regex_head = '^\(\s*\%(' . Comment() . '\s*\)\?\)'
  let regex_item = '\(\%([*-]\|\d\+\.\|\a\+\.\)\s*\)'
  let regex_tail = '\(.*\)$'
  let regex = regex_head . regex_item . regex_tail

  " Put lines on single bullet
  let linenum = a:lastline
  let lastline = a:lastline
  let linecount = 0
  for linenum in range(a:lastline, a:firstline, -1)
    let line = getline(linenum)
    let linecount += 1
    if line =~# regex
      exe linenum . 'join ' . linecount
      let linecount = 0
      if lastline == a:lastline
        let lastline = linenum  " the new lastline
      endif
    endif
  endfor

  " Wrap lines
  for linenum in range(lastline, a:firstline, -1)
    let line = getline(linenum)
    if len(line) > &l:textwidth
      let is_match = line =~# regex
      let match_head = substitute(line, regex, '\1', '')
      let match_tail = substitute(line, regex, '\2', '')
      let line1 = linenum + 1
      exe linenum
      normal! gqgq
      let line2 = line('.')  " may have changed!
      if is_match && line2 >= line1
        exe line1 . ',' . line2
          \ . 's/' . regex_head . regex_item . '\?' . regex_tail
          \ . '/' . match_head . repeat(' ', len(match_tail)) . '\3'
          \ . '/ge'
      endif
    endif
  endfor
endfunction

