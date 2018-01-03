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

## LS Colors
The value of this variable describes what color to use for which attribute when colors are enabled with `CLICOLOR`.  This string is a concatenation of pairs of
the format `fb`, where `f` is the foreground color and `b` is the background color.

The color designators are as follows:

    a     black
    b     red
    c     green
    d     brown
    e     blue
    f     magenta
    g     cyan
    h     light grey
    A     bold black, usually shows up as dark grey
    B     bold red
    C     bold green
    D     bold brown, usually shows up as yellow
    E     bold blue
    F     bold magenta
    G     bold cyan
    H     bold light grey; looks like bright white
    x     default foreground or background

Note that the above are standard ANSI colors.  The actual display may differ depending on the color capabilities of the terminal in use.

The order of the attributes are as follows:

    1.   directory
    2.   symbolic link
    3.   socket
    4.   pipe
    5.   executable
    6.   block special
    7.   character special
    8.   executable with setuid bit set
    9.   executable with setgid bit set
    10.  directory writable to others, with sticky bit
    11.  directory writable to others, without sticky bit

The default is `exfxcxdxbxegedabagacad`, i.e. blue foreground and default background for regular directories, black foreground and red background for setuid
executables, etc.

## LS_COLORS
LS_COLORS='di=1:fi=0:ln=31:pi=5:so=5:bd=5:cd=5:or=31'

The parameters for LS_COLORS (di, fi, ln, pi, etc) refer to different file types:

    di 	Directory
    fi 	File
    ln 	Symbolic Link
    pi 	Fifo file
    so 	Socket file
    bd 	Block (buffered) special file
    cd 	Character (unbuffered) special file
    or 	Symbolic Link pointing to a non-existent file (orphan)
    mi 	Non-existent file pointed to by a symbolic link (visible when you type ls -l)
    ex 	File which is executable (ie. has 'x' set in permissions).

### Color Codes

Through trial and error I worked out the color codes for `LS_COLORS` to be:

    0 =	Default Colour
    1 =	Bold
    4 =	Underlined
    5 =	Flashing Text
    7 =	Reverse Field
    31 =	Red
    32 =	Green
    33 =	Orange
    34 =	Blue
    35 =	Purple
    36 =	Cyan
    37 =	Grey
    40 =	Black Background
    41 =	Red Background
    42 =	Green Background
    43 =	Orange Background
    44 =	Blue Background
    45 =	Purple Background
    46 =	Cyan Background
    47 =	Grey Background
    90 =	Dark Grey
    91 =	Light Red
    92 =	Light Green
    93 =	Yellow
    94 =	Light Blue
    95 =	Light Purple
    96 =	Turquoise
    100 =	Dark Grey Background
    101 =	Light Red Background
    102 =	Light Green Background
    103 =	Yellow Background
    104 =	Light Blue Background
    105 =	Light Purple Background
    106 =	Turquoise Background

These codes can also be combined with one another:

    di=5;34;43
