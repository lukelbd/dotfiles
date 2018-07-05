"------------------------------------------------------------------------------"
"Plugin by Luke Davis <lukelbd@gmail.com>
"------------------------------------------------------------------------------"
"This plugin is inspired by the 'surround.vim' plugin, just a git more succinct syntax
"For example, instead of ysiwb (ys=command prefix, iw=movement, b=delimit specifier)
"we just call ;b -- also is easily extensible to insert mode. But we keep many of
"the original bindings.
"------------------------------------------------------------------------------"
"First some notes about current functionality
" * See documentation in ~/.vim/doc for details, but the gist is:
" * cs<delim><newdelim> to e.g. change surrounding { into (
" * ds<delim> to e.g. delete the surrounding {
" * ys<movement/inner something/block indicator><newdelim> to e.g. add quotes
"       around word iw, add parentheses between cursor and W movement, etc.
" * yss is special case (should be memorized; ys"special"); performs for entire
"       line, ignoring leading/trailing whitespace
" * yS<movement><newdelim> puts text on line of its own, and auto-indents
"       according to indent settings
" * S<newdelim>, VISUAL MODE remap to place surroundings
"       if your <newdelim> is something like <a>, then by default the first one
"       will be <a> and the closing one </a>, for HTML useage
" * t,< will generically refer to ANY HTML-environment
" * ], [ are different; the first adds no space, the second *does* add space
" * b, B, r, a correspond to ), }, ], > (second 2 should be memorized, first 2
"       are just like vim)
" * p is a Vim-paragraph (block between blank lines)
"##############################################################################"
"Expand the functionality of the cs, ds, etc. commands; manipulating
"surrounding delimiters
"##############################################################################"
if !exists("g:plugs")
  echo "Warning: vim-plugs required to check if dependency plugins are installed."
  finish
endif
if !has_key(g:plugs, "vim-surround")
  finish
endif
"Alias the BUILTIN ds[, ds(, etc. behavior for NEW KEY-CONVENTIONS introduced by SURROUND
"Function simply matches these builtin VIM methods with a new delimiter-identifier
function! s:surround(original,new)
  exe 'nnoremap da'.a:original.' da'.a:new
  exe 'nnoremap di'.a:original.' di'.a:new
  exe 'nnoremap ca'.a:original.' ca'.a:new
  exe 'nnoremap ci'.a:original.' ci'.a:new
  exe 'nnoremap ya'.a:original.' ya'.a:new
  exe 'nnoremap yi'.a:original.' yi'.a:new
  exe 'nnoremap <silent> va'.a:original.' mVva'.a:new
  exe 'nnoremap <silent> vi'.a:original.' mVvi'.a:new
endfunction
for s in ['r[', 'a<', 'c{']
  call s:surround(s[0], s[1]) "most simple ones
endfor
"Alias all SURROUND curly-bracket commands with c
nmap dsc dsB
  "delete curlies
nmap cscb csBb
nmap cscr csBr
nmap csca csBa
  "to curlies
nmap csbc csbB
nmap csrc csbB
nmap csac csbB
  "from curlies
"Similar idea for functions, i.e. text formatted like foo(bar)
"Mimick builtin Vim syntax, and the Surround plugin with dsf
nnoremap <silent> daf mzF(bdt(lda(`z
nnoremap <silent> caf F(bdt(lca(
nnoremap <silent> yaf mzF(bvf(%y`z
nnoremap <silent> vaf F(bmVvf(%
nnoremap <silent> dsf mzF(bdt(xf)x`z
nnoremap <silent> <expr> csf 'mzF(bct('.input('Enter new function name: ').'<Esc>`z'
"Selecting text in-between commented out lines
nnoremap <expr> vic "/^\\s*".b:NERDCommenterDelims['left']."<CR><Up>$mVvN<Down>0<Esc>:noh<CR>gv"

"##############################################################################"
" Define a totally new syntax based on semicolon, instead of that funky
" ysiwb stuff. Create functions to facilitate making new bindings in this style.
"##############################################################################"
"Mimick the ysiwb command (i.e. adding delimiters to current word) for new delimiters
"The following functions create arbitrary delimtier maps; current convention is
"to prefix with ';' and ','; see below for details
function! s:delims(map,left,right,buffer,bigword)
  let leftjump=(a:bigword ? "B" : "b")
  let rightjump=(a:bigword ? "E" : "e")
  let buffer=(a:buffer ? " <buffer> " : "")
  let offset=(a:right=~"|" ? 1 : 0) "need special consideration when doing | maps, but not sure why
  "Normal mode maps
  "Note that <silent> works, but putting :silent! before call to repeat does not, weirdly
  "The <Plug> maps are each named <Plug>(prefix)(key), for example <Plug>;b for normal mode bracket map
  " * Warning: it seems (the) movements within this remap can trigger MatchParen action,
  "   due to its CursorMovedI autocmd perhaps.
  " * Added eventignore manipulation because it makes things considerably faster
  "   especially when matchit regexes try to highlight unmatched braces. Considered
  "   changing :noautocmd but that can't be done for a remap; see :help <mod>
  " * Will retain cursor position, but adjusted to right by length of left delimiter.
  exe 'nnoremap <silent> '.buffer.' <Plug>n'.a:map.' '
    \.':let b:indentexpr=&l:indentexpr<CR>:setlocal noautoindent indentexpr=<CR>'
    \.':setlocal eventignore=CursorMoved,CursorMovedI<CR>'
    \.'mzl'.leftjump.'i'.a:left.'<Esc>h'.rightjump.'a'.a:right.'<Esc>`z'.len(a:left).'l'
    \.':call repeat#set("\<Plug>n'.a:map.'",v:count)<CR>'
    \.':setlocal autoindent eventignore=<CR>:let &l:indentexpr=b:indentexpr<CR>'
  exe 'nmap '.a:map.' <Plug>n'.a:map
  "Non-repeatable map
  " exe 'nnoremap '.buffer.' '.a:map.' '
  "   \.':let b:indentexpr=&l:indentexpr<CR>:setlocal noautoindent indentexpr=<CR>'
  "   \.':setlocal eventignore=CursorMoved,CursorMovedI<CR>'
  "   \.'mzl'.leftjump.'i'.a:left.'<Esc>h'.rightjump.'a'.a:right.'<Esc>`z'
  "   \.':setlocal autoindent eventignore=<CR>:let &l:indentexpr=b:indentexpr<CR>'
  if !a:bigword "don't map if a WORD map; they are identical
    "Visual map
    exe 'vnoremap <silent> '.buffer.' '.a:map.' <Esc>'
      \.':let b:indentexpr=&l:indentexpr<CR>:setlocal noautoindent indentexpr=<CR>'
      \.':setlocal eventignore=CursorMoved,CursorMovedI<CR>'
      \.'`>a'.a:right.'<Esc>`<i'.a:left.'<Esc>'.repeat('<Left>',len(a:left)-1-offset)
      \.':setlocal autoindent eventignore=<CR>:let &l:indentexpr=b:indentexpr<CR>'
    "Insert map
    exe 'inoremap '.buffer.' '.a:map.' '.a:left.a:right.repeat('<Left>',len(a:right)-offset)
  endif
endfunction
"Next, similar to above, but always place stuff on newlines
function! s:environs(map,left,right)
  exe 'inoremap <silent> <buffer> ,'.a:map.' '.a:left.'<CR>'.a:right.'<Up><End><CR>'
  exe 'nnoremap <silent> <buffer> ,'.a:map.' mzO'.a:left.'<Esc><Down>o'.a:right.'<Esc>`z=='
  exe 'vnoremap <silent> <buffer> ,'.a:map.' <Esc>`>a<CR>'.a:right.'<Esc>`<i'.a:left.'<CR><Esc><Up><End>'.repeat('<Left>',len(a:left)-1)
    "don't gotta worry about repeat command here, because cannot do that in visual
    "or insert mode; doesn't make sense anyway because we rarely have to do something like
    "100 times in insert mode/visual mode repeatedly, but often have to do so in normal mode
endfunction
"More advanced 'delimiters' and aliases for creating delimiters
"Arguments are as follows:
"1. Shortcut key
"2. Left-hand delimiter
"3. Right-hand delimiter
"4. Whether the map is buffer-local
"5. Whether the normal-mode map is for WORD instead of word
"   In this last case, only the normal-mode map is defined.
call s:delims(';p', 'print(', ')', 0, 0)
call s:delims(';P', 'print(', ')', 0, 1)
call s:delims(';b', '(', ')', 0, 0)
call s:delims(';B', '(', ')', 0, 1)
call s:delims(';c', '{', '}', 0, 0)
call s:delims(';C', '{', '}', 0, 1)
call s:delims(';r', '[', ']', 0, 0)
call s:delims(';R', '[', ']', 0, 1)
call s:delims(';a', '<', '>', 0, 0)
call s:delims(';A', '<', '>', 0, 1)
call s:delims(";'", "'", "'", 0, 0)
call s:delims(';"', '"', '"', 0, 0)
call s:delims(';$', '$', '$', 0, 0)
call s:delims(';*', '*', '*', 0, 0)
call s:delims(';`', '`', '`', 0, 0)
call s:delims(';\', '\"', '\"', 0, 0)
vnoremap ;f <Esc>`>a)<Esc>`<i(<Esc>hi
nnoremap ;f lbmzi(<Esc>hea)<Esc>`zi
nnoremap ;F lBmzi(<Esc>hEa)<Esc>`zi
  "special function that inserts brackets, then
  "puts your cursor in insert mode at the start so you can make a function call
"Repair semicolon in insert mode
"Also offer 'cancelling' completion with Escape
inoremap ;; ;
inoremap ;: ;;
inoremap ;<Esc> ;<Esc>

"###############################################################################
" Now apply the above concepts to LaTeX in particular
" This makes writing in LaTeX a ton easier
"##############################################################################"
augroup tex_delimit
  au!
  au FileType tex call s:texmacros()
augroup END
function! s:texmacros()
  "Repair comma-macros, and period/comma in insert mode
  "Offer 'cancelling' completion with escape
  inoremap <buffer> .<Esc> <Nop>
  inoremap <buffer> ,<Esc> <Nop>
  inoremap <buffer> .. .
  inoremap <buffer> ,, ,
  nnoremap <buffer> ,, @q
    "special exception; otherwise my 'macro repitition' shortcut fails in LaTeX documents
  "Quick way of declaring \latex{} commands
  vnoremap <buffer> <expr> ;. '<Esc>mz`>a}<Esc>`<i\'.input('Enter \<name>{}-style environment name: ').'{<Esc>`z'
  nnoremap <buffer> <expr> ;. 'mzviw<Esc>`>a}<Esc>`<i\'.input('Enter \<name>{}-style environment name: ').'{<Esc>`z'
  inoremap <buffer> <expr> ;. '\'.input('Enter \<name>{}-style environment name: ').'{}<Left>'
  "Quick way of declaring begin-end environments
  "1) start newline and enter \begin{}, then exit, then input new environment name inside, then exit
  "2) paste name (line looks like \begin{name}name)
  "3) wrap pasted name in \end{}
  "4) place newlines in appropriate positions -- for the visual remap, adding new lines
  "   messes up the < and > marks, so need to do that at end
  nnoremap <buffer> <expr> ,. 'A<CR>\begin{}<Esc>i'.input('Enter begin-end environment name: ').'<Esc>'
        \.'$".pF}a\end{<Esc>A}<Esc>F}a<CR><Esc><Up>A<CR>'
  " vnoremap <buffer> <expr> ,. '<Esc>mz`>a\end{'.input('Enter begin-end-style environment name: ').'}<Esc>yiB'
  "       \.'F\i<CR><Esc>==`<i\begin{}<Esc>"aPf}a<CR><Esc><Up>V/\\end{<CR>==:noh<CR>`z'
  vnoremap <buffer> <expr> ,. '<Esc>mz`>a<CR>\end{}<Esc>i'.input('Enter begin-end-style environment name: ').'<Esc>=='
        \.'`<i\begin{<C-r>.}<CR><Esc><Up>==`z'
        " \.'F\i<CR><Esc>==`<i\begin{}<Esc>"aPf}a<CR><Esc><Up>V/\\end{<CR>==:noh<CR>`z'
  inoremap <buffer> <expr> ,. '<CR>\begin{}<Esc>i'.input('Enter begin-end environment name: ').'<Esc>'
        \.'$".pF}a\end{<Esc>A}<Esc>F}a<CR><Esc><Up>A<CR>'
  "Apply 'inner'/'outer'/'surround' syntax to \command{text} and \begin{env}text\end{env}
  nmap <buffer> dsl F{F\dt{dsB
  nnoremap <buffer> <expr> csl 'mzF{F\lct{'.input('Enter new \<name>{}-style environment name: ').'<Esc>`z'
  nnoremap <buffer> dal F{F\dt{daB
  nnoremap <buffer> cal F{F\dt{caB
  nnoremap <buffer> yal F{F\vf{%y
  nnoremap <buffer> val F{F\vf{%
  nnoremap <buffer> dil diB
  nnoremap <buffer> cil ciB
  nnoremap <buffer> yil yiB
  nnoremap <buffer> vil viB
  "Fix for $$, since Vim won't do any ca$ va$ et cetera commands on them
  "Surround syntax will already work, i.e. ds$ works fine
  nnoremap <buffer> da$ F$df$
  nnoremap <buffer> ca$ F$cf$
  nnoremap <buffer> ya$ F$yf$
  nnoremap <buffer> va$ F$vf$
  nnoremap <buffer> di$ T$dt$
  nnoremap <buffer> ci$ T$ct$
  nnoremap <buffer> yi$ T$yt$
  nnoremap <buffer> vi$ T$vt$
  "Selecting LaTeX begin/end environments as best we can, using %-jumping 
  "enhanced by an ftplugin if possible.
  nmap <silent> <buffer> viL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>
  nmap <silent> <buffer> diL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>d
  nmap <silent> <buffer> ciL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>cc
  nmap <silent> <buffer> vaL /\\end{<CR>:noh<CR>V^%
  nmap <silent> <buffer> daL /\\end{<CR>:noh<CR>V^%d
  nmap <silent> <buffer> caL /\\end{<CR>:noh<CR>V^%cc
  nmap <silent> <buffer> dsL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>dp<Up>V<Up>d
  nmap <silent> <buffer> <expr> csL '/\\end{<CR>:noh<CR>APLACEHOLDER<Esc>^%f{<Right>ciB'
    \.input('Enter new begin-end environment name: ').'<Esc>/PLACEHOLDER<CR>:noh<CR>A {<C-r>.}<Esc>2F{dt{'
  "Next, latex quotes
  nnoremap <buffer> dsq f'xF`x
  nnoremap <buffer> daq F`df'
  nnoremap <buffer> diq T`dt'
  nnoremap <buffer> caq F`cf'
  nnoremap <buffer> ciq T`ct'
  nnoremap <buffer> yaq F`yf'
  nnoremap <buffer> yiq T`yt'
  nnoremap <buffer> vaq F`vf'
  nnoremap <buffer> viq T`vt'
  nnoremap <buffer> dsQ 2f'F'2x2F`2x
  nnoremap <buffer> daQ 2F`d2f'
  nnoremap <buffer> diQ T`dt'
  nnoremap <buffer> caQ 2F`c2f'
  nnoremap <buffer> ciQ T`ct'
  nnoremap <buffer> yaQ 2F`y2f'
  nnoremap <buffer> yiQ T`yt'
  nnoremap <buffer> vaQ 2F`v2f'
  nnoremap <buffer> viQ T`vt'
  "Delimiters (advanced)/quick environments
  "First the delimiters without newlines
  " call s:delims('\|', '\left\\|', '\right\\|', 1)
  call s:delims(';\|', '\left\|',      '\right\|', 1, 0)
  call s:delims(';{',  '\left\{',      '\right\}', 1, 0)
  call s:delims(';(',  '\left(',       '\right)',  1, 0)
  call s:delims(';[',  '\left[',       '\right]',  1, 0)
  call s:delims(';<',  '\left<',       '\right>',  1, 0)
  call s:delims(';o', '{\color{red}', '}', 1, 0)
  call s:delims(';i', '\textit{',     '}', 1, 0)
  call s:delims(';t', '\textbf{',     '}', 1, 0) "now use ;i for various cite commands
  call s:delims(';y', '\texttt{',     '}', 1, 0) "typewriter text
  call s:delims(';u', '\underline{',  '}', 1, 0) "u for under
  call s:delims(';l', '\linespread{',  '}', 1, 0) "u for under
  call s:delims(';m', '\mathrm{',     '}', 1, 0)
  call s:delims(';n', '\mathbf{',     '}', 1, 0)
  call s:delims(';M', '\mathcal{',    '}', 1, 0)
  call s:delims(';N', '\mathbb{',     '}', 1, 0)
  call s:delims(';v', '\vec{',        '}', 1, 0)
  call s:delims(';V', '\verb$',       '$', 1, 0) "verbatim
  call s:delims(';d', '\dot{',        '}', 1, 0)
  call s:delims(';D', '\ddot{',       '}', 1, 0)
  call s:delims(';h', '\hat{',        '}', 1, 0)
  call s:delims(';`', '\tilde{',      '}', 1, 0)
  call s:delims(';-', '\overline{',   '}', 1, 0)
  call s:delims(';\', '\cancelto{}{', '}', 1, 0)
  call s:delims(';x', '\boxed{',      '}', 1, 0)
  call s:delims(';X', '\fbox{\parbox{\textwidth}{', '}}\medskip', 1, 0)
    "the second one allows stuff to extend into margins, possibly
  call s:delims(';/', '\sqrt{',     '}',  1, 0)
  call s:delims(';q', '`',          "'",  1, 0)
  call s:delims(';Q', '``',         "''", 1, 0)
  call s:delims(';$', '$',          '$',  1, 0)
  call s:delims(';e', '\times10^{', '}',  1, 0)
  call s:delims(';k', '^{',         '}',  1, 0)
  call s:delims(';j', '_{',         '}',  1, 0)
  call s:delims(';K', '\overset{}{', '}', 1, 0)
  call s:delims(';J', '\underset{}{',     '}',   1, 0)
  call s:delims(';f', '\dfrac{',          '}{}', 1, 0)
  call s:delims(';0', '\frametitle{',     '}',   1, 0)
  call s:delims(';1', '\section{',        '}',   1, 0)
  call s:delims(';2', '\subsection{',     '}',   1, 0)
  call s:delims(';3', '\subsubsection{',  '}',   1, 0)
  call s:delims(';4', '\section*{',       '}',   1, 0)
  call s:delims(';5', '\subsection*{',    '}',   1, 0)
  call s:delims(';6', '\subsubsection*{', '}',   1, 0)
  "Shortcuts for citations and such
  call s:delims(';7', '\ref{',     '}', 1, 0) "just the number
  call s:delims(';8', '\autoref{', '}', 1, 0) "name and number; autoref is part of hyperref package
  call s:delims(';9', '\label{',   '}', 1, 0) "declare labels that ref and autoref point to
  call s:delims(';!', '\tag{',     '}', 1, 0) "change the default 1-2-3 ordering; common to use *
  call s:delims(';z', '\note{',    '}', 1, 0) "notes are for beamer presentations, appear in separate slide
  call s:delims(';a', '\caption{', '}', 1, 0) "amazingly a not used yet
  call s:delims(';A', '\captionof{figure}{', '}', 1, 0) "alternative
  call s:delims(';*', '\cite{',    '}', 1, 0) "most common
  call s:delims(';&', '\citet{',   '}', 1, 0) "second most common one
  call s:delims(';@', '\citep{',   '}', 1, 0) "second most common one
  call s:delims(';#', '\citenum{', '}', 1, 0) "most common
    "other stuff like citenum/citep (natbib) and textcite/authorcite (biblatex) must be done manually
    "have been rethinking this
  "Shortcuts for graphics
  call s:delims(';g', '\includegraphics{', '}', 1, 0)
  call s:delims(';G', '\makebox[\textwidth][c]{\includegraphicsawidth=\textwidth]{', '}}', 1, 0) "center across margins
  " call s:delims('G', '\vcenteredhbox{\includegraphics[width=\textwidth]{', '}}', 1) "use in beamer talks
  "Comma-prefixed delimiters without newlines
  "Generally are more closely-related to the begin-end latex environments
  inoremap <buffer> ,1 \tiny 
  inoremap <buffer> ,2 \scriptsize 
  inoremap <buffer> ,3 \footnotesize 
  inoremap <buffer> ,4 \small 
  inoremap <buffer> ,5 \normalsize 
  inoremap <buffer> ,6 \large 
  inoremap <buffer> ,7 \Large 
  inoremap <buffer> ,8 \LARGE 
  inoremap <buffer> ,9 \huge 
  inoremap <buffer> ,0 \Huge 
  call s:delims(',!', '{\tiny ',         '}', 1, 0)
  call s:delims(',@', '{\scriptsize ',   '}', 1, 0)
  call s:delims(',#', '{\footnotesize ', '}', 1, 0)
  call s:delims(',$', '{\small ',        '}', 1, 0)
  call s:delims(',%', '{\normalsize ',   '}', 1, 0)
  call s:delims(',^', '{\large ',        '}', 1, 0)
  call s:delims(',&', '{\Large ',        '}', 1, 0)
  call s:delims(',*', '{\LARGE ',        '}', 1, 0)
  call s:delims(',(', '{\huge ',         '}', 1, 0)
  call s:delims(',)', '{\Huge ',         '}', 1, 0)
  call s:delims(',{', '\left\{\begin{array}{ll}', '\end{array}\right.', 1, 0)
  call s:delims(',m', '\begin{pmatrix}',           '\end{pmatrix}',       1, 0)
  call s:delims(',M', '\begin{bmatrix}',           '\end{bmatrix}',       1, 0)
  "Versions of the above, but this time puting them on own lines
  " call s:environs('P', '\begin{pmatrix}', '\end{pmatrix}')
  " call s:environs('B', '\begin{bmatrix}', '\end{bmatrix}')
  "Comma-prefixed delimiters with newlines; these have separate special function because
  "it does not make sense to have normal-mode maps for multiline begin/end environments
  "* The onlytextwidth option keeps two-columns (any arbitrary widths) aligned
  "  with default single column; see: https://tex.stackexchange.com/a/366422/73149
  "* Use command \rule{\textwidth}{<any height>} to visualize blocks/spaces in document
  call s:environs(';', '\begin{center}', '\end{center}') "because ; was available
  call s:environs(':', '\newpage\hspace{0pt}\vfill', '\vfill\hspace{0pt}\newpage') "vertically centered page
  call s:environs('c', '\begin{columns}[c]', '\end{columns}')
  " call s:environs('c', '\begin{columns}[t,onlytextwidth]', '\end{columns}')
    "not sure what these args are for; c will vertically center
  call s:environs('C', '\begin{column}{.5\textwidth}', '\end{column}')
  call s:environs('i', '\begin{itemize}', '\end{itemize}')
  call s:environs('I', '\begin{description}', '\end{description}') "d is now open
  call s:environs('n', '\begin{enumerate}', '\end{enumerate}')
  call s:environs('N', '\begin{enumerate}[label=\alph*.]', '\end{enumerate}')
  call s:environs('t', '\begin{tabular}', '\end{tabular}')
  call s:environs('e', '\begin{equation*}', '\end{equation*}')
  call s:environs('a', '\begin{align*}', '\end{align*}')
  call s:environs('E', '\begin{equation}', '\end{equation}')
  call s:environs('A', '\begin{align}', '\end{align}')
  call s:environs('b', '\begin{block}{}', '\end{block}')
  call s:environs('B', '\begin{alertblock}{}', '\end{alertblock}')
  call s:environs('v', '\begin{verbatim}', '\end{verbatim}')
  call s:environs('V', '\begin{code}', '\end{code}')
  call s:environs('s', '\begin{frame}', '\end{frame}')
  call s:environs('S', '\begin{frame}[fragile]', '\end{frame}')
    "fragile option makes verbatim possible (https://tex.stackexchange.com/q/136240/73149)
    "note that fragile make compiling way slower
  call s:environs('w', '{\usebackgroundtemplate{}\begin{frame}', '\end{frame}}')
    "white frame
  call s:environs('p', '\begin{minipage}{\linewidth}', '\end{minipage}')
  call s:environs('f', '\begin{figure}', '\end{figure}')
  call s:environs('F', '\begin{subfigure}{.5\textwidth}', '\end{subfigure}')
  call s:environs('W', '\begin{wrapfigure}{r}{.5\textwidth}', '\end{wrapfigure}')
  "Single-character maps
  "THIS NEEDS WORK; right now maybe just too confusing
  inoremap <expr> <buffer> .m '\mathrm{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .M '\mathbf{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .h '\hat{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .v '\vec{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .` '\tilde{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .= '\overline{'.nr2char(getchar()).'}'
  " inoremap <expr> <buffer> .M '\mathcal{'.nr2char(getchar()).'}'
  " inoremap <expr> <buffer> .N '\mathbb{'.nr2char(getchar()).'}'
  "Arrows
  inoremap <buffer> ., \pause
  inoremap <buffer> ., \pause
  inoremap <buffer> ., \pause
  inoremap <buffer> ., \pause
  "Misc symbotls
  inoremap <buffer> ., \pause
  inoremap <buffer> .i \item 
  "Math symbols
  inoremap <buffer> .a \alpha 
  inoremap <buffer> .b \beta 
  inoremap <buffer> .c \xi 
  inoremap <buffer> .C \Xi 
    "weird curly one
    "the upper case looks like 3 lines
  inoremap <buffer> .x \chi 
    "looks like an x so want to use this map
    "pronounced 'zi', the 'i' in 'tide'
  inoremap <buffer> .d \delta 
  inoremap <buffer> .D \Delta 
  inoremap <buffer> .f \phi 
  inoremap <buffer> .F \Phi 
  inoremap <buffer> .g \gamma 
  inoremap <buffer> .G \Gamma 
  " inoremap <buffer> .k \kappa
  inoremap <buffer> .l \lambda 
  inoremap <buffer> .L \Lambda 
  inoremap <buffer> .u \mu 
  inoremap <buffer> .n \nabla 
  inoremap <buffer> .N \nu 
  inoremap <buffer> .e \epsilon 
  inoremap <buffer> .E \eta 
  inoremap <buffer> .p \pi 
  inoremap <buffer> .P \Pi 
  inoremap <buffer> .q \theta 
  inoremap <buffer> .Q \Theta 
  inoremap <buffer> .r \rho 
  inoremap <buffer> .s \sigma 
  inoremap <buffer> .S \Sigma 
  inoremap <buffer> .t \tau 
  inoremap <buffer> .y \psi 
  inoremap <buffer> .Y \Psi 
  inoremap <buffer> .w \omega 
  inoremap <buffer> .W \Omega 
  inoremap <buffer> .z \zeta 
  inoremap <buffer> .1 \partial 
  inoremap <buffer> .2 \mathrm{d}
  inoremap <buffer> .3 \mathrm{D}
  "3 levels of differentiation; each one stronger
  inoremap <buffer> .4 \sum 
  inoremap <buffer> .5 \prod 
  inoremap <buffer> .6 \int 
  inoremap <buffer> .7 \iint 
  inoremap <buffer> .8 \oint 
  inoremap <buffer> .9 \oiint 
  inoremap <buffer> .x \times 
  inoremap <buffer> .o \cdot 
  inoremap <buffer> .O \circ 
  inoremap <buffer> .- {-}
  inoremap <buffer> .+ {+}
  inoremap <buffer> .~ {\sim}
  inoremap <buffer> .k ^
  inoremap <buffer> .j _
  inoremap <buffer> ., \,
  inoremap <buffer> ._ {\centering\noindent\rule{\paperwidth/2}{0.7pt}}
    "centerline (can modify this; \rule is simple enough to understand)
  "Commands for compiling latex
  "-use clear, because want to clean up previous output first
  "-use set -x to ECHO LAST COMMAND
  "-use c-x for compile/run, and c-w for creating Word document
  noremap <silent> <buffer> <Leader>x :w<CR>:exec("!clear; set -x; "
      \.'~/bin/compile '.shellescape(@%).' true')<CR>
  noremap <silent> <buffer> <C-b> :w<CR>:exec("!clear; set -x; "
      \.'~/bin/compile '.shellescape(@%).' false')<CR>
  inoremap <silent> <buffer> <C-b> <Esc>:w<CR>:exec("!clear; set -x; "
      \.'~/bin/compile '.shellescape(@%).' false')<CR>a
  "This section is weird; C-@ is same as C-Space (google it), and
  "S-Space sends hex codes for F1 in iTerm (enter literal characters in Vim and
  "use ga commands to get the hex codes needed)
  "Why do this? Because want to keep these maps consistent with system map to count
  "highlighted text; and mapping that command to some W-combo is dangerous; may
  "accidentally close a window
  noremap <silent> <buffer> <C-@> :exec("!clear; set -x; "
      \.'ps2ascii '.shellescape(expand('%:p:r').'.pdf').' 2>/dev/null \| wc -w')<CR>
  noremap <silent> <buffer> <F1> :exec('!clear; set -x; open -a Skim; '
      \.'osascript ~/bin/wordcount.scpt '.shellescape(expand('%:p:r').'.pdf').'; '
      \.'[ "$TERM_PROGRAM"=="Apple_Terminal" ] && terminal="Terminal" \|\| terminal="$TERM_PROGRAM"; '
      \.'open -a iTerm')<CR>:redraw!<CR>
endfunction

"###############################################################################
"HTML macros
"For now pretty empty, but we should add to this
"##############################################################################"
augroup html_delimit
  au!
  au FileType html call s:htmlmacros()
augroup END
function! s:htmlmacros()
  call s:environs('h', '<head>', '</head>')
  call s:environs('b', '<body>', '</body>')
  call s:environs('t', '<title>', '</title>')
  call s:environs('p', '<p>', '</p>')
  call s:environs('1', '<h1>', '</h1>')
  call s:environs('2', '<h2>', '</h2>')
  call s:environs('3', '<h3>', '</h3>')
  call s:environs('4', '<h4>', '</h4>')
  call s:environs('5', '<h5>', '</h5>')
  call s:delims(',e', '<em>', '</em>', 1, 0)
  call s:delims(',t', '<strong>', '</strong>', 1, 0)
endfunction
