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

Also check out my repositories starting with `vim-` for some handy custom plugins.

## Misc config
You can find various functions in `bin`,
and handy `git` commands in my `.gitconfig` file.
Note `.jupyter` is synced just to preserve my custom key bindings in `notebook.json`, along with some `nbextension` settings in `tree.json`, `common.json`, and `jupyter_notebook_config.json`.
<!-- The `custom` folder contains custom javascript and CSS files controlled by `jupyterthemes`.  -->

