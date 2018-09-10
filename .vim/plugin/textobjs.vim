"------------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-09-10
" Custom text objects defined with vim-text-obj, and copied from other folks.
"------------------------------------------------------------------------------"
"------------------------------------------------------------------------------"
"First some simple operator remaps
function! s:alias(original,new)
  exe 'onoremap i'.a:original.' i'.a:new
  exe 'onoremap a'.a:original.' a'.a:new
endfunction
for pair in ['r[', 'a<', 'c{']
  call s:alias(pair[0], pair[1])
endfor

"Expand to include 'function' delimiters, i.e. function[...]
nnoremap daf mzF(bdt(lda(`z
nnoremap caf F(bdt(lca(
nnoremap yaf mzF(bvf(%y`z
nnoremap <silent> vaf F(bmVvf(%

"Expand to include 'array' delimiters, i.e. array[...]
onoremap iA ir
nnoremap daA mzF[bdt[lda[`z
nnoremap caA F[bdt[lca[
nnoremap yaA mzF[bvf[%y`z
nnoremap <silent> vaA F[bmVvf[%

"Next mimick surround syntax with current line
"Will make 'a' the whole line excluding newline, and 'i' ignore leading/trailing whitespace
nnoremap das 0d$
nnoremap cas cc
nnoremap yas 0y$
nnoremap <silent> vas 0v$
nnoremap dis ^v$gEd
nnoremap cis ^v$gEc
nnoremap yis ^v$gEy
nnoremap <silent> vis ^v$gE

"And as we do with surround below, sentences
"Will make 'a' the whole sentence, and 'i' up to start of next one
nnoremap da. l(v)hd
nnoremap ca. l(v)hs
nnoremap ya. l(v)hy
nnoremap <silent> va. l(v)h
nnoremap di. v)hd
nnoremap ci. v)hs
nnoremap yi. v)hy
nnoremap <silent> va. v)h

"Jumping between comments and empty lines
"Should implement the below as text objects
function! s:smartjump(regex,backwards) "jump to next comment
  let startline=line('.')
  let flag=(a:backwards ? 'Wnb' : 'Wn') "don't wrap around EOF, and don't jump yet
  let offset=(a:backwards ? 1 : -1) "actually want to jump to line *just before* comment
  let commentline=search(a:regex,flag)
  if getline('.') =~# a:regex
    return startline
  elseif commentline==0
    return startline "don't move
  else
    return commentline+offset
  endif
endfunction
noremap <expr> <silent> gc <sid>smartjump('^\s*'.b:NERDCommenterDelims['left'],0).'gg'
noremap <expr> <silent> gC <sid>smartjump('^\s*'.b:NERDCommenterDelims['left'],1).'gg'
noremap <expr> <silent> ge <sid>smartjump('^\s*$',0).'gg'
noremap <expr> <silent> gE <sid>smartjump('^\s*$',1).'gg'
nmap vic gCVgc
nmap vip gEVge

"Alias some 'block' definitions for vim-surround replacement commands
"* Analagous to the yss syntax for current line
"* Pretty much never ever want to surround based
"  on result of a movement, so the 'iw' stuff is unnecessary
"* For some reason the visual ones don't work, need to specify explicitly
onoremap w iw
onoremap W iW
onoremap p ip
onoremap s is
onoremap . is
nmap vw viw
nmap vW viW
nmap vp vip
nmap vs vis
nmap v. vis

"------------------------------------------------------------------------------"
"Declare some textobj objects
"TODO: Implement this.
"------------------------------------------------------------------------------"
if !has_key(g:plugs, 'vim-textobj-user')
  finish
endif
call textobj#user#plugin('general', {
\   'line': {
\     'select-a-function': 'CurrentLineA',
\     'select-a': 'as',
\     'select-i-function': 'CurrentLineI',
\     'select-i': 'is',
\   },
\ })
"Fucntions for general objects
function! CurrentLineA()
  normal! 0
  let head_pos = getpos('.')
  normal! $
  let tail_pos = getpos('.')
  return ['v', head_pos, tail_pos]
endfunction
function! CurrentLineI()
  normal! ^
  let head_pos = getpos('.')
  normal! g_
  let tail_pos = getpos('.')
  let non_blank_char_exists_p = (getline('.')[head_pos[2] - 1] !~# '\s')
  return (non_blank_char_exists_p ? ['v', head_pos, tail_pos] : 0)
endfunction

"Other people do it better: machakann/vim-textobj-functioncall
"Question: Why does the below not work without \<?
" \   'function': {
" \     'pattern': ['\<[a-zA-Z_][a-zA-Z0-9_]*(', ')'],
" \     'select-a': 'af',
" \     'select-i': 'if',
" \   },
" \   'method': {
" \     'pattern': ['\<[a-zA-Z_][a-zA-Z0-9_.#]*(', ')'],
" \     'select-a': 'aF',
" \     'select-i': 'iF',
" \   },
