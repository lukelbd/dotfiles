"-----------------------------------------------------------------------------"
" Utilities for fugitive windows
"-----------------------------------------------------------------------------"
" Todo: Memorize these mappings and possibly modify some.
" Blame help
" g?    show this help
" A     resize to end of author column
" C     resize to end of commit column
" D     resize to end of date/time column
" gq    close blame, then |:Gedit| to return to work tree
" <CR>  close blame, and jump to patch that added line
" o     jump to patch or blob in horizontal split
" O     jump to patch or blob in new tab
" p     jump to patch or blob in preview window
" -     reblame at commit
" Staging/unstaging
" s     Stage (add) the file or hunk under the cursor.
" u     Unstage (reset) the file or hunk under the cursor.
" -     Stage or unstage the file or hunk under the cursor.
" U     Unstage everything.
" X     Discard the change under the cursor.
" =     Toggle an inline diff of the file under the cursor.
" >     Insert an inline diff of the file under the cursor.
" <     Remove the inline diff of the file under the cursor.
" gI    Open .git/info/exclude in a split and add the file
" I|P   Invoke |:Git| add --patch or reset --patch on the file
" Diff maps
" dp    Invoke |:Git| diff on the file under the cursor.
" dd    Perform a |:Gdiffsplit| on the file under the cursor.
" dv    Perform a |:Gvdiffsplit| on the file under the cursor.
" ds|dh Perform a |:Ghdiffsplit| on the file under the cursor.
" dq    Close all but one diff buffer, and |:diffoff|! the last one.
" d?    Show this help.
" Navigation maps ~
" <CR>  Open the file or |fugitive-object| under the cursor.
" o     Open the file or |fugitive-object| under the cursor in
" gO    Open the file or |fugitive-object| under the cursor in
" O     Open the file or |fugitive-object| under the cursor in
" p     Open the file or |fugitive-object| under the cursor in
" ~     Open the current file in the [count]th first ancestor.
" P     Open the current file in the [count]th parent.
" C     Open the commit containing the current file.
" (     Jump to the previous file, hunk, or revision.
" )     Jump to the next file, hunk, or revision.
" [c    Jump to previous hunk, expanding inline diffs
" ]c    Jump to next hunk, expanding inline diffs
" [/|[m Jump to previous file, collapsing inline diffs
" ]/|]m Jump to next file, collapsing inline diffs
" i     Jump to the next file or hunk, expanding inline diffs
" [[    Jump [count] sections backward.
" ]]    Jump [count] sections forward.
" []    Jump [count] section ends backward.
" ][    Jump [count] section ends forward.
" *     On the first column of a + or - diff line, search.
" #     Same as "*", but search backward.
" gu    Jump to file [count] in the "Untracked" or "Unstaged"
" gU    Jump to file [count] in the "Unstaged" section.
" gs    Jump to file [count] in the "Staged" section.
" gp    Jump to file [count] in the "Unpushed" section.
" gP    Jump to file [count] in the "Unpulled" section.
" gr    Jump to file [count] in the "Rebasing" section.
" gi    Open .git/info/exclude in a split.  Use a count to
" Commit maps ~
" cc    Create a commit.
" ca    Amend the last commit and edit the message.
" ce    Amend the last commit without editing the message.
" cw    Reword the last commit.
" cvc   Create a commit with -v.
" cva   Amend the last commit with -v
" cf    Create a `fixup!` commit for the commit under the
" cF    Create a `fixup!` commit for the commit under the
" cs    Create a `squash!` commit for the commit under the
" cS    Create a `squash!` commit for the commit under the
" cA    Create a `squash!` commit for the commit under the
" c<Space>  Populate command line with ":Git commit ".
" crc   Revert the commit under the cursor.
" crn   Revert the commit under the cursor in the index and
" cr<Spa>   Populate command line with ":Git revert ".
" cm<Spa>   Populate command line with ":Git merge ".
" Checkout/branch maps ~
" coo   Check out the commit under the cursor.
" cb<Spa>   Populate command line with ":Git branch ".
" co<Spa>   Populate command line with ":Git checkout ".
" cb?|co?   Show this help.
" Stash maps ~
" czz   Push stash.  Pass a [count] of 1 to add
" czw   Push stash of the work-tree.  Like `czz` with
" czs   Push stash of the stage.  Does not accept a count.
" czA   Apply topmost stash, or stash@{count}.
" cza   Apply topmost stash, or stash@{count}, preserving the
" czP   Pop topmost stash, or stash@{count}.
" czp   Pop topmost stash, or stash@{count}, preserving the
" cz<Spa>               Populate command line with ":Git stash ".
" cz?   Show this help.
" Rebase maps ~
" ri|u  Perform an interactive rebase. Uses ancestor of
" rf    Perform an autosquash rebase without editing the todo
" ru    Perform an interactive rebase against @{upstream}.
" rp    Perform an interactive rebase against @{push}.
" asdfad
" rr    Continue the current rebase.
" rs    Skip the current commit and continue the current
" ra    Abort the current rebase.
" re    Edit the current rebase todo list.
" rw    Perform an interactive rebase with the commit under
" rm    Perform an interactive rebase with the commit under
" rd    Perform an interactive rebase with the commit under
" r<Spa>  Populate command line with ":Git rebase ".
" r?    Show this help.
" Miscellaneous maps ~
" gq    Close the status buffer.
" .     Start a |:| command line with the file under the
" g?    Show help for |fugitive-maps|.

" Git commit setup
" Note: This works for both command line and fugitive commits
function! git#commit_setup(...)
  let &l:colorcolumn = 73
  call switch#autosave(1)
  goto
  startinsert
endfunction

" Fugitive jumping to existing files
" Note: Currently avoid overwriting existing buffer with non-existing partials and
" diffs by always starting interactive fugitive from new tab.
" Note: Should use other insert or changing commands e.g. 'o' and 'O' for opening
" diffs and stuff. The below is mainly used for the fugitive home page.
" General fugitive window setup
function! git#fugitive_setup() abort
  exe 'file ' &filetype
  let b:maparg = maparg('<CR>')
  noremap <expr> <buffer> <CR> git#fugitive_open()
endfunction
function! git#fugitive_open(...)
  let path = a:0 ? a:1 : expand('<cfile>')
  if !empty(glob(path))
    return "\<Cmd>Existing " . path . "\<CR>"
  else  " should be applied by autocmd
    return eval('"' . escape(get(b:, 'maparg', ''), '"<') . '"')
  endif
endfunction

" Git gutter staging jumping and previewing
" Note: This was designed by looking at hunk.vim. Seems all buffer local gitgutter
" settings are stores in g:gitgutter dictionary with 'hunks' containing lists of
" [id, type, line, nline] where type == 0 is for addition-only hunks. Seems that
" gitgutter#hunk#stage() requires cursor inside lines and fails when specifying lines
" outside of addition hunk (see s:hunk_op) so explicitly navigate lines below. Also
" this automatically stages partial additions if motion intersects only partly, but
" otherwise, for intersections with non-addition hunks, stages the entire thing.
" Note: Currently GitGutterStageHunk only supports partial staging of additions
" specified by visual selection, not different hunks. This supports both, iterates in
" reverse in case lines change. See: https://github.com/airblade/vim-gitgutter/issues/279
function! git#hunk_action(stage) abort range
  call switch#gitgutter(1)  " ensure enabled
  let cmd = 'GitGutter' . (a:stage ? 'Stage' : 'Undo') . 'Hunk'
  let lines = []
  let hunks = get(get(b:, 'gitgutter', {}), 'hunks', [])
  let [firstline, lastline] = sort([a:firstline, a:lastline])
  for [id, typ, lnum, lcnt] in hunks
    let lmax = lcnt == 0 ? lnum : lnum + lcnt - 1
    if firstline <= lnum && lmax <= lastline
      let range = ''
    elseif firstline <= lnum && lnum <= lastline  " starts inside, ends outside
      let range = typ == 0 ? lnum . ',' . lastline : ''
    elseif firstline <= lmax && lmax <= lastline  " starts outside, ends inside
      let range = typ == 0 ? firstline . ',' . lmax : ''
    else
      continue
    endif
    exe lnum
    exe range . cmd
  endfor
  GitGutter  " update signs (sometimes they lag)
endfunction
" Hunk jumping utility
function! git#hunk_jump(forward, stage) abort
  call switch#gitgutter(1)  " ensure enabled
  let which = a:forward ? 'Next' : 'Prev'
  let cmd = 'GitGutter' . which . 'Hunk'
  exe v:count1 . cmd
  if a:stage | exe 'GitGutterStageHunk' | endif
endfunction
" Hunk preview utility
function! git#hunk_preview() abort
  call switch#gitgutter(1)
  GitGutter
  GitGutterPreviewHunk
  wincmd j
endfunction
" For <expr> map accepting motion
function! git#hunk_action_expr(...) abort
  return utils#motion_func('git#hunk_action', a:000)
endfunction
