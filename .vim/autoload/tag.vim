"-----------------------------------------------------------------------------"
" Utilities for ctags management
"-----------------------------------------------------------------------------"
" Iterate over tags (see also mark#next_mark)
" Todo: Consider adding 'tag stack search' fzf command or supporting navigation
" across 'from' position throughout stack instead of just at the bottom of stack.
function! tag#next_stack(...) abort
  let cnt = a:0 ? a:1 : v:count1
  let name = get(g:, 'tag_name', [])  " see also mark#next_mark()
  let iloc = get(g:, 'tag_loc', 0)
  let ilen = len(get(g:, 'tag_stack', []))
  let itag = get(name, 2, '')
  let ctag = tags#find_tag(line('.'))
  let pseudo = '<top>'  " pseudo-tag for top of stack
  let current = !empty(itag) && itag ==# get(ctag, 0, '')
  if cnt < 0 && ilen > 0 && iloc >= ilen - 1 && !current
    if itag ==# pseudo | call stack#pop_stack('tag', name) | endif  " remove previous
    let name = [expand('%:p'), [line('.'), col('.')], pseudo]
    let g:tag_name = name  " push_stack() adds this to the stack
    call stack#push_stack('tag', '', '', 0)
  endif
  if !empty(name)  " see also mark.vim
    let [pos1, pos2] = [get(name, 1, 0), [line('.'), col('.')]]
    let cursor = type(pos1) <= 1 ? pos1 == pos2[0] : pos1 == pos2
    let ignore = current || itag ==# pseudo && iloc >= ilen - 1 && cnt >= 0
    if !cursor && !ignore  " drop <from> tag below
      let offset = cnt > 0 ? -1 : 1
      if abs(cnt) <= 1  " note this also resets <from>
        call call('tags#iter_tag', [1] + name)
      else  " suppress message
        silent call call('tags#iter_tag', [1] + name)
      endif
      let cnt += offset
    endif
  endif
  return stack#push_stack('tag', function('tags#iter_tag', [cnt]), cnt)
endfunction

" Select from tags in the current window stack
" Note: This finds tag kinds using taglist() and ignores missing files.
" See: https://github.com/junegunn/fzf.vim/issues/240
function! tag#fzf_stack() abort
  let items = []
  let itags = gettagstack(win_getid())
  for item in get(itags, 'items', [])  " search tag stack
    let iname = item.tagname
    let ipath = expand('#' . item.bufnr . ':p')
    if !filereadable(ipath) | continue | endif
    call extend(items, taglist(iname, ipath))
  endfor
  let paths = map(copy(items), 'v:val.filename')
  let level = len(uniq(sort(paths))) > 1 ? 2 : 0
  if level > 0
    let expr = '[v:val.filename, v:val.cmd, v:val.name, v:val.kind]'
  else
    let expr = '[v:val.cmd, v:val.name, v:val.kind]'
  endif
  let opts = map(copy(items), expr)
  return tags#select_tag(level, opts, 1)
endfunction

" Override fzf :Btags and :Tags
" Note: This is similar to fzf except uses custom sink that adds results to window
" tag stack for navigation with ctrl-bracket maps and tag/pop commands.
function! tag#fzf_btags(query, ...) abort
  let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let args = copy(a:000)
  let cmd = 'ctags -f - --sort=yes --excmd=number %s 2>/dev/null | sort -s -k 5'
  let cmd = printf(cmd, fzf#shellescape(expand('%')))
  let flags = "-m -d '\t' --with-nth 1,4.. -n 1 --layout=reverse-list"
  let flags .= ' --preview-window +{3}-/2 --query ' . shellescape(a:query)
  let options = {
    \ 'source': call(snr . 'btags_source', [[cmd]]),
    \ 'sink': function('tags#push_tag', [0]),
    \ 'options': flags . ' --prompt "BTags> "',
  \ }
  return call(snr . 'fzf', ['btags', options, a:000])
endfunction
function! tag#fzf_tags(query, ...) abort
  if !executable('perl')
    echohl ErrorMsg | echom 'Error: Tags command requires perl' | echohl None | return
  endif
  let cmd = expand('~/.vim/plugged/fzf.vim/bin/tags.pl')
  let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let paths = map(tagfiles(), 'fnamemodify(v:val, ":p")')
  let [nbytes, maxbytes] = [0, 1024 * 1024 * 200]
  for path in paths
    let nbytes += getfsize(path)
    if nbytes > maxbytes | break | endif
  endfor
  let flags = "-m -d '\t' --nth 1..2 --tiebreak=begin"
  let flags .= nbytes > maxbytes ? ' --algo=v1' : ''
  let args = map([a:query] + paths, 'fzf#shellescape(v:val)')
  let options = {
    \ 'source': join(['perl', fzf#shellescape(cmd)] + args, ' '),
    \ 'sink': function('tags#push_tag'),
    \ 'options': flags . ' --prompt "Tags> "',
  \ }
  return call(snr . 'fzf', ['tags', options, a:000])
endfunction

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
  let paths = copy(a:000)
  if empty(paths)
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
  return a:join ? join(ignores, ' ') : ignores
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
