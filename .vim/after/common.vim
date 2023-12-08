"-----------------------------------------------------------------------------"
" Override filetype and syntax settings
" See: https://stackoverflow.com/a/4301809/4970632
"-----------------------------------------------------------------------------"
" General settings
" Note: This overrides native vim filetype navigation maps (e.g. :map [[ inside
" vim file shows mapping that searches for functions. Also accounts for situations
" e.g. help pages where single '[' or ']' are assigned <nowait> mappings.
setlocal concealcursor=
setlocal conceallevel=2
setlocal formatoptions=lrojcq
setlocal linebreak
setlocal nojoinspaces
let &l:textwidth = g:linelength  " see also .vimrc
let &l:wrapmargin = 0
if empty(maparg('[')) && empty(maparg(']'))
  if !empty(maparg('<Plug>TagsBackwardTop')) && !empty(maparg('<Plug>TagsForwardTop'))
    map <buffer> [[ <Plug>TagsBackwardTop
    map <buffer> ]] <Plug>TagsForwardTop
  endif
endif

" Enforce folding colors
" Note: Plugins vim-tabline and vim-statusline use custom auto-calculated colors
" based on colorscheme. Leverage that instead of reproducing here. Also need special
" workaround to apply bold gui syntax. See https://stackoverflow.com/a/73783079/4970632
if has('gui_running')
  highlight! link Folded TabLine
  highlight! link Terminal TabLine
  let hl = hlget('Folded')[0]  " keeps getting overridden so use this
  let hl['gui'] = extend(get(hl, 'gui', {}), {'bold': v:true})
  let hl['gui'] = extend(get(hl, 'gui', {}), {'bold': v:true})
  call hlset([hl])
endif

" Define folding regions
" Note: Python block uses b:SimpylFold_cache to apply custom docstring folds and opens
" classes by default. For some reason fails if anything here is moved to ftplugin. Also
" critical to use 'FileType' not 'BufWritePost' for python or get recursion issues.
" Note: Markdown block overwrites foldtext from $RUNTIME/syntax/[markdown|javascript]
" and re-applies plugged/vim-markdown folding. Also resets open-close status but
" unfortunately required because vim filetype refresh seems to clean out definitions.
if &filetype ==# 'python'  " trigger fastfold update
  setlocal foldexpr=python#fold_expr(v:lnum)
  doautocmd FileType
endif
if &filetype ==# 'markdown'  " trigger vim-markdown folds and fastfold update
  setlocal foldtext=fold#fold_text()
  doautocmd BufWritePost
endif
call fold#set_defaults()

" Buffer-local syntax
" Note: The URL regex is from .tmux.conf and https://vi.stackexchange.com/a/11547/8084
" Warning: The containedin just tries to *guess* what particular comment and string
" group names are for given filetype syntax schemes (use :Group for testing).
syntax match CommonBang
  \ /^\%1l#!.*$/
  \ contains=@NoSpell
syntax match CommonLink
  \ =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^' 	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]=
  \ containedin=.*\(Comment\|String\).*
syntax match CommonTodo
  \ /\C\%(WARNINGS\?\|ERRORS\?\|FIXMES\?\|TODOS\?\|NOTES\?\|XXX\)\ze:\?/
  \ containedin=.*Comment.*
highlight link CommonBang Special
highlight link CommonTodo Todo
highlight link CommonLink Underlined

" Filetype syntax. Could move to after/syntax but annoying
" Note: This tries to fix docstring highlighting issues but inconsistent, so also
" have vimrc 'syntax sync' mappings. See: https://github.com/vim/vim/issues/2790
if &filetype ==# 'python'  " fix syntax: https://stackoverflow.com/a/28114709/4970632
  highlight BracelessIndent ctermfg=0 ctermbg=0 cterm=inverse
  syntax sync minlines=100
endif
if &filetype ==# 'json'  " json comments: https://stackoverflow.com/a/68403085/4970632
  syntax match jsonComment '^\s*\/\/.*$'
  highlight link jsonComment Comment
endif
if &filetype ==# 'vim'  " repair comments: https://github.com/vim/vim/issues/11307
  syntax match vimQuoteComment /^[ \t:]*".*$/ contains=vimComment.*,@Spell
  highlight link vimQuoteComment Comment
endif
if &filetype ==# 'html'  " no spell comments (here overwrite original group name)
  syn region htmlComment start=+<!--+ end=+--\s*>+ contains=@NoSpell
  highlight link htmlComment Comment
endif
if &filetype ==# 'fortran'  " repair comments (ensure followed by space, skip c = value)
  syn match fortranComment excludenl '^\s*[cC]\s\+=\@!.*$' contains=@spell,@fortranCommentGroup
  highlight link fortranComment Comment
endif
