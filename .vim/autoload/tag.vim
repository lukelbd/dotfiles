"-----------------------------------------------------------------------------"
" Utilities for ctags management
"-----------------------------------------------------------------------------"
" Helper formatting functions
" Note: Encountered bug when naming this same as vim-tags (plural).
" Note: Formatting with more complex regex can cause slowdown. Avoid complex
" regex patterns e.g. extra globs and non-greedy globs.
scriptencoding utf-8
let s:type_cache = {}
let s:regex_tag1 = '^\([^\t]*\)\(.*\)$'
let s:regex_tag2 = '^\([^\t]*\)\t\([^\t]*\)\(.*\)$'
function! s:tag_trunc(name, size) abort
  let name = a:name | if strchars(name) > a:size
    let name = strcharpart(name, 0, a:size - 1) . '·'
  endif | return printf('%-' . a:size . 's', name)
endfunction
function! s:tag_fmt1(size, ...) abort  " see fzf.vim/bin/tagpreview.sh
  let name = s:tag_trunc(trim(submatch(1)), a:size)
  let append = a:0 ? "\t" . a:1 . '.vimtags' : ''
  return name . submatch(2) . append
endfunction
function! s:tag_fmt2(size, head, base, cache) abort
  let name = s:tag_trunc(trim(submatch(1)), a:size)
  let path = a:base . submatch(2)  " submatch with base
  let a:cache[trim(path)] = a:head  " efficient cache (avoid huge string table)
  return name . "\t" . path . submatch(3) . "\t" . a:head . '.vimtags'
endfunction
function! s:tag_filter(line, ftype, regex, fast) abort
  if a:line =~# '^\s*!\|^\s*\d\+\>' | return 0 | endif
  if empty(a:ftype) | return 1 | endif
  let path = substitute(a:line, s:regex_tag2, '\2', 'g')
  return tags#type_match(path, a:ftype, a:regex, s:type_cache, a:fast)
endfunction
function! tag#show_cache() abort
  echom 'File type cache (' . len(s:type_cache) . ' entries):'
  let paths = {}
  let names = map(copy(s:type_cache), {key, val -> RelativePath(key)})
  for path in keys(names) | let paths[names[path]] = path | endfor
  let size = 1 + max(map(keys(paths), 'len(v:val)'))
  for name in sort(keys(paths))
    let tail = s:type_cache[paths[name]]
    if empty(tail) | continue | endif
    let head = printf('%-' . size . 's', name . ':')
    echom head . ' ' . tail
  endfor
endfunction

" Tag source functions
" Note: This matches fzf.vim/bin/tags.pl perl script formatting, but adds optional
" filetype filter (see vim-tags). Note removing vim quotes causes viewer to fail.
function! tag#read_tags(mode, type, query, ...) abort
  let sel = a:mode ? s:regex_tag2 : s:regex_tag1
  let sub = a:mode ? '\=s:tag_fmt2(30, head, base, cache)' : '\=s:tag_fmt1(30, path)'
  let cmd = 'readtags -t %s -e -p - ' . fzf#shellescape(a:query)
  if empty(a:type)
    let [ftype, regex] = ['', '']
  elseif type(a:type)
    let [ftype, regex] = [a:type, tags#type_regex(a:type)]
  else
    let [ftype, regex] = [&l:filetype, tags#type_regex()]
  endif
  let [result, cache] = [[], {}]  " see also tags.vim s:tag_source()
  for path in a:0 ? a:1 : [expand('%')]
    if !filereadable(path) | continue | endif
    if empty(a:query)
      let lines = readfile(path)
    else
      let lines = systemlist(printf(cmd, fzf#shellescape(path)))
    endif
    let folder = fnamemodify(path, ':p:h')  " tag file folder
    let prepend = a:0 > 1 && strpart(expand('%:p'), 0, len(folder)) !=# folder
    let fast = index(values(s:type_cache), ftype) >= 0  " whether cached
    let base = prepend ? fnamemodify(folder, ':t') . '/' : ''  " slash required
    let head = prepend ? fnamemodify(folder, ':h') . '/' : folder . '/'
    call filter(lines, {_, val -> s:tag_filter(val, ftype, regex, fast)})
    call map(lines, {_, val -> substitute(val, sel, sub, '')})
    call extend(result, lines)
  endfor
  return [result, cache]
endfunction

" Return the 'from' position for the given path and tag
" Note: This only jumps if the destination 'from' line contains the tag (i.e. not
" jumping to an outdated position or from a random fzf call) or when at the bottom.
function! tag#from_stack(arg, name, ...) abort
  let path = expand('%:p')
  let wins = type(a:arg) ? win_findbuf(bufnr(a:arg)) : [a:arg]
  let stack = gettagstack(get(wins, 0, winnr()))
  for item in reverse(get(stack, 'items', []))  " search from top
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
function! s:goto_iloc(tag, ...) abort  " see also mark.vim
  let [path, tpos, name] = a:tag
  let [iloc, size] = stack#get_loc('tag')
  let [ibnr, tbnr] = [bufnr(), bufnr(path)]
  let ipos = [ibnr] + slice(getpos('.'), 1)
  let itag = [ibnr] + tags#find_tag(line('.'))  " cursor [buf name line kind]
  let tpos = [tbnr] + map(type(tpos) > 1 ? tpos : [tpos], 'str2nr(v:val)')
  let ttag = [tbnr] + tags#find_tag(tpos[:1])  " tag [buf name line kind]
  let fpos = tag#from_stack(path, name, iloc == 0)
  let cnt = a:0 ? a:1 : v:count1
  let outside = !empty(fpos) && ipos[:1] != fpos[:1] && itag != ttag
  if cnt < 0 && size > 1 && iloc >= size - 1 && outside  " add <top> pseudo-tag
    let name = '<top>'  " updated tag name
    let item = [expand('%:p'), [line('.'), col('.')], name]
    let g:tag_name = item  " push_stack() adds to top of stack
    call stack#push_stack('tag', '', '', 0)
  endif
  let jpos = cnt >= 0 || empty(fpos) && iloc == 0 ? tpos : fpos
  let outside = jpos != slice(ipos, 0, len(jpos))
  if !empty(jpos) && name !=# '<top>' && outside
    let [path, lnum; rest] = jpos
    let iarg = empty(rest) ? lnum : [lnum, rest[0]]
    silent call tags#_goto_tag(2, path, iarg, name)
    let noop = cnt < 0 ? ipos[:1] == jpos[:1] : itag == ttag  " ignore from count
    let cnt += noop ? 0 : cnt < 0 ? 1 : -1  " possibly adjust count
  endif
  return cnt
endfunction

" Iterate over tags (see also mark#next_mark)
" Note: Here pass '-1' verbosity to disable both function messages and stack message.
" Note: This implicitly adds 'current' location to top of stack before navigation,
" and additionally jumps to the tag stack 'from' position when navigating backwards.
function! tag#next_stack(...) abort
  let cnt = a:0 ? a:1 : v:count1
  let item = stack#get_item('tag')
  let item = empty(item) ? [] : item
  let [iloc, size] = stack#get_loc('tag')
  if iloc >= size - 1 && get(item, 2, '') ==# '<top>'
    call stack#pop_stack('tag', item)
    let [iloc, size] = stack#get_loc('tag')
    let item = stack#get_item('tag')
    let item = empty(item) ? [] : item
  endif
  let cnt = empty(item) ? cnt : s:goto_iloc(item, cnt)
  let icnt = cnt < 0 ? -1 : 1
  if cnt == 0  " push currently assigned name to stack
    let status = stack#push_stack('tag', '', 0, -1)
  else  " iterate stack then pass to tag jump function
    let status = stack#push_stack('tag', function('tags#_goto_tag', [icnt]), cnt, -1)
  endif
  let item = stack#get_item('tag')
  if cnt < 0 && !empty(item)  " mimic :pop behavior
    let [iloc, _] = stack#get_loc('tag')
    let pos = tag#from_stack(item[0], item[2], iloc == 0)
    let pos = empty(pos) ? getpos('.') : pos
    let [bnr, lnum, cnum, vnum] = empty(pos) ? getpos('.') : pos
    call file#goto_file(bnr ? bnr : bufnr())  " without tab stack
    call cursor(lnum, cnum, vnum)
  endif
  exe &l:foldopen =~# '\<tag\>' ? 'normal! zv' : ''
  if !status | call stack#print_item('tag') | endif
endfunction

" Select from tags in the current window stack
" Note: This finds tag kinds using taglist() and ignores missing files.
" See: https://github.com/junegunn/fzf.vim/issues/240
function! tag#fzf_stack() abort
  let items = []
  for item in get(g:, 'tag_stack', [])  " jumping tag stack
    let [iname, ipath] = [item[2], item[0]]
    if !filereadable(ipath) | continue | endif
    call extend(items, tags#tag_list(iname, ipath, 1))
  endfor
  let stack = gettagstack(win_getid())
  for item in get(stack, 'items', [])  " window tag stack
    let ipath = expand('#' . item.bufnr . ':p')
    if !filereadable(ipath) | continue | endif
    call extend(items, tags#tag_list(item.tagname, ipath, 1))  " infer kind from stack
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
function! s:tag_error() abort
  redraw | echohl ErrorMsg
  echom 'Error: Tags not found or not available.'
  echohl None | return
endfunction
function! s:tag_search(...) abort
  let tags = []
  for path in a:000
    let path = resolve(expand(path))
    if filereadable(path)
      call add(tags, path)
    elseif isdirectory(path)
      call extend(tags, globpath(path, '**/.vimtags', 0, 1))
    endif
  endfor | return tags
endfunction
function! tag#fzf_btags(bang, query, ...) abort
  let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let opts = fzf#vim#with_preview({'placeholder': '{2}:{3..}'})
  let cmd = 'ctags -f - --sort=yes --excmd=number %s 2>/dev/null | sort -s -k 5'
  let cmd = printf(cmd, fzf#shellescape(expand('%')))
  let flags = "-m -d '\t' --with-nth 1,4.. --nth 1"
  let flags .= ' --preview-window +{3}-/2 --query ' . shellescape(a:query)
  try
    let source = call(snr . 'btags_source', [[cmd]])
  catch /.*/
    return s:tag_error()
  endtry
  call filter(source, {_, val -> s:tag_filter(val, 0, 0, 0)})
  call map(source, {_, val -> substitute(val, s:regex_tag1, '\=s:tag_fmt1(40)', '')})
  let options = {
    \ 'source': source,
    \ 'sink': function('tags#_select_tag', [{}, 0]),
    \ 'options': flags . ' --prompt "BTags> "',
  \ }
  return call(snr . 'fzf', ['btags', options, [opts, a:bang]])
endfunction
function! tag#fzf_tags(type, bang, ...) abort
  let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let opts = fzf#vim#with_preview({'placeholder': '--tag {2}:{-1}:{3..}' })
  let paths = a:0 ? call('s:tag_search', a:000) : tags#tag_files()
  let paths = map(paths, 'fnamemodify(v:val, ":p")')
  let [nbytes, maxbytes] = [0, 1024 * 1024 * 200]
  for path in paths
    let nbytes += getfsize(path)
    if nbytes > maxbytes | break | endif
  endfor
  let flags = "-m -d '\t' --with-nth ..4 --nth ..2"
  let flags .= nbytes > maxbytes ? ' --algo=v1' : ''
  let prompt = empty(a:type) ? 'Tags> ' : 'FTags> '
  let [source, cache] = tag#read_tags(1, a:type, '', paths)
  if empty(source) | return s:tag_error() | endif
  let options = {
    \ 'source': source,
    \ 'sink': function('tags#_select_tag', [cache, 0]),
    \ 'options': flags . ' --prompt ' . string(prompt),
  \ }
  return call(snr . 'fzf', ['tags', options, [opts, a:bang]])
endfunction

" Update tags variable (requires g:gutentags_ctags_auto_set_tags = 0)
" Note: Using :setlocal tags requires e.g. '.vim\\,tags' and '.vim\\\ tags' for literal
" commas and spaces (see :help option-backslash). Setting with &l:tags requires only
" single backslashes, and paths appear with single backslash when retrieving after set.
" Note: This is hooked up to GutenTagsUpdated autocommand, makes fzf :Tags function
" and native :tags features use all projects but prioritize the file project.
" Note: Vim resolves all symlinks so unfortunately cannot just commit to using
" the symlinked $HOME version in other projects. Resolve below for safety.
function! tag#update_paths(...) abort
  if a:0  " append to existing
    let toggle = !type(a:1) ? a:1 : 1  " type zero i.e. number (see :help empty)
    let args = copy(a:000[!type(a:1):])
    let bufs = map(args, 'bufnr(v:val)')
  else  " reset defaults
    let toggle = 1 | setglobal tags=
    let [bufs, tabs] = [[], range(1, tabpagenr('$'))]
    call map(tabs, 'extend(bufs, tabpagebuflist(v:val))')
  endif
  for bnr in bufs  " possible iteration
    let opts = getbufvar(bnr, 'gutentags_files', {})
    let path = get(opts, 'ctags', '')
    if empty(path) || !filewritable(resolve(path))
      continue  " invalid path
    endif
    let path = substitute(path, ',', '\\\\,', 'g')  " see above
    let path = substitute(path, ' ', '\\\\\\ ', 'g')  " see above
    exe 'setglobal tags' . (toggle ? '+=' : '-=') . path
  endfor
  for bnr in bufs
    let tags = tags#tag_files(bufname(bnr))  " prefer buffer file
    call map(tags, {_, val -> substitute(val, '\(,\| \)', '\\\1', 'g')})  " see above
    call setbufvar(bnr, '&tags', join(tags, ','))  " see above
  endfor
endfunction
