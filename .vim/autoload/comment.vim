"-----------------------------------------------------------------------------"
" Utilities for inserting comments
"-----------------------------------------------------------------------------"
" Helper functions
" Todo: Also use &comments or tcomment supporting functions that parse &comments
" to optionally choose between block comments and inline comments when inserting.
" Note: This uses cursor line as default header value, e.g. turning header into comment,
" and searches non-printable dummy characters 1-32 from &isprint. Note character
" zero is null i.e. string termination so matches empty string. See :help /\]
function! s:get_indent() abort  " match current indent level
  let regex = '^\s*\S\zs'  " location of first non-whitespace char
  let indent = match(getline('.'), regex)
  let indent = indent == -1 ? 0 : indent - 1
  return repeat(' ', indent)
endfunction
function! s:get_header() abort
  let regex = '^\s*\(' . comment#get_regex() . '\s*\)\?'
  let default = substitute(getline('.'), regex, '', '')
  let result = utils#input_default('Header text', default, '')
  if result ==# default | call feedkeys('"_dd', 'n') | endif
  return result
endfunction
function! comment#get_string(...) abort
  let space = repeat(' ', a:0 ? a:1 : 0)  " include spaces
  let string = substitute(&commentstring, '^$', '%s', '')  " copied from tpope/commentary
  let string = substitute(string, '\S\zs\s*%s', space . '%s', '')
  let string = substitute(string, '%s\s*\ze\S', '%s' . space, '')
  return string
endfunction
function! comment#get_regex(...) abort
  let space = a:0 && a:1 ? '\s\+' : a:0 ? '\s*' : ''  " prepend spaces
  let noop = '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'
  let regex = substitute(comment#get_string(), '%s.*', '', '')
  let regex = empty(regex) ? noop : escape(regex, '[]\.*$~')
  return space . regex  " include spaces if passed
endfunction

" Add general comment matching current indentation (used for author date) or add dashes
" up to current line length (ignoring leading comments, used for python and markdown)
function! comment#append_note(note) abort
  let indent = s:get_indent()
  let string = comment#get_string(1)
  let append = printf(string, a:note)
  call append(line('.') - 1, indent . append)
endfunction
function! comment#append_line(fill, ...) abort
  let [col2, col1; double] = a:0 > 1 ? reverse(copy(a:000)) : [0, 0] + a:000
  let [col1, col2] = [type(col1) ? col(col1) : col1, type(col2) ? col(col2) : col2]
  let double = !empty(double) && double[0]
  let regex = '\(' . comment#get_regex(1) . '.*\)\?\s*$'
  if col1 && col2  " columns start at one
    let indent = repeat(' ', col1 - 1)
    let nfill = 1 + abs(col2 - col1)
  else  " default divider
    let indent = s:get_indent()
    let nfill = match(getline('.'), regex) - len(indent)  " last non-whitespace loc
  endif
  let append = indent . repeat(a:fill, nfill)
  call append(line('.'), append)  " always append line
  if double | call append(line('.') - 1, append) | endif
endfunction

" Add character or inline headers '# Hello world! #' and '# ---- Hello world! ---- #'
" or add line headers of arbitrary width given input fill charaacters.
function! comment#header_inchar() abort
  let indent = s:get_indent()
  let header = s:get_header()
  if empty(header) | return | endif
  let string = comment#get_string(1)
  let leader = substitute(string, '%s.*', '', '')
  let string .= string =~# '%s$' ? join(reverse(split(leader, '\zs')), '') : ''
  let append = indent . printf(string, header)
  call append(line('.') - 1, append)
endfunction
function! comment#header_inline(ndash) abort
  let indent = s:get_indent()
  let header = s:get_header()
  if empty(header) | return | endif
  let string = comment#get_string(1)
  let leader = substitute(string, '%s.*', '', '')
  let string .= string =~# '%s$' ? join(reverse(split(leader, '\zs')), '') : ''
  let header = repeat('-', a:ndash) . ' ' . header . ' ' . repeat('-', a:ndash)
  let append = indent . printf(string, header)
  call append(line('.') - 1, append)
endfunction
function! comment#header_line(fill, nfill, ...) abort  " inserts above by default
  let double = a:0 && a:1
  let indent = s:get_indent()
  let string = comment#get_string(0)
  let leader = substitute(string, '%s.*', '', '')
  let string .= string =~# '%s$' ? join(reverse(split(leader, '\zs')), '') : ''
  let repeat = (a:nfill - strchars(indent)) / strchars(a:fill)  " divide by width
  let append = indent . printf(string, repeat(a:fill, repeat))
  if double
    let string = comment#get_string(1)
    let header = s:get_header() | if empty(header) | return | endif
    let header = indent . printf(string, header)
    let append = [append, header, append]
  endif
  call append(line('.') - 1, append)
endfunction

" Navigate between comment blocks and headers
" Note: The '$' is required for lookbehind for some reason
function! comment#next_comment(count, ...) abort
  let head = a:0 && a:1 ? '' : '\s*'  " include indented
  let tail = comment#get_regex() . '.\+$\n'
  let back = '^\(' . head . tail . '\)\@<!'
  let regex = back . head . '\zs' . tail . '\(' . head . tail . '\)*'
  let flags = a:count >= 0 ? 'w' : 'bw'
  for _ in range(abs(a:count))
    call search(regex, flags, 0, 0, "tags#get_skip(0, 'Comment')")
  endfor
  if &foldopen =~# 'block' | exe 'normal! zv' | endif
endfunction
function! comment#next_header(count, ...) abort
  let head = a:0 && a:1 ? '' : '\s*'  " include indented
  let back = '^\(' . head . comment#get_regex() . '.\+$\n\)\@<!'
  let tail = comment#get_regex() . '\s*[-=]\{3,}' . comment#get_regex() . '\?'
  let regex = back . head . '\zs' . tail .'\(\s\|$\)'
  let flags = a:count >= 0 ? 'w' : 'bw'
  for _ in range(abs(a:count))
    call search(regex, flags, 0, 0, "tags#get_skip(0, 'Comment')")
  endfor
  if &foldopen =~# 'block' | exe 'normal! zv' | endif
endfunction
function! comment#next_label(count, ...) abort
  let [flag, opts] = a:0 && !type(a:1) ? [a:1, a:000[1:]] : [0, a:000]
  let head = (flag ? '^\s*' : '') . comment#get_regex() . '\s*'
  let tail = '\c\zs\(' . join(opts, '\|') . '\).*$'
  let regex = head . '\zs' . tail
  let flags = a:count >= 0 ? 'w' : 'bw'
  for _ in range(abs(a:count))
    call search(regex, flags, 0, 0, "tags#get_skip(0, 'Comment')")
  endfor
  if &foldopen =~# 'quickfix' | exe 'normal! zv' | endif
endfunction

" Toggle comment under cursor accounting for folds
" Note: Required since default 'gcc' maps to g@$ operator function call
function! comment#toggle_comment(...) abort
  call tcomment#ResetOption()
  if v:count > 0 | call tcomment#SetOption('count', v:count) | endif
  let suffix = !a:0 ? 'gcc' : a:1 ? 'Commentc' : 'Uncommentc'
  let w:tcommentPos = getpos('.')
  let &operatorfunc = 'TCommentOpFunc_' . suffix
  let line1 = foldclosed('.')
  let line2 = foldclosedend('.')
  if line1 == line2  " e.g. both -1
    call feedkeys('g@$', 'n')
  else  " toggle fold
    call feedkeys(line1 . 'ggg@$', 'n')
  endif
endfunction
