"-----------------------------------------------------------------------------"
" Utilities for managing files
"-----------------------------------------------------------------------------"
" Helper functions and variables
" Warning: For some reason including 'down' in fzf#run prevents fzf from returning
" a list (version 0.29). However exluding it produces weird behavior that blacks
" out rest of screen. Workaround is to factor out an unnecessary source function.
let s:new_file = '[new file]'  " dummy entry for requesting new file in current directory

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
    echom 'Current file: ' . escape(show, chars)
    echom 'Current project: ' . escape(root, chars)
    echom 'Current directory: ' . escape(work, chars)
  endfor
endfunction

" Generate list of files in directory
" Warning: Critical that the list options match the prompt lead or else
" when a single path is returned <Tab> during input() does not complete it.
function! s:path_source(base, user) abort
  let glob = fnamemodify(a:base, ':p')  " full directory name
  let glob = substitute(glob, '/$', '', '')  " remove trailing slash
  let paths = globpath(glob, '*', 0, 1) + globpath(glob, '.?*', 0, 1)
  let paths = map(paths, "fnamemodify(v:val, ':t')")
  if a:user  " user input
    call insert(paths, s:new_file, 0)
  endif
  return paths
endfunction
function! s:path_complete(lead) abort
  let head = fnamemodify(a:lead, ':h')
  let tail = fnamemodify(a:lead, ':t')
  if empty(head) || head ==# '.'  " exclude leading component
    let paths = glob(tail . '*', 1, 1) + glob(tail . '.*', 1, 1)
  else  " include leading component
    let paths = globpath(head, tail . '*', 1, 1) + globpath(head, tail . '.*', 1, 1)
  endif
  let paths = filter(paths, 'fnamemodify(v:val, '':t'') !~# ''^\.\+$''')
  let paths = map(paths, 'isdirectory(v:val) ? v:val . ''/'' : v:val')
  return map(paths, 'substitute(v:val, ''^\.\/'', '''', '''')')
endfunction
function! file#complete_lwd(lead, line, cursor) abort
  if exists('*RelativePath')
    let head = RelativePath(expand('%:h'))
  else
    let head = expand('%:h:~:.')
  endif
  if head =~# '^' . a:lead
    return s:path_complete(head)
  else
    return s:path_complete(a:lead)
  endif
endfunction
function! file#complete_cwd(lead, line, cursor) abort
  return s:path_complete(a:lead)
endfunction

" Open recently edited file
" Note: This is companion to :History with nicer behavior. Files tracked
" in ~/.vim_mru_files across different open vim sessions.
function! file#open_recent() abort
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
    \ 'sink': function('s:open_recent_sink'),
    \ 'source' : files,
    \ 'options': '--no-sort --prompt="Global Hist> "',
    \ }))
endfunction
function! s:open_recent_sink(path) abort
  exe 'Drop ' . a:path
endfunction

" Open from local or current directory (see also grep.vim)
" Note: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
function! file#open_head(path) abort
  let prompt = fnamemodify(a:path, ':p:~:.')  " note do not use RelativePath
  let prompt = prompt[:1] ==# '/' ? prompt : './' . prompt
  let prompt = substitute(prompt, '/$', '', '') . '/'
  return prompt
endfunction
function! file#open_init(cmd, local) abort
  let cmd = a:cmd ==# 'Drop' ? 'Open' : a:cmd  " recursive fzf or non-resucrive internal
  let base = a:local ? fnamemodify(resolve(@%), ':p:h') : tag#find_root(@%)
  let init = utils#input_default(cmd, 'file#complete_cwd', file#open_head(base))
  if empty(init)
    return
  elseif cmd ==# 'Files'
    call fzf#vim#files(init, fzf#vim#with_preview(), 0)
  else
    call file#open_continuous(cmd, init)
  endif
endfunction

" Check if user selection is directory, descend until user selects a file.
" Warning: Must use expand() rather than glob() or new file names are not completed.
" Warning: FZF executes asynchronously so cannot do loop recursion inside driver
" function. See https://github.com/junegunn/fzf/issues/1577#issuecomment-492107554
function! file#open_continuous(cmd, ...) abort
  let paths = []
  for glob in a:000
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
  if !exists(':' . a:cmd)
    echohl WarningMsg
    echom "Error: Open command '" . a:cmd . "' not found."
    echohl None
    return
  endif
  " Process paths input manually or from fzf
  let paths = []
  for item in items
    let user = item ==# s:new_file
    if user  " should be recursed at least one level
      let item = input(file#open_head(base), '', 'customlist,utils#null_list')
    endif
    let item = substitute(item, '\s', '\ ', 'g')
    if item ==# '..'  " :p adds a slash so need two :h:h to remove then
      call add(paths, fnamemodify(base, ':p:h:h'))
    elseif !empty(item)
      call add(paths, empty(base) ? item : base . '/' . item)
    elseif user
      call add(paths, base)
    endif
  endfor
  " Possibly activate or re-activate fzf
  if empty(paths) && a:0 == 1 || len(paths) == 1 && isdirectory(paths[0])
    let base = empty(paths) ? '.' : paths[0]
    let paths = []  " only continue in recursion
    call fzf#run(fzf#wrap({
      \ 'sink*': function('s:open_continuous', [a:cmd, base]),
      \ 'source': s:path_source(base, 1),
      \ 'options': "--multi --no-sort --prompt='" . file#open_head(base) . "'",
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
" Warning: The default ':tab drop' seems to jump to the last tab on failure and
" also takes forever. Also have run into problems with it on some vim versions.
function! file#open_drop(...) abort
  for path in a:000
    let abspath = fnamemodify(path, ':p')
    for tnr in range(1, tabpagenr('$'))  " iterate through each tab
      for bnr in tabpagebuflist(tnr)
        if expand('#' . bnr . ':p') ==# abspath
          let wnr = bufwinnr(bnr)
          exe tnr . 'tabnext'
          exe wnr . 'wincmd w'
          return
        endif
      endfor
    endfor
    let fugitive = &l:filetype ==# 'git' || bufname() =~# '^fugitive:'
    let blank = !&modified && empty(bufname())
    if blank || fugitive
      exe 'edit ' . path
    else  " create new tab
      exe 'tabnew ' . path
    end
  endfor
endfunction

" Rename2.vim  -  Rename a buffer within Vim and on disk
" Copyright July 2009 by Manni Heumann <vim at lxxi.org> based on Rename.vim
" Note: Ignore missing 'b:gitgutter_was_enabled' error
function! file#rename(name, bang)
  let b:gitgutter_was_enabled = get(b:, 'gitgutter_was_enabled', 0)
  let curfile = expand('%:p')
  let curfilepath = expand('%:p:h')
  let newname = curfilepath . '/' . a:name
  let v:errmsg = ''
  silent! exe 'saveas' . a:bang . ' ' . newname
  if v:errmsg =~# '^$\|^E329\|^E108'
    if expand('%:p') !=# curfile && filewritable(expand('%:p'))
      silent exe 'bwipe! ' . curfile
      if delete(curfile) != 0
        throw 'Could not delete ' . curfile
      endif
    endif
  else
    throw v:errmsg
  endif
endfunction

" Update the file
" Note: Prevents vim bug where cancelling the save in the confirmation
" prompt still triggers BufWritePost and resets b:tabline_filechanged.
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
