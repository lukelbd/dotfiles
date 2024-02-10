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
  map <buffer> [[ <Plug>TagsBackwardTop
  map <buffer> ]] <Plug>TagsForwardTop
endif

" Update folds and re-enforce colors
" Note: Here fold#set_defaults() resets fold open-close status for some filetypes but
" unfortunately required because refresh seems to clean out vim-markdown definitions.
" Note: Here overwrite native foldtext function so that vim-markdown autocommands
" re-apply it along with other settings. Critical to prevent e.g. javascript.vim
" from overwriting fold settings: https://github.com/tpope/vim-markdown/pull/173
" and note this requires g:vim_markdown_override_foldtext = 1 in .vimrc (default).
function! Foldtext_markdown(...)
  return call('fold#fold_text', a:000)
endfunction
let closed = foldclosed('.') > 0
let winview = winsaveview()
call fold#update_folds()
call fold#set_defaults()
call winrestview(winview)
if closed > 0  " e.g. markdown files
  silent! normal! zv
endif

" Buffer-local syntax overrides
" Note: The URL regex is from .tmux.conf and https://vi.stackexchange.com/a/11547/8084
" and the containedin line just tries to *guess* what particular comment and string
" group names are for given filetype syntax schemes (use :Group for testing).
" Note: Plugins vim-tabline and vim-statusline use custom auto-calculated colors
" based on colorscheme. Leverage that instead of reproducing here. Also need special
" workaround to apply bold gui syntax. See https://stackoverflow.com/a/73783079/4970632
syntax match CommonLink
  \ =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^' 	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]=
  \ containedin=.*\(Comment\|String\).*
syntax match CommonHeader
  \ /\C\%(WARNINGS\?\|ERRORS\?\|FIXMES\?\|TODOS\?\|NOTES\?\|XXX\)\ze:\?/
  \ containedin=.*Comment.*
syntax match CommonShebang
  \ /^\%1l#!.*$/
  \ contains=@NoSpell
highlight link CommonLink Underlined
highlight link CommonHeader Todo
highlight link CommonShebang Special
if has('gui_running')
  highlight! link Folded TabLine
  highlight! link Terminal TabLine
  let hl = hlget('Folded')[0]  " keeps getting overridden so use this
  let hl['gui'] = extend(get(hl, 'gui', {}), {'bold': v:true})
  let hl['gui'] = extend(get(hl, 'gui', {}), {'bold': v:true})
  call hlset([hl])
endif

" Filetype syntax. Could move to after/syntax but annoying
" Note: This tries to fix docstring highlighting issues but inconsistent, so also
" have vimrc 'syntax sync' mappings. See: https://github.com/vim/vim/issues/2790
if &filetype ==# 'python'  " fix syntax: https://stackoverflow.com/a/28114709/4970632
  highlight BracelessIndent ctermfg=0 ctermbg=0 cterm=inverse
  if exists('*SetCellHighlighting') | call SetCellHighlighting() | endif | syntax sync minlines=100
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
