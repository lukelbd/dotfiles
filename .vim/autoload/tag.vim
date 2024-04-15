"-----------------------------------------------------------------------------"
" Utilities for ctags management
"-----------------------------------------------------------------------------"
" Tag source functions
" Warning: Encountered strange error where naming .vim/autoload
" file same as vim-tags/autoload. So give this a separate name.
" Note: This matches fzf.vim/bin/tags.pl perl script formatting, but adds optional
" filetype filter (see vim-tags). Note removing vim quotes causes viewer to fail.
let s:cache = {}
function! s:tag_format(line, path) abort
  let regex = '\=printf("%-24s", submatch(0))'
  let text = substitute(a:line, '^[^\t]*', regex, '')
  return text . "\t" . a:path
endfunction
function! s:tag_match(line, ftype, regex, fast) abort
  let tagline = '^[^\t]*\t\([^\t]*\)\t.*$'
  if a:line =~# '^\s*!' | return 0 | endif
  if empty(a:ftype) | return 1 | endif
  let path = substitute(a:line, tagline, '\1', 'g')
  return tags#type_match(path, a:ftype, a:regex, s:cache, a:fast)
endfunction
function! tag#show_cache() abort
  echom 'File type cache (' . len(s:cache) . ' entries):'
  let paths = {}
  let names = map(copy(s:cache), {key, val -> RelativePath(key)})
  for path in keys(names) | let paths[names[path]] = path | endfor
  let size = 1 + max(map(keys(paths), 'len(v:val)'))
  for name in sort(keys(paths))
    let tail = s:cache[paths[name]]
    if empty(tail) | continue | endif
    let head = printf('%-' . size . 's', name . ':')
    echom head . ' ' . tail
  endfor
endfunction
function! tag#read_tags(type, query, ...) abort
  let cmd = 'readtags -t %s -e -p - ' . fzf#shellescape(a:query)
  if empty(a:type)
    let [ftype, regex] = ['', '']
  elseif type(a:type)
    let [ftype, regex] = [a:type, tags#type_regex(a:type)]
  else
    let [ftype, regex] = [&l:filetype, tags#type_regex()]
  endif
  let result = []
  for path in a:000
    if empty(a:query)
      let lines = readfile(path)
    else
      let lines = systemlist(printf(cmd, fzf#shellescape(path)))
    endif
    let fast = !empty(ftype) && index(values(s:cache), ftype) >= 0
    let lines = filter(lines, {idx, val -> s:tag_match(val, ftype, regex, fast)})
    let lines = map(lines, {idx, val -> s:tag_format(val, path)})
    call extend(result, lines)
  endfor
  return result
endfunction

" Return the 'from' position for the given path and tag
" Note: This only jumps if the destination 'from' line contains the tag (i.e. not
" jumping to an outdated position or from a random fzf call) or when at the bottom.
function! tag#from_stack(arg, name, ...) abort
  let path = expand('%:p')
  let wins = type(a:arg) ? win_findbuf(bufnr(a:arg)) : [a:arg]
  let stack = gettagstack(get(wins, 0, winnr()))
  for item in get(stack, 'items', [])  " search tag stack
    let iname = item.tagname
    let ipath = expand('#' . item.bufnr . ':p')
    if ipath !=# path | continue | endif
    if iname !=# a:name | continue | endif
    if !has_key(item, 'from') | continue | endif
    let [bnr, lnum, cnum, onum] = item.from
    let bnr = empty(bnr) ? bufnr() : bnr
    let text = get(getbufline(bnr, lnum), 0, '')
    if a:0 && a:1 || text =~# escape(iname, '[]\.*$~')
      return [bnr, lnum, cnum, onum]
    endif
  endfor | return []
endfunction

" Go to the current tag location and adjust the count
" Note: This adds a pseudo-tag <top> at the top of the stack so we can return to
" where we started when scrolling backwards, and pushes <top> if cursor is outside
" both 'from' and 'tag' buffers or inside the 'tag' buffer but outside its bounds.
function! s:goto_iloc(path, line, name, ...) abort  " see also mark.vim
  let [iloc, size] = stack#get_loc('tag')
  let tname = a:name  " current tag name
  let path = fnamemodify(a:path, ':p')
  let cnt = a:0 ? a:1 : v:count1
  let fpos = tag#from_stack(path, a:name, iloc == 0)  " stack from position
  let cpos = [bufnr()] + slice(getpos('.'), 1)
  let apos = type(a:line) > 1 ? copy(a:line) : [a:line]
  let tpos = [bufnr(path)] + map(apos, 'str2nr(v:val)')
  let atag = [tpos[0]] + tags#find_tag(tpos[:1])  " argument [buf name line kind]
  let ctag = [bufnr()] + tags#find_tag(line('.'))  " cursor [buf name line kind]
  let outside = !empty(fpos) && fpos[:1] != cpos[:1] && ctag != atag
  if cnt < 0 && size > 1 && iloc >= size - 1 && outside  " add <top> pseudo-tag
    let tname = '<top>'  " updated tag name
    let item = [expand('%:p'), [line('.'), col('.')], tname]
    let g:tag_name = item  " push_stack() adds to top of stack
    call stack#push_stack('tag', '', '', 0)
  endif
  let ipos = cnt < 0 ? fpos : tpos
  let outside = ipos != slice(cpos, 0, len(ipos))
  if !empty(ipos)  && tname !=# '<top>' && outside
    if len(ipos) > 2  " exact position
      silent call file#open_drop(ipos[0]) | call call('cursor', ipos[1:])
    else  " automatic position
      silent call tags#jump_tag(2, a:path, a:line, a:name)
    endif
    let noop = cnt < 0 ? cpos[:1] == ipos[:1] : ctag == atag   " ignore from count
    let cnt += noop ? 0 : cnt < 0 ? 1 : -1  " possibly adjust count
  endif
  return cnt
endfunction

" Iterate over tags (see also mark#next_mark)
" Note: This implicitly adds 'current' location to top of stack before navigation,
" and additionally jumps to the tag stack 'from' position when navigating backwards.
function! tag#next_stack(...) abort
  let item = stack#get_item('tag')
  let item = empty(item) ? [] : item
  let [iloc, size] = stack#get_loc('tag')
  let cnt = a:0 ? a:1 : v:count1
  if iloc >= size - 1 && get(item, 2, '') ==# '<top>'
    call stack#pop_stack('tag', item)
    let [iloc, size] = stack#get_loc('tag')
    let item = stack#get_item('tag')
    let item = empty(item) ? [] : item
  endif
  if !empty(item)  " jump to 'current' tag (see also mark.vim)
    let cnt = s:goto_iloc(item[0], item[1], item[2], cnt)
  endif
  if cnt == 0  " push currently assigned name to stack
    call stack#push_stack('tag', '', 0, 2)
  else  " iterate stack then pass to tag jump function
    call stack#push_stack('tag', function('tags#jump_tag', [cnt < 0 ? -1 : 1]), cnt)
  endif
  let item = stack#get_item('tag')
  if cnt < 0 && !empty(item)  " mimic :pop behavior
    let [iloc, _] = stack#get_loc('tag')
    let pos = tag#from_stack(item[0], item[2], iloc == 0)
    let pos = empty(pos) ? getpos('.') : pos
    if pos[0] | silent call file#open_drop(pos[0]) | endif
    call call('cursor', pos[1:])
  endif
  if &l:foldopen =~# '\<tag\>' | exe 'normal! zv' | endif
endfunction

" Select from tags in the current window stack
" Note: This finds tag kinds using taglist() and ignores missing files.
" See: https://github.com/junegunn/fzf.vim/issues/240
function! tag#fzf_stack() abort
  let items = []
  for item in get(g:, 'tag_stack', [])  " jumping tag stack
    let ipath = item[0]
    if !filereadable(ipath) | continue | endif
    call extend(items, tags#get_tags(item[2], item[0], 1))
  endfor
  let stack = gettagstack(win_getid())
  for item in get(stack, 'items', [])  " window tag stack
    let ipath = expand('#' . item.bufnr . ':p')
    if !filereadable(ipath) | continue | endif
    call extend(items, tags#get_tags(item.tagname, ipath, 1))  " infer kind from stack
  endfor
  let paths = map(copy(items), 'v:val.filename')
  let level = len(uniq(sort(paths))) > 1 ? 2 : 0
  if level > 0
    let expr = '[v:val.filename, v:val.cmd, v:val.name, v:val.kind]'
  else
    let expr = '[v:val.cmd, v:val.name, v:val.kind]'
  endif
  let opts = map(copy(items), expr)
  if !empty(opts)
    call tags#select_tag(level, reverse(opts), 1)
  else
    redraw | echohl WarningMsg
    echom 'Error: Tag stack is empty'
    echohl None
  endif
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
  let flags = "-m -d '\t' --with-nth 1,4.. --nth 1"
  let flags .= ' --preview-window +{3}-/2 --query ' . shellescape(a:query)
  let options = {
    \ 'source': call(snr . 'btags_source', [[cmd]]),
    \ 'sink': function('tags#push_tag', [0]),
    \ 'options': flags . ' --prompt "BTags> "',
  \ }
  return call(snr . 'fzf', ['btags', options, a:000])
endfunction
function! tag#fzf_tags(type, query, ...) abort
  let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let paths = map(tags#get_files(), 'fnamemodify(v:val, ":p")')
  let [nbytes, maxbytes] = [0, 1024 * 1024 * 200]
  for path in paths
    let nbytes += getfsize(path)
    if nbytes > maxbytes | break | endif
  endfor
  let flags = "-m -d '\t' --with-nth ..4 --nth ..2"
  let flags .= nbytes > maxbytes ? ' --algo=v1' : ''
  let prompt = empty(a:type) ? 'Tags> ' : 'FTags> '
  let source = call('tag#read_tags', [a:type, a:query] + paths)
  let options = {
    \ 'source': source,
    \ 'sink': function('tags#push_tag', [0]),
    \ 'options': flags . ' --prompt ' . string(prompt),
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
function! tag#find_root(path, ...) abort
  let folder = fnamemodify(resolve(expand(a:path)), ':p:h')  " no trailing slash
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
  let cloud = resolve(home . '/icloud')
  for base in [cloud, home]  " WARNING: order is critical
    if base ==# folder
      let tail = base ==# home ? 'dotfiles' : 'Mackup'
      return base . '/' . tail
    elseif len(base) < len(folder) && base ==# strpart(folder, 0, len(base))
      let mods = repeat(':h', count(folder, '/') - count(base, '/') - 1)
      return fnamemodify(folder, mods)
    endif
  endfor
  return folder
endfunction

" Parse .ignore files for ctags utilities (compare to bash ignores())
" Note: Critical to remove trailing slash for ctags recursive searching.
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
        let line = substitute(line, '\/\s*$', '', '')
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
    if empty(path) || !filewritable(resolve(path))
      continue  " invalid path
    endif
    if toggle  " append path
      exe 'setglobal tags+=' . fnameescape(path)
    else  " remove path
      exe 'setglobal tags-=' . fnameescape(path)
    endif
  endfor
endfunction
