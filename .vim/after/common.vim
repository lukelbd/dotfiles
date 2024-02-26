"-----------------------------------------------------------------------------"
" Override filetype and syntax settings
" See: https://stackoverflow.com/a/4301809/4970632
"-----------------------------------------------------------------------------"
" General settings
" Warning: Peekaboo mappings are set
" Note: This overrides native vim filetype-specific double-bracket maps (e.g. :map [[
" in vim files for jumping to functions) but skips mapping in presence of buffer-local
" single-bracket maps (e.g. help file tag navigation) and buffer-local indent maps
" (e.g. fugitive indent toggling). Should remove unmap lines after restarting vim.
setlocal concealcursor=
setlocal conceallevel=2
setlocal formatoptions=lrojcq
setlocal linebreak
setlocal nojoinspaces
let &l:textwidth = g:linelength
let &l:wrapmargin = 0
let s:jump1 = get(maparg('[', '', 0, 1), 'buffer', 0)
let s:jump2 = get(maparg(']', '', 0, 1), 'buffer', 0)
let s:indent1 = get(maparg('<', '', 0, 1), 'buffer', 0)
let s:indent2 = get(maparg('>', '', 0, 1), 'buffer', 0)
if exists('*peekaboo#on') && exists('*peekaboo#on')
  silent! call peekaboo#off()  " re-enforce mappings
  silent! call peekaboo#on()
endif
if !s:jump1 && !s:jump2  " no single bracket mappings
  map <buffer> [[ <Plug>TagsBackwardTop
  map <buffer> ]] <Plug>TagsForwardTop
endif
if !s:indent1 && !s:indent2 | exe 'nnoremap <buffer> == <Esc>=='
  nnoremap <expr> <buffer> >> '<Esc>' . repeat('>>', v:count1)
  nnoremap <expr> <buffer> << '<Esc>' . repeat('<<', v:count1)
endif

" Update folds and plugin-specific settings
" Note: Here CursorHold is needed for vim-markdown overrides and BufReadPost is needed
" for conflict-marker overrides. No public functional way to do either of these.
" Note: Here fold#update_open() resets fold open-close status for some filetypes but
" unfortunately required because refresh seems to clean out vim-markdown definitions.
" Note: Here overwrite native foldtext function so that vim-markdown autocommands
" re-apply it along with other settings. Critical to prevent e.g. javascript.vim
" from overwriting fold settings: https://github.com/tpope/vim-markdown/pull/173
" and note this requires g:vim_markdown_override_foldtext = 1 in .vimrc (default).
function! Foldtext_markdown(...)
  return call('fold#fold_text', a:000)
endfunction
let closed = foldclosed('.')
let winview = winsaveview()
call fold#update_folds()
call fold#update_open()
call winrestview(winview)
if closed <= 0 | exe 'silent! normal! zv' | endif
doautocmd CursorHold
doautocmd ConflictMarkerDetect BufReadPost
doautocmd conflict_marker_setup BufWinEnter
for s:suffix in ['g', 's', 'S', '%']
  exe 'silent! iunmap <C-g>' . s:suffix
  exe 'silent! iunmap <buffer><C-g>' . s:suffix
endfor
for s:prefix in ['<Nop>', '<C-w>', '<C-g>', '<buffer><Nop>', '<buffer><C-w>', '<buffer><C-g>', '<buffer><C-r>']
  for s:suffix in ['@', '"', "'", '/', '?', 'g', '"', "'", '<C-w>', '<C-g>', '<C-r>']
    exe 'silent! nunmap ' . s:prefix . s:suffix
    exe 'silent! xunmap ' . s:prefix . s:suffix
  endfor
endfor

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
