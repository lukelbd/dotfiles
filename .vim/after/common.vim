"-----------------------------------------------------------------------------"
" Override filetype and syntax settings
" See: https://stackoverflow.com/a/4301809/4970632
"-----------------------------------------------------------------------------"
" Update general settings
" Note: Peekaboo mappings are local so have to override here. Also in future should
" consider setting b:surround_indent for filetypes but for now have this for safety.
" Note: This overrides native vim filetype-specific double-bracket maps (e.g. :map [[
" in vim files for jumping to functions) but skips mapping in presence of buffer-local
" single-bracket maps (e.g. help file tag navigation) and buffer-local indent maps
" (e.g. fugitive indent toggling). Should remove unmap lines after restarting vim.
setlocal concealcursor=nc
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
silent! iunmap <buffer> <C-n>
inoremap <buffer> <F5> <Space><C-\><C-o>v:TCommentInline mode=#<CR><Delete>
inoremap <buffer> <F6> <Space><C-\><C-o>:TCommentBlock mode=#<CR><Delete>
if exists('*peekaboo#on') && exists('*peekaboo#on')
  silent! call peekaboo#off()
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

" Update folds and syntax
" Note: Here fold#regex_levels() resets fold open-close status for some filetypes but
" unfortunately required because refresh seems to clean out vim-markdown definitions.
" Note: Here overwrite native foldtext function so that vim-markdown autocommands
" re-apply it along with other settings. Critical to prevent e.g. javascript.vim
" from overwriting fold settings: https://github.com/tpope/vim-markdown/pull/173
" and note this requires g:vim_markdown_override_foldtext = 1 in .vimrc (default).
function! Foldtext_markdown(...)
  return call('fold#fold_text', [])
endfunction
let s:closed = foldclosed('.')
let s:winview = winsaveview()
call fold#update_folds()
call fold#regex_levels()
call winrestview(s:winview)
silent! doautocmd CursorHold
silent! doautocmd ConflictMarkerDetect BufReadPost
silent! doautocmd conflict_marker_setup BufWinEnter
call syntax#update_groups()
call syntax#update_matches()
call syntax#update_highlights()
if s:closed <= 0 | exe 'silent! normal! zv' | endif
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
