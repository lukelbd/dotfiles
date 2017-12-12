## The dotfiles repo
This syncs my settings for `bash`, `vim`, `tmux`, `screen`, and some limited `python` settings.

Good idea to keep separate installations of **`anaconda`**, because for example compiling the ISCA module must be complicated if the distro is shared by two servers with different utilities. So do not attempt syncing this, probably is major can of worms.

Don't really use any `.ipython` settings as they are enabled by cell magic on startup. However that is probably silly, will start syncing after all.

Test -- does this linebreak?

And don't really need `.jupyter` for enabling themes because can just enable on them on startup every time with an alias to `jt`. However we do want stuff stored in `nbconfig/notebook.json` (these are all the keyboard shortcuts and extension options).
<!-- 1. Sync all plugins (not really feasible if maintaining separate anaconda distros; need to `pip install` the `nbextensions` organizer). -->
<!-- 2. Sync their options (mostly the keyboard shortcuts, making sure Table of Contents is enabled with desired settings; maybe way to isolate the config file for this). -->
