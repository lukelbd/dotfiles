"-----------------------------------------------------------------------------"
" Override filetype and syntax settings
" See: https://stackoverflow.com/a/4301809/4970632
"-----------------------------------------------------------------------------"
" Override buffer-local settings
" Note: The URL regex is from .tmux.conf and https://vi.stackexchange.com/a/11547/8084
setlocal concealcursor=
setlocal conceallevel=2
setlocal formatoptions=lrojcq
setlocal linebreak
setlocal nojoinspaces
let &l:textwidth = g:linelength  " see .vimrc
let &l:wrapmargin = 0

" Override folding syntax
" Note: For overwriting gui syntax see https://stackoverflow.com/a/73783079/4970632
" Note: Plugins vim-tabline and vim-statusline use custom auto-calculated colors
" based on colorscheme. Leverage that instead of reproducing here.
if has('gui_running')
  highlight! link Folded TabLine
  let hl = hlget('Folded')[0]  " keeps getting overridden so use this
  let hl['gui'] = extend(get(hl, 'gui', {}), {'bold': v:true})
  let hl['gui'] = extend(get(hl, 'gui', {}), {'bold': v:true})
  call hlset([hl])
endif

" Override buffer-local syntax
" Warning: The containedin just tries to *guess* what particular comment and string
" group names are for given filetype syntax schemes (use :Group for testing).
syntax match customBang /^\%1l#!.*$/  " shebang highlighting
syntax match customLink =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^' 	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]= containedin=.*\(Comment\|String\).*
syntax match customTodo /\C\%(WARNINGS\?\|ERRORS\?\|FIXMES\?\|TODOS\?\|NOTES\?\|XXX\)\ze:\?/ containedin=.*Comment.*  " comments
highlight link customBang Special
highlight link customTodo Todo
highlight link customLink Underlined
