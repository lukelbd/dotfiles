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
function! utils#input_default(prompt, ...) abort
  let complete = a:0 > 1 ? a:2 : ''
  let default = a:0 > 0 ? a:1 : ''
  let paren = a:prompt =~# ')$' || empty(default) ? '' : ' (' . default . ')'
  let prompt = a:prompt . paren . ': '
  let s:complete_opts = [1, default, complete] + a:000[2:]
  call feedkeys("\<Tab>", 't')  " auto-complete getchar() results
  return input(prompt, '', 'customlist,utils#input_complete')
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

" Switch buffer-local panel mappings
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
function! utils#switch_maps(...) abort
  let queue = {}  " delay assignment until iteration
  for [map1, map2, imodes; iopts] in a:000
    for imode in imodes  " string or list of chars
      let raw = eval('"' . substitute(map2, '^<', '\\<', '') . '"')
      let item = maparg(map1, imode, 0, 1)
      let items = get(queue, imode, [])
      call extend(item, {'rhs': s:eval_map(item), 'lhs': map2, 'lhsraw': raw})
      call extend(item, empty(iopts) ? {} : iopts[0])
      call add(items, item)
      let queue[imode] = items
    endfor
  endfor
  for [imode, items] in items(queue)
    for item in items
      call mapset(imode, 0, item)
    endfor
  endfor
endfunction

" Set register and rotate out other options
" Note: This auto-cycles previous register contents if input count was empty, either
" immediately for macros or delaying until TextYankPost i.e. delete or yank finished.
" Note: Vim by default sends multi-line deletes/changes to @1 through @9, 'small'
" deletes/changes to @-, and all yanks to @0. Here use numbers for all multi-line
" changes, letters for single-line changes, and zero for excluding yanks.
function! s:set_register(text, opts, reg, ...) abort
  let rmin = type(a:reg) ? a:reg : nr2char(a:reg)
  let rmax = a:0 ? type(a:1) ? a:1 : nr2char(a:1) : rmin
  let [nmin, nmax] = [char2nr(rmin), char2nr(rmax)]
  for nr in range(nmax, nmin + 1, -1)
    let reg1 = nr2char(nr - 1)  " copy from this register
    let reg2 = nr2char(nr)  " copy to this register
    let text = getreg(reg1)
    let opts = get(getreginfo(reg1), 'regtype', '')
    call setreg(reg2, text, opts)
  endfor
  call setreg(rmin, a:text, a:opts)
  call setreg('"', a:text, a:opts)
endfunction
function! utils#rotate_setup() abort
  augroup rotate_registers
    au!
    au BufLeave,CursorHold * autocmd! rotate_registers
    au TextYankPost * call utils#rotate_registers(v:event.operator, v:event.regname) | autocmd! rotate_registers
  augroup END
endfunction
function! utils#rotate_registers(mode, ...) abort
  if a:0 && a:1 !~# '^"\?$' | return | endif
  let text = getreg('')  " string contents
  let info = getreginfo('')  " empty if unset
  let opts = get(info, 'regtype', '')  " see :help getreginfo
  let dest = get(info, 'points_to', '')
  let [nr1, nr2, _] = s:translate_chars(a:mode)
  if !count(text, "\n")  " never points to 1
    call s:set_register(text, opts, nr1, nr2)  " see below
  elseif dest ==# '0'  " multi-line yank
    call s:set_register(text, opts, '1', '9')
  elseif dest ==# '1'  " multi-line delete/change
    call s:set_register(text, opts, '0')
  endif
endfunction

" Return the register based on input count
" Note: This translates counts passed to yanks/change/delete/paste to first
" 20 letters of alphabet, counts passed to macro records/plays to next 6 letters of
" alphabet, and counts passed to mark sets/jumps to first 24 letters of alphabet.
function! s:translate_stack(mode) abort
  let offset = a:mode ==# 'm' ? 1 : 0  " offset
  let stack = get(g:, 'mark_stack', [])  " recent mark stack
  let base = char2nr('A')  " default mark
  let mrk1 = nr2char(base - offset)  " previous mark
  let mrk2 = char2nr(get(stack, -1, mrk1))
  let cnt = mrk2 - base + 1
  return cnt + offset
endfunction
function! s:translate_chars(mode, ...) abort
  if a:mode =~# '[m`]'  " marks: uppercase a-z (64+1-64+26)
    let [char1, char2] = [char2nr('A'), char2nr('Z')]
  elseif a:mode =~# '[q@]'  " macros: lowercase u-z (96+21-96+26)
    let [char1, char2] = [char2nr('u'), char2nr('z')]
  else  " registers: lowercase a-t (96+1-96+20)
    let [char1, char2] = [char2nr('a'), char2nr('t')]
  endif
  return [char1, char2, char2 - char1 + 1]
endfunction
function! s:translate_count(mode, ...) abort
  let zero = a:0 && !empty(a:1)
  if v:count  " user-input count
    let cnt = v:count
  elseif !zero && a:mode =~# '[m`]'  " translate count
    let cnt = s:translate_stack(a:mode)
  elseif !zero && a:mode =~# '[q@]'  " enforce count
    let cnt = 1 | call utils#rotate_registers(a:mode)
  else  " allow empty count
    let cnt = 0 | call utils#rotate_setup()
  endif
  let [nr1, nr2, cmax] = s:translate_chars(a:mode)
  let [cnt, msg] = [min([cnt, cmax]), '']  " truncate user-input count
  let name = cnt ? nr2char(min([nr1 + cnt - 1, nr2])) : ''
  if v:count > cmax  " emit warning
    let msg .= ' Truncating count ' . v:count . ' to ' . string(name) . ' (count ' . cmax . ')'
  endif
  if a:mode ==# 'm' && index(map(getmarklist(), 'v:val.mark'), "'" . name) != -1
    let msg .= ' Overwriting mark ' . string(name) . ' (count ' . cnt . ')'
  endif
  if !empty(msg)  " warning messages
    echohl WarningMsg | echom 'Warning: ' . trim(msg) | echohl None
  endif
  return [name, cnt && empty(msg) ? 'count ' . cnt : '']
endfunction
function! utils#translate_count(mode, ...) abort
  if a:mode !~# '[m`]' && v:register !=# '"' | return '' | endif
  let [name, label] = s:translate_count(a:mode, a:0 ? a:1 : 0)
  if a:0 && empty(name)  " no count so request additional character
    let char = utils#input_default('Register', '', '', 1)
    if char =~# '^[''"]$'  " select vim register name
      let name = utils#input_default('Register (vim)', '', '', 1)
    elseif char =~# '^\d$'  " select number register
      let name = char
    else  " pass default to operator
      let name = char =~? '^[dcyp]$' ? a:1 : '' | call feedkeys(char, 'm')
    endif
    if name ==# '_'
      let label = 'blackhole'
    elseif name =~# '[+*]'
      let label = 'clipboard'
    elseif name =~# '\d'  " use character to pick number register
      let label = name . get({'1': 'st', '2': 'nd', '3': 'rd'}, name, 'th') . ' delete'
    else  " default label
      let label = ''
    endif
  endif
  if !empty(name) && !empty(label)  " mark name label
    let head = a:mode =~# '[m`]' ? 'Mark' : 'Register'
    echom head . ': ' . name[0] . ' (' . label . ')'
  endif
  let head = v:count ? "\<Esc>" : ''
  if a:0 || a:mode !~# '[m`q@]'
    let head .= '"'
  elseif !a:0 && a:mode =~# '[q@]'
    let head .= a:mode
  endif
  return head . name
endfunction
