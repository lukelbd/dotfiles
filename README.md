## The dotfiles repo
This syncs my settings for `bash`, `vim`, `tmux`, `screen`, and some limited `python` settings.

Good idea to keep separate installations of **`anaconda`**, because for example
compiling the ISCA module must be complicated if the distro is shared by two servers with different utilities.
So do not attempt syncing this, probably is major can of worms.

The case of `.jupyter` and `.ipython` stuff is more tricky. It would be nice to sync the
`.css` themes generated by `jt`, but notebook themes can just be enabled on startup every time
with a simple alias. Really we just want the following:
1. Sync all plugins (not really feasible if maintaining separate anaconda distros; need to `pip install` the `nbextensions` organizer).
2. Sync their options (mostly the keyboard shortcuts, making sure Table of Contents is enabled with desired settings; 
maybe way to isolate the config file for this).
