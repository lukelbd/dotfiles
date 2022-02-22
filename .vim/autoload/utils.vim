"-----------------------------------------------------------------------------"
" Various utils defined here
"-----------------------------------------------------------------------------"
" Call function over the visual line range or the user motion line range
" Note: Use this approach rather than adding line range as physical arguments and
" calling with call call(func, firstline, lastline, ...) so that funcs can still be
" invoked manually with V<motion>:call func(). This is more standard paradigm.
function! utils#motion_func(funcname, args) abort
  let g:operator_func_signature = a:funcname . '(' . string(a:args)[1:-2] . ')'
  if mode() =~# '^\(v\|V\|\)$'
    return ":\<C-u>'<,'>call utils#operator_func('')\<CR>"
  elseif mode() ==# 'n'
    set operatorfunc=utils#operator_func
    return 'g@'  " uses the input line range
  else
    echoerr 'E999: Illegal mode: ' . string(mode())
    return ''
  endif
endfunction

" Execute the function name and call signature passed to utils#motion_func. This
" is generally invoked inside an <expr> mapping.
" Note: Only motions can cause backwards firstline to lastline order. Manual
" calls to the function will have sorted lines.
function! utils#operator_func(type) range abort
  if empty(a:type)  " default behavior
      let firstline = a:firstline
      let lastline  = a:lastline
  elseif a:type =~? 'line\|char\|block'  " builtin g@ type strings
      let firstline = line("'[")
      let lastline  = line("']")
  else
    echoerr 'E474: Invalid argument: ' . string(a:type)
    return ''
  endif
  if firstline > lastline
    let [firstline, lastline] = [lastline, firstline]
  endif
  exe firstline . ',' . lastline . 'call ' . g:operator_func_signature
  return ''
endfunction

" Special behavior when popup menu is open
" See: https://github.com/lukelbd/dotfiles/blob/master/.vimrc
function! utils#pum_next() abort
  let b:pum_pos += 1 | return "\<C-n>"
endfunction
function! utils#pum_prev() abort
  let b:pum_pos -= 1 | return "\<C-p>"
endfunction
function! utils#pum_reset() abort
  let b:pum_pos = 0 | return ''
endfunction

" Set up temporary paste mode
function! utils#setup_paste() abort
  let s:paste = &paste
  let s:mouse = &mouse
  set paste
  set mouse=
  augroup insert_paste
    au!
    au InsertLeave *
      \ if exists('s:paste') |
      \   let &paste = s:paste |
      \   let &mouse = s:mouse |
      \   unlet s:paste |
      \   unlet s:mouse |
      \ endif |
      \ autocmd! insert_paste
  augroup END
  return ''
endfunction

" Inserting blank lines
" See: https://github.com/tpope/vim-unimpaired
function! utils#blank_up(count) abort
  put!=repeat(nr2char(10), a:count)
  ']+1
  silent! call repeat#set("\<Plug>BlankUp", a:count)
endfunction
function! utils#blank_down(count) abort
  put =repeat(nr2char(10), a:count)
  '[-1
  silent! call repeat#set("\<Plug>BlankDown", a:count)
endfunction

" Swap characters
function! utils#swap_characters(right) abort
  let cnum = col('.')
  let line = getline('.')
  let idx = a:right ? cnum : cnum - 1
  if idx > 0 && idx < len(line)
    let line = line[:idx - 2] . line[idx] . line[idx - 1] . line[idx + 1:]
    call setline('.', line)
  endif
endfunction

" Swap lines
function! utils#swap_lines(bottom) abort
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
function! utils#iter_colorschemes(reverse) abort
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

" Enable/disable autocomplete and jedi popups
function! utils#plugin_toggle(...) abort
  if a:0
    let toggle = a:1
  elseif exists('g:plugin_toggle')
    let toggle = 1 - g:plugin_toggle
  else
    let toggle = 1
  endif
  let g:plugin_toggle = toggle
  if exists('*deoplete#custom#option')
    call deoplete#custom#option('auto_complete', toggle ? v:true : v:false)
  endif
  if exists('*jedi#configure_call_signatures')
    let g:jedi#show_call_signatures = toggle
    call jedi#configure_call_signatures()
  endif
endfunction

" Indent multiple times
function! utils#multi_indent(dedent, count) range abort
  exe a:firstline . ',' . a:lastline . repeat(a:dedent ? '<' : '>', a:count)
endfunction
" For <expr> map accepting motion
function! utils#multi_indent_expr(...) abort
  return utils#motion_func('utils#multi_indent', a:000)
endfunction

" Search replace without polluting history
" Undoing this command will move the cursor to the first line in the range of
" lines that was changed: https://stackoverflow.com/a/52308371/4970632
function! utils#replace_regexes(message, ...) range abort
  let prevhist = @/
  let winview = winsaveview()
  for i in range(0, a:0 - 2, 2)
    keepjumps exe a:firstline . ',' . a:lastline . 's@' . a:000[i] . '@' . a:000[i + 1] . '@ge'
    call histdel('/', -1)
  endfor
  echom a:message
  let @/ = prevhist
  call winrestview(winview)
endfunction
" For <expr> map accepting motion
function! utils#replace_regexes_expr(...) abort
  return utils#motion_func('utils#replace_regexes', a:000)
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
    echom 'Returned to previous directory.'
  else
    echom 'Previous directory is unset.'
  endif
endfunction

" Test if file exists
function! utils#file_exists() abort
  let files = glob(expand('<cfile>'))
  if empty(files)
    echom "File or pattern '" . expand('<cfile>') . "' does not exist."
  else
    echom 'File(s) ' . join(map(a:0, '"''".v:val."''"'), ', ') . ' exist.'
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
  if !empty(item)
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
  if !empty(cmd)
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
  if !empty(cmd)
    silent! exe '!clear; '
      \ . 'search=' . cmd . '; '
      \ . 'if [ -n $search ] && command man $search &>/dev/null; then '
      \ . '  command man $search; '
      \ . 'fi'
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

" Either listen to input, turn on if switch not declared, or do opposite
function! utils#gitgutter_toggle(...) abort
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
    if !(exists('b:syntastic_on') && b:syntastic_on) && !(exists('b:ale_enabled') && b:ale_enabled)
      silent! setlocal signcolumn=no
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
    let cmds = exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave'
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

" Closing tabs and windows
function! utils#window_close() abort
  let ntabs = tabpagenr('$')
  let islast = tabpagenr('$') == tabpagenr()
  quit
  if ntabs != tabpagenr('$') && !islast
    silent! tabp
  endif
endfunction
function! utils#tab_close() abort
  let ntabs = tabpagenr('$')
  let islast = tabpagenr('$') == tabpagenr()
  if ntabs == 1
    qall
  else
    tabclose
    if !islast
      silent! tabp
    endif
  endif
endfunction

" Rename2.vim  -  Rename a buffer within Vim and on disk
" Copyright July 2009 by Manni Heumann <vim at lxxi.org> based on Rename.vim
" Copyright June 2007 by Christian J. Robinson <infynity@onewest.net>
" Usage: Rename[!] {newname}
function! utils#rename_file(name, bang)
  let curfile = expand('%:p')
  let curfilepath = expand('%:p:h')
  let newname = curfilepath . '/' . a:name
  let v:errmsg = ''
  silent! exe 'saveas' . a:bang . ' ' . newname
  if v:errmsg =~# '^$\|^E329'
    if expand('%:p') !=# curfile && filewritable(expand('%:p'))
      silent exe 'bwipe! ' . curfile
      if delete(curfile)
        echoerr 'Could not delete ' . curfile
      endif
    endif
  else
    echoerr v:errmsg
  endif
endfunction

" For popup windows
" File mode can be 0 (no file) 1 (simple file) or 2 (editable file)
" Warning: Critical error happens if try to auto-quite when only popup window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with utils#tab_close().
function! s:no_buffer_map(map)
  let dict = maparg(a:map, 'n', v:false, v:true)
  return empty(dict) || !dict['buffer']
endfunction
function! utils#popup_setup(...) abort
  let filemode = a:0 ? a:1 : 1
  if s:no_buffer_map('q') | nnoremap <silent> <buffer> q :quit!<CR> | endif
  if s:no_buffer_map('<C-w>') | nnoremap <silent> <buffer> <C-w> :quit!<CR> | endif
  setlocal nolist nonumber norelativenumber nocursorline colorcolumn=
  if filemode == 0 | setlocal buftype=nofile | endif  " this has no file
  if filemode == 2 | return | endif  " this is editable file
  setlocal nospell statusline=%{''}  " additional settings
  if s:no_buffer_map('u') | nnoremap <buffer> u <C-u> | endif
  if s:no_buffer_map('d') | nnoremap <buffer> <nowait> d <C-d> | endif
  if s:no_buffer_map('b') | nnoremap <buffer> b <C-b> | endif
  if s:no_buffer_map('f') | nnoremap <buffer> <nowait> f <C-f> | endif
endfunction

" For help windows
function! utils#help_setup() abort
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
  nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
  silent call utils#popup_setup()
endfunction

" For command windows, make sure local maps work
function! utils#cmdwin_setup() abort
  inoremap <buffer> <expr> <CR> ""
  nnoremap <buffer> <CR> <C-c><CR>
  nnoremap <buffer> <Plug>Execute <C-c><CR>
  silent call utils#popup_setup()
endfunction

" Popup windows showing ftplugin files, syntax files, color display
function! utils#show_ftplugin() abort
  execute 'split $VIMRUNTIME/ftplugin/' . &filetype . '.vim'
  silent call utils#popup_setup()
endfunction
function! utils#show_syntax() abort
  execute 'split $VIMRUNTIME/syntax/' . &filetype . '.vim'
  silent call utils#popup_setup()
endfunction
function! utils#color_test() abort
  source $VIMRUNTIME/syntax/colortest.vim
  silent call utils#popup_setup()
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

" Cyclic next error in location list
" Copied from: https://vi.stackexchange.com/a/14359
function! utils#cyclic_next(count, list, ...) abort
  let reverse = a:0 && a:1
  let func = 'get' . a:list . 'list'
  let params = a:list ==# 'loc' ? [0] : []
  let cmd = a:list ==# 'loc' ? 'll' : 'cc'
  let items = call(func, params)
  if empty(items)
    return 'echoerr ' . string('E42: No Errors')  " string() adds quotes
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
    return 'echoerr ' . string(inext)  " string() adds quotes
  endif
endfunction

" Formatting tools
" Build regexes
let s:item_head = '^\(\s*\%(' . Comment() . '\s*\)\?\)'  " leading spaces or comment
let s:item_indicator = '\(\%([*-]\|\d\+\.\|\a\+\.\)\s\+\)'  " item indicator plus space
let s:item_tail = '\(.*\)$'  " remainder of line
let s:item_total = s:item_head . s:item_indicator . s:item_tail

" Remove the item indicator
function! s:remove_item(line, firstline_, lastline_) abort
  let match_head = substitute(a:line, s:item_total, '\1', '')
  let match_item = substitute(a:line, s:item_total, '\2', '')
  keepjumps exe a:firstline_ . ',' . a:lastline_
    \ . 's@' . s:item_head . s:item_indicator . '\?' . s:item_tail
    \ . '@' . match_head . repeat(' ', len(match_item)) . '\3'
    \ . '@ge'
  call histdel('/', -1)
endfunction

" Wrap the lines to 'count' columns rather than 'textwidth'
" Note: Could put all commands in feedkeys() but then would get multiple
" commands flashing at bottom of screen. Also need feedkeys() because normal
" doesn't work inside an expression mapping.
function! utils#wrap_lines(...) range abort
  let textwidth = &l:textwidth
  let &l:textwidth = a:0 ? a:1 ? a:1 : textwidth : textwidth
  let cmd =
    \ a:lastline . 'gggq' . a:firstline . 'gg'
    \ . ':silent let &l:textwidth = ' . textwidth
    \ . " | echom 'Wrapped lines to " . &l:textwidth . " characters.'\<CR>"
  call feedkeys(cmd, 'n')
endfunction
" For <expr> map accepting motion
function! utils#wrap_lines_expr(...) abort
  return utils#motion_func('utils#wrap_lines', a:000)
endfunction

" Fix all lines that are too long, with special consideration for bullet style lists and
" asterisks (does not insert new bullets and adds spaces for asterisks).
" Note: This is good example of incorporating motion support in custom functions!
" Note: Optional arg values is vim 8.1+ feature; see :help optional-function-argument
" See: https://vi.stackexchange.com/a/7712/8084 and :help g@
function! utils#wrap_items(...) range abort
  let textwidth = &l:textwidth
  let &l:textwidth = a:0 ? a:1 ? a:1 : textwidth : textwidth
  let prevhist = @/
  let winview = winsaveview()
  " Put lines on a single bullet
  let linecount = 0
  let lastline = a:lastline
  for linenum in range(a:lastline, a:firstline, -1)
    let line = getline(linenum)
    let linecount += 1
    if line =~# s:item_total
      let tail = substitute(line, s:item_total, '\3', '')
      if tail =~# '^\s*[a-z]'  " remove item indicator if starts with lowercase
        call s:remove_item(line, linenum, linenum)
      else  " otherwise join count lines and adjust lastline
        exe linenum . 'join ' . linecount
        let lastline -= linecount - 1
        let linecount = 0
      endif
    endif
  endfor
  " Wrap each line, accounting for bullet indent. If gqgq results in a wrapping, cursor
  " is placed at end of that block. Then must remove auto-inserted item indicators.
  echom lastline . ', ' . a:firstline
  for linenum in range(lastline, a:firstline, -1)
    exe linenum
    let line = getline('.')
    normal! gqgq
    if line =~# s:item_total && line('.') > linenum
      call s:remove_item(line, linenum + 1, line('.'))
    endif
  endfor
  let @/ = prevhist
  call winrestview(winview)
  let &l:textwidth = textwidth
endfunction

" For <expr> map accepting motion
function! utils#wrap_items_expr(...) abort
  return utils#motion_func('utils#wrap_items', a:000)
endfunction
