"-----------------------------------------------------------------------------"
" Internal utilities
"-----------------------------------------------------------------------------"
" Null input() completion function (not currently used)
function! utils#null_list(...) abort
  return []
endfunction
" Null operator motion function (default Z mapping)
function! utils#null_operator(...) range abort
  return ''
endfunction
" For <expr> mapping accepting motion
function! utils#null_operator_expr(...) abort
  return utils#motion_func('utils#null_operator', a:000)
endfunction

" Safely run tests without verbose error message
" Todo: Add to this, should have custom testing features and maps.
" Note: This prevents 'press enter to continue' error messages e.g. when
" accidentally hitting test maps in filetypes without utilities installed.
function! utils#catch_errors(...) abort
  try
    exe join(a:000, ' ')
    return 0
  catch /E492/
    let msg = substitute(v:exception, '\w\+:E\d\+:', '', '')
    echohl ErrorMsg
    echom 'Error:' . msg
    echohl None | return 1
  endtry
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

" Get user input with requested default
" Note: Force option forces return after single key press (used for registers). Try
" to feed the result with feedkeys() instead of adding to opts to reduce screen flash.
" Note: This is currently used with grep and file mappings. Specifies a default value
" in parentheses that can be tab expanded, selects it when user presses enter, or
" replaces it when user starts typing text or backspace. This is a bit nicer than
" filling input prompt with default value, simply start typing to drop the default
function! utils#input_list(lead, line, cursor)
  let [initial, default, complete; force] = s:complete_opts
  let force = !empty(force) && force[0]
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
    catch  " e.g. user presses Ctrl-C
      let char = "\<C-c>"
    endtry
    if char ==# "\<Esc>"  " cancellation
      let opts = []
      call feedkeys("\<CR>", 't')
    elseif char ==# "\<CR>"  " confirm default
      let opts = []
      call feedkeys(default ."\<CR>", 't')
    elseif char ==# "\<Tab>"  " expand default
      let opts = force ? [] : [default]
      call feedkeys(force ? default . "\<CR>" : '', 't')
    elseif char ==# "\<PasteStart>"  " clipboard paste
      let opts = [] | call feedkeys(char, 'it')
      call feedkeys(force ? "\<CR>" : '', 't')
    elseif char !~# '^\p\+$'  " non-printables and multi-byte escpaes e.g. \<BS>
      let opts = force ? [] : []
      call feedkeys(force ? "\<CR>" : '', 't')
    else  " printable input characters
      let opts = force ? [] : [char]
      call feedkeys(force ? char . "\<CR>" : '', 't')
    endif
  endif
  return opts
endfunction
function! utils#input_default(prompt, ...) abort
  let complete = a:0 > 1 ? a:2 : ''
  let default = a:0 > 0 ? a:1 : ''
  let result = a:prompt
  let result .= empty(default) ? '' : ' (' . default . ')'
  let result .= result =~# '\w$\|)$' ? ': ' : ' '
  let s:complete_opts = [1, default, complete] + a:000[2:]
  call feedkeys("\<Tab>", 't')
  return input(result, '', 'customlist,utils#input_list')
endfunction

" Call over the visual line range or user motion line range (see e.g. python.vim)
" Note: :call call(function, args) with range seems to execute line-by-line instead of
" entire block which causes issues with some functions. So use below clunky method.
" Also ensure functions accept :[range]call function(args) for consistency with vim
" standard paradigm and so they can be called with e.g. V<motion>:call func().
function! utils#motion_func(funcname, args) abort
  let string = string(a:args)[1:-2]
  let string = a:funcname . '(' . string . ')'
  let s:operator_func = string
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

" Return commands specifying or demanding a register (e.g. " or peekaboo)
" Note: These functions translate counts passed to yanks/change/delete/paste to first
" 12 letters of alphabet, counts passed to macro records/plays to next 12 letters of
" alphabet, and counts passed to mark sets/jumps to first 24 letters of alphabet.
" Leave letters 'y' and 'z' alone for internal use (currently just used by marks).
function! s:translate_count(mode, ...) abort
  let cnt = v:count
  let name = v:register
  let warnings = []
  if name !=# '"' && a:mode !=# 'm'  " already translated (avoid recursion)
    return [name, '']
  elseif a:mode =~# '[m`]'  " marks: uppercase a-x (64+1-64+24)
    let [base, min, max] = [64, 1, 24]
  elseif a:mode =~# '[q@]'  " macros: lowercase n-z (109+1-109+13)
    let [base, min, max] = [109, 1, 13]
  else  " others: lowercase a-m (96+1-96+13)
    let [base, min, max] = [96, 0, 13]
  endif
  if cnt == 0 && a:mode =~# '[m`]'
    let stack = get(g:, 'mark_recents', [])  " goto most recent and create adjacent
    let prev = empty(stack) ? a:mode ==# 'm' ? '@' : 'A' : stack[-1]  " @ + 1 == A
    let char = a:mode ==# 'm' ? char2nr(prev) + 1 : char2nr(prev)
    let name = nr2char(min([char, base + max]))
  else
    let min = a:0 ? a:1 : min  " e.g. set to '0' disables v:count1 for 'm' and 'q'
    let char = max([min, cnt])  " use v:count1 for 'm' and 'q'
    let char = min([char, max])  " below maximum letter
    let name = char == 0 ? '' : nr2char(base + char)
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
  let label = empty(warnings) ? 'count ' . cnt : ''
  return [name, label]
endfunction
" Translate into map command
function! s:translate_input(mode, ...) abort
  if empty(a:0) || empty(a:1)  " i.e. empty(0) || empty('')
    let char = ''
    let [name, label] = s:translate_count(a:mode)
    if a:mode =~# '[m`q@]'  " marks/macros (register mandatory)
      let result = name
    elseif !empty(name)  " yanks/changes/deletes/pastes
      let result = '"' . name
    else  " default unnamed register
      let result = ''
    endif
  else  " ' or \" register invocation
    let char = ''
    let [name, label] = s:translate_count(a:mode, 0)
    let result = '"' . name
    if empty(name)  " no count preceded ' or \" press
      let char = utils#input_default('Register', '', '', 1)
      if empty(char)  " e.g. escape character
        let name = char
        let result = ''
      elseif char ==# "'"  " native register selection
        let name = utils#input_default('Register (raw)', '', '', 1)
        let result = '"' . name
      elseif char ==# '"'  " native register selection
        let name = ''
        let result = peekaboo#peek(1, '"', 0)
      elseif char =~# '\d'  " use character to pick number register
        let name = char
        let result = '"' . name
      else  " pass character to normal mode (e.g. <Left>, d2j, ciw, yy)
        let name = a:1
        let result = '"' . name . char  " including next character
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
  endif
  let head = a:mode =~# '[m`]' ? 'Mark' : 'Register'
  echom empty(name) || empty(label) ? '': head . ': ' . name[0] . ' (' . label . ')'
  return result
endfunction
" Public function without autocommands
function! utils#translate_name(...) abort
  noautocmd return call('s:translate_input', a:000)
endfunction
