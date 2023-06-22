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
  let [init, funcname, default, fill] = s:complete_params
  if !init  " kludge for default behavior
    return call(funcname, a:000)
  else
    let s:complete_params[0] = 0
    try
      let char = nr2char(getchar())
    catch  " user presses Ctrl-C
      call feedkeys("\<CR>", 't')
      return ['']
    endtry
    if char ==# "\<Tab>"
      return [fill]
    elseif char ==# "\<CR>"
      call feedkeys("\<CR>", 't')
      return [fill]
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
function! utils#input_complete(prompt, funcname, default, ...) abort
  let fill = call(a:funcname, [a:default, '', ''])
  let fill = empty(fill) ? a:default : fill[0]  " e.g. expand intial path
  let message = a:prompt . ' (' . a:default . '): '
  let s:complete_params = [1, a:funcname, a:default, fill]
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

" Set registers or return command that will demand a register (" or peekaboo).
" Note: First function translates counts passed to yanks/change/delete/paste and
" marks to named registers a-j or a-k, and counts passed to macros to registers k-v.
" Note: This permits passing counts as shorthand for number registers (maps ' and ") or
" for the number-translated register set a-j (map <Leader>') or k-u (map <Leader>").
" So have two options for specifying (translated or untranslated) number register:
" either counts or as the register name (e.g. 2'p and ''2p are same). Double press of
" ' and " are required when specifying name, except for <Leader> maps (see vimrc).
function! utils#register_find(mode) abort
  if v:count  " now enable translation
    if a:mode ==# "'"
      let reg = nr2char(96 + v:count)
    else
      let reg = nr2char(105 + v:count1)
    endif
    echom 'Register: ' . reg . ' (' . v:count . ')'
    let cmd = "\<Esc>" . '"' . reg
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
  return cmd
endfunction
function! utils#register_count(mode) abort
  if v:count > 9
    echoerr 'Error: Shorthand register number must fall between 0 and 9.'
    return ''
  endif
  if a:mode =~# 'q\|@'  " marks: letters j-s (10)
    let reg = nr2char(105 + v:count1)
    let cmd = reg
    if a:mode ==# 'q'
      let record = get(b:, 'recording', 0)
      let cmd = record ? '' : cmd
      let b:recording = 1 - record
    endif
  elseif a:mode =~# '`\|m'  " macros: letters a-j (10)
    let cmd = reg
    let reg = nr2char(97 + v:count)
    if a:mode ==# 'm'
      let cmd = cmd . "\<Cmd>HighlightMark " . reg . "\<CR>"
    endif
  else  " yanks/changes/deletes/pastes: letters a-i (9) else default
    let reg = v:count ? nr2char(96 + v:count) : ''
    let cmd = empty(reg) ? '' : '"' . reg
    if v:count && a:mode ==# 'n'
      let cmd = "\<Esc>" . cmd
    endif
  endif
  if !empty(reg)
    echom 'Register: ' . reg . ' (' . v:count . ')'
  endif
  return cmd
endfunction
