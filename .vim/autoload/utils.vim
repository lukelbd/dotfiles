"-----------------------------------------------------------------------------"
" Internal utilities
"-----------------------------------------------------------------------------"
" Null completion function
function! utils#null_complete(...) abort
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
" For conditoinal CursorHold operations
function! utils#none_pending() abort
  return v:register ==# '"' && v:count == 0 && mode(1) !~# '^no'
endfunction

" Catch errors while running tests or events while calling peekaboo
" NOTE: This prevents 'press enter to continue' error messages e.g. when
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
" NOTE: This is used to override fzf marks commands and support jumping to existing
" tabs, and to overide jumplist and changelist command for various new settings.
function! utils#get_scripts(arg, ...) abort
  let opts = type(a:arg) ? {'name': a:arg} : {'sid': a:arg}
  let items = []  " no dictionary because confusing
  for info in getscriptinfo(opts)
    let item = a:0 && a:1 ? info.sid : exists('*RelativePath') ? RelativePath(info.name) : info.name
    call add(items, item)
  endfor
  return items
endfunction
function! utils#get_snr(regex, ...) abort
  silent! call fzf#vim#with_preview()  " trigger autoload if not already done
  let sids = utils#get_scripts(a:regex, 1)
  if len(sids) > 0  " return latest script
    return "\<snr>" . sids[-1] . '_'
  elseif a:0 && a:1  " optionally suppress warning
    return ''
  else  " emit warning
    echohl WarningMsg
    echom "Warning: Autoload script '" . a:regex . "' not found."
    echohl None | return ''
  endif
endfunction

" Get user input with requested default
" WARNING: For some reason [''] required instead of [''] after pressing backspace
" or else subsequent tab-completion requests do nothing. Not sure why.
" NOTE: Force option forces return after single key press (used for registers). Try
" to feed the result with feedkeys() instead of adding to opts to reduce screen flash.
" NOTE: This is currently used with grep and file mappings. Specifies a default value
" in parentheses that can be tab expanded, selects it when user presses enter, or
" replaces it when user starts typing text or backspace. This is a bit nicer than
" filling input prompt with default value, simply start typing to drop the default
function! utils#input_default(prompt, ...) abort
  let default = a:0 ? a:1 : ''
  let paren = a:prompt =~# ')$' || empty(default) ? '' : ' (' . default . ')'
  let prompt = a:prompt . paren . ': '
  let s:complete_opts = [1] + a:000
  call feedkeys("\<Tab>", 't')  " auto-complete getchar() results
  return input(prompt, '', 'customlist,utils#input_complete')
endfunction
function! utils#input_complete(lead, line, cursor) abort
  let [initial, default; rest] = s:complete_opts
  let force = len(rest) > 1 ? rest[1] : 0
  if !initial  " get complete options
    if empty(rest) || empty(rest[0])
      let opts = []
    elseif type(rest[0]) == 1 && rest[0] =~# '^[a-z_]\+$'
      let opts = getcompletion(a:lead, rest[0])
    else
      let opts = call(rest[0], [a:lead, a:line, a:cursor])
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
" NOTE: Vim help recommends capturing full map settings using maparg(lhs, 'n', 0, 1)
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
    let msg = 'Warning: Could not find source maps ' . join(map(fails, 'string(v:val)'), ', ')
    redraw | echohl WarningMsg | echom msg | echohl None | return 1
  endif
endfunction

" Call function with range supplied by motion
" WARNING: Plugin text objects may be single-line linewise so avoid check below
" NOTE: Only motions can cause backwards firstline to lastline order. Manual calls
" to the function will have sorted lines. This wrapper sorts the range for safety
" NOTE: Calling :[range]call call(...) for functions declared without range flag
" executes line-by-line instead of entire block. Prefer :[range]call function(args)
" usage instead of input arguments so ranges can be passed with V<motion>.
function! utils#motion_func(name, args, ...) abort
  let signature = string(a:args)[1:-2]  " remove square brackets
  let operator = a:name . '(' . signature . ')'
  let s:operator_func = operator
  let s:operator_view = a:0 && a:1 ? winsaveview() : {}
  let s:operator_view['bufnr'] = bufnr()
  if mode() =~# '^\(v\|V\|\)$'  " call operator function with current line range
    return ":call utils#operator_func('')\<CR>"
  elseif mode() ==# 'n'  " await motion and call operator function over those lines
    set operatorfunc=utils#operator_func
    return "\<Esc>g@"
  else  " fallback
    echoerr 'E999: Illegal mode: ' . string(mode())
    return "\<Esc>"
  endif
endfunction
function! utils#operator_func(type, ...) range abort
  if empty(a:type)  " default behavior
    let nums = [a:firstline, a:lastline]
    let locs = ["'<", "'>"]
  elseif a:type =~? 'line\|char\|block'  " builtin g@ type strings
    let nums = [line("'["), line("']")]
    let locs = ["'[", "']"]
  else  " fallback
    echoerr 'E474: Invalid argument: ' . string(a:type)
    return ''
  endif
  let [line1, line2] = sort(nums, 'n')
  let [col1, col2] = map(copy(locs), 'col(v:val)')
  if a:type !=# 'line' && line1 == line2 && col1 >= col2  " keep single-line hunks
    return ''
  endif
  let view = s:operator_view.bufnr ==# bufnr() ? s:operator_view : {}
  exe line1 . ',' . line2 . 'call ' . s:operator_func
  call winrestview(view) | return ''
endfunction

" Convert ranges to arguments and jump to next match
" NOTE: This is generally invoked inside an <expr> mapping (see e.g. python.vim).
" NOTE: Here utils#range_func() converts command ranges to input arguments and
" converts zeros to the full range. Used with git#get_hunks() and edit#get_errors()
function! utils#next_func(count, ...) abort
  for _ in range(abs(a:count))
    let [lnum0, lnum] = [-1, line('.')]
    let [fnum0, fnum] = [lnum, lnum]
    while lnum0 != lnum && fnum0 > 0 && fnum == fnum0
      let lnum0 = line('.')
      let fnum0 = foldclosed('.')
      for cmd in a:000 | call call(cmd, []) | endfor
      let lnum = line('.')
      let fnum = foldclosed('.')
    endwhile
  endfor
endfunction
function! utils#range_func(name, args, ...) abort range
  let [range1, range2] = a:0 ? a:1 : [a:firstline, a:lastline]
  let [arg1, arg2] = [get(a:args, 0, -1), get(a:args, 1, -1)]
  let line1 = arg1 > 0 ? arg1 : arg1 == 0 ? 1 : range1
  let line2 = arg2 >= 0 ? arg2 > 0 ? arg2 : line('$') : range2
  let fold1 = foldclosed(line1)
  let fold2 = foldclosedend(line2)
  let span1 = fold1 > 0 ? fold1 : line1
  let span2 = fold2 > 0 ? fold2 : line2
  let spans = sort([span1, span2], 'n')
  return call(a:name, spans + a:args[2:])
endfunction

" Generate repeatable mappings for arbitrary modes
" WARNING: Normal mode commands issued from right-hand-side functions can reset count,
" so v:prevcount could be e.g. line number if 'G' was called. Careful to avoid this
" NOTE: This supports arbitrary operator-pending modifications, e.g. text changes
" that prompt for user input, like vim-tags utility. Should try more ideas
" NOTE: GUI vim raises error when combining <Plug> maps with <Cmd> so have to disable
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
  let setup = "\<Cmd>let g:repeat_count = v:count\<CR>"
  let repeat = empty(icmd) ? '' : icmd . 'call repeat#set(' . iset . ')<CR>'
  if empty(a:name)  " disable repetition (e.g. require user input)
    exe noremap . ' ' . a:lhs . ' ' . a:rhs . repeat
  else | exe map . ' ' . a:lhs . ' <Plug>' . a:name
    exe noremap . ' <Plug>' . a:name . ' ' . a:rhs . repeat
    exe noremap . ' <Plug>Repeat' . a:name . ' ' . a:rhs
  endif
endfunction
