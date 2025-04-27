"-----------------------------------------------------------------------------"
" Utilities for syntax syncing
"-----------------------------------------------------------------------------"
" Helper functions for concealed characters
" NOTE: This detects both columns concealed with matchadd(..., {'conceal': ''}) and
" syntax 'conceal' or 'concealends'. In the former case leverage fact that matchadd
" method is only used to make tex and markdown characters invisible, so no need to
" compare replacement characters or check groups -- simply skip those columns.
function! syntax#get_concealed(...) abort
  let cnum = a:0 > 1 ? a:2 : col('.')
  let cols = a:0 > 2 ? a:3 : call('syntax#_matches', a:000[:0])
  let item = call('syntax#_concealed', a:000[:1] + a:000[3:])  " see fold#fold_label
  return type(item) ? item : index(cols, cnum) != -1
endfunction
function! syntax#_concealed(...) abort
  if &l:conceallevel < 2 | return 0 | endif
  let lnum = a:0 > 0 ? a:1 : line('.')
  let cnum = a:0 > 1 ? a:2 : col('.')
  let value = a:0 > 2 ? a:3 : mode()
  let value = value ==# '' ? 'v' : value
  if cnum < 1 || &l:concealcursor !~? value[0]
    let [nr, str] = [0, '']
  else  " check if concealed
    let [nr, str, _] = synconcealed(lnum, cnum)
  endif
  return nr > 0 ? str : 0
endfunction
function! syntax#_matches(...) abort
  if &l:conceallevel < 2 | return [] | endif
  let regexes = filter(getmatches(), "v:val.group ==# 'Conceal'")
  let regexes = uniq(map(regexes, 'v:val.pattern'))
  let string = getline(a:0 ? a:1 : '.')
  let cols = []  " concealed with empty string
  for regex in regexes
    let idx = 0
    while idx >= 0 && idx < len(string)
      let [str, jdx, idx] = matchstrpos(string, regex, idx)
      let idxs = empty(str) ? [] : range(jdx + 1, idx)
      call extend(cols, idxs)
    endwhile
  endfor | return cols
endfunction

" Jump to next conceal charactee
" See: https://stackoverflow.com/a/24224578/4970632
" NOTE: This will be inaccurate for horizontal motions spanning multiple lines
" but generally not noticeable in that case (e.g. 20l just means 'go far away').
function! syntax#next_nonconceal(count, ...) abort
  let [icnt, jcnt] = [a:count, 0]
  let [direc, offset] = icnt < 0 ? [-1, -1] : [1, 0]
  let [lnum, cnum, cmax] = [line('.'), col('.'), col('$')]
  let cols = a:0 ? a:1 : syntax#_matches(lnum)
  let string = getline('.')
  while direc * icnt > 0
    if a:count < 0 && cnum <= 1 || a:count > 0 && cnum >= cmax
      let jcnt += icnt | break
    endif
    let value = syntax#get_concealed(lnum, cnum + offset, cols)
    if !type(value)
      if a:count < 0
        let cnum -= len(matchstr(string[:cnum - 2], '.$'))
      else  " vint: next-string -ProhibitUsingUndeclaredVariable
        let cnum += len(matchstr(string[cnum - 1:], '^.'))
      endif
      let [sub, add] = [value ? 0 : 1, 1]
    else
      let pnum = cnum  " previous colum number
      let cnum += direc  " increment column number
      while cnum > 1 && cnum < cmax
        let val = syntax#get_concealed(lnum, cnum + offset, cols)
        if !type(val) && empty(val) || type(val) && val !=# value
          break
        else  " increment column number
          let cnum += direc
        endif
      endwhile
      let sub = strchars(value)
      if a:count < 0
        let add = strchars(string[max([cnum - 1, 0]):pnum - 2])
      else
        let add = strchars(string[pnum - 1:cnum - 2])
      endif
    endif
    let icnt -= direc * sub  " iterate input count
    let jcnt += direc * add  " iterate output count
  endwhile
  return jcnt > 0 ? jcnt . 'l' : jcnt < 0 ? -jcnt . 'h' : ''
endfunction

" Switch to next or previous colorschemes and print the name
" See: https://stackoverflow.com/a/2419692/4970632
" NOTE: Here getcompletion(..., 'color') will follow &wildignorecase which follows
" &fileignorecase and filters out 'duplicate' color schemes with same case. This can
" cause errors where we land on unknown schemes so add set nofileignorecase to vimrc.
" NOTE: Have to trigger 'InsertLeave' so status line updates (for some reason only
" works after timer when :colorscheme triggers ColorScheme autocommand). Also note
" g:colors_name is convention shared by most color schemes, no official vim setting.
function! syntax#next_scheme(...) abort
  let default = get(g:, 'colors_default', 'default')
  if !exists('g:colors_all')
    let g:colors_all = getcompletion('', 'color')
  endif
  if a:0 && type(a:1)  " use input scheme
    let name = a:1
  else  " iterate over schemes
    let delta = a:0 ? a:1 : 0
    let name = get(g:, 'colors_name', default)
    let idx = indexof(g:colors_all, {idx, val -> val ==# name})
    let idx = idx == -1 ? index(g:colors_all, default) : idx + delta
    let idx = idx % len(g:colors_all)
    let name = g:colors_all[idx]
  endif
  silent! exe 'colorscheme ' . name
  silent call syntax#update_groups()  " override vim comments
  silent call syntax#update_matches()  " override vim comments
  silent call syntax#update_links()  " override highlight colors
  silent! doautocmd BufEnter
  let g:colors_name = name  " in case differs
  redraw | echom 'Colorscheme: ' . name
endfunction

" Show syntax or filetype info
" NOTE: This adds header in same format as built-in command and opens files in
" separate tabs instead of panels for consistency with others tools.
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
    for lab in labels | echom lab | endfor | exe 'syntax list ' . join(names, ' ')
  else  " no syntax
    let msg = 'Warning: No syntax names under cursor.'
    echohl WarningMsg | echom msg | echohl None
  endif
endfunction

" Update syntax colors
" NOTE: This gets the closest tag to the first line in the window, all tags
" rather than top-level only, searching backward, and without circular wrapping.
function! syntax#sync_lines(count, ...) abort
  if a:0 && a:1
    let cmd = 'syntax sync fromstart'
    let msg = 'Syntax sync: fromstart'
  elseif a:count  " input count
    let cmd = 'syntax sync minlines=' . a:count . ' maxlines=0'
    let msg = 'Syntax sync: minlines=' . a:count
  else  " sync from tag
    let item = tags#get_tag(line('w0'))
    let lnum = empty(item) ? line('w0') : str2nr(get(item, 1, 1))
    let nlines = max([0, line('.') - lnum])
    let info = '(' . get(item, 0, 'unknown') . ')'
    let msg = 'Syntax sync: minlines=' . nlines . ' ' . info
    let cmd = 'syntax sync minlines=' . nlines . ' maxlines=0'
  endif
  exe cmd | redraw | echom msg
endfunction

" Highlight group with gui or cterm codes
" NOTE: This enforces core grayscale-style defaults, with dark comments against
" darker background and sign and number columns that blend into the main window.
" NOTE: Cannot use e.g. aliases 'bg' or 'fg' in terminal since often unset, and cannot
" use transparent 'NONE' in gui vim since undefined, so swap them here.
function! s:update_highlight(group, back, front, ...) abort
  let defaults = {'Black': '#000000', 'DarkGray': '#222222', 'Gray': '#444444'}
  call extend(defaults, {'LightGray': '#666666', 'White': '#888888'})
  let name = has('gui_running') ? 'gui' : 'cterm'
  let text = a:0 && type(a:1) ? empty(a:1) ? 'None' : a:1 : ''
  let args = empty(text) ? [] : [name . '=' . text]
  if type(a:back)
    if empty(a:back)  " background
      let code = has('gui_running') ? 'bg' : 'NONE'
    elseif has('gui_running')  " hex color
      let code = get(g:, 'statusline_' . a:back, get(defaults, a:back, a:back))
    else  " color name
      let code = a:back
    endif
    call add(args, name . 'bg=' . code)
  endif
  if type(a:front)  " foreground
    if empty(a:front)
      let code = has('gui_running') ? 'fg' : 'NONE'
    elseif has('gui_running')  " hex color
      let code = get(g:, 'statusline_' . a:front, get(defaults, a:front, a:front))
    else  " color name
      let code = a:front
    endif
    call add(args, name . 'fg=' . code)
  endif
  exe 'noautocmd highlight ' . a:group . ' ' . join(args, ' ')
  exe 'noautocmd highlight ' . a:group . ' ' . join(args, ' ')
endfunction

" Update default cterm highlight groups
" NOTE: Here :set background triggers colorscheme autocmd so 'noautocmd' is
" required to avoid infinite loop.
" NOTE: Here need special workaround to apply bold gui syntax for folded text.
" See: https://stackoverflow.com/a/73783079/4970632
function! syntax#update_highlights() abort
  let name0 = has('gui_running') ? 'macvim' : 'default'
  let name = get(g:, 'colors_default', name0)
  let name1 = get(g:, 'colors_name', name0)
  if name1 ==? name && has('gui_running')  " user highlighting
    call s:update_highlight('Normal', 'MacTextBackgroundColor', 'MacTextColor', '')
  elseif name1 ==? name && !has('gui_running')
    exe 'noautocmd set background=dark'
    call s:update_highlight('Normal', '', '', '')
    call s:update_highlight('MatchParen', 'Blue', '')
    call s:update_highlight('Sneak', 'DarkMagenta', '')
    call s:update_highlight('Search', 'Magenta', '')
    call s:update_highlight('PmenuSel', 'Magenta', '', '')
    call s:update_highlight('PmenuSbar', 'DarkGray', '', '')
    call s:update_highlight('Type', '', 'DarkGreen')
    call s:update_highlight('Constant', '', 'Red')
    call s:update_highlight('Special', '', 'DarkRed')
    call s:update_highlight('PreProc', '', 'DarkCyan')
    call s:update_highlight('Indentifier', '', 'Cyan', 'bold')
  endif
  let group = hlget('Folded')[0]  " enforce bold folded gui text
  let group['gui'] = extend(get(group, 'gui', {}), {'bold': v:true})
  call hlset([group])  " apply bold folded gui text
  if has('gui_running')
    call s:update_highlight('CursorLine', 'DarkGray', 0, '')
    call s:update_highlight('Comment', '', 'Gray', '')
    call s:update_highlight('Todo', '', 'LightGray', '')
    call s:update_highlight('Folded', '', 'White', '')
  else
    call s:update_highlight('CursorLine', 'Black', 0, '')
    call s:update_highlight('Comment', '', 'Black', '')
    call s:update_highlight('Todo', '', 'Gray', '')
    call s:update_highlight('Folded', '', 'LightGray', '')
  endif
  if v:true  " shared highlighting
    call s:update_highlight('DiffAdd', 'Black', '', 'bold')
    call s:update_highlight('DiffChange', '', '', '')
    call s:update_highlight('DiffDelete', 'Black', 'Black', '')
    call s:update_highlight('DiffText', 'Black', '', 'bold')
    call s:update_highlight('Search', 'DarkYellow', 0, '')
    call s:update_highlight('ErrorMsg', 'DarkRed', 'White', '')
    call s:update_highlight('WarningMsg', 'LightRed', 'Black', '')
    call s:update_highlight('InfoMsg', 'LightYellow', 'Black', '')
    call s:update_highlight('StatusLineTerm', 'LightYellow', 'Black', '')
    call s:update_highlight('StatusLineTermNC', '', 'LightYellow', '')
  endif
endfunction

" Update syntax highlight group links
" NOTE: ALE highlights point to nothing when scrolling color schemes, but are still
" used for sign definitions, so manually enable here (note getcompletion() will fail)
" NOTE: Plugins vim-tabline and vim-statusline use custom auto-calculated colors
" based on colorscheme. Leverage them instead of reproducing here.
function! syntax#update_links() abort
  let pairs = [['ColorColumn', 'CursorLine']]  " highlight links
  for group in ['Conceal', 'Pmenu', 'Terminal']
    call add(pairs, [group, 'Normal'])
  endfor
  for group in ['LineNR', 'SignColumn', 'FoldColumn', 'CursorLineNR', 'CursorLineFold', 'NonText', 'SpecialKey']
    call add(pairs, [group, 'Comment'])
  endfor
  for group in ['ALEErrorLine', 'ALEWarningLine', 'ALEInfoLine']  " see above
    call add(pairs, [group, 'Conceal'])
  endfor
  for group in ['ModeMsg', 'Marker'] + getcompletion('GitGutter', 'highlight')  " see above
    call add(pairs, [group, 'Folded'])
  endfor
  for group in ['ALEError', 'ALEErrorSign', 'ALEStyleError', 'ALEStyleErrorSign']  " see above
    call add(pairs, [group, 'ErrorMsg'])
  endfor
  for group in ['ALEWarning', 'ALEWarningSign', 'ALEStyleWarning', 'ALEStyleWarningSign']  " see above
    call add(pairs, [group, 'WarningMsg'])
  endfor
  for group in ['ALEInfo', 'ALEInfoSign']  " see above
    call add(pairs, [group, 'InfoMsg'])
  endfor
  for [tail, dest] in [['Shebang', 'Special'], ['Hyperlink', 'Underlined']]
    call add(pairs, [tail, dest])
  endfor
  for [tail, dest] in [['Header', 'Todo'], ['Colon', 'Comment']]
    call add(pairs, ['comment' . tail, dest])
  endfor
  for tail in ['Map', 'NotFunc', 'FuncKey', 'Command']
    call add(pairs, ['vim' . tail, 'Statement'])
  endfor
  for [group1, group2] in pairs
    exe 'highlight! link ' . group1 . ' ' . group2
  endfor
endfunction

" Update syntax match groups. Could move to after/syntax but annoying
" WARNING: Critical to include 'comment' in group names or else pep8 indent expression
" incorrectly auto-indents. See: https://github.com/Vimjas/vim-python-pep8-indent
" NOTE: This tries to fix docstring highlighting issues but inconsistent, so also
" have vimrc 'syntax sync' mappings. See: https://github.com/vim/vim/issues/2790
" NOTE: The URL regex is from .tmux.conf and https://vi.stackexchange.com/a/11547/8084
" and the containedin line just tries to *guess* what particular comment and string
" group names are for given filetype syntax schemes (use :Group for testing).
function! syntax#update_groups() abort
  if &filetype ==# 'html'  " no spell comments (here overwrite original group name)
    syntax region htmlComment start='<!--' end='--\s*>' contains=@NoSpell
    highlight link htmlComment Comment
  elseif &filetype ==# 'json'  " json comments: https://stackoverflow.com/a/68403085/4970632
    syntax match jsonComment '^\s*\/\/.*$'
    highlight link jsonComment Comment
  elseif &filetype ==# 'vim'  " repair comments: https://github.com/vim/vim/issues/11307
    syntax match vimQuoteComment '^[ \t:]*".*$' contains=vimComment.*,@Spell
    highlight link vimQuoteComment Comment | silent! syntax clear vimInsert vimCommentTitle vimCommentError
  elseif &filetype ==# 'fortran'  " repair comments (ensure space and skip c = value)
    syntax match fortranComment excludenl '^\s*[cC]\s\+=\@!.*$' contains=@spell,@fortranCommentGroup
    highlight link fortranComment Comment
  elseif &filetype ==# 'python'  " fix syntax: https://stackoverflow.com/a/28114709/4970632
    highlight BracelessIndent ctermfg=NONE ctermbg=NONE cterm=inverse
    syntax sync minlines=100 | exe exists('*SetCellHighlighting') ? 'call SetCellHighlighting()' : ''
  endif
  syntax match Marker /\%({{{\d\?\|}}}\d\?\)\s*$/ containedin=.*Comment.*
  syntax match Shebang /^\%1l#!.*$/ contains=@NoSpell
  syntax match Hyperlink
    \ =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^' 	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]=
    \ containedin=.*\(Comment\|String\).*
  syntax match commentColon /:/ contained
  syntax match commentHeader
    \ /\C\%([a-z.]\s\+\)\@<!\%(Warning\|WARNING\|Error\|ERROR\|Fixme\|FIXME\|Todo\|TODO\|Note\|NOTE\|XXX\|{{{\d\?\|}}}\d\?\)[sS]\?:\@=/
    \ containedin=.*Comment.* contains=pythonTodo nextgroup=commentColon
endfunction

" Update on-the-fly matchadd() matches.
" NOTE: Unlike typical syntax highlighting these are window-local and do not
" require explicit names (assigned automatic ids). They are managed separately
" from :highlight and :syntax commands with getmatches() and setmatches()
" NOTE: Critical to make 'priority' (third argument, default 10) same as :hlsearch
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
    call s:update_highlight('StrikeThrough', 0, 0, 'strikethrough')
    call matchadd('Conceal', '<s>\ze\_.\{-}</s>', 10, -1, {'conceal': ''})
    call matchadd('Conceal', '<s>\_.\{-}\zs</s>', 10, -1, {'conceal': ''})
    call matchadd('StrikeThrough', '<s>\zs\_.\{-}\ze</s>')
  endif
endfunction
