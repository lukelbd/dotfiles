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
