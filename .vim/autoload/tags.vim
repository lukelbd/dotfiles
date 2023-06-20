"-----------------------------------------------------------------------------"
" Utilities for ctags management
"-----------------------------------------------------------------------------"
" Update tags setting for whole project
" This makes fzf :Tags function and other utils search everything
function! tags#update() abort
  let paths = []
  for tnr in range(tabpagenr('$')) " iterate through each tab
    let tabnr = tnr + 1 " the tab number
    for bnr in tabpagebuflist(tabnr)
      let opts = getbufvar(bnr, 'gutentags_files', {})
      let path = get(opts, 'ctags', '')
      if !empty(path) && index(paths, path) == -1
        call add(paths, path)
      endif
    endfor
  endfor
  let &g:tags = join(paths, ',')
endfunction

" Parse .ignore files for ctags generation
" Note: This is actually only used to handle 'gutentags' ignore list but
" should be ported to bash and also used for 'qf()' and 'ff()' commands?
" Note: For some reason parsing '--exclude-exception' rules for g:fzf_tags_command
" does not work, ignores all other excludes, and vim-gutentags can only
" handle excludes anyway, so just bypass all patterns starting with '!'.
function! tags#ignores(join, ...) abort
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
