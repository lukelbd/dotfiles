# dotfiles
This syncs various tools/plugins/settings for for `bash`, `vim`, `tmux`, and `jupyter`, along with some `bin` scripts.

## Bash config
Check out the `nc<suffix>` functions in my `.bashrc` for a bunch of super useful tools that parse `ncdump` output/summarize NetCDF files. You will also find some handy tools for maintaining connections to remote `jupyter notebook` sessions.
Try out my `.dircolors.ansi` for useful color-coding of `ls` results. 

## Vim config
Check out `.vimrc` for my plugin usage and some handy functions and remaps. Instead of
just using `<Leader>` for custom maps, I use several different keys for custom
map prefixes:

* `<Tab>`: Normal mode. Used for window and tab management and resizing.
* `c`: Normal mode. Used for toggling comments and inserting comment headers.
* `\`: Normal mode. Used for complex regex replacements and tabular alignment.
* `;`: Normal mode. Used for syntastic commands and spell checking.
* `g`: Normal mode. Used for git-gutter commands and other git things.
* `<Leader>`: Normal mode. Used for miscellaneous and complex tasks. Mapped to `<Space>`.
* `<C-o>`, `<C-p>`: Insert mode. Used for inserting LaTeX citations.
* `<C-s>`, `<C-z>`: Insert mode. Used for surrounding cursor with delimiters and inserting snippets or symbols.

Also check out my repositories starting with `vim-` for some custom plugins.

## Misc config
You can find various functions in `bin`,
and handy `git` commands in my `.gitconfig` file.
Note `.jupyter` is synced just to preserve my custom key bindings in `notebook.json`, along with some `nbextension` settings in `tree.json`, `common.json`, and `jupyter_notebook_config.json`.
<!-- The `custom` folder contains custom javascript and CSS files controlled by `jupyterthemes`.  -->

## Code style
At various times, I've had to make enormous global changes to code style in various projects. They were generally applied with the vi regex engine, since it contains advanced features like non-greedy searches unavailable in sed. They are generally applied with

```sh
find . -name '*.ext' -exec vi -u NONE -c '%s/regex/replacement/ge | wq' {} \;
```

where some of the replacement patterns are as follows.

### No-space vi comments
This prepends a space to vi comments. The comment character is so small that I used to write comments without a space, but no one else on the planet seems to do this.
```
%s/\(^[ \t:]*"\(\zs\ze\)[^ #].*$\|^[^"]*\s"\(\zs\ze\)[^_\-:.%#=" ][^"]*$\)/ \2/ge
```

### No-space vi assignments
This surrounds assignments in vi script with spaces.
```
%s/\<let\>\s\+\S\{-1,}\zs\([.^+%-]\?=\)/ \1 /ge
```

### No-space comparison operators
This surrounds comparison operators with spaces, accounting for `<Tab>` style keystroke indicators in vim script.
```
%s/\_s[^ ,\-<>@!&]\+\zs\(<=\|>=\|==\|<\|>\)\ze[^ ,!\-<>&]\+\_s/ \1 /ge
```
