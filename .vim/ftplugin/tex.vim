"------------------------------------------------------------------------------"
"LaTeX specific settings
"Not much in here so far; note templates and snippets must be controlled by the vimrc.
"Various syntax settings below; for help, see :help tex-syntax
"------------------------------------------------------------------------------"
"Disable latex spellchecking in comments (works for default syntax file)
let g:tex_comment_nospell=1
"Restrict concealmeant to just symbols and stuff
" a=accents/ligatures
" b=bold/italics
" d=delimiters (e.g. $$ math mode)
" m=math symbols
" g=Greek
" s=superscripts/subscripts
let g:tex_conceal='agm'
" let g:tex_conceal= 'abdmgsS'
"With foldmethod=syntax, can now fold chapters and stuff
let g:tex_fold_enable=1
"Disable spell checking in verbatim mode; this is the default
let g:tex_verbspell=0
"Disable all errors
let g:tex_no_error=1
"Allow @ in makeatletter, allow texmathonly outside of math regions (i.e.
"don't highlight [_^] when you think they are outside math zone
let g:tex_stylish=1
"Fast highlighting, but pretty ugly
" let g:tex_fast= ""
"------------------------------------------------------------------------------"
"Commands for compiling latex
"Use C-z for compiling normally, and <Leader>z for compiling to word document.
noremap <silent> <buffer> <C-z> :w<CR>:exec('!clear; set -x; document '.shellescape(@%).' false')<CR>
noremap <silent> <buffer> <Leader>z :w<CR>:exec('!clear; set -x; document '.shellescape(@%).' true')<CR>
"------------------------------------------------------------------------------"
"Font sizing
inoreabbrev <buffer> ;1 \tiny 
inoreabbrev <buffer> ;2 \scriptsize 
inoreabbrev <buffer> ;3 \footnotesize 
inoreabbrev <buffer> ;4 \small 
inoreabbrev <buffer> ;5 \normalsize 
inoreabbrev <buffer> ;6 \large 
inoreabbrev <buffer> ;7 \Large 
inoreabbrev <buffer> ;8 \LARGE 
inoreabbrev <buffer> ;9 \huge 
inoreabbrev <buffer> ;0 \Huge 
"------------------------------------------------------------------------------"
"Greek letters, mathematical symbols, and other commands
"First arrows, most commonly used ones anyway
inoreabbrev <buffer> ;> \Rightarrow 
inoreabbrev <buffer> ;< \Longrightarrow 
"Misc symbotls, want quick access
inoreabbrev <buffer> ;, \item 
inoreabbrev <buffer> ;/ \pause
"Math symbols
inoreabbrev <buffer> ;a \alpha 
inoreabbrev <buffer> ;b \beta 
inoreabbrev <buffer> ;c \xi 
"weird curly one
"the upper case looks like 3 lines
inoreabbrev <buffer> ;C \Xi 
"looks like an x so want to use this map
"pronounced 'zi', the 'i' in 'tide'
inoreabbrev <buffer> ;x \chi 
"More normal ones
inoreabbrev <buffer> ;d \delta 
inoreabbrev <buffer> ;D \Delta 
inoreabbrev <buffer> ;f \phi 
inoreabbrev <buffer> ;F \Phi 
inoreabbrev <buffer> ;g \gamma 
inoreabbrev <buffer> ;G \Gamma 
inoreabbrev <buffer> ;K \kappa
inoreabbrev <buffer> ;l \lambda 
inoreabbrev <buffer> ;L \Lambda 
inoreabbrev <buffer> ;m \mu 
inoreabbrev <buffer> ;n \nabla 
inoreabbrev <buffer> ;N \nu 
inoreabbrev <buffer> ;e \epsilon 
inoreabbrev <buffer> ;E \eta 
inoreabbrev <buffer> ;p \pi 
inoreabbrev <buffer> ;P \Pi 
inoreabbrev <buffer> ;q \theta 
inoreabbrev <buffer> ;Q \Theta 
inoreabbrev <buffer> ;r \rho 
inoreabbrev <buffer> ;s \sigma 
inoreabbrev <buffer> ;S \Sigma 
inoreabbrev <buffer> ;t \tau 
inoreabbrev <buffer> ;y \psi 
inoreabbrev <buffer> ;Y \Psi 
inoreabbrev <buffer> ;w \omega 
inoreabbrev <buffer> ;W \Omega 
inoreabbrev <buffer> ;z \zeta 
"derivatives
inoreabbrev <buffer> ;` \partial 
inoreabbrev <buffer> ;~ \mathrm{d} 
inoreabbrev <buffer> ;! \mathrm{D} 
"u is for unary
inoreabbrev <buffer> ;U ${-}$
inoreabbrev <buffer> ;u ${+}$
"integration
inoreabbrev <buffer> ;i \int 
inoreabbrev <buffer> ;I \iint 
"3 levels of differentiation; each one stronger
inoreabbrev <buffer> ;+ \sum 
inoreabbrev <buffer> ;* \prod 
inoreabbrev <buffer> ;x \times 
inoreabbrev <buffer> ;o \cdot 
inoreabbrev <buffer> ;O \circ 
inoreabbrev <buffer> ;= \equiv 
inoreabbrev <buffer> ;~ {\sim} 
inoreabbrev <buffer> ;k ^
inoreabbrev <buffer> ;j _
inoreabbrev <buffer> ;, \,
"Insert a line (feel free to modify width)
"Will prompt user for fraction of page
"Note centering fails inside itemize environments, so use begin/end center instead
" inoreabbrev <buffer> <expr> ;_ '{\centering\noindent\rule{'
"   \.input('fraction: ').'\textwidth}{0.7pt}}'
inoreabbrev <buffer> <expr> ;_ '\begin{center}\noindent\rule{'
    \.input('fraction: ').'\textwidth}{0.7pt}\end{center}'
"centerline (can modify this; \rule is simple enough to understand)
"------------------------------------------------------------------------------"
"C-@ is same as C-Space (google it)
"These are pretty much obsolete now
" noremap <silent> <buffer> <F11> :exec("!clear; set -x; "
"     \.'ps2ascii '.shellescape(expand('%:p:r').'.pdf').' 2>/dev/null \| wc -w')<CR>
" noremap <silent> <buffer> <F12> :exec('!clear; set -x; open -a Skim; '
"     \.'osascript ~/bin/wordcount.scpt '.shellescape(expand('%:p:r').'.pdf').'; '
"     \.'[ "$TERM_PROGRAM"=="Apple_Terminal" ] && terminal="Terminal" \|\| terminal="$TERM_PROGRAM"; '
"     \.'open -a iTerm')<CR>:redraw!<CR>
