dotfiles
========

This repo synchronizes various settings for `bash`, `vim`, `git`, `tmux`, `ipython`,
and `jupyter`. It also includes some handy shell functions and shell scripts.

Bash config
-----------

The `.bashrc` file is utterly massive. Among other things, it provides `nc<suffix>`
functions that summarize NetCDF files by parsing `ncdump`, provides tools for working
over SSH connections and maintaining connections to remote `jupyter` sessions, and
configures FZF fuzzy autocompletion and the conda environment. It also evaluates
`.dircolors.ansi` to keep color-coding of `ls` results consistent between workstations.

Vim config
----------

The `.vimrc` is even more utterly massive. Among other things, it configures a few dozen
vim plugins, configures FZF fuzzy autocompletion integration features, and defines a
billion key mappings as I see fit. In general, I use the prefix `<Leader>` for commands,
`<Tab>` for window operations, `\` for regex replacements, `g` for navigation actions,
and `z` for folding actions.

You can also find filetype-specific features in the `ftplugin`, `syntax`, and
`after/syntax` folders, including improved syntax highlighting and `<Plug>Execute`
mappings that "run", "compile", or "open" the current file (mapped to `Z` by default).
I have also written a number of vim plugins over the years: [vim-succinct](https://github.com/lukelbd/vim-succinct),
[vim-tags](https://github.com/lukelbd/vim-tags), [vim-statusline](https://github.com/lukelbd/vim-statusline), [vim-tabline](https://github.com/lukelbd/vim-tabline), [vim-scrollwrapped](https://github.com/lukelbd/vim-scrollwrapped), and [vim-toggle](https://github.com/lukelbd/vim-toggle).

Other config
------------

You can find various shell script utilities in `bin` and `git` commands in `.gitconfig`,
including a `latexmk` shell script integrated with `ftplugin` for convenient LaTeX
document rendering and viewing. Also, `.jupyter` files are synced to preserve custom
key binding and extension settings across jupyter notebook and jupyter lab sessions.
