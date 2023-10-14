"-----------------------------------------------------------------------------"
" Utilities for fugitive windows
"-----------------------------------------------------------------------------"
" Todo: Memorize these mappings and possibly modify some.
" :help fugitive-maps
" Blame maps
" g?    Show this help.
" A     Resize to end of author column.
" C     Resize to end of commit column.
" D     Resize to end of date/time column.
" gq    Close blame, then |:Gedit| to return to work tree version.
" <CR>  Close blame, and jump to patch that added line (or directly to blob for boundary commit).
" o     Jump to patch or blob in horizontal split.
" O     Jump to patch or blob in new tab.
" p     Jump to patch or blob in preview window.
" -     Reblame at commit.
" Staging/unstaging maps
" s     Stage (add) the file or hunk under the cursor.
" u     Unstage (reset) the file or hunk under the cursor.
" -     Stage or unstage the file or hunk under the cursor.
" U     Unstage everything.
" X     Discard the change under the cursor. This uses `checkout` or `clean` under the hood.  A command is echoed that shows how to undo the change.  Consult `:messages` to see it again.  During a merge conflict, use 2X to call `checkout --ours` or 3X to call `checkout --theirs` .
" =     Toggle an inline diff of the file under the cursor.
" >     Insert an inline diff of the file under the cursor.
" <     Remove the inline diff of the file under the cursor.
" gI    Open .git/info/exclude in a split and add the file under the cursor.  Use a count to open .gitignore.
" I|P   Invoke |:Git| add --patch or reset --patch on the file under the cursor. On untracked files, this instead calls |:Git| add --intent-to-add.
" Diff maps
" dp    Invoke |:Git| diff on the file under the cursor. Deprecated in favor of inline diffs.
" dd    Perform a |:Gdiffsplit| on the file under the cursor.
" dv    Perform a |:Gvdiffsplit| on the file under the cursor.
" ds|dh Perform a |:Ghdiffsplit| on the file under the cursor.
" dq    Close all but one diff buffer, and |:diffoff|! the last one.
" d   ? Show this help.
" Navigation maps
" <CR>  Open the file or |fugitive-object| under the cursor. In a blob, this and similar maps jump to the patch from the diff where this was added, or where it was removed if a count was given.  If the line is still in the work tree version, passing a count takes you to it.
" o     Open the file or |fugitive-object| under the cursor in a new split.
" gO    Open the file or |fugitive-object| under the cursor in a new vertical split.
" O     Open the file or |fugitive-object| under the cursor in a new tab.
" p     Open the file or |fugitive-object| under the cursor in a preview window.  In the status buffer, 1p is required to bypass the legacy usage instructions.
" ~     Open the current file in the [count]th first ancestor.
" P     Open the current file in the [count]th parent.
" C     Open the commit containing the current file.
" (     Jump to the previous file, hunk, or revision.
" )     Jump to the next file, hunk, or revision.
" [c    Jump to previous hunk, expanding inline diffs automatically.  (This shadows the Vim built-in |[c| that provides a similar operation in |diff| mode.)
" ]c    Jump to next hunk, expanding inline diffs automatically.  (This shadows the Vim built-in |]c| that provides a similar operation in |diff| mode.)
" [/|[m Jump to previous file, collapsing inline diffs automatically.  (Mnemonic: "/" appears in filenames, m" appears in "filenames".)
" ]/|]m Jump to next file, collapsing inline diffs automatically.  (Mnemonic: "/" appears in filenames, m" appears in "filenames".)
" i     Jump to the next file or hunk, expanding inline diffs automatically.
" [[    Jump [count] sections backward.
" ]]    Jump [count] sections forward.
" []    Jump [count] section ends backward.
" ][    Jump [count] section ends forward.
" *     On the first column of a + or - diff line, search for the corresponding - or + line.  Otherwise, defer to built-in |star|.
" gU    Jump to file [count] in the "Unstaged" section.
" gs    Jump to file [count] in the "Staged" section.
" gp    Jump to file [count] in the "Unpushed" section.
" gP    Jump to file [count] in the "Unpulled" section.
" gr    Jump to file [count] in the "Rebasing" section.
" gi    Open .git/info/exclude in a split. Use a count to open .gitignore.
" Commit maps
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
" c<Space>  Populate command line with ":Git commit ". *fugitive_cr*
" crc       Revert the commit under the cursor.
" crn       Revert the commit under the cursor in the index and work tree, but do not actually commit the changes.
" cr<Space> Populate command line with ":Git revert ". *fugitive_cm*
" cm<Space> Populate command line with ":Git merge ".
" c?        Show this help.
" Checkout/branch maps
" coo       Check out the commit under the cursor.
" cb<Space> Populate command line with ":Git branch ".
" co<Space> Populate command line with ":Git checkout ".
" cb?       Show this help. co?
" Stash maps
" czz       Push stash. Pass a [count] of 1 to add `--include-untracked` or 2 to add `--all`.
" czw       Push stash of the work-tree. Like `czz` with `--keep-index`.
" czs       Push stash of the stage. Does not accept a count.
" czA       Apply topmost stash, or stash@{count}.
" cza       Apply topmost stash, or stash@{count}, preserving the index.
" czP       Pop topmost stash, or stash@{count}.
" czp       Pop topmost stash, or stash@{count}, preserving the index.
" cz<Space> Populate command line with ":Git stash ".
" cz?       Show this help.
" Rebase maps
" ri|u     Perform an interactive rebase. Uses ancestor of commit under cursor as upstream if available.
" rf       Perform an autosquash rebase without editing the todo list.  Uses ancestor of commit under cursor as upstream if available.
" ru       Perform an interactive rebase against @{upstream}.
" rp       Perform an interactive rebase against @{push}.
" rr       Continue the current rebase.
" rs       Skip the current commit and continue the current rebase.
" ra       Abort the current rebase.
" re       Edit the current rebase todo list.
" rw       Perform an interactive rebase with the commit under the cursor set to `reword`.
" rm       Perform an interactive rebase with the commit under the cursor set to `edit`.
" rd       Perform an interactive rebase with the commit under the cursor set to `drop`.
" r<Space> Populate command line with ":Git rebase ".
" r?       Show this help.
" Miscellaneous maps
" gq    Close the status buffer.
" .     Start a |:| command line with the file under the cursor prepopulated.
" g?    Show help for |fugitive-maps|.
" Global maps
" <C-R><C-G>    On the command line, recall the path to the current |fugitive-object| (that is, a representation of the object recognized by |:Gedit|).
" ["x]y<C-G>    Yank the path to the current |fugitive-object|.

" Helper function
" Note: Vim help recommends capturing full map settings using maparg(lhs, 'n', 0, 1)
" then re-adding them using mapset(). This is a little easier than working with strings
" returned by maparg(lhs, 'n'), for which we have to use escape(map, '"<') then
" evaluate the resulting string with eval('"' . map . '"'). However in the dictionary
" case, the 'rhs' entry uses <sid> instead of <snr>nr, and when calling mapset(), the
" *current script* id is used rather than the id in the dict. Have to fix this manually.
function! s:eval_map(map) abort
  let rhs = get(a:map, 'rhs', '')
  let sid = get(a:map, 'sid', '')  " see above
  let snr = '<snr>' . sid . '_'
  let rhs = substitute(rhs, '\c<sid>', snr, 'g')
  return rhs
endfunction

" Git command with message
" Note: Fugitive does not currently use &previewwindow and does not respect <mods>
" so set window explicitly below. See: https://stackoverflow.com/a/8356605/4970632
" Note: Previously used <Leader>b for toggle but now use lower and upper
" case for blaming either range or entire file and 'zbb' for current line.
function! git#run_command(cmd, ...) abort range
  let [firstline, lastline] = sort([a:firstline, a:lastline])
  let forcerange = a:0 ? a:1 : 0
  let range = forcerange || a:firstline != a:lastline ? firstline . ',' . lastline : ''
  echom range . 'Git ' . a:cmd
  let cmd = a:cmd =~# '^status' ? '' : a:cmd
  let mods = cmd =~# '^diff' ? 'silent ' : ''
  exe mods . range . 'Git ' . cmd
  exe &previewheight . 'wincmd'
endfunction
" For <expr> map accepting motion
function! git#run_command_expr(...) abort
  return utils#motion_func('git#run_command', a:000)
endfunction

" Git commit setup
" Note: This prevents annoying <press enter to continue> message showing up when
" committing with no staged changes, issues a warning instead of showing the message.
function! git#commit_setup(...) abort
  goto
  let &l:colorcolumn = 73
  call switch#autosave(1, 1)  " suppress message
  startinsert
endfunction
function! git#commit_run() abort
  let output = system('git diff --staged --quiet')  " see: https://stackoverflow.com/a/1587877/4970632
  if v:shell_error  " unseccessful status if has uncommitted staged changes
    echom 'Git commit'
    Git commit
  else  " successful status if has no uncommitted staged changes
    echohl WarningMsg
    echom 'Warning: No staged changes found. Unable to begin commit.'
    echohl None
    Git
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
function! git#fugitive_setup() abort
  let alt = maparg('<CR>', 'n', 0, 1)  " used throughout fugitive
  let main = maparg('O', 'n', 0, 1)  " used throughout fugitive
  let click = copy(main)
  let rhs = s:eval_map(main)
  call extend(alt, {'lhs': 'O', 'lhsraw': 'O'})
  call extend(main, {'rhs': rhs, 'lhs': '<CR>', 'lhsraw': "\<CR>"})
  call extend(click, {'rhs': rhs, 'lhs': '<2-LeftMouse>', 'lhsraw': "\<2-LeftMouse>"})
  call mapset('n', 0, alt)
  call mapset('n', 0, main)
  call mapset('n', 0, click)
endfunction

" Git gutter jumping and previewing
" Note: These ensure git gutter is turned on at start. In general want to
" keep off since it is really intensive especially for larger projects.
function! git#hunk_preview() abort
  call switch#gitgutter(1, 1)  " ensure enabled, suppress message
  GitGutter
  GitGutterPreviewHunk
  wincmd j
endfunction
function! git#hunk_jump(forward, stage) abort
  call switch#gitgutter(1, 1)  " ensure enabled, suppress message
  let which = a:forward ? 'Next' : 'Prev'
  let cmd = 'GitGutter' . which . 'Hunk'  " natively expands folds
  exe v:count1 . cmd
  if a:stage | exe 'GitGutterStageHunk' | endif
endfunction

" Git gutter staging and unstaging
" Note: Currently GitGutterStageHunk only supports partial staging of additions
" specified by visual selection, not different hunks. This supports both, iterates in
" reverse in case lines change. See: https://github.com/airblade/vim-gitgutter/issues/279
" Note: This was designed by looking at hunk.vim. Seems all buffer local gitgutter
" settings are stores in g:gitgutter dictionary with 'hunks' containing lists of
" [id, type, line, nline] where type == 0 is for addition-only hunks. Seems that
" gitgutter#hunk#stage() requires cursor inside lines and fails when specifying lines
" outside of addition hunk (see s:hunk_op) so explicitly navigate lines below.
function! git#hunk_action(stage) abort range
  call switch#gitgutter(1, 1)  " ensure enabled, suppress message
  let cmd = 'GitGutter' . (a:stage ? 'Stage' : 'Undo') . 'Hunk'
  let hunks = get(get(b:, 'gitgutter', {}), 'hunks', [])
  let [firstline, lastline] = sort([a:firstline, a:lastline])
  for [id, htype, line1, lcount] in hunks
    let line2 = lcount == 0 ? line1 : line1 + lcount - 1
    if firstline <= line1 && lastline >= line2  " range encapsulates hunk
      let range = ''
    elseif firstline <= line1 && line1 <= lastline  " starts inside, ends outside
      let range = htype == 0 ? line1 . ',' . lastline : ''
    elseif firstline <= line2 && line2 <= lastline  " starts outside, ends inside
      let range = htype == 0 ? firstline . ',' . line2 : ''
    else
      continue
    endif
    exe line1
    exe range . cmd
  endfor
  GitGutter  " update signs (sometimes they lag)
endfunction
" For <expr> map accepting motion
function! git#hunk_action_expr(...) abort
  return utils#motion_func('git#hunk_action', a:000)
endfunction
