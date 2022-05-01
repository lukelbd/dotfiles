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
vim plugins, configures FZF fuzzy autocompletion integration features, and configures a
billion key mappings as I see fit. I use a few different standard prefixes:

| Prefix   | Mode(s) | Description                                                       |
| ------   | ------- | -----------                                                       |
| `<Leader>` | `n`       | Miscellaneous and complex tasks. Set to `<Space>`.                  |
| `<Tab>`    | `n`       | Window and tab management and resizing.                           |
| `\`        | `n`       | Preset search and replaces with motions.                          |
| `g`        | `n`       | Various plugin-specific extensions.                               |
| `<C-s>`    | `vi`      | Surrounding content with delimiters. See the [vim-succinct](https://github.com/lukelbd/vim-succinct) plugin. |
| `<C-d>`    | `i`       | Inserting pre-defined snippets. See the [vim-succinct](https://github.com/lukelbd/vim-succinct) plugin.      |

Also check out the vim plugins I've written over the years:
[vim-succinct](https://github.com/lukelbd/vim-templates),
[vim-tags](https://github.com/lukelbd/vim-tags),
[vim-statusline](https://github.com/lukelbd/vim-statusline),
[vim-tabline](https://github.com/lukelbd/vim-tabline),
[vim-scrollwrapped](https://github.com/lukelbd/vim-scrollwrapped), and
[vim-toggle](https://github.com/lukelbd/vim-toggle).

You can also find the following filetype-specific features in the `ftplugin`, `syntax`,
`after/ftplugin`, and `after/syntax` folders:

* Improved python and LaTeX highlighting.
* Improved comment highlighting for fortran and HTML syntax.
* Support for MATLAB, NCL, and "awk" script syntax highlighting.
* Support for highlighting SLURM and PBS supercomputer directives in comments at
  the head of shell scripts.
* `<Plug>Execute` maps for most languages that "run", "compile", and/or "open"
  the current file, depending on the language. This is mapped to `Z` by default.

Other config
------------

You can find various shell script utilities in `bin` and `git` commands in `.gitconfig`,
including a `latexmk` shell script integrated with `ftplugin` for convenient LaTeX
document rendering and viewing. Also, `.jupyter` files are synced to preserve custom
key binding and extension settings across jupyter notebook and jupyter lab sessions.
