"-----------------------------------------------------------------------------"
" Internal utilities
"-----------------------------------------------------------------------------"
" Null operator motion function (default Z mapping)
function! utils#null_operator(...) range abort
  return ''
endfunction
" For <expr> mapping accepting motion
function! utils#null_operator_expr(...) abort
  return utils#motion_func('utils#null_operator', a:000)
endfunction
" For conditoinal CursorHold operations
function! utils#none_pending() abort
  return v:register ==# '"' && v:count == 0 && mode() !~# '^no'
endfunction

" Catch errors while running tests or events while calling peekaboo
" Note: This prevents 'press enter to continue' error messages e.g. when
" accidentally hitting test maps in filetypes without utilities installed.
function! utils#catch_errors(...) abort
  try
    exe join(a:000, ' ')
    return 0
  catch /E492/
    let msg = substitute(v:exception, '\w\+:E\d\+:', '', '')
    echohl ErrorMsg | echom 'Error:' . msg | echohl None | return 1
  endtry
endfunction
function! utils#catch_events(events, func, ...) abort
  let &l:eventignore = a:events
  try
    let result = call(a:func, a:000)
  catch /.*/
    let &l:eventignore = ''
  endtry
  call timer_start(10, function('execute', ['setlocal eventignore=']))
  return result
endfunction

" Get the fzf.vim/autoload/fzf/vim.vim script id for overriding.
" See: https://stackoverflow.com/a/49447600/4970632
" Note: This is used to override fzf marks commands and support jumping to existing
" tabs, and to overide jumplist and changelist command for various new settings.
function! utils#get_snr(regex, ...) abort
  silent! call fzf#vim#with_preview()  " trigger autoload if not already done
  let [paths, sids] = utils#get_scripts(1)
  let path = filter(copy(paths), 'v:val =~# a:regex')
  let idx = index(paths, get(path, 0, ''))
  if !empty(path) && idx >= 0
    return "\<snr>" . sids[idx] . '_'
  elseif a:0 && a:1  " optionally suppress warning
    return ''
  else  " emit warning
    echohl WarningMsg
    echom "Warning: Autoload script '" . a:regex . "' not found."
    echohl None | return ''
  endif
endfunction
function! utils#get_scripts(...) abort
  let suppress = a:0 > 0 ? a:1 : 0
  let regex = a:0 > 1 ? a:2 : ''
  let [paths, sids] = [[], []]  " no dictionary because confusing
  for path in split(execute('scriptnames'), "\n")
    let sid = substitute(path, '^\s*\(\d*\):.*$', '\1', 'g')
    let path = substitute(path, '^\s*\d*:\s*\(.*\)$', '\1', 'g')
    let path = fnamemodify(resolve(expand(path)), ':p')  " then compare to home
    if !empty(regex) && path !~# regex
      continue
    endif
    call add(paths, path)
    call add(sids, sid)
  endfor
  if !suppress | echom 'Script names: ' . join(paths, ', ') | endif
  return [paths, sids]
endfunction

" Get user input with requested default
" Warning: For some reason [''] required instead of [''] after pressing backspace
" or else subsequent tab-completion requests do nothing. Not sure why.
" Note: Force option forces return after single key press (used for registers). Try
" to feed the result with feedkeys() instead of adding to opts to reduce screen flash.
" Note: This is currently used with grep and file mappings. Specifies a default value
" in parentheses that can be tab expanded, selects it when user presses enter, or
" replaces it when user starts typing text or backspace. This is a bit nicer than
" filling input prompt with default value, simply start typing to drop the default
function! utils#input_default(prompt, ...) abort
  let complete = a:0 > 1 ? a:2 : ''
  let default = a:0 > 0 ? a:1 : ''
  let paren = a:prompt =~# ')$' || empty(default) ? '' : ' (' . default . ')'
  let prompt = a:prompt . paren . ': '
  let s:complete_opts = [1, default, complete] + a:000[2:]
  call feedkeys("\<Tab>", 't')  " auto-complete getchar() results
  return input(prompt, '', 'customlist,utils#input_complete')
endfunction
function! utils#input_complete(lead, line, cursor)
  let [initial, default, complete; rest] = s:complete_opts
  let force = get(rest, 0, 0)
  if !initial  " get complete options
    if empty(complete)
      let opts = []
    elseif complete =~# '^[a-z_]\+$'
      let opts = getcompletion(a:lead, complete)
    else
      let opts = call(complete, [a:lead, a:line, a:cursor])
    endif
  else  " initial iteration
    let s:complete_opts[0] = 0
    try  " getchar() returns strings for escape sequences and numbers otherwise
      let char = getcharstr()
    catch /^Vim:Interrupt$/  " e.g. user presses Ctrl-C
      let char = "\<C-c>"
    endtry
    if char ==# "\<Esc>" || char ==# "\<C-c>"  " cancellation
      let opts = ['']
      call feedkeys("\<CR>", 'nt')
    elseif char ==# "\<CR>"  " confirm default
      let opts = ['']
      call feedkeys(default . "\<CR>", 'nt')
    elseif char ==# "\<Tab>" || char ==# "\<F2>"  " expand default
      let opts = force ? [''] : [default]
      call feedkeys(force ? default . "\<CR>" : '', 'nt')
    elseif char ==# "\<PasteStart>"  " clipboard paste
      let opts = [''] | call feedkeys(char, 'int')
      call feedkeys(force ? "\<CR>" : '', 'nt')
    elseif char !~# '^\p\+$'  " non-printables and multi-byte escapes e.g. \<BS>
      let opts = force ? [char] : ['']
      call feedkeys(force ? "\<CR>" : '', 'int')
    else  " printable input characters
      let opts = force ? [''] : [char]
      call feedkeys(force ? char . "\<CR>" : '', 'nt')
    endif
  endif
  return opts
endfunction

" Add mappings from other buffer-local mappings
" Note: Vim help recommends capturing full map settings using maparg(lhs, 'n', 0, 1)
" then re-adding using mapset(). This is a little easier than working with strings
" returned by maparg(lhs, 'n') which requires using escape(map, '"<') then evaluating
" the resulting string with eval('"' . map . '"'). However in the dictionary case, the
" 'rhs' entry uses <sid> instead of <snr>nr, and when calling mapset(), the *current
" script* id is used rather than the id in the dict. Have to fix this manually.
function! s:eval_map(map) abort
  let rhs = get(a:map, 'rhs', '')
  let sid = get(a:map, 'sid', '')  " see above
  let snr = '<snr>' . sid . '_'
  let rhs = substitute(rhs, '\c<sid>', snr, 'g')
  return rhs
endfunction
function! utils#map_from(...) abort
  let fails = []
  let queue = {}  " delay assignment until iteration
  for [imodes, ilhs, isrc; iopts] in a:000
    let iopt = get(iopts, 0, '')
    let iadd = type(iopt) > 1 ? '' : iopt
    for imode in imodes  " string or list of chars
      let item = maparg(isrc, imode, 0, 1)
      if !get(item, 'buffer', 0)  " ignore global maps
        call add(fails, imode . ':' . isrc) | continue
      endif
      let irhs = s:eval_map(item) . iadd
      let iraw = eval('"' . substitute(ilhs, '^<', '\\<', '') . '"')
      call extend(item, {'lhs': ilhs, 'lhsraw': iraw, 'rhs': irhs})
      call extend(item, type(iopt) > 1 ? copy(iopt) : {})
      let items = get(queue, imode, [])
      let queue[imode] = add(items, item)
    endfor
  endfor
  for [imode, items] in items(queue)
    for item in items
      call mapset(imode, 0, item)
    endfor
  endfor
  if !empty(fails)
    redraw | echohl WarningMsg
    echom 'Warning: Could not find source maps ' . join(map(fails, 'string(v:val)'), ', ')
    echohl None | return 1
  endif
endfunction

" Call over the visual line range or user motion line range (see e.g. python.vim)
" Note: :call call(function, args) with range seems to execute line-by-line instead of
" entire block which causes issues with some functions. So use below clunky method.
" Also ensure functions accept :[range]call function(args) for consistency with vim
" standard paradigm and so they can be called with e.g. V<motion>:call func().
function! utils#motion_func(funcname, args, ...) abort
  let string = string(a:args)[1:-2]  " remove square brackets
  let string = a:funcname . '(' . string . ')'
  let s:operator_view = a:0 && a:1 ? winsaveview() : {}
  let s:operator_func = string
  if mode() =~# '^\(v\|V\|\)$'  " call operator function with line range
    return ":call utils#operator_func('')\<CR>"
  elseif mode() ==# 'n'
    set operatorfunc=utils#operator_func
    return "\<Esc>g@"  " await user motion and call operator function over those lines
  else
    echoerr 'E999: Illegal mode: ' . string(mode())
    return "\<Esc>"
  endif
endfunction

" Execute the function name and call signature passed to utils#motion_func.
" This is generally invoked inside an <expr> mapping (see e.g. python.vim) .
" Note: Only motions can cause backwards firstline to lastline order. Manual calls
" to the function will have sorted lines. This sorts the range for safety.
function! utils#operator_func(type, ...) range abort
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
  call winrestview(s:operator_view)
  return ''
endfunction

" Generate repeatable mappings for arbitrary modes
" Note: This supports arbitrary operator-pending modifications, e.g. text changes
" that prompt for user input, like vim-tags utility. Should try more ideas
" Note: GUI vim raises error when combining <Plug> maps with <Cmd> so have to disable
" repeat for operator-pending maps e.g. 'cgw' in case they trigger insert mode.
function! utils#repeat_op(name, ...) abort
  let feed = '"\<Esc>\<Cmd>let g:repeat_tick = b:changedtick\<CR>"'
  let keys = v:operator . (a:0 && a:1 ? a:1 : 1) . "\<Plug>Repeat" . a:name
  if v:operator ==# 'c'  " e.g. change
    return keys . "\<Cmd>call feedkeys(getreg('.') . " . feed . ", 'n')\<CR>"
  else  " e.g. delete
    return keys . "\<Cmd>call feedkeys(" . feed . ", 'n')\<CR>"
  endif
endfunction
function! utils#repeat_map(mode, lhs, name, rhs) abort
  let [map, noremap] = [a:mode . 'map', a:mode . 'noremap <silent>']
  let icmd = has('gui_running') ? a:mode ==? 'o' ? '' : ':<C-u>' : '<Cmd>'
  let mrep = '"\<Plug>' . a:name . '", v:prevcount'
  let orep = 'utils#repeat_op(' . string(a:name) . ', v:prevcount)'
  let iset = empty(a:name) ? '"\<Ignore>"' : a:mode ==# 'o' ? orep : mrep
  let repeat = empty(icmd) ? '' : icmd . 'call repeat#set(' . iset . ')<CR>'
  if empty(a:name)  " disable repetition (e.g. require user input)
    exe noremap . ' ' . a:lhs . ' ' . a:rhs . repeat
  else | exe map . ' ' . a:lhs . ' <Plug>' . a:name
    exe noremap . ' <Plug>' . a:name . ' ' . a:rhs . repeat
    exe noremap . ' <Plug>Repeat' . a:name . ' ' . a:rhs
  endif
endfunction

" Helper translation functions
" Note: Here default mark is top of stack (plus one if recording), default macro
" recording register is zero (move to one if non-empty), default macro execution
" register is one (recent successful recording), and default register is unnamed.
" Note: This translates counts passed to yanks/change/delete/paste to first
" 20 letters of alphabet, counts passed to macro records/plays to next 6 letters of
" alphabet, and counts passed to mark sets/jumps to first 24 letters of alphabet.
function! s:default_mark(mode) abort
  let offset = a:mode ==# 'm' ? 1 : 0  " offset
  let stack = get(g:, 'mark_stack', [])  " recent mark stack
  let base = char2nr('A')  " default mark
  let init = nr2char(base - offset)  " initial value
  let cnum = char2nr(get(stack, -1, init))
  return nr2char(cnum + offset)
endfunction
function! s:translate_count(mode, count) abort
  if a:mode =~# '[m`]'  " marks: uppercase a-z (64+1-64+26)
    let [default, name1, name2] = [s:default_mark(a:mode), 'A', 'Z']
  elseif a:mode =~# '[q@]'  " macros: lowercase q-z (96+17-96+26)
    let [default, name1, name2] = [a:mode ==# 'q' ? '0' : '1', '1', '9']
  else  " registers: lowercase a-p (96+1-96+16)
    let [default, name1, name2] = ['"', 'a', 'z']
  endif
  let cmax = char2nr(name2) - char2nr(name1) + 1  " register range
  let cnum = char2nr(name1) + min([a:count, cmax]) - 1
  let name = a:count > 0 ? nr2char(cnum) : default
  return [name, name1, name2, cmax]
endfunction

" Set register and rotate other entries forward
" Note: This auto-cycles previous register contents if input count was empty, either
" immediately for macros or delaying until TextYankPost i.e. delete or yank finished.
" Note: This radically overrides native register system by using numbered registers
" 1 through 9 for macros (0 while recording, assigned conditionally if non-empty) and
" letter registers for deletes and yanks. Also tried using -/+ for most recent v/V
" deletions but + is locked to * on mac and - cannot be assigned regtype V so ignore.
function! utils#set_register(info, dest, ...) abort
  let dest1 = type(a:dest) ? a:dest : nr2char(a:dest)
  let dest2 = a:0 ? type(a:1) ? a:1 : nr2char(a:1) : dest1
  for char in range(char2nr(dest2), char2nr(dest1) + 1, -1)
    let prev = getreginfo(nr2char(char - 1))
    let prev.isunnamed = v:false
    call setreg(nr2char(char), prev)
  endfor | call setreg(dest1, a:info)  " changes unnamed if isunnamed=v:true
endfunction
function! utils#set_translate(name, mode) abort
  let [_, name1, name2, _] = s:translate_count(a:mode, 0)
  let info = getreginfo(a:name)  " information
  let info.isunnamed = a:mode =~# '[q@m`]' ? v:false : v:true
  if has_key(info, 'points_to') | call remove(info, 'points_to') | endif
  if a:name ==# '"' || a:name ==# '0'
    if a:name ==# '0' && a:mode ==# 'q' && getreg(a:name) !~# '\p\|\t'
      echom 'Cancelled macro' | return a:name
    elseif a:name !=# '0' || a:mode ==# 'q'  " push 0 for recordings only
      call utils#set_register(info, name1, name2)
    endif
  endif
  if a:mode ==# 'q' | echom 'Finished macro' | endif | return name1
endfunction
function! utils#setup_registers() abort
  let b:registers = {}
  let regs = map(range(0, 9), 'string(v:val)')
  for name in regs  " restore macros
    let info = getreginfo(name)
    let info.isunnamed = v:false
    let b:registers[name] = info
  endfor
  let restore = "call map(get(b:, 'registers', {}), 'setreg(v:key, v:val)')"
  let rotate = 'call utils#set_translate(v:event.regname, v:event.operator)'
  let reset = 'unlet! b:registers | autocmd! registers_' . bufnr()
  exe 'augroup registers_' . bufnr() | exe 'au!'
  exe 'au TextYankPost <buffer> ' . rotate . ' | ' restore . ' | ' . reset
  exe 'au CursorHold <buffer> if utils#none_pending() | ' . restore . ' | ' . reset . ' | endif'
  exe 'augroup END'
endfunction

" Return the name or register translated from input arguments
" Note: This supports e.g. pasting macro keys with e.g. 1"p then quickly editing them
" and copying back into macro register with e.g. 1"dil. Also rotates yanks, changes,
" and deletions across a-z registers and macros across 1-9 registers (see above)
function! s:get_label(name) abort
  let label = ''  " default label
  if a:name ==# '_'
    let label = 'blackhole'
  elseif a:name =~# '[+*]'
    let label = 'clipboard'
  elseif a:name =~# '\d'  " use character to pick number register
    let label = getreg(a:name)
  elseif v:count
    let label = v:count ? 'count ' . v:count : ''
  endif
  return label
endfunction
function! s:get_input(mode, name) abort
  let char = utils#input_default('Register', '', '', 1)
  if char =~? '^[dcyp]$'  " default register
    call feedkeys(char, 'm') | return a:name
  endif
  if char =~# '^[''"]$'  " select vim register name
    let char = utils#input_default('Register (native)', '', '', 1)
  endif
  if len(char) != 1 || char !~? '\p\|\t'
    call feedkeys(char, 'm') | return ''
  elseif char =~# '^\d$'  " select macro number register
    return s:translate_count(a:mode, str2nr(char))[0]
  else
    return char
  endif
endfunction
function! utils#translate_count(mode, ...) abort
  if v:register !=# '"' | return '' | endif  " avoid recursion
  let [name, _, _, cmax] = s:translate_count(a:mode, v:count)
  let name = !a:0 || v:count ? name : s:get_input(a:mode, a:1)
  redraw | if empty(name)  " clear message
    echo '' | return ''
  elseif !v:count && a:mode !~# '[m`q@]'
    call utils#setup_registers()  " queue register changes
  endif
  let label = s:get_label(name)
  let group = a:mode =~# '[m`]' ? 'Mark' : name =~# '^\d$' ? 'Macro' : 'Register'
  let warn = '' | if v:count > cmax  " emit warning
    let warn .= ' Truncating count ' . v:count . ' to ' . string(name) . ' (count ' . cmax . ')'
  endif
  if a:mode ==# 'm' && index(map(getmarklist(), 'v:val.mark'), "'" . name) != -1
    let warn .= ' Overwriting mark ' . string(name) . ' (count ' . v:count . ')'
  endif
  if !empty(warn)
    echohl WarningMsg | echom 'Warning: ' . trim(warn) | echohl None
  elseif name !=# '"'  " show register
    echom group . ': ' . name[0] . (empty(label) ? '' : ' (' . label . ')')
  endif
  if !a:0 && a:mode =~# '[q@]'
    let name = a:mode . name  " e.g. q1 @1
  elseif a:0 || a:mode !~# '[q@m`]'
    let name = '"' . name
  endif
  return v:count && mode() ==# 'n' ? "\<Esc>" . name : name
endfunction
