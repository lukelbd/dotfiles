"-----------------------------------------------------------------------------"
" Utilities for managing files
"-----------------------------------------------------------------------------"
" Helper functions
" Warning: For some reason including 'down' in fzf#run prevents fzf from returning
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
  for root in ['', getcwd(), expand('%:p:h'), parse#find_root(expand('%:p'))]
    let check = empty(root) ? path : root . '/' . path
    let files = glob(check, 0, 1)
    if !empty(files) | break | endif
  endfor
  return map(files, 'RelativePath(v:val, show)')
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

" Open recently edited file
" Note: This is companion to :History with nicer behavior. Files tracked
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
function! file#fzf_recent() abort
  let files = readfile(expand(g:MRU_file))
  if files[0] =~# '^#'
    call remove(files, 0)
  endif
  call map(files, 'RelativePath(v:val)')
  call fzf#run(fzf#wrap({
    \ 'sink': function('file#open_drop'),
    \ 'source' : files,
    \ 'options': '--no-sort --prompt="Global Hist> "',
    \ }))
endfunction

" Open input files
" Note: Must use expand() not glob() or new file names are not completed.
" Note: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
function! file#fzf_init(bang, global, level, cmd, ...) abort
  let paths = [] | call map(copy(a:000), 'extend(paths, expand(trim(v:val), 0, 1))')
  let paths = call('parse#get_paths', [2, a:global, 1 + a:level] + reverse(paths))
  let paths = reverse(paths)  " important paths at top instead of bottom
  let func = a:cmd ==# 'Files' ? 'file#fzf_files' : 'file#fzf_open'
  let args = a:cmd ==# 'Files' ? [a:bang] + paths : [a:bang, a:cmd, paths]
  return call(func, args)
endfunction
function! file#fzf_input(cmd, default, ...) abort
  let cmd = a:cmd ==# 'Drop' ? 'Open' : a:cmd  " alias 'Open' for 'Drop' command
  let input = file#input_path(cmd, '', a:default)
  if empty(input) | return | endif
  return file#fzf_init(cmd, input)
endfunction

" Open arbitrary files recursively
" Note: Try to preserve relative paths constructed by parse#get_paths(). Follows all
" symlinks, e.g. ~/.vimrc pointing to dotfiles, but keeps RelativePath() 'icloud'.
" Note: This is modeled after fzf :Files command. Used to search arbitrary files
" while respecting '.ignore' patterns used for e.g. f0/f1 commands.
function! file#fzf_files(bang, ...) abort
  " Parse input arguments
  let [bases, warns] = [[], []]
  for base in a:0 ? copy(a:000) : [getcwd()]
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
    if base =~# '^icloud'
      if empty(bases)  " icloud file
        let base = '~/' . base
      else  " repair e.g. 'icloud/Mackup/shell.sh'
        let base = RelativePath(expand('~/' . base), fnamemodify(bases[0], ':p'))
      endif
    endif
    call add(bases, base)
  endfor
  " Generate and select files
  if !empty(warns)
    let msg = join(map(warns, 'string(v:val)'), ', ')
    redraw | echohl WarningMsg
    echom 'Warning: Ignoring invalid directory path(s): ' . msg
    echohl None
  endif
  let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let flags = '-type d \( -name .git -o -name .svn -o -name .hg \) -prune -o '
  let flags .= join(parse#get_ignores(1, 1, 2), ' ')  " skip .gitignore, skip folders
  let flags .= ' -type f -print | sed ''s@^./@@'''  " remove leading dot
  let source = 'find . ' . join(bases[1:], ' ') . ' ' . flags
  let opts = fzf#vim#with_preview()
  let opts.dir = fnamemodify(bases[0], ':p')
  let prompt = file#format_dir(bases[0], 1)
  let prompt = string('Files> ' . prompt)
  let options = {
    \ 'sink*': function('file#fzf_open', [a:bang, 'Drop', bases[0]]),
    \ 'source': source,
    \ 'options': '--no-sort --prompt=' . prompt,
  \ }
  return call(snr . 'fzf', ['files', options, [opts, 0]])
endfunction

" Check if user selection is directory, descend until user selects a file.
" Note: Since fzf executes asynchronously cannot do loop recursion inside the driver
" function. See https://github.com/junegunn/fzf/issues/1577#issuecomment-492107554
function! file#fzf_open(bang, cmd, ...) abort
  " Parse arguments
  if a:0 == 1  " user invocation
    let base = ''
    let items = a:1
  else  " fzf invocation (ignore binding)
    let base = a:1
    let items = a:2[1:]
  endif
  if !exists(':' . get(split(a:cmd), 0, ''))
    redraw | echohl WarningMsg
    echom 'Error: Command ' . string(a:cmd) . ' not found.'
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
    let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
    if empty(snr) | return | endif
    let base = get(paths, 0, '.')
    let paths = []  " only continue in recursion
    let opts = fzf#vim#with_preview()
    let prompt = string(a:cmd . '> ' . file#format_dir(base, 1))
    let options = {
      \ 'sink*': function('file#fzf_open', [a:bang, a:cmd, base]),
      \ 'source': file#glob_files(base, 1),
      \ 'options': '--no-sort --prompt=' . prompt,
    \ }
    let options.dir = base
    call call(snr . 'fzf', ['open', options, [opts, 0]])
  endif
  " Open file(s), or if it is already open just to that tab
  " Note: Use feedkeys() if only one file selected or else template loading
  " on s:new_file selection will fail.
  let files = []
  for path in paths
    if isdirectory(path)  " false for empty string
      redraw | echohl WarningMsg
      echom 'Warning: Skipping directory ' . string(path) . '.'
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
    let root = parse#find_root(path)
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
" Note: This is alternative to bufwipeout plugin.
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
" Note: Here :Gedit returns to head after viewing a blob. Can also use e.g. :Mru
" to return but this is faster. See https://github.com/tpope/vim-fugitive/issues/543
" Note: Here file#rename adapated from Rename.vim. Avoids bug where cancelling the save
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
  if exists('*FugitiveGitDir') && !empty(FugitiveGitDir())
    silent! exe 'GMove' . a:bang . ' ' . path2
  else  " standard move
    silent! exe 'saveas' . a:bang . ' ' . path2
  endif
  if v:errmsg !~# '^$\|^E329\|^E108'
    throw v:errmsg
  endif
  let path = expand('%:p')  " resulting location
  if path !=# path1 && filewritable(path) && filewritable(path1)
    silent exe 'bwipe! ' . path1
    if !empty(delete(path1)) | throw 'Could not delete ' . path1 | endif
  endif
endfunction
