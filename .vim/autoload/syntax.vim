"-----------------------------------------------------------------------------"
" Utilities for syntax syncing
"-----------------------------------------------------------------------------"
" Jump to next conceal character
" See: https://stackoverflow.com/a/24224578/4970632
" Note: This detects both columns concealed with matchadd(..., {'conceal': ''}) and
" syntax 'conceal' or 'concealends'. In the former case leverage fact that matchadd
" method is only used to make tex and markdown characters invisible, so no need to
" compare replacement characters or check groups -- simply skip those columns.
function! s:skip_cols(...) abort
  let cols = []  " column numbers concealed with empty string
  let line = getline(a:0 ? a:1 : '.')
  let matches = filter(getmatches(), "v:val.group ==# 'Conceal'")
  let regexes = uniq(map(matches, 'v:val.pattern'))
  for regex in regexes
    let idx = 0  " search start of string
    while idx >= 0 && idx < len(line)
      let [str, jdx, idx] = matchstrpos(line, regex, idx)
      call extend(cols, empty(str) ? [] : range(jdx + 1, idx))
    endwhile
  endfor
  return cols
endfunction
function! syntax#next_char(count)
  let [lnum, cnum, cmax] = [line('.'), col('.'), col('$')]
  let [line, skip] = [getline(lnum), s:skip_cols(lnum)]
  let [icnt, jcnt] = [a:count, 0]
  let cmode = mode() ==# '' ? 'v' : mode()
  let offset = a:count < 0 ? -1 : 0
  let delta = a:count < 0 ? -1 : 1
  while delta * icnt > 0
    let concealed = 0
    let invisible = index(skip, cnum + offset) != -1
    if a:count < 0 && cnum <= 1 || a:count > 0 && cnum >= cmax
      let jcnt += icnt | break
    endif
    if cnum && &l:concealcursor =~? cmode[:0]
      let [concealed, cchar, _] = synconcealed(lnum, cnum + offset)
    endif
    if invisible || !concealed
      if a:count < 0
        let cnum -= len(matchstr(line[:cnum - 2], '.$'))
      else  " vint: next-line -ProhibitUsingUndeclaredVariable
        let cnum += len(matchstr(line[cnum - 1:], '^.'))
      endif
      let [sub, add] = [invisible ? 0 : 1, 1]
    else
      let pnum = cnum  " previous colum number
      let cnum += delta  " increment column number
      while cnum > 1 && cnum < cmax
        let [concealed, ichar, _] = synconcealed(lnum, cnum + offset)
        if !concealed || cchar !=# ichar | break | endif
        let cnum += delta  " increment column number
      endwhile
      let sub = strchars(cchar)
      if a:count < 0
        let add = strchars(line[max([cnum - 1, 0]):pnum - 2])
      else
        let add = strchars(line[pnum - 1:cnum - 2])
      endif
    endif
    let icnt -= delta * sub  " iterate input count
    let jcnt += delta * add  " iterate output count
  endwhile
  let motion = jcnt > 0 ? jcnt . 'l' : jcnt < 0 ? -jcnt . 'h' : ''
  return "\<Ignore>" . motion
endfunction

" Switch to next or previous colorschemes and print the name
" See: https://stackoverflow.com/a/2419692/4970632
" Note: Here getcompletion(..., 'color') will follow &wildignorecase which follows
" &fileignorecase and filters out 'duplicate' color schemes with same case. This can
" cause errors where we land on unknown schemes so add set nofileignorecase to vimrc.
" Note: Have to trigger 'InsertLeave' so status line updates (for some reason only
" works after timer when :colorscheme triggers ColorScheme autocommand). Also note
" g:colors_name is convention shared by most color schemes, no official vim setting.
function! s:echo_scheme(...) abort
  let name = get(g:, 'colors_name', 'default')
  echom 'Colorscheme: ' . name
endfunction
function! syntax#next_scheme(arg) abort
  let default = get(g:, 'colors_default', 'default')
  if !exists('g:colors_all')
    let g:colors_all = getcompletion('', 'color')
  endif
  if type(a:arg)  " use input scheme
    let name = a:arg
  else  " iterate over schemes
    let name = get(g:, 'colors_name', default)
    let idx = indexof(g:colors_all, {idx, val -> val ==# name})
    let idx = idx == -1 ? index(g:colors_all, default) : idx + a:arg
    let idx = idx % len(g:colors_all)
    let name = g:colors_all[idx]
  endif
  silent! exe 'colorscheme ' . name
  silent call syntax#update_groups()  " override vim comments
  silent call syntax#update_matches()  " override vim comments
  silent call syntax#update_highlights()  " override highlight colors
  silent! doautocmd BufEnter
  let g:colors_name = name  " in case differs
  redraw | echom 'Colorscheme: ' . name
endfunction

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
  call window#setup_panel()
endfunction
function! syntax#show_runtime(...) abort
  let path = a:0 ? a:1 : 'ftplugin'
  let path = $VIMRUNTIME . '/' . path . '/' . &l:filetype . '.vim'
  call file#open_drop(path)
  call window#setup_panel()
endfunction

" Update syntax colors
" Note: This gets the closest tag to the first line in the window, all tags
" rather than top-level only, searching backward, and without circular wrapping.
function! syntax#update_lines(count, ...) abort
  if a:0 && a:1
    exe 'syntax sync fromstart'
    echom 'Syntax sync: fromstart'
  elseif a:count  " input count
    exe 'syntax sync minlines=' . a:count . ' maxlines=0'
    echom 'Syntax sync: minlines=' . a:count
  else  " sync from tag
    let item = tags#close_tag(line('w0'))
    let nlines = max([0, get(item, 1, line('w0')) - line('.')])
    exe 'syntax sync minlines=' . nlines . ' maxlines=0'
    echom 'Syntax sync: minlines=' . nlines
  endif
endfunction

" Update on-the-fly matchadd() matches.
" Note: Unlike typical syntax highlighting these are window-local and do not
" require explicit names (assigned automatic ids). They are managed separately
" from :highlight and :syntax commands with getmatches() and setmatches()
" Note: Critical to make 'priority' (third argument, default 10) same as :hlsearch
" priority (0) or matches are weird. Note :syntax match fails since concealed backslash
" overwrites any existing matches. See: https://vi.stackexchange.com/q/5696/8084
function! syntax#update_matches() abort
  let matches = filter(getmatches(), "v:val.group ==# 'Conceal'")
  if !empty(matches) | return | endif
  if &filetype ==# 'tex'  " backslashes (skips e.g. \cmd1\cmd2 but helpful anyway)
    let regex = '\(%.*\|\\[a-zA-Z@]\+\|\\\)\@<!\zs\\\([a-zA-Z@]\+\)\@='
    call matchadd('Conceal', regex, 0, -1, {'conceal': ''})
  endif
  if &filetype ==# 'markdown'  " strikethrough: https://www.reddit.com/r/vim/comments/g631im/any_way_to_enable_true_markdown_strikethrough/
    call matchadd('StrikeThrough', '<s>\zs\_.\{-}\ze</s>')
    call matchadd('Conceal', '<s>\ze\_.\{-}</s>', 10, -1, {'conceal': ''})
    call matchadd('Conceal', '<s>\_.\{-}\zs</s>', 10, -1, {'conceal': ''})
  endif
endfunction

" Update syntax match groups. Could move to after/syntax but annoying
" Note: This tries to fix docstring highlighting issues but inconsistent, so also
" have vimrc 'syntax sync' mappings. See: https://github.com/vim/vim/issues/2790
" Note: The URL regex is from .tmux.conf and https://vi.stackexchange.com/a/11547/8084
" and the containedin line just tries to *guess* what particular comment and string
" group names are for given filetype syntax schemes (use :Group for testing).
function! syntax#update_groups() abort
  if &filetype ==# 'vim'  " repair comments: https://github.com/vim/vim/issues/11307
    syntax match vimQuoteComment '^[ \t:]*".*$' contains=vimComment.*,@Spell
    highlight link vimQuoteComment Comment
  endif
  if &filetype ==# 'html'  " no spell comments (here overwrite original group name)
    syntax region htmlComment start='<!--' end='--\s*>' contains=@NoSpell
    highlight link htmlComment Comment
  endif
  if &filetype ==# 'json'  " json comments: https://stackoverflow.com/a/68403085/4970632
    syntax match jsonComment '^\s*\/\/.*$'
    highlight link jsonComment Comment
  endif
  if &filetype ==# 'fortran'  " repair comments (ensure space and skip c = value)
    syntax match fortranComment excludenl '^\s*[cC]\s\+=\@!.*$' contains=@spell,@fortranCommentGroup
    highlight link fortranComment Comment
  endif
  if &filetype ==# 'python'  " fix syntax: https://stackoverflow.com/a/28114709/4970632
    highlight BracelessIndent ctermfg=NONE ctermbg=NONE cterm=inverse
    if exists('*SetCellHighlighting') | call SetCellHighlighting() | endif | syntax sync minlines=100
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
  call s:update_highlight('Normal', '', '', '')
  call s:update_highlight('LineNR', '', 'black', '')
  call s:update_highlight('Folded', '', 'white', 'bold')
  call s:update_highlight('CursorLine', 'black', 0, '')
  call s:update_highlight('ColorColumn', 'gray', 0, '')
  call s:update_highlight('DiffAdd', 'black', '', 'bold')
  call s:update_highlight('DiffChange', 'black', '', '')
  call s:update_highlight('DiffDelete', '', 'black', '')
  call s:update_highlight('DiffText', 0, 0, 'inverse')
  call s:update_highlight('StrikeThrough', 0, 0, 'strikethrough')
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
