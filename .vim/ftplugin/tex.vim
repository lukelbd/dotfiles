"------------------------------------------------------------------------------"
"LaTeX specific settings
"Not much in here so far; note templates and snippets must be controlled by the vimrc.
"Various syntax settings below; for help, see :help tex-syntax
"------------------------------------------------------------------------------"
"Disable latex spellchecking in comments (works for default syntax file)
let g:tex_comment_nospell=1
"Configure concealment
" let user determine which classes of concealment will be supported
"   a=accents/ligatures b=bold/italics d=delimiters m=math symbols  g=Greek  s=superscripts/subscripts
let g:tex_conceal='amgsS'
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
noremap <silent> <buffer> <C-z> :w<CR>:exec('!clear; set -x; compile '.shellescape(@%).' false')<CR>
noremap <silent> <buffer> <Leader>z :w<CR>:exec('!clear; set -x; ~/bin/compile '.shellescape(@%).' true')<CR>
"------------------------------------------------------------------------------"
"Greek letters, mathematical symbols, and other commands
inoremap <buffer> .<Esc> <Nop>
inoremap <buffer> .. .
"Arrows, most commonly used ones anyway
inoremap <buffer> .<Left>  \Rightarrow 
inoremap <buffer> .<Right> \Longrightarrow 
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
"------------------------------------------------------------------------------"
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
