"------------------------------------------------------------------------------"
"LaTeX specific settings
"Not much in here so far; note templates and snippets must be controlled by the vimrc.
"Various syntax settings below; for help, see :help tex-syntax
"------------------------------------------------------------------------------"
"Restrict concealmeant to just symbols and stuff
" a=accents/ligatures
" b=bold/italics
" d=delimiters (e.g. $$ math mode)
" m=math symbols
" g=Greek
" s=superscripts/subscripts
let g:tex_conceal='agm'
"Allow @ in makeatletter, allow texmathonly outside of math regions (i.e.
"don't highlight [_^] when you think they are outside math zone
let g:tex_stylish=1
"Disable spell checking in verbatim mode and comments, disable errors
"With foldmethod=syntax, can now fold chapters and stuff
let g:tex_fold_enable=1
let g:tex_comment_nospell=1
let g:tex_verbspell=0
let g:tex_no_error=1
" let g:tex_fast= "" "fast highlighting, but pretty ugly

"Commands for compiling latex
"Use C-z for compiling normally, and <Leader>Z for compiling to word document.
noremap <silent> <buffer> <C-z> :update<CR>:silent exec('!clear; set -x; ~/bin/vimlatex '.shellescape(@%).' &>'.expand('%:t:r').'.vilog &') \| redraw! \| echo "Typesetting in background."<CR>
noremap <silent> <buffer> <Leader>z :w<CR>:silent exec('!clear; set -x; ~/bin/vimlatex '.shellescape(@%).' --diff &>'.expand('%:t:r').'.vilog --diff &') \| redraw! \| echo "Typesetting in background."<CR>
noremap <silent> <buffer> <Leader>Z :w<CR>:silent exec('!clear; set -x; ~/bin/vimlatex '.shellescape(@%).' --word &>'.expand('%:t:r').'.vilog --diff &') \| redraw! \| echo "Typesetting in background."<CR>

"C-@ is same as C-Space (google it)
"These are pretty much obsolete now, since 'detex' can exclude figure environments
"and tables and equations and stuff, but these cannot
" function! s:wordcount()
"   exe '!clear; set -x; ps2ascii '.shellescape(expand('%:p:r').'.pdf').' 2>/dev/null | wc -w'
"   exe '!clear; set -x; open -a Skim; '
"     \.'osascript ~/bin/wordcount.scpt '.shellescape(expand('%:p:r').'.pdf').'; '
"     \.'[ "$TERM_PROGRAM"=="Apple_Terminal" ] && terminal="Terminal" \|\| terminal="$TERM_PROGRAM"; '
"     \.'open -a iTerm')<CR>:redraw!<CR>
" endfunction
" command! WordCount call <sid>wordcount()
