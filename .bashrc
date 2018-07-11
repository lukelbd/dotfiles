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
# PROMPT
################################################################################
# Keep things minimal; just make prompt boldface so its a bit more identifiable
unset PROMPT_COMMAND # don't enable this by default
export PS1='\[\033[1;37m\]\h[\j]:\W \u\$ \[\033[0m\]' # prompt string 1; shows "<comp name>:<work dir> <user>$"
  # style; the \[ \033 chars are escape codes for changing color, then restoring it at end
  # see: https://unix.stackexchange.com/a/124408/112647

################################################################################
# SETTINGS FOR PARTICULAR MACHINES
# CUSTOM KEY BINDINGS AND INTERACTION
################################################################################
# Reset all aliases
unalias -a
# Flag for if in MacOs
[[ "$OSTYPE" == "darwin"* ]] && macos=true || macos=false
# First, the path management
# If loading default bashrc, *must* happen before everything else or may get unexpected
# behavior! For example, due to my overriding behavior of grep/man/help commands, and
# the system default bashrc running those commands with my unexpected overrides
export PYTHONPATH="" # this one needs to be re-initialized
if $macos; then
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
  export PATH="$HOME/youtubetag:$PATH"
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
    [[ -z "$CONDA_PREFIX" ]] && {
      echo "Activating conda environment."
      source activate /project2/rossby/group07/.conda
      }
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
if [[ -e "$HOME/anaconda3/bin" || -e "$HOME/miniconda3/bin" ]]; then
  echo "Adding anaconda to path."
  export PATH="$HOME/anaconda3/bin:$PATH"
fi

################################################################################
# WRAPPERS FOR COMMON FUNCTIONS
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
  if command man $1 | head -2 | grep "BUILTIN" &>/dev/null; then
    if $macos; then # mac shows truncated manpage/no extra info; need the 'bash' manpage for full info
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
  local sessionfile=".session.vim"
  if [[ -z "$@" ]] && [[ -r "$sessionfile" ]]; then
    # Unfold stuff after entering each buffer; for some reason folds are otherwise
    # re-closed upon openening each file
    # Check out: cat $sessionfile | grep -n -E 'fold|zt'
    $macos && sed=gsed || sed=sed # only GNU sed works here
    $sed -i "/zt/a setlocal nofoldenable" $sessionfile
    command vim -S $sessionfile # for working with obsession
  else
    command vim -p "$@" # when loading specific files; also open them in separate tabs
  fi
  clear # clear screen after exit
}
# Open wrapper
function open() {
  # Parse input
  local app=
  unset files
  local files=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      -a|--application) local app="$2"; shift; shift; ;;
      -*) echo "Error: Unknown flag $1." && return 1 ;;
      *) local files+=($1); shift; ;;
    esac
  done
  echo ${files[@]}
  for file in "${files[@]}"; do
    # echo $file
    local iapp="$app"
    if [ -z "$iapp" ]; then
      case "$file" in
        *.html) local app="Chromium.app" ;;
        *.txt)  local app="TextEdit.app" ;;
        *.md)   local app="Marked 2.app" ;;
        *) echo "File type unknown for file: \"$file\"." && return 1 ;;
      esac
    fi
    echo "Opening file \"$file\"."
    # continue
    command open -a "$app" $file
  done
}
# Environment variables
export EDITOR=vim # default editor, nice and simple
export LC_ALL=en_US.UTF-8 # needed to make Vim syntastic work
# Use this for watching log files
alias watch="tail -f" # actually already is a watch command

################################################################################
# SHELL BEHAVIOR, KEY BINDINGS
################################################################################
# Readline/inputrc settings
# Use Ctrl-R to search previous commands
# Equivalent to putting lines in single quotes inside .inputrc
# bind '"\C-i":glob-expand-word' # expansion but not completion
complete -r # remove completions
bind -r '"\C-i"'
bind -r '"\C-d"'
bind -r '"\C-s"' # to enable C-s in Vim (normally caught by terminal as start/stop signal)
bind 'set disable-completion off'          # ensure on
bind 'set completion-ignore-case on'       # want dat
bind 'set completion-map-case on'          # treat hyphens and underscores as same
bind 'set show-all-if-ambiguous on'        # one tab press instead of two; from this: https://unix.stackexchange.com/a/76625/112647
bind "set menu-complete-display-prefix on" # show string typed so far as 'member' while cycling through completion options
bind 'set completion-display-width 1'      # easier to read
bind 'set bell-style visible'              # only let readlinke/shell do visual bell; use 'none' to disable totally
bind 'set skip-completed-text on'          # if there is text to right of cursor, make bash ignore it; only bash 4.0 readline
bind 'set visible-stats on'                # extra information, e.g. whether something is executable with *
bind '"\C-i": menu-complete'               # this will not pollute scroll history; better
bind '"\e-1\C-i": menu-complete-backward'  # this will not pollute scroll history; better
bind '"\e[Z": "\e-1\C-i"'                  # shift tab to go backwards
bind '"\C-l": forward-char'
bind '"\C-s": beginning-of-line' # match vim motions
bind '"\C-e": end-of-line'       # match vim motions
bind '"\C-h": backward-char'     # match vim motions
bind '"\C-w": forward-word'      # requires
bind '"\C-b": backward-word'     # by default c-b moves back one word, and deletes it
bind '"\C-k": menu-complete'     # scroll through complete options
bind '"\C-j": menu-complete-backward'
stty werase undef # no more ctrl-w word delete function; allows c-w re-binding to work
stty stop undef   # no more ctrl-s
stty eof undef    # no more ctrl-d
# function bind() {
#   if [ $# -eq 0 ]; then
#     command bind -p | grep -F '\C'
#   else
#     echo "bind $@"
#     command bind "$@"
#   fi
# }

# Shell Options
# Check out 'shopt -p' to see possibly interesting shell options
# Note diff between .inputrc and .bashrc settings: https://unix.stackexchange.com/a/420362/112647
function opts() {
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
  export HISTIGNORE="&:[ ]*:return *:exit *:cd *:source *:. *:bg *:fg *:history *:clear *" # don't record some commands
  export PROMPT_DIRTRIM=2 # trim long paths in prompt
  export HISTSIZE=50000
  export HISTFILESIZE=10000 # huge history -- doesn't appear to slow things down, so why not?
  export HISTCONTROL="erasedups:ignoreboth" # avoid duplicate entries
}
opts 2>/dev/null # ignore if option unavailable

################################################################################
# Aliases/functions for printing out information
################################################################################
# The -X show bindings bound to shell commands (i.e. not builtin readline functions, but strings specifying our own)
# The -s show bindings 'bound to macros' (can be combination of key-presses and shell commands)
alias bindings="bind -Xps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort" # print keybindings
alias bindings_stty="stty -e"                # bindings
alias functions="declare -F | cut -d' ' -f3" # show current shell functions
alias inputrc_funcs="bind -l"                # the functions, for example 'forward-char'
alias inputrc_ops="bind -v"                  # the 'set' options, and their values
function env() { set; } # just prints all shell variables

################################################################################
# Magic changing stderr color
# Turns out that iTerm2 SHELL INTEGRATION mostly handles the idea behind this;
# want "bad commands" to be more visible
################################################################################
# See comment: https://stackoverflow.com/a/21320645/4970632
# See exec summary: https://stackoverflow.com/a/18351547/4970632
# For trap info: https://www.computerhope.com/unix/utrap.htm
# But unreliable; there is issue with sometimes no newline generated

# Uncomment stuff below to restore
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
# General utilties
################################################################################
# Listing files
# * This page: https://geoff.greer.fm/lscolors/ converts BSD to Linux ls color string
# * The commented-out export is Linux default (run 'dircolors'), excluding filetype-specific ones.
# * We use the Mac default 'dircolors', and convert them to Linux colors.
#   Default mac colors were found with simple google search.
# * Use bin perl script lscolors-convert to go other direction -- Linux to BSD.
#   https://github.com/AndyA/dotfiles/blob/master/bin/ls-colors-linux-to-bsd
if $macos; then
  _ls_command=gls
  _dc_command=gdircolors
  _sort_command=gsort
else
  _ls_command=ls
  _dc_command=dircolors
  _sort_command=sort
fi
# Default mac colors
# LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43' \
# LSCOLORS='exfxcxdxbxegedabagacad' \
# Default linux colors
export LSCOLORS='ExGxFxdaCxDADAadhbheFx'
export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:'
# Custom linux colors
if [ -r "$HOME/.dircolors.ansi" ]; then
  eval "$($_dc_command $HOME/.dircolors.ansi)"
fi
# Apply ls
alias ls="$_ls_command --color=always -AF"   # ls useful (F differentiates directories from files)
alias ll="$_ls_command --color=always -AFhl" # ls "list", just include details and file sizes
! $macos && alias cd="cd -P" # don't want this on my mac temporarily

# Information on directories
alias df="df -h" # disk useage
alias eject="diskutil unmount" # eject disk on macOS
! $macos && alias hardware="cat /etc/*-release" # print out Debian, etc. release info
function ds() { # directory ls
  [ -z $1 ] && dir="" || dir="$1/"
  dir="${dir//\/\//\/}"
  command $_ls_command --color=always -A -d $dir*/
}
function dl() { # directory sizes
  [ -z $1 ] && dir="." || dir="$1"
  find "$dir" -maxdepth 1 -mindepth 1 -type d -exec du -hs {} \; | $_sort_command -sh
}

# Grepping and diffing; enable colors
alias grep="grep --color=auto" # always show color
alias egrep="egrep --color=auto" # always show color
# Make Perl color wrapper default; also allow color difference with git
# Note to recursively compare directories, use --name-status
hash colordiff 2>/dev/null && alias diff="command colordiff"

# Controlling and viewing running processes
alias pt="top" # mnemonically similar to 'ps'; table of processes, total
alias pc="mpstat -P ALL 1" # mnemonically similar to 'ps'; individual core usage
function listjobs() {
  # [[ -z "$@" ]] && echo "Error: Must specify grep pattern." && return 1
  ps | grep "$1" | grep -v PID | sed "s/^[ \t]*//" | tr -s ' ' | cut -d' ' -f1 | xargs
} # list jobs by name
function killjobs() {
  [ $# -eq 0 ] && echo "Error: Must specify grep pattern(s)." && return 1
  for str in $@; do
    echo "Killing $str jobs..."
    kill $(ps | grep "$str" | sed "s/^[ \t]*//" | tr -s ' ' | cut -d' ' -f1 | xargs) 2>/dev/null
  done
} # kill jobs by name

# Scripting utilities
alias tac="gtac" # use dis
function calc() { bc -l <<< "$1"; } # wrapper around bc floating-point calculator
function join() { local IFS="$1"; shift; echo "$*"; } # join array elements by some separator
function empty() { for i in {1..100}; do echo; done; }

# Differencing stuff, similar git commands stuff
# First use git as the difference engine; disable color
# Color not useful anyway; is just bold white, and we delete those lines
function discrep() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  git --no-pager diff --no-index --no-color "$1" "$2" 2>&1 | sed '/^diff --git/d;/^index/d' \
    | egrep '(files|differ)' # add to these
}
# Next use builtin diff command as engine
# *Different* files
# The last grep command is to highlight important parts
function delta() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  command diff -x '.session.vim' -x '*.sw[a-z]' --brief --strip-trailing-cr -r "$1" "$2" \
    | egrep '(Only in.*:|Files | and |differ| identical)'
}
# *Identical* files in two directories
function idelta() {
  [ $# -ne 2 ] && echo "Error: Need exactly two args." && return 1
  command diff -s -x '.session.vim' -x '*.sw[a-z]' --brief --strip-trailing-cr -r "$1" "$2" | grep identical \
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
# More Colors
################################################################################
# Tool for changing iTerm2 profile before command executed, and returning
# after executed (e.g. interactive prompts)
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
# [[ -f ~/.LESS_TERMCAP ]] && . ~/.LESS_TERMCAP # use colors for less, man, etc.
export LESS="--RAW-CONTROL-CHARS"
[ -f ~/.LESS_TERMCAP ] && . ~/.LESS_TERMCAP
if hash tput 2>/dev/null; then
  export LESS_TERMCAP_mb=$(tput setaf 2) # 2=green
  export LESS_TERMCAP_md=$(tput setaf 6) # cyan; took off "bold" for these; was too light
  export LESS_TERMCAP_me=$(tput sgr0)
  export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4) # yellow on blue
  export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
  export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7) # white
  export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
  export LESS_TERMCAP_mr=$(tput rev)
  export LESS_TERMCAP_mh=$(tput dim)
  export LESS_TERMCAP_ZN=$(tput ssubm)
  export LESS_TERMCAP_ZV=$(tput rsubm)
  export LESS_TERMCAP_ZO=$(tput ssupm)
  export LESS_TERMCAP_ZW=$(tput rsupm)
fi

################################################################################
# Utilities for converting figures between different types
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
function pdf2tiff() {
  resolution=1200 args=("$@")
  [[ $1 =~ ^[0-9]+$ ]] && resolution=$1 args="${args[@]:1}"
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

################################################################################
# Supercomputer tools 
################################################################################
alias sjobs="squeue -u $USER | tail -1 | tr -s ' ' | cut -s -d' ' -f2 | tr -d '[:alpha:]'"
alias suser="squeue -u $USER"

################################################################################
# Python workspace setup
################################################################################
# For profiling scripts
alias profile="python -m cProfile -s time"
# Python shell utilities
# io="import pandas as pd; import xarray as xr; import netCDF4 as nc4; "
io="import pandas as pd; import xarray as xr; "
basic="import numpy as np; from datetime import datetime; from datetime import date; "
magic="get_ipython().magic('load_ext autoreload'); get_ipython().magic('autoreload 2'); "
plots=$($macos && echo "import matplotlib as mpl; mpl.use('MacOSX'); import matplotlib.pyplot as plt; ") # plots
pyfuncs=$($macos && echo "import pyfuncs.plots as py; ") # lots of plot-related stuff in here
alias matlab="matlab -nodesktop -nosplash -r \"run('~/startup.m')\""
# Other shell utilities
# Simple thing for R
# * Calling R with --slave or --interactive makes quiting totally impossible somehow.
# * The ---always-readline prevents prompt from switching to the default prompt, but
#   also seems to disable ctrl-d for exiting.
alias r="R"   # because why not?
alias ir="iR" # again, why not?
function iR() {
  echo 'This is an Interactive R shell.'
  ! hash rlwrap &>/dev/null && echo "Error: Must install rlwrap." && return 1
  R -q --no-save # keep it simple stupid
  # rlwrap --always-readline -A -p"green" -R -S"R> " R -q --no-save
}
# NCL -- and a couple other things
# Binding thing doesn't work (cause it's not passed to shell), but was neat idea
function incl() {
  # local binding_old="$(bind -Xps | grep C-d)" # print every kind of binding; flags are different kinds
  echo "This is an Interactive NCL shell."
  ncl -Q -n
  # bind '"\C-d":"exit()\C-m"'
  # bind "$binding_old" # spaces gotta be escaped
}
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
alias iworkspace="ipython --no-term-title --no-banner --no-confirm-exit --pprint \
    -i -c \"$io$basic$magic$plots$pyfuncs\""
alias ipython="ipython --no-term-title --no-banner --no-confirm-exit --pprint \
    -i -c \"$magic\"" # double quotes necessary, because var contains single quotes
# With new shell color
# alias iworkspace="cmdcolor ipython --no-banner --no-confirm-exit --pprint -i -c \"$io$basic$magic$plots$pyfuncs\""
# alias ipython="cmdcolor ipython --no-banner --no-confirm-exit --pprint -i -c \"$magic\""
# alias perl="cmdcolor perl -de1" # pseudo-interactive console; from https://stackoverflow.com/a/73703/4970632
# alias R="cmdcolor R"

################################################################################
# NOTEBOOK STUFF
################################################################################
# * First will set the jupyter theme. Makes all fonts the same size (10) and makes cells nice and wide (95%)
# * IMPORTANT note: to uninstall nbextensions completely, use `jupyter contrib nbextension uninstall --user` and
#   `pip uninstall jupyter_contrib_nbextensions`; remove the configurator with `jupyter nbextensions_configurator disable`
# * If you have issues where themes is just not changing in Chrome, open Developer tab with Cmd+Opt+I
#   and you can right-click refresh for a hard reset, cache reset
# alias jtheme="jt -cellw 95% -nfs 10 -fs 10 -tfs 10 -ofs 10 -dfs 10 -t grade3"
jupyter_ready=false # theme is not initially setup because takes a long time
function jt() {
  # Choose default themes and font
  # chesterish is best; monokai has green/pink theme;
  # gruvboxd has warm color style; other dark themes too pale (solarizedd is turquoise pale)
  # solarizedl is really nice though; gruvboxl a bit too warm/monochrome
  if [ $# -lt 1 ]; then 
    echo "Choosing jupytertheme automatically based on hostname."
    case $HOSTNAME in
      uriah*)  jupyter_theme=solarizedl;;
      gauss*)   jupyter_theme=gruvboxd;;
      euclid*)  jupyter_theme=gruvboxd;;
      monde*)   jupyter_theme=onedork;;
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
function notebook() {
  # Set the jupyter theme
  echo "Configuring jupyter notebook theme."
  ! $jupyter_ready && jt # trigger default theme
  jupyter_ready=true # this value is available for rest of session
  # Test the hostname and get unique port we have picked
  if [ ! -z $1 ]; then
    jupyterremote=$1 # override with user input
  else case ${HOSTNAME%%.*} in
      uriah)    jupyterport=20000;;
      gauss)    jupyterport=20001;;
      euclid)   jupyterport=20002;;
      monde)    jupyterport=20003;;
      midway*)  jupyterport=20004;;
      *)      echo "Error: No jupyterport assigned to hostname \"${HOSTNAME%%.*}\". Edit your .bashrc." && return 1 ;;
    esac
  fi
  # Create the notebook
  echo "Initializing jupyter notebook over port port: $jupyterport."
  jupyter notebook --no-browser --port=$jupyterport --NotebookApp.iopub_data_rate_limit=10000000
    # need to extend data rate limit when making some plots with lots of stuff
}
# See current ssh connections
alias connections="ps aux | grep -v grep | grep ssh"
# Setup new connection to another server, enables REMOTE NOTEBOOK ACCESS
function connect() { # connect to remove notebook on port
  [ $# -lt 1 ] && echo "Error: Need at least 1 argument." && return 1
  local user=${1%%@*}
  local hostname=${1##*@} # the host we connect to, minus username
  if [ ! -z $2 ]; then
    jupyterconnect=$2 # override with user input
  else case ${hostname%%.*} in
      gauss)   jupyterconnect=20001;;
      euclid)  jupyterconnect=20002;;
      monde)   jupyterconnect=20003;;
      midway*) jupyterconnect=20004;;
      *)        echo "Error: No jupyterport assigned to hostname \"$hostname\". Edit your .bashrc." && return 1
    esac
  fi
  # Establish the connection
  echo "Connecting to $hostname over port $jupyterconnect."
  echo "Warning: Keep this window open to use your remote jupyter notebook!"
  \ssh -N -f -L localhost:$jupyterconnect:localhost:$jupyterconnect $user@$hostname
      # the -f command sets this port-forwarding to the background for the duration of the
      # ssh command to follow; but the -N command says we don't need to issue a command,
      # the port will just remain forwarded indefinitely
}
# Include option to cancel connection: see: https://stackoverflow.com/a/20240445/4970632
function disconnect() {
  # Determine the port to use
  if [ ! -z $1 ]; then
    local jupyterdisconnect=$1
  elif [ ! -z $jupyterconnect ]; then
    local jupyterdisconnect=$jupyterconnect
  else
    echo "Error: Must specify a port or make sure port is available from variable \"jupyterconnect\"."
    return 1
  fi
  # Disable the connection
  # lsof -t -i tcp:$jupyterdisconnect | xargs kill # this can accidentally kill Chrome instance
  local ports=($(lsof -i tcp:$jupyterdisconnect | grep ssh | sed "s/^[ \t]*//" | tr -s ' ' | cut -d' ' -f2 | xargs))
  [ -z $ports ] && echo "Error: Connection over port \"${jupyterdisconnect}\" not found." && return 1
  kill ${ports[@]} # kill the SSH processes
  [ $? == 0 ] && unset jupyterconnect || echo "Error: Could not disconnect from port \"${jupyterdisconnect}\"."
  echo "Connection over port ${jupyterdisconnect} removed."
}

################################################################################
# iTerm2 title and other stuff
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
titlefile=~/.title
winnum="${TERM_SESSION_ID%%t*}"
winnum="${winnum#w}"
function title() { # Cmd-I from iterm2 also works
  ! $macos && echo "Error: Can only set title from mac." && return 1
  [ -z "$TERM_SESSION_ID" ] && echo "Error: Not an iTerm session." && return 1
  if [ -n "$1" ]; then title="$1"
  else read -p "Enter title for this window: " title
  fi
  [ -z "$title" ] && title="window $winnum"
  # Use gsed instead of sed, because Mac syntax is "sed -i '' <pattern> <file>" while
  # GNU syntax is "sed -i <pattern> <file>", which is annoying.
  [ ! -e "$titlefile" ] && touch "$titlefile"
  gsed -i '/^'$winnum':.*$/d' $titlefile # remove existing title from file
  echo "$winnum: $title" >>$titlefile # add to file
  title_update # update
}
# Prompt user input potentially, but try to load from file
function title_update() {
  # Check file availability
  [ ! -r "$titlefile" ] && {
    if ! $macos; then echo "Error: Title file not available." && return 1
    else title
    fi; }
  # Read from file
  if $macos; then
    title="$(cat $titlefile | grep "^$winnum:.*$" 2>/dev/null | cut -d: -f2-)"
  else title="$(cat $titlefile)" # only text in file
  fi
  # Update or re-declare
  title="$(echo "$title" | sed 's/^[ \t]*//;s/[ \t]*$//')"
  if [ -z "$title" ]; then title # reset title
  else echo -ne "\033]0;"$title"\007" # re-assert existing title, in case changed
  fi
}
# New window; might have closed one and opened another, so declare new title
[[ ! "$PROMPT_COMMAND" =~ "title_update" ]] && prompt_append title_update
$macos && [[ "$TERM_SESSION_ID" =~ w?t?p0: ]] && [ -z "$title" ] && title

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
# ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
work='ldavis@10.83.16.91' # for scp'ing into my Mac
home='ldavis@10.253.201.216'
gauss='ldavis@gauss.atmos.colostate.edu'
monde='ldavis@monde.atmos.colostate.edu'
euclid='ldavis@euclid.atmos.colostate.edu'
olbers='ldavis@olbers.atmos.colostate.edu'
zephyr='lukelbd@zephyr.meteo.mcgill.ca'
chicago='t-9841aa@midway2-login1.rcc.uchicago.edu' # pass: orkalluctudg
archive='ldm@ldm.atmos.colostate.edu' # atmos-2012
ldm='ldm@ldm.atmos.colostate.edu' # atmos-2012

# archive='/media/archives/reanalyses/era_interim/'
# olbers='ldavis@129.82.49.159'
# Check git remote on current folder, make sure it points to SSH/HTTPS depending
# on current machine (on Macs just use HTTPS with keychain; on Linux must use id_rsa_github
# SSH key or password/username can only be stored in plaintext in home directory)
gitmessage=$(git remote -v 2>/dev/null)
if [ ! -z "$gitmessage" ]; then
  if [[ "$gitmessage" =~ "https" ]] && ! $macos; then # ssh node for Linux
    echo "Warning: Current Github repository points to HTTPS address. Must be changed to git@github.com SSH node."
  elif [[ "$gitmessage" =~ "git@github" ]] && $macos; then # url for Mac
    echo "Warning: Current Github repository points to SSH node. Must be changed to HTTPS address."
  fi
fi

# Trigger ssh-agent if not already running, and add Github private key
# Make sure to make private key passwordless, for easy login; all I want here
# is to avoid storing plaintext username/password in ~/.git-credentials, but free private key is fine
# See: https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux
# Also look into more complex approach: https://stackoverflow.com/a/18915067/4970632
# The AUTH_SOCK idea came from: https://unix.stackexchange.com/a/90869/112647
if ! $macos && [ -z "$SSH_AUTH_SOCK" ]; then
  if [ -e "$HOME/.ssh/id_rsa_github" ]; then
    echo "Adding Github private SSH key."
    eval "$(ssh-agent -s)" &>/dev/null # start agent, silently
    # ssh_agent=$! # save PID
    ssh-add ~/.ssh/id_rsa_github &>/dev/null # add Github private key; assumes public key has been added to profile
  else echo "Warning: Github private SSH key \"~/.ssh/id_rsa_github\" is not available."
  fi
fi

# Functions for executing stuff on remote servers
# Note git pull will fail if the merge is anything other than
# a fast-forward merge (e.g. modifying multiple files); otherwise
# need to commit local changes first
function figuresync() {
  # For now this function is designed specifically for one project; for
  # future projects can modify it
  # * The exclude-standard flag excludes ignored files listed with 'other' -o flag
  #   See: https://stackoverflow.com/a/26891150/4970632
  # * Takes server argument..
  extramessage="$2" # may be empty
  [ -z "$1" ] && echo "Error: Hostname argument required." && return 1
  local server="$1" # server
  local localdir="$(pwd)"
  local localdir="${localdir##*/}"
  if [ "$localdir" == "Tau" ]; then # special handling
    [[ "$server" =~ euclid ]] && local remotedir=/birner-home/ldavis || local remotedir=/home/ldavis
    local remotedir=$remotedir/working
  else # default handling
    local remotedir="/home/ldavis/$localdir"
  fi
  echo "Syncing local directory \"$localdir\" with remote directory \"$remotedir\"."
  eval "$(ssh-agent -s)" &>/dev/null # start agent, silently
  ssh-add ~/.ssh/id_rsa_github &>/dev/null # add Github private key; assumes public key has been added to profile
  \ssh $server 'eval "$(ssh-agent -s)" &>/dev/null; ssh-add ~/.ssh/id_rsa_github
    cd '"$remotedir"'; git status -s; sleep 1
    mfiles=($(git ls-files -m)); fmfiles=(${mfiles[@]##*.pdf}); Nmfiles=$((${#mfiles[@]}-${#fmfiles[@]}))
    ofiles=($(git ls-files -o --exclude-standard)); fofiles=(${ofiles[@]##*.pdf}); Nofiles=$((${#ofiles[@]}-${#fofiles[@]}))
    space1="" space2="" message="" # initialize message
    [ $Nmfiles -eq 1 ] && mfigures="figure" || mfigures="figures"
    [ $Nofiles -eq 1 ] && ofigures="figure" || ofigures="figures"
    [ $Nmfiles -ne 0 ] && message+="Modified $Nmfiles $mfigures." && space1=" "
    [ $Nofiles -ne 0 ] && message+="${space1}Made $Nofiles new $ofigures." && space2=" "
    [ ! -z "'"$extramessage"'" ] && message+="${space2}'"$extramessage"'"
    if [ ! -z "$message" ]; then
      echo "Commiting changes with message: \"$message\""
      git add --all && git commit -q -m "$message" && git push -q
    else echo "No new figures." && exit 1
    fi'
  if [ $? -eq 0 ]; then # non-zero exit code
    echo "Pulling changes to macbook."
    git fetch && git merge -m "Syncing with macbook." # assume in correct directory already
    # cd "$localdir" && git pull # attempt pull
  fi
# Method using read command
#   local commands # create local commands variable; https://stackoverflow.com/a/23991919/4970632
#   read -r -d '' commands << EOF
# commands go here
# EOF
#   \ssh $server "$commands"
# Method using multiline string
# \ssh $server "command 1
#   command 2
#   command 3"
}

# Functions for scp-ing from local to remote, and vice versa
# For initial idea see: https://stackoverflow.com/a/25486130/4970632
# For exit on forward see: https://serverfault.com/a/577830/427991
# For why we alias the function see: https://serverfault.com/a/656535/427991
# For enter command then remain in shell see: https://serverfault.com/q/79645/427991
#   * Note this has nice side-effect of eliminating annoying "banner message"
#   * Why iterate from ports 10000 upward? Because is even though disable host key
#     checking, still get this warning message every time.
portfile=~/.port # file storing port number
alias ssh="ssh_wrapper" # must be an alias or will fail! for some reason
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
function ssh_wrapper() {
  [ $# -lt 1 ] && echo "Error: Need at least 1 argument." && return 1
  local port=10000 # starting port
  local listen=22 # default sshd listening port; see the link above
  local args=($@) # all arguments
  [[ ${args[0]} =~ ^[0-9]+$ ]] && port=(${args[0]}) && args=(${args[@]:1}) # override
  # while netstat -an | grep "$port" | grep -i listen &>/dev/null; do # check for localhost availability; wrong!
  while \ssh ${args[@]} "netstat -an | grep \":$port\" &>/dev/null && exit 0 || exit 1"; do # check for availability on remote host
    echo "Warning: Port $port unavailable." # warning message
    local port=$(($port + 1)) # generate new port
  done
  # \ssh -o StrictHostKeyChecking=no \
  local portwrite="$(compressuser $portfile)"
  local titlewrite="$(compressuser $titlefile)"
  \ssh -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 \
    -t -R $port:localhost:$listen ${args[@]} \
    "echo $port >$portwrite; echo $title >$titlewrite; " \
    "echo \"Port number: ${port}.\"; /bin/bash -i" # -t says to stay interactive
}
# Copy from <this server> to local macbook
function rlcp() {    # "copy to local (from remote); 'copy there'"
  $macos && echo "Error: This function is intended to be used while SSH'd into remote servers." && return 1
  [ $# -lt 2 ] && echo "Error: Need at least 2 arguments." && return 1
  [ ! -r $portfile ] && echo "Error: Port unavailable." && return 1
  local port=$(cat $portfile) # port from most recent login
  local args=(${@:1:$#-2}) # $# stores number of args passed to shell, and perform minus 1
  [[ ${args[0]} =~ ^[0-9]+$ ]] && local port=${args[0]} && local args=(${args[@]:1})
  local file="${@:(-2):1}" # second to last
  local dest="$(compressuser ${@:(-1)})" # last value
  local dest="${dest//\ /\\\ }"  # escape whitespace manually
  echo "(Port $port) Copying $file on this server to home server at: $dest..."
  scp -o StrictHostKeyChecking=no -P$port ${args[@]} "$file" ldavis@127.0.0.1:"$dest"
}
# Copy from local macbook to <this server>
function lrcp() {    # "copy to remote (from local); 'copy here'"
  $macos && echo "Error: This function is intended to be used while SSH'd into remote servers." && return 1
  [ $# -lt 2 ] && echo "Error: Need at least 2 arguments." && return 1
  [ ! -r $portfile ] && echo "Error: Port unavailable." && return 1
  local port=$(cat $portfile) # port from most recent login
  local args=(${@:1:$#-2})   # $# stores number of args passed to shell, and perform minus 1
  [[ ${args[0]} =~ ^[0-9]+$ ]] && local port=${args[0]} && local args=(${args[@]:1})
  local dest="${@:(-1)}"   # last value
  local file="$(compressuser ${@:(-2):1})" # second to last
  local file="${file//\ /\\\ }"  # escape whitespace manually
  echo "(Port $port) Copying $file from home server to this server at: $dest..."
  scp -o StrictHostKeyChecking=no -P$port ${args[@]} ldavis@127.0.0.1:"$file" "$dest"
}

################################################################################
# LaTeX utilities
################################################################################
# Should have "compile" executable in $HOME directory; generally only use this
# with the .vimrc remap to <Ctrl+x> (compile, and potentially compile difference)
# and <Ctrl+w> (for HTML docs)
# Next need way to get word count
function wordcount() {
  file="$1"
  # This worked for certain templates:
  # detexed="$(cat "$file" | sed '1,/^\\end{abstract}/d;/^\\begin{addendum}/,$d' \
  #   | sed '/^\\begin{/d;/^\\end{/d;/=/d' | detex -c | grep -v .pdf | grep -v 'fig[0-9]' \
  #   | grep -v 'empty' | grep -v '^\s*$')"
  # Provide -e flag to ignore certain environments (e.g. abstract environment)
  # This worked for BAMS template:
  detexed="$(cat "$file" | \
    detex -e align,equation | grep -v .pdf | grep -v 'fig[0-9]')"
  echo "$detexed" # echo result
  echo "$detexed" | wc -w # get word count
    # * prints word count between end of abstract and start of methods
    # * explicitly delete begin/end environments because detex won't pick them up
    #   and use the equals sign to exclud equations
    # * note citations are left inside, but they are always right next to other
    #   words/not separated by whitespace so they don't affect wordcounts
}
# Our presentation software; install with commented line below from: http://pygobject.readthedocs.io/en/latest/getting_started.html
# brew install pygobject3 --with-python3 gtk+3 && /usr/local/bin/pip3 install pympress
# Other tools: "impressive", and "presentation"; both should be in $HOME/bin
alias pympress="LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/python3 /usr/local/bin/pympress"

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
  $macos && reverse="tail -r" || reverse="tac"
  # command ncdump -v "$1" "$2" | grep -A100 "^data:" | tail -n +3 | $reverse | tail -n +2 | $reverse
  command ncdump -v "$1" "$2" | $reverse | egrep -m 1 -B100 "[[:space:]]$1[[:space:]]" | sed '1,1d' | $reverse | less
    # shhh... just let it happen baby
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
# Utilities handling media and PDF files
################################################################################
# Fun stuff
alias music="ls -1 *.{mp3,m4a} | sed -e \"s/\ \-\ .*$//\" | uniq -c | $_sort_command -sn | $_sort_command -sn -r -k 2,1"
alias weather="curl wttr.in/Fort\ Collins" # list weather information

# Opening commands for some GUI apps
alias edit='\open -a TextEdit'
alias html='\open -a Google\ Chrome'
alias pdf='\open -a Skim'

# Extracting PDF annotations
function unannotate() {
  local original=$1
  local final=${original%.pdf}_unannotated.pdf
  [ ${original##*.} != "pdf" ] && echo "Error: Must input PDF file." && return 1
  pdftk $original output uncompressed.pdf uncompress
  LANG=C sed -n '/^\/Annots/!p' uncompressed.pdf > stripped.pdf
  pdftk stripped.pdf output $final compress
  rm uncompressed.pdf stripped.pdf
}

# Sync a local directory with files on SD card
# This function will only modify files on the SD card, never the local directory
function sdsync() {
  # Behavior option: check for modified files?
  # Only problem: file "modified" every time transferred to SD card
  shopt -u nullglob # no nullglob
  updateold=true
  # Can change this, but default will be to sync playlist
  sdcard="NO NAME" # edit when get new card
  sdloc="/Volumes/$sdcard/Playlist" # sd data
  [ ! -d "$sdloc" ] && echo "Error: SD card not found." && return 1
  locloc="$HOME/Playlist" # local data
  echo "SD Location: $sdloc"
  echo "Local location: $locloc"
  # Iterate through local files
  copied=false # copied anything?
  updated=false # updated anything?
  deleted=false # deleted anything?
  $macos && date=gdate || date=date
  for path in "$locloc/"*.{mp3,m4a,m3u8}; do
    [ ! -r "$path" ] && continue # e.g. if glob failed
    file="${path##*/}"
    if [ ! -r "$sdloc/$file" ]; then
      copied=true # record
      echo "New local file: $file. Copying to SD..."
      cp "$path" "$sdloc/$file"
    elif $updateold; then
      # This will work, because just record last date that sync occurred
      [ -r "$locloc/sdlog" ] || touch "$locloc/sdlog" # if doesn't exist, make
      datec=$(tail -n 1 "$locloc/sdlog") # date copied to SD
      datem=$($date -r "$path" +%s) # date last modified
      if [ -z "$datec" ]; then # initializing directory
        if [ $datem -gt $(($(date +%s) - (50*3600*24))) ]; then # update stuff changes in last 50 days
          modified=true
        else modified=false
        fi
      elif [ "$datem" -gt "$datec" ]; then
        modified=true # modified since last copied
      else modified=false # not modified since last copied
      fi
      $modified && {
        echo "Modified local file \"$file\" since previous sync."
        updated=true
        cp "$path" "$sdloc/$file"
        }
    fi
  done
  $copied || echo "No new files found."
  $updated || echo "No recently modified files found."
  # Iterate through remote files
  for path in "$sdloc/"*.{mp3,m4a,m3u8}; do
    [ ! -r "$path" ] && continue # e.g. if glob failed
    file="${path##*/}"
    if [ ! -r "$locloc/$file" ]; then
      deleted=true # record
      echo "Deleted local file: $file. Deleting from SD..."
      rm "$path"
    fi
  done
  $deleted || echo "No old files deleted."
  # Record in Playlist when last sync occurred
  date +%s >> "$locloc/sdlog"
}

################################################################################
# SHELL INTEGRATION; iTerm2 feature only
################################################################################
# Turn off prompt markers with: https://stackoverflow.com/questions/38136244/iterm2-how-to-remove-the-right-arrow-before-the-cursor-line
# They are super annoying and useless
if [ -f ~/.iterm2_shell_integration.bash ]; then
   source ~/.iterm2_shell_integration.bash
   echo "Enabled shell integration."
fi

################################################################################
# FZF FUZZY FILE COMPLETION TOOL
# See this page for ANSI color information: https://stackoverflow.com/a/33206814/4970632
################################################################################
# Run installation script; similar to the above one
if [ -f ~/.fzf.bash ]; then
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
  # To re-generate, just delete the .commands file and source this file
  # Generate list of all executables, and use fzf path completion by default
  # for almost all of them
  # WARNING: BOLD MOVE COTTON.
  echo "Setting up completion."
  _ignore="^\\($(echo "echo \\[ \\[\\[ cdo git fzf $FZF_COMPLETION_DIR_COMMANDS" | sed 's/ /\\|/g')\\)$"
  if [ ! -r "$HOME/.commands" ]; then
    echo "Recording available commands."
    compgen -c | grep -v $_ignore >$HOME/.commands # will include aliases and functions
  fi
  export FZF_COMPLETION_FILE_COMMANDS=$(cat $HOME/.commands | xargs) # pass to the script
  # complete $_complete_path $(cat $HOME/.commands | xargs)          # create them yourself
  #----------------------------------------------------------------------------#
  # See man page for --bind information
  # * Mainly use this to set bindings and window behavior; --no-multi seems to have no effect, certain
  #   key bindings will enabled multiple selection
  # * Also very important, bind slash to accept, so now the behavior is very similar
  #   to behavior of normal bash shell completion
  # * Inline info puts the number line thing on same line as text. More compact.
  # * For colors, see: https://stackoverflow.com/a/33206814/4970632
  #   Also see manual; here, '-1' is terminald default, not '0'
  _opts=$(echo ' --select-1 --exit-0 --inline-info --height=6
    --ansi --color=bg:-1,bg+:-1 --layout=default
    --bind=ctrl-a:toggle-all,ctrl-t:toggle,ctrl-g:jump,ctrl-d:toggle+down,ctrl-u:toggle+up,tab:accept,shift-tab:cancel,/:accept' \
    | tr '\n' ' ')
    # --ansi --color=bw
  # Custom options
  export FZF_COMPLETION_TRIGGER='' # tab triggers completion
  export FZF_COMPLETION_COMMAND_OPTS=" -maxdepth 1 "
  export FZF_COMPLETION_DIR_COMMANDS="cd pushd rmdir" # usually want to list everything
  # The builtin options next
  _command='' # use find . -maxdepth 1 search non recursively
  export FZF_DEFAULT_COMMAND="$_command"
  export FZF_CTRL_T_COMMAND="$_command"
  export FZF_ALT_C_COMMAND="$_command"
  # Options, same every time
  export FZF_COMPLETION_OPTS="$_opts" # tab triggers completion
  export FZF_DEFAULT_OPTS="$_opts"
  export FZF_CTRL_T_OPTS="$_opts"
  export FZF_ALT_C_OPTS="$_opts"
  # Source file
  complete -r # reset first
  source ~/.fzf.bash
  #----------------------------------------------------------------------------#
  # Old commands for filtering completion options; now it seems the -X filter
  # is ignored, as the function supplies all completion options
  # complete -f -X '*.@(pdf|png|jpg|jpeg|gif|eps|dvi|pdf|ps|svg|nc|aux|hdf|grib)' -o plusdirs vim
  # complete -f -X '!*.@(jpg|jpeg|png|gif|eps|dvi|pdf|ps|svg)' -o plusdirs preview
  # complete -f -X '!*.pdf' skim              # changes behavior of my alias "skim"; shows only
  # complete -f -X '!*.tex' -o plusdirs latex
  # complete -f -X '!*.html' -o plusdirs html # for opening HTML files in chrome
  # complete -f -o plusdirs mv # some shells disable tab-completion of dangerous commands; re-enable
  # complete -f -o plusdirs rm
  # Specific completion options
  _opts_custom="$(echo $_opts | sed 's/--select-1//g')"
  _fzf_complete_git() { # git commands be an alias that lists commands
    _fzf_complete "$_opts_custom" "$@" < <(
    git commands
    )
  }
  _fzf_complete_cdo() {
    _fzf_complete "$_opts_custom" "$@" < <(
    cdo --operators
    )
  }
  _fzf_complete_cdo_post() { # must be used with pipe
    cat /dev/stdin | cut -d' ' -f1
  }
  # Apply them as completion commands
  for _command in cdo git; do
    # complete -F _fzf_complete_$_command -o default -o bashdefault $_command
    complete -F _fzf_complete_$_command $_command
  done
  #----------------------------------------------------------------------------#
  # Finished
  echo "Enabled fuzzy file completion."
fi

################################################################################
# Message
# If github push/pulls will require password, configure with SSH (may require
# entering password once) or configure with http (stores information in plaintext
# but only ever have to do this once)
################################################################################
# Options for ensuring git credentials (https connection) is set up; now use SSH id, so forget it
# $macos || { [ ! -e ~/.git-credentials ] && git config --global credential.helper store && \ssh -T git@github.com; }
# $macos || { [ ! -e ~/.git-credentials ] && git config --global credential.helper store && echo "You may be prompted for a username+password when you enter a git command."; }
# Overcomplicated MacOS options
# $macos && fortune | lolcat || echo "Shell configured and namespace populated."
# $macos && { neofetch --config off --color_blocks off --colors 4 1 8 8 8 7 --disable term && fortune | lolcat; } || echo "Shell configured and namespace populated."
# alias hack="cmatrix" # hackerlolz
# alias clock="while true; do echo \"$(date '+%D %T' | toilet -f term -F border --metal)\"; sleep 1; done"
# hash powerline-shell 2>/dev/null && { # powerline shell; is ooglay so forget it
#   function _update_ps1() { PS1="$(powerline-shell $?)"; }
#   [ "$TERM" != "linux" ] && PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
#   }
# Messages
$macos && { # first the MacOS options
  grep '/usr/local/bin/bash' /etc/shells 1>/dev/null || \
    sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells' # add Homebrew-bash to list of valid shells
  [[ $BASH_VERSION =~ ^4.* ]] || chsh -s /usr/local/bin/bash # change current shell to Homebrew-bash
  fortune # fun message
  } || { curl https://icanhazdadjoke.com/; echo; } # yay dad jokes

