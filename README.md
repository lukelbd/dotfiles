dotfiles
========

This syncs various tools/plugins/settings for for `bash`, `vim`, `tmux`, and `jupyter`,
along with some `bin` scripts.

Bash config
-----------

Check out the `nc<suffix>` functions in my `.bashrc` for a bunch of super useful tools
that parse `ncdump` output/summarize NetCDF files. You will also find some handy tools
for maintaining connections to remote `jupyter notebook` sessions. Try out my
`.dircolors.ansi` for useful color-coding of `ls` results. 

Vim config
----------

Check out `.vimrc` for my plugin usage and some handy functions and remaps. Instead of
just using `<Leader>` for custom maps, I use several different keys for custom map
prefixes.

| Prefix | Mode(s) | Description |
| ---- | ---- | ---- |
| `<Leader>` | `n` | Miscellaneous and complex tasks. Mapped to `<Space>`. |
| `\` | `n` | Complex regex replacements and tabular alignment. |
| `c` | `n` | Toggling comments and inserting comment headers. |
| `g` | `n` | Git-gutter commands and other git-related things. |
| `<Tab>` | `n` | Window and tab management and resizing. |
| `<C-s>` | `vi` | Surrounding content with delimiters. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |
| `<C-d>` | `i` | Inserting pre-defined snippets. See the [textools](https://github.com/lukelbd/vim-textools) plugin. |

Also check out my [vim-idetools](https://github.com/lukelbd/vim-idetools),
[vim-scrollwrapped](https://github.com/lukelbd/vim-scrollwrapped),
[vim-tabline](https://github.com/lukelbd/vim-tabline), and
[vim-statusline](https://github.com/lukelbd/vim-statusline), and
[vim-toggle](https://github.com/lukelbd/vim-toggle) vim plugins.

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

You can find various functions in `bin`, and handy `git` commands in my `.gitconfig`
file. Note `.jupyter` is synced just to preserve my custom key bindings in
`notebook.json`, along with some `nbextension` settings in `tree.json`, `common.json`,
and `jupyter_notebook_config.json`.
