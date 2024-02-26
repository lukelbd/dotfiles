"-----------------------------------------------------------------------------"
" Utilities for python files
"-----------------------------------------------------------------------------"
" Convert between key=value pairs and 'key': value dictionaries
" Warning: Use kludge where lastcol is always at the end of line. Accounts for weird
" bug where if opening bracket is immediately followed by newline, then 'inner'
" bracket range incorrectly sets the closing bracket column position to '1'.
function! python#dict_to_kw(invert, ...) abort range
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
  let check = (
    \ '"_jupyter_session" in globals() and '
    \ . '_jupyter_session.kernel_client.check_connection()'
  \ )
  if has('python3')
    return str2nr(py3eval('int(' . check . ')'))
  else
    return 0
  endif
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
  echohl WarningMsg
  echom "Warning: No connection files found for path '" . expand('%:p:h') . "'."
  echohl None
endfunction

" Run with popup window using conda python, not vim python (important for macvim)
" Todo: More robust checking for anaconda python in other places.
function! python#run_file()
  if !exists('$CONDA_PREFIX')
    echohl WarningMsg
    echom 'Cannot find conda prefix.'
    echohl None
  else
    let exe = $CONDA_PREFIX . '/bin/python'
    let proj = $CONDA_PREFIX . '/share/proj'
    let cmd = 'PROJ_LIB=' . shellescape(proj) . ' ' . shellescape(exe) . ' ' . shellescape(@%)
    silent call shell#job_win(cmd)
  endif
endfunction

" Run file or lines using either popup window or jupyter session
" Note: Running 'cell' in file without cells still works
function! python#run_general() abort
  update
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

" Run input motion using jupyter session. Warning is issued if no connection
" Todo: Add generalization for running chunks of arbitrary filetypes?
function! python#run_motion() range abort
  update
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
function! s:parse_name(item)
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
function! python#doc_name(...) abort
  let line = getline('.')  " current line
  let parse = &l:filetype ==# 'python'
  let current = get(b:, 'doc_name', '')  " see shell.vim
  if a:0  " input value
    let item = a:1
  elseif !parse && empty(current)
    let item = ''
  else  " cursor word in pydoc page or python file
    let head = matchstr(line[:col('.') - 1], '\h\(\w\|\.\)*$')
    let tail = matchstr(line[col('.'):], '^\w*')
    let item = head . tail
  endif
  let item = empty(item) ? get(s:, 'doc_prev', '') : item
  let item = parse ? s:parse_name(item) : item
  if empty(current) || item =~# current || current =~# item
    let name = item
  elseif item =~# '^[a-z]\w*\.[A-Z]\w\+'  " cursor item is full class name
    let name = item
  else  " infer from header line
    let header = matchstr(getline(1), '\s\+\zs\h\(\w\|\.\)*\ze:$')  " '.' is keyword in man
    let package = matchstr(getline(1), '\s\+\zs\h\w*\ze\(\.\h\w*\)*:$')
    if empty(header)
      let name = item  " fallback
    elseif getline(1) =~# 'Help on \(module\|package\)'
      let name = current . '.' . item  " e.g. xarray.<name>
    elseif empty(package) || item =~# '^[a-z_]\+$'
      let name = header . '.' . item  " e.g. pd.DataFrame.read_csv
    else  " reference package
      let name = package . '.' . item
    endif
  endif
  return name
endfunction

" Browse documentation with man-style pydoc pages
" Note: This is still useful over Lsp e.g. for generalized help page browsing. And
" everything is standardized to man-format so has consistency with man utilities.
function! python#doc_page(...) abort
  if !a:0  " user input page
    let page = utils#input_default('Pydoc page', python#doc_name(), 'python#doc_source')
  else  " navigation page
    let page = empty(a:1) ? python#doc_name() : a:1
  endif
  let parse = &l:filetype ==# 'python'
  if empty(page) | return 1 | endif
  if parse | let page = s:parse_name(page) | endif
  let bnr = bufnr()  " current buffer
  let pnr = bufnr(page)  " WARNING: only matches start of string
  let new = !bufexists(page)  " WARNING: only matches exact string
  if new  " create new buffer
    let result = systemlist('pydoc ' . shellescape(page))
    let result = map(result, 'substitute(v:val, ''^\( \{4}\)* |  '', ''\1'', ''ge'')')
    let msg = "Error: Pydoc page '" . page . "' not found"
    if len(result) <= 5 | echohl ErrorMsg | echom msg | echohl None | return 1 | endif
  endif
  let s:doc_prev = page  " previously browsed
  if !empty(get(b:, 'doc_name', ''))  " existing path shell.vim
    silent exe new ? 'enew | file ' . page : pnr . 'buffer'
  else
    silent exe new ? 'tabedit ' . page : 'tabedit | ' . pnr . 'buffer'
  endif
  if new | call append(0, result) | goto | endif | let b:doc_name = page  " critical
  setlocal nobuflisted bufhidden=hide buftype=nofile filetype=man | return 0
endfunction
function! python#doc_source(...) abort
  let cmd = 'pip list --no-color --no-input --no-python-version-warning'
  let pages = systemlist(cmd)[2:]
  let pages = map(pages, 'substitute(v:val, ''\s\+.*$'', '''', ''g'')')
  let pages = filter(pages, '!empty(v:val)')
  return pages
endfunction
function! python#doc_search() abort
  call fzf#run(fzf#wrap({
    \ 'source': python#doc_source(),
    \ 'options': '--no-sort --prompt="pydoc> "',
    \ 'sink': function('stack#push_stack', ['doc', 'python#doc_page'])
    \ }))
endfunction

" Split docstrings over multiple lines
" Note: This is used to adjust vim-pydocstring without using complicated template files.
" Use 'timer_start' to avoid race condition with plugin job (see ftplugin/python.vim).
" Note: This ensures correct indentation after line break. Below shows alternative
" approach using 'gnd' and auto-indent by adding newline to @" match via @= and using
" indent-preserving paste ]p. See https://stackoverflow.com/a/2783670/4970632
" exe 'global/' . regex . '/normal! gnd"="\n" . @"' . '\<CR>' . ']p'
function! python#split_docstrings(...) abort
  let regex = '["'']\{3}\n\@!\zs.*$'
  let cmd = "normal! gnc\<CR>\<C-r>\""
  exe 'global/' . regex . '/' . cmd
  let regex = '\(\(^\|\_s\)[frub]*\)\@<!'
  let regex = regex . '["'']\{3}\s*$'
  exe 'global/' . regex . '/' . cmd
endfunction
function! python#next_docstring(count, ...) abort
  let flags = a:count >= 0 ? 'w' : 'wb'
  if a:0 && a:1
    let head = '^\(\|\t\| \{' . &tabstop . '\}\)'
  else
    let head = '\(' . comment#get_regex() . '.*\)\@<!'
  endif
  let regex = head . '[frub]*["'']\{3}\_s*\zs'
  for _ in range(abs(a:count))
    call search(regex, flags, 0, 0, "!utils#get_inside(-1, 'Constant')")
  endfor
endfunction
