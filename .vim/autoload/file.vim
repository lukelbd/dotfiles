"-----------------------------------------------------------------------------"
" Utilities for managing files
"-----------------------------------------------------------------------------"
" Helper functions
" Warning: For some reason including 'down' in fzf#run prevents fzf from returning
" a list (version 0.29). However exluding it produces weird behavior that blacks
" out rest of screen. Workaround is to factor out an unnecessary source function.
let s:new_dir = ''  " path completion base folder
let s:new_file = '[new file]'  " fzf entry for requesting new file
function! file#echo_path(head, ...) abort
  let path = expand(a:0 ? a:1 : '%')
  let path = exists('*RelativePath') ? RelativePath(path) : fnamemodify(path, ':p:~:.')
  redraw | echom '' . substitute(a:head, '^\(\a\)\(\a*\)$', '\u\1\l\2', '') . ': ' . path
endfunction
function! file#format_dir(path, ...) abort
  let base = fnamemodify(a:path, ':p:~:.')  " note do not use RelativePath
  let base = a:0 && a:1 && base !~# '^[~.]*/\|^\w\+:' ? './' . base : base
  return substitute(base, '[^/]\@<=/*$', '/', '')
endfunction

" Generate list of files in directory
" Warning: Critical that the list options match the prompt lead or else
" when a single path is returned <Tab> during input() does not complete it.
function! file#glob_files(base, ...) abort
  let glob = substitute(fnamemodify(a:base, ':p'), '^\@!/\?$', '', '')
  let paths = globpath(glob, '*', 0, 1) + globpath(glob, '.?*', 0, 1)
  return extend(map(paths, "fnamemodify(v:val, ':t')"), a:0 && a:1 ? [s:new_file] : [])
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

" Print whether current file exists
" Useful when trying to debug 'go to this file' mapping
function! file#print_exists() abort
  let files = glob(expand('<cfile>'), 0, 1)
  if exists('*RelativePath')  " statusline function
    let files = map(files, 'RelativePath(v:val)')
  else
    let files = map(files, "fnamemodify(v:val, ':~:.')")
  endif
  if empty(files)
    echom "File or pattern '" . expand('<cfile>') . "' does not exist."
  else
    echom 'File(s) ' . join(map(files, '"''".v:val."''"'), ', ') . ' exist.'
  endif
endfunction

" Print current file information
" Useful before using 'go to this local directory' mapping
function! file#print_paths(...) abort
  let chars = ' *[]()?!#%&<>'
  let paths = a:0 ? a:000 : [@%]
  for path in paths
    let root = tag#find_root(path)
    if exists('*RelativePath')  " statusline function
      let root = RelativePath(root)
      let show = RelativePath(path)
    else
      let root = fnamemodify(root, ':~:.')
      let show = fnamemodify(path, ':~:.')
    endif
    let root = empty(root) ? fnamemodify(getcwd(), ':~:.') : root
    let work = fnamemodify(getcwd(), ':~')
    echom 'Path: ' . escape(show, chars)
    echom 'Project: ' . escape(root, chars)
    echom 'Session: ' . escape(work, chars)
  endfor
endfunction

" Open recently edited file
" Note: This is companion to :History with nicer behavior. Files tracked
" in ~/.vim_mru_files across different open vim sessions.
function! file#open_used() abort
  let files = readfile(expand(g:MRU_file))
  if files[0] =~# '^#'
    call remove(files, 0)
  endif
  if exists('*RelativePath')
    call map(files, 'RelativePath(v:val)')
  else
    call map(files, 'fnamemodify(v:val, ":~:.")')
  endif
  call fzf#run(fzf#wrap({
    \ 'sink': function('file#open_drop'),
    \ 'source' : files,
    \ 'options': '--no-sort --prompt="Global Hist> "',
    \ }))
endfunction

" Open from local or current directory (see also grep.vim)
" Note: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
function! file#setup_dir() abort
  call utils#switch_maps(['<CR>', 't', 'n'], ['t', '<CR>', 'n'])
  for char in 'fbFL' | silent! exe 'unmap <buffer> q' . char | endfor
endfunction
function! file#open_dir(cmd, local) abort
  let base = a:local ? fnamemodify(resolve(@%), ':p:h') : tag#find_root(@%)
  exe a:cmd . ' ' . base
  exe 'vert resize ' . window#default_width(1)
  exe 'resize ' . window#default_height(1) | goto
endfunction
function! file#open_init(cmd, local) abort
  let cmd = a:cmd ==# 'Drop' ? 'Open' : a:cmd  " alias 'Open' for 'Drop' command
  let path = resolve(expand('%:p'))
  let base = a:local ? fnamemodify(path, ':p:h') : tag#find_root(path)
  let init = file#input_path(cmd, '', base)
  if empty(init)
    return
  elseif cmd ==# 'Files'
    call fzf#vim#files(init, fzf#vim#with_preview(), 0)
  else
    call file#open_continuous(cmd, init)
  endif
endfunction

" Check if user selection is directory, descend until user selects a file.
" Note: Must use expand() not glob() or new file names are not completed. Also
" since fzf executes asynchronously cannot do loop recursion inside the driver
" function. See https://github.com/junegunn/fzf/issues/1577#issuecomment-492107554
function! file#open_continuous(cmd, ...) abort
  let paths = []
  for glob in a:000  " iterate input
    let glob = substitute(glob, '^\s*\(.\{-}\)\s*$', '\1', '')  " strip spaces
    call extend(paths, expand(glob, 0, 1))
  endfor
  call s:open_continuous(a:cmd, paths)  " call fzf sink function
endfunction
function! s:open_continuous(cmd, ...) abort
  " Parse arguments
  if a:0 == 1  " user invocation
    let base = ''
    let items = a:1
  else  " fzf invocation
    let base = a:1
    let items = a:2
  endif
  if !exists(':' . get(split(a:cmd), 0, ''))
    echohl WarningMsg
    echom "Error: Open command '" . a:cmd . "' not found."
    echohl None | return
  endif
  " Process paths input manually or from fzf
  let paths = []
  for item in items
    if item ==# s:new_file  " should be recursed at least one level
      try
        let item = file#input_path('File', expand('<cfile>'), base)
      catch /^Vim:Interrupt$/
        let item = ''  " avoid error message
      finally
        if !empty(item) | call add(paths, item) | endif
      endtry
    elseif item ==# '..'  " :p adds trailing slash so need two :h:h for parent
      call add(paths, fnamemodify(base, ':p:h:h'))
    elseif !empty(item)
      call add(paths, empty(base) ? item : base . '/' . item)
    endif
  endfor
  " Possibly activate or re-activate fzf
  if empty(paths) && a:0 == 1 || len(paths) == 1 && isdirectory(paths[0])
    let base = get(paths, 0, '.')
    let paths = []  " only continue in recursion
    call fzf#run(fzf#wrap({
      \ 'sink*': function('s:open_continuous', [a:cmd, base]),
      \ 'source': file#glob_files(base, 1),
      \ 'options': "--multi --no-sort --prompt='" . file#format_dir(base, 1) . "'",
      \ }))
  endif
  " Open file(s), or if it is already open just to that tab
  " Note: Use feedkeys() if only one file selected or else template loading
  " on s:new_file selection will fail.
  let files = []
  for path in paths
    if isdirectory(path)  " false for empty string
      echohl WarningMsg
      echom "Warning: Skipping directory '" . path . "'."
      echohl None
    elseif !empty(path) && path !~# '[*?[\]]'  " not unexpanded glob
      let icmd = a:cmd . ' ' . fnameescape(path)
      call feedkeys("\<Cmd>" . icmd . "\<CR>", 'n')
    endif
  endfor
  return files
endfunction

" Open file or jump to tab. From tab drop plugin: https://github.com/ohjames/tabdrop
" Warning: Using :edit without feedkeys causes issues navigating fugitive panels.
" Warning: The default ':tab drop' seems to jump to the last tab on failure and
" also takes forever. Also have run into problems with it on some vim versions.
function! file#open_drop(...) abort
  let current = expand('%:p')
  if a:0 && !type(a:1)
    let [quiet, paths] = [a:1, a:000[1:]]
  else
    let [quiet, paths] = [0, a:000]
  endif
  for path in paths
    let nrs = []  " tab and window number
    let abs = fnamemodify(path, ':p')
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
    call stack#update_tabs()  " update before leaving
    if !empty(nrs)
      silent exe nrs[0] . 'tabnext' | silent exe nrs[1] . 'wincmd w'
    elseif !blank && !panel && !fugitive
      silent exe 'tabnew ' . fnameescape(path)
    else  " create new tab
      call feedkeys("\<Cmd>silent edit " . path . "\<CR>", 'n')
    end
    if !quiet && !blank && !panel && !fugitive && abs !=# current
      call file#echo_path('path', path)
    endif
  endfor
endfunction

" Save or rename the file
" Note: Prevents vim bug where cancelling the save in the confirmation prompt still
" triggers BufWritePost and resets b:tabline_filechanged., and prevents Rename.vim
" integration bug that triggers undefined b:gitgutter_was_enabled errors.
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
function! file#rename(name, bang)
  let b:gitgutter_was_enabled = get(b:, 'gitgutter_was_enabled', 0)
  let v:errmsg = ''  " reset message
  let folder = expand('%:p:h')
  let path1 = expand('%:p')
  let path2 = folder . '/' . a:name
  silent! exe 'saveas' . a:bang . ' ' . path2
  if v:errmsg !~# '^$\|^E329\|^E108'
    throw v:errmsg
  endif
  if expand('%:p') !=# path1 && filewritable(expand('%:p'))
    silent exe 'bwipe! ' . path1
    if delete(path1) != 0
      throw 'Could not delete ' . path1
    endif
  endif
endfunction
