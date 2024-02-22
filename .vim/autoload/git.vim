"-----------------------------------------------------------------------------"
" Utilities for fugitive windows
"-----------------------------------------------------------------------------"
" Set up fugitive commands
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
    \ G call git#run_command(1, <line1>, <count>, +'<range>', <bang>0, '<mods>', <q-args>)
  command! -buffer
    \ -bar -bang -nargs=? -range=-1 -complete=customlist,fugitive#Complete
    \ Git call git#run_command(1, <line1>, <count>, +"<range>", <bang>0, "<mods>", <q-args>)
  command! -buffer
    \ -bar -bang -range=-1 -nargs=* -complete=customlist,fugitive#EditComplete
    \ Gtabedit exe fugitive#Open(<q-args> =~# '^+' ? 'edit' : 'Drop', <bang>0, '<mods>', <q-args>)
  command! -buffer -nargs=* Gsplit Gvsplit <args>
  command! -buffer -nargs=* -bang Gdrop Gtabedit <args>
  command! -buffer -nargs=* -bang GDrop Gtabedit <args>
  command! -buffer -nargs=* -bang Gdiffsplit Git diff <args>
endfunction

" Git command with message
" Note: Fugitive does not currently use &previewwindow and does not respect <mods>
" so set window explicitly below. See: https://stackoverflow.com/a/8356605/4970632
let s:flags1 = '--graph --abbrev-commit --max-count=50'
let s:flags2 = '--date=relative --branches --decorate'
let s:git_user = ['merge', 'commit', 'oops']
let s:git_tree = ['log', 'tree', 'trunk']
let s:git_wide = ['', 'status', 'show', 'diff'] + s:git_user
let s:git_quiet = ['add', 'stage', 'reset', 'push', 'pull', 'fetch', 'switch', 'restore', 'checkout']
let s:git_aliases = {
  \ 'status': '',
  \ 'blame': 'blame --show-email',
  \ 'show': 'show --abbrev-commit',
  \ 'log': 'log ' . s:flags1,
  \ 'tree': 'log --stat ' . s:flags1 . ' ' . s:flags2,
  \ 'trunk': 'log --name-status ' . s:flags1 . ' ' . s:flags2,
\ }
function! s:echo_git(args, empty, ...) abort
  if !a:empty
    echom 'Git ' . a:args
  else  " empty message
    echohl WarningMsg
    echom "Warning: 'Git " . a:args . "' was empty"
    echohl None
  endif
endfunction
function! git#run_command(echo, line1, count, range, bang, mods, args, ...) abort range
  " Parse input arguments
  if empty(FugitiveGitDir())
    let args = [a:line1, a:count, a:range, a:bang, a:mods, ''] + a:000
    let cmd = "call('fugitive#Command', " . string(args) . ')'
    call feedkeys("\<Cmd>exe " . cmd . "\<CR>", 'n') | return
  endif
  let [bnum, width, height] = [bufnr(), winwidth(0), winheight(0)]
  let [name; flags] = empty(trim(a:args)) ? [''] : split(a:args, '\\\@<!\s\+')
  let quiet = index(s:git_quiet, name) != -1  " commands print at most one line
  let user = index(s:git_user, name) != -1  " commands require user interaction
  let wide = index(s:git_wide, name) != -1  " popup window should have 'main' size
  let tree = index(s:git_tree, name) != -1  " popup window should be vertical
  let name = get(s:git_aliases, name, name)  " e.g. '' for 'status'
  let mods = tree && empty(a:mods) ? 'topleft vert' : a:mods
  " Generate and run command
  let opts = name . (empty(flags) ? '' : ' ' . join(flags, ' '))
  let opts = substitute(opts, '--color\>', '', 'g')  " fugitive uses its own colors
  let opts = [a:line1, a:count, a:range, a:bang, mods, opts] + a:000
  silent let cmd = call('fugitive#Command', opts)
  if !user && bnum == bufnr() && cmd !~# '\<v\?split\>'
    echo 'Git ' . a:args . (quiet ? ' ' : "\n") | exe cmd
  else
    silent exe cmd | let empty = line('$') <= 1
    if !user
      setlocal bufhidden=delete | if empty | call window#close_pane(1) | endif
    endif
    if a:echo  " ensure message shows
      call timer_start(500, function('s:echo_git', [a:args, empty]))
    endif
  endif
  " Configure resulting window
  if bnum == bufnr()  " pane not opened
    exe 'vertical resize ' . width | exe 'resize ' . height
  elseif a:args =~# '^blame\( %\)\@!' || cmd =~# '\<\(vsplit\|vert\(ical\)\?\)\>'
    exe 'vertical resize ' . window#default_width(tree ? 0.5 : !wide)
  else  " bottom pane
    exe 'resize ' . window#default_height(tree ? 0.5 : !wide)
  endif
  if !a:range && a:args =~# '^blame'  " syncbind is no-op if not vertical
    exe a:line1 | exe 'normal! z.' | call feedkeys("\<Cmd>syncbind\<CR>", 'n')
  endif
  " if a:args =~# '\s\+%' && bnum != bufnr()  " open single difference fold
  "   call feedkeys('zv', 'n')
  " endif
  if empty(name) && bnum != bufnr()  " open change statistics
    global/^\(Staged\|Unstaged\)\>/normal =zxgg
  endif
endfunction
" For special range handling
function! git#run_map(range, ...) abort range
  if a:range && a:firstline == a:lastline
    let offset = 5 | let [line1, line2] = [a:firstline - offset, a:lastline + offset]
  else
    let offset = 0 | let [line1, line2] = sort([a:firstline, a:lastline], 'n')
  endif
  if a:range || line1 != line2
    call call('git#run_command', [1, line1, line2, a:range] + a:000)
  else
    call call('git#run_command', [1, line1, -1, a:range] + a:000)
  endif
  call feedkeys(offset ? abs(offset) . (offset > 0 ? 'j' : 'k') : '', 'n')
endfunction
" For <expr> map accepting motion
function! git#run_map_expr(...) abort
  return utils#motion_func('git#run_map', a:000)
endfunction

" Git blame and commit setup
" Note: Git commit is asynchronous unlike others so resize must be reapplied here. In
" general do not apply resize to setup functions since could be panel or full-screen.
" Note: This prevents annoying <press enter to continue> message showing up when
" committing with no staged changes, issues a warning instead of showing the message.
function! git#blame_setup() abort
  let regex = '^\x\{8}\s\+\d\+\s\+(\zs<\S\+>\s\+'
  call matchadd('Conceal', regex, 0, -1, {'conceal': ''})
  if window#count_panes('h') == 1
    call feedkeys("\<Cmd>vertical resize " . window#default_width(1) . "\<CR>", 'n')
  endif
endfunction
function! git#commit_setup(...) abort
  exe 'resize ' . window#default_height()
  call switch#autosave(1, 1)  " suppress message
  setlocal colorcolumn=73
  goto | startinsert  " first row column
endfunction
function! git#commit_safe() abort
  let args = ['diff', '--staged', '--quiet']
  let result = FugitiveExecute(args)  " see: https://stackoverflow.com/a/1587877/4970632
  let status = get(result, 'exit_status', 1)
  if status == 0  " exits 0 if there are no staged changes
    echohl WarningMsg
    echom 'Error: No staged changes'
    echohl None
    call git#run_command(0, line('.'), -1, 0, 0, '', 'status')
  else  " exits 1 if there are staged changes
    call git#run_command(1, line('.'), -1, 0, 0, '', 'commit')
  endif
endfunction

" Fugitive popup setup
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
  \ ['[c', '(', 'nox'],
  \ [']c', ')', 'nox'],
  \ ['[m', '{', 'nox'],
  \ [']m', '}', 'nox'],
  \ ['=', ',', 'nx'],
  \ ['-', '.', 'nx'],
  \ ['.', ';', 'n'],
\ ]
function! git#fugitive_setup() abort
  if &filetype ==# 'fugitiveblame'
    call git#blame_setup()
  endif
  for val in s:fugitive_remove
    silent! exe 'unmap <buffer> ' . val
  endfor
  setlocal foldmethod=syntax
  call fold#update_folds()
  call fold#set_defaults()
  call call('utils#switch_maps', s:fugitive_switch)
endfunction
function! git#fugitive_return() abort
  if get(b:, 'fugitive_type', '') ==# 'blob'
    let winview = winsaveview()
    exe 'Gedit %'
    call winrestview(winview)
  else
    echohl ErrorMsg
    echom 'Error: Not in fugitive blob'
    echohl None
  endif
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
function! git#hunk_show() abort
  call s:hunk_process()
  GitGutterPreviewHunk | silent wincmd j
  call timer_start(10, function('execute', ["echom 'Hunk difference'"]))
endfunction
function! git#hunk_jump(forward, stage) abort
  call s:hunk_process()
  exe v:count1 . 'GitGutter' . (a:forward ? 'Next' : 'Prev') . 'Hunk'
  exe a:stage ? 'GitGutterStageHunk' : ''
endfunction

" Git gutter staging and unstaging
" Note: Currently GitGutterStageHunk only supports partial staging of additions
" specified by visual selection, not different hunks. This supports both, iterates in
" reverse in case lines change. See: https://github.com/airblade/vim-gitgutter/issues/279
" Note: Created below by studying s:process_hunk() and gitgutter#diff#process_hunks()
" in autoload/gitgutter/diff.vim. Hunks are stored in g:gitgutter['hunks'] list of
" 4-item [from_start, from_count, to_start, to_count] lists i.e. the starting line and
" counts before and after changes. Addition-only hunks have from_count '0' and to_count
" non-zero since no text was present before the change. Also note gitgutter#hunk#stage()
" requires cursor inside lines and fails when specifying lines outside of addition hunk
" (see s:hunk_op) so explicitly navigate lines below before calling stage commands.
function! git#hunk_action(stage) abort range
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
    call s:hunk_process()
    echom action . ' hunks: ' . join(ranges, ', ')
  endif
endfunction
" For <expr> map accepting motion
function! git#hunk_action_expr(...) abort
  return utils#motion_func('git#hunk_action', a:000)
endfunction

" Tables of fugitive mappings
" See: :help fugitive-maps
" -----------
" Global maps
" -----------
" <C-R><C-G>  On the command line, recall the path to the current |fugitive-object|
" ["x]y<C-G>  Yank the path to the current |fugitive-object|
" .     Start a |:| command line with the file under the cursor prepopulated.
" gq    Close the status buffer.
" g?    Show help for |fugitive-maps|.
" ----------
" Blame maps
" ----------
" g?    Show this help.
" A     Resize to end of author column.
" C     Resize to end of commit column.
" D     Resize to end of date/time column.
" gq    Close blame, then |:Gedit| to return to work tree version.
" <CR>  Close blame, and jump to patch that added line (or to blob for boundary commit).
" o     Jump to patch or blob in horizontal split.
" O     Jump to patch or blob in new tab.
" p     Jump to patch or blob in preview window.
" -     Reblame at commit.
" ----------------------
" Staging/unstaging maps
" ----------------------
" s     Stage (add) the file or hunk under the cursor.
" u     Unstage (reset) the file or hunk under the cursor.
" -     Stage or unstage the file or hunk under the cursor.
" U     Unstage everything.
" X     Discard the change under the cursor. This uses `checkout` or `clean` under
"       the hood. A command is echoed that shows how to undo the change.  Consult
"       `:messages` to see it again.  During a merge conflict, use 2X to call
"       `checkout --ours` or 3X to call `checkout --theirs` .
" =     Toggle an inline diff of the file under the cursor.
" >     Insert an inline diff of the file under the cursor.
" <     Remove the inline diff of the file under the cursor.
" gI    Open .git/info/exclude in a split and add the file under the cursor.  Use a
"       count to open .gitignore.
" I|P   Invoke |:Git| add --patch or reset --patch on the file under the cursor. On
"       untracked files, this instead calls |:Git| add --intent-to-add.
" dp    Invoke |:Git| diff on the file under the cursor. Deprecated in favor of inline diffs.
" dd    Perform a |:Gdiffsplit| on the file under the cursor.
" dv    Perform a |:Gvdiffsplit| on the file under the cursor.
" ds|dh Perform a |:Ghdiffsplit| on the file under the cursor.
" dq    Close all but one diff buffer, and |:diffoff|! the last one.
" d   ? Show this help.
" ---------------
" Navigation maps
" ---------------
" <CR>  Open the file or |fugitive-object| under the cursor. In a blob, this and
"       similar maps jump to the patch from the diff where this was added, or where
"       it was removed if a count was given.  If the line is still in the work tree
"       version, passing a count takes you to it.
" o     Open the file or |fugitive-object| under the cursor in a new split.
" gO    Open the file or |fugitive-object| under the cursor in a new vertical split.
" O     Open the file or |fugitive-object| under the cursor in a new tab.
" p     Open the file or |fugitive-object| under the cursor in a preview window. In
"       the status buffer, 1p is required to bypass the legacy usage instructions.
" ~     Open the current file in the [count]th first ancestor.
" P     Open the current file in the [count]th parent.
" C     Open the commit containing the current file.
" (     Jump to the previous file, hunk, or revision.
" )     Jump to the next file, hunk, or revision.
" [c    Jump to previous hunk, expanding inline diffs automatically.  (This shadows
"       the Vim built-in |[c| that provides a similar operation in |diff| mode.)
" ]c    Jump to next hunk, expanding inline diffs automatically.  (This shadows
"       the Vim built-in |]c| that provides a similar operation in |diff| mode.)
" [/|[m Jump to previous file, collapsing inline diffs automatically.  (Mnemonic:
"       '/' appears in filenames, 'm' appears in 'filenames'.)
" ]/|]m Jump to next file, collapsing inline diffs automatically.  (Mnemonic: '/'
"       appears in filenames, 'm' appears in 'filenames'.)
" i     Jump to the next file or hunk, expanding inline diffs automatically.
" [[    Jump [count] sections backward.
" ]]    Jump [count] sections forward.
" []    Jump [count] section ends backward.
" ][    Jump [count] section ends forward.
" *     On the first column of a + or - diff line, search for the corresponding -
"       or + line.  Otherwise, defer to built-in |star|.
" gU    Jump to file [count] in the 'Unstaged' section.
" gs    Jump to file [count] in the 'Staged' section.
" gp    Jump to file [count] in the 'Unpushed' section.
" gP    Jump to file [count] in the 'Unpulled' section.
" gr    Jump to file [count] in the 'Rebasing' section.
" gi    Open .git/info/exclude in a split. Use a count to open .gitignore.
" -----------
" Commit maps
" -----------
" cc        Create a commit.
" ca        Amend the last commit and edit the message.
" ce        Amend the last commit without editing the message.
" cw        Reword the last commit.
" cvc       Create a commit with -v.
" cva       Amend the last commit with -v
" cf        Create a `fixup!` commit for the commit under the cursor.
" cF        Create a `fixup!` commit for the commit under the cursor and immediately rebase it.
" cs        Create a `squash!` commit for the commit under the cursor.
" cS        Create a `squash!` commit for the commit under the cursor and immediately rebase it.
" cA        Create a `squash!` commit for the commit under the cursor and edit the message.
" c<Space>  Populate command line with ':Git commit '. *fugitive_cr*
" crc       Revert the commit under the cursor.
" crn       Revert the commit under the cursor in the index and work tree,
"           but do not actually commit the changes.
" cr<Space> Populate command line with ':Git revert '. *fugitive_cm*
" cm<Space> Populate command line with ':Git merge '.
" c?        Show this help.
" --------------------
" Checkout/branch maps
" --------------------
" coo       Check out the commit under the cursor.
" cb<Space> Populate command line with ':Git branch '.
" co<Space> Populate command line with ':Git checkout '.
" cb?       Show this help. co?
" Stash maps
" czz       Push stash. Pass a [count] of 1 to add `--include-untracked` or 2 to add `--all`.
" czw       Push stash of the work-tree. Like `czz` with `--keep-index`.
" czs       Push stash of the stage. Does not accept a count.
" czA       Apply topmost stash, or stash@{count}.
" cza       Apply topmost stash, or stash@{count}, preserving the index.
" czP       Pop topmost stash, or stash@{count}.
" czp       Pop topmost stash, or stash@{count}, preserving the index.
" cz<Space> Populate command line with ':Git stash '.
" cz?       Show this help.
" -----------
" Rebase maps
" -----------
" ri|u     Perform an interactive rebase. Uses ancestor of commit under cursor
"          as upstream if available.
" rf       Perform an autosquash rebase without editing the todo list.  Uses ancestor
"          of commit under cursor as upstream if available.
" ru       Perform an interactive rebase against @{upstream}.
" rp       Perform an interactive rebase against @{push}.
" rr       Continue the current rebase.
" rs       Skip the current commit and continue the current rebase.
" ra       Abort the current rebase.
" re       Edit the current rebase todo list.
" rw       Perform an interactive rebase with the commit under the cursor set to `reword`.
" rm       Perform an interactive rebase with the commit under the cursor set to `edit`.
" rd       Perform an interactive rebase with the commit under the cursor set to `drop`.
" r<Space> Populate command line with ':Git rebase '.
" r?       Show this help.
