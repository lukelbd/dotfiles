"------------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-07-29
"------------------------------------------------------------------------------"
"This plugin is inspired by the 'surround.vim' plugin.
"Neat tools for working smoothly with delimited text.
"Future:
" * Want to include way to put braces around entire line (ignoring trailing and
"   leading whitespace) like yss<delimiter>.
" * Might want to add similar yS and ySS-commands which behave just like
"   ys and yss, except they put containing text on own line.
" * There's also the S-map in visual mode, and the t-prefix which lets
"   you type in an arbitrary tag.
" * Consider implementing surround feature where ] adds space but [ adds
"   no space.
" * Not sure what vs and vS features do. To be figured out.
" * The broad theme here is that ***IMO the motion-feature offered by surround
"   plugin is overkill***. Generally there's only a few types of blocks
"   that we want to surround with delimiters: selections, words WORDs, lines,
"   and paragraphs (note these would be 'is' and 'ip' in surround).
"Gameplan:
" * Just like S activates visual mode surround.vim, could come up with way
"   to activate it in insert mode. Perhaps yy would work, and fits better
"   with original mnemonic.
" * Could instead use ;-letter for the *Greek letter inserts*, then use
"   sy and sY as analogies for ys and yS.
" * Could change ysiw to ysw, ysiW to ysW, et cetera. Or... simply conform to
"   this more flexible syntax, and make , and ; commands accept range indicators
"   like w, W, l, s, p, et cetera. Perhaps could even make it accept a count,
"   where we wrap around that number of delimiters (e.g. 1;lb would wrap
"   this line and the one above, 1;Lb would wrap this line and the one below, or
"   just have them wrap one line on either side).
" * Note there is already a Ctrl-S insert mode map to insert delimiters,
"   so maybe should just expand that in future. Along with a Ctrl-Y map
"   to insert those ,-prefixed ones.
"Features:
" * Changes to surround mnemonics: now use a for <>, r for [], c for {}, and
"   b for (). Also use ;+key to put braces around words or seletions. Use B, C,
"   et cetera to put braces around WORDs. This replaces most common use of
"   ys<motion><delimiter> command.
" * LaTeX environment mappings: like a hundred different ;-prefixed ,-prefixed
"   and .-prefixed commands, where the usual syntax is <leader><letter>. Those
"   punctuation keys were chosen because they are rarely followed immediately
"   with text. Surround text with {} commands and begin/end statements, and
"   insert math symbols with the press of a .-shortcut.
" * HTML tag mappings: similar to the above; put text inside HTML tags.
"   Still needs to be expanded.
"------------------------------------------------------------------------------"
"###############################################################################
"Get cursor outside current delimiter
"Similar to the delimitMate <C-g>g insert mode command
"Pretty darn useful
"##############################################################################"
"Function for escaping current delimiter
"Just search for braces instead of using percent-mapping, because when
"in the middle of typing often don't particularly *care* if a bracket is completed/has
"a pair -- just see a bracket, and want to get out of it.
"Also percent matching solution would require leaving insert mode, triggering
"various autocmds, and is much slower/jumpier -- vim script solutions are better!
"  ( [ [ ( "  "  asdfad) sdf    ]  sdfad   ]  asdfasdf) hello   asdfas) 
function! s:tabreset()
  let b:tabcount=0 | return ''
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
"Mnemonic here is C-o gets us out; currently not used by any other maps!
"So works perfectly
noremap <expr> ;o <sid>outofdelim(1)
noremap <expr> ;O <sid>outofdelim(10)
inoremap <expr> ;o !pumvisible() ? <sid>outofdelim(1)
  \ : b:tabcount==0 ? "\<C-e>".<sid>tabreset().<sid>outofdelim(1) 
  \ : "\<C-y>".<sid>tabreset().<sid>outofdelim(1)
inoremap <expr> ;O !pumvisible() ? <sid>outofdelim(10)
  \ : b:tabcount==0 ? "\<C-e>".<sid>tabreset().<sid>outofdelim(10) 
  \ : "\<C-y>".<sid>tabreset().<sid>outofdelim(10)

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
nnoremap <silent> csf F(hciw
"And now for lines; already exists for paragraphs
"If on first character of sentence, want to count that as 'current' sentence, so move to right
"Kind of need to use selections always here
nnoremap <silent> dal l(v)hd
nnoremap <silent> cal l(v)hs
nnoremap <silent> yal l(v)hy
nnoremap <silent> val l(v)h
" nnoremap <silent> <expr> csf 'mzF(bct('.input('Enter new function name: ').'<Esc>`z'
"Selecting text in-between commented out lines
"Maybe add other special ideas
nnoremap <expr> vic "/^\\s*".b:NERDCommenterDelims['left']."<CR><Up>$mVvN<Down>0<Esc>:noh<CR>gv"

"##############################################################################"
" Define a totally new syntax based on semicolon, instead of that funky
" ysiwb stuff. Create functions to facilitate making new bindings in this style.
"##############################################################################"
"Mimick the ysiwb command (i.e. adding delimiters to current word) for new delimiters
"The following functions create arbitrary delimtier maps; current convention is
"to prefix with ';' and ','; see below for details
function! s:surround(left, right, class, pad)
  "Initial stuff
  if a:pad==#'n'
    let pad='\n'
  else a:pad==#'w'
    let pad=' '
  else
    let pad=''
  endif
  if a:class==#'w'
    let regex='\(\<\w*\%#\w\+\>\|\%#\S\)' "matches word under cursor, or alternatively, single character
  elseif a:class==#'W'
    let regex='\(\S*\%#\S\+\)'
  elseif a:class==#'v'
    let regex='\(\%V\_.*\%V.\?\)' "matches from *anywhere* inside selection to end of selection
    " let regex='\(\%'."'".'<\_.*\%'."'".'>.\?\)' "matches inside selection; include multiline selections thanks to ._
  else
    echom "Error: Unknown group class \"".a:class."\"" | return
  endif
  echo 's/'.regex.'/'.a:left.'\1'.a:right.'/'
  exe 's/'.regex.'/'.a:left.'\1'.a:right.'/'
  " let @/='/'.regex
endfunction
" hello
" word
" goodbye
function! s:delims(map,left,right,buffer,nclass)
  let buffer=(a:buffer ? " <buffer> " : "")
  let offset=(a:right=~"|" ? 1 : 0) "need special consideration when doing | maps, but not sure why
  let nclass=(a:nclass ? "W" : "w") "use WORD instead of word for normal map
  "Normal mode maps
  "Note that <silent> works, but putting :silent! before call to repeat does not, weirdly
  "The <Plug> maps are each named <Plug>(prefix)(key), for example <Plug>;b for normal mode bracket map
  " * Warning: it seems the movements within this remap can trigger MatchParen action,
  "   due to its CursorMovedI autocmd perhaps.
  " * Added eventignore manipulation because it makes things considerably faster
  "   especially when matchit regexes try to highlight unmatched braces. Considered
  "   changing :noautocmd but that can't be done for a remap; see :help <mod>
  " * Will retain cursor position, but adjusted to right by length of left delimiter.
  exe "nnoremap <silent> ".buffer." <Plug>n".a:map." "
    \.":call <sid>surround('".a:left."','".a:right."','".nclass."','')<CR>``"
    \.":call repeat#set('\\<Plug>n".a:map."',v:count)<CR>"
  exe "nmap ".a:map." <Plug>n".a:map
  "Insert map
  exe "inoremap ".buffer." ".a:map." ".a:left.a:right.repeat("<Left>",len(a:right)-offset)
  "Visual map
  exe "vnoremap ".buffer." ".a:map." :<C-u>call <sid>surround('".a:left."','".a:right."','v','')<CR>``"
endfunction
"Next, similar to above, but always place stuff on newlines
function! s:environs(map,left,right)
  exe 'inoremap <silent> <buffer> '.a:map.' '.a:left.'<CR>'.a:right.'<Up><End><CR>'
  exe 'nnoremap <silent> <buffer> '.a:map.' mzO'.a:left.'<Esc><Down>o'.a:right.'<Esc>`z=='
  exe 'vnoremap <silent> <buffer> '.a:map.' <Esc>`>a<CR>'.a:right.'<Esc>`<i'.a:left.'<CR><Esc><Up><End>'.repeat('<Left>',len(a:left)-1)
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
" inoremap ;<Esc> ;<Esc>
inoremap ;<Esc> <Nop>

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
  inoremap <buffer> ,<Esc> <Nop>
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
  call s:delims(';>\|', '\left\|',      '\right\|', 1, 0)
  call s:delims(';>{',  '\left\{',      '\right\}', 1, 0)
  call s:delims(';>(',  '\left(',       '\right)',  1, 0)
  call s:delims(';>[',  '\left[',       '\right]',  1, 0)
  call s:delims(';><',  '\left<',       '\right>',  1, 0)
  call s:delims(';>o', '{\color{red}', '}', 1, 0)
  call s:delims(';>i', '\textit{',     '}', 1, 0)
  call s:delims(';>t', '\textbf{',     '}', 1, 0) "now use ;i for various cite commands
  call s:delims(';>u', '\underline{',  '}', 1, 0) "u for under
  call s:delims(';>l', '\linespread{',  '}', 1, 0) "u for under
  call s:delims(';>m', '\mathrm{',     '}', 1, 0)
  call s:delims(';>n', '\mathbf{',     '}', 1, 0)
  call s:delims(';>M', '\mathcal{',    '}', 1, 0)
  call s:delims(';>N', '\mathbb{',     '}', 1, 0)
  call s:delims(';>y', '\texttt{',     '}', 1, 0) "typewriter text
  call s:delims(';>Y', '\pyth$',       '$', 1, 0) "python verbatim
  call s:delims(';>v', '\vec{',        '}', 1, 0)
  call s:delims(';>V', '\verb$',       '$', 1, 0) "verbatim
  call s:delims(';>d', '\dot{',        '}', 1, 0)
  call s:delims(';>D', '\ddot{',       '}', 1, 0)
  call s:delims(';>h', '\hat{',        '}', 1, 0)
  call s:delims(';>`', '\tilde{',      '}', 1, 0)
  call s:delims(';>-', '\overline{',   '}', 1, 0)
  call s:delims(';>\', '\cancelto{}{', '}', 1, 0)
  call s:delims(';>x', '\boxed{',      '}', 1, 0)
  call s:delims(';>X', '\fbox{\parbox{\textwidth}{', '}}\medskip', 1, 0)
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
  " call s:environs(',P', '\begin{pmatrix}', '\end{pmatrix}')
  " call s:environs(',B', '\begin{bmatrix}', '\end{bmatrix}')
  "Comma-prefixed delimiters with newlines; these have separate special function because
  "it does not make sense to have normal-mode maps for multiline begin/end environments
  "* The onlytextwidth option keeps two-columns (any arbitrary widths) aligned
  "  with default single column; see: https://tex.stackexchange.com/a/366422/73149
  "* Use command \rule{\textwidth}{<any height>} to visualize blocks/spaces in document
  call s:environs(',;', '\begin{center}', '\end{center}') "because ; was available
  call s:environs(',:', '\newpage\hspace{0pt}\vfill', '\vfill\hspace{0pt}\newpage') "vertically centered page
  call s:environs(',c', '\begin{columns}[c]', '\end{columns}')
  call s:environs(',y', '\begin{python}', '\end{python}')
  " call s:environs('c', '\begin{columns}[t,onlytextwidth]', '\end{columns}')
    "not sure what these args are for; c will vertically center
  call s:environs(',C', '\begin{column}{.5\textwidth}', '\end{column}')
  call s:environs(',i', '\begin{itemize}', '\end{itemize}')
  call s:environs(',I', '\begin{description}', '\end{description}') "d is now open
  call s:environs(',n', '\begin{enumerate}', '\end{enumerate}')
  call s:environs(',N', '\begin{enumerate}[label=\alph*.]', '\end{enumerate}')
  call s:environs(',t', '\begin{tabular}', '\end{tabular}')
  call s:environs(',e', '\begin{equation*}', '\end{equation*}')
  call s:environs(',a', '\begin{align*}', '\end{align*}')
  call s:environs(',E', '\begin{equation}', '\end{equation}')
  call s:environs(',A', '\begin{align}', '\end{align}')
  call s:environs(',b', '\begin{block}{}', '\end{block}')
  call s:environs(',B', '\begin{alertblock}{}', '\end{alertblock}')
  call s:environs(',v', '\begin{verbatim}', '\end{verbatim}')
  call s:environs(',V', '\begin{code}', '\end{code}')
  call s:environs(',s', '\begin{frame}', '\end{frame}')
  call s:environs(',S', '\begin{frame}[fragile]', '\end{frame}')
    "fragile option makes verbatim possible (https://tex.stackexchange.com/q/136240/73149)
    "note that fragile make compiling way slower
  call s:environs(',w', '{\usebackgroundtemplate{}\begin{frame}', '\end{frame}}') "white frame
  call s:environs(',p', '\begin{minipage}{\linewidth}', '\end{minipage}')
  call s:environs(',f', '\begin{figure}', '\end{figure}')
  call s:environs(',F', '\begin{subfigure}{.5\textwidth}', '\end{subfigure}')
  call s:environs(',W', '\begin{wrapfigure}{r}{.5\textwidth}', '\end{wrapfigure}')
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
