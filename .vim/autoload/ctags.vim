"-----------------------------------------------------------------------------"
" Utilities for ctags management
"-----------------------------------------------------------------------------"
" Search for the 'root' directory to store the ctags file
" Note: Root detectors are copied from g:gutentags_add_default_root_markers.
" Note: Previously tried just '__init__.py' for e.g. conda-managed packages and
" placing '.tagproject' in vim-plug folder but this caused tons of nested .vimtags
" file creations including *duplicate* tags when invoking :Tags function.
function! ctags#find_root(path) abort
  let names = ['.git', '.hg', '.svn', '.bzr', '_darcs', '_darcs', '_FOSSIL_', '.fslckout']
  let dists = ['__init__.py', 'setup.py', 'setup.cfg']
  let root = fnamemodify(resolve(expand(a:path)), ':p')
  let base = fnamemodify(root, ':h')
  while root !=# '' && root !=# '/'
    let root = fnamemodify(root, ':h')
    let head = fnamemodify(root, ':h')
    let init = split(globpath(root, '__init__.py'), "\n")
    let init_below = split(globpath(head, '__init__.py'), "\n")
    for name in names
      if !empty(split(globpath(root, name), "\n"))
        return root  " always respect distributions
      endif
    endfor
    for dist in dists
      if !empty(split(globpath(root, dist), "\n"))
        for name in names + dists
          if !empty(split(globpath(head, name), "\n"))
            return head  " e.g. site-packages folders
          endif
        endfor
      endif
    endfor
  endwhile
  return base
endfunction

" Parse .ignore files for ctags utilities (compare to bash ignores())
" Warning: Encountered strange error where naming .vim/autoload
" file same as vim-tags/autoload. So give this a separate name.
" Note: For some reason parsing '--exclude-exception' rules for g:fzf_tags_command
" does not work, ignores all other exclude flags, and vim-gutentags can only
" handle excludes anyway, so just bypass all patterns starting with '!'.
function! ctags#get_ignores(join, ...) abort
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
function! ctags#set_tags() abort
  let paths = []
  for tnr in range(tabpagenr('$')) " iterate through each tab
    let tabnr = tnr + 1 " the tab number
    for bnr in tabpagebuflist(tabnr)
      let opts = getbufvar(bnr, 'gutentags_files', {})
      let path = get(opts, 'ctags', '')
      if getcwd() =~# expand('~/') && expand(resolve(path)) !~# expand('~/')
        continue  " ignore individual files outside of home when inside home
      endif
      if getcwd() !~# expand('~/dotfiles') && expand(resolve(path)) =~# expand('~/dotfiles')
        continue  " ignore individual files in dotfiles when outside of dotfiles
      endif
      if !empty(path) && index(paths, path) == -1
        call add(paths, path)
      endif
    endfor
  endfor
  let &g:tags = join(paths, ',')
endfunction
