"-----------------------------------------------------------------------------"
" Utilities for python files
"-----------------------------------------------------------------------------"
" Convert between key=value pairs and 'key': value dictionaries
" Warning: Use kludge where lastcol is always at the end of line. Accounts for weird
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

" Folding expression to add global constants and docstrings to SimpylFold cache
" Warning: Only call this when SimpylFold updates to improve performance. Might break
" if SimpylFold renames internal cache variable (monitor). Note
function! s:fold_exists(lnum) abort
  return exists('b:SimpylFold_cache')
    \ && !empty(b:SimpylFold_cache[a:lnum])
    \ && !empty(b:SimpylFold_cache[a:lnum]['foldexpr'])  " note empty(0) returns 1
endfunction
function! python#fold_expr(lnum) abort
  let recache = !exists('b:SimpylFold_cache')
  call SimpylFold#FoldExpr(a:lnum)  " auto recache
  if recache | call python#fold_cache() | endif
  return b:SimpylFold_cache[a:lnum]['foldexpr']
endfunction
function! python#fold_cache() abort
  let lnum = 1
  let cache = b:SimpylFold_cache
  let headers = '^\(if\|for\|while\|with\|try\|def\|class\)\>.*:\s*\(#.*\)\?$'
  let keywords = '^\(elif\|else\|except\|finally\)\>.*:\s*\(#.*\)\?$'
  let docstring = '[frub]*["'']\{3}'  " doctring regex (see fold.vim)
  while lnum <= line('$')
    if s:fold_exists(lnum) | let lnum += 1 | continue | endif
    let line = getline(lnum)
    let group = []
    " Docstring fold (e.g. _docstring_snippet = '''...)
    let [_, _, pos] = matchstrpos(line, '^\K\k*\s*=\s*' . docstring)
    if pos > -1  " vint: -ProhibitUsingUndeclaredVariable
      call add(group, lnum)
      while lnum < line('$') && getline(lnum)[pos:] !~# docstring  " fold entire docstring
        let [pos, lnum] = [0, lnum + 1]
        call add(group, lnum)
        if s:fold_exists(lnum)
          let group = [] | break
        endif
      endwhile
    endif
    " Zero-indent fold (e.g. VARIABLE = [... or if condition:...)
    if empty(group) && line =~# '^\K\k*'
      call add(group, lnum)
      while lnum < line('$') && (get(cache[lnum + 1], 'indent', 0) || getline(lnum + 1) =~# keywords)
        let lnum += 1 | call add(group, lnum)
        if s:fold_exists(lnum) && getline(lnum) !~# '^\s*\(from\|import\)\>'
          let group = [] | break
        endif
      endwhile
      if len(group) > 1 && line !~# headers
        let lnum += 1 | call add(group, lnum)
      endif
    endif
    " Apply results (see :help fold-expr)
    if len(group) > 1  " constant group found
      let cache[group[0]]['foldexpr'] = '>1'  " fold start
      let cache[group[-1]]['foldexpr'] = '<1'  " fold end
      for value in range(group[1], group[-2])
        let cache[value]['foldexpr'] = 1  " inner fold
      endfor
    endif
    let lnum += 1  " e.g. termination of constant group
  endwhile
endfunction

" Initiate jupyter-vim connection using the file matching this directory or a parent
" Note: This relies on automatic connection file naming in jupyter_[qt|]console.py.
" Also depends on private variable _jupyter_session. Should monitor for changes.
" Note: The jupyter-vim plugin offloads connection file searching to jupyter_client's
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
" Todo: More robust checking for conda python in other places
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
" Note: Running 'cell' in file without cells still works
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
" Todo: Add generalization for running chunks of arbitrary filetypes?
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
" Todo: Use below regexes to generate suggestion lists based on file text. Should
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
" Note: This is still useful over Lsp e.g. for generalized help page browsing. And
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
  setlocal nobuflisted bufhidden=hide buftype=nofile filetype=man | return 0
endfunction
function! python#doc_list(...) abort
  let pages = systemlist('pip list --no-color --no-input --no-python-version-warning')
  let pages = map(pages[2:], 'substitute(v:val, ''\s\+.*$'', '''', ''g'')')
  return filter(pages, '!empty(v:val)')
endfunction
function! python#fzf_doc() abort
  call fzf#run(fzf#wrap({
    \ 'source': python#doc_list(),
    \ 'options': '--no-sort --prompt="doc> "',
    \ 'sink': function('stack#push_stack', ['doc', 'python#doc_page'])
  \ }))
endfunction

" Insert pydocstring 'doq' docstrings and convert from single-line to multi-line
" Note: This ensures correct indentation after line break. Could also use doq templates
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
  let itag = tags#find_tag(line('.') + 1)  " preceding tags
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
