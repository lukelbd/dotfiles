## The dotfiles repo
This syncs my settings for `bash`, `vim`, `tmux`, `screen`, and some limited `python` settings.

Good idea to keep separate installations of **`anaconda`**, because for example compiling the ISCA module must be complicated if the distro is shared by two servers with different utilities. So do not attempt syncing this, probably is major can of worms.

Don't really use any `.ipython` settings as they are enabled by cell magic on startup. However that is probably silly, will start syncing after all.

And don't really need `.jupyter` for enabling themes because can just enable on them on startup every time with an alias to `jt`. However we do want stuff stored in `nbconfig/notebook.json` (these are all the keyboard shortcuts and extension options).

## Customization notes for iTerm2 and macbook
* Make sure Profiles-->Terminal-->Enable Mouse Reporting is turned on so can use mouse in VIM.
* Change mouse settings to allow alt-clicking to move cursor while entering shell command.
* Delete all Profile-specific keyboard mappings and make the special Alt+Arrow escape sequence mappings to allow moving cursor by word like you can do elsewhere in the OS.
* See [this link](https://stackoverflow.com/a/29403520/4970632) for enabling word deletion/line deletion and movement in iTerm2 just like you can do elsewhere in OS.
* The Cmd+Enter shortcut in iTerm2 refreshes the screen and repeats the previous command, don't remember where this idea came from.
* Remember to save changes to file after every exit; this way when switch to new laptop have everything
right there. If iTerm crashes, the settings are not saved.
<!-- 1. Sync all plugins (not really feasible if maintaining separate anaconda distros; need to `pip install` the `nbextensions` organizer). -->
<!-- 2. Sync their options (mostly the keyboard shortcuts, making sure Table of Contents is enabled with desired settings; maybe way to isolate the config file for this). -->
