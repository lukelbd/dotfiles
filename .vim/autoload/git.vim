"-----------------------------------------------------------------------------"
" Utilities for fugitive windows
"-----------------------------------------------------------------------------"
" Helper function and aliases
" Todo: Use bufhidden=delete more frequently, avoid tons of useless buffers
" Note: Here use 'Git' to open standard status pane and 'Git status' to open
" pane with diff hunks expanded with '=' and folded with 'zc'.
let s:git_tall = ['commits', 'log', 'tree', 'trunk']  " vertical commands
let s:git_editor = ['merge', 'commit', 'oops']  " commands open editor
let s:git_nobreak = ['add', 'stage', 'reset', 'push', 'pull', 'fetch', 'switch', 'restore', 'checkout']
let s:git_resize = {'show': 0, 'diff': 0, 'merge': 0, 'commit': 0, 'oops': 0, 'status': 0, '': 0.5}
let s:git_resize = extend(s:git_resize, {'commits': 0.5, 'log': 0.5, 'tree': 0.5, 'trunk': 0.5})
function! s:run_cmd(bnum, lnum, cmd, ...) abort
  let input = join(a:000, '')
  let name = split(input, '', 1)[0]
  let editor = index(s:git_editor, name) != -1
  let newbuf = editor || a:bnum != bufnr() || a:cmd =~# '\<v\?split\>'
  if a:cmd =~# '^echoerr'
    let msg = substitute(a:cmd, '^echoerr', 'echom', '')
    redraw | echohl ErrorMsg | exe msg | echohl None
  elseif !newbuf  " no panel generated
    let space = index(s:git_nobreak, name) == -1 ? "\n" : ' '
    redraw | echo 'Git ' . input . space | exe a:cmd
  else  " panel generated
    let [width, height] = [winwidth(0), winheight(0)]
    let resize = get(s:git_resize, name, 1)
    silent exe a:cmd
    if a:bnum != bufnr()
      setlocal bufhidden=delete | if line('$') <= 1 | call window#close_pane(1) | endif
    endif
    if a:bnum != bufnr() && input =~# '^blame'  " syncbind is no-op if not vertical
      exe a:lnum | exe 'normal! z.' | call feedkeys("\<Cmd>syncbind\<CR>", 'n')
    elseif a:bnum != bufnr() && input =~# '\s\+%'  " open single difference fold
      call feedkeys('zv', 'n')
    elseif a:bnum != bufnr() && name ==# 'status'  " open change statistics
      silent global/^\(Staged\|Unstaged\)\>/normal =zxgg
    endif
    if a:bnum == bufnr()
      exe 'vertical resize ' . width | exe 'resize ' . height | return
    elseif input =~# '^blame\( %\)\@!' || a:cmd =~# '\<\(vsplit\|vert\(ical\)\?\)\>'
      exe 'vertical resize ' . window#default_width(resize)
    else  " bottom panel
      exe 'resize ' . window#default_height(resize)
    endif
  endif
  return newbuf && a:cmd !~# '^echoerr'  " whether echo required
endfunction

" Override fugitive commands
" Note: Native fugitive command is declared with :command! Git -nargs=? -range=-1
" fugitive#Command(<line1>, <count>, +'<range>', <bang>0, '<mods>', <q-args>)
" where <line1> is cursor line, <count> is -1 if no range supplied and <line2>
" if any range supplied (see :help command-range), and confusingly <range> is the
" number of range arguments supplied (i.e. 0 for :Git, 1 for e.g. :10Git, and
" 2 for e.g. :10,20Git) where +'<range>' forces this to integer. Here, use simpler
" implicit distinction between calls with/without range where we simply test the
" equality of <line1> and <line2>, or allow a force-range a:range argument.
function! git#command_setup() abort
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

" Run fugitive command or mapping
" Note: Fugitive does not currently use &previewwindow and does not respect <mods>
" so set window explicitly below. See: https://stackoverflow.com/a/8356605/4970632
let s:git_trim = '--graph --abbrev-commit --max-count=50'
let s:git_format = '--date=relative --branches --decorate'
let s:git_translate = {'status': '',
  \ 'log': 'log ' . s:git_trim,
  \ 'tree': 'log --stat ' . s:git_trim . ' ' . s:git_format,
  \ 'trunk': 'log --name-status ' . s:git_trim . ' ' . s:git_format,
  \ 'show': 'show --abbrev-commit',
  \ 'blame': 'blame --show-email',
  \ 'commits': 'log --graph --oneline ' . s:git_format,
\ }
function! git#run_command(msg, line1, count, range, bang, mods, cmd, ...) abort range
  let [bnum, lnum] = [bufnr(), line('.')]
  let icmd = empty(FugitiveGitDir()) ? '' : a:cmd
  let [name; flags] = split(icmd, '\\\@<!\s\+', 1)
  let icmd = get(s:git_translate, name, name) . ' ' . join(flags, ' ')
  let imod = empty(a:mods) ? index(s:git_tall, name) > 0 ? 'vert botright' : 'botright' : a:mods
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
function! git#safe_commit(editor, ...) abort
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

" Git panel window setup
" Note: Fugitive maps get re-applied when re-opening existing fugitive buffers due to
" its FileType autocommands, so should not have issues modifying already-modified maps.
" Note: Many mappings call script-local functions with strings like 'tabedit', and
" initially tried replacing with 'Drop', but turns out these all call fugitive
" internal commands like :Gtabedit and :Gedit (and there is no :Gdrop). So now
" overwrite :Gtabedit in .vimrc. Also considered replacing 'tabedit' with 'drop' in
" maps and having fugitive use :Gdrop, but was getting error where after tab switch
" an empty panel was opened in the git window. Might want to revisit.
" let rhs = substitute(rhs, '\C\<tabe\a*', 'drop', 'g')  " use :Git drop?
let s:fugitive_remove = ['dq', '<<', '>>', '==', '<F1>', '<F2>']
let s:fugitive_switch = [
  \ ['<CR>', 'O', 'n'],
  \ ['O', '<2-LeftMouse>', 'n'],
  \ ['O', '<CR>', 'n'],
  \ ['(', '[', 'nx', {'nowait': 1}],
  \ [')', ']', 'nx', {'nowait': 1}],
  \ ['[c', '{', 'nox'],
  \ [']c', '}', 'nox'],
  \ ['[m', '(', 'nox'],
  \ [']m', ')', 'nox'],
  \ ['=', ',', 'nx'],
  \ ['-', '.', 'nx'],
  \ ['.', ';', 'n'],
\ ]
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
function! git#setup_fugitive() abort
  for val in s:fugitive_remove | silent! exe 'unmap <buffer> ' . val | endfor
  setlocal foldmethod=syntax
  call fold#update_folds(0, 0)
  call call('utils#switch_maps', s:fugitive_switch)
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
