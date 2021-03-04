dotfiles
========

This repo is used to synchronize various tools and settings for `bash`, `vim`, `tmux`,
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

The `.vimrc` is even more utterly massive. Among other things, it configures a few
dozen vim plugins, configures FZF fuzzy autocompletion integration features, and
configures nearly every conceivable key mapping as I see fit. Instead of just using
`<Leader>` for custom normal mode maps, I use few different prefixes:

| Prefix | Mode(s) | Description |
| ---- | ---- | ---- |
| `<Leader>` | `n` | Miscellaneous and complex tasks. Set to `<Space>`. |
| `<Tab>` | `n` | Window and tab management and resizing. |
| `\` | `n` | Complex regex replacements and tabular alignment. |
| `c` | `n` | Toggling comments and inserting comment headers. |
| `g` | `n` | Git-gutter commands and other git-related things. |
| `<C-s>` | `vi` | Surrounding content with delimiters. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |
| `<C-d>` | `i` | Inserting pre-defined snippets. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |

Also check out the vim plugins I've written over the years:
[vim-textools](https://github.com/lukelbd/vim-textools),
[vim-idetools](https://github.com/lukelbd/vim-idetools),
[vim-scrollwrapped](https://github.com/lukelbd/vim-scrollwrapped),
[vim-tabline](https://github.com/lukelbd/vim-tabline), and
[vim-statusline](https://github.com/lukelbd/vim-statusline), and
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

You can find various utilities in `bin`, and handy `git` commands in `.gitconfig`.
Also, `.jupyter` is synced just to preserve custom key binding and extension settings
across jupyter notebook and jupyter lab sessions.
