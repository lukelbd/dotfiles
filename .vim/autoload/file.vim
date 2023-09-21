"-----------------------------------------------------------------------------"
" Utilities for managing files
"-----------------------------------------------------------------------------"
" Helper functions and variables
" Warning: For some reason including 'down' in fzf#run prevents fzf from returning
" a list (version 0.29). However exluding it produces weird behavior that blacks
" out rest of screen. Workaround is to factor out an unnecessary source function.
let s:new_file = '[new file]'  " dummy entry for requesting new file in current directory

" Path and folder utility
" Print file information and whether file exists
function! file#print_exists() abort
  let files = glob(expand('<cfile>'), 0, 1)
  if exists('*RelativePath')
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
function! file#print_paths(...) abort
  let chars = ' *[]()?!#%&<>'
  let paths = a:0 ? a:000 : [@%]
  for path in paths
    let user = fnamemodify(path, ':~')
    let root = tag#find_root(path)
    if exists('*RelativePath')
      let root = RelativePath(root)
      let show = RelativePath(path)
    else
      let root = fnamemodify(root, ':~:.')
      let show = fnamemodify(path, ':~:.')
    endif
    let root = empty(root) ? fnamemodify(getcwd(), ':~:.') : root
    let work = fnamemodify(getcwd(), ':~')
    echom 'Current file: ' . escape(show, chars) . ' (' . escape(user, chars) . ')'
    echom 'Current project: ' . escape(root, chars)
    echom 'Current directory: ' . escape(work, chars)
  endfor
endfunction

" Generate list of files in directory
" Warning: Critical that the list options match the prompt lead or else
" when a single path is returned <Tab> during input() does not complete it.
function! s:path_source(dir, user) abort
  let paths = split(globpath(a:dir, '*'), "\n") + split(globpath(a:dir, '.?*'), "\n")
  let paths = map(paths, "fnamemodify(v:val, ':t')")
  if a:user | call insert(paths, s:new_file, 0) | endif
  return paths
endfunction
function! file#path_list(lead, line, cursor) abort
  let head = fnamemodify(a:lead, ':h')
  let tail = fnamemodify(a:lead, ':t')
  if head ==# '.'  " exclude leading component
    let paths = glob(tail . '*', 1, 1) + glob(tail . '.*', 1, 1)
  else  " include leading component
    let paths = globpath(head, tail . '*', 1, 1) + globpath(head, tail . '.*', 1, 1)
  endif
  let paths = filter(paths, "fnamemodify(v:val, ':t') !~# '^\\.\\+$'")
  let paths = map(paths, "isdirectory(v:val) ? v:val . '/' : v:val")
  return paths
endfunction

" Open from local or current directory (see also grep.vim)
" Note: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
function! file#init_path(files, local) abort
  let cmd = a:files ? 'Files' : 'Open'  " recursive fzf or non-resucrive internal
  let dir = a:local ? expand('%:p:h') : getcwd()  " neither has trailing slash
  let path = fnamemodify(dir, ':~')
  let prompt = cmd . ' (' . path . ')'  " display longer version in prompt
  let default = fnamemodify(dir, ':p:~:.')  " display shorter version here
  let default = empty(default) ? './' : default  " differentiate from user cancellation
  let start = utils#input_complete(prompt, 'file#path_list', default)
  if empty(start) | return | endif
  exe cmd . ' ' . start
endfunction

" Check if user selection is directory, descend until user selects a file.
" Warning: Must use expand() rather than glob() or new file names are not completed.
" Warning: FZF executes asynchronously so cannot do loop recursion inside driver
" function. See https://github.com/junegunn/fzf/issues/1577#issuecomment-492107554
function! file#open_continuous(open, ...) abort
  let paths = []
  for glob in a:000
    let glob = substitute(glob, '^\s*\(.\{-}\)\s*$', '\1', '')  " strip spaces
    call extend(paths, expand(glob, 0, 1))
  endfor
  call s:open_continuous(a:open, paths)  " call fzf sink function
endfunction
function! s:open_continuous(open, ...) abort
  " Parse arguments
  if a:0 == 1  " user invocation
    let base = ''
    let items = a:1
  else  " fzf invocation
    let base = a:1
    let items = a:2
  endif
  if !exists('*' . a:open) && !exists(':' . a:open)
    echohl WarningMsg
    echom "Error: Open command '" . a:open . "' not found."
    echohl None
    return
  endif
  " Process paths input manually or from fzf
  let paths = []
  for item in items
    let user = item ==# s:new_file
    if user  " should be recursed at least one level
      let item = input(fnamemodify(base, ':~:.') . '/', '', 'customlist,utils#null_list')
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
  if empty(paths) || len(paths) == 1 && isdirectory(paths[0])
    let base = empty(paths) ? '.' : paths[0]
    let base = fnamemodify(base, ':p')  " full directory name
    let base = substitute(base, '/$', '', '')  " remove trailing slash
    let trunc = fnamemodify(base, ':~:.')  " remove unnecessary stuff
    let trunc = trunc[:1] =~# '/' ? trunc : './' . trunc
    let paths = []  " only continue in recursion
    call fzf#run(fzf#wrap({
      \ 'source': s:path_source(base, 1),
      \ 'sinklist': function('s:open_continuous', [a:open, base]),
      \ 'options': "--multi --no-sort --prompt='" . trunc . "/'",
      \ }))
  endif
  " Open file(s), or if it is already open just to that tab
  for path in paths
    if isdirectory(path)  " false for empty string
      echohl WarningMsg
      echom "Warning: Skipping directory '" . path . "'."
      echohl None
    elseif empty(path) || path =~# '[*?[\]]'  " unexpanded glob
      :
    elseif exists(':' . a:open)  " e.g. vsplit or split
      exe a:open . ' ' . path
    else  " e.g. file#open_drop
      call call(a:open, [path])
    endif
  endfor
endfunction

" Open file or jump to tab. From tab drop plugin: https://github.com/ohjames/tabdrop
" Warning: The default ':tab drop' seems to jump to the last tab on failure and
" also takes forever. Also have run into problems with it on some vim versions.
function! file#open_drop(...) abort
  for path in a:000
    for tnr in range(1, tabpagenr('$'))  " iterate through each tab
      for bnr in tabpagebuflist(tnr)
        if expand('#' . bnr . ':p') ==# fnamemodify(path, ':p')
          let wnr = bufwinnr(bnr)
          exe tnr . 'tabnext'
          exe wnr . 'wincmd w'
          return
        endif
      endfor
    endfor
    if bufname('%') ==# '' && &modified == 0  " fill this window
      exec 'edit ' . path
    else  " create new tab
      exec 'tabnew ' . path
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
