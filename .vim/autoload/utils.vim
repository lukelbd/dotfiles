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
  let [init, funcname, default] = s:complete_opts
  if !init  " get complete options
    if funcname =~# '^[a-z_]\+$'
      let opts = getcompletion(a:lead, funcname)
    else
      let opts = call(funcname, [a:lead, a:line, a:cursor])
    endif
  else
    let s:complete_opts[0] = 0
    try
      let char = nr2char(getchar())
    catch  " user presses Ctrl-C
      let char = "\<C-c>"
    endtry
    if len(char) == 0  " clear prompt
      let opts = ['']
    elseif char =~# '\p'  " fill prompt
      let opts = [char]
    elseif char ==# "\<Tab>"  " expand default
      let opts = [default]
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
function! utils#input_default(prompt, funcname, default) abort
  let prompt = a:prompt . ' (' . a:default . '): '
  let s:complete_opts = [1, a:funcname, a:default]
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
  if &l:foldlevel == 0 | let &l:foldlevel = 1 | endif
  nnoremap <silent> <buffer> q :call window#close_window()<CR>
  nnoremap <silent> <buffer> <C-w> :call window#close_window()<CR>
  if &filetype ==# 'qf'  " disable <Nop> map
    nnoremap <buffer> <CR> <CR>zv
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

" Return commands specifying or demanding a register (e.g. " or peekaboo)
" Note: These functions translate counts passed to yanks/change/delete/paste to first
" 12 letters of alphabet, counts passed to macro records/plays to next 12 letters of
" alphabet, and counts passed to mark sets/jumps to first 24 letters of alphabet.
" Leave letters 'y' and 'z' alone for internal use (currently just used by marks).
function! s:translate_count(mode, ...) abort
  let cnt = v:count
  let curr = v:register
  if curr !=# '"' && a:mode !=# 'm'  " no translation needed
    return [curr, '']
  elseif a:mode =~# '[m`]'  " marks: uppercase a-z (24)
    let [base, min, max] = [64, 1, 24]
  elseif a:mode =~# '[q@]'  " macros: lowercase n-z (13)
    let [base, min, max] = [109, 1, 13]
  else  " others: lowercase a-m (13)
    let [base, min, max] = [96, 0, 13]
  endif
  let min = a:0 ? a:1 : min  " e.g. set to '0' disables v:count1 for 'm' and 'q'
  let adj = max([min, cnt])  " use v:count1 for 'm' and 'q'
  let adj = min([adj, max])  " below maximum letter
  let name = adj ? nr2char(base + adj) : ''
  let warnings = []
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
function! utils#translate_count(mode, ...) abort
  let peekaboo = a:0 > 1 ? a:2 : ''  " whether double press should open peekaboo panel
  let default = a:0 > 0 ? a:1 : ''  " default register after key press (e.g. 'yy or \"yy)
  let label = default ==# '_' ? 'blackhole' : default =~# '[+*]' ? 'clipboard' : ''
  let char = ''
  if empty(default) && empty(peekaboo)
    let [name, label] = s:translate_count(a:mode)
    if a:mode =~# '[m`q@]'  " marks/macros (register mandatory)
      let result = name
    elseif !empty(name)  " yanks/changes/deletes/pastes
      let result = '"' . name
    else
      let result = ''
    endif
  else
    let [name, label] = s:translate_count(a:mode, 0)
    if !empty(name)  " ''/\"\"/'<command>/\"<command>
      let result = '"' . name
    else
      let char = nr2char(getchar())
      if char =~# '["'']'  " await native register selection
        echom 'Register: ...'
        let name = peekaboo ? '"' : nr2char(getchar())
        let label = ''
        let result = '"' . name
        echom 'Register: ' . name[0]
      elseif char =~# '\d'  " use character to pick number register
        let name = char
        let label = 'previous delete'
        let result = '"' . name
      else  " pass character to next normal mode command (e.g. d2j, ciw, yy)
        let name = default
        let label = name ==# '_' ? 'blackhole' : name =~# '[+*]' ? 'clipboard' : ''
        let result = '"' . name . char  " including next character
      endif
    endif
  endif
  if !empty(name) && !empty(label)
    let head = a:mode =~# '[m`]' ? 'Mark' : 'Register'
    echom head . ': ' . name[0] . ' (' . label . ')'
  endif
  return result
endfunction
