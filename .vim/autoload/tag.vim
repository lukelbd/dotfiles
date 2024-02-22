"-----------------------------------------------------------------------------"
" Utilities for ctags management
"-----------------------------------------------------------------------------"
" Search for the 'root' directory to store the ctags file
" Note: Root detectors are copied from g:gutentags_add_default_root_markers.
" Note: Previously tried just '__init__.py' for e.g. conda-managed packages and
" placing '.tagproject' in vim-plug folder but this caused tons of nested .vimtags
" file creations including *duplicate* tags when invoking :Tags function.
function! s:get_root(folder, globs, ...) abort
  let reverse = a:0 ? a:1 : 0
  let root = fnamemodify(a:folder, ':p')
  let home = expand('~')
  let roots = []
  while !empty(root) && root !=# '/'
    let root = fnamemodify(root, ':h')
    if root !=# home[:len(root) - 1]  " skip home or above
      call add(roots, root)
    endif
  endwhile
  for root in reverse ? reverse(roots) : roots
    for glob in a:globs
      if !empty(globpath(root, glob, 0, 1))
        return root
      endif
    endfor
  endfor
  return ''
endfunction
function! tag#find_root(path) abort
  let folder = fnamemodify(resolve(expand(a:path)), ':p:h')
  let globs = ['.git', '.hg', '.svn', '.bzr', '_darcs', '_darcs', '_FOSSIL_', '.fslckout']
  let root = s:get_root(folder, globs)  " highest-level control system indicator
  if !empty(root)
    return root
  endif
  let globs = ['__init__.py', 'setup.py', 'setup.cfg']
  let root = s:get_root(folder, globs, 1)  " lowest-level python distribution indicator
  if !empty(root)
    return root
  endif
  let home = expand('~')
  let root = folder ==# home[:len(folder) - 1] ? folder . '/dotfiles' : folder
  return root
endfunction

" Parse .ignore files for ctags utilities (compare to bash ignores())
" Warning: Encountered strange error where naming .vim/autoload
" file same as vim-tags/autoload. So give this a separate name.
" Note: For some reason parsing '--exclude-exception' rules for g:fzf_tags_command
" does not work, ignores all other exclude flags, and vim-gutentags can only
" handle excludes anyway, so just bypass all patterns starting with '!'.
function! tag#parse_ignores(join, ...) abort
  if a:0 && !empty(a:1) " input path
    let paths = [a:1]
  else
    let project = split(system('git rev-parse --show-toplevel'), "\n")
    let suffix = empty(project) ? [] : [project[0] . '/.gitignore']
    let paths = ['~/.ignore', '~/.wildignore', '~/.gitignore'] + suffix
  endif
  let ignores = []
  for path in paths
    let path = resolve(expand(path))
    if filereadable(path)
      for line in readfile(path)
        if line =~# '^\s*\(#.*\)\?$'
          continue
        elseif line[:0] ==# '!'
          continue
        elseif a:join
          let ignore = "--exclude='" . line . "'"
        else
          let ignore = line
        endif
        call add(ignores, ignore)
      endfor
    endif
  endfor
  let ignores = uniq(ignores)  " .ignore and .gitignore are often duplicates
  let ignores = a:join ? join(ignores, ' ') : ignores
  return ignores
endfunction

" Update tags variable (requires g:gutentags_ctags_auto_set_tags = 0)
" This is hooked up to the gutentags tag-updating autocommand, makes fzf :Tags
" function and native :tags features use all projects instead of just the current
" project. Also ignores 'dotfiles' project unless the working directory is in dotfiles
" since very common to open simple config files from other projects e.g. 'proplotrc'.
" Note: Vim resolves all symlinks so unfortunately cannot just commit to using
" the symlinked $HOME version in other projects. Resolve below for safety.
function! tag#update_paths(...) abort
  let bufs = []  " source buffers
  let paths = []  " tag paths
  if a:0  " append to existing
    let args = copy(a:000[empty(type(a:1)):])
    let toggle = empty(type(a:1)) ? a:1 : 1  " type zero i.e. number (see :help empty)
    call extend(bufs, map(args, 'bufnr(v:val)'))
  else  " reset defaults
    setglobal tags=
    let toggle = 1
    call map(range(1, tabpagenr('$')), 'extend(bufs, tabpagebuflist(v:val))')
  endif
  for bnr in bufs  " possible iteration
    let opts = getbufvar(bnr, 'gutentags_files', {})
    let path = get(opts, 'ctags', '')
    if empty(path)
      continue  " invalid path
    endif
    if getcwd() !~# expand('~/dotfiles') && expand(resolve(path)) =~# expand('~/dotfiles')
      continue  " ignore individual files in dotfiles when outside of dotfiles
    endif
    if getcwd() =~# expand('~/') && expand(resolve(path)) !~# expand('~/')
      continue  " ignore individual files outside of home when inside home
    endif
    if toggle  " append path
      exe 'setglobal tags+=' . fnameescape(path)
    else  " remove path
      exe 'setglobal tags-=' . fnameescape(path)
    endif
  endfor
endfunction
