"------------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-09-10
" Custom text objects defined with vim-text-obj, and copied from other folks.
" For more info see: https://www.reddit.com/r/vim/comments/48e4ci/vimscript_how_to_create_a_new_text_object/d0iy3ny/
"------------------------------------------------------------------------------"
" Global stuff
" Some ideas for future:
" https://github.com/kana/vim-textobj-lastpat/tree/master/plugin/textobj (similar to my d/ and d? commands!)
"------------------------------------------------------------------------------"
"Alias single-key builtin text objects
function! s:alias(original,new)
  exe 'onoremap i'.a:original.' i'.a:new
  exe 'xnoremap i'.a:original.' i'.a:new
  exe 'onoremap a'.a:original.' a'.a:new
  exe 'xnoremap a'.a:original.' a'.a:new
endfunction
for pair in ['r[', 'a<', 'c{']
  call s:alias(pair[0], pair[1])
endfor

"For some **super common** blocks, don't always have to hit inner/outer/whatever
"Here, in spirit of vim-surround 'yss', declare a few special such blocks
"Note the visual ones don't work by default, need to specify explicitly
"Nevermind, bad idea! Actually do want dw/dW sometimes!!!
" onoremap w  iw
" onoremap W  iW
" onoremap p  ip
" nnoremap vw viw
" nnoremap vW viW
" nnoremap vp vip

"This fucking stupid plugin doesn't fucking support buffer-local
"mappings, an incredibly simple feature, because it fucking sucks
if !PlugActive('vim-textobj-user')
  echom "Warning: textobj plugin unavailable."
  finish
endif
augroup textobj_tex
  au!
  au BufEnter * call s:textobj_setup()
augroup END

"Helper function
function! s:textobj_setup()
  call textobj#user#plugin('universal',s:universal_textobjs_dict)
  if &ft=='tex' "this will overwrite some default ones, quote-related
    call textobj#user#plugin('latex',s:tex_textobjs_dict)
  endif
endfunction

"------------------------------------------------------------------------------"
"Universal object definitions
"------------------------------------------------------------------------------"
"Highlight current line, to match 'yss' vim-surround syntax
"Also functions and arrays; use keyword chars, i.e. what is considered
"a 'word' by '*', 'gd/gD', et cetera
let s:universal_textobjs_dict={
  \   'line': {
  \     'sfile': expand('<sfile>:p'),
  \     'select-a-function': 's:current_line_a',
  \     'select-a': 'as',
  \     'select-i-function': 's:current_line_i',
  \     'select-i': 'is',
  \   },
  \   'blanklines': {
  \     'sfile': expand('<sfile>:p'),
  \     'select-a-function': 's:blank_lines',
  \     'select-a': 'a<Space>',
  \     'select-i-function': 's:blank_lines',
  \     'select-i': 'i<Space>',
  \   },
  \   'nonblanklines': {
  \     'sfile': expand('<sfile>:p'),
  \     'select-a-function': 's:nonblank_lines',
  \     'select-a': 'ap',
  \     'select-i-function': 's:nonblank_lines',
  \     'select-i': 'ip',
  \   },
  \   'uncommented': {
  \     'sfile': expand('<sfile>:p'),
  \     'select-a-function': 's:uncommented_lines',
  \     'select-a': 'au',
  \     'select-i-function': 's:uncommented_lines',
  \     'select-i': 'iu',
  \   },
  \   'methodcall': {
  \     'sfile': expand('<sfile>:p'),
  \     'select-a': 'af', 'select-a-function': 's:methodcall_a',
  \     'select-i': 'if', 'select-i-function': 's:methodcall_i',
  \   },
  \   'methodef': {
  \     'sfile': expand('<sfile>:p'),
  \     'select-a': 'aF', 'select-a-function': 's:methoddef_a',
  \     'select-i': 'iF', 'select-i-function': 's:methoddef_i'
  \   },
  \   'function': {
  \     'pattern': ['\<\h\w*(', ')'],
  \     'select-a': 'am',
  \     'select-i': 'im',
  \   },
  \   'array': {
  \     'pattern': ['\<\h\w*\[', '\]'],
  \     'select-a': 'aA',
  \     'select-i': 'iA',
  \   },
  \  'curly': {
  \     'pattern': ['‘', '’'],
  \     'select-a': 'aq',
  \     'select-i': 'iq',
  \   },
  \  'curly-double': {
  \     'pattern': ['“', '”'],
  \     'select-a': 'aQ',
  \     'select-i': 'iQ',
  \   },
  \ }
" \     'move-p': 'gC', "tried doing this, got weird error, whatevs
" \     'move-n': 'gc',
" For some reason this doesn't work, have to use special methodall
" \   'fart': {
" \     'pattern': ['\<[_a-zA-Z0-9.]*(', ')'],
" \     'select-a': 'aF',
" \     'select-i': 'iF',
" \   },

"------------------------------------------------------------------------------"
"TeX plugin definitions
"Copied from: https://github.com/rbonvall/vim-textobj-latex/blob/master/ftplugin/tex/textobj-latex.vim
"so the names could be changed
"------------------------------------------------------------------------------"
let s:tex_textobjs_dict={
  \   'environment': {
  \     'pattern': ['\\begin{[^}]\+}.*\n', '\\end{[^}]\+}.*$'],
  \     'select-a': 'aL',
  \     'select-i': 'iL',
  \   },
  \  'command': {
  \     'pattern': ['\\\S\+{', '}'],
  \     'select-a': 'al',
  \     'select-i': 'il',
  \   },
  \  'bracket-math': {
  \     'pattern': ['\\\[', '\\\]'],
  \     'select-a': 'a[',
  \     'select-i': 'i[',
  \   },
  \  'paren-math': {
  \     'pattern': ['\\(', '\\)'],
  \     'select-a': 'a(',
  \     'select-i': 'i(',
  \   },
  \  'dollar-math-a': {
  \     'pattern': '[$][^$]*[$]',
  \     'select': 'a$',
  \   },
  \  'dollar-math-i': {
  \     'pattern': '[$]\zs[^$]*\ze[$]',
  \     'select': 'i$',
  \   },
  \  'quote': {
  \     'pattern': ['`', "'"],
  \     'select-a': "a'",
  \     'select-i': "i'",
  \   },
  \  'double-quote': {
  \     'pattern': ['``', "''"],
  \     'select-a': 'a"',
  \     'select-i': 'i"',
  \   },
  \ }


"------------------------------------------------------------------------------"
" Helper functions
"------------------------------------------------------------------------------"
"Motion functions
"Had hard time getting stuff to work in textobj
function! s:search(regex,forward)
  let motion=(a:forward ? '' : 'b')
  let result=search(a:regex, 'Wn'.motion)
  return (result==0 ? line('.') : result)
endfunction
noremap <expr> <silent> gc <sid>search('^\ze\s*'.Comment().'.*$', 1).'gg'
noremap <expr> <silent> gC <sid>search('^\ze\s*'.Comment().'.*$', 0).'gg'
noremap <expr> <silent> ge <sid>search('^\ze\s*$', 1).'gg'
noremap <expr> <silent> gE <sid>search('^\ze\s*$', 0).'gg'

"Functions for current line stuff
function! s:current_line_a()
  normal! 0
  let head_pos = getpos('.')
  normal! $
  let tail_pos = getpos('.')
  return ['v', head_pos, tail_pos]
endfunction
function! s:current_line_i()
  normal! ^
  let head_pos = getpos('.')
  normal! g_
  let tail_pos = getpos('.')
  let non_blank_char_exists_p = (getline('.')[head_pos[2] - 1] !~# '\s')
  return (non_blank_char_exists_p ? ['v', head_pos, tail_pos] : 0)
endfunction

"Functions for blank line stuff
function! s:helper(pnb, nnb)
  let start_line = (a:pnb == 0) ? 1         : a:pnb + 1
  let end_line   = (a:nnb == 0) ? line('$') : a:nnb - 1
  let start_pos = getpos('.') | let start_pos[1] = start_line
  let end_pos   = getpos('.') | let end_pos[1]   = end_line
  return ['V', start_pos, end_pos]
endfunction
function! s:blank_lines()
  normal! 0
  let pnb = prevnonblank(line('.'))
  let nnb = nextnonblank(line('.'))
  if pnb==line('.') "also will be true for nextnonblank, if on nonblank
    return 0
  endif
  return s:helper(pnb,nnb)
endfunction

"Functions for new and improved paragraph stuff
function! s:nonblank_lines()
  normal! 0l
  let nnb = search('^\s*\zs$', 'Wnc') "the c means accept current position
  let pnb = search('^\ze\s*$', 'Wnbc') "won't work for backwards search unless to right of first column
  if pnb==line('.')
    return 0
  endif
  return s:helper(pnb,nnb)
endfunction

"And the commented line stuff
function! s:uncommented_lines()
  normal! 0l
  let nnb = search('^\s*'.Comment().'.*\zs$', 'Wnc')
  let pnb = search('^\ze\s*'.Comment().'.*$', 'Wncb')
  if pnb==line('.')
    return 0
  endif
  return s:helper(pnb,nnb)
endfunction

"Method calls
function! s:methodcall_a()
   return s:methodcall('a')
endfunction
function! s:methodcall_i()
   return s:methodcall('i')
endfunction
function! s:methodcall(motion)
   if a:motion == 'a'
      silent! normal! [(
   endif
   silent! execute "normal! w?\\v(\\.{0,1}\\w+)+\<cr>"
   let head_pos = getpos('.')
   normal! %
   let tail_pos = getpos('.')
   if tail_pos == head_pos
      return 0
   endif
   return ['v', head_pos, tail_pos]
endfunction

"Chained methodcall command
function! s:methoddef_i()
   return s:methoddef('i')
endfunction
function! s:methoddef_a()
   return s:methoddef('a')
endfunction
function! s:char_under_cursor()
    return getline('.')[col('.') - 1]
endfunction
function! s:methoddef(motion)
   if a:motion == 'a'
      silent! normal! [(
   endif
   silent! execute 'normal! w?\v(\.{0,1}\w+)+' . "\<cr>"
   let head = getpos('.')
   while s:char_under_cursor() == '.'
      silent! execute "normal! ?)\<cr>%"
      silent! execute 'normal! w?\v(\.{0,1}\w+)+' . "\<cr>"
      let head = getpos('.')
   endwhile
   silent! execute "normal! %"
   let tail = getpos('.')
   silent! execute 'normal! /\v(\.{0,1}\w+)+' . "\<cr>"
   while s:char_under_cursor() == '.'
      silent! execute "normal! %"
      let tail = getpos('.')
      silent! execute 'normal! /\v(\.{0,1}\w+)+' . "\<cr>"
   endwhile
   call setpos('.', tail)
   if tail == head
      return 0
   endif
   return ['v', head, tail]
endfunction


