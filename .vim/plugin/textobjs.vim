"------------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-09-10
" Custom text objects defined with vim-text-obj, and copied from other folks.
" For more info see: https://www.reddit.com/r/vim/comments/48e4ci/vimscript_how_to_create_a_new_text_object/d0iy3ny/
"------------------------------------------------------------------------------"
"------------------------------------------------------------------------------"
" Global stuff
" Some ideas for future:
" https://github.com/kana/vim-textobj-lastpat/tree/master/plugin/textobj (similar to my d/ and d? commands!)
"------------------------------------------------------------------------------"
"For some **super common** blocks, don't always have to hit inner/outer/whatever
"Here, in spirit of vim-surround 'yss', declare a few special such blocks
"Note the visual ones don't work by default, need to specify explicitly
onoremap w  iw
onoremap W  iW
onoremap p  ip
nnoremap vw viw
nnoremap vW viW
nnoremap vp vip

"Next declare some special textobj plugin objects
"Consider using: machakann/vim-textobj-functioncall
if !has_key(g:plugs, 'vim-textobj-user')
  finish
endif
"Highlight functions and arrays; use keyword chars, i.e. what is considered
"a 'word' by '*', 'gd/gD', et cetera
"Note the 'a' letter is reserved for c'a'rats, e.g. <hello>
"Question: Why does the below not work without \<?
call textobj#user#plugin('misc', {
  \   'function': {
  \     'pattern': ['\<\h\k*(', ')'],
  \     'select-a': 'af',
  \     'select-i': 'if',
  \   },
  \   'array': {
  \     'pattern': ['\<\h\k*\[', '\]'],
  \     'select-a': 'aA',
  \     'select-i': 'iA',
  \   },
  \ })
"Highlight current line, to match 'yss' vim-surround syntax
"Copied from example somewhere possibly
call textobj#user#plugin('general', {
  \   'line': {
  \     'select-a-function': 'CurrentLineA',
  \     'select-a': 'as',
  \     'select-i-function': 'CurrentLineI',
  \     'select-i': 'is',
  \   },
  \ })
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

"------------------------------------------------------------------------------"
" Miscelenaous stuff, single-key aliases
"------------------------------------------------------------------------------"
function! s:alias(original,new)
  exe 'onoremap i'.a:original.' i'.a:new
  exe 'onoremap a'.a:original.' a'.a:new
endfunction
for pair in ['r[', 'a<', 'c{']
  call s:alias(pair[0], pair[1])
endfor
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
"Comment jumping and selecting
"Consider turning the comment selections below into text objects
noremap <expr> <silent> gc <sid>smartjump('^\s*'.b:NERDCommenterDelims['left'],0).'gg'
noremap <expr> <silent> gC <sid>smartjump('^\s*'.b:NERDCommenterDelims['left'],1).'gg'
nmap vic gCVgc
nmap vac vic
"Empty line jumping
"Note vip/vap are builtin commands -- just wanted to redefine {/} motions
"to go to the line just *before*/*after* empty one
noremap <expr> <silent> ge <sid>smartjump('^\s*$',0).'gg'
noremap <expr> <silent> gE <sid>smartjump('^\s*$',1).'gg'

"------------------------------------------------------------------------------"
"TeX plugin
"Copied from: https://github.com/rbonvall/vim-textobj-latex/blob/master/ftplugin/tex/textobj-latex.vim
"so I could change the names.
"------------------------------------------------------------------------------"
augroup textobj_tex
  au!
  au FileType tex call textobj#user#plugin('latex',s:tex_textobjs_dict)
augroup END
"Dictionary containing text objects
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
  \     'select-a': 'ab',
  \     'select-i': 'ib',
  \   },
  \  'paren-math': {
  \     'pattern': ['\\(', '\\)'],
  \     'select-a': 'a\',
  \     'select-i': 'i\',
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
  \     'select-a': 'aq',
  \     'select-i': 'iq',
  \   },
  \  'double-quote': {
  \     'pattern': ['``', "''"],
  \     'select-a': 'aQ',
  \     'select-i': 'iQ',
  \   },
  \ }

"------------------------------------------------------------------------------"
"Previous version with manual mappings, super ugly
"------------------------------------------------------------------------------"
" "Expand to include 'function' delimiters, i.e. function[...]
" nnoremap daf mzF(bdt(lda(`z
" nnoremap caf F(bdt(lca(
" nnoremap yaf mzF(bvf(%y`z
" nnoremap <silent> vaf F(bmVvf(%
" "Expand to include 'array' delimiters, i.e. array[...]
" onoremap iA ir
" nnoremap daA mzF[bdt[lda[`z
" nnoremap caA F[bdt[lca[
" nnoremap yaA mzF[bvf[%y`z
" nnoremap <silent> vaA F[bmVvf[%
" "Next mimick surround syntax with current line
" "Will make 'a' the whole line excluding newline, and 'i' ignore leading/trailing whitespace
" nnoremap das 0d$
" nnoremap cas cc
" nnoremap yas 0y$
" nnoremap <silent> vas 0v$
" nnoremap dis ^v$gEd
" nnoremap cis ^v$gEc
" nnoremap yis ^v$gEy
" nnoremap <silent> vis ^v$gE
" "And as we do with surround below, sentences
" "Will make 'a' the whole sentence, and 'i' up to start of next one
" nnoremap da. l(v)hd
" nnoremap ca. l(v)hs
" nnoremap ya. l(v)hy
" nnoremap <silent> va. l(v)h
" nnoremap di. v)hd
" nnoremap ci. v)hs
" nnoremap yi. v)hy
" nnoremap <silent> va. v)h
"----------------------------------------------------------------------------"
" As above but for latex stuff
"----------------------------------------------------------------------------"
" "Apply 'inner'/'outer'/'surround' syntax to \command{text} and \begin{env}text\end{env}
" nnoremap <buffer> dal F{F\dt{daB
" nnoremap <buffer> cal F{F\dt{caB
" nnoremap <buffer> yal F{F\vf{%y
" nnoremap <buffer> <silent> val F{F\vf{%
" nnoremap <buffer> dil diB
" nnoremap <buffer> cil ciB
" nnoremap <buffer> yil yiB
" nnoremap <buffer> <silent> vil viB
" "Selecting LaTeX begin/end environments as best we can, using %-jumping
" "enhanced by an ftplugin if possible.
" nmap <buffer> daL /\\end{<CR>:noh<CR>V^%d
" nmap <buffer> caL /\\end{<CR>:noh<CR>V^%cc
" nmap <silent> <buffer> vaL /\\end{<CR>:noh<CR>V^%
" nmap <buffer> diL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>d
" nmap <buffer> ciL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>cc
" nmap <silent> <buffer> viL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>
" "Next, latex quotes
" "The double ones are harder to do
" nnoremap <buffer> daq F`df'
" nnoremap <buffer> caq F`cf'
" nnoremap <buffer> yaq F`yf'
" nnoremap <buffer> <silent> vaq F`vf'
" nnoremap <buffer> diq T`dt'
" nnoremap <buffer> ciq T`ct'
" nnoremap <buffer> yiq T`yt'
" nnoremap <buffer> <silent> viq T`vt'
" nnoremap <buffer> daQ 2F`d2f'
" nnoremap <buffer> caQ 2F`c2f'
" nnoremap <buffer> yaQ 2F`y2f'
" nnoremap <buffer> <silent> vaQ 2F`v2f'
" nnoremap <buffer> diQ T`dt'
" nnoremap <buffer> ciQ T`ct'
" nnoremap <buffer> yiQ T`yt'
" nnoremap <buffer> <silent> viQ T`vt'

