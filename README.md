## The dotfiles repo
This syncs various tools/plugins/settings for for `bash`, `vim`, `tmux`, and `jupyter`, along with some `bin` scripts.

Check out the `nc<suffix>` functions in my `.bashrc` for a bunch of super useful tools that parse `ncdump` output/summarize NetCDF files. You will also find some handy tools for maintaining connections to remote `jupyter notebook` sessions. Check out `.vim/plugin` and `.vim/ftplugin` for a bunch of custom VIM plugins, and `.vimrc` for a bunch of other tools. Try out my `.dircolors.ansi` for useful color-coding of `ls` results. Try out my `.gitconfig` for a few handy `git` aliases.

The `.jupyter` folder is synced just to preserve my custom key bindings in `notebook.json`, along with some `nbextension` settings. Note `jupyter_nbconvert_config.json` controls settings for exporting the notebook to other formats, `jupyter_notebook_config.json` enables the nbextensions tab, `nbconfig/tree.json` controls the tree tab, and `nbconfig/common.json` controls hiding of incompatible extensions. The `custom` folder contains custom javascript and CSS files controlled by `jupyterthemes`. 
