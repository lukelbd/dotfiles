"-----------------------------------------------------------------------------"
" Utilities for ctags management
"-----------------------------------------------------------------------------"
" Return the 'from' position for the given path and tag
" Note: Encountered bug when naming this same as vim-tags (plural).
" Note: This only jumps if the destination 'from' line contains the tag (i.e. not
" jumping to an outdated position or from a random fzf call) or when at the bottom.
scriptencoding utf-8
function! s:goto_pos(...) abort
  let [bnr, lnum; rest] = a:0 ? a:000 : getpos('.')
  call file#goto_file(bnr ? bnr : bufnr())  " without tab stack
  let ipos = empty(rest) ? [lnum, 1] : [lnum] + rest
  return call('cursor', ipos)
endfunction
function! s:get_from(arg, name, ...) abort
  let force = a:0 && a:1  " always keep bottom of stack
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
    if force || text =~# escape(iname, '[]\.*$~')
      return [bnr, lnum, cnum, onum]
    endif
  endfor | return []
endfunction

" Go to the current tag location and adjust the count
" Note: This adds a pseudo-tag <top> at the top of the stack so we can return to
" where we started when scrolling backwards, and pushes <top> if cursor is outside
" both 'from' and 'tag' buffers or inside the 'tag' buffer but outside its bounds.
function! s:goto_stack(item, count, ...) abort  " see also mark.vim
  if empty(a:item) | return ['', a:count] | endif
  let [path, tpos, name] = a:item
  let [iloc, size] = stack#get_loc('tag')
  let [ibnr, tbnr] = [bufnr(), bufnr(path)]
  let icnt = a:count  " input count
  let ipos = [ibnr] + slice(getpos('.'), 1)
  let itag = [ibnr] + tags#get_tag(line('.'))  " cursor [buf name line kind]
  let tpos = [tbnr] + map(type(tpos) > 1 ? tpos : [tpos], 'str2nr(v:val)')
  let ttag = [tbnr] + tags#get_tag(tpos[:1])  " tag [buf name line kind]
  let fpos = s:get_from(path, name, iloc == 0)  " always allow returning to bottom
  let noop = itag == ttag || !empty(fpos) && ipos[:1] == fpos[:1]
  if icnt && size && !noop && iloc >= size - 1  " add <top> pseudo-tag
    if name ==# '<top>'
      let iloc -= 1 | call stack#pop_stack('tag', a:item)
    endif
    let name = '<top>'  " updated tag name
    let g:tag_name = [expand('%:p'), [line('.'), col('.')], name]
    call stack#push_stack('tag', '', '', 0)  " adds to top of stack
  endif
  let from = icnt < 0 && !empty(fpos)
  let jpos = from ? fpos : tpos
  let ipos = slice(ipos, 0, len(jpos))
  if icnt && ipos != jpos && name !=# '<top>'
    let [path, lnum; rest] = jpos
    let iarg = empty(rest) ? lnum : [lnum, rest[0]]
    if from  " go to from position
      call call('s:goto_pos', [path, lnum] + rest)
    else  " go to exact tag position
      silent call tags#_goto_tag(2, path, iarg, name)
    endif
    let noop = from ? ipos[:1] == jpos[:1] : itag == ttag  " exclude from count
    let icnt += noop ? 0 : icnt > 0 ? -1 : 1  " possibly adjust count
  endif
  return [name, icnt]
endfunction

" Iterate over tags (see also mark#next_mark)
" Note: Here pass '-1' verbosity to disable both function messages and stack message.
" Note: Tag jumps with <Enter> or fzf selection may float selections above <top> entry,
" so here remove any <top> entries not already on the top before iterating stack.
" Note: This implicitly adds 'current' location to top of stack before navigation,
" and additionally jumps to the tag stack 'from' position when navigating backwards.
function! s:clean_stack() abort
  let items = []  " outdated pseudo-tags
  let [_, size] = stack#get_loc('tag')
  for idx in size > 1 ? range(size - 2) : []  " skip final tag
    let item = stack#get_item('tag', idx)
    let name = get(item, 2, '')
    if name ==# '<top>' | call add(items, item) | endif
  endfor
  for item in items  " remove top tags
    call stack#pop_stack('tag', item)
  endfor
endfunction
function! tag#next_stack(...) abort
  exe "normal! m'"
  call s:clean_stack()
  let icnt = a:0 ? a:1 : v:count1
  let item = stack#get_item('tag')
  let [name, icnt] = s:goto_stack(item, icnt)
  let iarg = icnt >= 0 ? 1 : -1
  if !icnt  " push currently assigned name to stack
    let result = stack#push_stack('tag', '', 0, -1)
  else  " iterate stack then pass to tag jump function
    let result = stack#push_stack('tag', function('tags#_goto_tag', [iarg]), icnt, -1)
  endif
  let item = stack#get_item('tag')  " current tag
  if icnt < 0 && !empty(item) && name !=# '<top>'  " mimic :pop behavior
    let [iloc, _] = stack#get_loc('tag')  " force on zero
    let ipos = s:get_from(item[0], item[2], iloc == 0)
    call call('s:goto_pos', ipos)  " possibly empty
  endif
  exe &l:foldopen =~# '\<tag\>' ? 'normal! zv' : ''
  if !result | call stack#print_item('tag') | endif
endfunction

" Select from tags in the current stack
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
    call map(items, '[v:val.filename, v:val.cmd, v:val.name, v:val.kind]')
  else
    call map(items, '[v:val.cmd, v:val.name, v:val.kind]')
  endif
  if empty(items)
    redraw | echohl WarningMsg
    echom 'Error: Tag stack is empty'
    echohl None | return
  endif
  return tags#select_tag(level, reverse(items), 1)
endfunction

" Select from buffer tags
" Note: This is similar to fzf except uses custom sink that adds results to window
" tag stack for navigation with ctrl-bracket maps and tag/pop commands.
function! s:raise() abort
  redraw | echohl ErrorMsg
  echom 'Error: Tags not found or not available.'
  echohl None | return
endfunction
function! s:format(size, ...) abort
  let path = a:0 ? "\t" . a:1 . '.vimtags' : ''  " see fzf.vim/bin/tagpreview.sh
  let name = strcharpart(submatch(1), 0, a:size - 1)
  let name = len(name) < len(submatch(1)) ? name . '·' : name
  let name = printf('%-' . a:size . 's', name)
  return name . "\t" . submatch(2) . submatch(3) . path
endfunction
function! tag#fzf_btags(bang, query, ...) abort
  let snr = utils#get_snr('fzf.vim/autoload/fzf/vim.vim')
  if empty(snr) | return | endif
  let cmd = 'ctags -f - --sort=yes --excmd=number %s 2>/dev/null | sort -s -k 5'
  let cmd = printf(cmd, fzf#shellescape(expand('%')))
  let opts = fzf#vim#with_preview({'placeholder': '{2}:{3..}'})
  let opts = join(map(get(opts, 'options', []), 'fzf#shellescape(v:val)'), ' ')
  let opts .= " -m -d '\t' --with-nth 1,4.. --nth 1"
  let opts .= ' --preview-window +{3}-/2 --query ' . shellescape(a:query)
  try
    let source = call(snr . 'btags_source', [[cmd]])
  catch /.*/
    return s:raise()
  endtry
  let regex = '^\([^\t]*\)\t\([^\t]*\)\(.*\)$'
  let prompt = string('BTags> ')
  call filter(source, {_, val -> val !~# '^!\|^\s*\d\+\>'})
  call map(source, {_, val -> substitute(val, regex, '\=s:format(40)', '')})
  let options = {
    \ 'source': source,
    \ 'sink': function('tags#_select_tag', [0]),
    \ 'options': opts . ' --prompt=' . prompt,
  \ }
  return fzf#run(fzf#wrap('btags', options, a:bang))
endfunction

" Select from the current tag files
" Note: Tried 'readtags -t - -e -E -Q (#/.py/ $input) -l' but fails since parses
" the tag file path appended by tags.pl to each line. Instead simply use awk.
" Note: Formatting with more complex regex can cause slowdown. Avoid complex
" regex patterns e.g. extra globs and non-greedy globs.
function! s:get_files(...) abort
  let tags = [] |
  for path in a:000
    let path = resolve(expand(path))
    if filereadable(path)
      call add(tags, path)
    elseif isdirectory(path)
      call extend(tags, globpath(path, '**/.vimtags', 0, 1))
    endif
  endfor | return tags
endfunction
function! tag#fzf_tags(type, bang, ...) abort
  let scripts = utils#get_scripts('fzf.vim/autoload/fzf/vim.vim')
  if empty(scripts) | return | endif
  let script = fnamemodify(scripts[0], ':p:h:h:h') . '/bin/tags.pl'
  if !executable(script) | return | endif
  let paths = a:0 ? call('s:get_files', a:000) : tags#tag_files()
  let [args, nbytes, maxbytes] = [[], 0, 1024 * 1024 * 200]
  for path in paths
    if !filereadable(path) | continue | endif
    call add(args, fnamemodify(path, ':p'))
    let nbytes += getfsize(path)
    if nbytes > maxbytes | break | endif
  endfor
  if empty(args) | return s:raise() | endif
  let regex = tags#type_regex(a:type ? &l:filetype : '')
  let regex = substitute(regex, '\\\@<![(|)]', '\\\\\&', 'g')
  let regex = substitute(regex, '\\\([(|)]\)', '\1', 'g')
  if empty(regex) && !empty(a:type)
    redraw | echohl WarningMsg
    echom 'Warning: Unable to filter file type ' . string(a:type) . '.'
    echohl None
  endif
  let post = empty(regex) ? '' : " | awk -F'\t' '$2 ~ /" . regex . "/'"
  let read = join(map(['perl', script, ''] + args, 'shellescape(v:val)'), ' ')
  let opts = fzf#vim#with_preview({'placeholder': '--tag {2}:{-1}:{3..}'})
  let opts = join(map(get(opts, 'options', []), 'fzf#shellescape(v:val)'), ' ')
  let opts .= " -m -d '\t' --with-nth ..4 --nth ..2"
  let opts .= nbytes > maxbytes ? ' --algo=v1' : ''
  let prompt = string(empty(a:type) ? 'Tags> ' : 'FTags> ')
  let options = {
    \ 'source': read . post,
    \ 'sink': function('tags#_select_tag', [0]),
    \ 'options': opts . ' --prompt=' . prompt,
  \ }
  return fzf#run(fzf#wrap('tags', options, a:bang))
endfunction

" Update tags variable (requires g:gutentags_ctags_auto_set_tags = 0)
" Note: Using :setlocal tags requires e.g. '.vim\\,tags' and '.vim\\\ tags' for literal
" commas and spaces (see :help option-backslash). Setting with &l:tags requires only
" single backslashes, and paths appear with single backslash when retrieving after set.
" Note: This is hooked up to GutenTagsUpdated autocommand, makes fzf :Tags function
" and native :tags features use all projects but prioritize the file project.
" Note: Vim resolves all symlinks so unfortunately cannot just commit to using
" the symlinked $HOME version in other projects. Resolve below for safety.
function! tag#setup_taglist() abort
  for char in 'ud' | silent! exe 'nunmap <buffer> ' . char | endfor
endfunction
function! tag#update_files(...) abort
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
