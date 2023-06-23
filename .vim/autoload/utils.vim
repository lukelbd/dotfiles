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

" Get user input (see grep and file command completion)
" Note: This is used for grep and file command completions. It specifies a default
" value in parentheses that can be tab expanded, selects it when user presses enter,
" or replaces it when user starts typing text. Unique part is that it does not fill
" the input line with text from the start, allowing both 1) quick user overrides of
" the entire line and 2) quick selection of a default value, all in one cmdline line.
function! utils#input_list(...)
  let [init, funcname, default] = s:complete_opts
  if !init  " kludge for default behavior
    return call(funcname, a:000)
  else
    let s:complete_opts[0] = 0
    try
      let char = nr2char(getchar())
    catch  " user presses Ctrl-C
      call feedkeys("\<CR>", 't')
      return ['']
    endtry
    if char ==# "\<Tab>"
      return [default]
    elseif char ==# "\<CR>"
      call feedkeys("\<CR>", 't')
      return [default]
    elseif char =~# '\p'
      return [char]
    elseif len(char) == 0  " backspace or delete
      return ['']
    else
      call feedkeys("\<CR>", 't')
      return ['']
    endif
  endif
endfunction
function! utils#input_complete(prompt, funcname, default) abort
  let default = call(a:funcname, [a:default, '', ''])
  let default = empty(default) ? a:default : default[0]  " e.g. default intial path
  let message = a:prompt . ' (' . a:default . '): '
  let s:complete_opts = [1, a:funcname, default]
  call feedkeys("\<Tab>", 't')
  return input(message, '', 'customlist,utils#input_list')
endfunction

" Call over the visual line range or user motion line range (see e.g. python.vim)
" Note: Use this approach rather than adding line range as physical arguments and
" calling with call call(func, firstline, lastline, ...) so that funcs can still be
" invoked manually with V<motion>:call func(). This is the more standard paradigm.
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

" Execute the function name and call signature passed to utils#motion_func.
" This is generally invoked inside an <expr> mapping (see e.g. python.vim) .
" Note: Only motions can cause backwards firstline to lastline order. Manual calls
" to the function will have sorted lines. So this sorts for safety.
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

" Setup popup windows. Mode can be 0 (not editable) or 1 (editable).
" Warning: Setting nomodifiable tends to cause errors e.g. for log files run with
" shell#job_win() or other internal stuff. So instead just try to disable normal mode
" commands that could accidentally modify text (aside from d used for scrolling).
" Warning: Critical error happens if try to auto-quit when only popup window is
" left... fzf will take up the whole window in small terminals, and even when fzf
" immediately runs and closes as e.g. with non-tex BufNewFile template detection,
" this causes vim to crash and breaks the terminal. Instead never auto-close windows
" and simply get in habit of closing entire tabs with session#close_tab().
function! utils#popup_setup(filemode) abort
  nnoremap <silent> <buffer> q :call window#close_window()<CR>
  nnoremap <silent> <buffer> <C-w> :call window#close_window()<CR>
  setlocal nolist nonumber norelativenumber nocursorline
  if &filetype ==# 'qf' | nnoremap <buffer> <CR> <CR> | endif
  if a:filemode == 1 | return | endif  " this is an editable file
  setlocal nospell colorcolumn= statusline=%{'[Popup\ Window]'}%=%{StatusRight()}  " additional settings
  for char in 'uUrRxXpPdDaAiIcCoO' | exe 'nmap <buffer> ' char . ' <Nop>' | endfor
  for char in 'dufb' | exe 'map <buffer> <nowait> ' . char . ' <C-' . char . '>' | endfor
endfunction

" Return commands specifying or demanding a register (e.g. " or peekaboo)
" Note: These functions translate counts passed to yanks/change/delete/paste to first
" 12 letters of alphabet, counts passed to macro records/plays to next 12 letters of
" alphabet, and counts passed to mark sets/jumps to first 24 letters of alphabet.
" Leave letters 'y' and 'z' alone for internal use (currently just used by marks).
function! s:translate_count(mode) abort
  let cnt = v:count
  if a:mode =~# '`\|m'  " marks: letters j-s (10)
    let type = 'Mark'
    let [base, min, max] = [96, 1, 24]
  elseif a:mode =~# 'q\|@\|"'  " macros: letters a-j (10)
    let type = 'Register'
    let [base, min, max] = [108, 1, 12]
  else
    let type = 'Register'
    let [base, min, max] = [96, 0, 12]
  endif
  if cnt > max
    echohl WarningMsg
    echom "Warning: Shorthand number for '" . a:mode . '" must be less than ' . max . '.'
    echohl None
    let cnt = max
  endif
  let cnt = max([min, cnt])  " similar to v:count1
  let name = cnt == 0 ? '' : nr2char(base + cnt)
  if !empty(name)
    echom type . ': ' . name . ' (' . cnt . ')'
  endif
  return name
endfunction
" Convert count into command
function! utils#translate_count(mode) abort
  let name = s:translate_count(a:mode)
  if a:mode =~# "'" . '\|' . '"'
    if !empty(name)
      let cmd = "\<Esc>" . '"' . name
    else
      let char = nr2char(getchar())
      if char ==# "'"  " manual register selection
        let cmd = '"'
      elseif char ==# '"'  " peekaboo register selection
        let cmd = '""'
      elseif a:mode ==# "'"
        let cmd = '"_' . char
      else
        let cmd = '"*' . char
      endif
    endif
  elseif a:mode =~# '`\|m'  " marks
    let cmd = name
    if a:mode ==# 'm'
      let cmd = cmd . "\<Cmd>HighlightMark " . name . "\<CR>"
    endif
  elseif a:mode =~# 'q\|@'  " macros
    let cmd = name
    if a:mode ==# 'q'
      let rec = get(b:, 'recording', 0) | let cmd = rec ? '' : cmd | let b:recording = 1 - rec
    endif
  else  " yanks/changes/deletes/pastes
    let cmd = empty(name) ? '' : '"' . name
    if !empty(name) && a:mode ==# 'n'
      let cmd = "\<Esc>" . cmd
    endif
  endif
  return cmd
endfunction
