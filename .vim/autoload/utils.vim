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
function! utils#input_list(...)
  let [init, funcname, default] = s:complete_opts
  if !init  " get complete options
    let opts = call(funcname, a:000)
  else
    let s:complete_opts[0] = 0
    try
      let char = nr2char(getchar())
    catch  " user presses Ctrl-C
      let char = "\<C-c>"
    endtry
    if char =~# '\p'  " fill prompt
      let opts = [char]
    elseif len(char) == 0  " clear prompt
      let opts = ['']
    elseif char ==# "\<Tab>"  " expand default
      let opts = [default]
    elseif char ==# "\<CR>"  " confirm default
      call feedkeys("\<CR>", 't')
      let opts = [default]
    else  " escape or cancel
      call feedkeys("\<CR>", 't')
      let opts = ['']
    endif
  endif
  return opts
endfunction
function! utils#input_default(prompt, funcname, default) abort
  let s:complete_opts = [1, a:funcname, a:default]
  call feedkeys("\<Tab>", 't')
  return input(a:prompt . ': ', '', 'customlist,utils#input_list')
endfunction

" Set up command for repetition
" Todo: Finish writing this function for e.g. [G and ]G
function! utils#repeat_command() abort
  :
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
" Note: Use this approach rather than adding line range as physical arguments and
" calling with call call(func, firstline, lastline, ...) so that funcs can still be
" invoked manually with V<motion>:call func(). This is the more standard paradigm.
function! utils#motion_func(funcname, args) abort
  let g:operator_func_signature = a:funcname . '(' . string(a:args)[1:-2] . ')'
  if mode() =~# '^\(v\|V\|\)$'
    return ":call utils#operator_func('')\<CR>"
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
  if curr !=# '"' && a:mode !=# 'm'
    return [curr, '']
  elseif a:mode =~# '[m`]'  " marks: uppercase a-z (24)
    let [base, min, max] = [64, 1, 24]
  elseif a:mode =~# '[q@]'  " macros: lowercase n-z (13)
    let [base, min, max] = [109, 1, 13]
  else  " others: lowercase a-m (13)
    let [base, min, max] = [96, 0, 13]
  endif
  let min = a:0 ? a:1 : min  " e.g. set to '0' disables v:count1 for 'm' and 'q'
  let cnt = max([min, cnt])  " use v:count1 for 'm' and 'q'
  let name = cnt == 0 ? '' : nr2char(base + min([cnt, max]))
  let warnings = []
  if cnt > max  " emit warning
    let head = "Count '" . cnt . "' too high for translation."
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
  return [name, empty(warnings) ? string(cnt) : '']
endfunction
" Translate into map command
function! utils#translate_count(mode, ...) abort
  let default = a:0 > 0 ? a:1 : ''
  let double = a:0 > 1 ? a:2 : ''
  let char = ''
  if empty(default) && empty(double)
    let [name, label] = s:translate_count(a:mode)
    if a:mode =~# '[m`q@]'  " marks/macros
      let cmd = name
    else  " yanks/changes/deletes/pastes
      let cmd = empty(name) ? '' : '"' . name
    endif
  else
    let [name, label] = s:translate_count(a:mode, 0)
    if empty(name)  " ''/\"\"/'<motion>/\"<motion>
      let char = nr2char(getchar())
      let name = char =~# "['\"]" ? repeat('"', double) : default . char
      let label = name ==# '_' ? 'blackhole' : name[0] =~# '[+*]' ? 'clipboard' : ''
    endif
    let cmd = '"' . name
  endif
  if !empty(name) && !empty(label)
    let head = a:mode =~# '[m`]' ? 'Mark' : 'Register'
    echom head . ': ' . name[0] . ' (' . label . ')'
  endif
  return cmd
endfunction
