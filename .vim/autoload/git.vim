"-----------------------------------------------------------------------------"
" Utilities for fugitive windows
"-----------------------------------------------------------------------------"
" Global settings
" Note: Fugitive maps get re-applied when re-opening existing fugitive buffers due to
" its FileType autocommands, so should not have issues modifying already-modified maps.
" Note: Many mappings call script-local functions with strings like 'tabedit', and
" initially tried replacing with 'Drop', but turns out these all call fugitive
" internal commands like :Gtabedit and :Gedit (and there is no :Gdrop). So now
" overwrite :Gtabedit in .vimrc. Also considered replacing 'tabedit' with 'drop' in
" maps and having fugitive use :Gdrop, but was getting error where after tab switch
" an empty panel was opened in the git window. Might want to revisit.
" let rhs = substitute(rhs, '\C\<tabe\a*', 'drop', 'g')  " use :Git drop?
let s:log_trim = '--graph --abbrev-commit --max-count=50'
let s:log_format = '--date=relative --branches --decorate'
let s:cmd_vert = ['commits', 'log', 'tree', 'trunk']  " vertical commands
let s:cmd_editor = ['merge', 'commit', 'oops']  " commands open editor
let s:cmd_oneline = ['add', 'stage', 'reset', 'push', 'pull', 'fetch', 'switch', 'restore', 'checkout']
let s:cmd_resize = {
  \ '': 0.5, 'commits': 0.5, 'log': 0.5, 'tree': 0.5, 'trunk': 0.5,
  \ 'show': 0, 'diff': 0, 'merge': 0, 'commit': 0, 'oops': 0, 'status': 0,
\ }
let s:cmd_translate = {'status': '',
  \ 'log': 'log ' . s:log_trim,
  \ 'tree': 'log --stat ' . s:log_trim . ' ' . s:log_format,
  \ 'trunk': 'log --name-status ' . s:log_trim . ' ' . s:log_format,
  \ 'show': 'show --abbrev-commit',
  \ 'blame': 'blame --show-email',
  \ 'commits': 'log --graph --oneline ' . s:log_format,
\ }
let s:map_remove = ['dq', '<<', '>>', '==', '<F1>', '<F2>']
let s:map_from = [
  \ ['n', '<2-LeftMouse>', 'O'],
  \ ['n', '<CR>', 'O'],
  \ ['n', 'O', '<CR>'],
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
\ ]

" Helper setup functions for commands
" See: https://github.com/sgeb/vim-diff-fold/
" Works with normal, context, unified, rcs, ed, subversion and git diffs.
" For rcs diffs folds only files (rcs has no hunks in the common sense)
" Uses foldlevel=1 ==> file foldlevel=2 ==> hunk. Note context diffs need special
" treatment, as hunks are defined via context (after '***************'), and checking
" for '*** ' or ('--- ') only does not work, as file lines have the same marker.
function! git#setup_panel() abort  " also used for general diff filetypes
  for val in s:map_remove | silent! exe 'unmap <buffer> ' . val | endfor
  let &l:foldexpr = 'git#setup_folds(v:lnum)'
  let &l:foldmethod = &l:filetype ==# 'fugitive' ? 'syntax' : 'expr'
  call call('utils#map_from', &l:filetype ==# 'diff' ? [] : s:map_from)
  call fold#update_folds(0, 0)  " re-apply defaults after setting foldexpr
endfunction
function! git#setup_blame() abort
  let regex = '^\x\{8}\s\+\d\+\s\+(\zs<\S\+>\s\+'
  call matchadd('Conceal', regex, 0, -1, {'conceal': ''})
  if window#count_panes('h') == 1
    call feedkeys("\<Cmd>vertical resize " . window#default_width(1) . "\<CR>", 'n')
  endif
endfunction
function! git#setup_commit(...) abort
  exe 'resize ' . window#default_height()
  call switch#autosave(1, 1)  " suppress message
  setlocal colorcolumn=73
  goto | startinsert  " first row column
endfunction
function! git#setup_folds(lnum) abort
  let line = getline(a:lnum)
  if line =~# '^\(diff\|Index\)'     " file
    return '>1'
  elseif line =~# '^\(@@\|\d\)'  " hunk
    return '>2'
  elseif line =~# '^\*\*\* \d\+,\d\+ \*\*\*\*$' " context: file1
    return '>2'
  elseif line =~# '^--- \d\+,\d\+ ----$'     " context: file2
    return '>2'
  else
    return '='
  endif
endfunction

" Override native fugitive commands
" Note: Native fugitive command is declared with :command! Git -nargs=? -range=-1
" fugitive#Command(<line1>, <count>, +'<range>', <bang>0, '<mods>', <q-args>)
" where <line1> is cursor line, <count> is -1 if no range supplied and <line2>
" if any range supplied (see :help command-range), and confusingly <range> is the
" number of range arguments supplied (i.e. 0 for :Git, 1 for e.g. :10Git, and
" 2 for e.g. :10,20Git) where +'<range>' forces this to integer. Here, use simpler
" implicit distinction between calls with/without range where we simply test the
" equality of <line1> and <line2>, or allow a force-range a:range argument.
function! git#setup_commands() abort
  command! -buffer
    \ -bar -bang -nargs=? -range=-1 -complete=customlist,fugitive#Complete
    \ G call git#run_command(0, <line1>, <count>, +'<range>', <bang>0, '<mods>', <q-args>)
  command! -buffer
    \ -bar -bang -nargs=? -range=-1 -complete=customlist,fugitive#Complete
    \ Git call git#run_command(0, <line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)
  command! -buffer
    \ -bar -bang -range=-1 -nargs=* -complete=customlist,fugitive#EditComplete
    \ Gtabedit exe fugitive#Open(<q-args> =~# '^+' ? 'edit' : 'Drop', <bang>0, '<mods>', <q-args>)
  for cmd in ['drop', 'Drop']  " tab drop sinks
    exe 'command! -buffer -nargs=* -bang G' . cmd . ' Gtabedit <args>'
  endfor
  for cmd in ['diff', 'split', 'diffsplit']  " outdated commands
    silent! exe 'delcommand -buffer G' . cmd
  endfor
endfunction

" Run and process results of fugitive operation
" Todo: Use bufhidden=delete more frequently, avoid tons of useless buffers
" Note: Here use 'Git' to open standard status pane and 'Git status' to open
" pane with diff hunks expanded with '=' and folded with 'zc'.
function! s:run_cmd(bnum, lnum, cmd, ...) abort
  let input = join(a:000, '')
  let name = split(input, '', 1)[0]
  let editor = index(s:cmd_editor, name) != -1
  let newbuf = editor || a:bnum != bufnr() || a:cmd =~# '\<v\?split\>'
  if a:cmd =~# '^echoerr'
    let msg = substitute(a:cmd, '^echoerr', 'echom', '')
    redraw | echohl ErrorMsg | exe msg | echohl None
  elseif !newbuf  " no panel generated
    let space = index(s:cmd_oneline, name) != -1 ? ' ' : "\n"
    redraw | echo 'Git ' . input . space | exe a:cmd
  else  " panel generated
    let [width, height] = [winwidth(0), winheight(0)]
    let resize = get(s:cmd_resize, name, 1)
    silent exe a:cmd | let newbuf = a:bnum != bufnr()
    if newbuf
      setlocal bufhidden=delete | if line('$') <= 1 | call window#close_pane(1) | endif
    endif
    if bufnr() == a:bnum
      if input =~# '^blame'  " syncbind is no-op if not vertical
        exe a:lnum | exe 'normal! z.' | call feedkeys("\<Cmd>syncbind\<CR>", 'n')
      elseif newbuf && input =~# '\s\+%'  " open single difference fold
        call feedkeys('zv', 'n')
      elseif newbuf && name ==# 'status'  " open change statistics
        call feedkeys('gg=', 'm')
      endif
      exe 'vertical resize ' . width | exe 'resize ' . height
    elseif input =~# '^blame\( %\)\@!' || a:cmd =~# '\<\(vsplit\|vert\(ical\)\?\)\>'
      exe 'vertical resize ' . window#default_width(resize)
    else  " bottom panel
      exe 'resize ' . window#default_height(resize)
    endif
  endif
  return newbuf && a:cmd !~# '^echoerr'  " whether echo required
endfunction

" Run fugitive command or mapping
" Note: Fugitive does not currently use &previewwindow and does not respect <mods>
" so set window explicitly below. See: https://stackoverflow.com/a/8356605/4970632
" Run from command line
function! git#run_command(msg, line1, count, range, bang, mods, cmd, ...) abort range
  let [bnum, lnum] = [bufnr(), line('.')]
  let icmd = empty(FugitiveGitDir()) ? '' : a:cmd
  let [name; flags] = split(icmd, '\\\@<!\s\+', 1)
  let icmd = get(s:cmd_translate, name, name) . ' ' . join(flags, ' ')
  let imod = empty(a:mods) ? index(s:cmd_vert, name) > 0 ? 'vert botright' : 'botright' : a:mods
  let args = [a:line1, a:count, a:range, a:bang, imod, icmd]
  silent let rcmd = call('fugitive#Command', args + a:000)
  let verbose = s:run_cmd(bnum, lnum, rcmd, a:cmd)
  let input = 'Git ' . a:cmd
  let error = 'Warning: ' . (type(a:msg) ? a:msg : string(input) . ' was empty')
  if verbose && bnum == bufnr()  " empty result
    redraw | echohl WarningMsg | echom error | echohl None
  elseif verbose
    redraw | echom input
  endif
endfunction
" Run from normal mode
function! git#run_map(range, ...) abort range
  if a:range && a:firstline == a:lastline
    let offset = 5 | let [line1, line2] = [a:firstline - offset, a:lastline + offset]
  else
    let offset = 0 | let [line1, line2] = sort([a:firstline, a:lastline], 'n')
  endif
  if a:range || line1 != line2
    call call('git#run_command', [0, line1, line2, a:range] + a:000)
  else
    call call('git#run_command', [0, line1, -1, a:range] + a:000)
  endif
  call feedkeys(offset ? abs(offset) . (offset > 0 ? 'j' : 'k') : '', 'n')
endfunction
" For <expr> map accepting motion
function! git#run_map_expr(...) abort
  let winview = winsaveview()
  return utils#motion_func('git#run_map', a:000)
endfunction

" Git commit and edit actions
" Note: Git commit is asynchronous unlike others so resize must be reapplied here. In
" general do not apply resize to setup functions since could be panel or full-screen.
" Note: This prevents annoying <press enter to continue> message showing up when
" committing with no staged changes, issues a warning instead of showing the message.
function! git#complete_msg(lead, line, cursor, ...) abort
  let cnt = a:0 ? a:1 : 50  " default count
  let result = FugitiveExecute(['log', '-n', string(cnt), '--pretty=%B'])
  let lead = string('^' . escape(a:lead, '[]\/.*$~'))
  let opts = filter(copy(result.stdout), 'len(v:val)')
  let opts = filter(copy(opts), 'v:val =~# ' . lead)
  return map(opts, 'substitute(v:val, "\s\+", "", "g")')
endfunction
function! git#commit_wrap(editor, ...) abort
  let cmd = a:0 ? a:1 : 'commit'  " commit version
  let flag = cmd =~# '^stash' ? [] : ['--staged']
  let args = ['diff', '--quiet']  " see: https://stackoverflow.com/a/1587877/4970632
  let result = FugitiveExecute(args + flag)
  let status = get(result, 'exit_status', 1)
  if status == 0 && cmd !~# '^oops'  " exits 0 if there are no staged changes
    let msg = empty(flag) ? 'No unstaged changes' : 'No staged changes'
    if !a:editor
      redraw | echohl WarningMsg
      echom 'Warning: ' . msg
      echohl None | return
    endif
    return git#run_command(msg, line('.'), -1, 0, 0, '', 'status')
  endif
  if !a:editor
    let default = get(git#complete_msg('', '', '', 1), 0, '')
    let opts = FugitiveExecute(['log', '-n', '50', '--pretty=%B'])
    let msg = utils#input_default('Git ' . cmd, default, 'git#complete_msg')
    while !empty(msg) && len(msg) > 50  " see .bashrc git()
      redraw | echohl WarningMsg
      echom 'Error: Message has length ' . len(msg) . '. Must be less than or equal to 50.'
      echohl None
      let msg = utils#input_default('Git ' . cmd, msg[:49], 'git#complete_msg')
    endwhile
    if empty(msg) | return | endif
    let cmd .= ' --message ' . shellescape(msg)
  endif
  call git#run_command(0, line('.'), -1, 0, 0, '', cmd)
endfunction

" Git hunk jumping and previewing
" Note: Git gutter works by triggering on &updatetime after CursorHold only if
" text was changed and starts async process. Here temporarily make synchronous.
" Note: Always ensure gitgutter on and up-to-date before actions. Note CursorHold
" triggers conservative update gitgutter#process_buffer('.', 0) that only runs if
" text was changed while GitGutter and staging commands trigger forced update.
function! s:hunk_process(...) abort
  call switch#gitgutter(1, 1)
  let force = a:0 ? a:1 : 0
  let g:gitgutter_async = 0
  try
    call gitgutter#process_buffer(bufnr(''), force)
  finally
    let g:gitgutter_async = 1
  endtry
endfunction
function! git#hunk_next(count, stage) abort
  call s:hunk_process()
  let str = a:count < 0 ? 'Prev' : 'Next'
  let cmd = 'keepjumps GitGutter' . str . 'Hunk'
  for _ in range(abs(a:count))
    exe cmd | exe a:stage ? 'GitGutterStageHunk' : ''
  endfor
endfunction
function! git#hunk_show() abort
  call s:hunk_process()
  GitGutterPreviewHunk
  silent wincmd j
  call window#setup_preview()
  redraw  " ensure message shows
  echom 'Hunk difference'
endfunction

" Git gutter statistics over input lines
" Note: Here g:gitgutter['hunks'] are [from_start, from_count, to_start, to_count]
" lists i.e. starting line and counts before and after changes. Adapated s:isadded()
" s:isremoved() etc. methods from autoload/gitgutter/diff.vim for partitioning into
" simple added/changed/removed groups (or just 'changed') as shown below.
function! git#hunk_stats(lmin, lmax, ...) range abort
  let [cnts, delta] = [[0, 0, 0], '']
  let verbose = a:0 > 1 ? a:2 : 0
  let single = a:0 > 0 ? a:1 : 0
  let line1 = a:lmin < 0 ? a:firstline : a:lmin ? a:lmin : 1
  let line2 = a:lmax < 0 ? a:lastline : a:lmax ? a:lmax : line('$')
  let idxs = single ? [0, 0, 0] : [0, 1, 2]  " single delta
  let signs = single ? ['~'] : ['+', '~', '-']
  let hunks = &l:diff ? [] : gitgutter#hunk#hunks(bufnr())
  for [hunk0, count0, hunk1, count1] in hunks
    let hunk2 = count1 ? hunk1 + count1 - 1 : hunk1
    let [clip1, clip2] = [max([hunk1, line1]), min([hunk2, line2])]
    if clip2 < clip1 | continue | endif
    let offset = (hunk2 - clip2) + (clip1 - hunk1)  " count change
    let cnt0 = max([count0 - offset, 0])
    let cnt1 = max([count1 - offset, 0])
    let cnts[idxs[0]] += max([cnt1 - cnt0, 0])  " added
    let cnts[idxs[1]] += min([cnt0, cnt1])  " modified
    let cnts[idxs[2]] += max([cnt0 - cnt1, 0])  " removed
  endfor
  for idx in range(len(cnts))
    if !cnts[idx] | continue | endif
    let delta .= signs[idx] . cnts[idx]
  endfor
  if verbose
    let range = a:lmin || a:lmax ? ' (lines ' . line1 . ' to ' . line2 . ')' : ''
    echom 'Hunks: ' . delta . range
  endif
  return delta
endfunction
" For <expr> map accepting motion
function! git#hunk_stats_expr(...) abort
  let args = [-1, -1, a:0 ? a:1 : 0, 1]
  return utils#motion_func('git#hunk_stats', args, 1)
endfunction

" Git gutter staging and unstaging over input lines
" Note: Currently GitGutterStageHunk only supports partial staging of additions
" specified by visual selection, not different hunks. This supports both, iterates in
" reverse in case lines change. See: https://github.com/airblade/vim-gitgutter/issues/279
" Note: Created below by studying s:process_hunk() and gitgutter#diff#process_hunks().
" in autoload/gitgutter/diff.vim. Addition-only hunks have from_count '0' and to_count
" non-zero since no text was present before the change. Also note gitgutter#hunk#stage()
" requires cursor inside lines and fails when specifying lines outside of addition hunk
" (see s:hunk_op) so explicitly navigate lines below before calling stage commands.
function! git#hunk_stage(stage) abort range
  let action = a:stage ? 'Stage' : 'Undo'
  let cmd = 'GitGutter' . action . 'Hunk'
  call s:hunk_process()
  let hunks = gitgutter#hunk#hunks(bufnr(''))
  let ranges = []  " ranges staged
  let [range1, range2] = sort([a:firstline, a:lastline], 'n')
  for [line0, count0, line1, count1] in hunks
    let line2 = count1 ? line1 + count1 - 1 : line1  " to closing line
    if range1 <= line1 && range2 >= line2
      let range = []  " selection encapsulates hunk
    elseif range1 >= line1 && range2 <= line2
      let range = count0 ? [] : [range1, range2]
    elseif range1 <= line2 && range2 >= line2  " starts inside goes outside
      let range = count0 ? [] : [range1, line2]
    elseif range1 <= line1 && range2 >= line1  " starts outside goes inside
      let range = count0 ? [] : [line1, range2]
    else  " no update needed
      continue
    endif
    let winview = winsaveview()
    exe line1 | exe join(range, ',') . cmd
    call winrestview(winview)
    let range = empty(range) ? [line1, line2] : range
    call add(ranges, join(uniq(range), '-'))
  endfor
  if !empty(ranges)
    call s:hunk_process() | redraw
    echom action . ' hunks: ' . join(ranges, ', ')
  endif
endfunction
" For <expr> map accepting motion
function! git#hunk_stage_expr(...) abort
  return utils#motion_func('git#hunk_stage', a:000)
endfunction
