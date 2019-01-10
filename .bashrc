#!/bin/bash
#.bashrc
# This file should override defaults in /etc/profile in /etc/bashrc.
# Check out what is in the system defaults before using this, make sure your $PATH is populated.
# To SSH between servers without password use:
# https://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
# A few notes:
#  * Prefix key for issuing SSH-session commands is '~'; 'exit' sometimes doesn't work (perhaps because
#    if aliased or some 'exit' is in $PATH
#     C-d/'exit' -- IF AVAILABLE, exit SSH session
#     ~./~C-z -- Exit SSH session
#     ~& -- Puts SSH into background
#     ~# -- Gives list of forwarded connections in this session
#     ~? -- Gives list of these commands
#  * Extended globbing explanations, see:
#     http://mywiki.wooledge.org/glob
#  * Use '<package_manager> list' for MOST PACKAGE MANAGERS to see what is installed
#     e.g. brew list, conda list, pip list
################################################################################
# Bail out, if not running interactively (e.g. when sending data packets over with scp/rsync)
# Known bug, scp/rsync fail without this line due to greeting message:
# 1) https://unix.stackexchange.com/questions/88602/scp-from-remote-host-fails-due-to-login-greeting-set-in-bashrc
# 2) https://unix.stackexchange.com/questions/18231/scp-fails-without-error
################################################################################
[[ $- != *i* ]] && return
clear # first clear screen

################################################################################
# Prompt
################################################################################
# Keep things minimal; just make prompt boldface so its a bit more identifiable
export PS1='\[\033[1;37m\]\h[\j]:\W\$ \[\033[0m\]' # prompt string 1; shows "<comp name>:<work dir> <user>$"
# export PS1='\[\033[1;37m\]\h[\j]:\W \u\$ \[\033[0m\]' # prompt string 1; shows "<comp name>:<work dir> <user>$"
  # style; the \[ \033 chars are escape codes for changing color, then restoring it at end
  # see: https://stackoverflow.com/a/28938235/4970632
  # also see: https://unix.stackexchange.com/a/124408/112647
# Message constructor; modify the number to increase number of dots
_bashrc_message() {
  printf "${1}$(printf '.%.0s' $(seq 1 $((29 - ${#1}))))"
}

################################################################################
# Settings for particular machines
# Custom key bindings and interaction
################################################################################
# Reset all aliases
# Very important! Sometimes we wrap new aliases around existing ones, e.g. ncl!
unalias -a
# Reset functions? Nah, no decent way to do it
# declare -F # to view current ones
# Flag for if in MacOs
[[ "$OSTYPE" == "darwin"* ]] && _macos=true || _macos=false
# First, the path management
# If you source the default bashrc, *must* happen before everything else or
# may get unexpected behavior due to unexpected alias/function overrides!
_bashrc_message "Variables and modules"
export PYTHONPATH="" # this one needs to be re-initialized
if $_macos; then
  # Mac options
  # Defaults... but will reset them
  # eval `/usr/libexec/path_helper -s`
  # . /etc/profile # this itself should also run /etc/bashrc
  # Defaults
  export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
  # LaTeX and X11
  export PATH="/opt/X11/bin:/Library/TeX/texbin:$PATH"
  # Homebrew, Macports, PGI compilers
  export PATH="/opt/local/bin:/opt/local/sbin:$PATH" # MacPorts compilation locations
  export PATH="/usr/local/bin:$PATH" # Homebrew package download locations
  export PATH="/opt/pgi/osx86-64/2017/bin:$PATH"

  # Local tools
  # NOTE: Added matlab as a symlink in builds directory, was cleaner
  # NOTE: CDO needs IO thread locking (with -L flag) for NetCDF4 files (which
  # use HDF5 internally) if HDF5 wasn't compiled with parallel support
  # Turns out *cannot be done* in Homebrew; see: https://code.mpimet.mpg.de/boards/2/topics/4630?r=5714#message-5714
  # We remedied this by compiling cdo ourselves with hdf5 and netcdf libraries
  # export PATH="$HOME/builds/cdo-1.9.5/src:$HOME/builds/ncl-6.4.0/bin:$HOME/builds/matlab/bin:$PATH" # no more local cdo, had issues
  export PATH="$HOME/builds/ncl-6.4.0/bin:$HOME/builds/matlab/bin:$PATH"
  export PATH="$HOME/youtube-m4a:$PATH"

  # NCL NCAR command language (had trouble getting it to work on Mac with conda,
  # but on Linux distributions seems to work fine inside anaconda)
  # NOTE: By default, ncl tried to find dyld to /usr/local/lib/libgfortran.3.dylib;
  # actually ends up in above path after brew install gcc49; and must install
  # this rather than gcc, which loads libgfortran.3.dylib and yields gcc version 7
  # NOTE: Instead of aliasing ncl with library path prefix, try using
  # a fallback library path; suggested here: https://stackoverflow.com/a/3172515/4970632
  # This shouldn't screw up Homebrew stuff
  # NOTE: Fallback path doesn't mess up Homebrew, but *does* mess up some
  # python modules e.g. cartopy, so forget it
  alias ncl='DYLD_LIBRARY_PATH="/usr/local/lib/gcc/4.9" ncl' # fix libs
  export NCARG_ROOT="$HOME/builds/ncl-6.4.0" # critically necessary to run NCL
  # export DYLD_FALLBACK_LIBRARY_PATH="/usr/local/lib/gcc/4.9" # fix libs
else
  # Linux options
  case $HOSTNAME in
  # Olbers options
  # olbers)
  #   # Add utilies to path; PGI, Matlab, basics, and edit library path
  #   export PATH="/usr/local/bin:/usr/bin:/bin"
  #   export PATH="/usr/local/netcdf4-pgi/bin:/usr/local/netcdf4/bin:$PATH" # fortran lib
  #   export PATH="/usr/local/hdf5/bin:/usr/local/mpich3/bin:$PATH"
  #   export PATH="/opt/pgi/linux86-64/2017/bin:/opt/Mathworks/R2016a/bin$PATH"
  #   export LD_LIBRARY_PATH="/usr/local/mpich3/lib:/usr/local/hdf5/lib:/usr/local/netcdf4/lib:/usr/local/netcdf4-pgi/lib"
  # Gauss options
  # gauss)
  #   # Add utilities to path; PGI, Matlab, basics, and edit library path
  #   export PATH="/usr/local/bin:/usr/bin:/bin"
  #   export PATH="/usr/local/netcdf4-pgi/bin:/usr/local/hdf5-pgi/bin:/usr/local/mpich3-pgi/bin:$PATH"
  #   export PATH="/opt/pgi/linux86-64/2016/bin:/opt/Mathworks/R2016a/bin:$PATH"
  #   export LD_LIBRARY_PATH="/usr/local/mpich3-pgi/lib:/usr/local/hdf5-pgi/lib:/usr/local/netcdf4-pgi/lib"

  # Euclid options
  euclid)
    # Basics; all netcdf, mpich, etc. utilites already in in /usr/local/bin
    export PATH="/usr/local/bin:/usr/bin:/bin"
    export PATH="/opt/pgi/linux86-64/13.7/bin:/opt/Mathworks/bin:$PATH"
    export LD_LIBRARY_PATH="/usr/local/lib"

  # Monde options
  ;; monde*)
    # Basics; all netcdf, mpich, etc. utilites separate, add them
    export PATH="/usr/lib64/mpich/bin:/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"
    export LD_LIBRARY_PATH="/usr/lib64/mpich/lib:/usr/local/lib"
    # PGI stuff
    # source set_pgi.sh # or do this manually
    export PGI="/opt/pgi"
    export PATH="/opt/pgi/linux86-64/18.10/bin:$PATH"
    export MANPATH="$MANPATH:/opt/pgi/linux86-64/18.10/man"
    export LM_LICENSE_FILE="/opt/pgi/license.dat-COMMUNITY-18.10"
    # Isca modeling stuff
    export GFDL_BASE=$HOME/isca
    export GFDL_ENV=monde # "environment" configuration for emps-gv4
    export GFDL_WORK=/mdata1/ldavis/isca_work # temporary working directory used in running the model
    export GFDL_DATA=/mdata1/ldavis/isca_data # directory for storing model output
    # The Euclid/Gauss servers do not have NCL, so need to use conda
    # Monde has NCL installed already
    export NCARG_ROOT="/usr/local" # use the version located here

  # Chicago supercomputer, any of the login nodes
  ;; midway*)
    # Default bashrc setup
    export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" # need to start here, or get error
    source /etc/bashrc
    # Module load and stuff
    # NOTE: Use 'sinteractive' for interactive mode
    # module purge 2>/dev/null
    _loaded=($(module --terse list 2>&1)) # already loaded
    _toload=(Anaconda3 intel mkl) # for some reason latest CDO version is not default
    for _module in ${_toload[@]}; do
      if [[ ! " ${_loaded[@]} " =~ "$_module" ]]; then
        module load $_module
      fi
    done
    # Fix prompt
    export PROMPT_COMMAND="$(echo $PROMPT_COMMAND | sed 's/printf.*";//g')"

  # Cheyenne supercomputer, any of the login nodes
  ;; cheyenne*)
    # Edit library path, path
    export LD_LIBRARY_PATH="/glade/u/apps/ch/opt/netcdf/4.6.1/intel/17.0.1/lib:$LD_LIBRARY_PATH"
    # Set tmpdir; following direction of: https://www2.cisl.ucar.edu/user-support/storing-temporary-files-tmpdir
    export TMPDIR=/glade/scratch/$USER/tmp
    # Load some modules
    # NOTE: Use 'qinteractive' for interactive mode
    _loaded=($(module --terse list 2>&1)) # already loaded
    _toload=(nco tmux) # have latest greatest versions of CDO and NCL via conda
    for _module in ${_toload[@]}; do
      if [[ ! " ${_loaded[@]} " =~ "$_module" ]]; then
        module load $_module
      fi
    done
  # Otherwise
  ;; *) echo "\"$HOSTNAME\" does not have custom settings. You may want to edit your \".bashrc\"."
  ;; esac
fi

# Access custom executables
# No longer will keep random executables loose in homre directory; put everything here
export PATH="$HOME/bin:$PATH"

# Homebrew; save path before adding anaconda
# Brew conflicts with anaconda (try "brew doctor" to see)
alias brew="PATH=\"$PATH\" brew"

# Include modules (i.e. folders with python files) located in the home directory
# Also include python scripts in bin
export PYTHONPATH="$HOME/bin:$HOME:$PYTHONPATH"
export PYTHONBREAKPOINT=IPython.embed # use ipython for debugging! see: https://realpython.com/python37-new-features/#the-breakpoint-built-in

# Matplotlib stuff
# May be necessary for rendering fonts in ipython notebooks
# See: https://github.com/olgabot/sciencemeetproductivity.tumblr.com/blob/master/posts/2012/11/how-to-set-helvetica-as-the-default-sans-serif-font-in.md
export MPLCONFIGDIR=$HOME/.matplotlib
printf "done\n"

################################################################################
# Anaconda stuff
################################################################################
_conda=
if [ -d "$HOME/anaconda3" ]; then
  _conda='anaconda3'
elif [ -d "$HOME/miniconda3" ]; then
  _conda='miniconda3'
fi
if [ -n "$_conda" ]; then
  # For info on what's going on see: https://stackoverflow.com/a/48591320/4970632
  # The first thing creates a bunch of environment variables and functions
  # The second part calls the 'conda' function, which calls an activation function, which does the
  # whole solving environment thing
  # If you use the '. activate' version, there is an 'activate' file in bin
  # that does these two things
  _bashrc_message "Enabling conda"
  source $HOME/$_conda/etc/profile.d/conda.sh # set up environment variables
  conda activate # activate the default environment
  printf "done\n"
fi

################################################################################
# Wrappers for common functions
################################################################################
_bashrc_message "Functions and aliases"
# Append prompt command
_prompt() { # input argument should be new command
  export PROMPT_COMMAND="$(echo "$PROMPT_COMMAND; $1" | sed 's/;[ \t]*;/;/g;s/^[ \t]*;//g')"
}

# Neat function that splits lines into columns so they fill the terminal window
_columnize() {
  local cmd
  local input output final
  local tcols ncols maxlen nlines
  [ $# -eq 0 ] && input="$(cat /dev/stdin)" || input="$1"
  ! $_macos && cmd=wc || cmd=gwc
  ncols=1 # start with 1
  tcols=$(tput cols)
  maxlen=0 # initial
  nlines=$(printf "$input" | $cmd -l) # check against initial line count
  output="$input" # default
  while true; do
    final="$output" # record previous output, this is what we will print
    output=$(printf "$input" | xargs -n$ncols | column -t)
    maxlen=$(printf "$output" | $cmd -L)
    # maxlen=$(printf "$output" | awk '{print length}' | sort -nr | head -1) # or wc -L but that's unavailable on mac
    [ $maxlen -gt $tcols ] && break # this time *do not* print latest result, will result in line break due to terminal edge
    [ $ncols -gt $nlines ] && final="$output" && break # test *before* increment, want to use that output
    # echo terminal $tcols ncols $ncols nlines $nlines maxlen $maxlen
    let ncols+=1
  done
  printf "$final"
}

# Help page wrapper
# See this page for how to avoid recursion when wrapping shell builtins and commands:
# http://blog.jpalardy.com/posts/wrapping-command-line-tools/
# Don't want to use aliases, e.g. because ncl requires DYLD_LIBRARY_PATH to open
# so we alias that as command prefix (don't want to change global path cause it
# messes other shit up, maybe homebrew)
help() {
  local arg="$@"
  [ -z "$arg" ] && echo "Requires argument." && return 1
  if builtin help "$arg" &>/dev/null; then
    builtin help "$arg" 2>&1 | less
  elif $arg --help &>/dev/null; then
    $arg --help 2>&1 | less # combine output streams or can get weird error
  else
    echo "No help information for \"$arg\"."
  fi
}

# Man page wrapper
man() { # always show useful information when man is called
  # See this answer and comments: https://unix.stackexchange.com/a/18092/112647
  # Note Mac will have empty line then BUILTIN(1) on second line, but linux will
  # show as first line BASH_BUILTINS(1); so we search the first two lines
  # if command man $1 | sed '2q;d' | grep "^BUILTIN(1)" &>/dev/null; then
  local arg="$@"
  [[ "$arg" =~ " " ]] && arg="$(echo $arg | tr '-' ' ')"
  [ -z $1 ] && echo "Requires one argument." && return 1
  if command man $1 2>/dev/null | head -2 | grep "BUILTIN" &>/dev/null; then
    if $_macos; then # mac shows truncated manpage/no extra info; need the 'bash' manpage for full info
      [ $1 == "builtin" ] && local search=$1 || local search=bash
    else local search=$1 # linux shows all info necessary, just have to find it
    fi
    echo "Searching for stuff in ${search}."
    LESS=-p"^ *${1}.*\[.*$" command man $search
    # LESS=-p"^ *$1 \[.*$" command man $search
  elif command man $1 &>/dev/null; then
    echo "Item has own man page."
    command man $1
  else
    echo "No man entry for \"$1\"."
  fi
}

# Editor stuff
# VIM command to keep track of session -- need to 'source' the sessionfile, which is
# just a bunch of commands in Vimscript. Also make a *patch* to stop folds from
# re-closing every time we start a session
vim() {
  # First modify the Obsession-generated session file
  # Then restore the session; in .vimrc specify same file for writing, so this 'resumes'
  # tracking in the current session file
  local session=.vimsession
  local flags files
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -*) flags+=("$1") ;;
       *) files+=("$1")  ;;
    esac
    shift
 done
  if [[ "${#files[@]}" -eq 0 ]] && [[ -r "$session" ]]; then
    # Fix various Obsession bugs
    # Unfold stuff after entering each buffer; for some reason folds are otherwise
    # re-closed upon openening each file
    # Also prevent double-loading, possibly Obsession expects different workflow/does
    # not anticipate :tabedit commands, ends up loading everything *twice*
    # Check out: cat $session | grep -n -E 'fold|zt'
    $_macos && _sed='gsed' || _sed='sed' # only GNU sed works here
    $_sed -i '/zt/a setlocal nofoldenable' $session
    $_sed -i 's/^[0-9]*,[0-9]*fold$//g' $session
    $_sed -i 's/^if bufexists.*$//g' $session
    $_sed -i -s 'N;/normal! zo/!P;D' $session
    $_sed -i -s 'N;/normal! zc/!P;D' $session
    command vim "${flags[@]}" -S $session # for working with obsession
  else
    command vim "${flags[@]}" -p "${files[@]}" # when loading specific files; also open them in separate tabs
  fi
  clear # clear screen after exit
}

# Open files optionally based on name, or revert to default behavior
# if -a specified
open() {
  local files app app_default
  while [[ $# -gt 0 ]]; do
    case $1 in
      -a|--application) app_default="$2"; shift; shift; ;;
      -*) echo "Error: Unknown flag $1." && return 1 ;;
      *)  files+=($1); shift; ;;
    esac
  done
  echo ${files[@]}
  for file in "${files[@]}"; do
    if [ -z "$app_default" ]; then
      case "$file" in
        *.pdf|*.svg|*.jpg|*.jpeg|*.png) app="Preview.app" ;;
        *.nc|*.nc[1-7]|*.df|*.hdf[1-5]) app="Panoply.app" ;;
        *.html|*.xml|*.htm|*.gif) app="Chromium.app" ;;
        *.mov|*.mp4) app="VLC.app" ;;
        *.md) app="Marked 2.app" ;;
        *)    app="TextEdit.app" ;;
      esac
    else
      app="$app_default"
    fi
    echo "Opening file \"$file\"."
    command open -a "$app" $file
  done
}

# Environment variables
export LC_ALL=en_US.UTF-8 # needed to make Vim syntastic work
export EDITOR=vim # default editor, nice and simple

################################################################################
# SHELL BEHAVIOR, KEY BINDINGS
################################################################################
# Readline/inputrc settings
# Use Ctrl-R to search previous commands
# Equivalent to putting lines in single quotes inside .inputrc
# bind '"\C-i":glob-expand-word' # expansion but not completion
_setup_bindings() {
  complete -r # remove completions
  bind -r '"\C-i"'
  bind -r '"\C-d"'
  bind -r '"\C-s"' # to enable C-s in Vim (normally caught by terminal as start/stop signal)
  bind 'set disable-completion off'          # ensure on
  bind 'set completion-ignore-case on'       # want dat
  bind 'set completion-map-case on'          # treat hyphens and underscores as same
  bind 'set show-all-if-ambiguous on'        # one tab press instead of two; from this: https://unix.stackexchange.com/a/76625/112647
  bind 'set menu-complete-display-prefix on' # show string typed so far as 'member' while cycling through completion options
  bind 'set completion-display-width 1'      # easier to read
  bind 'set bell-style visible'              # only let readlinke/shell do visual bell; use 'none' to disable totally
  bind 'set skip-completed-text on'          # if there is text to right of cursor, make bash ignore it; only bash 4.0 readline
  bind 'set visible-stats off'               # extra information, e.g. whether something is executable with *
  bind 'set page-completions off'            # no more --more-- pager when list too big
  bind 'set completion-query-items 0'        # never ask for user confirmation if there's too much stuff
  bind 'set mark-symlinked-directories on'   # add trailing slash to directory symlink
  bind '"\C-i": menu-complete'               # this will not pollute scroll history; better
  bind '"\e-1\C-i": menu-complete-backward'  # this will not pollute scroll history; better
  bind '"\e[Z": "\e-1\C-i"'                  # shift tab to go backwards
  bind '"\C-l": forward-char'
  bind '"\C-s": beginning-of-line' # match vim motions
  bind '"\C-e": end-of-line'       # match vim motions
  bind '"\C-h": backward-char'     # match vim motions
  bind '"\C-w": forward-word'      # requires
  bind '"\C-b": backward-word'     # by default c-b moves back one word, and deletes it
  bind '"\eOP": menu-complete'          # history
  bind '"\eOQ": menu-complete-backward' # history
  bind '"\C-j": next-history'
  bind '"\C-k": previous-history'  # history
  bind '"\C-j": next-history'
  bind '"\C-p": previous-history'  # history
  bind '"\C-n": next-history'
  stty werase undef # no more ctrl-w word delete function; allows c-w re-binding to work
  stty stop undef   # no more ctrl-s
  stty eof undef    # no more ctrl-d
}
_setup_bindings 2>/dev/null # ignore any errors

# Shell Options
# Check out 'shopt -p' to see possibly interesting shell options
# Note diff between .inputrc and .bashrc settings: https://unix.stackexchange.com/a/420362/112647
_setup_opts() {
  # Turn off history expansion, so can use '!' in strings; see: https://unix.stackexchange.com/a/33341/112647
  set +H
  # No more control-d closing terminal
  set -o ignoreeof
  # Disable start/stop output control
  stty -ixon # note for putty, have to edit STTY value and set ixon to zero in term options
  # Exit this script when encounter error, and print each command; useful for debugging
  # set -ex
  # Various shell options
  shopt -s cmdhist                 # save multi-line commands as one command in shell history
  shopt -s checkwinsize            # allow window resizing
  shopt -u nullglob                # turn off nullglob; so e.g. no null-expansion of string with ?, * if no matches
  shopt -u extglob                 # extended globbing; allows use of ?(), *(), +(), +(), @(), and !() with separation "|" for OR options
  shopt -u dotglob                 # include dot patterns in glob matches
  shopt -s direxpand               # expand dirs
  shopt -s dirspell                # attempt spelling correction of dirname
  shopt -s cdspell                 # spelling errors during cd arguments
  shopt -s cdable_vars             # cd into shell variable directories, no $ necessary
  shopt -s nocaseglob              # case insensitive
  shopt -s autocd                  # typing naked directory name will cd into it
  shopt -s no_empty_cmd_completion # no more completion in empty terminal!
  shopt -s histappend              # append to the history file, don't overwrite it
  shopt -s cmdhist                 # save multi-line commands as one command
  shopt -s globstar                # **/ matches all subdirectories, searches recursively
  shopt -u failglob                # turn off failglob; so no error message if expansion is empty
  # shopt -s nocasematch # don't want this; affects global behavior of case/esac, and [[ =~ ]] commands
  # Related environment variables
  export HISTIGNORE="&:[ ]*:return *:exit *:cd *:source *:. *:bg *:fg *:history *:clear *" # don't record some commands
  export PROMPT_DIRTRIM=2 # trim long paths in prompt
  export HISTSIZE=50000
  export HISTFILESIZE=10000 # huge history -- doesn't appear to slow things down, so why not?
  export HISTCONTROL="erasedups:ignoreboth" # avoid duplicate entries
}
_setup_opts 2>/dev/null # ignore if option unavailable

################################################################################
# Aliases/functions for printing out information
################################################################################
# The -X show bindings bound to shell commands (i.e. not builtin readline functions, but strings specifying our own)
# The -s show bindings 'bound to macros' (can be combination of key-presses and shell commands)
# NOTE: Example for finding variables:
# for var in $(variables | grep -i netcdf); do echo ${var}: ${!var}; done
# NOTE: See: https://stackoverflow.com/a/949006/4970632
alias aliases="compgen -a"
alias variables="compgen -v"
alias functions="compgen -A function" # show current shell functions
alias builtins="compgen -b" # bash builtins
alias commands="compgen -c"
alias keywords="compgen -k"
alias modules="module avail 2>&1 | cat "
if $_macos; then
  alias bindings="bind -Xps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort" # print keybindings
  alias bindings_stty="stty -e"                # bindings
else
  alias bindings="bind -ps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort" # print keybindings
  alias bindings_stty="stty -a"                # bindings
fi
alias inputrc_ops="bind -v"           # the 'set' options, and their values
alias inputrc_funcs="bind -l"         # the functions, for example 'forward-char'
env() { set; } # just prints all shell variables

################################################################################
# General utilties
################################################################################
# Configure ls behavior, define colorization using dircolors
if [ -r "$HOME/.dircolors.ansi" ]; then
  $_macos && _dc_command=gdircolors || _dc_command=dircolors
  eval "$($_dc_command $HOME/.dircolors.ansi)"
fi
$_macos && _ls_command='gls' || _ls_command='ls'
alias ls="clear && $_ls_command --color=always -AF"   # ls useful (F differentiates directories from files)
alias ll="clear && $_ls_command --color=always -AFhl" # ls "list", just include details and file sizes
alias cd="cd -P" # don't want this on my mac temporarily
alias log="tail -f" # only ever use this command to watch logfiles in realtime
alias ctags="ctags --langmap=vim:+.vimrc,sh:+.bashrc" # permanent lang maps

# Information on directories
! $_macos && alias hardware="cat /etc/*-release" # print out Debian, etc. release info
! $_macos && alias cores="cat /proc/cpuinfo | awk '/^processor/{print \$3}' | wc -l"
alias df="df -h" # disk useage
alias eject="diskutil unmount 'NO NAME'" # eject disk on macOS, default to this name
# Directory sizes, normal and detailed, analagous to ls/ll
alias du='du -h -d 1' # also a better default du
ds() {
  local dir
  [ -z $1 ] && dir="." || dir="$1"
  find "$dir" -maxdepth 1 -mindepth 1 -type d -print | sed 's|^\./||' | sed 's| |\\ |g' | _columnize
}
dl() {
  local cmd dir
  [ -z $1 ] && dir="." || dir="$1"
  ! $_macos && cmd=sort || cmd=gsort
  find "$dir" -maxdepth 1 -mindepth 1 -type d -exec du -hs {} \; | sed $'s|\t\./|\t|' | sed 's|^\./||' | $cmd -sh
}
# Find but ignoring hidden folders and stuff
alias homefind="find . -type d \( -path '*/\.*' -o -path '*/*conda3' -o -path '*/[A-Z]*' \) -prune -o"

# Convert bytes to human
# From: https://unix.stackexchange.com/a/259254/112647
# NOTE: Used to use this in a couple awk scripts in git config
# aliases and other tools, so used export -f bytes2human. This causes errors
# when intering interactive node on supercomputer, so forget it.
bytes2human() {
  if [ $# -gt 0 ]; then
    nums="$@"
  else
    nums="$(cat /dev/stdin)"
  fi
  for i in $nums; do
    b=${i:-0}; d=''; s=0; S=(Bytes {K,M,G,T,P,E,Z,Y}iB)
    # b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,P,E,Z,Y}iB)
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    echo "$b$d${S[$s]}"
    # echo "$b$d$ {S[$s]}"
  done
}

# Grepping and diffing; enable colors
alias grep="grep --exclude-dir=_site --exclude-dir=plugged --exclude-dir=.git --exclude-dir=.svn --color=auto"
alias egrep="egrep --exclude-dir=_site --exclude-dir=plugged --exclude-dir=.git --exclude-dir=.svn --color=auto"
hash colordiff 2>/dev/null && alias diff="command colordiff" # use --name-status to compare directories

# Query files
todo() { for f in $@; do echo "File: $f"; grep -i '\btodo\b' "$f"; done; }
note() { for f in $@; do echo "File: $f"; grep -i '\bnote:' "$f"; done; }

# Shell scripting utilities
calc()  { bc -l <<< "$(echo $@ | tr 'x' '*')"; } # wrapper around bc, make 'x'-->'*' so don't have to quote glob all the time!
join()  { local IFS="$1"; shift; echo "$*"; }    # join array elements by some separator
clear!() { for i in {1..100}; do echo; done; clear; } # print bunch of empty liens
abspath() { # abspath that works on mac, Linux, or anything with bash
  if [ -d "$1" ]; then
    (cd "$1"; pwd)
  elif [ -f "$1" ]; then
    if [[ "$1" = /* ]]; then
      echo "$1"
    elif [[ "$1" == */* ]]; then
      echo "$(cd "${1%/*}"; pwd)/${1##*/}"
    else
      echo "$(pwd)/$1"
    fi
  fi
}

# Controlling and viewing running processes
alias toc="mpstat -P ALL 1" # like top, but for each core
alias restarts="last reboot | less"
# List shell processes using ps (will include background processes initiated
# by shell scripts, not just ones sent to background by this shell)
tos() {
  ps | sed "s/^[ \t]*//" | tr -s ' ' | grep -v -e PID -e 'bash' -e 'grep' -e 'ps' -e 'sed' -e 'tr' -e 'cut' -e 'xargs' \
     | grep "$1" | cut -d' ' -f1,4
}
# Kill jobs by name
pskill() {
  local strs
  $_macos && echo "Error: GNU ps not available, and macOS grep lists not just processes started in this shell. Don't use on macOS." && return 1
  [ $# -ne 0 ] && strs=($@) || strs=(all)
  for str in ${strs[@]}; do
    echo "Killing $str jobs..."
    [ $str == 'all' ] && str=""
    kill $(tos "$str" | cut -d' ' -f1 | xargs) 2>/dev/null
  done
}
 # Kill jobs with the percent sign thing; NOTE background processes started by scripts not included!
jkill() {
  local count=$(jobs | wc -l | xargs)
  for i in $(seq 1 $count); do
    echo "Killing job $i..."
    eval "kill %$i"
  done
}
# Kill PBS processes all at once; useful when debugging stuff, submitting teeny
# jobs. The tail command skips first (n-1) lines.
qkill() {
  local proc
  for proc in $(qstat | tail -n +3 | cut -d' ' -f1 | cut -d. -f1); do
    qdel $proc
    echo "Deleted job $proc"
  done
}
# Other convenient aliases; remove logs, and better qstat command
alias qrm="rm ~/*.[oe][0-9][0-9][0-9]* ~/.qcmd*" # remove (empty) job logs
alias qls="qstat -f -w | grep -v '^[[:space:]]*[A-IK-Z]' | grep -E '^[[:space:]]*$|^[[:space:]]*[jJ]ob|^[[:space:]]*resources|^[[:space:]]*queue|^[[:space:]]*[mqs]time' | less"
# alias qls="qstat -f -w | grep -v '^[[:space:]]*[A-IK-Z]' | grep -E -v 'etime|pset|project|substate|server|ctime|Job_Owner|Join_Path|comment|umask|exec|mem|jobdir|cpupercent'"
# alias qls="qstat -f -w | grep -v '^[[:space:]]*[A-IK-Z]' | grep -v 'Join'"

# Differencing stuff, similar git commands stuff
# First use git as the difference engine; disable color
# Color not useful anyway; is just bold white, and we delete those lines
gdiff() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  # git --no-pager diff --no-index --no-color "$1" "$2" 2>&1 | sed '/^diff --git/d;/^index/d' \
  #   | grep -E '(files|differ|$|@@.*|^\+*|^-*)' # add to these
  git --no-pager diff --no-index "$1" "$2"
}
# Next use builtin diff command as engine
# *Different* files
# The last grep command is to highlight important parts
ddiff() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  command diff -x '.vimsession' -x '*.sw[a-z]' --brief \
    --exclude='*.git*' --exclude='*.svn*' \
    --strip-trailing-cr -r "$1" "$2" \
    | grep -E '(Only in.*:|Files | and |differ| identical)'
}
# *Identical* files in two directories
idiff() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  command diff -s -x '.vimsession' -x '*.sw[a-z]' --brief --strip-trailing-cr -r "$1" "$2" | grep identical \
    | grep -E '(Only in.*:|Files | and | differ| identical)'
}

# Merge fileA and fileB into merge.{ext}
# See this answer: https://stackoverflow.com/a/9123563/4970632
merge() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  [[ ! -r $1 || ! -r $2 ]] && echo "Error: One of the files is not readable." && return 1
  local ext="" # no extension
  if [[ ${1##*/} =~ '.' || ${2##*/} =~ '.' ]]; then
    [ ${1##*.} != ${2##*.} ] && echo "Error: Files must have same extension." && return 1
    local ext=.${1##*.}
  fi
  touch tmp$ext # use empty file as the 'root' of the merge
  cp $1 backup$ext
  git merge-file $1 tmp$ext $2 # will write to file 1
  mv $1 merge$ext
  mv backup$ext $1
  rm tmp$ext
  echo "Files merged into \"merge$ext\"."
}

################################################################################
# Supercomputer tools
# Add to these
################################################################################
alias suser="squeue -u $USER"
alias sjobs="squeue -u $USER | tail -1 | tr -s ' ' | cut -s -d' ' -f2 | tr -d '[:alpha:]'"

################################################################################
# Website tools
################################################################################
# Use 'brew install ruby-bundler nodejs' then 'bundle install' first
# See README.md in website directory
# Ignore standard error because of annoying deprecation warnings; see:
# https://github.com/academicpages/academicpages.github.io/issues/54
# jupyter nbconvert --to html
# A template idea:
# http://briancaffey.github.io/2016/03/14/ipynb-with-jekyll.html
# Another template idea:
# http://www.leeclemmer.com/2017/07/04/how-to-publish-jupyter-notebooks-to-your-jekyll-static-website.html
# For fixing tiny font size in code cells see
# http://purplediane.github.io/jekyll/2016/04/10/syntax-hightlighting-in-jekyll.html
# Note CSS variables are in _sass/_variables
alias server="bundle exec jekyll liveserve --config '_config.yml,_config.dev.yml' 2>/dev/null"
nbweb() {
  [ $# -ne 1 ] && echo "Error: Need one input arg." && return 1
  local template name root dir md
  root=$HOME/website
  template=$root/nbtemplate.tpl
  path=$root/_tools/files
  base=${1%.ipynb}
  base=${base##*/}
  md="$path/$base".md
  jupyter nbconvert --to=markdown --template=$template --output-dir=$path $1
  gsed -i "s:${base}_files:/tools/files/${base}_files:g" $md
  # gsed -i "s:${base}_files:../files/${base}_files:g" $md
  # jupyter nbconvert --to markdown $1 --config $root/jekyll.py
  # jupyter nbconvert --to markdown --output-dir $path $1
}

################################################################################
# SSH, session management, and Github stuff
# Note: enabling files with spaces is tricky, need: https://stackoverflow.com/a/20364170/4970632
# 1) Basically have to escape the string "twice"; once in this shell, and again once re-interpreted by
# destination shell... however we ACTUALLY *DO* WANT THE TILDE TO EXPAND
# 2) Another weird thing; note we must ESCAPE TILDE IN A PARAMETER EXPANSION, even
# though this is not necessary in double quotes alone; makes sense... maybe...
# 3) BEWARE: replacing string with tilde in parameter expansion behaves DIFFERENTLY
# ACROSS DIFFERENT VERSIONS OF BASH. Test this with foo=~/data, foobar="${foo/#$HOME/~}".
#   * On Gauss (bash 4.3), you need to escape the tilde or surround it by quotes.
#   * On Mac (bash 4.4) and Euclid (bash 4.2), the escape \ or quotes "" are interpreted literally; need tilde by itself.
################################################################################
# Declare some names for active servers
# For cheyenne, to hook up to existing screen/tmux sessions, pick one
# of the 1-6 login nodes -- from testing seems node 4 is usually most
# empty (probably human psychology thing; 3 seems random, 1-2 are obvious
# first and second choices, 5 is nice round number, 6 is last node)
gauss="ldavis@gauss.atmos.colostate.edu"
monde="ldavis@monde.atmos.colostate.edu"
cheyenne="davislu@cheyenne5.ucar.edu"
euclid="ldavis@euclid.atmos.colostate.edu"
olbers="ldavis@olbers.atmos.colostate.edu"
zephyr="lukelbd@zephyr.meteo.mcgill.ca"
midway="t-9841aa@midway2-login1.rcc.uchicago.edu" # pass: orkalluctudg
archive="ldm@ldm.atmos.colostate.edu"             # user: atmos-2012
ldm="ldm@ldm.atmos.colostate.edu"                 # user: atmos-2012

# SSH file system
# For how to install sshfs/osxfuse see: https://apple.stackexchange.com/a/193043/214359
# For pros and cons see: https://unix.stackexchange.com/q/25974/112647
# For how to test for empty directory see: https://superuser.com/a/352387/506762
# Idea is we use the mount to *transfer files back and forth*, or for example
# to view files on Mac/use Mac tools like Panoply to play with files
isempty() {
  if [ -d "$1" ]; then
    local contents=($(find "$1" -maxdepth 1 -mindepth 1 2>/dev/null))
    if [ ${#contents[@]} == 0 ]; then
      return 0 # nothing inside
    elif [ ${#contents[@]} == 1 ] && [ ${contents##*/} == .DS_Store ]; then
      return 0 # this can happen even if you delete all files
    else
      return 1
    fi
  else
    return 0 # does not exist, so is empty
  fi
}
mount() {
  # Mount remote server by name (using the names declared above)
  local server address
  ! $_macos && echo "Error: This should be run from your macbook." && return 1
  [ $# -ne 1 ] && echo "Error: Function sshfs() requires exactly 1 argument." && return 1
  # Detect aliases
  server="$1"
  location="$server"
  case "$server" in
    glade) server=cheyenne ;;
  esac
  # Get address
  address="${!server}" # evaluates the variable name passed
  echo "Server: $server"
  echo "Address: $address"
  [ -z "$server" ] && echo "Error: Unknown server \"$server\". Consider adding it to .bashrc." && return 1
  if ! isempty "$HOME/$server"; then
    echo "Error: Directory \"$HOME/$server\" already exists, and is non-empty!" && return 1
  fi
  # Directory on remote server
  # NOTE: Using tilde ~ does not seem to work
  local dir
  case $location in
    glade*)    location="/glade/scratch/davislu" ;;
    cheyenne*) location="/glade/u/home/davislu" ;;
    *)         location="/home/ldavis" ;;
  esac
  # Options meant to help speed up connection
  # See discussion: https://superuser.com/q/344255/506762
  # Also see blogpost: https://www.smork.info/blog/2013/04/24/entry130424-163842.html
  # -ocache_timeout=115200 \
  # -oattr_timeout=115200 \
  # -ociphers=arcfour \
  # -oauto_cache,reconnect,defer_permissions,noappledouble,nolocalcaches,no_readahead \
  # -oauto_cache,reconnect,defer_permissions \
  command sshfs "$address:$location" "$HOME/$server" \
    -ocache_timeout=115200 -oattr_timeout=115200 \
    -ocompression=no \
    -ovolname="$server"
}
unmount() { # name 'unmount' more intuitive than 'umount'
  # WARNING: Need to be super careful server is not empty and we accidentally rm -r $HOME!
  ! $_macos && echo "Error: This should be run from your macbook." && return 1
  server="$1"
  [ -z "$server" ] && echo "Error: Function usshfs() requires exactly 1 argument." && return 1
  echo "Server: $server"
  command umount "$HOME/$server" &>/dev/null
  if [ $? -ne 0 ]; then
    echo "Error: Server name \"$server\" does not seem to be mounted in \"$HOME\"."
  elif ! isempty "$HOME/$server"; then
    echo "Warning: Leftover mount folder appears to be non-empty!"
  else
    rm -r "$HOME/$server"
  fi
}

# Short helper functions
# See current ssh connections
alias connections="ps aux | grep -v grep | grep 'ssh '"
# View address
ip() {
  # Get the ip address; several weird options for this
  if ! $_macos; then
    # See this: https://stackoverflow.com/q/13322485/4970632
    # command ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'
    command ip route get 1 | awk '{print $NF;exit}'
  else
    # See this: https://apple.stackexchange.com/q/20547/214359
    ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}' 
  fi
}
# String parsing
_expanduser() { # turn tilde into $HOME
  local param="$*"
  param="${param/#~/$HOME}"  # restore expanded tilde
  param="${param/#\~/$HOME}" # if previous one failed/was re-expanded, need to escape the tilde
  echo $param
}
_compressuser() { # turn $HOME into tilde
  local param="$*"
  param="${param/#$HOME/~}"
  param="${param/#$HOME/\~}"
  echo $param
}
# Disable connection over some port; see: https://stackoverflow.com/a/20240445/4970632
disconnect() {
  local pids port=$1
  [ $# -ne 1 ] && echo "Error: Function requires exactly 1 arg." && return 1
  # lsof -t -i tcp:$port | xargs kill # this can accidentally kill Chrome instance
  pids="$(lsof -i tcp:$port | grep ssh | sed "s/^[ \t]*//" | tr -s ' ' | cut -d' ' -f2 | xargs)"
  [ -z "$pids" ] && echo "Error: Connection over port \"$port\" not found." && return 1
  kill $pids # kill the SSH processes
  echo "Processes $pids killed. Connections over port $port removed."
}

# Trigger ssh-agent if not already running, and add Github private key
# Make sure to make private key passwordless, for easy login; all I want here
# is to avoid storing plaintext username/password in ~/.git-credentials, but
# free private key is fine
# * See: https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux
#   The AUTH_SOCK idea came from: https://unix.stackexchange.com/a/90869/112647
# * Used to just ssh-add on every login, but that starts fantom ssh-agent
#   processes that persist when terminal is closed (all the 'eval' does is
#   set environment variables; ssh-agent without the eval just starts the
#   process in background).
# * Now we re-use pre-existing agents with: https://stackoverflow.com/a/18915067/4970632
SSH_ENV="$HOME/.ssh/environment"
killssh() {
  # kill $(ps aux | grep ssh-agent | tr -s ' ' | cut -d' ' -f2 | xargs)
  kill $(ps aux | grep ssh-agent | grep -v grep | awk '{print $2}')
}
initssh() {
  if [ -f "$HOME/.ssh/id_rsa_github" ]; then
    command ssh-agent | sed 's/^echo/#echo/' >"$SSH_ENV"
    chmod 600 "${SSH_ENV}"
    source "${SSH_ENV}" >/dev/null
    command ssh-add "$HOME/.ssh/id_rsa_github" &>/dev/null # add Github private key; assumes public key has been added to profile
  else
    echo "Warning: Github private SSH key \"$HOME/.ssh/id_rsa_github\" is not available." && return 1
  fi
}
# Source SSH settings, if applicable
if ! $_macos; then # only do this if not on macbook
  if [ -f "$SSH_ENV" ]; then
    . "$SSH_ENV" >/dev/null
    ps -ef | grep $SSH_AGENT_PID | grep ssh-agent$ >/dev/null || initssh
  else
    initssh
  fi
fi

# Functions for scp-ing from local to remote, and vice versa
# For initial idea see: https://stackoverflow.com/a/25486130/4970632
# For exit on forward see: https://serverfault.com/a/577830/427991
# For why we alias the function see: https://serverfault.com/a/656535/427991
# For enter command then remain in shell see: https://serverfault.com/q/79645/427991
#   * Note this has nice side-effect of eliminating annoying "banner message"
#   * Why iterate from ports 10000 upward? Because is even though disable host key
#     checking, still get this warning message every time.
# Big honking useful wrapper -- will *always* use this to ssh between servers
# WARNING: This function ssh's into the server twice, first to query the available
# port for two-way forwarding, then to ssh in over that port. If the server in question
# *requires* password entry (e.g. Duo authentification), and cannot be configured
# for passwordless login with ssh-copy-id, then need to skip first step.
_port_file=~/.port # file storing port number
alias ssh="_ssh" # other utilities do *not* test if ssh was overwritten by function! but *will* avoid aliases. so, use an alias
_ssh() {
  local port listen port_write title_write
  [ $# -gt 2 ] && echo "Error: This function needs 1 or 2 arguments." && return 1
  listen=22  # default sshd listening port; see the link above
  port=10000 # starting port
  if [ -n "$2" ]; then
    port="$2" # custom
  elif ! [[ $1 =~ cheyenne ]]; then # dynamically find first available port
    echo "Determining port automatically."
    port=$(command ssh "$1" "port=$port
      while netstat -an | grep \"[:.]\$port\" &>/dev/null; do
        let port=\$port+1
      done; echo \$port")
  fi
  port_write="$(_compressuser $_port_file)"
  title_write="$(_compressuser $_title_file)"
  command ssh -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 \
    -X \
    -t -R $port:localhost:$listen $1 \
    "echo $port >$port_write; echo $_title >$title_write; \
    echo \"Port number: ${port}.\"; /bin/bash -i" # enter bash and stay interactive
}
# Copy from <this server> to local macbook
# NOTE: Often want to copy result of glob expansion.
# NOTE: Below, we use the bash parameter expansion ${!#} -->
# 'variable whose name is result of "$#"' --> $n where n is the number
# of args. Also can do math inside param expansion indexing.
rlcp() { # "copy to local (from remote); 'copy there'"
  local port file dest
  $_macos && echo "Error: Function intended to be called from an ssh session." && return 1
  ! [ -r $_port_file ] && echo "Error: Port unavailable." && return 1
  port=$(cat $_port_file)      # port from most recent login
  array=${@:1:$#-1}            # result of user input glob expansion, or just one file
  dest="$(_compressuser ${!#})" # last value
  dest="${dest//\ /\\\ }"      # escape whitespace manually
  echo "(Port $port) Copying ${array[@]} on this server to home server at: $dest..."
  command scp -o StrictHostKeyChecking=no -P$port ${array[@]} ${USER}@localhost:"$dest"
}
# Copy from local macbook to <this server>
lrcp() { # "copy to remote (from local); 'copy here'"
  local port file dest
  $_macos && echo "Error: Function intended to be called from an ssh session." && return 1
  [ $# -ne 2 ] && echo "Error: This function needs exactly 2 arguments." && return 1
  ! [ -r $_port_file ] && echo "Error: Port unavailable." && return 1
  port=$(cat $_port_file)   # port from most recent login
  dest="$2"                 # last value
  file="$(_compressuser $1)" # second to last
  file="${file//\ /\\\ }"   # escape whitespace manually
  echo "(Port $port) Copying $file from home server to this server at: $dest..."
  command scp -o StrictHostKeyChecking=no -P$port ${USER}@localhost:"$file" "$dest"
}

################################################################################
# Setup REPLs
################################################################################
# R utilities
# * Calling R with --slave or --interactive makes quiting totally impossible somehow.
# * The ---always-readline prevents prompt from switching to the default prompt, but
#   also seems to disable ctrl-d for exiting.
alias r="echo 'This is an R REPL.' && command R -q --no-save"
alias R="echo 'This is an R REPL.' && command R -q --no-save"
# alias R="rlwrap --always-readline -A -p"green" -R -S"R> " R -q --no-save"
# Matlab, just a simple alias
alias matlab="matlab -nodesktop -nosplash -r \"run('~/init.m')\""
# NCL interactive environment
# Make sure that we encapsulate any other alias; for example, on Macs, will
# prefix ncl by setting DYLD_LIBRARY_PATH, so want to keep that.
if alias ncl &>/dev/null; then
  eval "$(alias ncl)' -Q -n'"
else
  alias ncl="ncl -Q -n"
fi
# Julia, simple alias
# NOTE: Need revise plugin https://github.com/timholy/Revise.jl to automatically
# update modules like ipython autoreload
alias julia="julia -e 'push!(LOAD_PATH, \"./\"); using Revise' -i -q --color=yes"
$_macos && JULIA="/Applications/Julia-1.0.app/Contents/Resources/julia"
# iPython wrapper -- load your favorite magics and modules on startup
# Have to sed trim the leading spaces to avoid indentation errors
# NOTE: MacOSX backend broken right now:
# https://github.com/matplotlib/matplotlib/pull/11850
# Seems to not yet be in a stable conda release, so stay tuned.
_py_simple=$(echo "
  get_ipython().magic('load_ext autoreload')
  get_ipython().magic('autoreload 2')
  " | sed 's/^ *//g')
_py_complex=$(echo "$_py_simple
  import numpy as np
  import pandas as pd
  import xarray as xr
  " | sed 's/^ *//g')
  # $($_macos && echo "import matplotlib as mpl; mpl.use('MacOSX'); import proplot as plot")
alias iviper="ipython --no-term-title --no-banner --no-confirm-exit --pprint -i -c \"$_py_complex\""
alias ipython="ipython --no-term-title --no-banner --no-confirm-exit --pprint -i -c \"$_py_simple\""
# Perl -- hard to understand, but here it goes:
# * The first args are passed to rlwrap (-A sets ANSI-aware colors, and -pgreen applies green prompt)
# * The next args are perl args; -w prints more warnings, -n is more obscure, and -E
#   evaluates an expression -- say eval() prints evaluation of $_ (default searching and
#   pattern space, whatever that means), and $@ is set if eval string failed so the // checks
#   for success, and if not, prints the error message. This is a build-your-own eval.
iperl() { # see this answer: https://stackoverflow.com/a/22840242/4970632
  echo 'This is a Perl REPL.'
  ! hash rlwrap &>/dev/null && echo "Error: Must install rlwrap." && return 1
  rlwrap -A -p"green" -S"perl> " perl -wnE'say eval()//$@' # rlwrap stands for readline wrapper
}

################################################################################
# Notebook stuff
# * Install nbstripout with 'pip install nbstripout', then add it to the
#   global .gitattributes for automatic stripping of contents.
# * To uninstall nbextensions completely, use `jupyter contrib nbextension uninstall --user` and
#   `pip uninstall jupyter_contrib_nbextensions`; remove the configurator with `jupyter nbextensions_configurator disable`
# * If you have issues where themes are just not changing in Chrome, open Developer tab
#   with Cmd+Opt+I and you can right-click refresh for a hard reset, cache reset
################################################################################
# Wrapper aroung jupyter theme function, much better
_jt_configured=false # theme is not initially setup because takes a long time
_jt() {
  # Choose default themes and font
  # chesterish is best; monokai has green/pink theme;
  # gruvboxd has warm color style; other dark themes too pale (solarizedd is turquoise pale)
  # solarizedl is really nice though; gruvboxl a bit too warm/monochrome
  local jupyter_theme jupyter_font themes
  if [ $# -lt 1 ]; then 
    echo "Choosing jupytertheme automatically based on hostname."
    case $HOSTNAME in
      uriah*)  jupyter_theme=solarizedl;;
      gauss*)  jupyter_theme=gruvboxd;;
      euclid*) jupyter_theme=gruvboxd;;
      monde*)  jupyter_theme=onedork;;
      midway*) jupyter_theme=onedork;;
      *) echo "Error: Unknown default theme for hostname \"$HOSTNAME\"." && return 1 ;;
    esac
  else jupyter_theme="$1"
  fi
  if [ $# -lt 2 ]; then
    export jupyter_font="cousine" # look up available ones online
  else
    export jupyter_font="$2"
  fi
  # Make sure theme is valid
  themes=($(jt -l | sed '1d'))
  [[ ! " ${themes[@]} " =~ " $jupyter_theme " ]] && \
    echo "Error: Theme $jupyter_theme is invalid; choose from ${themes[@]}." && return 1
  jt -cellw 95% -fs 9 -nfs 10 -tfs 10 -ofs 10 -dfs 10 \
    -t $jupyter_theme -f $jupyter_font
}

# This function will establish two-way connection between server and local macbook
# with the same port number (easier to understand that way).
# Will be called whenever a notebook is iniated, and can be called to refresh stale connections.
_connect() {
  # Error checks and declarations
  local server outcome ports exits
  unset _jupyter_port
  $_macos                && echo "Error: This function is intended to run inside ssh sessions."                      && return 1
  ! [ -r $_port_file ]   && echo "Error: File \"$HOME/$_port_file\" not available. Cannot send commands to macbook." && return 1
  ! which ip &>/dev/null && echo "Error: Command \"ip\" not available. Cannot determine this server's address."      && return 1
  # The ip command prints this server's ip address ($hostname doesn't include full url)
  # ssh -f (port-forwarding in background) -N (don't issue command)
  echo "Sending commands to macbook."
  server=$USER@$(ip) # calls my custom function
  [ $? -ne 0 ] && echo "Error: Could not figure out this server's ip address." && return 1
  # Try to establish 2-way connections
  # Can filter to find ports available on host *and* home server, or just iterate
  # through user provided ports -- if the ssh fails, will return error.
  outcome=$(command ssh -t -o StrictHostKeyChecking=no -p $(cat $_port_file) $USER@localhost "
  if [ $# -ne 0 ]; then
    # Just try connecting over input ports
    ports=\"$@\" # could fail when we try to ssh
  else
    # Find available port on this server
    # Warning: Giant subprocess below
    candidates=($(
      for port in $(seq 30000 30020); do
        ! netstat -an | grep "[:.]$port" &>/dev/null && echo $port
      done
      ))
    # Find which of these is available on home server
    ports=${candidates[0]} # initialize
    i=0; while netstat -an | grep \"[:.]\$ports\" &>/dev/null; do
      let i=i+1
      ports=\${candidates[\$i]}
    done
  fi
  # Attempt connections over each port in ports list
  exits=\"\"
  for port in \$ports; do
    command ssh -N -f -L localhost:\$port:localhost:\$port $server &>/dev/null
    exits+=\"\$? \"
  done
  # Finally print stuff that can be easily parsed; try to avoid newlines
  printf \"\$ports\" | tr ' ' '-'
  printf ' '
  printf \"\$exits\" | tr ' ' '-'
  " 2>/dev/null)
  # Parse result
  ports=($(echo $outcome | cut -d' ' -f1 | tr '-' ' ' | xargs))
  exits=($(echo $outcome | cut -d' ' -f2 | tr '-' ' ' | xargs))
  for idx in $(seq 0 $((${#ports[@]}-1))); do
    if [ ${exits[idx]} -eq 0 ]; then
      _jupyter_port=${ports[idx]}
      echo "Connection over port ${ports[idx]} successful."
    else
      echo "Connection over port ${ports[idx]} failed."
    fi
  done
  [ -z "$_jupyter_port" ] && return 1 || return 0
}

# Refresh stale connections from macbook to server
# Simply calls the '_connect' function
reconnect() {
  local ports
  $_macos && echo "Error: This function is intended to run inside ssh sessions." && return 1
  ports=$(ps u | grep jupyter-notebook | tr ' ' '\n' | grep -- --port | cut -d'=' -f2 | xargs)
  if [ -n "$ports" ]; then
    echo "Refreshing jupyter notebook connections over port(s) $ports."
    _connect $ports
  else
    echo "No active jupyter notebooks found."
  fi
}

# Fancy wrapper for declaring notebook
# Will set up necessary port-forwarding connections on local and remote server, so
# that you can just click the url that pops up
notebook() {
  # Set default jupyter theme
  local port
  ! $_jt_configured && \
    echo "Configure jupyter notebook theme." && _jt && _jt_configured=true
  # Create the notebook
  # Need to extend data rate limit when making some plots with lots of stuff
  if [ -n "$1" ]; then
    echo "Initializing jupyter notebook over port $1."
    port="--port=$1"
  elif ! $_macos; then # remote ports will use 3XXXX   
    _connect
    [ $? -ne 0 ] && return 1
    echo "Initializing jupyter notebook over port $_jupyter_port."
    port="--port=$_jupyter_port"
  else # local ports will use 2XXXX
    for port in $(seq 20000 20020); do
      ! netstat -an | grep "[:.]$port" &>/dev/null && break
    done
    echo "Initializing jupyter notebook over port $port."
    port="--port=$port"
  fi
  jupyter notebook --no-browser $port --NotebookApp.iopub_data_rate_limit=10000000
}

################################################################################
# Dataset utilities
################################################################################
# Fortran tools
namelist() {
  [ -z "$1" ] && local file="input.nml" || local file="$1"
  echo "Params in current namelist:"
  cat "$file" | cut -d= -f1 -s | grep -v '!' | xargs
}

# NetCDF tools (should just remember these)
# NCKS behavior very different between versions, so use ncdump instead
#   * note if HDF4 is installed in your anaconda distro, ncdump will point to *that location* before
#     the homebrew install location 'brew tap homebrew/science, brew install cdo'
#   * this is bad, because the current version can't read netcdf4 files; you really don't need HDF4,
#     so just don't install it
# Summaries first
nchelp() {
  echo "Available commands:"
  echo "ncdump ncinfo ncglobal
        ncvarsinfo ncdimsinfo
        ncin ncitems ncvars ncdims
        ncvarinfo ncvardump ncvartable ncvartable2" | column -t
}
ncdump() { # almost always want this; access old versions in functions with backslash
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  command ncdump -h "$@" | less
}
ncglobal() { # show just the global attributes
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  command ncdump -h "$@" | grep -A100 ^// | less
}
ncinfo() { # only get text between variables: and linebreak before global attributes
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  ! [ -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | sed '/^$/q' | sed '1,1d;$d' | less # trims first and last lines; do not need these
}
ncvars() { # get information for just variables (no dimension/global info)
    # the cdo parameter table actually gives a subset of this information, so don't
    # bother parsing that information
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  ! [ -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | grep -A100 "^variables:$" | sed '/^$/q' | \
    sed $'s/^\t//g' | grep -v "^$" | grep -v "^variables:$" | less
    # the space makes sure it isn't another variable that has trailing-substring
    # identical to this variable; and the $'' is how to insert literal tab
    # -A means print x TRAILING lines starting from FIRST match
    # -B means prinx x PRECEDING lines starting from LAST match
}
ncdims() { # just dimensions and their numbers
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  ! [ -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  # command ncdump -h "$1" | grep -B100 "^variables:$" | sed '1,2d;$d' | \
  #   tr -d ';' | tr -s ' ' | column -t
  command ncdump -h "$1" | sed -n '/dimensions:/,$p' | sed '/variables:/q'  | sed '1d;$d' \
      | tr -d ';' | tr -s ' ' | column -t
}

# Listing stuff
ncin() { # simply test membership; exit code zero means variable exists, exit code 1 means it doesn't
  [ $# -ne 2 ] && { echo "two arguments required."; return 1; }
  ! [ -r "$2" ] && { echo "file \"$2\" not found."; return 1; }
  command ncdump -h "$2" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
    | cut -d'=' -f1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | grep "$1" &>/dev/null
}
nclist() { # only get text between variables: and linebreak before global attributes
    # note variables don't always have dimensions! (i.e. constants)
    # in this case looks like " double var ;" instead of " double var(x,y) ;"
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  ! [ -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | sed -n '/variables:/,$p' | sed '/^$/q' | grep -v '[:=]' \
    | cut -d';' -f1 | cut -d'(' -f1 | sed 's/ *$//g;s/.* //g' | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
ncdimlist() { # get list of dimensions
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  ! [ -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
    | cut -d'=' -f1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
ncvarlist() { # only get text between variables: and linebreak before global attributes
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  ! [ -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  # cdo -s showname "$1" # this omits some "weird" variables that don't fit into CDO
  #   # data model, so don't use this approach
  local list=($(nclist "$1"))
  local dmnlist=($(ncdimlist "$1"))
  local varlist=() # add variables here
  for item in "${list[@]}"; do
    if [[ ! " ${dmnlist[@]} " =~ " $item " ]]; then
      varlist+=("$item")
    fi
  done
  echo "${varlist[@]}" | tr -s ' ' '\n' | grep -v '[{}]' | sort # print results
}

# Inquiries about specific variables
ncvarinfo() { # as above but just for one variable
  [ $# -ne 2 ] && { echo "Two arguments required."; return 1; }
  ! [ -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  command ncdump -h "$2" | grep -A100 "[[:space:]]$1(" | grep -B100 "[[:space:]]$1:" | sed "s/$1://g" | sed $'s/^\t//g'
    # the space makes sure it isn't another variable that has trailing-substring
    # identical to this variable; and the $'' is how to insert literal tab
}
ncvardump() { # dump variable contents (first argument) from file (second argument)
  [ $# -ne 2 ] && { echo "Two arguments required."; return 1; }
  ! [ -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  $_macos && _reverse="gtac" || _reverse="tac"
  # command ncdump -v "$1" "$2" | grep -A100 "^data:" | tail -n +3 | $_reverse | tail -n +2 | $_reverse
  command ncdump -v "$1" "$2" | $_reverse | egrep -m 1 -B100 "[[:space:]]$1[[:space:]]" | sed '1,1d' | $_reverse
    # shhh... just let it happen
    # tail -r reverses stuff, then can grep to get the 1st match and use the before flag to print stuff
    # before (need extended grep to get the coordinate name), then trim the first line (curly brace) and reverse
}
ncvartable() { # parses the CDO parameter table; ncvarinfo replaces this
  # Below procedure is ideal for "sanity checks" of data; just test one
  # timestep slice at every level; the tr -s ' ' trims multiple whitespace
  # to single and the column command re-aligns columns
  [ $# -ne 2 ] && { echo "Two arguments required."; return 1; }
  local args=("$@")
  local args=(${args[@]:2}) # extra arguments
  cdo -s infon ${args[@]} -seltimestep,1 -selname,"$1" "$2" | tr -s ' ' | cut -d ' ' -f 6,8,10-12 | column -t 2>&1 | less
}
ncvartable2() { # as above but show everything
  [ $# -ne 2 ] && { echo "Two arguments required."; return 1; }
  ! [ -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  local args=("$@")
  local args=(${args[@]:2}) # extra arguments
  cdo -s infon ${args[@]} -seltimestep,1 -selname,"$1" "$2" 2>&1 | less
}

# Extract generalized files
extract() {
  for name in "$@"; do
      # shell actually passes **already expanded** glob pattern when you call it as argument
      # to a function; so, need to cat all input arguments with @ into list
    if [ -f "$name" ] ; then
      case "$name" in
        *.tar.bz2) tar xvjf "$name"    ;;
        *.tar.xz)  tar xf "$name"      ;;
        *.tar.gz)  tar xvzf "$name"    ;;
        *.bz2)     bunzip2 "$name"     ;;
        *.rar)     unrar x "$name"     ;;
        *.gz)      gunzip "$name"      ;;
        *.tar)     tar xvf "$name"     ;;
        *.tbz2)    tar xvjf "$name"    ;;
        *.tgz)     tar xvzf "$name"    ;;
        *.zip)     unzip "$name"       ;;
        *.Z)       uncompress "$name"  ;;
        *.7z)      7z x "$name"        ;;
        *)         echo "Don't know how to extract '$name'..." ;;
      esac
      echo "'$name' was extracted."
    else
      echo "'$name' is not a valid file!"
    fi
  done
}

################################################################################
# Fancy Colors
################################################################################
# Standardize less/man/etc. colors
# Used this: https://unix.stackexchange.com/a/329092/112647
export LESS="--RAW-CONTROL-CHARS"
[ -f ~/.LESS_TERMCAP ] && . ~/.LESS_TERMCAP
if hash tput 2>/dev/null; then
  export LESS_TERMCAP_md=$'\e[1;33m'     # begin blink
  export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
  export LESS_TERMCAP_us=$'\e[01;37m'    # begin underline
  export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
  export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
  export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
  export GROFF_NO_SGR=1                  # for konsole and gnome-terminal
fi

# Temporarily change iTerm2 profile while REPL or other command is active
# Alias any command with '_cmdcolor' as prefix
# _cmdcolor() {
#   # Get current profile name; courtesy of: https://stackoverflow.com/a/34452331/4970632
#   # Or that's dumb and just use ITERM_PROFILE
#   newprofile=Argonaut
#   oldprofile=$ITERM_PROFILE
#   # Restore the current settings if the user ctrl-c's out of the command
#   trap ctrl_c INT
#   function ctrl_c() {
#     echo -e "\033]50;SetProfile=$oldprofile\a"
#     exit
#   }
#   # Set profile; if you want you can allow profile as $1, then call shift,
#   # and now the remaining command arguments are $@
#   echo -e "\033]50;SetProfile=$newprofile\a"
#   # Note, can use 'command' to avoid function/alias lookup
#   # See: https://stackoverflow.com/a/6365872/4970632
#   "$@" # need to quote it, might need to escape stuff
#   # Restore settings
#   echo -e "\033]50;SetProfile=$oldprofile\a"
# }

# # Magic changing stderr color
# # Turns out that iTerm2 SHELL INTEGRATION mostly handles the idea behind this;
# # want "bad commands" to be more visible
# # See comment: https://stackoverflow.com/a/21320645/4970632
# # See exec summary: https://stackoverflow.com/a/18351547/4970632
# # For trap info: https://www.computerhope.com/unix/utrap.htm
# # But unreliable; there is issue with sometimes no newline generated
# # Uncomment stuff below to restore
# export COLOR_RED="$(tput setaf 1)"
# export COLOR_RESET="$(tput sgr0)"
# exec 9>&2 # copy error descriptor onto write file descriptor 9
# exec 8> >( # open this "process substitution" for writing on descriptor 8
#   # while IFS='' read -r -d $'\0' line || [ -n "$line" ]; do
#   while IFS='' read -r line || [ -n "$line" ]; do
#     echo -e "${COLOR_RED}${line}${COLOR_RESET}" # -n is non-empty; this terminates at end
#   done # "read" reads from standard input (whatever stream fed into this process)
# )
# _undirect(){ echo -ne '\0'; exec 2>&9; } # return stream 2 to "dummy stream" 9
# _undirect(){ exec 2>&9; } # return stream 2 to "dummy stream" 9
# _redirect(){
#   local PRG="${BASH_COMMAND%% *}" # ignore flags/arguments
#   for X in ${STDERR_COLOR_EXCEPTIONS[@]}; do
#     [ "$X" == "${PRG##*/}" ] && return 1; # trim directories
#   done # if special program, don't send to coloring stream
#   exec 2>&8 # send stream 2 to the coloring stream
# }

# # Interactive stuff gets super wonky if you try to _redirect it, so
# # filter these tools out
# trap "_redirect;" DEBUG # trap executes whenever receiving signal <ARG> (here, "DEBUG"==every simple command)
# export PROMPT_COMMAND="_undirect;" # execute this just before prompt PS1 is printed (so after stderr/stdout printing)
# export STDERR_COLOR_EXCEPTIONS=(wget scp ssh mpstat top source .  diff sdsync # commands
#   brew
#   brew\ cask
#   youtube metadata # some scripts
#   \\ipython \\jupyter \\python \\matlab # disabled alias versions
#   node rhino ncl matlab # misc languages; javascript, NCL, matlab
#   cdo conda pip easy_install python ipython jupyter notebook) # python stuff

################################################################################
# Utilities related to preparing PDF documents
# Converting figures between different types, other pdf tools, word counts
################################################################################
# First some simple convsersions
# * Flatten gets rid of transparency/renders it against white background, and
#   the units/density specify a <N>dpi resulting bitmap file. Another option
#   is "-background white -alpha remove", try this.
# * Note the PNAS journal says 1000-1200dpi recommended for line art images
#   and stuff with text.
# * Note imagemagick does *not* handle vector formats; will rasterize output
#   image and embed in a pdf, so cannot flatten transparent components with
#   convert -flatten in.pdf out.pdf
gif2png() {
  for f in "$@";
    do [[ "$f" =~ .gif$ ]] && echo "Converting $f..." && convert "$f" "${f%.gif}.png"
  done
} # often needed because LaTeX can't read gif files
pdf2png() {
  density=1200 args=("$@")
  [[ $1 =~ ^[0-9]+$ ]] && density=$1 args="${args[@]:1}"
  flags="-flatten -units PixelsPerInch -density $density"
  for f in "${args[@]}"; do
    [[ "$f" =~ .pdf$ ]] && echo "Converting $f with ${density}dpi..." && convert $flags "$f" "${f%.pdf}.png"
  done
} # sometimes need bitmap yo
svg2png() {
  pdf2png $@
  density=1200 args=("$@")
  [[ $1 =~ ^[0-9]+$ ]] && density=$1 args="${args[@]:1}"
  flags="-flatten -units PixelsPerInch -density $density -background none"
  for f in "${args[@]}"; do
    [[ "$f" =~ .svg$ ]] && echo "Converting $f with ${density}dpi..." && convert $flags "$f" "${f%.svg}.png"
  done
}
pdf2tiff() {
  density=1200 args=("$@")
  [[ $1 =~ ^[0-9]+$ ]] && density=$1 args="${args[@]:1}"
  flags="-flatten -units PixelsPerInch -density $density"
  for f in "${args[@]}"; do
    [[ "$f" =~ .pdf$ ]] && echo "Converting $f with ${density}dpi..." && convert $flags "$f" "${f%.pdf}.tiff"
  done
} # alternative for converting to bitmap
pdf2eps() {
  args=("$@")
  for f in "${args[@]}"; do
    [[ "$f" =~ .pdf$ ]] && echo "Converting $f..." && \
      pdf2ps "$f" "${f%.pdf}.ps" && ps2eps "${f%.pdf}.ps" "${f%.pdf}.eps" && rm "${f%.pdf}.ps"
  done
}
pdf2flat() {
  # This page is helpful:
  # https://unix.stackexchange.com/a/358157/112647
  # 1. pdftk keeps vector graphics
  # 2. convert just converts to bitmap and eliminates transparency
  # 3. pdf2ps piping retains quality (ps uses vector graphics, but can't do transparency)
  # convert "$f" "${f}_flat.pdf"
  # pdftk "$f" output "${f}_flat.pdf" flatten
  args=("$@")
  for f in "${args[@]}"; do
    [[ "$f" =~ .pdf$ ]] && [[ ! "$f" =~ "flat" ]] && echo "Converting $f..." && \
      pdf2ps "$f" - | ps2pdf - "${f}_flat.pdf"
  done
}

# Extract PDF annotations
# Turned out kind of complicated
unannotate() {
  local _sed
  local original="$1"
  local final="${original%.pdf}_unannotated.pdf"
  [ "${original##*.}" != "pdf" ] && echo "Error: Must input PDF file." && return 1
  $_macos && _sed='gsed' || _sed='sed'
  # Try this from: https://superuser.com/a/428744/506762
  # Actually doesn't work, maybe relied on some particular format; need pdftk uncompression
  # cp "$original" "$final"
  # perl -pi -e 's:/Annots \[[^]]+\]::g' "$final" +
  # See: https://stackoverflow.com/a/49614525/4970632
  # Fix indefinite pdftk hang on macOS: https://stackoverflow.com/q/39750883/4970632
  # Download package instead of Homebrew version; homebrew one is broked
  # The environment variables prevent 'Illegal byte sequence' error
  # on Linux and Mac; see: https://stackoverflow.com/a/23584470/4970632
  pdftk "$original" output uncompressed.pdf uncompress
  LANG=C LC_ALL=C $_sed -n '/^\/Annots/!p' uncompressed.pdf > stripped.pdf
  pdftk stripped.pdf output "$final" compress
  rm uncompressed.pdf stripped.pdf
}

# Rudimentary wordcount with detex
wctex() {
  # Below worked for certain templates:
  # Explicitly delete begin/end environments because detex won't pick them up
  # and use the equals sign to exclude equations
  # detexed="$(cat "$1" | sed '1,/^\\end{abstract}/d;/^\\begin{addendum}/,$d' \
  #   | sed '/^\\begin{/d;/^\\end{/d;/=/d' | detex -c | grep -v .pdf | grep -v 'fig[0-9]' \
  #   | grep -v 'empty' | grep -v '^\s*$')"
  # Below worked for BAMS template, gets count between end of abstract
  # and start of methods
  # The -e flag to ignore certain environments (e.g. abstract environment)
  local detexed="$(cat "$1" | \
    detex -e 'tabular,align,equation,align*,equation*' | grep -v .pdf | grep -v 'fig[0-9]')"
  echo "$detexed" | xargs # print result in one giant line
  echo "$detexed" | wc -w # get word count
}

# ***Other Tools*** are "impressive" and "presentation", and both should be in bin
# Homebrew presentation software; below installs it, from http://pygobject.readthedocs.io/en/latest/getting_started.html
# brew install pygobject3 --with-python3 gtk+3 && /usr/local/bin/pip3 install pympress
alias pympress="LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/python3 /usr/local/bin/pympress"

# This is ***the end*** of all function and alias declarations
printf "done\n"

################################################################################
# FZF fuzzy file completion tool
# See this page for ANSI color information: https://stackoverflow.com/a/33206814/4970632
################################################################################
# Run installation script; similar to the above one
if [ -f ~/.fzf.bash ]; then
  _bashrc_message "Enabling fzf"
  # See man page for --bind information
  # * Mainly use this to set bindings and window behavior; --no-multi seems to have no effect, certain
  #   key bindings will enabled multiple selection
  # * Also very important, bind slash to accept, so now the behavior is very similar
  #   to behavior of normal bash shell completion
  # * Inline info puts the number line thing on same line as text. More compact.
  # * For colors, see: https://stackoverflow.com/a/33206814/4970632
  #   Also see manual; here, '-1' is terminal default, not '0'
  # Completion options don't require export
  unset FZF_COMPLETION_FILE_COMMANDS FZF_COMPLETION_PID_COMMANDS FZF_COMPLETION_DIR_COMMANDS
  unset FZF_COMPLETION_INCLUDE # optional requirement
  FZF_COMPLETION_TRIGGER='' # empty means tab triggers completion, otherwise need '**'
  FZF_COMPLETION_FIND_OPTS="-maxdepth 1 -mindepth 1"
  FZF_COMPLETION_FIND_IGNORE=".DS_Store .vimsession .local anaconda3 miniconda3 plugged __pycache__ .ipynb_checkpoints"
  # Do not override default find command
  unset FZF_DEFAULT_COMMAND
  unset FZF_CTRL_T_COMMAND
  unset FZF_ALT_C_COMMAND
  # Override options, same for every one
  # Builtin options: --ansi --color=bw
  _fzf_opts=$(echo ' --select-1 --exit-0 --inline-info --height=6 --ansi --color=bg:-1,bg+:-1 --layout=default
    --bind=f1:up,f2:down,tab:accept,/:accept,ctrl-a:toggle-all,ctrl-t:toggle,ctrl-g:jump,ctrl-j:down,ctrl-k:up' \
    | tr '\n' ' ')
  FZF_COMPLETION_OPTS="$_fzf_opts" # tab triggers completion
  export FZF_DEFAULT_OPTS="$_fzf_opts"
  export FZF_CTRL_T_OPTS="$_fzf_opts"
  export FZF_ALT_C_OPTS="$_fzf_opts"

  # Source file
  complete -r # reset first
  source ~/.fzf.bash
  printf "done\n"
fi

################################################################################
# Shell integration; iTerm2 feature only
################################################################################
# Turn off prompt markers with: https://stackoverflow.com/questions/38136244/iterm2-how-to-remove-the-right-arrow-before-the-cursor-line
# They are super annoying and useless
if [ -f ~/.iterm2_shell_integration.bash ]; then
  _bashrc_message "Enabling shell integration"
  # First enable
  source ~/.iterm2_shell_integration.bash
  # Declare some helper functions
  for func in imgcat imgls; do
    unalias $func
    eval 'function '$func'() {
      local i tmp tmpdir files
      i=0
      files=($@)
      tmpdir="."
      # [ -n "$TMPDIR" ] && tmpdir="$TMPDIR" || tmpdir="."
      for file in "${files[@]}"; do
        if [ "${file##*.}" == pdf ]; then
          tmp="$tmpdir/tmp.${file%.*}.png" # convert to png
          convert -flatten -units PixelsPerInch -density 300 -background white "$file" "$tmp"
        else
          tmp="$tmpdir/tmp.${file}"
          convert -flatten "$file" "$tmp"
        fi
        $HOME/.iterm2/'$func' "$tmp"
        rm "$tmp"
      done
    }'
  done
  printf "done\n"
fi

################################################################################
# iTerm2 title management
################################################################################
# Set the iTerm2 window title; see https://superuser.com/a/560393/506762
# 1. First was idea to make title match the working directory; but fails/not useful
# when inside tmux sessions
# export PROMPT_COMMAND='echo -ne "\033]0;${PWD/#$HOME/~}\007"'
# 2. Finally had idea to investigate environment variables -- terms out that
# TERM_SESSION_ID/ITERM_SESSION_ID indicate the window/tab/pane number! Just
# grep that, then if the title is not already set AND we are on pane zero, request title.
################################################################################
# First function that sets title
# Note, in read, if you specify number of characters, even pressing
# enter key will be recorded as a result; break loop by checking if it
# was pressed
_win_num="${TERM_SESSION_ID%%t*}"
_win_num="${_win_num#w}"
_title_file=~/.title
_title_set() { # default way is probably using Cmd-I in iTerm2
  # Record title from user input, or as user argument
  ! $_macos && echo "Error: Can only set title from mac." && return 1
  [ -z "$TERM_SESSION_ID" ] && echo "Error: Not an iTerm session." && return 1
  if [ -n "$1" ]; then # warning: $@ is somehow always non-empty!
    _title="$@"
  else
    read -p "Window title (window $_win_num):" _title
  fi
  [ -z "$_title" ] && _title="window $_win_num"
  # Use gsed instead of sed, because Mac syntax is "sed -i '' <pattern> <file>" while
  # GNU syntax is "sed -i <pattern> <file>", which is annoying.
  [ ! -e "$_title_file" ] && touch "$_title_file"
  gsed -i '/^'$_win_num':.*$/d' $_title_file # remove existing title from file
  echo "$_win_num: $_title" >>$_title_file # add to file
}
_title_get() {
  # Simply gets the title from file
  # if [ -n "$_title" ]; then # this lets window have different title in different panes
    # _title="$_title" # already exists
  if ! [ -r "$_title_file" ]; then
    _title=""
  elif $_macos; then
    _title="$(cat "$_title_file" | grep "^$_win_num:.*$" 2>/dev/null | cut -d: -f2-)"
  else
    _title="$(cat "$_title_file")" # only text in file, is this current session's title
  fi
  _title="$(echo "$_title" | sed $'s/^[ \t]*//;s/[ \t]*$//')"
}
_title_update() {
  # Check file availability
  if ! [ -r "$_title_file" ] && ! $_macos; then
    echo "Error: Title file not available." && return 1
  fi
  # Read from file
  _title_get # set _title global variable, attemp to read existing window title
  if [ -z "$_title" ]; then
    $_macos && _title_set # set title name
  else
    echo -ne "\033]0;$_title\007" # re-assert existing title, in case changed
  fi
}
title_update() { # fix name issues
  _title_update $@
}
# Ask for a title when we create pane 0 (i.e. the first pane of a new window)
[[ ! "$PROMPT_COMMAND" =~ "_title_update" ]] && _prompt _title_update
$_macos && [[ "$TERM_SESSION_ID" =~ w?t?p0: ]] && _title_update
alias title="_title_set" # easier for user
# alias titlereset="rm ~/.title"

################################################################################
# Message
# If github push/pulls will require password, configure with SSH (may require
# entering password once) or configure with http (stores information in plaintext
# but only ever have to do this once)
################################################################################
# Options for ensuring git credentials (https connection) is set up; now use SSH id, so forget it
# $_macos || { [ ! -e ~/.git-credentials ] && git config --global credential.helper store && command ssh -T git@github.com; }
# $_macos || { [ ! -e ~/.git-credentials ] && git config --global credential.helper store && echo "You may be prompted for a username+password when you enter a git command."; }
# Overcomplicated MacOS options
# $_macos && fortune | lolcat || echo "Shell configured and namespace populated."
# $_macos && { neofetch --config off --color_blocks off --colors 4 1 8 8 8 7 --disable term && fortune | lolcat; } || echo "Shell configured and namespace populated."
# alias hack="cmatrix" # hackerlolz
# alias clock="while true; do echo \"$(date '+%D %T' | toilet -f term -F border --metal)\"; sleep 1; done"
# hash powerline-shell 2>/dev/null && { # powerline shell; is ooglay so forget it
#   function _update_ps1() { PS1="$(powerline-shell $?)"; }
#   [ "$TERM" != "linux" ] && PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
#   }
# Fun stuff
$_macos && { # first the MacOS options
  alias artists="command ls -1 *.{mp3,m4a} 2>/dev/null | sed -e \"s/\ \-\ .*$//\" | uniq -c | sort -sn | sort -sn -r -k 2,1"
  alias forecast="curl wttr.in/Fort\ Collins" # list weather information
  grep '/usr/local/bin/bash' /etc/shells 1>/dev/null || \
    sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells' # add Homebrew-bash to list of valid shells
  [[ $BASH_VERSION =~ ^4.* ]] || chsh -s /usr/local/bin/bash # change current shell to Homebrew-bash
  }
_bashrc_loaded='true'
# Dad jokes
# NOTE: Get hang when doing this from within interactive cluster node; good
# way to test for that is compare hostname command with variable (variable will
# not change for some reason)
[ "$(hostname)" == "$HOSTNAME" ] && curl https://icanhazdadjoke.com/ 2>/dev/null && echo # yay dad jokes
