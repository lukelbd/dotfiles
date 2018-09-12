"------------------------------------------------------------------------------"
"Author: Luke Davis (lukelbd@gmail.com)
"This plugin is a wrapper around the 'surround.vim' plugin.
"Add new surround.vim delimiters for LaTeX and HTML files, incorporate
"new delimiters more cleanly with the builtin LaTeX da/di/etc. commands,
"and provide new tool for jumping outside of delimiters.
"------------------------------------------------------------------------------"
if !exists("g:plugs")
  echo "Warning: vim-plug required to check if dependency plugins are installed."
  finish
endif
if !has_key(g:plugs, "vim-surround")
  finish
endif
if !has_key(g:plugs, "delimitmate")
  finish
endif

"------------------------------------------------------------------------------"
"Initial configuration
"------------------------------------------------------------------------------"
"First a simple function for moving outside current delimiter
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
inoremap kk k
inoremap jj j
inoremap <expr> jk !pumvisible() ? <sid>outofdelim(1)
  \ : b:menupos==0 ? "\<C-e>".<sid>tabreset().<sid>outofdelim(1)
  \ : "\<C-y>".<sid>tabreset().<sid>outofdelim(1)
" imap jk <C-o> "don't use this one
"Fancy builtin delimitMate version
"Get cursor outside of consecutive delimiter, ignoring subgroups
"and always passing to the right of consecutive braces
"Also disable <C-n> to avoid confusion; will be using up/down anyway
imap <C-p> <Plug>delimitMateJumpMany
imap <C-n> <Nop>
"Remap surround.vim defaults
"Make the visual-mode map same as insert-mode map; by default it is capital S
vmap <C-s> <Plug>VSurround

"------------------------------------------------------------------------------"
"Define additional shortcuts like ys's' for the non-whitespace part
"of this line -- use 'w' for <cword>, 'W' for <CWORD>, 'p' for current paragraph
"------------------------------------------------------------------------------"
nmap ysw ysiw
nmap ysW ysiW
nmap ysp ysip
nmap ys. ysis
nmap ySw ySiw
nmap ySW ySiW
nmap ySp ySip
nmap yS. ySis

"------------------------------------------------------------------------------"
"Function for adding fancy multiple character delimiters
"------------------------------------------------------------------------------"
"These will only be 'placed', never detected; for example, will never work in
"da<target>, ca<target>, cs<target><other>, etc. commands; only should be used for
"ys<target>, yS<target>, visual-mode S, insert-mode <C-s>, et cetera
function! s:target(symbol,start,end,...) "if final argument passed, this is buffer-local
  if a:0 "surprisingly, below is standard vim script syntax
    " silent! unlet g:surround_{char2nr(a:symbol)}
    let b:surround_{char2nr(a:symbol)}=a:start."\r".a:end
  else
    let g:surround_{char2nr(a:symbol)}=a:start."\r".a:end
  endif
endfunction

"------------------------------------------------------------------------------"
"Define global, *insertable* vim-surround targets
"Multichar Delims: Surround can 'put' them, but cannot 'find' them
"e.g. in a ds<custom-target> or cs<custom-target><other-target> command.
"Single Delims: Delims *can* be 'found' if they are single character, but
"setting g:surround_does not do so -- instead, just map commands
"------------------------------------------------------------------------------"
"* Hit ga to get ASCII code (leftmost number; not the HEX code!)
"* Note that if you just enter some uncoded character, will
"  use that as a delimiter -- e.g. yss` surrounds with backticks
"* Note double quotes are required, because surround-vim wants
"  the literal \r return character.
"c for curly brace
" let g:surround_{char2nr('c')}="{\r}"
call s:target('c', '{', '}')
nmap dsc dsB
nmap csc csB
"f for functions, with user prompting
call s:target('f', "\1function: \1(", ')') "initial part is for prompt, needs double quotes
nnoremap dsf mzF(bdt(xf)x`z
nnoremap <expr> csf 'F(hciw'.input('function: ').'<Esc>'
"\ for \" escaped quotes \"
call s:target('\', '\"', '\"')
nmap ds\ /\\"<CR>xxdN
nmap cs\ /\\"<CR>xNx
"p for print
"then just use dsf, csf, et cetera to delete
call s:target('p', 'print(', ')')

"------------------------------------------------------------------------------"
"Apply the above concepts to LaTeX in particular
"This makes writing in LaTeX a ton easier
augroup tex_delimit
  au!
  au FileType tex call s:texsurround()
augroup END
function! s:texsurround()
  "'l' for commands
  call s:target('l', "\1command: \1{", '}')
  nmap <buffer> dsl F{F\dt{dsB
  nmap <buffer> <expr> csl 'F{F\lct{'.input('command: ').'<Esc>F\'
  "'L' for environments
  "Note uppercase registers *append* to previous contents
  call s:target('L', "\\begin{\1\\begin{\1}", "\n"."\\end{\1\1}")
  nnoremap <buffer> dsL :let @/='\\end{[^}]\+}.*\n'<CR>dgn:let @/='\\begin{[^}]\+}.*\n'<CR>dgN
  nnoremap <expr> <buffer> csL ':let @/="\\\\end{\\zs[^}]\\+\\ze}"<CR>cgn'
           \ .input('\begin{')
           \ .'<Esc>h:let @z="<C-r><C-w>"<CR>:let @/="\\\\begin{\\zs[^}]\\+\\ze}"<CR>cgN<C-r>z<Esc>'
  " nmap <buffer> dsL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>dp<Up>V<Up>d
  " nmap <buffer> <expr> csL '/\\end{<CR>:noh<CR>A!!!<Esc>^%f{<Right>ciB'
  " \.input('\begin{').'<Esc>/!!!<CR>:noh<CR>A {<C-r>.}<Esc>2F{dt{'
  "Quotations
  call s:target('q', '`',  "'",  1)
  call s:target('Q', '``', "''", 1)
  nnoremap <buffer> dsq f'xF`x
  nnoremap <buffer> dsQ 2f'F'2x2F`2x

  "Next delimiters generally not requiring new lines
  "Math mode brackets
  call s:target('|', '\left\|', '\right\|', 1)
  call s:target('{', '\left\{', '\right\}', 1)
  call s:target('(', '\left(',  '\right)',  1)
  call s:target('[', '\left[',  '\right]',  1)
  call s:target('<', '\left<',  '\right>',  1)
  "Arrays and whatnot; analagous to above, just point to right
  call s:target('}', '\left\{\begin{array}{ll}', "\n".'\end{array}\right.', 1)
  call s:target(')', '\begin{pmatrix}',          "\n".'\end{pmatrix}',      1)
  call s:target(']', '\begin{bmatrix}',          "\n".'\end{bmatrix}',      1)
  "Font types
  call s:target('o', '{\color{red}', '}', 1)
  call s:target('i', '\textit{',     '}', 1)
  call s:target('t', '\textbf{',     '}', 1)
  call s:target('E', '\emph{'  ,     '}', 1) "use e for times 10 to the whatever
  call s:target('u', '\underline{',  '}', 1)
  call s:target('m', '\mathrm{',     '}', 1)
  call s:target('n', '\mathbf{',     '}', 1)
  call s:target('M', '\mathcal{',    '}', 1)
  call s:target('N', '\mathbb{',     '}', 1)
  "Verbatim
  call s:target('y', '\texttt{',     '}', 1) "typewriter text
  call s:target('Y', '\pyth$',       '$', 1) "python verbatim
  call s:target('V', '\verb$',       '$', 1) "verbatim
  "Math modifiers for symbols
  call s:target('v', '\vec{',        '}', 1)
  call s:target('d', '\dot{',        '}', 1)
  call s:target('D', '\ddot{',       '}', 1)
  call s:target('h', '\hat{',        '}', 1)
  call s:target('`', '\tilde{',      '}', 1)
  call s:target('-', '\overline{',   '}', 1)
  call s:target('_', '\cancelto{}{', '}', 1)
  "Boxes; the second one allows stuff to extend into margins, possibly
  call s:target('x', '\boxed{',      '}', 1)
  call s:target('X', '\fbox{\parbox{\textwidth}{', '}}\medskip', 1)
  "Simple enivronments, exponents, etc.
  call s:target('\', '\sqrt{',       '}',   1)
  call s:target('$', '$',            '$',   1)
  call s:target('e', '\times10^{',   '}',   1)
  call s:target('k', '^{',           '}',   1)
  call s:target('j', '_{',           '}',   1)
  call s:target('K', '\overset{}{',  '}',   1)
  call s:target('J', '\underset{}{', '}',   1)
  call s:target('/', '\dfrac{',      '}{}', 1)
  "Sections and titles
  call s:target('~', '\title{',     '}',   1)
  call s:target('!', '\frametitle{',     '}',   1)
  call s:target('1', '\section{',        '}',   1)
  call s:target('2', '\subsection{',     '}',   1)
  call s:target('3', '\subsubsection{',  '}',   1)
  call s:target('4', '\section*{',       '}',   1)
  call s:target('5', '\subsection*{',    '}',   1)
  call s:target('6', '\subsubsection*{', '}',   1)
  "Shortcuts for citations and such
  call s:target('7', '\ref{',     '}', 1) "just the number
  call s:target('8', '\autoref{', '}', 1) "name and number; autoref is part of hyperref package
  call s:target('9', '\label{',   '}', 1) "declare labels that ref and autoref point to
  call s:target('0', '\tag{',     '}', 1) "change the default 1-2-3 ordering; common to use *
  call s:target('a', '\caption{', '}', 1) "amazingly 'a' not used yet
  call s:target('A', '\captionof{figure}{', '}', 1) "alternative
  " call s:target('z', '\note{',    '}', 1) "notes are for beamer presentations, appear in separate slide
  "Other stuff like citenum/citep (natbib) and textcite/authorcite (biblatex) must be done manually
  "Have been rethinking this
  call s:target('c', '\cite{',   '}', 1) "second most common one
  call s:target('C', '\citenum{',    '}', 1) "most common
  call s:target('z', '\citep{',   '}', 1) "second most common one
  call s:target('Z', '\citet{', '}', 1) "most common
  " call s:target('G', '\vcenteredhbox{\includegraphics[width=\textwidth]{', '}}', 1) "use in beamer talks
  "The next enfironments will also insert *newlines*
  "Frame; fragile option makes verbatim possible (https://tex.stackexchange.com/q/136240/73149)
  "note that fragile make compiling way slower
  "Slide with 'w'hite frame is the w map
  call s:target('g', '\makebox[\textwidth][c]{\includegraphicsawidth=\textwidth]{', '}}', 1) "center across margins
  call s:target('s', '\begin{frame}',                          "\n".'\end{frame}' , 1)
  call s:target('S', '\begin{frame}[fragile]',                 "\n".'\end{frame}' , 1)
  call s:target('w', '{\usebackgroundtemplate{}\begin{frame}', "\n".'\end{frame}}', 1)
  "Figure environments, and pages
  call s:target('p', '\begin{minipage}{\linewidth}', "\n".'\end{minipage}', 1)
  call s:target('f', '\begin{figure}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{figure}', 1)
  call s:target('f', '\begin{center}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{center}', 1)
  " call s:target('F', '\begin{subfigure}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{subfigure}', 1)
  call s:target('W', '\begin{wrapfigure}{r}{.5\textwidth}'."\n".'\centering'."\n".'\includegraphics{', "}\n".'\end{wrapfigure}')
  "Equations
  call s:target('%', '\begin{equation*}', "\n".'\end{equation*}')
  call s:target('^', '\begin{align*}', "\n".'\end{align*}')
  call s:target('T', '\begin{tabular}{', "}\n".'\end{tabular}')
  "Itemize environments
  call s:target('*', '\begin{itemize}',                  "\n".'\end{itemize}')
  call s:target('&', '\begin{description}',              "\n".'\end{description}') "d is now open
  call s:target('#', '\begin{enumerate}',                "\n".'\end{enumerate}')
  call s:target('@', '\begin{enumerate}[label=\alph*.]', "\n".'\end{enumerate}')
  "Versions of the above, but this time puting them on own lines
  "TODO: fix these
  " * The onlytextwidth option keeps two-columns (any arbitrary widths) aligned
  "   with default single column; see: https://tex.stackexchange.com/a/366422/73149
  " * Use command \rule{\textwidth}{<any height>} to visualize blocks/spaces in document
  " call s:target(',;', '\begin{center}',             '\end{center}')               "because ; was available
  " call s:target(',:', '\newpage\hspace{0pt}\vfill', '\vfill\hspace{0pt}\newpage') "vertically centered page
  " call s:target(',c', '\begin{columns}[c]',         '\end{columns}')
  " call s:target(',y', '\begin{python}',             '\end{python}')
  " " call s:target('c', '\begin{columns}[t,onlytextwidth]', '\end{columns}')
  "   "not sure what these args are for; c will vertically center
  " call s:target(',C', '\begin{column}{.5\textwidth}',     '\end{column}')
  " call s:target(',b', '\begin{block}{}',                  '\end{block}')
  " call s:target(',B', '\begin{alertblock}{}',             '\end{alertblock}')
  " call s:target(',v', '\begin{verbatim}',                 '\end{verbatim}')
  " call s:target(',V', '\begin{code}',                     '\end{code}')
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
  call s:target('h', '<head>',   '</head>',   1)
  call s:target('b', '<body>',   '</body>',   1)
  call s:target('t', '<title>',  '</title>',  1)
  call s:target('e', '<em>',     '</em>',     1)
  call s:target('t', '<strong>', '</strong>', 1)
  call s:target('p', '<p>',      '</p>',      1)
  call s:target('1', '<h1>',     '</h1>',     1)
  call s:target('2', '<h2>',     '</h2>',     1)
  call s:target('3', '<h3>',     '</h3>',     1)
  call s:target('4', '<h4>',     '</h4>',     1)
  call s:target('5', '<h5>',     '</h5>',     1)
endfunction

