"-----------------------------------------------------------------------------"
" Utilities for fugitive windows
"-----------------------------------------------------------------------------"
" Global settings
" NOTE: Fugitive maps get re-applied when re-opening existing fugitive buffers due to
" its FileType autocommands, so should not have issues modifying already-modified maps.
" NOTE: Many mappings call script-local functions with strings like 'tabedit', and
" initially tried replacing with 'Drop', but turns out these all call fugitive
" internal commands like :Gtabedit and :Gedit (and there is no :Gdrop). So now
" overwrite :Gtabedit in .vimrc. Also considered replacing 'tabedit' with 'drop' in
" maps and having fugitive use :Gdrop, but was getting error where after tab switch
" an empty panel was opened in the git window. Might want to revisit.
" let rhs = substitute(rhs, '\C\<tabe\a*', 'drop', 'g')  " use :Git drop?
let s:cmd_graph = '--graph --abbrev-commit --max-count=50'  " {{{
let s:cmd_format = '--date=relative --branches --decorate'
let s:cmd_vert = ['commits', 'log', 'refs', 'tree', 'trunk']  " vertical commands
let s:cmd_editor = ['merge', 'commit', 'oops']  " commands open editor
let s:cmd_oneline = ['add', 'stage', 'reset', 'push', 'pull', 'fetch', 'switch', 'restore', 'checkout']
let s:cmd_resize = {
  \ '': 0.5, 'commits': 0.5, 'log': 0.5, 'tree': 0.5, 'trunk': 0.5,
  \ 'show': 1, 'diff': 1, 'merge': 1, 'commit': 1, 'oops': 1, 'status': 1,
\ }
let s:cmd_translate = {
  \ 'status': '', 'log': 'log ' . s:cmd_graph,
  \ 'tree': 'log --stat ' . s:cmd_graph . ' ' . s:cmd_format,
  \ 'trunk': 'log --name-status ' . s:cmd_graph . ' ' . s:cmd_format,
  \ 'show': 'show --abbrev-commit',
  \ 'blame': 'blame --show-email',
  \ 'commits': 'log --graph --oneline ' . s:cmd_format,
\ }  " }}}
let s:map_drop = ['dq', '<<', '>>', '==', '<F1>', '<F2>']  " {{{
let s:map_translate = [
  \ ['n', '<2-LeftMouse>', 'O'],
  \ ['n', '<CR>', 'O'],
  \ ['n', 'o', '<CR>'],
  \ ['n', 'O', 'o'],
  \ ['nx', ';', '.'],
  \ ['nx', '.', '-'],
  \ ['nox', '{', '[c'],
  \ ['nox', '}', ']c'],
  \ ['nox', '(', '[m'],
  \ ['nox', ')', ']m'],
  \ ['nx', '[g', '('],
  \ ['nx', ']g', ')'],
  \ ['nx', ',', '=', ":\<C-u>call fold#update_folds(0, 1)\<CR>"],
  \ ['nx', '=', '=', ":\<C-u>call fold#update_folds(0, 1)\<CR>"],
  \ ]  " }}}

" Call fugitive internal command returned by fugitive#Command()
" TODO: Use bufhidden=delete more frequently, avoid tons of useless buffers
" NOTE: Here use 'Git' to open standard status pane and 'Git status' to open
" pane with diff hunks expanded with '=' and folded with 'zc'.
function! s:call_fugitive(bnum, lnum, cmd, ...) abort
  let winview = winsaveview()
  let input = join(a:000, '')
  let name = split(input, '', 1)[0]
  let panel = name ==# 'commit' && input !~# '--message'
  let panel = panel || a:bnum != bufnr() || a:cmd =~# '\<v\?split\>'
  if a:cmd =~# '^echoerr'
    let msg = substitute(a:cmd, '^echoerr', 'echom', '')
    redraw | echohl ErrorMsg | exe msg | echohl None
  elseif !panel  " no panel generated
    let space = index(s:cmd_oneline, name) != -1 ? ' ' : "\n"
    redraw | echo 'Git ' . input . space | exe a:cmd
  else  " panel generated
    let [width, height] = [winwidth(0), winheight(0)]
    let resize = get(s:cmd_resize, name, 0)  " default panel size
    silent exe a:cmd | let check = bufnr() != a:bnum
    if check | setlocal bufhidden=delete | endif
    if check && line('$') <= 1 | quit | call winrestview(winview) | endif
    if a:bnum == bufnr() && input =~# '^blame'  " syncbind is no-op if not vertical
      exe a:lnum | exe 'normal! z.' | call feedkeys("\<Cmd>syncbind\<CR>", 'n')
    elseif a:bnum != bufnr() && name ==# 'status'  " open change statistics
      keepjumps goto | exe 'normal ='
    elseif a:bnum != bufnr() && input =~# '\s\+%'  " open single difference fold
      exe 'normal! zv'
    endif
    if bufnr() == a:bnum
      exe 'vertical resize ' . width | exe 'resize ' . height
    elseif input =~# '^blame\( %\)\@!' || a:cmd =~# '\<\(vsplit\|vert\(ical\)\?\)\>'
      call window#default_width(resize)
    else  " bottom panel
      call window#default_height(resize)
    endif
  endif
  return panel && a:cmd !~# '^echoerr'  " whether echo required
endfunction

" Call fugitive :Git via command or mapping (see git#setup_commands())
" NOTE: Fugitive does not currently use &previewwindow and does not respect <mods>
" so set window explicitly below. See: https://stackoverflow.com/a/8356605/4970632
" Run from <expr> mapping
function! git#call_git_expr(...) abort
  return utils#motion_func('git#call_git', a:000, 1)
endfunction
" Run from normal mode
function! git#call_git(range, ...) range abort
  if a:range && a:firstline == a:lastline
    let offset = 5 | let [line1, line2] = [a:firstline - offset, a:lastline + offset]
  else
    let offset = 0 | let [line1, line2] = sort([a:firstline, a:lastline], 'n')
  endif
  if a:range || line1 != line2
    call call('s:call_git', [0, line1, line2, a:range] + a:000)
  else
    call call('s:call_git', [0, line1, -1, a:range] + a:000)
  endif
  call feedkeys(offset ? abs(offset) . (offset > 0 ? 'j' : 'k') : '', 'n')
endfunction
" Run from command line
function! s:call_git(msg, line1, count, range, bang, mods, cmd, ...) range abort
  let [bnum, lnum] = [bufnr(), line('.')]
  let icmd = empty(FugitiveGitDir()) ? '' : a:cmd
  let [name; flags] = split(icmd, '\\\@<!\s\+', 1)
  let icmd = get(s:cmd_translate, name, name) . ' ' . join(flags, ' ')
  if !empty(a:mods) || a:cmd =~# '^blame\( %\)\@!'
    let imod = a:mods
  elseif index(s:cmd_vert, name) >= 0
    let imod = 'vert botright'
  else
    let imod = 'botright'
  endif
  silent let args = [a:line1, a:count, a:range, a:bang, imod, icmd]
  silent let cmd = call('fugitive#Command', args + a:000)
  let verbose = s:call_fugitive(bnum, lnum, cmd, a:cmd)
  let error = type(a:msg) ? a:msg : string('Git ' . a:cmd)
  let error = 'Warning: ' . error . ' was empty'
  if verbose && bnum == bufnr()  " empty result
    redraw | echohl WarningMsg | echom error | echohl None
  elseif verbose
    redraw | echo 'Git ' . a:cmd
  endif
endfunction

" Call git commit with or without editor
" NOTE: Git commit is asynchronous unlike others so resize must be reapplied here. In
" general do not apply resize to setup functions since could be panel or full-screen.
" NOTE: This prevents annoying <press enter to continue> message showing up when
" committing with no staged changes, issues a warning instead of showing the message.
function! git#complete_commit(lead, line, cursor, ...) abort
  let cnt = a:0 ? a:1 : 50  " default count
  let lead = '^' . escape(a:lead, '[]\/.*$~')
  let input = get(get(s:, 'messages', {}), FugitiveGitDir(), '')
  let logs = FugitiveExecute(['log', '-n', string(cnt), '--pretty=%B'])
  let opts = empty(input) ? logs.stdout : [input] + logs.stdout
  let opts = filter(opts, '!empty(v:val) && v:val =~# ' . string(lead))
  return map(opts, 'substitute(v:val, "\s\+", "", "g")')
endfunction
function! git#call_commit(editor, ...) abort
  let cmd = a:0 ? a:1 : 'commit'  " commit version
  let flag = cmd =~# '^stash' ? [] : ['--staged']
  let args = ['diff', '--quiet']  " see: https://stackoverflow.com/a/1587877/4970632
  let result = FugitiveExecute(args + flag)
  let status = get(result, 'exit_status', 1)
  if status == 0 && cmd !~# '^oops'  " exits 0 if there are no staged changes
    let msg = empty(flag) ? 'No unstaged changes' : 'No staged changes'
    if !a:editor
      redraw | echohl WarningMsg | echom 'Warning: ' . msg | echohl None | return
    endif
    return s:call_git(msg, line('.'), -1, 0, 0, '', 'status')
  endif
  if !a:editor
    let s:messages = get(s:, 'messages', {})
    let default = get(git#complete_commit('', '', '', 1), 0, '')
    let base = FugitiveGitDir()  " base directory
    let opts = FugitiveExecute(['log', '-n', '50', '--pretty=%B'])
    let msg = utils#input_default('Git ' . cmd, default, 'git#complete_commit')
    if !empty(msg) | let s:messages[base] = msg[:49] | endif
    while !empty(msg) && len(msg) > 50  " see .bashrc git()
      let msg = 'Error: Message has length ' . len(msg) . '. Must be less than or equal to 50.'
      redraw | echohl WarningMsg | echom msg | echohl None
      let msg = utils#input_default('Git ' . cmd, msg[:49], 'git#complete_commit')
      if !empty(msg) | let s:messages[base] = msg[:49] | endif
    endwhile
    if empty(msg) | return | endif
    let cmd .= ' --message ' . shellescape(msg)
  endif
  call s:call_git(0, line('.'), -1, 0, 0, '', cmd)
endfunction

" Helper functions for git gutter utilities
" NOTE: Git gutter works by triggering on &updatetime after CursorHold only if
" text was changed and starts async process. Here temporarily make synchronous.
function! s:show_hunks(locs, max, msg, ...) abort
  if empty(a:locs)
    let msg = 'E490: No hunks found'
  elseif len(uniq(sort(a:locs))) == a:max
    let msg = a:msg . ' (' . a:max . ' total)'
  else  " show hunk ranges
    let [min, max] = [min(a:locs), max(a:locs)]
    let range = min == max ? a:locs[0] : min . '-' . max
    let msg = a:msg . ' (' . range . ' of ' . a:max . ')'
  endif
  let cmd = empty(a:locs) ? 'echoerr' : a:0 && a:1 ? 'echom' : 'echo'
  let feed = "\<Cmd>redraw\<CR>\<Cmd>" . cmd . ' ' . string(msg) . "\<CR>"
  call feedkeys(feed, 'n')
endfunction
function! s:get_hunks(...) abort
  let skip = a:0 ? a:1 : 0
  let bnr = bufnr()
  if &l:diff
    return 0
  endif
  if !skip
    try  " synchronous update
      let g:gitgutter_async = 0
      call gitgutter#process_buffer(bnr, 0)
    finally
      let g:gitgutter_async = 1
    endtry
  endif
  if !pumvisible() && !gitgutter#utility#is_active(bnr)
    return 0  " ignore gitgutter pumvisible() condition
  endif
  let hunks = gitgutter#hunk#hunks(bnr)
  if !skip && empty(hunks)
    let msg = 'Error: No hunks in file'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
  return hunks
endfunction

" Create git gutter hunk description
" NOTE: Here g:gitgutter['hunks'] are [from_start, from_count, to_start, to_count]
" lists i.e. starting line and counts before and after changes. Adapated s:isadded()
" s:isremoved() etc. methods from autoload/gitgutter/diff.vim for partitioning into
" simple added/changed/removed groups (or just 'changed') as shown below.
function! git#_get_hunks(line1, line2, ...) abort
  let locs = []  " hunk indices
  let cnts = [0, 0, 0]  " change counts
  let skip = a:0 ? a:1 : 0  " skip synchronous
  let hunks = s:get_hunks(skip)
  if empty(hunks) | return '' | endif
  for idx in range(len(hunks))
    let [hunk0, count0, hunk1, count1] = hunks[idx]
    let hunk2 = count1 ? hunk1 + count1 - 1 : hunk1
    let clip1 = max([hunk1, a:line1])
    let clip2 = min([hunk2, a:line2])
    if clip2 < clip1 | continue | endif
    let offset = (hunk2 - clip2) + (clip1 - hunk1)  " count change
    let cnt0 = max([count0 - offset, 0])
    let cnt1 = max([count1 - offset, 0])
    let cnts[0] += max([cnt1 - cnt0, 0])  " added
    let cnts[1] += min([cnt0, cnt1])  " modified
    let cnts[2] += max([cnt0 - cnt1, 0])  " removed
    call add(locs, idx + 1)  " included hunk
  endfor
  let delta = cnts[0] ? '+' . cnts[0] : ''
  let delta .= cnts[1] ? '~' . cnts[1] : ''
  let delta .= cnts[2] ? '-' . cnts[2] : ''
  if !skip && !empty(locs) " show message
    let msg = 'Hunk(s): ' . delta
    call s:show_hunks(locs, len(hunks), msg, 0)
  endif
  return delta
endfunction
" For optional range arguments
function! git#get_hunks(...) range abort
  return call('git#_get_hunks', [a:firstline, a:lastline] + a:000)
endfunction
" For <expr> map accepting motion
function! git#get_hunks_expr(...) abort
  return utils#motion_func('git#get_hunks', a:000, 1)
endfunction

" Git gutter staging and unstaging over input lines
" NOTE: Currently GitGutterStageHunk only supports partial staging of additions
" specified by visual selection, not different hunks. This supports both, iterates in
" reverse in case lines change. See: https://github.com/airblade/vim-gitgutter/issues/279
" NOTE: Created below by studying s:get_hunks() and gitgutter#diff#exe_hunks()
" in autoload/gitgutter/diff.vim. Addition-only hunks have from_count '0' and to_count
" non-zero since no text was present before the change. Also note gitgutter#hunk#stage()
" requires cursor inside lines and fails when specifying lines outside of addition hunk
" (see s:hunk_op) so explicitly navigate lines below before calling stage commands.
function! git#_exe_hunks(line1, line2, ...) abort
  let cmd = a:0 && a:1 ? 'Undo' : 'Stage'
  let undo = a:0 && a:1 ? 1 : 0
  let locs = []  " hunk locations
  let ranges = []  " ranges staged
  let offset = 0  " offset after undo
  let hunks = s:get_hunks()  " general update
  let winview = winsaveview()
  if empty(hunks) | return | endif
  for idx in range(len(hunks))
    let [hunk0, count0, hunk1, count1] = hunks[idx]
    let [iline, jline] = [a:line1 + offset, a:line2 + offset]
    let [line0, line1] = [hunk0 + offset, hunk1 + offset]
    let line2 = count1 ? line1 + count1 - 1 : line1  " changed closing line
    if iline <= line1 && jline >= line2
      let range = []  " selection encapsulates hunk
    elseif iline >= line1 && jline <= line2
      let range = count0 || a:0 && a:1 ? [] : [iline, jline]
    elseif iline <= line2 && jline >= line2  " starts inside goes outside
      let range = count0 || a:0 && a:1 ? [] : [iline, line2]
    elseif iline <= line1 && jline >= line1  " starts outside goes inside
      let range = count0 || a:0 && a:1 ? [] : [line1, jline]
    else  " no update needed
      continue
    endif
    exe line1 | exe join(range, ',') . 'GitGutter' . cmd . 'Hunk'
    let range = empty(range) ? [line1, line2] : range
    let range = map(uniq(range), 'v:val - offset')
    let offset += a:0 && a:1 ? count0 - count1 : 0
    call add(locs, idx + 1)  " included hunk
    call add(ranges, join(range, '-'))
  endfor
  call winrestview(winview)
  if !empty(ranges)  " show information
    let msg = cmd . ' hunk(s): ' . join(ranges, ', ')
    call s:show_hunks(locs, len(hunks), msg, 1)
  endif
endfunction
" For optional range arguments
function! git#exe_hunks(...) range abort
  return call('git#_exe_hunks', [a:firstline, a:lastline] + a:000)
endfunction
" For <expr> map accepting motion
function! git#exe_hunks_expr(...) abort
  return utils#motion_func('git#exe_hunks', a:000, 1)
endfunction

" Update gitgutter hunks and show hunks under cursor
" NOTE: Here skip hunks beneath current closed fold. This is consistent with native
" vim behavior, since n/N do not open fold under cursor to access inner match even if
" foldopen contains 'search' (but may open match in another fold). See also tags.vim
function! s:next_hunk(hunk, ...) abort
  let stage = a:0 ? a:1 : 0
  exe a:hunk[2] == 0 ? 1 : a:hunk[2]
  if !stage | return | endif
  let keys = git#exe_hunks_expr(0)  " see vimrc maps
  let keys .= (foldclosed('.') > 0 ? 'iz' : 'ih')
  exe 'keepjumps normal ' . keys
endfunction
function! git#next_hunk(count, ...) abort
  let cnt = a:count
  let stage = a:0 ? a:1 : 0
  let forward = cnt >= 0
  if empty(cnt) | return | endif
  if &l:diff  " native vim jumps
    let keys = abs(cnt) . (forward ? ']c' : '[c')
    exe 'normal! ' . keys | return
  endif
  let hunk = s:current_hunk()  " hunk under cursor
  if stage && !empty(hunk)
    let cnt += forward ? -1 : 1
    call s:next_hunk(hunk, 1)
  endif
  let lnum = forward ? foldclosedend('.') : foldclosed('.')
  let lnum = lnum > 0 ? lnum : line('.')  " ignore within fold
  let hunks = s:get_hunks()
  let hunks = forward ? hunks : reverse(copy(hunks))
  if empty(hunks) | return | endif
  for ihunk in hunks
    if cnt == 0 | break | endif
    if cnt > 0 ? ihunk[2] > lnum : ihunk[2] < lnum
      let cnt += forward ? -1 : 1
      let hunk = ihunk  " stop if count zero
      call s:next_hunk(hunk, stage)
    endif
  endfor
  if cnt == a:count  " no jumps or stages so echo message
    let msg = 'Warning: No more hunks'
    redraw | echohl WarningMsg | echom msg | echohl None
  elseif !stage  " WARNING: 'G' changes v:count1 which messes up repeat.vim [G/]G
    exe &l:foldopen =~# 'block\|all' ? 'normal! zv' : ''
    call s:show_hunk(hunk)
  endif
endfunction

" Conflict jumping and delta folding
" NOTE: This is adapted from conflict-marker.vim/autoload/conflict_marker.vim. Only
" searches for complete blocks, ignores false-positive matches e.g. markdown ===
" NOTE: Fold expr supports normal, context, unified, rcs, ed, subversion and git diffs.
" For rcs diffs folds only files (rcs has no hunks in common sense). Uses foldlevel=1
" ==> file foldlevel=2 ==> hunk. Note context diffs need special treatment, as hunks
" are defined via context (after '***'), and checking for '*** ' or ('--- ') only
" does not work since the file lines have the same marker. Copied this from elsewhere
function! git#fold_expr(lnum) abort
  let line = getline(a:lnum)  " see below
  let regex1 = '^\(diff\|Index\)'  " difference file
  let regex2 = '^\(@@\|\d\)\|^[*-]\{3}\s*\d\+,\d\+\s*[*-]\{3}'  " difference hunk
  return line =~# regex2 ? '>2' : line =~# regex1 ? '>1' : '='
endfunction
function! git#next_conflict(count, ...) abort
  let winview = winsaveview()
  let reverse = a:0 && a:1
  if !reverse
    for _ in range(a:count) | let pos0 = searchpos(g:conflict_marker_begin, 'w') | endfor
    let pos1 = searchpos(g:conflict_marker_separator, 'cW')
    let pos2 = searchpos(g:conflict_marker_end, 'cW')
  else
    for _ in range(a:count) | let pos2 = searchpos(g:conflict_marker_end, 'bw') | endfor
    let pos1 = searchpos(g:conflict_marker_separator, 'bcW')
    let pos0 = searchpos(g:conflict_marker_begin, 'bcW')
  endif
  if pos2[0] > pos1[0] && pos1[0] > pos0[0]
    call cursor(pos0)  " always open folds (same as gitgutter)
    exe 'normal! zv'
  else  " echo warning
    let msg = 'Error: No conflicts'
    redraw | echohl ErrorMsg | echom msg | echohl None | call winrestview(winview)
  endif
endfunction

" Git gutter hunk objects (compare with fold.vim)
" WARNING: Native gitgutter changes lines with 'G' which resets count and causes
" utils#repeat_map() invocation of v:prevcount to use giant line number.
function! git#object_hunk_i() abort
  return s:object_hunk(0)
endfunction
function! git#object_hunk_a() abort
  return s:object_hunk(1)
endfunction
function! s:object_hunk(...) abort
  let hunk = s:current_hunk()
  if empty(hunk)
    let msg = 'E490: No hunk found'
    redraw | echohl ErrorMsg | echom msg | echohl None
    return ['v', getpos('.'), getpos('.')]
  endif
  let [line1, line2] = [hunk[2], hunk[2] + hunk[3] - 1]
  if a:0 && a:1
    let inum = line('$')
    let lnum = line2
    while lnum < inum && empty(trim(getline(lnum + 1)))
      let lnum += 1
    endwhile
    let line2 = lnum
  endif
  let pos1 = [0, line1, 1, 0]
  let pos2 = [0, line2, col([line2, '$']), 0]
  return ['V', pos1, pos2]
endfunction

" Show hunk under cursor
" NOTE: Compare to vim-lsp and ale.vim utilities. Here we do not auto-open
" hunk difference popups since they are way bigger than those plugins.
function! s:show_hunk(hunk) abort
  if empty(a:hunk) | return | endif
  let [line1, line2] = [a:hunk[2], a:hunk[2] + max([a:hunk[3], 1]) - 1]
  let [fold1, fold2] = [foldclosed(line1), foldclosedend(line2)]
  return git#_get_hunks(fold1 > 0 ? fold1 : line1, fold2 > 0 ? fold2 : line2)
endfunction
function! s:current_hunk() abort
  let hunks = s:get_hunks(1)
  if empty(hunks) | return [] | endif
  let hunk = []
  for ihunk in hunks
    if gitgutter#hunk#cursor_in_hunk(ihunk)
      let hunk = ihunk | break
    endif
  endfor | return hunk
endfunction
function! git#current_hunk() abort
  call map(popup_list(), 'popup_close(v:val)')
  call switch#gitgutter(1, 1)  " turn on if possible
  let hunks = s:get_hunks()
  if empty(hunks) | return | endif
  let hunk = s:current_hunk()
  if empty(hunk)
    let msg = 'Error: No hunk under cursor'
    redraw | echohl ErrorMsg | echom msg | echohl None | return
  endif
  GitGutterPreviewHunk
  call window#setup_preview()
  let winids = popup_list()
  if empty(winids) | return | endif
  call s:show_hunk(hunk)
endfunction

" Helper functions for fugitive commands
" NOTE: Fugitive commands permit overriding both option flags and sink entries
" NOTE: Native fzf-vim :BCommits and :Commits commands include bindings inconsistent
" with panel actions (hitting enter calls :edit, hitting ctrl-d runs split diff) so
" here ensure enter triggers :Drop which calls edit only if in single-tab pane and
" override ctrl-d mapping and header help information with standard mappings.
function! git#setup_opts() abort
  let b:fzf_winview = winsaveview()  " copied from fzf.vim
  let opts = fzf#vim#with_preview({'placeholder': ''})
  let opts['sink*'] = function('git#setup_sink')
  call extend(opts.options, ['--header', '', '--header-first'])
  call extend(opts.options, ['--bind', 'ctrl-d:half-page-down'])
  call extend(opts.options, ['--no-expect', '--expect=ctrl-y,ctrl-o'])
  return opts
endfunction
function! git#setup_sink(lines)
  let regex = '[0-9a-f]\{7,40}'
  if len(a:lines) < 2 | return | endif
  if a:lines[0] ==# 'ctrl-y'
    let hash = join(filter(map(a:lines[1:], 'matchstr(v:val, regex)'), 'len(v:val)'))
    let @" = hash | silent! let @* = hash | silent! let @+ = hash | return
  endif
  let cmd = get(get(g:, 'fzf_action', {}), a:lines[0], '')
  let cmd = type(cmd) == 1 && !empty(cmd) ? cmd : 'Drop'
  for idx in range(1, len(a:lines) - 1)
    let sha = matchstr(a:lines[idx], regex)
    if empty(sha) | continue | endif
    exe cmd . ' ' . FugitiveFind(sha)
  endfor
endfunction

" Setup fugitive windows
" See: https://github.com/sgeb/vim-diff-fold/
" NOTE: Renamed files additionally have file name next to the commit number.
" NOTE: Native fugitive command is declared with :command! Git -nargs=? -range=-1
" fugitive#Command(<line1>, <count>, +'<range>', <bang>0, '<mods>', <q-args>)
" where <line1> is cursor line, <count> is -1 if no range supplied and <line2>
" if any range supplied (see :help command-range), and confusingly <range> is the
" number of range arguments supplied (i.e. 0 for :Git, 1 for e.g. :10Git, and
" 2 for e.g. :10,20Git) where +'<range>' forces this to integer.
function! git#setup_blame() abort
  let regex = '^\x\{8}\s\+.\{-}\s\+(\zs<\S\+>\s\+'
  call matchadd('Conceal', regex, 0, -1, {'conceal': ''})
  call feedkeys(window#count_panes('h') == 1 ? "\<Cmd>call window#default_width(0)\<CR>": '', 'n')
endfunction
function! git#setup_commit(...) abort
  call switch#autosave(1, 1)
  call window#default_height(1) | setlocal colorcolumn=73
  keepjumps goto | call feedkeys("\<Cmd>startinsert\<CR>", 'n')
endfunction
function! git#setup_deltas() abort  " also used for general diff filetypes
  for val in s:map_drop | silent! exe 'unmap <buffer> ' . val | endfor
  let &l:foldexpr = 'git#fold_expr(v:lnum)'
  let &l:foldmethod = &l:filetype ==# 'fugitive' ? 'syntax' : 'expr'
  call matchadd('Conceal', '^[ +-]', 0, -1, {'conceal': ''})
  call call('utils#map_from', &l:filetype ==# 'diff' ? [] : s:map_translate)
  call fold#update_folds(0, 0)  " re-apply defaults after setting foldexpr
endfunction
function! git#setup_commands() abort
  for cmd in ['drop', 'Drop']  " tab drop sinks
    exe 'command! -buffer -nargs=* -bang G' . cmd . ' Gtabedit <args>'
  endfor
  for cmd in ['diff', 'split', 'diffsplit']  " outdated commands
    silent! exe 'delcommand -buffer G' . cmd
  endfor
  command! -buffer -bar -bang -nargs=? -range=-1 -complete=customlist,fugitive#Complete
    \ G call s:call_git(0, <line1>, <count>, +'<range>', <bang>0, '<mods>', <q-args>)
  command! -buffer -bar -bang -nargs=? -range=-1 -complete=customlist,fugitive#Complete
    \ Git call s:call_git(0, <line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)
  command! -buffer -bar -bang -range=-1 -nargs=* -complete=customlist,fugitive#EditComplete
    \ Gtabedit exe fugitive#Open(<q-args> =~# '^+' ? 'edit' : 'Drop', <bang>0, '<mods>', <q-args>)
  command! -buffer -bar -bang -nargs=* -range=% BCommits
    \ <line1>,<line2>call fzf#vim#buffer_commits(<q-args>, git#setup_opts(), <bang>0)
  command! -buffer -bar -bang -nargs=* -range=% -complete=file Commits
    \ <line1>,<line2>call fzf#vim#commits(<q-args>, git#setup_opts(), <bang>0)
endfunction
