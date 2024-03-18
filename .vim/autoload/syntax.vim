"-----------------------------------------------------------------------------"
" Utilities for syntax syncing
"-----------------------------------------------------------------------------"
" Show syntax highlight groups and info
" Note: This adds header in same format as built-in command
function! syntax#show_stack(...) abort
  let sids = a:0 ? map(copy(a:000), 'hlID(v:val)') : synstack(line('.'), col('.'))
  let [names, labels] = [[], []]
  for sid in sids
    let name = synIDattr(sid, 'name')
    let group = synIDattr(synIDtrans(sid), 'name')
    let label = empty(group) ? name : name . ' (' . group . ')'
    call add(names, name)
    call add(labels, label)
  endfor
  if !empty(names)
    echohl Title | echom '--- Syntax names ---' | echohl None
    for label in labels | echom label | endfor
    exe 'syntax list ' . join(names, ' ')
  else  " no syntax
    echohl WarningMsg
    echom 'Warning: No syntax under cursor.'
    echohl None
  endif
endfunction

" Show syntax or plugin information
" Note: This opens files in separate tabs for consistency with others tools
function! syntax#show_colors() abort
  silent call file#open_drop('colortest.vim')
  silent let path = $VIMRUNTIME . '/syntax/colortest.vim'
  exe 'source ' . path
  call window#setup_panel(1)
endfunction
function! syntax#show_runtime(...) abort
  let path = a:0 ? a:1 : 'ftplugin'
  let path = $VIMRUNTIME . '/' . path . '/' . &l:filetype . '.vim'
  call file#open_drop(path)
  call window#setup_panel(1)
endfunction

" Update syntax colors
" Note: This gets the closest tag to the first line in the window, all tags
" rather than top-level only, searching backward, and without circular wrapping.
function! syntax#update_lines(count, ...) abort
  if a:0 && a:1
    exe 'syntax sync fromstart'
  elseif a:count  " input count
    exe 'syntax sync minlines=' . a:count . ' maxlines=0'
  else  " sync from tag
    let item = tags#close_tag(line('w0'), 0, 0, 0)
    let nlines = max([0, get(item, 1, line('w0')) - line('.')])
    exe 'syntax sync minlines=' . nlines . ' maxlines=0'
  endif
endfunction

" Switch to next or previous colorschemes and print the name
" See: https://stackoverflow.com/a/2419692/4970632
" Note: Have to trigger 'InsertLeave' so status line updates (for some reason only
" works after timer when :colorscheme triggers ColorScheme autocommand). Also note
" g:colors_name is convention shared by most color schemes, no official vim setting.
function! s:echo_scheme(...) abort
  let default = get(g:, 'colors_default', 'default')
  let name = get(g:, 'colors_name', 'default')
  exe name ==# default ? 'silent doautocmd BufEnter' : ''
  echom 'Colorscheme: ' . name
endfunction
function! syntax#update_scheme(arg) abort
  if !exists('g:all_colorschemes')
    let g:all_colorschemes = getcompletion('', 'color')
  endif
  if type(a:arg)  " use input scheme
    let name = a:arg
  else  " iterate over schemes
    let idx = index(g:all_colorschemes, get(g:, 'colors_name', 'default'))
    let idx = idx == -1 ? 0 : idx + a:arg   " set to zero if not present
    let idx = idx % len(g:all_colorschemes)
    let name = g:all_colorschemes[idx]
  endif
  let g:colors_name = name
  silent! noautocmd exe 'colorscheme ' . name
  silent call syntax#update_groups()  " required for vim comment
  silent call syntax#update_highlights()  " override highlights
  let default = get(g:, 'colors_default', 'default')
  exe name ==# default ? '' : 'silent doautocmd BufEnter'
  call timer_start(1, 's:echo_scheme')
endfunction

" Updaet syntax match groups. Could move to after/syntax but annoying
" Note: This tries to fix docstring highlighting issues but inconsistent, so also
" have vimrc 'syntax sync' mappings. See: https://github.com/vim/vim/issues/2790
" Note: The URL regex is from .tmux.conf and https://vi.stackexchange.com/a/11547/8084
" and the containedin line just tries to *guess* what particular comment and string
" group names are for given filetype syntax schemes (use :Group for testing).
function! syntax#update_groups() abort
  if &filetype ==# 'vim'  " repair comments: https://github.com/vim/vim/issues/11307
    syntax match vimQuoteComment /^[ \t:]*".*$/ contains=vimComment.*,@Spell
    highlight link vimQuoteComment Comment
  endif
  if &filetype ==# 'html'  " no spell comments (here overwrite original group name)
    syn region htmlComment start=+<!--+ end=+--\s*>+ contains=@NoSpell
    highlight link htmlComment Comment
  endif
  if &filetype ==# 'json'  " json comments: https://stackoverflow.com/a/68403085/4970632
    syntax match jsonComment '^\s*\/\/.*$'
    highlight link jsonComment Comment
  endif
  if &filetype ==# 'fortran'  " repair comments (ensure followed by space, skip c = value)
    syn match fortranComment excludenl '^\s*[cC]\s\+=\@!.*$' contains=@spell,@fortranCommentGroup
    highlight link fortranComment Comment
  endif
  if &filetype ==# 'python'  " fix syntax: https://stackoverflow.com/a/28114709/4970632
    highlight BracelessIndent ctermfg=0 ctermbg=0 cterm=inverse
    if exists('*SetCellHighlighting') | call SetCellHighlighting() | endif | syntax sync minlines=100
  endif
  if &filetype ==# 'markdown'  " strikethrough: https://www.reddit.com/r/vim/comments/g631im/any_way_to_enable_true_markdown_strikethrough/
    highlight MarkdownStrike cterm=strikethrough gui=strikethrough
    call matchadd('MarkdownStrike', '<s>\zs.\{-}\ze</s>')
    call matchadd('Conceal', '<s>\ze.\{-}</s>', 10, -1, {'conceal':''})
    call matchadd('Conceal', '<s>.\{-}\zs</s>\ze', 10, -1, {'conceal':''})
  endif
  syntax match CommonShebang
    \ /^\%1l#!.*$/
    \ contains=@NoSpell
  syntax match CommonHeader
    \ /\C\%(WARNINGS\?\|ERRORS\?\|FIXMES\?\|TODOS\?\|NOTES\?\|XXX\)\ze:\?/
    \ containedin=.*Comment.*
  syntax match CommonLink
    \ =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^' 	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]=
    \ containedin=.*\(Comment\|String\).*
endfunction

" Highlight group with gui or cterm codes
" Note: Cannot use e.g. aliases 'bg' or 'fg' in terminal since often unset, and cannot
" use transparent 'NONE' in gui vim since undefined, so swap them here.
function! s:update_highlight(group, back, front, ...) abort
  let defaults = {'black': '#000000', 'gray': '#333333', 'white': '#ffffff'}
  let name = has('gui_running') ? 'gui' : 'cterm'
  let text = a:0 && type(a:1) ? empty(a:1) ? 'None' : a:1 : ''
  let args = empty(text) ? [] : [name . '=' . text]
  if type(a:back)
    if empty(a:back)  " background
      let code = has('gui_running') ? 'bg' : 'NONE'
    elseif has('gui_running')  " hex color
      let code = get(g:, 'statusline_' . a:back, get(defaults, a:back, '#808080'))
    else  " color name
      let code = substitute(a:back, '^\(\a\)\(\a*\)$', '\u\1\l\2', '')
    endif
    call add(args, name . 'bg=' . code)
  endif
  if type(a:front)  " foreground
    if empty(a:front)
      let code = has('gui_running') ? 'fg' : 'NONE'
    elseif has('gui_running')  " hex color
      let code = get(g:, 'statusline_' . a:front, get(defaults, a:front, '#808080'))
    else  " color name
      let code = substitute(a:front, '^\(\a\)\(\a*\)$', '\u\1\l\2', '')
    endif
    call add(args, name . 'fg=' . code)
  endif
  exe 'noautocmd highlight ' . a:group . ' ' . join(args, ' ')
  exe 'noautocmd highlight ' . a:group . ' ' . join(args, ' ')
endfunction

" Update syntax highlight groups
" Note: This enforces core grayscale-style defaults, with dark comments against
" darker background and sign and number columns that blend into the main window.
" Note: ALE highlights point to nothing when scrolling color schemes, but are still
" used for sign definitions, so manually enable here (note getcompletion() will fail)
" Note: Plugins vim-tabline and vim-statusline use custom auto-calculated colors
" based on colorscheme. Leverage that instead of reproducing here. Also need special
" workaround to apply bold gui syntax. See https://stackoverflow.com/a/73783079/4970632
function! syntax#update_highlights() abort
  let pairs = []  " highlight links
  call s:update_highlight('LineNR', '', 'black', '')
  call s:update_highlight('Folded', '', 'white', 'Bold')
  call s:update_highlight('CursorLine', 'black', 0, '')
  call s:update_highlight('ColorColumn', 'gray', 0, '')
  call s:update_highlight('DiffAdd', 'black', '', 'Bold')
  call s:update_highlight('DiffChange', 'black', '', '')
  call s:update_highlight('DiffDelete', '', 'black', '')
  call s:update_highlight('DiffText', 0, 0, 'Inverse')
  for group in ['Conceal', 'Pmenu', 'Terminal']
    call add(pairs, [group, 'Normal'])
  endfor
  for group in ['SignColumn', 'FoldColumn', 'CursorLineNR', 'CursorLineFold', 'Comment', 'NonText', 'SpecialKey']
    call add(pairs, [group, 'LineNR'])
  endfor
  for group in ['ALEErrorLine', 'ALEWarningLine', 'ALEInfoLine']  " see above
    call add(pairs, [group, 'Conceal'])
  endfor
  for group in ['ALEErrorSign', 'ALEStyleErrorSign', 'ALESignColumnWithErrors']  " see above
    call add(pairs, [group, 'Error'])
  endfor
  for group in ['ALEWarningSign', 'ALEStyleWarningSign', 'ALEInfoSign']  " see above
    call add(pairs, [group, 'Todo'])
  endfor
  for group in getcompletion('GitGutter', 'highlight')  " see above
    call add(pairs, [group, 'Folded'])
  endfor
  for [tail, dest] in [['Link', 'Underlined'], ['Header', 'Todo'], ['Shebang', 'Special']]
    call add(pairs, ['Common' . tail, dest])
  endfor
  for tail in ['Map', 'NotFunc', 'FuncKey', 'Command']
    call add(pairs, ['vim' . tail, 'Statement'])
  endfor
  for [group1, group2] in pairs
    exe 'highlight! link ' . group1 . ' ' . group2
  endfor
  if has('gui_running')  " keeps getting overridden so use this
    let hl = hlget('Folded')[0]
    let hl['gui'] = extend(get(hl, 'gui', {}), {'bold': v:true})
    let hl['gui'] = extend(get(hl, 'gui', {}), {'bold': v:true})
    call hlset([hl])
  endif
endfunction
