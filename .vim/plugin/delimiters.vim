"------------------------------------------------------------------------------"
"Author: Luke Davis (lukelbd@gmail.com)
"This plugin is a wrapper around the 'surround.vim' plugin.
"Add new surround.vim delimiters for LaTeX and HTML files, incorporate
"new delimiters more cleanly with the builtin LaTeX da/di/etc. commands,
"and provide new tool for jumping outside of delimiters.
"------------------------------------------------------------------------------"
if !exists("g:plugs")
  echo "Warning: vim-plugs required to check if dependency plugins are installed."
  finish
endif
if !has_key(g:plugs, "vim-surround")
  finish
endif
if !has_key(g:plugs, "delimitmate")
  finish
endif

"------------------------------------------------------------------------------"
"Simple function for moving outside current delimiter
"Puts cursor to the right of closing braces and quotes
" * Just search for braces instead of using percent-mapping, because when
"   in the middle of typing often don't particularly *care* if a bracket is completed/has
"   a pair -- just see a bracket, and want to get out of it.
" * Also percent matching solution would require leaving insert mode, triggering
"   various autocmds, and is much slower/jumpier -- vim script solutions are better!
" ( [ [ ( "  "  asdfad) sdf    ]  sdfad   ]  asdfasdf) hello   asdfas) 
function! s:tabreset()
  let b:menupos=0 | return ''
endfunction
function! s:outofdelim(n)
  "Note: matchstrpos is relatively new/less portable, e.g. fails on midway
  "Used to use matchstrpos, now just use match(); much simpler
  let regex = "[\"')\\]}>]" "list of 'outside' delimiters for jk matching
  let pos = 0 "minimum match position
  let string = getline('.')[col('.')-1:]
  for i in range(a:n)
    let result = match(string, regex, pos) "get info on *first* match
    if result==-1 | break | endif
    let pos = result + 1 "go to next one
  endfor
  if mode()!~#'[rRiI]' && pos+col('.')>=col('$')
    let pos=col('$')-col('.')-1
  endif
  if pos==0 "relative position is zero, i.e. don't move
    return ""
  else
    return repeat("\<Right>", pos)
  endif
endfunction
"Apply remaps
"Original mnemonic was C-o gets us OUT!
imap jk <C-o>
inoremap kk k
inoremap jj j
" inoremap <expr> <C-o> !pumvisible() ? <sid>outofdelim(1)
"   \ : b:menupos==0 ? "\<C-e>".<sid>tabreset().<sid>outofdelim(1)
"   \ : "\<C-y>".<sid>tabreset().<sid>outofdelim(1)

"------------------------------------------------------------------------------"
"Fancy builtin delimitMate version
"Get cursor outside of consecutive delimiter, ignoring subgroups
"and always passing to the right of consecutive braces
"Also disable <C-n> to avoid confusion; will be using up/down anyway
imap <C-p> <Plug>delimitMateJumpMany
imap <C-n> <Nop>

"------------------------------------------------------------------------------"
"Remap surround.vim defaults
"Make the visual-mode map same as insert-mode map; by default it is capital S
vmap <C-s> <Plug>VSurround

"------------------------------------------------------------------------------"
"Function to alias builtin vim surround blocks
function! s:alias(original,new,...)
  if a:0 "just checks for existance of third variable
    let buffer="<buffer>"
  else
    let buffer=""
  endif
  exe 'nnoremap '.buffer.' di'.a:original.' di'.a:new
  exe 'nnoremap '.buffer.' ci'.a:original.' ci'.a:new
  exe 'nnoremap '.buffer.' yi'.a:original.' yi'.a:new
  exe 'nnoremap '.buffer.' <silent> vi'.a:original.' mVvi'.a:new
  exe 'nnoremap '.buffer.' da'.a:original.' da'.a:new
  exe 'nnoremap '.buffer.' ca'.a:original.' ca'.a:new
  exe 'nnoremap '.buffer.' ya'.a:original.' ya'.a:new
  exe 'nnoremap '.buffer.' <silent> va'.a:original.' mVva'.a:new
endfunction
for pair in ['r[', 'a<', 'c{']
  call s:alias(pair[0], pair[1])
endfor

"Expand to include 'function' delimiters, i.e. function[...]
nnoremap dif dib
nnoremap cif cib
nnoremap yif yib
nnoremap <silent> vif vib
nnoremap daf mzF(bdt(lda(`z
nnoremap caf F(bdt(lca(
nnoremap yaf mzF(bvf(%y`z
nnoremap <silent> vaf F(bmVvf(%

"Expand to include 'array' delimiters, i.e. array[...]
nnoremap diA dir
nnoremap ciA cir
nnoremap yiA yir
nnoremap <silent> viA vir
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

"------------------------------------------------------------------------------"
"Miscellaneous stuff
"Selecting text in-between commented out lines
nnoremap <expr> vic "/^\\s*".b:NERDCommenterDelims['left']."<CR><Up>$mVvN<Down>0<Esc>:noh<CR>gv"
"Maybe add other special ideas

"------------------------------------------------------------------------------"
"Alias some 'block' definitions for vim-surround replacement commands
"* Analagous to the yss syntax for current line
"* Pretty much never ever want to surround based
"  on result of a movement, so the 'iw' stuff is unnecessary
nmap ysw ysiw
nmap ysW ysiW
nmap ysp ysip
nmap ys. ysis
nmap ySw ySiw
nmap ySW ySiW
nmap ySp ySip
nmap yS. ySis

"------------------------------------------------------------------------------"
"Define some new vim-surround targets, usable with ds/cs/ys/yS
"* Hit ga to get ASCII code (leftmost number; not the HEX code!)
"* Note that if you just enter some uncoded character, will
"  use that as a delimiter -- e.g. yss` surrounds with backticks
"* Note double quotes are required, because surround-vim wants
"  the literal \r return character.
"c for curly brace
let g:surround_{char2nr('c')}="{\r}"
"f for functions, with user prompting
let g:surround_{char2nr('f')}="\1function: \1(\r)"
"\ for \" escaped quotes
let g:surround_{char2nr('\')}="\\\"\r\\\""
"p for print
let g:surround_{char2nr('p')}="print(\r)"

"------------------------------------------------------------------------------"
"Important Note: One problem with custom targets is vim-surround
"can 'put' them, but cannot 'find' them e.g. in a ds<custom-target>
"or cs<custom-target><other-target> command.
"Caveat: Surround *can* detect them if they are single character, so if
"you have a single-character map, just point the alias to that character.
"Fix curly braces
nmap dsc dsB
nmap csc csB
"Fix escaped quotes
nmap ds\ /\\"<CR>xxdN
"Fix functions
nnoremap dsf mzF(bdt(xf)x`z
nnoremap <expr> csf 'F(hciw'.input('function: ').'<Esc>'

"Function for adding single-character delim mappings and fixing
"surround-vim commands as described above automatically
function! s:target_simple(symbol,start,end,...)
  if a:0
    let buffer="<buffer>"
  else
    let buffer=""
  endif
  "First the builtin ones
  exe 'nnoremap '.buffer.' da'.a:symbol.' F'.a:start.'df'.a:end
  exe 'nnoremap '.buffer.' ca'.a:symbol.' F'.a:start.'cf'.a:end
  exe 'nnoremap '.buffer.' ya'.a:symbol.' F'.a:start.'yf'.a:end
  exe 'nnoremap <silent> '.buffer.' va'.a:symbol.' F'.a:start.'vf'.a:end
  exe 'nnoremap '.buffer.' da'.a:symbol.' T'.a:start.'dt'.a:end
  exe 'nnoremap '.buffer.' ca'.a:symbol.' T'.a:start.'ct'.a:end
  exe 'nnoremap '.buffer.' ya'.a:symbol.' T'.a:start.'yt'.a:end
  exe 'nnoremap <silent> '.buffer.' va'.a:symbol.' T'.a:start.'vt'.a:end
  "Next vim-surround repair
  "This time we can't assume there is an existing valid target e.g. mapping
  "c to B, so we have to make these up ourselves
  if a:symbol==a:start && a:symbol==a:end "nothing needs to be done
    return
  elseif a:start==a:end "just point surround to the actual delimiters
    exe 'nmap '.buffer.' ds'.a:symbol.' ds'.a:start
    exe 'nmap '.buffer.' cs'.a:symbol.' cs'.a:start
  else "harder
  "Warning: Ugly hack! Just change delimiters to (), and execute cs on those
    exe 'nmap '.buffer.' ds'.a:symbol.' f'.a:end.'xF'.a:start.'x'
    exe 'nmap '.buffer.' cs'.a:symbol.' f'.a:end.'r)F'.a:start.'r(dsb'
  endif
endfunction
"Add a couple very simple ones
call s:target_simple('$', '$', '$', 0)
call s:target_simple('!', '!', '!', 0)

"------------------------------------------------------------------------------"
"Function for adding fancy multiple character delimiters
"These will only be 'placed', never detected; for example, will never work in
"da<target>, ca<target>, cs<target><other>, etc. commands; only should be used for
"ys<target>, yS<target>, visual-mode S, insert-mode <C-s>, et cetera
function! s:target_fancy(symbol,start,end,...) "if final argument passed, this is buffer-local
  if a:0 "surprisingly, below is standard vim script syntax
    " silent! unlet g:surround_{char2nr(a:symbol)}
    let b:surround_{char2nr(a:symbol)}=a:start."\r".a:end
  else
    let g:surround_{char2nr(a:symbol)}=a:start."\r".a:end
  endif
endfunction

"------------------------------------------------------------------------------"
"Apply the above concepts to LaTeX in particular
"This makes writing in LaTeX a ton easier
augroup tex_delimit
  au!
  au FileType tex call s:texsurround()
augroup END
function! s:texsurround()
  "Use 'l' for commands, 'L' for environments
  "These are special maps that will load prompts; see vim-surround documentation on customization
  let b:surround_{char2nr('l')} = "\1command: \1{\r}"
  let b:surround_{char2nr('L')} = "\\begin{\1\\begin{\1}\r\\end{\1\1}"

  "Apply 'inner'/'outer'/'surround' syntax to \command{text} and \begin{env}text\end{env}
  nnoremap <buffer> dal F{F\dt{daB
  nnoremap <buffer> cal F{F\dt{caB
  nnoremap <buffer> yal F{F\vf{%y
  nnoremap <buffer> <silent> val F{F\vf{%
  nnoremap <buffer> dil diB
  nnoremap <buffer> cil ciB
  nnoremap <buffer> yil yiB
  nnoremap <buffer> <silent> vil viB

  "Fix vim-surround for 'l' commands
  nmap <buffer> dsl F{F\dt{dsB
  nmap <buffer> <expr> csl 'F{F\lct{'.input('command: ').'<Esc>F\'

  "Selecting LaTeX begin/end environments as best we can, using %-jumping 
  "enhanced by an ftplugin if possible.
  nmap <buffer> daL /\\end{<CR>:noh<CR>V^%d
  nmap <buffer> caL /\\end{<CR>:noh<CR>V^%cc
  nmap <silent> <buffer> vaL /\\end{<CR>:noh<CR>V^%
  nmap <buffer> diL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>d
  nmap <buffer> ciL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>cc
  nmap <silent> <buffer> viL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>

  "Fix vim-surround for 'L' environments
  "Ugly hack for the surround one
  nmap <buffer> dsL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>dp<Up>V<Up>d
  nmap <buffer> <expr> csL '/\\end{<CR>:noh<CR>A!!!<Esc>^%f{<Right>ciB'
  \.input('\begin{').'<Esc>/!!!<CR>:noh<CR>A {<C-r>.}<Esc>2F{dt{'

  "Next, latex quotes
  "The double ones are harder to do
  nnoremap <buffer> daq F`df'
  nnoremap <buffer> caq F`cf'
  nnoremap <buffer> yaq F`yf'
  nnoremap <buffer> <silent> vaq F`vf'
  nnoremap <buffer> diq T`dt'
  nnoremap <buffer> ciq T`ct'
  nnoremap <buffer> yiq T`yt'
  nnoremap <buffer> <silent> viq T`vt'
  nnoremap <buffer> daQ 2F`d2f'
  nnoremap <buffer> caQ 2F`c2f'
  nnoremap <buffer> yaQ 2F`y2f'
  nnoremap <buffer> <silent> vaQ 2F`v2f'
  nnoremap <buffer> diQ T`dt'
  nnoremap <buffer> ciQ T`ct'
  nnoremap <buffer> yiQ T`yt'
  nnoremap <buffer> <silent> viQ T`vt'

  "Vim-surround fixes for them
  nnoremap <buffer> dsq f'xF`x
  nnoremap <buffer> dsQ 2f'F'2x2F`2x

  "Next delimiters generally not requiring new lines
  "Math mode brackets
  call s:target_fancy('|', '\left\|', '\right\|', 1)
  call s:target_fancy('{', '\left\{', '\right\}', 1)
  call s:target_fancy('(', '\left(',  '\right)',  1)
  call s:target_fancy('[', '\left[',  '\right]',  1)
  call s:target_fancy('<', '\left<',  '\right>',  1)
  "Arrays and whatnot; analagous to above, just point to right
  call s:target_fancy('}', '\left\{\begin{array}{ll}', '\end{array}\right.', 1)
  call s:target_fancy(')', '\begin{pmatrix}',          '\end{pmatrix}',      1)
  call s:target_fancy(']', '\begin{bmatrix}',          '\end{bmatrix}',      1)
  "Font types
  call s:target_fancy('o', '{\color{red}', '}', 1)
  call s:target_fancy('i', '\textit{',     '}', 1)
  call s:target_fancy('t', '\textbf{',     '}', 1)
  call s:target_fancy('E', '\emph{'  ,     '}', 1) "use e for times 10 to the whatever
  call s:target_fancy('u', '\underline{',  '}', 1)
  call s:target_fancy('m', '\mathrm{',     '}', 1)
  call s:target_fancy('n', '\mathbf{',     '}', 1)
  call s:target_fancy('M', '\mathcal{',    '}', 1)
  call s:target_fancy('N', '\mathbb{',     '}', 1)
  "Verbatim
  call s:target_fancy('y', '\texttt{',     '}', 1) "typewriter text
  call s:target_fancy('Y', '\pyth$',       '$', 1) "python verbatim
  call s:target_fancy('V', '\verb$',       '$', 1) "verbatim
  "Math modifiers for symbols
  call s:target_fancy('v', '\vec{',        '}', 1)
  call s:target_fancy('d', '\dot{',        '}', 1)
  call s:target_fancy('D', '\ddot{',       '}', 1)
  call s:target_fancy('h', '\hat{',        '}', 1)
  call s:target_fancy('`', '\tilde{',      '}', 1)
  call s:target_fancy('-', '\overline{',   '}', 1)
  call s:target_fancy('_', '\cancelto{}{', '}', 1)
  "Boxes; the second one allows stuff to extend into margins, possibly
  call s:target_fancy('x', '\boxed{',      '}', 1)
  call s:target_fancy('X', '\fbox{\parbox{\textwidth}{', '}}\medskip', 1)
  "Quotes
  call s:target_fancy('q', '`',          "'",  1)
  call s:target_fancy('Q', '``',         "''", 1)
  "Simple enivronments, exponents, etc.
  call s:target_fancy('\', '\sqrt{',       '}',   1)
  call s:target_fancy('$', '$',            '$',   1)
  call s:target_fancy('e', '\times10^{',   '}',   1)
  call s:target_fancy('k', '^{',           '}',   1)
  call s:target_fancy('j', '_{',           '}',   1)
  call s:target_fancy('K', '\overset{}{',  '}',   1)
  call s:target_fancy('J', '\underset{}{', '}',   1)
  call s:target_fancy('/', '\dfrac{',      '}{}', 1)
  "Sections and titles
  call s:target_fancy('0', '\frametitle{',     '}',   1)
  call s:target_fancy('1', '\section{',        '}',   1)
  call s:target_fancy('2', '\subsection{',     '}',   1)
  call s:target_fancy('3', '\subsubsection{',  '}',   1)
  call s:target_fancy('4', '\section*{',       '}',   1)
  call s:target_fancy('5', '\subsection*{',    '}',   1)
  call s:target_fancy('6', '\subsubsection*{', '}',   1)
  "Shortcuts for citations and such
  call s:target_fancy('7', '\ref{',     '}', 1) "just the number
  call s:target_fancy('8', '\autoref{', '}', 1) "name and number; autoref is part of hyperref package
  call s:target_fancy('9', '\label{',   '}', 1) "declare labels that ref and autoref point to
  call s:target_fancy('z', '\note{',    '}', 1) "notes are for beamer presentations, appear in separate slide
  call s:target_fancy('a', '\caption{', '}', 1) "amazingly 'a' not used yet
  call s:target_fancy('A', '\captionof{figure}{', '}', 1) "alternative
  "Other stuff like citenum/citep (natbib) and textcite/authorcite (biblatex) must be done manually
  "Have been rethinking this
  call s:target_fancy('!', '\tag{',     '}', 1) "change the default 1-2-3 ordering; common to use *
  call s:target_fancy('&', '\citet{',   '}', 1) "second most common one
  call s:target_fancy('*', '\cite{',    '}', 1) "most common
  call s:target_fancy('@', '\citep{',   '}', 1) "second most common one
  call s:target_fancy('#', '\citenum{', '}', 1) "most common
  " call s:target_fancy('G', '\vcenteredhbox{\includegraphics[width=\textwidth]{', '}}', 1) "use in beamer talks
  "The next enfironments will also insert *newlines*
  "Frame; fragile option makes verbatim possible (https://tex.stackexchange.com/q/136240/73149)
  "note that fragile make compiling way slower
  "Slide with 'w'hite frame is the w map
  call s:target_fancy('g', '\makebox[\textwidth][c]{\includegraphicsawidth=\textwidth]{', '}}', 1) "center across margins
  call s:target_fancy('s', "\n".'\begin{frame}'."\n",                          "\n".'\end{frame}' ."\n", 1)
  call s:target_fancy('S', "\n".'\begin{frame}[fragile]'."\n",                 "\n".'\end{frame}' ."\n", 1)
  call s:target_fancy('w', "\n".'{\usebackgroundtemplate{}\begin{frame}'."\n", "\n".'\end{frame}}'."\n", 1)
  "Figure environments, and pages
  call s:target_fancy('p', "\n".'\begin{minipage}{\linewidth}'."\n", "\n".'\end{minipage}'."\n", 1)
  call s:target_fancy('f', "\n".'\begin{figure}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{figure}'."\n", 1)
  call s:target_fancy('f', "\n".'\begin{center}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{center}'."\n", 1)
  " call s:target_fancy('F', "\n".'\begin{subfigure}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{subfigure}'."\n", 1)
  call s:target_fancy('W', "\n".'\begin{wrapfigure}{r}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{wrapfigure}'."\n")
  "Equations
  call s:target_fancy('%', "\n".'\begin{equation*}'."\n", "\n".'\end{equation*}'."\n")
  call s:target_fancy('^', "\n".'\begin{align*}'."\n", "\n".'\end{align*}'."\n")
  call s:target_fancy('T', "\n".'\begin{tabular}{', "}\n\n".'\end{tabular}'."\n")
  "Versions of the above, but this time puting them on own lines
  "TODO: fix these
  " * The onlytextwidth option keeps two-columns (any arbitrary widths) aligned
  "   with default single column; see: https://tex.stackexchange.com/a/366422/73149
  " * Use command \rule{\textwidth}{<any height>} to visualize blocks/spaces in document
  " call s:target_fancy(',;', '\begin{center}',             '\end{center}')               "because ; was available
  " call s:target_fancy(',:', '\newpage\hspace{0pt}\vfill', '\vfill\hspace{0pt}\newpage') "vertically centered page
  " call s:target_fancy(',c', '\begin{columns}[c]',         '\end{columns}')
  " call s:target_fancy(',y', '\begin{python}',             '\end{python}')
  " " call s:target_fancy('c', '\begin{columns}[t,onlytextwidth]', '\end{columns}')
  "   "not sure what these args are for; c will vertically center
  " call s:target_fancy(',C', '\begin{column}{.5\textwidth}',     '\end{column}')
  " call s:target_fancy(',i', '\begin{itemize}',                  '\end{itemize}')
  " call s:target_fancy(',I', '\begin{description}',              '\end{description}') "d is now open
  " call s:target_fancy(',n', '\begin{enumerate}',                '\end{enumerate}')
  " call s:target_fancy(',N', '\begin{enumerate}[label=\alph*.]', '\end{enumerate}')
  " call s:target_fancy(',b', '\begin{block}{}',                  '\end{block}')
  " call s:target_fancy(',B', '\begin{alertblock}{}',             '\end{alertblock}')
  " call s:target_fancy(',v', '\begin{verbatim}',                 '\end{verbatim}')
  " call s:target_fancy(',V', '\begin{code}',                     '\end{code}')
endfunction

"------------------------------------------------------------------------------"
"HTML macros
"For now pretty empty, but we should add to this
"Note that tag delimiters are *built in* to vim-surround
"Just use the target 't', and prompt will ask for description
augroup html_delimit
  au!
  au FileType html call s:htmlmacros()
augroup END
function! s:htmlmacros()
  call s:target_fancy('h', '<head>',   '</head>',   1)
  call s:target_fancy('b', '<body>',   '</body>',   1)
  call s:target_fancy('t', '<title>',  '</title>',  1)
  call s:target_fancy('e', '<em>',     '</em>',     1)
  call s:target_fancy('t', '<strong>', '</strong>', 1)
  call s:target_fancy('p', '<p>',      '</p>',      1)
  call s:target_fancy('1', '<h1>',     '</h1>',     1)
  call s:target_fancy('2', '<h2>',     '</h2>',     1)
  call s:target_fancy('3', '<h3>',     '</h3>',     1)
  call s:target_fancy('4', '<h4>',     '</h4>',     1)
  call s:target_fancy('5', '<h5>',     '</h5>',     1)
endfunction

