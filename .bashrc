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

################################################################################
# Prompt
################################################################################
# Keep things minimal; just make prompt boldface so its a bit more identifiable
export PS1='\[\033[1;37m\]\h[\j]:\W \u\$ \[\033[0m\]' # prompt string 1; shows "<comp name>:<work dir> <user>$"
  # style; the \[ \033 chars are escape codes for changing color, then restoring it at end
  # see: https://unix.stackexchange.com/a/124408/112647

################################################################################
# Settings for particular machines
# Custom key bindings and interaction
################################################################################
# Reset all aliases
# Very important! Sometimes we wrap new aliases around existing ones, e.g. ncl!
unalias -a
# Flag for if in MacOs
[[ "$OSTYPE" == "darwin"* ]] && _macos=true || _macos=false
# First, the path management
# If loading default bashrc, *must* happen before everything else or may get unexpected
# behavior! For example, due to my overriding behavior of grep/man/help commands, and
# the system default bashrc running those commands with my unexpected overrides
export PYTHONPATH="" # this one needs to be re-initialized
if $_macos; then
  # Mac options
  # Defaults... but will reset them
  # eval `/usr/libexec/path_helper -s`
  # Basics
  export PATH=""
  export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
  # LaTeX and X11
  export PATH="/opt/X11/bin:/Library/TeX/texbin:$PATH"
  # Macports
  export PATH="/opt/local/bin:/opt/local/sbin:$PATH" # MacPorts compilation locations
  # Homebrew
  export PATH="/usr/local/bin:$PATH" # Homebrew package download locations
  # PGI compilers
  export PATH="/opt/pgi/osx86-64/2017/bin:$PATH"
  # Youtube tool
  export PATH="$HOME/youtube-m4a:$PATH"
  # Matlab
  export PATH="/Applications/MATLAB_R2014a.app/bin:$PATH"
  # NCL NCAR command language (had trouble getting it to work on Mac with conda,
  # but on Linux distributions seems to work fine inside anaconda)
  alias ncl="DYLD_LIBRARY_PATH=\"/usr/local/lib/gcc/4.9\" ncl"
  export PATH="$HOME/ncl/bin:$PATH" # NCL utilities
  export NCARG_ROOT="$HOME/ncl" # critically necessary to run NCL
    # by default, ncl tried to find dyld to /usr/local/lib/libgfortran.3.dylib; actually ends
    # up in above path after brew install gcc49... and must install this rather than gcc, which
    # loads libgfortran.3.dylib and yields gcc version 7
  # Mac loading; load /etc/profile (on macOS, this runs a path setup executeable and resets the $PATH variable)
  # [ -f /etc/profile ] && . /etc/profile # this itself should also run /etc/bashrc
else
  # Linux options
  case $HOSTNAME in
  # Olbers options
  olbers)
    # Add netcdf4 executables to path, for ncdump
    echo "Overriding system \$PATH and \$LD_LIBRARY_PATH."
    export PATH="/usr/local/bin:/usr/bin:/bin"
    export PATH="/usr/local/netcdf4-pgi/bin:$PATH" # fortran lib
    export PATH="/usr/local/netcdf4/bin:$PATH" # c lib
    # HDF5 utilities (not needed now, but maybe someday)
    export PATH="/usr/local/hdf5/bin:$PATH"
    # MPICH utilities
    export PATH="/usr/local/mpich3/bin:$PATH"
    # PGI utilities
    export PATH="/opt/pgi/linux86-64/2017/bin:$PATH"
    # Matlab
    export PATH="/opt/Mathworks/R2016a/bin:$PATH"
    # And edit library path
    export LD_LIBRARY_PATH=/usr/local/mpich3/lib:/usr/local/hdf5/lib:/usr/local/netcdf4/lib:/usr/local/netcdf4-pgi/lib
  # Gauss options
  ;; gauss)
    # Basics
    echo "Overriding system \$PATH and \$LD_LIBRARY_PATH."
    export PATH="/usr/local/bin:/usr/bin:/bin"
    # Add all other utilities to path
    export PATH="/usr/local/netcdf4-pgi/bin:$PATH"
    export PATH="/usr/local/hdf5-pgi/bin:$PATH"
    export PATH="/usr/local/mpich3-pgi/bin:$PATH"
    # PGI utilities, plus Matlab
    export PATH="/opt/pgi/linux86-64/2016/bin:/opt/Mathworks/R2016a/bin:$PATH"
    # edit the library path
    export LD_LIBRARY_PATH="/usr/local/mpich3-pgi/lib:/usr/local/hdf5-pgi/lib:/usr/local/netcdf4-pgi/lib"
  # Euclid options
  ;; euclid)
    # Basics; all netcdf, mpich, etc. utilites already in in /usr/local/bin
    echo "Overriding system \$PATH and \$LD_LIBRARY_PATH."
    export PATH="/usr/local/bin:/usr/bin:/bin"
    # PGI utilites, plus Matlab
    export PATH="/opt/pgi/linux86-64/13.7/bin:/opt/Mathworks/bin:$PATH"
    # And edit the library path
    export LD_LIBRARY_PATH="/usr/local/lib"
  # Monde options
  ;; monde*)
    # Basics; all netcdf, mpich, etc. utilites already in in /usr/local/bin
    echo "Overriding system \$PATH and \$LD_LIBRARY_PATH."
    export PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"
    # PGI utilites, plus Matlab
    source set_pgi.sh # is in /usr/local/bin
    # And edit the library path
    export LD_LIBRARY_PATH="/usr/lib64/mpich/lib:/usr/local/lib"
    # ISCA modeling stuff
    export GFDL_BASE=$HOME/isca
    export GFDL_ENV=monde # "environment" configuration for emps-gv4
    export GFDL_WORK=/mdata1/ldavis/isca_work # temporary working directory used in running the model
    export GFDL_DATA=/mdata1/ldavis/isca_data # directory for storing model output
    # The Euclid/Gauss servers do not have NCL, so need to use conda
    # Monde has NCL installed already
    export NCARG_ROOT="/usr/local" # use the version located here
  # Chicago options
  ;; midway*)
    # Default bashrc setup
    echo "Loading system default bashrc."
    export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" # need to start here, or get error
    source /etc/bashrc
    # Begin interactive node
    # Only lasts 2 hours, so forget it
    # echo "Entering interactive node."
    # sinteractive
    # Add stuff to pythonpath
    export PYTHONPATH="$HOME/project-midway2:$PYTHONPATH"
    # Module load and stuff
    echo "Running module load commands."
    module purge 2>/dev/null
    module load intel/16.0
    module load mkl/11.3
    # In future, use my own environment
    # Idea to share conda environment, but really not necessary
    module load Anaconda3
    # [[ -z "$CONDA_PREFIX" ]] && {
    #   echo "Activating conda environment."
    #   source activate /project2/rossby/group07/.conda
    #   }
    # Fix prompt
    # unset PROMPT_COMMAND
    export PROMPT_COMMAND="$(echo $PROMPT_COMMAND | sed 's/printf.*";//g')"
  # Otherwise
  ;; *) echo "\"$HOSTNAME\" does not have custom settings. You may want to edit your \".bashrc\"."
  ;; esac
  # Consider loading defaults
  # [ -f /etc/bashrc ] && . /etc/bashrc
  # [ -f /etc/profile ] && . /etc/profile
fi
# Access custom executables
# No longer will keep random executables loose in homre directory; put everything here
export PATH="$HOME/bin:$PATH"
# Homebrew; save path before adding anaconda
# Brew conflicts with anaconda (try "brew doctor" to see)
alias brew="PATH=$PATH brew"
# Include modules (i.e. folders with python files) located in the home directory
# Also include python scripts in bin
export PYTHONPATH="$HOME/bin:$HOME:$PYTHONPATH"
# Anaconda options
if [[ -e "$HOME/anaconda3" || -e "$HOME/miniconda3" ]]; then
  source $HOME/anaconda3/etc/profile.d/conda.sh # set up environment variables
  conda activate # activate the default environment
  echo "Enabled conda."
fi

################################################################################
# Wrappers for common functions
################################################################################
# Append prompt command
function prompt_append() { # input argument should be new command
  export PROMPT_COMMAND="$(echo "$PROMPT_COMMAND; $1" | sed 's/;[ \t]*;/;/g;s/^[ \t]*;//g')"
}
# Help page wrapper
# See this page for how to avoid recursion when wrapping shell builtins and commands:
# http://blog.jpalardy.com/posts/wrapping-command-line-tools/
# Don't want to use aliases, e.g. because ncl requires DYLD_LIBRARY_PATH to open
# so we alias that as command prefix (don't want to change global path cause it
# messes other shit up, maybe homebrew)
function help() {
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
function man() { # always show useful information when man is called
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
function vim() {
  # First modify the Obsession-generated session file
  # Then restore the session; in .vimrc specify same file for writing, so this 'resumes'
  # tracking in the current session file
  local session=".vimsession"
  if [[ -z "$@" ]] && [[ -r "$session" ]]; then
    # Unfold stuff after entering each buffer; for some reason folds are otherwise
    # re-closed upon openening each file
    # Check out: cat $session | grep -n -E 'fold|zt'
    $_macos && _sed='gsed' || _sed='sed' # only GNU sed works here
    $_sed -i "/zt/a setlocal nofoldenable" $session
    command vim -S $session # for working with obsession
  else
    command vim -p "$@" # when loading specific files; also open them in separate tabs
  fi
  clear # clear screen after exit
}
# Open files optionally based on name, or revert to default behavior
# if -a specified
function open() {
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
function _setup_bindings() {
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
_setup_bindings 2>/dev/null

# Shell Options
# Check out 'shopt -p' to see possibly interesting shell options
# Note diff between .inputrc and .bashrc settings: https://unix.stackexchange.com/a/420362/112647
function _setup_opts() {
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
alias aliases="compgen -a"
alias functions="compgen -A function" # show current shell functions
if $_macos; then
  alias bindings="bind -Xps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort" # print keybindings
  alias bindings_stty="stty -e"                # bindings
else
  alias bindings="bind -ps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort" # print keybindings
  alias bindings_stty="stty -a"                # bindings
fi
alias inputrc_funcs="bind -l"         # the functions, for example 'forward-char'
alias inputrc_ops="bind -v"           # the 'set' options, and their values
function env() { set; } # just prints all shell variables

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
alias ctags="ctags --langmap=vim:+.vimrc,sh:+.bashrc" # permanent lang maps

# Information on directories
alias df="df -h" # disk useage
alias eject="diskutil unmount 'NO NAME'" # eject disk on macOS, default to this name
! $_macos && alias hardware="cat /etc/*-release" # print out Debian, etc. release info
function ds() { # directory ls
  [ -z $1 ] && dir="" || dir="$1/"
  dir="${dir//\/\//\/}"
  command $_ls_command --color=always -A -d $dir*/
}
function dl() { # directory sizes
  [ -z $1 ] && dir="." || dir="$1"
  find "$dir" -maxdepth 1 -mindepth 1 -type d -exec du -hs {} \; | sort -sh
}

# Grepping and diffing; enable colors
alias grep="grep --exclude-dir=plugged --exclude-dir=.git --exclude-dir=.svn --color=auto"
alias egrep="egrep --exclude-dir=plugged --exclude-dir=.git --exclude-dir=.svn --color=auto"
hash colordiff 2>/dev/null && alias diff="command colordiff" # use --name-status to compare directories

# Shell scripting utilities
function calc() { bc -l <<< "$(echo $@ | tr 'x' '*')"; } # wrapper around bc, make 'x'-->'*' so don't have to quote glob all the time!
function join() { local IFS="$1"; shift; echo "$*"; } # join array elements by some separator
function empty() { for i in {1..100}; do echo; done; }
function abspath() { # abspath that works on mac, Linux, or anything with bash
  if [ -d "$1" ]; then
    (cd "$1"; pwd)
  elif [ -f "$1" ]; then
    if [[ $1 = /* ]]; then
      echo "$1"
    elif [[ $1 == */* ]]; then
      echo "$(cd "${1%/*}"; pwd)/${1##*/}"
    else
      echo "$(pwd)/$1"
    fi
  fi
}

# Controlling and viewing running processes
alias pt="top" # mnemonically similar to 'ps'; table of processes, total
alias pc="mpstat -P ALL 1" # mnemonically similar to 'ps'; individual core usage
alias restarts="last reboot | less"
function listps() {
  ps | sed "s/^[ \t]*//" | tr -s ' ' | grep -v -e PID -e 'bash' -e 'grep' -e 'ps' -e 'sed' -e 'tr' -e 'cut' -e 'xargs' \
     | grep "$1" | cut -d' ' -f1,4
} # list job pids using ps; alternatively can use naked 'jobs' command
function killps() {
  local strs
  [ $# -ne 0 ] && strs=($@) || strs=(all)
  for str in ${strs[@]}; do
    echo "Killing $str jobs..."
    [ $str == 'all' ] && str=""
    kill $(listps "$str" | cut -d' ' -f1 | xargs) 2>/dev/null
  done
} # kill jobs by name
function killjobs() {
  local count=$(jobs | wc -l | xargs)
  for i in $(seq 1 $count); do
    echo "Killing job $i..."
    eval "kill %$i"
  done
} # kill jobs with the percent sign thing; NOTE background processes started by scripts not included!

# Differencing stuff, similar git commands stuff
# First use git as the difference engine; disable color
# Color not useful anyway; is just bold white, and we delete those lines
function gdiff() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  git --no-pager diff --no-index --no-color "$1" "$2" 2>&1 | sed '/^diff --git/d;/^index/d' \
    | egrep '(files|differ)' # add to these
}
# Next use builtin diff command as engine
# *Different* files
# The last grep command is to highlight important parts
function ddiff() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  command diff -x '.vimsession' -x '*.sw[a-z]' --brief --strip-trailing-cr -r "$1" "$2" \
    | egrep '(Only in.*:|Files | and |differ| identical)'
}
# *Identical* files in two directories
function idiff() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  command diff -s -x '.vimsession' -x '*.sw[a-z]' --brief --strip-trailing-cr -r "$1" "$2" | grep identical \
    | egrep '(Only in.*:|Files | and | differ| identical)'
}

# Merge fileA and fileB into merge.{ext}
# See this answer: https://stackoverflow.com/a/9123563/4970632
function merge() {
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
gauss="ldavis@gauss.atmos.colostate.edu"
monde="ldavis@monde.atmos.colostate.edu"
euclid="ldavis@euclid.atmos.colostate.edu"
olbers="ldavis@olbers.atmos.colostate.edu"
zephyr="lukelbd@zephyr.meteo.mcgill.ca"
midway="t-9841aa@midway2-login1.rcc.uchicago.edu" # pass: orkalluctudg
archive="ldm@ldm.atmos.colostate.edu"             # user: atmos-2012
ldm="ldm@ldm.atmos.colostate.edu"                 # user: atmos-2012

# Short helper functions
# See current ssh connections
alias connections="ps aux | grep -v grep | grep 'ssh '"
# View address
function address_ip() {
  # Get the ip address; several weird options for this
  if ! $_macos; then
    # See this: https://stackoverflow.com/q/13322485/4970632
    # ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'
    ip route get 1 | awk '{print $NF;exit}'
  else
    # See this: https://apple.stackexchange.com/q/20547/214359
    ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}' 
  fi
}
# String parsing
function expanduser() { # turn tilde into $HOME
  local param="$*"
  param="${param/#~/$HOME}"  # restore expanded tilde
  param="${param/#\~/$HOME}" # if previous one failed/was re-expanded, need to escape the tilde
  echo $param
}
function compressuser() { # turn $HOME into tilde
  local param="$*"
  param="${param/#$HOME/~}"
  param="${param/#$HOME/\~}"
  echo $param
}
# Disable connection over some port; see: https://stackoverflow.com/a/20240445/4970632
function disconnect() {
  local pids port=$1
  [ $# -ne 1 ] && echo "Error: Function requires exactly 1 arg."
  # lsof -t -i tcp:$port | xargs kill # this can accidentally kill Chrome instance
  pids="$(lsof -i tcp:$port | grep ssh | sed "s/^[ \t]*//" | tr -s ' ' | cut -d' ' -f2 | xargs)"
  [ -z "$pids" ] && echo "Error: Connection over port \"$port\" not found." && return 1
  kill $pids # kill the SSH processes
  echo "Processes $pids killed. Connections over port $port removed."
}

# Trigger ssh-agent if not already running, and add Github private key
# Make sure to make private key passwordless, for easy login; all I want here
# is to avoid storing plaintext username/password in ~/.git-credentials, but free private key is fine
# * See: https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux
#   The AUTH_SOCK idea came from: https://unix.stackexchange.com/a/90869/112647
# * Used to just ssh-add on every login, but that starts fantom ssh-agent processes that persist
#   when terminal is closed (all the 'eval' does is set environment variables; ssh-agent without
#   the eval just starts the process in background).
# * Now we re-use pre-existing agents with: https://stackoverflow.com/a/18915067/4970632
SSH_ENV="$HOME/.ssh/environment"
function killssh {
  # kill $(ps aux | grep ssh-agent | tr -s ' ' | cut -d' ' -f2 | xargs)
  kill $(ps aux | grep ssh-agent | grep -v grep | awk '{print $2}')
}
function initssh {
  # echo "Initialising new SSH agent..."
  if [ -f "$HOME/.ssh/id_rsa_github" ]; then
    echo "Adding Github private SSH key."
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
# Check git remote on current folder, make sure it points to SSH/HTTPS depending
# on current machine (on Macs just use HTTPS with keychain; on Linux must use id_rsa_github
# SSH key or password/username can only be stored in plaintext in home directory)
_git_message=$(git remote -v 2>/dev/null)
if [ ! -z "$_git_message" ]; then
  if [[ "$_git_message" =~ "https" ]] && ! $_macos; then # ssh node for Linux
    echo "Warning: Current Github repository points to HTTPS address. Must be changed to git@github.com SSH node."
  elif [[ "$_git_message" =~ "git@github" ]] && $_macos; then # url for Mac
    echo "Warning: Current Github repository points to SSH node. Must be changed to HTTPS address."
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
_port_file=~/.port # file storing port number
alias ssh="ssh_fancy" # many other utilities use ssh and avoid aliases, but do *not* test for functions
function ssh_fancy() {
  local port listen port_write title_write
  [ $# -ne 1 ] && echo "Error: This function needs exactly 1 argument." && return 1
  listen=22  # default sshd listening port; see the link above
  port=10000 # starting port
  port=$(command ssh "$1" "
    port=$port
    while netstat -an | grep \"[:.]\$port\" &>/dev/null; do
      let port=\$port+1
    done
    echo \$port
    ") # find first available port
  port_write="$(compressuser $_port_file)"
  title_write="$(compressuser $_title_file)"
  command ssh -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 \
    -t -R $port:localhost:$listen $1 \
    "echo $port >$port_write; echo $_title >$title_write; \
     echo \"Port number: ${port}.\"; /bin/bash -i" # enter bash and stay interactive
}
# Copy from <this server> to local macbook
# NOTE: Often want to copy result of glob expansion.
# NOTE: Below, we use the bash parameter expansion ${!#} -->
# 'variable whose name is result of "$#"' --> $n where n is the number
# of args. Also can do math inside param expansion indexing.
function rlcp() { # "copy to local (from remote); 'copy there'"
  local port file dest
  $_macos && echo "Error: Function intended to be called from an ssh session." && return 1
  [ ! -r $_port_file ] && echo "Error: Port unavailable." && return 1
  port=$(cat $_port_file)      # port from most recent login
  array=${@:1:$#-1}            # result of user input glob expansion, or just one file
  dest="$(compressuser ${!#})" # last value
  dest="${dest//\ /\\\ }"      # escape whitespace manually
  echo "(Port $port) Copying ${array[@]} on this server to home server at: $dest..."
  command scp -o StrictHostKeyChecking=no -P$port ${array[@]} ${USER}@localhost:"$dest"
}
# Copy from local macbook to <this server>
function lrcp() { # "copy to remote (from local); 'copy here'"
  local port file dest
  $_macos && echo "Error: Function intended to be called from an ssh session." && return 1
  [ $# -ne 2 ] && echo "Error: This function needs exactly 2 arguments." && return 1
  [ ! -r $_port_file ] && echo "Error: Port unavailable." && return 1
  port=$(cat $_port_file)   # port from most recent login
  dest="$2"                 # last value
  file="$(compressuser $1)" # second to last
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
alias r="R -q --no-save"
alias R="R -q --no-save"
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
alias julia="julia --banner=no"
# iPython wrapper -- load your favorite magics and modules on startup
# Have to sed trim the leading spaces to avoid indentation errors
pysimple=$(echo "get_ipython().magic('load_ext autoreload')
  get_ipython().magic('autoreload 2')" | sed 's/^ *//g')
pycomplex=$(echo "$pysimple
  from datetime import datetime
  from datetime import date
  import numpy as np
  import pandas as pd
  import xarray as xr
  $($_macos && echo "import matplotlib as mpl; mpl.use('MacOSX')
                    import matplotlib.pyplot as plt
                    from pyfuncs import plot")
  " | sed 's/^ *//g')
alias iwork="ipython --no-term-title --no-banner --no-confirm-exit --pprint -i -c \"$pycomplex\""
alias ipython="ipython --no-term-title --no-banner --no-confirm-exit --pprint -i -c \"$pysimple\""
# Perl -- hard to understand, but here it goes:
# * The first args are passed to rlwrap (-A sets ANSI-aware colors, and -pgreen applies green prompt)
# * The next args are perl args; -w prints more warnings, -n is more obscure, and -E
#   evaluates an expression -- say eval() prints evaluation of $_ (default searching and
#   pattern space, whatever that means), and $@ is set if eval string failed so the // checks
#   for success, and if not, prints the error message. This is a build-your-own eval.
function iperl() { # see this answer: https://stackoverflow.com/a/22840242/4970632
  echo 'This is an Interactive Perl shell.'
  ! hash rlwrap &>/dev/null && echo "Error: Must install rlwrap." && return 1
  rlwrap -A -p"green" -S"perl> " perl -wnE'say eval()//$@' # rlwrap stands for readline wrapper
}

################################################################################
# Notebook stuff
################################################################################
# * To uninstall nbextensions completely, use `jupyter contrib nbextension uninstall --user` and
#   `pip uninstall jupyter_contrib_nbextensions`; remove the configurator with `jupyter nbextensions_configurator disable`
# * If you have issues where themes are just not changing in Chrome, open Developer tab
#   with Cmd+Opt+I and you can right-click refresh for a hard reset, cache reset
# Wrapper aroung jupyter theme function, much better
_jt_configured=false # theme is not initially setup because takes a long time
function jt() {
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
  # mkadf
  themes=($(command jt -l | sed '1d'))
  [[ ! " ${themes[@]} " =~ " $jupyter_theme " ]] && \
    echo "Error: Theme $jupyter_theme is invalid; choose from ${themes[@]}." && return 1
  command jt -cellw 95% -fs 9 -nfs 10 -tfs 10 -ofs 10 -dfs 10 \
    -t $jupyter_theme -f $jupyter_font
}

# This function will establish two-way connection between server and local macbook
# with the same port number (easier to understand that way).
# Will be called whenever a notebook is iniated, and can be called to refresh stale connections.
function connect() {
  # Error checks and declarations
  local server outcome ports exits
  unset _jupyter_port
  $_macos                && echo "Error: This function is intended to run inside ssh sessions."                      && return 1
  [ ! -r $_port_file ]   && echo "Error: File \"$HOME/$_port_file\" not available. Cannot send commands to macbook." && return 1
  ! which ip &>/dev/null && echo "Error: Command \"ip\" not available. Cannot determine this server's address."      && return 1
  # The ip command prints this server's ip address ($hostname doesn't include full url)
  # ssh -f (port-forwarding in background) -N (don't issue command)
  echo "Sending commands to macbook."
  server=$USER@$(ip route get 1 | awk '{print $NF;exit}')
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
    if [ ${exits[$idx]} -eq 0 ]; then
      _jupyter_port=${ports[$idx]}
      echo "Connection over port ${ports[$idx]} successful."
    else
      echo "Connection over port ${ports[$idx]} failed."
    fi
  done
}

# Fancy wrapper for declaring notebook
# Will set up necessary port-forwarding connections on local and remote server, so
# that you can just click the url that pops up
function notebook() {
  # Set default jupyter theme
  local port
  ! $_jt_configured && \
    echo "Configure jupyter notebook theme." && jt && _jt_configured=true
  # Create the notebook
  # Need to extend data rate limit when making some plots with lots of stuff
  if [ -n "$1" ]; then
    echo "Initializing jupyter notebook over port $1."
    port="--port=$1"
  elif ! $_macos; then # remote ports will use 3XXXX   
    connect
    [ -z "$_jupyter_port" ] && return 1
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

# Refresh stale connections from macbook to server
# Simply calls the 'connect' function
function reconnect() {
  local ports
  $_macos && echo "Error: This function is intended to run inside ssh sessions." && return 1
  ports=$(ps u | grep jupyter-notebook | tr ' ' '\n' | grep -- --port | cut -d'=' -f2 | xargs)
  if [ -n "$ports" ]; then
    echo "Refreshing jupyter notebook connections over port(s) $ports."
    connect $ports
  else
    echo "No active jupyter notebooks found."
  fi
}

# Note git pull will fail if the merge is anything other than
# a fast-forward merge (e.g. modifying multiple files); otherwise
# need to commit local changes first
function figuresync() {
  # For now this function is designed specifically for one project; for
  # future projects can modify it
  # * The exclude-standard flag excludes ignored files listed with 'other' -o flag
  #   See: https://stackoverflow.com/a/26891150/4970632
  # * Takes server argument..
  local server localdir remotedir extramessage
  [[ $# -ne 1 && $# -ne 2 ]] && echo "Error: This function needs 1-2 arguments."
  ! $_macos && echo "Error: Function intended to be called from macbook." && return 1
  server="$1"       # server
  extramessage="$2" # may be empty
  localdir="$(pwd)"
  localdir="${localdir##*/}"
  if [ "$localdir" == "Tau" ]; then # special handling
    [[ "$server" =~ euclid ]] && local remotedir=/birner-home/ldavis || local remotedir=/home/ldavis
    remotedir=$remotedir/working
  else # default handling
    remotedir="/home/ldavis/$localdir"
  fi
  echo "Syncing local directory \"$localdir\" with remote directory \"$remotedir\"."
  # Issue script to server over ssh
  read -r -d '' commands << EOF
# List modified and 'other' (untracked) files of pdf type
# Also have to add github rsa manually because we don't source the bashrc
eval "\$(ssh-agent -s)" &>/dev/null; ssh-add ~/.ssh/id_rsa_github
cd "${remotedir}"; git status -s; sleep 1
mfiles=\$(git ls-files -m | grep '^.*\\.pdf' | wc -w)
ofiles=\$(git ls-files -o | grep '^.*\\.pdf' | wc -w)
# Initialize message
[ \$mfiles -ne 0 ]         && message+="Modified \$mfiles figure(s)."           && space1=" "
[ \$ofiles -ne 0 ]         && message+="\${space1}Made \$ofiles new figure(s)." && space2=" "
[ ! -z "${extramessage}" ] && message+="\${space2}${extramessage}"
echo "Commiting changes with message: \\"\$message\\""
git add --all && git commit -q -m "\$message" && git push -q
# if [ ! -z "\$message" ]; then
#   echo "Commiting changes with message: \\"\$message\\""
#   git add --all && git commit -q -m "\$message" && git push -q
# else
#   echo "No new figures." && exit 1
# fi
EOF
  command ssh $server "$commands"
  # Check output, and git fetch if new figures were found
  if [ $? -eq 0 ]; then # non-zero exit code
    echo "Pulling changes to macbook."
    git fetch && git merge -m "Syncing with macbook." # assume in correct directory already
  fi
}

################################################################################
# Dataset utilities
################################################################################
# Fortran tools
function namelist() {
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
function nchelp() {
  echo "Available commands:"
  echo "ncdump ncglobal ncinfo
        ncvarsinfo ncdimsinfo
        nclist ncvarlist ncdimslist
        ncvarinfo ncvardump ncvardata ncvartable" | column -t
}
function ncdump() { # almost always want this; access old versions in functions with backslash
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  command ncdump -h "$@" | less
}
function ncglobal() { # show just the global attributes
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  command ncdump -h "$@" | grep -A100 ^// | less
}
function ncinfo() { # only get text between variables: and linebreak before global attributes
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | sed '/^$/q' | sed '1,1d;$d' | less # trims first and last lines; do not need these
}
function ncvarsinfo() { # get information for just variables (no dimension/global info)
    # the cdo parameter table actually gives a subset of this information, so don't
    # bother parsing that information
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | grep -A100 "^variables:$" | sed '/^$/q' | sed $'s/^\t//g' | grep -v "^$" | grep -v "^variables:$" | less
    # the space makes sure it isn't another variable that has trailing-substring
    # identical to this variable; and the $'' is how to insert literal tab
    # -A means print x TRAILING lines starting from FIRST match
    # -B means prinx x PRECEDING lines starting from LAST match
}
function ncdimsinfo() { # get information for just variables (no dimension/global info)
    # the cdo parameter table actually gives a subset of this information, so don't
    # bother parsing that information
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | grep -B100 "^variables:$" | sed '1,2d;$d' | tr -d ';' | tr -s ' ' | column -t | less
    # the space makes sure it isn't another variable that has trailing-substring
    # identical to this variable; and the $'' is how to insert literal tab
}
function nclist() { # only get text between variables: and linebreak before global attributes
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | sed -n '/variables:/,$p' | sed '/^$/q' | grep -v '[:=]' \
    | cut -d '(' -f 1 | sed 's/.* //g' | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
function ncdimlist() { # get list of dimensions
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
    | cut -d '=' -f 1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
function ncvarlist() { # only get text between variables: and linebreak before global attributes
  [ $# -ne 1 ] && { echo "One argument required."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
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
function ncvarinfo() { # as above but just for one variable
  [ $# -ne 2 ] && { echo "Two arguments required."; return 1; }
  [ ! -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  command ncdump -h "$2" | grep -A100 "[[:space:]]$1(" | grep -B100 "[[:space:]]$1:" | sed "s/$1://g" | sed $'s/^\t//g' | less
    # the space makes sure it isn't another variable that has trailing-substring
    # identical to this variable; and the $'' is how to insert literal tab
}
function ncvardump() { # dump variable contents (first argument) from file (second argument)
  [ $# -ne 2 ] && { echo "Two arguments required."; return 1; }
  [ ! -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  $_macos && _reverse="gtac" || _reverse="tac"
  # command ncdump -v "$1" "$2" | grep -A100 "^data:" | tail -n +3 | $_reverse | tail -n +2 | $_reverse
  command ncdump -v "$1" "$2" | $_reverse | egrep -m 1 -B100 "[[:space:]]$1[[:space:]]" | sed '1,1d' | $_reverse | less
    # shhh... just let it happen
    # tail -r reverses stuff, then can grep to get the 1st match and use the before flag to print stuff
    # before (need extended grep to get the coordinate name), then trim the first line (curly brace) and reverse
}
function ncvardata() { # parses the CDO parameter table; ncvarinfo replaces this
  [ $# -ne 2 ] && { echo "Two arguments required."; return 1; }
  local args=("$@")
  local args=(${args[@]:2}) # extra arguments
  echo ${args[@]}
  cdo -s infon ${args[@]} -seltimestep,1 -selname,"$1" "$2" | tr -s ' ' | cut -d ' ' -f 6,8,10-12 | column -t 2>&1 | less
    # this procedure is ideal for "sanity checks" of data; just test one
    # timestep slice at every level; the tr -s ' ' trims multiple whitespace to single
    # and the column command re-aligns columns
}
function ncvartable() { # as above but show everything
  [ $# -ne 2 ] && { echo "Two arguments required."; return 1; }
  [ ! -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  local args=("$@")
  local args=(${args[@]:2}) # extra arguments
  echo ${args[@]}
  cdo -s infon ${args[@]} -seltimestep,1 -selname,"$1" "$2" 2>&1 | less
  # 2>/dev/null
}
# Extract generalized files
function extract() {
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
# Temporarily change iTerm2 profile while REPL or other command is active
# Alias any command with 'cmdcolor' as prefix
function cmdcolor() {
  # Get current profile name; courtesy of: https://stackoverflow.com/a/34452331/4970632
  # Or that's dumb and just use ITERM_PROFILE
  newprofile=Argonaut
  oldprofile=$ITERM_PROFILE
  # Restore the current settings if the user ctrl-c's out of the command
  trap ctrl_c INT
  function ctrl_c() {
    echo -e "\033]50;SetProfile=$oldprofile\a"
    exit
  }
  # Set profile; if you want you can allow profile as $1, then call shift,
  # and now the remaining command arguments are $@
  echo -e "\033]50;SetProfile=$newprofile\a"
  # Note, can use 'command' to avoid function/alias lookup
  # See: https://stackoverflow.com/a/6365872/4970632
  "$@" # need to quote it, might need to escape stuff
  # Restore settings
  echo -e "\033]50;SetProfile=$oldprofile\a"
}
# Standardize less/man/etc. colors
# Used this post from thread: https://unix.stackexchange.com/a/329092/112647
# [[ -f ~/.LESS_TERMCAP ]] && . ~/.LESS_TERMCAP # use colors for less, man, etc.
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
# function undirect(){ echo -ne '\0'; exec 2>&9; } # return stream 2 to "dummy stream" 9
# function undirect(){ exec 2>&9; } # return stream 2 to "dummy stream" 9
# function redirect(){
#   local PRG="${BASH_COMMAND%% *}" # ignore flags/arguments
#   for X in ${STDERR_COLOR_EXCEPTIONS[@]}; do
#     [ "$X" == "${PRG##*/}" ] && return 1; # trim directories
#   done # if special program, don't send to coloring stream
#   exec 2>&8 # send stream 2 to the coloring stream
# }
# trap "redirect;" DEBUG # trap executes whenever receiving signal <ARG> (here, "DEBUG"==every simple command)
# export PROMPT_COMMAND="undirect;" # execute this just before prompt PS1 is printed (so after stderr/stdout printing)
# export STDERR_COLOR_EXCEPTIONS=(wget scp ssh mpstat top source .  diff sdsync # commands
#   brew
#   brew\ cask
#   youtube metadata # some scripts
#   \\ipython \\jupyter \\python \\matlab # disabled alias versions
#   node rhino ncl matlab # misc languages; javascript, NCL, matlab
#   cdo conda pip easy_install python ipython jupyter notebook) # python stuff
#   # interactive stuff gets SUPER WONKY if you try to redirect it with this script

################################################################################
# Utilities related to preparing PDF documents
# Converting figures between different types, other pdf tools, word counts
################################################################################
# * Flatten gets rid of transparency/renders it against white background, and the units/density specify
#   a <N>dpi resulting bitmap file.
# * Another option is "-background white -alpha remove", try this.
# * Note the PNAS journal says 1000-1200dpi recommended for line art images and stuff with text.
# * Note imagemagick does *not* handle vector formats; will rasterize output image and embed in a pdf, so
#   cannot flatten transparent components with convert -flatten in.pdf out.pdf
function gif2png() {
  for f in "$@";
    do [[ "$f" =~ .gif$ ]] && echo "Converting $f..." && convert "$f" "${f%.gif}.png"
  done
} # often needed because LaTeX can't read gif files
function pdf2png() {
  density=1200 args=("$@")
  [[ $1 =~ ^[0-9]+$ ]] && density=$1 args="${args[@]:1}"
  flags="-flatten -units PixelsPerInch -density $density"
  for f in "${args[@]}"; do
    [[ "$f" =~ .pdf$ ]] && echo "Converting $f with ${density}dpi..." && convert $flags "$f" "${f%.pdf}.png"
  done
} # sometimes need bitmap yo
function svg2png() {
  pdf2png $@
  density=1200 args=("$@")
  [[ $1 =~ ^[0-9]+$ ]] && density=$1 args="${args[@]:1}"
  flags="-flatten -units PixelsPerInch -density $density -background none"
  for f in "${args[@]}"; do
    [[ "$f" =~ .svg$ ]] && echo "Converting $f with ${density}dpi..." && convert $flags "$f" "${f%.svg}.png"
  done
}
function pdf2tiff() {
  density=1200 args=("$@")
  [[ $1 =~ ^[0-9]+$ ]] && density=$1 args="${args[@]:1}"
  flags="-flatten -units PixelsPerInch -density $density"
  for f in "${args[@]}"; do
    [[ "$f" =~ .pdf$ ]] && echo "Converting $f with ${density}dpi..." && convert $flags "$f" "${f%.pdf}.tiff"
  done
} # alternative for converting to bitmap
function pdf2eps() {
  args=("$@")
  for f in "${args[@]}"; do
    [[ "$f" =~ .pdf$ ]] && echo "Converting $f..." && \
      pdf2ps "$f" "${f%.pdf}.ps" && ps2eps "${f%.pdf}.ps" "${f%.pdf}.eps" && rm "${f%.pdf}.ps"
  done
}
function flatten() {
  # this page is helpful:
  # https://unix.stackexchange.com/a/358157/112647
  # 1. pdftk keeps vector graphics
  # 2. convert just converts to bitmap and eliminates transparency
  # 3. pdf2ps piping retains quality
  args=("$@")
  for f in "${args[@]}"; do
    [[ "$f" =~ .pdf$ ]] && [[ ! "$f" =~ "flat" ]] && echo "Converting $f..." && \
      pdf2ps "$f" - | ps2pdf - "${f}_flat.pdf"
      # convert "$f" "${f}_flat.pdf"
      # pdftk "$f" output "${f}_flat.pdf" flatten
  done
}

# Extract PDF annotations
# Turned out kind of complicated
function unannotate() {
  local original="$1"
  local final="${original%.pdf}_unannotated.pdf"
  [ "${original##*.}" != "pdf" ] && echo "Error: Must input PDF file." && return 1
  $_macos && local sed="gsed" || local sed="sed"
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
  LANG=C LC_ALL=C $sed -n '/^\/Annots/!p' uncompressed.pdf > stripped.pdf
  pdftk stripped.pdf output "$final" compress
  rm uncompressed.pdf stripped.pdf
}

# Rudimentary wordcount with detex
function wctex() {
  file="$1"
  # Below worked for certain templates:
  # Explicitly delete begin/end environments because detex won't pick them up
  # and use the equals sign to exclude equations
  # detexed="$(cat "$file" | sed '1,/^\\end{abstract}/d;/^\\begin{addendum}/,$d' \
  #   | sed '/^\\begin{/d;/^\\end{/d;/=/d' | detex -c | grep -v .pdf | grep -v 'fig[0-9]' \
  #   | grep -v 'empty' | grep -v '^\s*$')"
  # Below worked for BAMS template, gets count between end of abstract
  # and start of methods
  # The -e flag to ignore certain environments (e.g. abstract environment)
  detexed="$(cat "$file" | \
    detex -e align,equation | grep -v .pdf | grep -v 'fig[0-9]')"
  echo "$detexed" | xargs # print result in one giant line
  echo "$detexed" | wc -w # get word count
}

# ***Other Tools*** are "impressive" and "presentation", and both should be in bin
# Homebrew presentation software; below installs it, from http://pygobject.readthedocs.io/en/latest/getting_started.html
# brew install pygobject3 --with-python3 gtk+3 && /usr/local/bin/pip3 install pympress
alias pympress="LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/python3 /usr/local/bin/pympress"

################################################################################
# FZF fuzzy file completion tool
# See this page for ANSI color information: https://stackoverflow.com/a/33206814/4970632
################################################################################
# Run installation script; similar to the above one
if [ -f ~/.fzf.bash ]; then
  # See man page for --bind information
  # * Mainly use this to set bindings and window behavior; --no-multi seems to have no effect, certain
  #   key bindings will enabled multiple selection
  # * Also very important, bind slash to accept, so now the behavior is very similar
  #   to behavior of normal bash shell completion
  # * Inline info puts the number line thing on same line as text. More compact.
  # * For colors, see: https://stackoverflow.com/a/33206814/4970632
  #   Also see manual; here, '-1' is terminal default, not '0'
  # Custom options
  export FZF_COMPLETION_FIND_IGNORE=".DS_Store .vimsession .vim.tags __pycache__ .ipynb_checkpoints"
  export FZF_COMPLETION_FIND_OPTS=" -maxdepth 1 "
  export FZF_COMPLETION_TRIGGER='' # tab triggers completion
  export FZF_COMPLETION_DIR_COMMANDS="cd pushd rmdir" # usually want to list everything
  # The builtin options # --ansi --color=bw
  # Try to make bindings similar to vim; configure ctrl+, and ctrl+. to trigger completion
  # and scroll through just like tabs, ctrl+j and ctrl+k reserved for history scrolling, and use
  # slash, enter, or ctrl-d to accept an answer (d for 'descend')
  _command='' # use find . -maxdepth 1 search non recursively
  _opts=$(echo ' --select-1 --exit-0 --inline-info --height=6
    --ansi --color=bg:-1,bg+:-1 --layout=default
    --bind=f1:up,f2:down,shift-tab:up,tab:down,ctrl-a:toggle-all,ctrl-t:toggle,ctrl-g:jump,ctrl-j:down,ctrl-k:up,ctrl-d:accept,/:accept' \
    | tr '\n' ' ')
  export FZF_DEFAULT_COMMAND="$_command"
  export FZF_CTRL_T_COMMAND="$_command"
  export FZF_ALT_C_COMMAND="$_command"
  export FZF_COMPLETION_OPTS="$_opts" # tab triggers completion
  export FZF_DEFAULT_OPTS="$_opts"
  export FZF_CTRL_T_OPTS="$_opts"
  export FZF_ALT_C_OPTS="$_opts"
  #----------------------------------------------------------------------------#
  # To re-generate, just delete the .commands file and source this file
  # Generate list of all executables, and use fzf path completion by default
  # for almost all of them
  # WARNING: BOLD MOVE COTTON.
  _ignore="{ } \\[ \\[\\[ gecho echo type which cdo git fzf $FZF_COMPLETION_DIR_COMMANDS"
  _ignore="^\\($(echo "$_ignore" | sed 's/ /\\|/g')\\)$"
  if [ ! -r "$HOME/.commands" ]; then
    echo "Recording available commands."
    compgen -c >$HOME/.commands # will include aliases and functions
  fi
  export FZF_COMPLETION_FILE_COMMANDS=$(cat $HOME/.commands | grep -v "$_ignore" 2>/dev/null | xargs)
  # complete $_complete_path $(cat $HOME/.commands | grep -v $_ignore | xargs)
  #----------------------------------------------------------------------------#
  # Source file
  complete -r # reset first
  source ~/.fzf.bash
  #----------------------------------------------------------------------------#
  # Create custom bindings
  # Use below to bind ctrl t command
  # bind -x "$(bind -X | grep 'C-t' | sed 's/C-t/<custom>/g')"
  # Bind alt c command to ctrl f (i.e. the 'enter folder' command)
  bind "$(bind -s | grep '\\ec' | sed 's/\\ec/\\C-f/g')"
  # Add a few basic completion options
  # First set the default ones
  _complete_path=$(complete | grep 'rm$' | sed 's/complete//;s/rm//')
  complete -E # when line empty, perform no complection (options empty)
  # complete -D $_complete_path # ideal, but this seems to break stuff
  #----------------------------------------------------------------------------#
  # Non-path completion: subcommands, shell commands, etc.
  # Feel free to add to this list, it is super cool
  for _command in shopt help man type which bind alias unalias function git cdo; do
    # Post-processing commands *must* have name <name_of_complete_function>_post
    case $_command in
      shopt) _generator="shopt | cut -d' ' -f1 | cut -d$'\\t' -f1" ;;
      help|man|type|which) _generator="cat \$HOME/.commands | grep -v '[!.:]'" ;; # faster than loading every time
      bind)                _generator="bind -l" ;;
      unalias|alias)       _generator="compgen -a" ;;
      function)            _generator="compgen -A function" ;;
      git)                 _generator="git commands" ;;
      cdo)                 _generator="cdo --operators"
     _fzf_complete_cdo_post() { cat /dev/stdin | cut -d' ' -f1; } ;;
    esac
    # Create functions, and declare completions
    eval "_fzf_complete_$_command() {
          _fzf_complete \$FZF_COMPLETION_OPTS \"\$@\" < <( $_generator )
          }"
    complete -F _fzf_complete_$_command $_command
  done
  #----------------------------------------------------------------------------#
  # Path completion with file extension filter
  # For info see: https://unix.stackexchange.com/a/15309/112647
  # These will wrap around the generic path completion function
  _fzf_find_prefix='-name .git -prune -o -name .svn -prune -o ( -type d -o -type f -o -type l )'
  for _command in pdf image html; do
    case $_command in
      image) _filter="\\( -iname \\*.jpg -o -iname \\*.png -o -iname \\*.gif -o -iname \\*.svg -o -iname \\*.eps -o -iname \\*.pdf \\)" ;;
      html)  _filter="-iname \\*.html" ;;
      pdf)   _filter="-name \\*.pdf" ;;
    esac
    eval "_fzf_compgen_$_command() {
      command find -L \"\$1\" \
        \$FZF_COMPLETION_FIND_OPTS \
        -name .git -prune -o -name .svn -prune -o \\( -type d -o -type f -o -type l \\) \
        -a $_filter -a -not -path \"\$1\" -print 2> /dev/null | sed 's@^\\./@@'
    }"
    eval "_fzf_complete_$_command() {
          __fzf_generic_path_completion _fzf_compgen_$_command \"-m\" \"\$@\"
          }"
    complete -o nospace -F _fzf_complete_$_command $_command
  done
  echo "Enabled fuzzy file completion."
fi

################################################################################
# Shell integration; iTerm2 feature only
################################################################################
# Turn off prompt markers with: https://stackoverflow.com/questions/38136244/iterm2-how-to-remove-the-right-arrow-before-the-cursor-line
# They are super annoying and useless
if [ -f ~/.iterm2_shell_integration.bash ]; then
   source ~/.iterm2_shell_integration.bash
   echo "Enabled shell integration."
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
_title_file=~/.title
_win_num="${TERM_SESSION_ID%%t*}"
_win_num="${_win_num#w}"
function read_idle() {
  # Function to wait for 3 *idle* seconds, until
  # Other flags will be passed to command
  local args=("$@")
  local input=""
  read "${args[@]}" -t 3 -N 1 char
  while [ -n "$char" ] && [ "$char" != $'\n' ]; do
    input+=$char
    read -t 3 -N 1 char
  done
  echo "$input" # a bit different, echo instead of implicitly setting
}
function title() { # Cmd-I from iterm2 also works
  # Record title from user input, or as user argument
  ! $_macos && echo "Error: Can only set title from mac." && return 1
  [ -z "$TERM_SESSION_ID" ] && echo "Error: Not an iTerm session." && return 1
  if [ -n "$1" ]; then # warning: $@ is somehow always non-empty!
    _title="$@"
  else
    _title="$(read_idle -p "Window title (window $_win_num): ")"
  fi
  [ -z "$_title" ] && _title="window $_win_num"
  # Use gsed instead of sed, because Mac syntax is "sed -i '' <pattern> <file>" while
  # GNU syntax is "sed -i <pattern> <file>", which is annoying.
  [ ! -e "$_title_file" ] && touch "$_title_file"
  gsed -i '/^'$_win_num':.*$/d' $_title_file # remove existing title from file
  echo "$_win_num: $_title" >>$_title_file # add to file
}
# Prompt user input potentially, but try to load from file
function title_update() {
  # Check file availability
  [ ! -r "$_title_file" ] && {
    if ! $_macos; then echo "Error: Title file not available." && return 1
    else title
    fi; }
  # Read from file
  if $_macos; then
    _title="$(cat $_title_file | grep "^$_win_num:.*$" 2>/dev/null | cut -d: -f2-)"
  else
    _title="$(cat $_title_file)" # only text in file, is this current session's title
  fi
  # Update or re-declare
  _title="$(echo "$_title" | sed $'s/^[ \t]*//;s/[ \t]*$//')"
  if [ -z "$_title" ]; then title # reset title
  else echo -ne "\033]0;$_title\007" # re-assert existing title, in case changed
  fi
}
# New window; might have closed one and opened another, so declare new title
[[ ! "$PROMPT_COMMAND" =~ "title_update" ]] && prompt_append title_update
# Currently always asks for title; but could create new one
$_macos && [[ "$TERM_SESSION_ID" =~ w?t?p0: ]] && [ -z "$_title" ] && title

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
alias playlist="command ls -1 *.{mp3,m4a} 2>/dev/null | sed -e \"s/\ \-\ .*$//\" | uniq -c | sort -sn | sort -sn -r -k 2,1"
alias forecast="curl wttr.in/Fort\ Collins" # list weather information
# Messages
title_update # force update in case anything changed it, e.g. shell integration
$_macos && { # first the MacOS options
  grep '/usr/local/bin/bash' /etc/shells 1>/dev/null || \
    sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells' # add Homebrew-bash to list of valid shells
  [[ $BASH_VERSION =~ ^4.* ]] || chsh -s /usr/local/bin/bash # change current shell to Homebrew-bash
  fortune # fun message
  } || { curl https://icanhazdadjoke.com/; echo; } # yay dad jokes

