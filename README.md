# dotfiles

This syncs various tools/plugins/settings for for `bash`, `vim`, `tmux`, and `jupyter`,
along with some `bin` scripts.

## Bash config

Check out the `nc<suffix>` functions in my `.bashrc` for a bunch of super useful tools
that parse `ncdump` output/summarize NetCDF files. You will also find some handy tools
for maintaining connections to remote `jupyter notebook` sessions. Try out my
`.dircolors.ansi` for useful color-coding of `ls` results. 

## Vim config

Check out `.vimrc` for my plugin usage and some handy functions and remaps. Instead of
just using `<Leader>` for custom maps, I use several different keys for custom map
prefixes.

| Prefix | Description |
| ---- | ---- |
| `<Leader>` | Normal mode. Used for miscellaneous and complex tasks. Mapped to `<Space>`. |
| `\` | Normal mode. Used for complex regex replacements and tabular alignment. |
| `c` | Normal mode. Used for toggling comments and inserting comment headers. |
| `g` | Normal mode. Used for git-gutter commands and other git things. |
| `<Tab>` | Normal mode. Used for window and tab management and resizing. |
| `<C-s>` | Insert and visual mode. Used for surrounding the cursor with delimiters. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |
| `<C-z>` | Insert mode. Used for inserting snippets. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |
| `<C-b>` | Insert mode. Used for inserting LaTeX citations. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |

Also check out my [vim-idetools](https://github.com/lukelbd/vim-idetools),
[vim-scrollwrapped](https://github.com/lukelbd/vim-scrollwrapped),
[vim-tabline](https://github.com/lukelbd/vim-tabline), and
[vim-statusline](https://github.com/lukelbd/vim-statusline), and
[vim-toggle](https://github.com/lukelbd/vim-toggle) vim plugins.

## Misc config
You can find various functions in `bin`, and handy `git` commands in my `.gitconfig`
file. Note `.jupyter` is synced just to preserve my custom key bindings in
`notebook.json`, along with some `nbextension` settings in `tree.json`, `common.json`,
and `jupyter_notebook_config.json`.
<!-- The `custom` folder contains custom javascript and CSS files controlled by `jupyterthemes`. -->

