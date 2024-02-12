"-----------------------------------------------------------------------------"
" Internal utilities
"-----------------------------------------------------------------------------"
" Null input() completion function
" This prevents unexpected insertion of literal tabs
" Note: Used in various places throughout autoload
function! utils#null_list(...) abort
  return []
endfunction
" Null operator motion function
function! utils#null_operator(...) range abort
  return ''
endfunction
" For <expr> mapping accepting motion
function! utils#null_operator_expr(...) abort
  return utils#motion_func('utils#null_operator', a:000)
endfunction

" Get user input with requested default
" Note: This is currently used with grep and file mappings. Specifies a default value
" in parentheses that can be tab expanded, selects it when user presses enter, or
" replaces it when user starts typing text or backspace. This is a bit nicer than
" filling input prompt with default value, simply start typing to drop the default
function! utils#input_list(lead, line, cursor)
  let [initial, funcname, default; force] = s:complete_opts
  let force = len(force) && force[0]
  if !initial  " get complete options
    if funcname =~# '^[a-z_]\+$'
      let opts = getcompletion(a:lead, funcname)
    else
      let opts = call(funcname, [a:lead, a:line, a:cursor])
    endif
  else
    let s:complete_opts[0] = 0
    try  " note getcharstr() returns key codes for <BS> instead of empty string
      let char = nr2char(getchar())
    catch  " user presses Ctrl-C
      let char = "\<C-c>"
    endtry
    if len(char) == 0  " clear prompt
      let opts = [force ? default : '']
      call feedkeys(force ? "\<CR>" : '', 't')
    elseif char =~# '\p'  " printable character
      let opts = [char]
      call feedkeys(force ? "\<CR>" : '', 't')
    elseif char ==# "\<Tab>"  " expand default
      let opts = [default]
      call feedkeys(force ? "\<CR>" : '', 't')
    elseif char ==# "\<CR>"  " confirm default
      let opts = [default]
      call feedkeys("\<CR>", 't')
    else  " escape or cancel
      let opts = ['']
      call feedkeys("\<CR>", 't')
    endif
  endif
  return opts
endfunction
function! utils#input_default(prompt, funcname, default, ...) abort
  let parenth = empty(a:default) ? '' : ' (' . a:default . ')'
  let prompt = a:prompt . parenth . ': '
  let s:complete_opts = [1, a:funcname, a:default] + a:000
  call feedkeys("\<Tab>", 't')
  return input(prompt, '', 'customlist,utils#input_list')
endfunction

" Get the fzf.vim/autoload/fzf/vim.vim script id for overriding. This is
" used to override fzf marks command and support jumping to existing tabs.
" See: https://stackoverflow.com/a/49447600/4970632
function! utils#find_snr(regex) abort
  silent! call fzf#vim#with_preview()  " trigger autoload if not already done
  let [paths, sids] = vim#config_scripts(1)
  let path = filter(copy(paths), 'v:val =~# a:regex')
  let idx = index(paths, get(path, 0, ''))
  if !empty(path) && idx >= 0
    return "\<snr>" . sids[idx] . '_'
  else
    echohl WarningMsg
    echom "Warning: Autoload script '" . a:regex . "' not found."
    echohl None
    return ''
  endif
endfunction

" Call over the visual line range or user motion line range (see e.g. python.vim)
" Note: :call call(function, args) with range seems to execute line-by-line instead of
" entire block which causes issues with some functions. So use below clunky method.
" Also ensure functions accept :[range]call function(args) for consistency with vim
" standard paradigm and so they can be called with e.g. V<motion>:call func().
function! utils#motion_func(funcname, args) abort
  let funcstring = a:funcname . '(' . string(a:args)[1:-2] . ')'
  let s:operator_func = funcstring
  if mode() =~# '^\(v\|V\|\)$'  " call operator function with line range
    return ":call utils#operator_func('')\<CR>"
  elseif mode() ==# 'n'
    set operatorfunc=utils#operator_func
    return 'g@'  " await user motion and call operator function over those lines
  else
    echoerr 'E999: Illegal mode: ' . string(mode())
    return ''
  endif
endfunction

" Execute the function name and call signature passed to utils#motion_func.
" This is generally invoked inside an <expr> mapping (see e.g. python.vim) .
" Note: Only motions can cause backwards firstline to lastline order. Manual calls
" to the function will have sorted lines. This sorts the range for safety.
function! utils#operator_func(type) range abort
  if empty(a:type) " default behavior
      let line1 = a:firstline
      let line2 = a:lastline
  elseif a:type =~? 'line\|char\|block' " builtin g@ type strings
      let line1 = line("'[")
      let line2 = line("']")
  else
    echoerr 'E474: Invalid argument: ' . string(a:type)
    return ''
  endif
  let [line1, line2] = sort([line1, line2], 'n')
  exe line1 . ',' . line2 . 'call ' . s:operator_func
  return ''
endfunction

" Setup panel windows. Mode can be 0 (not editable) or 1 (editable).
" Warning: Setting nomodifiable tends to cause errors e.g. for log files run with
" shell#job_win() or other internal stuff. So instead just try to disable normal mode
" commands that could accidentally modify text (aside from d used for scrolling).
" Warning: Critical error happens if try to auto-quit when only panel window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with session#close_tab().
function! utils#panel_setup(modifiable) abort
  setlocal nolist nonumber norelativenumber nocursorline
  nnoremap <buffer> q <Cmd>silent! call window#close_window()<CR>
  nnoremap <buffer> <C-w> <Cmd>silent! call window#close_window()<CR>
  if &filetype ==# 'qf'  " disable <Nop> map
    nnoremap <buffer> <CR> <CR>zv
  endif
  if &filetype ==# 'netrw'
    call utils#switch_maps(['<CR>', 't'], ['t', '<CR>'])
  endif
  if a:modifiable == 1  " e.g. gitcommit window
    return
  endif
  setlocal nospell colorcolumn=
  setlocal statusline=%{'[Panel:Z'.&l:foldlevel.']'}%=%{StatusRight()}
  for char in 'du'  " always remap scrolling indicators
    exe 'map <buffer> <nowait> ' . char . ' <C-' . char . '>'
  endfor
  for char in 'uUrRxXdDcCpPaAiIoO'  " ignore buffer-local maps e.g. fugitive
    if !get(maparg(char, 'n', 0, 1), 'buffer', 0)
      exe 'nmap <buffer> ' char . ' <Nop>'
    endif
  endfor
endfunction

" Switch buffer-local panel mappings
" Note: Vim help recommends capturing full map settings using maparg(lhs, 'n', 0, 1)
" then re-adding them using mapset(). This is a little easier than working with strings
" returned by maparg(lhs, 'n'), for which we have to use escape(map, '"<') then
" evaluate the resulting string with eval('"' . map . '"'). However in the dictionary
" case, the 'rhs' entry uses <sid> instead of <snr>nr, and when calling mapset(), the
" *current script* id is used rather than the id in the dict. Have to fix this manually.
function! s:eval_map(map) abort
  let rhs = get(a:map, 'rhs', '')
  let sid = get(a:map, 'sid', '')  " see above
  let snr = '<snr>' . sid . '_'
  let rhs = substitute(rhs, '\c<sid>', snr, 'g')
  return rhs
endfunction
function! utils#switch_maps(...) abort
  let dicts = []  " delay assignment until iteration
  for [lhs1, lhs2] in a:000
    let iarg = maparg(lhs1, 'n', 0, 1)
    let lhs3 = substitute(lhs2, '^<', '\\<', '')
    let lhs3 = eval('"' . lhs3 . '"')
    let opts = {'rhs': s:eval_map(iarg), 'lhs': lhs2, 'lhsraw': lhs3}
    call extend(iarg, opts)
    call add(dicts, iarg)
  endfor
  for iarg in dicts
    call mapset('n', 0, iarg)
  endfor
endfunction

" Return commands specifying or demanding a register (e.g. " or peekaboo)
" Note: These functions translate counts passed to yanks/change/delete/paste to first
" 12 letters of alphabet, counts passed to macro records/plays to next 12 letters of
" alphabet, and counts passed to mark sets/jumps to first 24 letters of alphabet.
" Leave letters 'y' and 'z' alone for internal use (currently just used by marks).
function! s:translate_count(mode, ...) abort
  let cnt = v:count
  let curr = v:register
  let warnings = []
  if curr !=# '"' && a:mode !=# 'm'  " no translation needed
    return [curr, '']
  elseif a:mode =~# '[m`]'  " marks: uppercase a-z (24)
    let [base, min, max] = [64, 1, 24]
  elseif a:mode =~# '[q@]'  " macros: lowercase n-z (13)
    let [base, min, max] = [109, 1, 13]
  else  " others: lowercase a-m (13)
    let [base, min, max] = [96, 0, 13]
  endif
  if cnt == 0 && a:mode ==# '`'
    let stack = get(g:, 'mark_recents', [])
    let name = empty(stack) ? 'A' : stack[-1]  " recently set
  else
    let min = a:0 ? a:1 : min  " e.g. set to '0' disables v:count1 for 'm' and 'q'
    let adj = max([min, cnt])  " use v:count1 for 'm' and 'q'
    let adj = min([adj, max])  " below maximum letter
    let name = adj ? nr2char(base + adj) : ''
  endif
  if cnt > max  " emit warning
    let head = "Count '" . cnt . "' too high for register translation."
    let tail = "Using maximum '" . name . "' (" . max . ').'
    call add(warnings, head . ' ' . tail)
  endif
  if a:mode ==# 'm' && index(map(getmarklist(), "v:val['mark']"), "'" . name) != -1
    let head = 'Overwriting existing mark'
    let tail = "'" . name . "' (" . cnt . ').'
    call add(warnings, head . ' ' . tail)
  endif
  if !empty(warnings)
    echohl WarningMsg
    echom 'Warning: ' . join(warnings, ' ')
    echohl None
  endif
  return [name, empty(warnings) ? 'count ' . cnt : '']
endfunction
" Translate into map command
function! s:translate_input(mode, ...) abort
  let peekaboo = a:0 > 1 ? a:2 : ''  " whether double press should open peekaboo panel
  let default = a:0 > 0 ? a:1 : ''  " default register after key press (e.g. 'yy or \"yy)
  let char = ''
  if empty(default) && empty(peekaboo)
    let [name, label] = s:translate_count(a:mode)
    if a:mode =~# '[m`q@]'  " marks/macros (register mandatory)
      let result = name
    elseif !empty(name)  " yanks/changes/deletes/pastes
      let result = '"' . name
    else  " default unnamed register
      let result = ''
    endif
  else
    let [name, label] = s:translate_count(a:mode, 0)
    if !empty(name)  " ''/\"\"/'<command>/\"<command>
      let result = '"' . name
    else
      " let char = nr2char(getchar())  " single character
      let char = utils#input_default('Register', '', '', 1)
      if empty(char)
        let name = char
        let result = ''
      elseif char =~# '[''";_]'  " await native register selection
        let name = peekaboo ? '"' : utils#input_default('Raw Register', '', '', 1)
        let result = '"' . name
      elseif char =~# '\d'  " use character to pick number register
        let name = char
        let result = '"' . name
      else  " pass character to next normal mode command (e.g. d2j, ciw, yy)
        let name = default
        let result = '"' . name . char  " including next character
      endif
      if name ==# '_'
        let label = 'blackhole'
      elseif name =~# '[+*]'
        let label = 'clipboard'
      elseif name =~# '\d'  " use character to pick number register
        let label = name . get({'1': 'st', '2': 'nd', '3': 'rd'}, name, 'th') . ' delete'
      elseif empty(name)
        let label = ''
      endif
    endif
  endif
  if !empty(name) && !empty(label)
    let head = a:mode =~# '[m`]' ? 'Mark' : 'Register'
    echom head . ': ' . name[0] . ' (' . label . ')'
  endif
  return result
endfunction
" Public function without autocommands
function! utils#translate_name(...) abort
  noautocmd return call('s:translate_input', a:000)
endfunction

" Tables of netrw mappings
" See: :help netrw-quickmaps
" ---     -----------------      ----
" Map     Quick Explanation      Link
" ---     -----------------      ----
" <F1>    Causes Netrw to issue help
" <cr>    Netrw will enter the directory or read the file
" <del>   Netrw will attempt to remove the file/directory
" <c-h>   Edit file hiding list
" <c-l>   Causes Netrw to refresh the directory listing
" <c-r>   Browse using a gvim server
" <c-tab> Shrink/expand a netrw/explore window
"   -     Makes Netrw go up one directory
"   a     Cycles between normal display, hiding  (suppress display of files matching
"         g:netrw_list_hide) and showing (display only files which match g:netrw_list_hide)
"   cd    Make browsing directory the current directory
"   C     Setting the editing window
"   d     Make a directory
"   D     Attempt to remove the file(s)/directory(ies)
"   gb    Go to previous bookmarked directory
"   gd    Force treatment as directory
"   gf    Force treatment as file
"   gh    Quick hide/unhide of dot-files
"   gn    Make top of tree the directory below the cursor
"   gp    Change local-only file permissions
"   i     Cycle between thin, long, wide, and tree listings
"   I     Toggle the displaying of the banner
"   mb    Bookmark current directory
"   mc    Copy marked files to marked-file target directory
"   md    Apply diff to marked files (up to 3)
"   me    Place marked files on arg list and edit them
"   mf    Mark a file
"   mF    Unmark files
"   mg    Apply vimgrep to marked files
"   mh    Toggle marked file suffices' presence on hiding list
"   mm    Move marked files to marked-file target directory
"   mp    Print marked files
"   mr    Mark files using a shell-style
"   mt    Current browsing directory becomes markfile target
"   mT    Apply ctags to marked files
"   mu    Unmark all marked files
"   mv    Apply arbitrary vim   command to marked files
"   mx    Apply arbitrary shell command to marked files
"   mX    Apply arbitrary shell command to marked files en bloc
"   mz    Compress/decompress marked files
"   o     Enter the file/directory under the cursor in a new horizontal split browser.
"   O     Obtain a file specified by cursor
"   p     Preview the file
"   P     Browse in the previously used window
"   qb    List bookmarked directories and history
"   qf    Display information on file
"   qF    Mark files using a quickfix list
"   qL    Mark files using a
"   r     Reverse sorting order
"   R     Rename the designated file(s)/directory(ies)
"   s     Select sorting style: by name, time, or file size
"   S     Specify suffix priority for name-sorting
"   t     Enter the file/directory under the cursor in a new tab
"   u     Change to recently-visited directory
"   U     Change to subsequently-visited directory
"   v     Enter the file/directory under the cursor in a new vertical split browser.
"   x     View file with an associated program
"   X     Execute filename under cursor via
"   %  Open a new file in netrw's current directory
