"-----------------------------------------------------------------------------"
" Override filetype and syntax settings
" See: https://stackoverflow.com/a/4301809/4970632
"-----------------------------------------------------------------------------"
" Update general settings
" NOTE: Peekaboo mappings are local so have to override here. Also in future should
" consider setting b:surround_indent for filetypes but for now have this for safety.
" NOTE: This overrides native vim filetype-specific double-bracket maps (e.g. :map [[
" in vim files for jumping to functions) but skips mapping in presence of buffer-local
" single-bracket maps (e.g. help file tag navigation) and buffer-local indent maps
" (e.g. fugitive indent toggling). Should remove unmap lines after restarting vim.
let &l:conceallevel = &l:filetype ==# 'vim' ? 0 : 2
let &l:concealcursor = 'nc'
let &l:formatoptions = 'rojclqn'
let &l:joinspaces = 0
let &l:linebreak = 1
let &l:textwidth = g:linelength
let &l:wrapmargin = 0
let s:jump1 = get(maparg('[', '', 0, 1), 'buffer', 0)
let s:jump2 = get(maparg(']', '', 0, 1), 'buffer', 0)
let s:indent1 = get(maparg('<', '', 0, 1), 'buffer', 0)
let s:indent2 = get(maparg('>', '', 0, 1), 'buffer', 0)
if &l:filetype !=# 'markdown'  " vim includes special reference bullets
  let &l:formatlistpat = &g:formatlistpat  " see vimrc
endif
if !s:jump1 && !s:jump2  " no single bracket mappings
  map <buffer> [[ <Plug>TagsBackwardTop
  map <buffer> ]] <Plug>TagsForwardTop
endif
if !s:indent1 && !s:indent2 | exe 'nnoremap <buffer> == <Esc>=='
  nnoremap <buffer> >> <Cmd>call edit#indent_lines(0, v:count1)<CR>
  nnoremap <buffer> << <Cmd>call edit#indent_lines(1, v:count1)<CR>
endif

" Update folds and syntax
" NOTE: Here overwrite native foldtext function so that vim-markdown autocommands
" re-apply it along with other settings. Critical to prevent e.g. javascript.vim
" from overwriting fold settings: https://github.com/tpope/vim-markdown/pull/173
" and note this requires g:vim_markdown_override_foldtext = 1 in .vimrc (default).
if exists('b:common_syntax') || !exists('b:current_syntax')
  finish  " remove b:common_syntax on Syntax * autocommand
endif
let b:common_syntax = 1
call syntax#update_groups()
call syntax#update_matches()
call syntax#update_highlights()
for s:suffix in ['g', 's', 'S', '%']  " instead use <C-g> to insert literals
  exe 'silent! iunmap <C-g>' . s:suffix
  exe 'silent! iunmap <buffer><C-g>' . s:suffix
endfor
for s:prefix in ['<Nop>', '<C-w>', '<C-g>', '<buffer><Nop>', '<buffer><C-w>', '<buffer><C-g>', '<buffer><C-r>']
  for s:suffix in ['@', '"', "'", '/', '?', 'g', '"', "'", '<C-w>', '<C-g>', '<C-r>']
    exe 'silent! nunmap ' . s:prefix . s:suffix
    exe 'silent! xunmap ' . s:prefix . s:suffix
  endfor
endfor
