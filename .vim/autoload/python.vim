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
    let indent = strdisplaywidth(matchstr(getline(a:lnum), '^\s*')) / &l:tabstop
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

" Convert between key=value pairs and 'key': value dictionaries
" WARNING: Use kludge where lastcol is always at the end of line. Accounts for weird
" bug where if opening bracket is immediately followed by newline, then 'inner'
" bracket range incorrectly sets the closing bracket column position to '1'.
function! python#dict_to_kw(invert, ...) range abort
  let winview = winsaveview()
  let lines = []
  let marks = a:0 && a:1 ==# 'n' ? '[]' : '<>'
  let col1 = col("'" . marks[0]) - 1  " first column, note ' really means ` here
  let col2 = len(getline("'" . marks[1])) - 1  " last selection column
  let [line1, line2] = sort([a:firstline, a:lastline], 'n')
  for lnum in range(line1, line2)
    let [line, prefix, suffix] = [getline(lnum), '', '']
    if lnum == line1 && lnum == line2  " vint: -ProhibitUsingUndeclaredVariable
      let prefix = col1 > 0 ? line[:col1 - 1] : ''
      let suffix = line[col2 + 1:]
      let line = line[col1:col2]  " must come last
    elseif lnum == line1
      let prefix = col1 > 0 ? line[:col1 - 1] : ''
      let line = line[col1:]  " must come last
    elseif lnum == line2
      let suffix = line[col2 + 1:]
      let line = line[:col2]  " must come last
    endif
    if !empty(matchstr(line, ':')) && !empty(matchstr(line, '='))
      echohl WarningMsg
      echom 'Warning: Text is both dictionary-like and kwarg-like.'
      echohl None
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
  call cursor(line1, col1)
endfunction
" For <expr> map accepting motion
function! python#dict_to_kw_expr(invert) abort
  return utils#motion_func('python#dict_to_kw', [a:invert, mode()])
endfunction

" Return SimpylFold expressions for decorators, docstrings, constants
" WARNING: Only call this when SimpylFold updates to improve performance. Might
" break if SimpylFold renames internal cache variable (monitor).
function! s:get_decorator(lnum) abort
  if getline(a:lnum) !~# '^\s*@\k\+' | return [] | endif
  let [lnum, level, indent] = [a:lnum, s:get_level(a:lnum), s:get_indent(a:lnum)]
  while lnum < line('$') && !s:get_isdef(lnum + 1)
    let lnum += 1
    if s:get_level(lnum) != level || s:get_indent(lnum) < indent | return [] | endif
  endwhile
  let level = s:get_level(lnum + 1)  " definition level
  return ['>' . level] + repeat([level], lnum - a:lnum + 1)
endfunction
function! s:get_docstring(lnum) abort
  let regex = '[frub]*["'']\{3}'  " fold e.g.. _docstring_snippet = '''...
  let [_, _, pos] = matchstrpos(getline(a:lnum), '^\K\k*\s*=\s*' . regex)
  if pos == -1 | return [] | endif
  let lnum = a:lnum
  while lnum < line('$') && getline(lnum)[pos:] !~# regex  " fold entire docstring
    let [pos, lnum] = [0, lnum + 1]
    if s:get_level(lnum) | return [] | endif
  endwhile
  return lnum > a:lnum ? ['>1'] + repeat([1], lnum - a:lnum - 1) + ['<1'] : []
endfunction
function! s:get_constant(lnum) abort  " e.g. VARIABLE = [... or if condition:...
  let heads = '^\(if\|for\|while\|with\|try\|def\|class\)\>.*:\s*\(#.*\)\?$'
  let blocks = '^\(elif\|else\|except\|finally\)\>.*:\s*\(#.*\)\?$'
  let [lnum, line, indent] = [a:lnum, getline(a:lnum), s:get_indent(a:lnum + 1)]
  if line !~# '^\K\k*' || !indent | return [] | endif
  while lnum < line('$') && (s:get_indent(lnum + 1) || getline(lnum + 1) =~# blocks)
    let lnum += 1
    if s:get_level(lnum) && getline(lnum) !~# '^\s*\(from\|import\)\>' | return [] | endif
  endwhile
  if lnum > a:lnum && line !~# heads | let lnum += 1 | endif
  return lnum > a:lnum ? ['>1'] + repeat([1], lnum - a:lnum - 1) + ['<1'] : []
endfunction

" Return fold expression and text accounting for global constants and docstrings
" NOTE: This includes text following try-except blocks and docstring openers, but
" skips numpydoc and rest-style dash separators. Should add to this.
let s:maxlines = 100  " maxumimum lines to search
function! python#fold_expr(lnum) abort
  let recache = !exists('b:SimpylFold_cache')
  call SimpylFold#FoldExpr(a:lnum)  " auto recache
  if recache | call python#fold_cache() | endif
  return b:SimpylFold_cache[a:lnum]['foldexpr']
endfunction
function! python#fold_cache() abort
  let b:fold_heads = {}
  let [lnum, cache] = [1, b:SimpylFold_cache]
  while lnum <= line('$')
    let level = s:get_level(lnum)
    let exprs = s:get_decorator(lnum)
    if !empty(exprs) | let b:fold_heads[string(lnum)] = lnum + len(exprs) - 1 | endif
    let exprs = !level && empty(exprs) ? s:get_docstring(lnum) : exprs
    let exprs = !level && empty(exprs) ? s:get_constant(lnum) : exprs
    if empty(exprs) | let lnum += 1 | continue | endif
    for idx in range(len(exprs))  " apply overrides
      let cache[lnum].foldexpr = exprs[idx] | let lnum += 1
    endfor
  endwhile
endfunction
function! python#fold_text(lnum, ...) abort
  let heads = get(b:, 'fold_heads', {})
  let lnum = get(heads, string(a:lnum), a:lnum)
  let exprs = lnum != a:lnum ? [] : s:get_decorator(a:lnum)
  if !empty(exprs)  " recache
    let lnum = a:lnum + len(exprs) - 1
    let heads[string(a:lnum)] = lnum
  endif
  let [line1, line2] = [lnum + 1, lnum + s:maxlines]
  let label = fold#fold_label(lnum, 0)
  let width = get(g:, 'linelength', 88) - 10  " minimum width
  let regex = '["'']\{3}'  " docstring expression
  if label =~# '^try:\s*$'  " append lines
    let label .= ' ' . fold#fold_label(line1, 1)  " remove indent
  endif
  if label =~# regex . '\s*$'  " append lines
    for lnum in range(line1, min([line2, a:0 ? a:1 : line2]))
      let itext = fold#fold_label(lnum, 1)
      let istop = itext =~# regex  " docstring close
      let itext = itext =~# '[-=]\{3,}' ? '' : itext
      let space = !istop && lnum > line1 ? ' ' : '' 
      let label .= space . itext
      if istop || len(label) > width | break | endif
    endfor
  endif
  let l:subs = []  " see: https://vi.stackexchange.com/a/16491/8084
  let result = substitute(label, regex, '\=add(l:subs, submatch(0))', 'gn')
  let label .= len(l:subs) % 2 ? '···' . substitute(l:subs[0], '^[frub]*', '', 'g') : ''
  return label  " closed docstring
endfunction

" Initiate jupyter-vim connection using the file matching this directory or a parent
" NOTE: This relies on automatic connection file naming in jupyter_[qt|]console.py.
" Also depends on private variable _jupyter_session. Should monitor for changes.
" NOTE: The jupyter-vim plugin offloads connection file searching to jupyter_client's
" find_connection_file(), which selects the most recently accessed file from the glob
" pattern. Therefore pass the entire pattern to jupyter#Connect() rather than the file.
function! python#has_jupyter() abort
  let code = '''_jupyter_session'' in globals()'
    \ . ' and bool(_jupyter_session.kernel_client.check_connection())'
  return has('python3') ? str2nr(py3eval(code)) : 0
endfunction
function! python#init_jupyter() abort
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
  redraw | echohl WarningMsg
  echom "Error: No connection files found for path '" . expand('%:p:h') . "'."
  echohl None
endfunction

" Run current file with conda python (important for macvim)
" TODO: More robust checking for conda python in other places
function! python#run_file() abort
  if !exists('$CONDA_PREFIX')
    redraw | echohl WarningMsg
    echom 'Error: Cannot find conda prefix.'
    echohl None | return
  endif
  let exe = $CONDA_PREFIX . '/bin/python'
  let proj = $CONDA_PREFIX . '/share/proj'
  let cmd = 'PROJ_LIB=' . shellescape(proj) . ' ' . shellescape(exe) . ' ' . shellescape(@%)
  silent call shell#job_win(cmd)
endfunction

" Run current file or lines using either popup window or jupyter session
" NOTE: Running 'cell' in file without cells still works
function! python#run_general() abort
  update | redraw
  if v:count  " see also vim.vim
    echom 'Running ' . v:count . ' lines'
    exe 'JupyterSendCount ' . v:count
  elseif !python#has_jupyter()
    echom 'Running file with python'
    call python#run_file()
  elseif search('^# %%', 'n')  " returns line number if match found, zero if none found
    echom 'Running block with jupyter'
    JupyterSendCell
  else
    echom 'Running file with jupyter'
    JupyterRunFile
  endif
endfunction

" Run input motion using jupyter session (issue warning if no connection)
" TODO: Add generalization for running chunks of arbitrary filetypes?
function! python#run_motion() range abort
  update | redraw
  if python#has_jupyter()
    echom 'Running lines ' . a:firstline . ' to ' . a:lastline . '.'
    exe a:firstline . ',' . a:lastline . 'JupyterSendRange'
  else
    echohl WarningMsg
    echom 'Jupyter session not found. Cannot send selection.'
    echohl None
  endif
endfunction
" For <expr> map accepting motion
function! python#run_motion_expr(...) abort
  return utils#motion_func('python#run_motion', a:000)
endfunction

" Parse python module abbreviations
" TODO: Use below regexes to generate suggestion lists based on file text. Should
" iterate over file lines then suggest any <import>.method matches found for all
" imports names. Could also combine <variable>.method with every possible prefix.
function! python#doc_translate(item) abort
  if &l:filetype !=# 'python' | return a:item | endif
  let winview = winsaveview()
  let parts = split(a:item, '\.')
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
function! python#doc_options(...) abort
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
  let item = python#doc_translate(item)
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
  let opts = python#doc_options()  " item under cursor
  if !a:0  " user input page
    let page = utils#input_default('Doc page', opts[-1], 'python#doc_list')
  else  " navigation page
    let page = empty(a:1) ? opts[-1] : a:1
  endif
  if empty(page) | return 1 | endif
  let page = python#doc_translate(page)
  let opts = python#doc_options(page)
  let result = []  " default result
  if !bufexists(page)   " WARNING: only matches exact string
    for iopt in opts
      let result = systemlist('pydoc ' . shellescape(iopt))
      let result = map(result, {idx, val -> substitute(val, '^\( \{4}\)* |  ', '\1', 'ge')})
      if len(result) >= 5 | let page = iopt | break | endif
    endfor
    if len(result) < 5
      let msg = 'Error: Doc page not found: '  " show options
      let msg .= join(map(opts, {idx, val -> string(val)}), ', ')
      echohl ErrorMsg | echom msg | echohl None | return 1
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
  setlocal nobuflisted bufhidden=hide buftype=nofile filetype=man
endfunction
function! python#doc_list(...) abort
  let pages = systemlist('pip list --no-color --no-input --no-python-version-warning')
  let pages = map(pages[2:], 'substitute(v:val, ''\s\+.*$'', '''', ''g'')')
  return filter(pages, '!empty(v:val)')
endfunction
function! python#fzf_doc() abort
  let options = {
    \ 'source': python#doc_list(),
    \ 'options': '--no-sort --prompt="doc> "',
    \ 'sink': function('stack#push_stack', ['doc', 'python#doc_page'])
  \ }
  call fzf#run(fzf#wrap(options))
endfunction

" Insert pydocstring 'doq' docstrings and convert from single-line to multi-line
" NOTE: This ensures correct indentation after line break. Could also use doq templates
" or below alternative using 'gnd' and auto-indent by adding newline to @" match via
" @= then indent-preserving ]p paste. See https://stackoverflow.com/a/2783670/4970632
" exe 'global/' . regex . '/normal! gnd"="\n" . @"' . '\<CR>' . ']p'
let s:regex_doc = '["'']\{3}'
function! python#next_docstring(count, ...) abort
  let flags = a:count >= 0 ? 'w' : 'wb'
  if a:0 && a:1
    let head = '^\(\|\t\| \{' . &tabstop . '\}\)'
  else  " include comments
    let head = '\(' . comment#get_regex() . '.*\)\@<!'
  endif
  let regex = head . '[frub]*' . s:regex_doc . '\_s*\zs'
  for _ in range(abs(a:count))  " cursor is on first non-whitespace after triple-quote
    call search(regex, flags, 0, 0, "tags#get_skip(-1, 'Constant')")
  endfor
  if &foldopen =~# 'quickfix' | exe 'normal! zv' | endif
endfunction
function! python#insert_docstring() abort
  let winview = winsaveview()
  let itag = tags#get_tag(line('.'))
  if empty(itag) || itag[2] !~# '[mfc]'
    echohl ErrorMsg
    echom 'Error: Cursor is not inside class or function'
    echohl None
    call winrestview(winview) | return
  endif
  let tline = str2nr(itag[1])  " definition line
  call cursor(tline, 1)
  let regex = escape(itag[0], '[]\/.*$~') . '('
  let line1 = search(regex, 'e', tline)
  let line2 = searchpair('(', '', ')', 'W')  " returns end (note 'c' and '):' fail)
  if !line1 || !line2
    echohl ErrorMsg
    echom 'Error: Invalid object ' . string(itag[0]) . ' or position not found'
    echohl None
    call winrestview(winview) | return
  endif
  let dline = line2 + 1
  call cursor(dline, col([dline, '$']))
  silent let result = succinct#get_delims(s:regex_doc, s:regex_doc)
  if !empty(get(result, 0, 0))
    let [_, _, dline1, _, dline2, _] = result
    call deletebufline(bufnr(), dline1, dline2)
  endif
  call cursor(line1, col([line1, '$']))
  call pydocstring#insert('', 1, line1, line2)
  sleep 500m | call cursor(dline, 1)
  let doc0 = search(s:regex_doc, 'ce')
  if doc0 && col('.') < col('$') - 1  " format if necessary
    exe "normal! a\<CR>\<Esc>=="
  endif
endfunction
