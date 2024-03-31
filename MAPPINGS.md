Refactoring
===========

At several points, I've had to make enormous global changes to code style in various
projects. They are usually applied with the vi regex engine, since it contains advanced
features like non-greedy searches unavailable in sed and awk. They can be applied
interactively or in *bulk* as follows:

```sh
find . -name '*.ext' -exec vi -u NONE -c '%s/regex/replacement/ge | wq' {} \;
```

Fortran
-------

Convert fixed format line continuation indicators to Fortran 90.
```vim
%s/\(\s*!.*\)\?\n\(\s*\)\(&\)\(\S*\)\s*/\4 \3\1\r  \2/ge
```

Markdown
--------

Add a space between markdown headers indicators and the header text.
```vim
%s/#\([a-zA-Z0-9]\)/# \1/ge
```

Vimscript
---------

Surround assignments in vi script with spaces.
```vim
%s/\<let\>\s\+\S\{-1,}\zs\([.^+%-]\?=\)/ \1 /ge
```

Prepend a space to vi comments. The comment character is so small that I used to write comments without a space, but no one else on the planet seems to do this.
```vim
%s/\(^[ \t:]*"\(\zs\ze\)[^ #].*$\|^[^"]*\s"\(\zs\ze\)[^_\-:.%#=" ][^"]*$\)/ \2/ge
```

Surround comparison operators with spaces, accounting for `<Tab>` style keystroke indicators in vim script.

```vim
%s/\_s[^ ,\-<>@!&=\\]\+\zs\(<=\|>=\|==\|^C|>\)\ze[^ ,!\-<>&=\\]\+\_s/ \1 /ge
```


Mappings
========

The following buffer-local mappings are used for `fugitive` panes and
`netrw` folders. See `:help fugitive-maps` and `:help netrw-quickmaps`.

Global fugitive
---------------

| Mapping | Description |
| --- | --- |
| `<C-R><C-G>` | On the command line, recall the path to the current fugitive-object |
| `["x]y<C-G>` | Yank the path to the current fugitive-object |
| `.` | Start a :Git command line with the file under the cursor prepopulated. |
| `gq` | Close the status buffer. |
| `g?` | Show help for fugitive-maps. |

Fugitive blame
--------------

| Mapping | Description |
| --- | --- |
| `g?` | Show this help. |
| `A` | Resize to end of author column. |
| `C` | Resize to end of commit column. |
| `D` | Resize to end of date/time column. |
| `gq` | Close blame, then :Gedit to return to work tree version. |
| `<CR>` | Close blame, and jump to patch that added line (or blob for boundary commit). |
| `o` | Jump to patch or blob in horizontal split. |
| `O` | Jump to patch or blob in new tab. |
| `p` | Jump to patch or blob in preview window. |
| `-` | Reblame at commit. |

Fugitive stage
--------------

| Mapping | Description |
| --- | --- |
| `s` | Stage (add) the file or hunk under the cursor. |
| `u` | Unstage (reset) the file or hunk under the cursor. |
| `-` | Stage or unstage the file or hunk under the cursor. |
| `U` | Unstage everything. |
| `=` | Toggle an inline diff of the file under the cursor. |
| `>` | Insert an inline diff of the file under the cursor. |
| `<` | Remove the inline diff of the file under the cursor. |
| `gI` | Open .git/info/exclude in a split and add the file under the cursor. Use a count to open .gitignore. |
| `I|P` | Invoke `:Git` add --patch or reset --patch on the file under the cursor. On untracked files, this instead calls :Git add --intent-to-add. |
| `dp` | Invoke `:Git` diff on the file under the cursor. Deprecated in favor of inline diffs. |
| `dd` | Perform a `:Gdiffsplit` on the file under the cursor. |
| `dv` | Perform a `:Gvdiffsplit` on the file under the cursor. |
| `ds|dh` | Perform a `:Ghdiffsplit` on the file under the cursor. |
| `dq` | Close all but one diff buffer, and `:diffoff!` the last one. |
| `d?` | Show this help. |

Navigation maps
---------------

| Mapping | Description |
| --- | --- |
| `<CR>` | Open the file or fugitive-object under the cursor. In a blob, this and similar maps jump to the patch from the diff where this was added, or where it was removed if a count was given. If the line is still in the work tree version, passing a count takes you to it. 
| `o` | Open the file or fugitive-object under the cursor in a new split. |
| `gO` | Open the file or fugitive-object under the cursor in a new vertical split. |
| `O` | Open the file or fugitive-object under the cursor in a new tab. |
| `p` | Open the file or fugitive-object under the cursor in a preview window. In the status buffer, 1p is required to bypass the legacy usage instructions. |
| `~` | Open the current file in the [count]th first ancestor. |
| `P` | Open the current file in the [count]th parent. |
| `C` | Open the commit containing the current file. |
| `(` | Jump to the previous file, hunk, or revision. |
| `)` | Jump to the next file, hunk, or revision. |
| `[c` | Jump to previous hunk, expanding inline diffs automatically. (This shadows the Vim built-in [c that provides a similar operation in diff mode.) |
| `]c` | Jump to next hunk, expanding inline diffs automatically. (This shadows the Vim built-in ]c that provides a similar operation in diff mode.) |
| `[/|[m` | Jump to previous file, collapsing inline diffs automatically. (Mnemonic: '/' appears in filenames, 'm' appears in 'filenames'.) |
| `]/|]m` | Jump to next file, collapsing inline diffs automatically. (Mnemonic: '/' appears in filenames, 'm' appears in 'filenames'.) |
| `i` | Jump to the next file or hunk, expanding inline diffs automatically. |
| `[[` | Jump [count] sections backward. |
| `]]` | Jump [count] sections forward. |
| `[]` | Jump [count] section ends backward. |
| `][` | Jump [count] section ends forward. |
| `*` | On the first column of a + or - diff line, search for the corresponding - or + line. Otherwise, defer to built-in star. |
| `gU` | Jump to file [count] in the 'Unstaged' section. |
| `gs` | Jump to file [count] in the 'Staged' section. |
| `gp` | Jump to file [count] in the 'Unpushed' section. |
| `gP` | Jump to file [count] in the 'Unpulled' section. |
| `gr` | Jump to file [count] in the 'Rebasing' section. |
| `gi` | Open .git/info/exclude in a split. Use a count to open .gitignore. |

Commit maps
-----------

| Mapping | Description |
| --- | --- |
| `cc` | Create a commit. |
| `ca` | Amend the last commit and edit the message. |
| `ce` | Amend the last commit without editing the message. |
| `cw` | Reword the last commit. |
| `cvc` | Create a commit with -v. |
| `cva` | Amend the last commit with -v |
| `cf` | Create a `fixup!` commit for the commit under the cursor. |
| `cF` | Create a `fixup!` commit for the commit under the cursor and immediately rebase it. |
| `cs` | Create a `squash!` commit for the commit under the cursor. |
| `cS` | Create a `squash!` commit for the commit under the cursor and immediately rebase it. |
| `cA` | Create a `squash!` commit for the commit under the cursor and edit the message. |
| `c<Space>` | Populate command line with ':Git commit '. *fugitive_cr* |
| `crc` | Revert the commit under the cursor. |
| `crn` | Revert the commit under the cursor in the index and work tree, but do not actually commit the changes. |
| `cr<Space>` | Populate command line with ':Git revert '. *fugitive_cm* |
| `cm<Space>` | Populate command line with ':Git merge '. |
| `c?` | Show this help. |

Checkout maps
-------------

| Mapping | Description |
| --- | --- |
| `coo` | Check out the commit under the cursor. |
| `cb<Space>` | Populate command line with `:Git branch`. |
| `co<Space>` | Populate command line with `:Git checkout`. |
| `cb?` | Show this help. co? |
| `czz` | Push stash. Pass a [count] of 1 to add `--include-untracked` or 2 to add `--all`. |
| `czw` | Push stash of the work-tree. Like `czz` with `--keep-index`. |
| `czs` | Push stash of the stage. Does not accept a count. |
| `czA` | Apply topmost stash, or `stash@{count}`. |
| `cza` | Apply topmost stash, or `stash@{count}`, preserving the index. |
| `czP` | Pop topmost stash, or `stash@{count}`. |
| `czp` | Pop topmost stash, or `stash@{count}`, preserving the index. |
| `cz<Space>` | Populate command line with ':Git stash '. |
| `cz?` | Show this help. |

Rebase maps
-----------

| Mapping | Description |
| --- | --- |
| `ri|u` | Perform an interactive rebase. Uses ancestor of commit under cursor as upstream if available. |
| `rf` | Perform an autosquash rebase without editing the todo list. Uses ancestor of commit under cursor as upstream if available. |
| `ru` | Perform an interactive rebase against `@{upstream}`. |
| `rp` | Perform an interactive rebase against `@{push}`. |
| `rr` | Continue the current rebase. |
| `rs` | Skip the current commit and continue the current rebase. |
| `ra` | Abort the current rebase. |
| `re` | Edit the current rebase todo list. |
| `rw` | Perform an interactive rebase with the commit under the cursor set to `reword`. |
| `rm` | Perform an interactive rebase with the commit under the cursor set to `edit`. |
| `rd` | Perform an interactive rebase with the commit under the cursor set to `drop`. |
| `r<Space>` | Populate command line with `:Git rebase`. |
| `r?` | Show this help. |

Netrw maps
----------

| Mapping | Description |
| --- | --- |
| `<F1>` | Causes Netrw to issue help |
| `<cr>` | Netrw will enter the directory or read the file |
| `<del>` | Netrw will attempt to remove the file/directory |
| `<c-h>` | Edit file hiding list |
| `<c-l>` | Causes Netrw to refresh the directory listing |
| `<c-r>` | Browse using a gvim server |
| `<c-tab>` | Shrink/expand a netrw/explore window |
| `-` | Makes Netrw go up one directory |
| `a` | Cycles between normal display, hiding (suppress display of files matching g:netrw_list_hide) and showing (display only files which match g:netrw_list_hide) |
| `cd` | Make browsing directory the current directory |
| `C` | Setting the editing window |
| `d` | Make a directory |
| `D` | Attempt to remove the file(s)/directory(ies) |
| `gb` | Go to previous bookmarked directory |
| `gd` | Force treatment as directory |
| `gf` | Force treatment as file |
| `gh` | Quick hide/unhide of dot-files |
| `gn` | Make top of tree the directory below the cursor |
| `gp` | Change local-only file permissions |
| `i` | Cycle between thin, long, wide, and tree listings |
| `I` | Toggle the displaying of the banner |
| `mb` | Bookmark current directory |
| `mc` | Copy marked files to marked-file target directory |
| `md` | Apply diff to marked files (up to 3) |
| `me` | Place marked files on arg list and edit them |
| `mf` | Mark a file |
| `mF` | Unmark files |
| `mg` | Apply vimgrep to marked files |
| `mh` | Toggle marked file suffices' presence on hiding list |
| `mm` | Move marked files to marked-file target directory |
| `mp` | Print marked files |
| `mr` | Mark files using a shell-style |
| `mt` | Current browsing directory becomes markfile target |
| `mT` | Apply ctags to marked files |
| `mu` | Unmark all marked files |
| `mv` | Apply arbitrary vim command to marked files |
| `mx` | Apply arbitrary shell command to marked files |
| `mX` | Apply arbitrary shell command to marked files en bloc |
| `mz` | Compress/decompress marked files |
| `o` | Enter the file/directory under the cursor in a new horizontal split browser. |
| `O` | Obtain a file specified by cursor |
| `p` | Preview the file |
| `P` | Browse in the previously used window |
| `qb` | List bookmarked directories and history |
| `qf` | Display information on file |
| `qF` | Mark files using a quickfix list |
| `qL` | Mark files using a loclist |
| `r` | Reverse sorting order |
| `R` | Rename the designated file(s)/directory(ies) |
| `s` | Select sorting style: by name, time, or file size |
| `S` | Specify suffix priority for name-sorting |
| `t` | Enter the file/directory under the cursor in a new tab |
| `u` | Change to recently-visited directory |
| `U` | Change to subsequently-visited directory |
| `v` | Enter the file/directory under the cursor in a new vertical split browser. |
| `x` | View file with an associated program |
| `X` | Execute filename under cursor via |
| `%` | Open a new file in netrw's current directory |
