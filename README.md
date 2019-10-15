# dotfiles
This syncs various tools/plugins/settings for for `bash`, `vim`, `tmux`, and `jupyter`, along with some `bin` scripts.

## Bash config
Check out the `nc<suffix>` functions in my `.bashrc` for a bunch of super useful tools that parse `ncdump` output/summarize NetCDF files. You will also find some handy tools for maintaining connections to remote `jupyter notebook` sessions.
Try out my `.dircolors.ansi` for useful color-coding of `ls` results. 

## Vim config
Check out `.vimrc` for my plugin usage and some handy functions and remaps. Instead of
just using `<Leader>` for custom maps, I use several different keys for custom
map prefixes.

| Prefix | Description |
| ---- | ---- |
| `<Leader>` | Normal mode. Used for miscellaneous and complex tasks. Mapped to `<Space>`. |
| `\` | Normal mode. Used for complex regex replacements and tabular alignment. |
| `c` | Normal mode. Used for toggling comments and inserting comment headers. |
| `g` | Normal mode. Used for git-gutter commands and other git things. |
| `;` | Normal mode. Used for window and tab management and resizing. |
| `<C-s>` | Insert and visual mode. Used for surrounding the cursor with delimiters. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |
| `<C-z>` | Insert mode. Used for inserting snippets. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |
| `<C-b>` | Insert mode. Used for inserting LaTeX citations. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |

Also check out my [vim-idetools](https://github.com/lukelbd/vim-idetools), [vim-scrollwrapped](https://github.com/lukelbd/vim-scrollwrapped), [vim-tabline](https://github.com/lukelbd/vim-tabline), and [vim-statusline](https://github.com/lukelbd/vim-statusline), and [vim-toggle](https://github.com/lukelbd/vim-toggle) vim plugins.

## Misc config
You can find various functions in `bin`,
and handy `git` commands in my `.gitconfig` file.
Note `.jupyter` is synced just to preserve my custom key bindings in `notebook.json`, along with some `nbextension` settings in `tree.json`, `common.json`, and `jupyter_notebook_config.json`.
<!-- The `custom` folder contains custom javascript and CSS files controlled by `jupyterthemes`. -->

## Refactoring regexes
At various times, I've had to make enormous global changes to code style in various projects. They were generally applied with the vi regex engine, since it contains advanced features like non-greedy searches unavailable in sed. They are generally applied with

```sh
find . -name '*.ext' -exec vi -u NONE -c '%s/regex/replacement/ge | wq' {} \;
```

The following prepends a space to vi comments. The comment character is so small that I used to write comments without a space, but no one else on the planet seems to do this.
```vim
%s/\(^[ \t:]*"\(\zs\ze\)[^ #].*$\|^[^"]*\s"\(\zs\ze\)[^_\-:.%#=" ][^"]*$\)/ \2/ge
```

The following surrounds assignments in vi script with spaces.
```vim
%s/\<let\>\s\+\S\{-1,}\zs\([.^+%-]\?=\)/ \1 /ge
```

The following surrounds comparison operators with spaces, accounting for `<Tab>` style keystroke indicators in vim script.
```vim
%s/\_s[^ ,\-<>@!&=\\]\+\zs\(<=\|>=\|==\|^C|>\)\ze[^ ,!\-<>&=\\]\+\_s/ \1 /ge
```
