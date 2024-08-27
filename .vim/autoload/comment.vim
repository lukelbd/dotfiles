"-----------------------------------------------------------------------------"
" Utilities for inserting comments
"-----------------------------------------------------------------------------"
" Helper functions
" TODO: Use &comments or tcomment supporting functions that parse &comments to
" optionally choose between block comments and inline comments when inserting.
" NOTE: Search non-printable dummy characters 1-32 from &isprint by default. Note zero
" character is null i.e. string termination so matches empty string. See :help /\]
" let root = parse#get_root(expand('%:p'))
" let opts = ['setup.py', 'setup.cfg', '__init__.py']
" call filter(opts, '!empty(globpath(root, v:val))')
function! comment#get_string(...) abort
  let space = repeat(' ', a:0 ? a:1 : 0)  " include spaces
  let string = substitute(&commentstring, '^$', '%s', '')  " copied from tpope/commentary
  let string = substitute(string, '\S\zs\s*%s', space . '%s', '')
  return substitute(string, '%s\s*\ze\S', '%s' . space, '')
endfunction
function! comment#get_regex(...) abort
  let special = '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'
  let space = a:0 && a:1 ? '\s\+' : a:0 ? '\s*' : ''  " prepend spaces
  let regex = substitute(comment#get_string(), '%s.*', '', '')
  return space . (empty(regex) ? special : escape(regex, '[]\.*$~'))
endfunction

" Comment and section headers
" NOTE: This adds comment matching current indentaiton (used for author date) or dashes
" up to current line length ignoring comments (used for python and markdown). Also
" uses uses cursor line as default header value, e.g. turning header into comment.
function! s:get_header() abort
  let regex = '^\s*\(' . comment#get_regex() . '\s*\)\?'
  let cursor = substitute(getline('.'), regex, '', '')
  let header = utils#input_default('Header text', cursor, '')
  exe header ==# cursor ? 'delete _' : '' | return header
endfunction
function! comment#append_note(note) abort
  let indent = matchstr(getline('.'), '^\s*')
  let string = comment#get_string(1)
  let append = printf(string, a:note)
  call append(line('.') - 1, indent . append)
endfunction
function! comment#append_line(fill, ...) abort
  let [col2, col1; double] = a:0 > 1 ? reverse(copy(a:000)) : [0, 0] + a:000
  let [col1, col2] = [type(col1) ? col(col1) : col1, type(col2) ? col(col2) : col2]
  let double = !empty(double) && double[0]
  let regex = '^\s*\zs.\{-}\ze\(' . comment#get_regex(1) . '.*\)\?\s*$'
  if col1 && col2  " columns start at one
    let indent = repeat(' ', col1 - 1)
    let cnt = 1 + abs(col2 - col1)
  else  " default divider
    let indent = matchstr(getline('.'), '^\s*')
    let cnt = strchars(matchstr(getline('.'), regex))
  endif
  let append = indent . repeat(a:fill, cnt)
  call append(line('.'), append)  " always append line
  if double | call append(line('.') - 1, append) | endif
endfunction

" Character or inline headers
" NOTE: This adds inline headers e.g. '# Hello world #' and '# ---- Hello world ---- #'
" and header lines of arbitrary width given the input fill charaacters.
function! comment#header_inchar() abort
  let header = s:get_header()
  if empty(header) | return | endif
  let indent = matchstr(getline('.'), '^\s*')
  let string = comment#get_string(1)
  let leader = substitute(string, '%s.*', '', '')
  let string .= string =~# '%s$' ? join(reverse(split(leader, '\zs')), '') : ''
  let append = indent . printf(string, header)
  call append(line('.') - 1, append)
endfunction
function! comment#header_inline(ndash) abort
  let header = s:get_header()
  if empty(header) | return | endif
  let indent = matchstr(getline('.'), '^\s*')
  let string = comment#get_string(1)
  let leader = substitute(string, '%s.*', '', '')
  let string .= string =~# '%s$' ? join(reverse(split(leader, '\zs')), '') : ''
  let header = repeat('-', a:ndash) . ' ' . header . ' ' . repeat('-', a:ndash)
  let append = indent . printf(string, header)
  call append(line('.') - 1, append)
endfunction
function! comment#header_line(fill, count, ...) abort  " inserts above by default
  let double = a:0 && a:1
  let indent = matchstr(getline('.'), '^\s*')
  let string = comment#get_string(0)
  let leader = substitute(string, '%s.*', '', '')
  let string .= string =~# '%s$' ? join(reverse(split(leader, '\zs')), '') : ''
  let repeat = (a:count - strchars(indent)) / strchars(a:fill)  " divide by width
  let append = indent . printf(string, repeat(a:fill, repeat))
  if double  " add header above and label in-between
    let string = comment#get_string(1)
    let header = s:get_header() | if empty(header) | return | endif
    let header = indent . printf(string, header)
    let append = [append, header, append]
  endif
  call append(line('.') - 1, append)
endfunction

" Comment text objects
" NOTE: Native plugin sometimes includes non-comment vim double quotes
function! s:object_comment(name, ...) abort
  let inner = a:name[-1] ==# 'i'
  let winview = winsaveview()
  if a:0 && !empty(a:1)
    call call('cursor', type(a:1) > 1 ? a:1 : [a:1, col([a:1, '$'])])
  endif
  let [char, pos1, pos2] = call(a:name, [])
  let [lnum, cnum] = pos1[1:2]
  let [lmax, cmax] = pos2[1:2]
  if lnum > lmax || lnum == lmax && cnum >= cmax
    return [char, pos1, pos2]
  endif
  let inum = cnum
  let cmax = col([lnum, '$'])
  let cmax = min([cmax, lnum == pos2[1] ? pos2[2] + 1 : cmax])
  let text = getline(lnum)
  while inum < cmax && !tags#get_inside(0, 'Comment')
    let cnum = inum | call cursor(lnum, cnum) | let inum += 1
  endwhile
  if inum < cmax
    let text = strpart(getline(lnum), 0, cnum - 1)
    let delta = len(matchstr(reverse(text), '^\s*'))
    let pos1[2] = inner ? cnum : cnum - delta
  endif
  call winrestview(winview)
  return [char, pos1, pos2]
endfunction
function! comment#object_comment_i(...) abort
  return call('s:object_comment', ['textobj#comment#select_i'] + a:000)
endfunction
function! comment#object_comment_a(...) abort
  return call('s:object_comment', ['textobj#comment#select_a'] + a:000)
endfunction
function! comment#object_comment_big_a(...) abort
  return call('s:object_comment', ['textobj#comment#select_big_a'] + a:000)
endfunction

" Comment navigation and toggling
" NOTE: The '$' is required for lookbehind for some reason
function! comment#next_comment(count, ...) abort
  let comment = comment#get_regex()
  let head = a:0 && a:1 ? '' : '\s*'  " include indented
  let tail = comment . '.\+$\n'
  let back = '^\(^' . head . tail . '\)\@<!'
  let regex = back . head . '\zs' . tail . '\(' . head . tail . '\)*'
  let lnum = s:next_comment(a:count, regex)
  return lnum > 0
endfunction
function! s:next_comment(count, regex)
  let flags = a:count >= 0 ? 'w' : 'bw'
  for _ in range(abs(a:count))
    let inum = foldclosed('.')
    let skip = "!tags#get_inside(0, 'Comment')"
    let skip .= inum > 0 ? " || foldclosed('.') == " . inum : ''
    let lnum = search(a:regex, flags, 0, 0, skip)
  endfor
  exe &foldopen =~# 'block\|all' ? 'normal! zv' : '' | return lnum
endfunction
function! comment#toggle_comment(...) abort
  call tcomment#ResetOption()
  if v:count > 0 | call tcomment#SetOption('count', v:count) | endif
  let suffix = !a:0 ? 'gcc' : a:1 ? 'Commentc' : 'Uncommentc'
  let w:tcommentPos = getpos('.')
  let &operatorfunc = 'TCommentOpFunc_' . suffix
  let line1 = foldclosed('.')
  let line2 = foldclosedend('.')
  call feedkeys(line1 == line2 ? 'g@il' : 'g@iz', 'm')
endfunction

" Jump between comment blocks
" NOTE: Required since default 'gcc' maps to g@$ operator function call
function! comment#next_block(count, ...) abort
  let comment = comment#get_regex()
  let head = a:0 && a:1 ? '' : '\s*'  " include indented
  let back = '^\(^' . head . comment . '.\+$\n\)\@<!'
  let tail = comment . '\s*[-=]\{3,}' . comment . '\?'
  let regex = back . head . '\zs' . tail .'\(\s\|$\)'
  let lnum = s:next_comment(a:count, regex)
  if lnum <= 0 | return | endif
  let text = getline(lnum + 1)
  let msg = substitute(text, head . comment . '\s*', '', '')
  redraw | echo 'Header: ' . msg
endfunction
function! comment#next_label(count, ...) abort
  let [flag, opts] = a:0 && !type(a:1) ? [a:1, a:000[1:]] : [0, a:000]
  let comment = comment#get_regex()
  let head = (flag ? '^\s*' : '') . comment . '\s*'
  let tail = '\c\zs\(' . join(opts, '\|') . '\):.*$'
  let regex = head . '\zs' . tail
  let lnum = s:next_comment(a:count, regex)
  if lnum <= 0 | return | endif
  let msg = substitute(getline(lnum), head, '', '')
  let msg = split(msg, '^[^:]*\zs:', 1)
  let msg[0] = substitute(tolower(msg[0]), '^\a', '\u&', '')
  redraw | echo join(msg, ':') . '...'
endfunction
