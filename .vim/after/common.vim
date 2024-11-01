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
let &l:concealcursor = 'nc'
let &l:conceallevel = &l:filetype ==# 'vim' ? 0 : 2
let &l:formatlistpat = &l:filetype ==# 'markdown' ? &l:formatlistpat : &g:formatlistpat
let &l:formatoptions = 'rojclqn'
let &l:joinspaces = 0
let &l:linebreak = 1
let &l:textwidth = g:linelength
let &l:wrapmargin = 0
let s:bracket1 = get(maparg('[', '', 0, 1), 'buffer', 0)
let s:bracket2 = get(maparg(']', '', 0, 1), 'buffer', 0)
if !s:bracket1 && !s:bracket2  " no buffer-local single bracket maps
  map <buffer> [[ <Plug>TagsBackwardTop
  map <buffer> ]] <Plug>TagsForwardTop
endif
nnoremap <buffer> == <Esc>==
nnoremap <buffer> >> <Cmd>call edit#indent_lines(0, v:count1)<CR>
nnoremap <buffer> << <Cmd>call edit#indent_lines(1, v:count1)<CR>

" Update folds and syntax
" NOTE: Here remove various filetype-related mappings that can cause cursor hang for
" single-key mapings in vimrc (put after common_syntax to avoid unnecessary calls)
" NOTE: This implements default highlight colors and overrides syntax and matchadd()
" groups from e.g. vim-markdown and rainbow_csv plugins. Critical to call after all
" other Syntax * autocommands so generate and call group on VimEnter (see vimrc).
if exists('b:common_syntax') || !exists('b:current_syntax') && !exists('b:rbcsv')
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
