"------------------------------------------------------------------------------"
"LaTeX specific settings
"Not much in here so far; note templates and snippets must be controlled by the vimrc.
"For the syntax options, see :help tex-syntax
"------------------------------------------------------------------------------"
"Disable latex spellchecking in comments (works for default syntax file)
let g:tex_comment_nospell=1
"------------------------------------------------------------------------------"
"Configure concealment
" let user determine which classes of concealment will be supported
"   a=accents/ligatures b=bold/italics d=delimiters m=math symbols  g=Greek  s=superscripts/subscripts
let g:tex_conceal='amgsS'
" let S:tex_conceal= 'abdmgsS'
"------------------------------------------------------------------------------"
"Fast highlighting, but pretty ugly
" let g:tex_fast= ""
