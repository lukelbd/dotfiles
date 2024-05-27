"-----------------------------------------------------------------------------"
" Utilities for managing files
"-----------------------------------------------------------------------------"
" Helper functions
" WARNING: For some reason including 'down' in fzf#run prevents fzf from returning
" a list (version 0.29). However exluding it produces weird behavior that blacks
" out rest of screen. Workaround is to factor out an unnecessary source function.
let s:new_dir = ''  " path completion base folder
let s:new_file = '[new file]'  " fzf entry for requesting new file
function! file#format_dir(path, ...) abort
  let regex = '^[~.]*/\|^\w\+:'  " path base or 'drive' is present
  let base = fnamemodify(a:path, ':p:~:.')  " note do not use RelativePath
  let base = a:0 && a:1 && base !~# regex ? './' . base : base
  return substitute(base, '[^/]\@<=/*$', '/', '')
endfunction
function! file#echo_path(head, ...) abort
  let path = expand(a:0 ? a:1 : '%')
  let path = RelativePath(path, 1)
  let head = substitute(a:head, '^\(\a\)\(\a*\)$', '\u\1\l\2', '')
  redraw | echom head . ': ' . path
endfunction
function! file#expand_cfile(...) abort
  let show = a:0 ? a:1 : 0
  let path = expand('<cfile>')
  for root in ['', getcwd(), expand('%:p:h'), parse#get_root(expand('%:p'))]
    let check = empty(root) ? path : root . '/' . path
    let files = glob(check, 0, 1)
    if !empty(files) | break | endif
  endfor
  return map(files, 'RelativePath(v:val, show)')
endfunction

" Generate list of files in directory
" WARNING: Critical that the list options match the prompt lead or else
" when a single path is returned <Tab> during input() does not complete it.
function! file#glob_complete(base, ...) abort
endfunction
function! file#glob_files(base, ...) abort
  if a:0 && !empty(a:1)  " input pattern
    let paths = globpath(a:base, a:1 . '*', 0, 1)
  else  " all matches
    let paths = globpath(a:base, '*', 0, 1) + globpath(a:base, '.?*', 0, 1)
  endif
  return map(paths, "fnamemodify(v:val, ':t')")
endfunction
function! file#glob_paths(lead, ...) abort
  let base = a:lead =~# '^[~.]*/\|^\~$' ? '' : file#format_dir(s:new_dir)
  let head = base . file#format_dir(fnamemodify(a:lead, ':h'))
  let tail = fnamemodify(a:lead, ':t')
  if empty(head) || head ==# './'  " exclude leading component
    let paths = glob(tail . '*', 1, 1) + glob(tail . '.*', 1, 1)
  else  " include leading component
    let paths = globpath(head, tail . '*', 1, 1) + globpath(head, tail . '.*', 1, 1)
  endif
  let filt = 'fnamemodify(v:val, '':t'') !~# ''^\.\+$'''  " remove dots
  let map0 = 'fnamemodify(v:val, '':~:.'')'  " abbreviate names
  let map1 = 'isdirectory(v:val) ? v:val . ''/'' : v:val'  " append '/' to folders
  let map2 = 'substitute(v:val, ''^\.\/'', '''', '''')'  " remove current folder
  let map3 = 'substitute(v:val, ''^'' . base, '''', '''')'  " remove base folder
  return map(map(map(map(filter(paths, filt), map0), map1), map2), map3)
endfunction

" Open recently edited file
" NOTE: This is companion to :History with nicer behavior. Files tracked
" in ~/.vim_mru_files across different open vim sessions.
function! file#fzf_history(arg, ...)
  let bang = a:0 && a:1 || a:arg[len(a:arg) - 1] ==# '!'
  let opts = fzf#vim#with_preview()
  let opts.dir = getcwd()
  if a:arg[0] ==# ':'
    call fzf#vim#command_history(bang)
  elseif a:arg[0] ==# '/'
    call fzf#vim#search_history(bang)
  else
    call fzf#vim#history(opts, bang)
  endif
endfunction
function! file#fzf_recent(...) abort
  let files = readfile(expand(g:MRU_file))
  if files[0] =~# '^#' | call remove(files, 0) | endif
  let bang = a:0 ? a:1 : 0
  let opts = fzf#vim#with_preview()
  let opts = join(map(get(opts, 'options', []), 'fzf#shellescape(v:val)'), ' ')
  let prompt = string('Recents> ')
  call map(files, {_, val -> RelativePath(val)})
  call map(files, {_, val -> val =~# '^icloud\>' ? '~/' . val : val})
  let options = {
    \ 'sink': function('file#drop_file'),
    \ 'source' : files,
    \ 'options': opts . ' --no-sort --prompt=' . prompt,
  \ }
  return fzf#run(fzf#wrap('recents', options, bang))
endfunction

" Open input files
" NOTE: Must use expand() not glob() or new file names are not completed.
" NOTE: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
function! file#fzf_input(cmd, default, ...) abort
  let default = file#format_dir(a:default, 1)
  let input = utils#input_default(a:cmd, default, 'file#glob_paths')
  if empty(input) | return | endif
  return call('file#fzf_init', [0, 0, 0, a:cmd, input])
endfunction
function! file#fzf_init(bang, global, level, cmd, ...) abort
  let input = []  " user-input input paths (may not exist)
  call map(copy(a:000), 'extend(input, expand(trim(v:val), 0, 1))')
  let paths = call('parse#get_paths', [2, a:global, 1 + a:level] + reverse(input))
  let paths = empty(paths) ? input : reverse(paths)  " important paths at top instead of bottom
  let func = a:cmd ==# 'Files' ? 'file#fzf_files' : 'file#fzf_open'
  let args = a:cmd ==# 'Files' ? [a:bang, paths] : [a:bang, a:cmd, paths]
  return call(func, args)
endfunction
function! file#input_path(prompt, default, ...) abort
  let base1 = file#format_dir(a:0 ? a:1 : '', 0)
  let base2 = file#format_dir(a:0 ? a:1 : '', 1)  " leading ./
  let default1 = empty(a:default) ? base2 : a:default
  let default2 = empty(a:default) ? base2 : base1 . a:default
  let prompt = substitute(a:prompt, '^\(\a\)\(\a*\)$', '\u\1\l\2', '')
  let prompt = prompt . ' (' . default2 . ')'  " prompt with base folder
  let s:new_dir = base2  " glob using this folder
  let path = utils#input_default(prompt, default1, 'file#glob_paths')
  return path =~# '^[~.]*/\|^\~\?$' ? path : base1 . path
endfunction

" Open arbitrary files recursively
" NOTE: Try to preserve relative paths constructed by parse#get_paths(). Follows all
" symlinks, e.g. ~/.vimrc pointing to dotfiles, but keeps RelativePath() 'icloud'.
" NOTE: This is modeled after fzf :Files command. Used to search arbitrary files
" while respecting '.ignore' patterns used for e.g. f0/f1 commands.
function! file#fzf_find(base) abort
  let bases = type(a:base) > 1 ? join(a:base, ' ') : a:base
  let flags = '-type d \( -name .git -o -name .svn -o -name .hg \) -prune -o '
  let flags .= join(parse#get_ignores(1, 1, 2), ' ')  " skip .gitignore, skip folders
  let flags .= ' -type f -print | sed "s@^./@@;s@^$HOME@~@"'  " remove leading dot
  return 'find ' . bases . ' ' . flags
endfunction
function! file#fzf_files(bang, ...) abort
  " Parse input arguments
  let [bases, warns] = [[], []]
  for base in a:0 ? type(a:1) > 1 ? copy(a:1) : copy(a:000) : [getcwd()]
    let base = substitute(expand(base), '/$', '', '')
    if filereadable(resolve(base))
      let base = fnamemodify(base, ':h')
    endif
    if !isdirectory(resolve(base))
      call add(warns, base) | continue
    endif
    if !empty(bases)
      let base = RelativePath(base, bases[0])
    endif
    call add(bases, base . '/')  " resolve symlinks
  endfor
  " Generate and select files
  if !empty(warns)
    let msg = join(map(warns, 'string(v:val)'), ', ')
    redraw | echohl WarningMsg
    echom 'Warning: Ignoring invalid directory path(s): ' . msg
    echohl None
  endif
  let source = file#fzf_find(['.'] + bases[1:])
  let opts = fzf#vim#with_preview()
  let opts = join(map(get(opts, 'options', []), 'fzf#shellescape(v:val)'), ' ')
  let prompt = string('Files> ' . file#format_dir(bases[0], 1))
  let options = {
    \ 'dir': fnamemodify(bases[0], ':p'),
    \ 'sink*': function('file#fzf_open', [a:bang, 'Drop', bases[0]]),
    \ 'source': source,
    \ 'options': opts . ' --no-sort --prompt=' . prompt,
  \ }
  return fzf#run(fzf#wrap('files', options, 0))
endfunction

" Check if user selection is directory, descend until user selects a file.
" NOTE: Since fzf executes asynchronously cannot do loop recursion inside the driver
" function. See https://github.com/junegunn/fzf/issues/1577#issuecomment-492107554
function! file#open_sink(cmd, ...) abort
  for path in a:000
    if empty(path) | continue | endif
    if path =~# '[*?[\]]' | continue | endif  " unexpanded glob
    if isdirectory(path)  " false for empty string
      redraw | echohl WarningMsg
      echom 'Warning: Skipping directory ' . string(path) . '.'
      echohl None | continue
    endif
    exe a:cmd . ' ' . fnameescape(path)
  endfor
endfunction
function! file#fzf_open(bang, cmd, ...) abort
  " Parse arguments
  if a:0 == 1  " user invocation
    let base = ''
    let items = a:1
  else  " fzf invocation (ignore binding)
    let base = a:1
    let items = a:2
  endif
  if !exists(':' . get(split(a:cmd), 0, ''))
    redraw | echohl WarningMsg
    echom 'Error: Command ' . string(a:cmd) . ' not found.'
    echohl None | return
  endif
  " Process paths input manually or from fzf
  let base = fnamemodify(base, ':p')  " enforce trailing slash
  let paths = []
  for item in items  " expand tilde
    let item = expand(item)
    if item ==# s:new_file  " should be recursed at least one level
      let args = ['.']  " WARNING: fzf sets 'base' to current working directory
      let file = expand('<cfile>')
      try
        let item = utils#input_default('File', file, function('file#glob_files', args))
      catch /^Vim:Interrupt$/
        let item = ''  " avoid error message
      finally
        if !empty(item) | call add(paths, item) | endif
      endtry
    elseif item ==# '..'  " remove slash and tail
      call add(paths, fnamemodify(base, ':h:h'))
    elseif !empty(item)
      call add(paths, item =~# '^/' ? item : base . item)
    endif
  endfor
  " Possibly activate or re-activate fzf
  " NOTE: Use feedkeys() if only one selected or else new file template loading fails
  let ipath = get(paths, 0, '')
  let recurse = isdirectory(ipath) || fnamemodify(ipath, ':t') ==# '..'
  if empty(paths) && a:0 == 1 || len(paths) == 1 && recurse
    let base = fnamemodify(get(paths, 0, '.'), ':p')
    let opts = fzf#vim#with_preview()
    let opts = join(map(get(opts, 'options', []), 'fzf#shellescape(v:val)'), ' ')
    let prompt = string(a:cmd . '> ' . file#format_dir(base, 1))
    let options = {
      \ 'dir': base,
      \ 'sink*': function('file#fzf_open', [a:bang, a:cmd, base]),
      \ 'source': file#glob_files(base) + [s:new_file],
      \ 'options': opts . ' --no-sort --prompt=' . prompt,
    \ }
    let paths = []  " only continue in recursion
    call fzf#run(fzf#wrap('open', options, a:bang))
  endif
  if !empty(paths)
    let arg = join(map([a:cmd] + paths, 'string(v:val)'), ', ')
    call feedkeys("\<Cmd>call file#open_sink(" . arg . ")\<CR>", 'n')
  endif
endfunction

" Open file or jump to tab. From tab drop plugin: https://github.com/ohjames/tabdrop
" WARNING: Using :edit without feedkeys causes issues navigating fugitive panels.
" WARNING: The default ':tab drop' seems to jump to the last tab on failure and
" also takes forever. Also have run into problems with it on some vim versions.
function! file#goto_file(...) abort
  try
    set eventignore=BufEnter,BufLeave
    silent return call('file#drop_file', a:000)
  finally
    set eventignore=
  endtry
endfunction
function! file#drop_file(...) abort
  let current = expand('%:p')
  for iarg in a:000
    let path = type(iarg) ? iarg : bufname(iarg)
    let abs = fnamemodify(path, ':p')
    let nrs = []  " tab and window number
    for tnr in range(1, tabpagenr('$'))  " iterate through each tab
      for bnr in tabpagebuflist(tnr)
        if abs ==# expand('#' . bnr . ':p')
          let wnr = bufwinnr(bnr)
          let nrs = empty(nrs) ? [tnr, wnr] : nrs  " prefer first match
        endif
      endfor
    endfor
    let blank = !&modified && empty(bufname())
    let panel = &l:filetype =~# '^\(git\|netrw\)$'
    let fugitive = bufname() =~# '^fugitive:'
    if !empty(nrs)
      silent exe nrs[0] . 'tabnext' | silent exe nrs[1] . 'wincmd w'
    elseif !blank && !panel && !fugitive
      silent exe 'tabnew ' . fnameescape(path)
    else  " create new tab
      call feedkeys("\<Cmd>silent edit " . path . "\<CR>", 'n')
    end
    if !blank && !panel && !fugitive && abs !=# current
      call file#echo_path('path', path)
    endif
  endfor
endfunction

" Print current file or cursor file information
" Useful before using 'go to this local directory' mapping
function! file#show_cfile() abort
  let files = file#expand_cfile(1)
  if empty(files)
    echom "File or pattern '" . expand('<cfile>') . "' does not exist."
  else
    echom 'File(s) ' . join(map(files, 'string(v:val)'), ', ') . ' exist.'
  endif
endfunction
function! file#show_paths(...) abort
  let chars = ' *[]()?!#%&<>'
  let paths = a:0 ? a:000 : [@%]
  for path in paths
    let root = parse#get_root(path)
    let root = RelativePath(root)
    let show = RelativePath(path)
    let root = empty(root) ? fnamemodify(getcwd(), ':~:.') : root
    let work = fnamemodify(getcwd(), ':~')
    echom 'Path: ' . escape(show, chars)
    echom 'Project: ' . escape(root, chars)
    echom 'Session: ' . escape(work, chars)
  endfor
endfunction

" Manage file buffers
" NOTE: This is alternative to bufwipeout plugin.
" See: https://stackoverflow.com/a/7321131/4970632
" See: https://github.com/Asheq/close-buffers.vim
function! file#show_bufs() abort
  let ndigits = len(string(bufnr('$')))
  let result = {}
  let lines = []
  for bnr in tags#get_recents()  " buffers sorted by access time
    let pad = repeat(' ', ndigits - len(string(bnr)))
    let path = RelativePath(bufname(bnr), 1)
    call add(lines, pad . bnr . ': ' . path)
  endfor
  let message = "Open buffers (sorted by recent use):\n" . join(lines, "\n")
  echo message
endfunction
function! file#wipe_bufs()
  let nums = []
  for tnr in range(1, tabpagenr('$'))
    call extend(nums, tabpagebuflist(tnr))
  endfor
  let names = []
  for bnr in range(1, bufnr('$'))
    if bufexists(bnr) && !getbufvar(bnr, '&mod') && index(nums, bnr) == -1
      call add(names, bufname(bnr))
      silent exe 'bwipeout ' bnr
    endif
  endfor
  if !empty(names)
    echom 'Wiped out ' . len(names) . ' hidden buffer(s): ' . join(names, ', ')
  endif
endfunction

" Save, refresh, or rename the file
" NOTE: Here :Gedit returns to head after viewing a blob. Can also use e.g. :Mru
" to return but this is faster. See https://github.com/tpope/vim-fugitive/issues/543
" NOTE: Here file#rename adapated from Rename.vim. Avoids bug where cancelling the save
" in the confirmation prompt still triggers BufWritePost and b:tabline_filechanged, and
" prevents integration bug that triggers undefined b:gitgutter_was_enabled errors.
function! file#update() abort
  let tabline_changed = exists('b:tabline_filechanged') ? b:tabline_filechanged : 0
  let statusline_changed = exists('b:statusline_filechanged') ? b:statusline_filechanged : 0
  update  " only if unmodified
  if &l:modified && tabline_changed && !b:tabline_filechanged
    let b:tabline_filechanged = 1
  endif
  if &l:modified && statusline_changed && !b:statusline_filechanged
    let b:statusline_filechanged = 1
  endif
endfunction
function! file#reload() abort
  let type = get(b:, 'fugitive_type', '')
  if empty(type)  " edit from disk
    edit | call fold#update_folds(1, 1)
  elseif type ==# 'blob'  " return to file
    exe 'Gedit' | normal! zv
  else  " unknown
    redraw | echohl ErrorMsg | echom 'Error: Not in fugitive blob' | echohl None
  endif
endfunction
function! file#rename(name, bang)
  let b:gitgutter_was_enabled = get(b:, 'gitgutter_was_enabled', 0)
  let path1 = expand('%:p')
  let path2 = fnamemodify(path1, ':h') . '/' . a:name
  let v:errmsg = ''  " reset message
  try
    exe 'GMove' . a:bang . ' ' . path2
  catch /.*fugitive.*/
    silent! exe 'Move' . a:bang . ' ' . path2
    if v:errmsg !~# '^$\|^E329\|^E108' | throw v:errmsg | endif
  endtry
  let path = expand('%:p')  " resulting location
  if path !=# path1 && filewritable(path) && filewritable(path1)
    silent exe 'bwipe! ' . path1
    if !empty(delete(path1)) | throw 'Could not delete ' . path1 | endif
  endif
endfunction
