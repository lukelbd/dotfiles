"-----------------------------------------------------------------------------"
" Utilities for python files
"-----------------------------------------------------------------------------"
" Helper functions for SimPylFold
" NOTE: Cache is generated only on autocommands and with fold#update_folds(). Then
" modify with python#fold_expr to impose e.g. docstring and multi-line lsit folds.
scriptencoding utf-8
function! s:get_isdef(lnum) abort
  let opts = get(get(b:, 'SimpylFold_cache', []), a:lnum, {})
  if has_key(opts, 'is_def')
    let isdef = opts.is_def
  else  " manual detection (slower)
    let isdef = getline(a:lnum) =~# '^\s\+\%(class\|def\)\>'
  endif
  return isdef
endfunction
function! s:get_indent(lnum) abort
  let opts = get(get(b:, 'SimpylFold_cache', []), a:lnum, {})
  if has_key(opts, 'indent')
    let indent = opts.indent
  else  " manual detection (slower)
    let indent = strdisplaywidth(matchstr(getline(a:lnum), '^\s*')) / shiftwidth()
  endif
  return indent
endfunction
function! s:get_level(lnum) abort
  let opts = get(get(b:, 'SimpylFold_cache', []), a:lnum, {})
  if !empty(opts)
    let expr = get(opts, 'foldexpr', 0)
  else  " manual detection (possibly outdated)
    let expr = foldlevel(a:lnum)
  endif
  return !empty(expr) ? type(expr) ? len(expr) > 1 ? expr[1] : expr[0] : expr : 0
endfunction

" Parse python module abbreviations
" TODO: Use below regexes to generate suggestion lists based on file text. Should
" iterate over file lines then suggest any <import>.method matches found for all
" imports names. Could also combine <variable>.method with every possible prefix.
function! python#doc_alias(item) abort
  if &l:filetype !=# 'python' | return a:item | endif
  let winview = winsaveview()
  let parts = split(a:item, '\.', 1)
  let module = parts[0]
  let regex = '\(\k\|\.\)\+'
  if search('import\s\+' . regex . '\s\+as\s\+' . module, 'w')
    let name = matchlist(getline('.'), 'import\s\+\(' . regex . '\)\s\+as')[1]
    if !empty(name) | let module = name | endif
  endif
  if search('from\s\+' . regex . '\s\+import\s\+(\?\(' . regex . '\(,\s*\n*\s*\)\?\)*' . module)
    let package = matchlist(getline('.'), 'from\s\+\(' . regex . '\)\s\+import')[1]
    if !empty(package) | let module = package . '.' . module | endif
  endif
  let parts[0] = module
  call winrestview(winview)
  return join(parts, '.')
endfunction

" Return possible documentation options
" NOTE: This includes e.g. function name under cursor as method following b:doc_name
" or appending to package or header detected from top of file.
function! python#doc_names(...) abort
  let line = getline('.')  " current line
  let current = get(b:, 'doc_name', '')  " see shell.vim
  if a:0 || empty(current) && &l:filetype !=# 'python'
    let item = a:0 ? a:1 : ''
  else  " not in pydoc page or python file
    let head = matchstr(line[:col('.') - 1], '\h\(\w\|\.\)*$')
    let tail = matchstr(line[col('.'):], '^\w*')
    let item = head . tail
  endif
  let item = empty(item) ? get(s:, 'doc_prev', '') : item
  let item = python#doc_alias(item)
  let header = matchstr(getline(1), '\s\+\zs\h\(\w\|\.\)*\ze:$')
  let package = matchstr(getline(1), '\s\+\zs\h\w*\ze\(\.\h\w*\)*:$')
  let opts = [current . '.' . item]  " e.g. xr.DataArray.method
  if !empty(header) | call add(opts, header . '.' . item) | endif  " e.g. pandas.read_csv
  if !empty(package) | call add(opts, package . '.' . item) | endif
  call add(opts, item) | return uniq(opts)  " fallback to full name
endfunction

" Browse documentation with man-style pydoc pages
" NOTE: This is still useful over Lsp e.g. for generalized help page browsing. And
" everything is standardized to man-format so has consistency with man utilities.
function! python#doc_page(...) abort
  let opts = python#doc_names()  " item under cursor
  if !a:0  " user input page
    let page = utils#input_default('Doc page', opts[-1], 'python#doc_pages')
  else  " navigation page
    let page = empty(a:1) ? opts[-1] : a:1
  endif
  if empty(page) | return 1 | endif
  let page = python#doc_alias(page)
  let opts = python#doc_names(page)
  let result = []  " default result
  if !bufexists(page)   " WARNING: only matches exact string
    for iopt in opts
      let result = systemlist('pydoc ' . shellescape(iopt))
      let result = map(result, {idx, val -> substitute(val, '^\( \{4}\)* |  ', '\1', 'ge')})
      if len(result) >= 5 | let page = iopt | break | endif
    endfor
    if len(result) < 5
      let msg = 'Error: Doc page not found: '  " add options (avoid push_stack silent)
      let msg .= join(map(opts, {idx, val -> string(val)}), ', ')
      redraw | echohl ErrorMsg | unsilent echom msg | echohl None | return 1
    endif
  endif
  let exists = bufexists(page)
  let s:doc_prev = page  " previously browsed
  let [bnr, pnr] = [bufnr(), bufnr(page)]  " WARNING: only matches start of string
  if !empty(get(b:, 'doc_name', ''))  " existing path shell.vim
    silent exe exists ? pnr . 'buffer' : 'enew | file ' . page
  else
    silent exe exists ? 'tabedit | ' . pnr . 'buffer' : 'tabedit ' . page
  endif
  if !exists | call append(0, result) | goto | endif | let b:doc_name = page
  setlocal norelativenumber nonumber nobuflisted bufhidden=hide buftype=nofile filetype=man
endfunction
function! python#doc_pages(...) abort
  let cmd = 'pip list --no-color --no-input --no-python-version-warning'
  let pages = systemlist(cmd)
  let pages = map(pages[2:], 'substitute(v:val, ''\s\+.*$'', '''', ''g'')')
  return filter(pages, '!empty(v:val)')
endfunction
function! python#fzf_doc() abort
  let options = {
    \ 'source': python#doc_pages(),
    \ 'options': '--tiebreak length,index --prompt="doc> "',
    \ 'sink': function('stack#push_stack', ['doc', 'python#doc_page'])
  \ } | call fzf#run(fzf#wrap(options))
endfunction

" Return SimpylFold expressions for decorators, docstrings, constants
" WARNING: Only call this when SimpylFold updates to improve performance. Might
" break if SimpylFold renames internal cache variable (monitor).
function! s:fold_constant(lnum) abort  " e.g. VARIABLE = [... or if condition:...
  let heads = '^\%(if\|for\|while\|with\|try\|def\|class\)\>.*:\s*\%(#.*\)\?$'
  let blocks = '^\%(\s*\|\%(elif\|else\|except\|finally\)\>.*:\s*\%(#.*\)\?\)$'
  let [label, indent] = [getline(a:lnum), s:get_indent(a:lnum + 1)]
  if label !~# '^\K\k*' || empty(indent) | return [] | endif
  let [lnum, inum, ilabel] = [a:lnum, a:lnum + 1, getline(a:lnum + 1)]
  while inum <= line('$') && (s:get_indent(inum) || ilabel =~# blocks)
    let lnum = ilabel =~# '^\s*$' ? lnum : inum
    if s:get_level(inum) && ilabel !~# '^\s*\(from\|import\)\>' | return [] | endif
    let [inum, ilabel] = [inum + 1, getline(inum + 1)]
  endwhile
  let [inum, ilabel] = [lnum + 1, getline(lnum + 1)]
  let lnum += !s:get_indent(inum) && ilabel !~# '^\s*$'
  return lnum > a:lnum + 1 ? ['>1'] + repeat([1], lnum - a:lnum - 1) + ['<1'] : []
endfunction
function! s:fold_decorator(lnum) abort
  if getline(a:lnum) !~# '^\s*@\k\+' | return [] | endif
  let [lnum, level, indent] = [a:lnum, s:get_level(a:lnum), s:get_indent(a:lnum)]
  while lnum < line('$') && !s:get_isdef(lnum + 1)
    let lnum += 1
    if s:get_level(lnum) != level || s:get_indent(lnum) < indent | return [] | endif
  endwhile
  let level = s:get_level(lnum + 1)  " definition level
  return ['>' . level] + repeat([level], lnum - a:lnum + 1)
endfunction
function! s:fold_docstring(lnum) abort
  let regex = '[frub]*["'']\{3}'  " fold e.g.. _docstring_snippet = '''...
  let [_, _, pos] = matchstrpos(getline(a:lnum), '^\K\k*\s*=\s*' . regex)
  if pos == -1 | return [] | endif
  let lnum = a:lnum  " vint: -ProhibitUsingUndeclaredVariable
  while lnum < line('$') && getline(lnum)[pos:] !~# regex  " fold entire docstring
    let [pos, lnum] = [0, lnum + 1]
    if s:get_level(lnum) | return [] | endif
  endwhile
  return lnum > a:lnum ? ['>1'] + repeat([1], lnum - a:lnum - 1) + ['<1'] : []
endfunction

" Return cached fold expression
" NOTE: This works by modifying SimpylFold cache (generated on TextChanged,InsertLeave).
" Note also use separate fold text cache to retain decorator offsets
function! python#fold_expr(lnum) abort
  let recache = !exists('b:SimpylFold_cache')
  call SimpylFold#FoldExpr(a:lnum)  " auto recache
  if recache | call python#fold_cache() | endif
  return b:SimpylFold_cache[a:lnum]['foldexpr']
endfunction
function! python#fold_cache() abort
  let b:foldtext_delta = {}
  let [lnum, cache] = [1, b:SimpylFold_cache]
  while lnum <= line('$')
    let level = s:get_level(lnum)
    let exprs = s:fold_decorator(lnum)
    if !empty(exprs)  " line offset
      let b:foldtext_delta[lnum] = len(exprs) - 1
    endif
    let exprs = level == 0 && empty(exprs) ? s:fold_docstring(lnum) : exprs
    let exprs = level == 0 && empty(exprs) ? s:fold_constant(lnum) : exprs
    if empty(exprs)  " cache unmodified
      let lnum += 1 | continue
    endif
    for idx in range(len(exprs))  " apply overrides
      let cache[lnum].foldexpr = exprs[idx] | let lnum += 1
    endfor
  endwhile
endfunction

" Return filetype-specific fold text
" NOTE: This includes text following try-except blocks, multi-line global constants,
" and multi-line docstring openers, but skips numpydoc and rest-style dash separators.
function! python#fold_text(lnum, ...) abort
  if !exists('b:foldtext_delta')
    let b:foldtext_delta = {}
  endif
  let delta = get(b:foldtext_delta, string(a:lnum), -1)
  let keys = get(b:, 'foldtext_keys', {})
  if delta < 0  " detect fold text offset
    let delta = len(s:fold_decorator(a:lnum))
    let delta = max([delta - 1, 0])
    let b:foldtext_delta[a:lnum] = delta
  endif
  let [lnum, line1, line2] = [a:lnum + delta, a:lnum + delta + 1, a:lnum + delta + 100]
  let width = get(g:, 'linelength', 88) - 10  " minimum width
  let label = fold#fold_label(lnum, 0)  " initial fold text
  let label .= label =~# '^try:\s*$' ? ' ' . fold#fold_label(line1, 1) : ''
  if label =~# '["'']\{3}\s*$'  " append lines
    for lnum in range(line1, min([line2, a:0 ? a:1 : line2]))
      let itext = fold#fold_label(lnum, 1)
      let istop = itext =~# '["'']\{3}'  " docstring close
      let itext = itext =~# '[-=]\{3,}' ? '' : itext
      let space = !istop && lnum > line1 ? ' ' : ''
      let label .= space . itext
      if istop || len(label) > width | break | endif
    endfor
  endif
  let l:subs = []  " see: https://vi.stackexchange.com/a/16491/8084
  let result = substitute(label, '["'']\{3}', '\=add(l:subs, submatch(0))', 'gn')
  let label .= len(l:subs) % 2 ? '···' . substitute(l:subs[0], '^[frub]*', '', 'g') : ''
  return label  " closed docstring
endfunction

" Get properties for docstring under cursor
" NOTE: This assumes numpydoc style formatting. Returns the initial title
" and the parameter groups after first empty line in the docstring.
" exe 'global/' . regex . '/normal! gnd"="\n" . @"' . '\<CR>' . ']p'
function! s:parse_docstring() abort
  let regex = '["'']\{3}'
  let winview = winsaveview()
  let default = [0, 0, 0, '', [], [], []]
  let result = succinct#get_delims(regex, regex)
  if empty(get(result, 0, 0)) | return default | endif
  let [_, _, line0, col0, line2, col2] = result
  let iline = min([line0 + 1, line2])
  call cursor(iline, 1)  " label start
  call search('^\s*$', 'W', line2)  " line same if fails
  let labels = getline(iline, line('.') - 1)
  let label = getline(min([line0 + 1, line2]))
  let label = label =~# regex ? '' : label
  let indent = strpart(getline(line0), 0, col0 - 1)
  let indent = indent =~# '^\s*$' ? indent : ''
  let indent = !empty(label) ? matchstr(label, '^\s*') : indent
  call cursor(min([line0 + 1, line2]), 1)
  call search('^' . indent . '\k\+\s*:', 'W', line2)
  let line1 = search('^\s*$', 'nW', line2)
  let line1 = line1 ? line1 : line2
  let [bounds, params] = [[], []]  " parameters
  call cursor(min([line0 + 1, line2]), 1)
  while search('^' . indent . '\k\+\s*:', 'W', line1)
    let [lnum, text] = [line('.'), getline('.')]
    call add(get(bounds, -1, []), lnum - 1)
    call add(bounds, [matchstr(text, '\k\+'), lnum])
  endwhile
  call add(get(bounds, -1, []), line1 - 1)
  for [key, iline, jline] in bounds
    let parts = [key, iline, jline] + getline(iline, jline)
    call add(params, parts)
  endfor
  let lines = getline(line0, line2)
  let other = getline(line1, line2 - 1)
  call winrestview(winview)
  return [line0, line1, line2, lines, labels, params, other]
endfunction

" Update and replace auto-inserted docstrings
" NOTE: This ensures correct indentation after line break. Could also use doq templates
" or below alternative using 'gnd' and auto-indent by adding newline to @" match via
" @= then indent-preserving ]p paste. See https://stackoverflow.com/a/2783670/4970632
function! s:insert_docstring(m, result) abort
  let [line0, line1, line2, lines, labels, params, other] = a:result
  let winview = winsaveview() | call cursor(line0, 1)
  if !search('["'']\{3}', 'ce', line0) | return | endif
  let [num0, num1, num2, _, _, parts, _] = s:parse_docstring()
  if !num0 || !num1 || !num2
    call appendbufline(bufnr(), line0 - 1, lines)
    call winrestview(winview) | return a:m
  endif
  let delta = len(labels)  " docstring offset
  exe "normal! a\<CR>"
  if !empty(labels)  " should auto-indent
    call deletebufline(bufnr(), line0 + 1)
    call appendbufline(bufnr(), line0, labels)
  endif
  call cursor(line0 + 1, col([line0 + 1, '$']))
  for [name, inum, jnum; lines1] in parts
    let orig = filter(copy(params), 'v:val[0] ==# name')
    if empty(orig) | continue | endif
    let [inum, jnum] = [inum + delta, jnum + delta]
    call deletebufline(bufnr(), inum, jnum)
    let [_, _, _; lines0] = orig[0]
    call appendbufline(bufnr(), inum - 1, lines0)
    let delta += len(lines0) - len(lines1)
  endfor
  call appendbufline(bufnr(), num1 + delta - 1, other)
  call winrestview(winview) | return a:m
endfunction

" Navigate and insert pydocstring 'doq' docstrings
" NOTE: The idea here is to auto-remove and auto-add parameters from
" the docstring depending on parameters in the function definition.
function! python#next_docstring(count, ...) abort
  let flags = a:count >= 0 ? 'w' : 'wb'
  if a:0 && a:1
    let head = '^\(\|\t\| \{' . shiftwidth() . '\}\)'
  else  " include comments
    let head = '\(' . comment#get_regex() . '.*\)\@<!'
  endif
  let closed = foldclosed('.')
  let regex = head . '[frub]*["'']\{3}\_s*\zs'
  let skip = "!tags#get_inside(-1, 'Constant')"
  let skip .= closed > 0 ? " || foldclosed('.') == " . closed : ''
  for _ in range(abs(a:count))  " cursor is on first non-whitespace after triple-quote
    call search(regex, flags, 0, 0, skip)
  endfor
  exe &foldopen =~# 'block\|all' ? 'normal! zv' : ''
endfunction
function! python#parse_docstring(...) abort
  let winview = winsaveview()
  let default = [0, 0, 0, 0, '', {}]
  let lnum = a:0 ? a:1 : line('.')
  let itag = tags#get_tag(lnum)
  if empty(itag) || itag[2] !~# '[mfc]'
    let msg = 'Error: Cursor is not inside class or function'
    redraw | echohl ErrorMsg | echom msg | echohl None
    call winrestview(winview) | return default
  endif
  call cursor(str2nr(itag[1]), 1)  " definition line
  let regex = escape(itag[0], '[]\/.*$~') . '('
  let iline = search(regex, 'e', line('.'))  " definition start
  let jline = searchpair('(', '', ')', 'W')  " returns end (note 'c' and '):' fail)
  if !iline || !jline
    let msg = 'Error: Object position ' . string(itag[0]) . ' not found'
    redraw | echohl ErrorMsg | echom msg | echohl None
    call winrestview(winview) | return default
  endif
  call cursor(jline + 1, col([jline + 1, '$']))
  return [iline, jline] + s:parse_docstring()
endfunction
function! python#insert_docstring(...) abort
  let result = call('python#parse_docstring', a:000)
  let [iline, jline, line0, line1, line2; rest] = result
  if line0 && line2  " remove previous docstring
    call deletebufline(bufnr(), line0, line2)
  endif
  call cursor(iline, col([iline, '$']))
  call pydocstring#insert('', 1, iline, jline)
  let jobs = shell#get_jobs('\<doq\>')
  if len(jobs) != 1
    let msg = 'Warning: Unable to unique pydocstring job (found ' . len(jobs) . ')'
    redraw | echohl WarningMsg | echom msg | echohl None | return 1
  endif
  let job = ch_getjob(jobs[0].channel)
  let opts = {'exit_cb': {_, m -> s:insert_docstring(m, result[2:])}}
  call job_setoptions(job, opts)
endfunction

" Convert between key=value pairs and 'key': value dictionaries
" NOTE: Here restrict search range within columns using marks applied by 'expr' below.
" WARNING: Use kludge where lastcol is always at the end of line. Accounts for bug
" where if opening bracket is immediately followed by newline, then 'inner' bracket
" range incorrectly sets the closing bracket column position to '1'.
function! python#_kwargs_to_dict(invert, ...) range abort
  let [loc1, loc2] = a:0 && a:1 ==# 'n' ? ["'[", "']"] : ["'<", "'>"]
  let [idx1, idx2] = [col(loc1) - 1, col([line(loc2), '$']) - 1]  " kludge (see above)
  let [line1, line2] = [line(loc1), line(loc2)]  " sorted by utils operator_func
  let [lines, winview] = [[], winsaveview()]
  for lnum in range(line1, line2)
    let [line, prefix, suffix] = [getline(lnum), '', '']
    if lnum == line1 && lnum == line2  " vint: -ProhibitUsingUndeclaredVariable
      let prefix = idx1 > 0 ? line[:idx1 - 1] : ''
      let suffix = line[idx2 + 1:]
      let line = line[idx1:idx2]  " must come last
    elseif lnum == line1
      let prefix = idx1 > 0 ? line[:idx1 - 1] : ''
      let line = line[idx1:]  " must come last
    elseif lnum == line2
      let suffix = line[idx2 + 1:]
      let line = line[:idx2]  " must come last
    endif
    if !empty(matchstr(line, ':')) && !empty(matchstr(line, '='))
      let msg = 'Warning: Text is both dictionary-like and kwarg-like.'
      redraw | echohl WarningMsg | echom msg | echohl None
    endif
    if a:invert  " dictionary to kwargs
      let line = substitute(line, '\<\ze\w\+\s*=', "'", 'g')  " add leading quote first
      let line = substitute(line, '\>\ze\s*=', "'", 'g')
      let line = substitute(line, '\s*=\s*', ': ', 'g')
    else
      let line = substitute(line, '\>[''"]\ze\s*:', '', 'g')  " remove trailing quote first
      let line = substitute(line, '[''"]\<\ze\w\+\s*:', '', 'g')
      let line = substitute(line, '\s*:\s*', '=', 'g')
    endif
    call add(lines, prefix . line . suffix)
  endfor
  exe line1 . ',' . line2 . 'd _'
  call append(line1 - 1, lines)  " replace with fixed lines
  call winrestview(winview)
  call cursor(line1, idx1 + 1)
endfunction

" Convert between key=value pairs and 'key': value dictionaries
" NOTE: Here the flagship function auto-detects surrounding dictionary or kwarg
" delimiters and replaces contents within. Fails if called anywhere else
function! python#kwargs_to_dict(invert)
  if a:invert  " dict to kwargs
    let [prev1, prev2, repl1, repl2] = ['\<\k\+(', ')', '{', '}']
  else  " kwargs to dict
    let [prev1, prev2, repl1, repl2] = ['{', '}', 'dict(', ')']
  endif
  let winview = winsaveview()
  let [line1, col1, line2, col2] = succinct#search_pairs(prev1, prev2)
  if empty(line1) || empty(line2) | return | endif
  call setpos("'<", [bufnr(), line1, col1, 0])
  call setpos("'>", [bufnr(), line2, col2, 0])
  call python#_kwargs_to_dict(a:invert)  " replace within '< '>
  call succinct#modify_delims(prev1, prev2, repl1, repl2)
  call winrestview(winview)
endfunction
" For <expr> map accepting motion
function! python#kwargs_to_dict_expr(invert) abort
  return utils#motion_func('python#_kwargs_to_dict', [a:invert, mode()])
endfunction

" Initiate jupyter-vim connection using the file matching this directory or a parent
" NOTE: This relies on automatic connection file naming in jupyter_[qt|]console.py.
" Also depends on private variable _jupyter_session. Should monitor for changes.
" NOTE: The jupyter-vim plugin offloads connection file searching to jupyter_client's
" find_connection_file(), which selects the most recently accessed file from the glob
" pattern. Therefore pass the entire pattern to jupyter#Connect() rather than the file.
function! s:jupyter() abort
  let expr = "'_jupyter_session' in globals() and "
    \ . 'bool(_jupyter_session.kernel_client.check_connection())'
  return has('python3') ? str2nr(py3eval(expr)) : 0
endfunction
function! python#jupyter_setup() abort
  let parent = 0
  let runtime = trim(system('jupyter --runtime-dir'))  " vim 8.0.163: https://stackoverflow.com/a/53250594/4970632
  while !exists('folder') || !empty(folder)  " note default scope is  (g: is ignored)
    let parent += 1
    let string = '%:p' . repeat(':h', parent)
    let folder = expand(string . ':t')
    let path = expand(string)
    let pattern = 'kernel-' . folder . '-[0-9][0-9].json'
    if !empty(glob(runtime . '/' . pattern)) | return jupyter#Connect(pattern) | endif
  endwhile
  let msg = 'Error: No connection files found for path ' . string(expand('%:p:h')) . '.'
  redraw | echohl WarningMsg | echom msg | echohl None
endfunction

" Run current motion or script
" NOTE: Running 'cell' in file without cells still works
" TODO: Add generalization for running chunks of arbitrary filetypes
function! python#run_file() abort
  if !exists('$CONDA_PREFIX')
    let msg = 'Error: Cannot find conda prefix.'
    redraw | echohl WarningMsg | echom msg | echohl None | return
  endif
  let [exe, proj] = [$CONDA_PREFIX . '/bin/python', $CONDA_PREFIX . '/share/proj']
  let cmd = 'PROJ_LIB=' . shellescape(proj) . ' ' . shellescape(exe) . ' ' . shellescape(@%)
  update | silent call shell#job_win(cmd)
endfunction
function! python#run_motion() range abort
  if s:jupyter()
    redraw | echom 'Running lines ' . a:firstline . ' to ' . a:lastline . '.'
    update | exe a:firstline . ',' . a:lastline . 'JupyterSendRange'
  else
    let msg = 'Jupyter session not found. Cannot send selection.'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
endfunction
function! python#run_general() abort
  if v:count  " see also vim.vim
    redraw | echom 'Running ' . v:count . ' lines' | exe 'JupyterSendCount ' . v:count
  elseif !s:jupyter()  " run entire script manually
    redraw | echom 'Running script with python' | call python#run_file()
  elseif search('^# %%', 'n')  " returns line number if match found, zero if none found
    redraw | echom 'Running block with jupyter' | update | JupyterSendCell
  else  " run entire script via jupyter
    redraw | echom 'Running file with jupyter' | update | JupyterRunFile
  endif
endfunction
" For <expr> map accepting motion
function! python#run_motion_expr(...) abort
  return utils#motion_func('python#run_motion', a:000)
endfunction
