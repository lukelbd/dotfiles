#!/bin/bash
#.bashrc
# This file should override defaults in /etc/profile in /etc/bashrc.
# Check out what is in the system defaults before using this, make sure your $PATH is populated.
# To SSH between servers without password use:
# https://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/

################################################################################
# Bail out, if not running interactively (e.g. when sending data packets over with scp/rsync)
# Known bug, scp/rsync fail without this line due to greeting message: 
# 1) https://unix.stackexchange.com/questions/88602/scp-from-remote-host-fails-due-to-login-greeting-set-in-bashrc
# 2) https://unix.stackexchange.com/questions/18231/scp-fails-without-error
################################################################################
[[ $- != *i* ]] && return

################################################################################
# SHELL INTEGRATION; iTerm2 feature only
################################################################################
# printf "Enabling shell integration... "
# echo "Enabling shell integration."
[ -e "${HOME}/.iterm2_shell_integration.bash" ] && . "${HOME}/.iterm2_shell_integration.bash"
# echo "Done."

################################################################################
# Shell stuff
################################################################################
# Check if we are on MacOS
[[ "$OSTYPE" == "darwin"* ]] && macos=true || macos=false
# Mac loading; load /etc/profile (on macOS, this runs a path setup executeable and resets the $PATH variable)
# [ -f /etc/profile ] && . /etc/profile
# ...this itself should also run /etc/bashrc
# Linux loading; make sure default bashrc is loaded first, if exists
# [ -f /etc/bashrc ] && . /etc/bashrc
# [ -f /etc/profile ] && . /etc/profile

# Shell prompt stuff
set +H
  # turn off history expansion, so can use '!' in strings; see: https://unix.stackexchange.com/a/33341/112647
unset USERNAME # forum quote: "if you use the sudo command, sudo typically
  # sets USER to root and USERNAME to the user who invoked the sudo command"
shopt -s checkwinsize # allow window resizing
shopt -u nullglob # turn off nullglob; so e.g. no expansion of ?, *, attempted if no matches
shopt -u extglob # extended globbing; allows use of ?(), *(), +(), +(), @(), and !() with separation "|" for OR options
  # Note extended globbing IS ONLY USED WITH THESE PARENTHESES; otherwise is same
  # * Use rm !(*.jpg|*.gif|*.png) instead of rm *{.jpg,.gif,.png}, but latter raises error if one has 0 matches
  # * Extglob: ?=0-1, *=0-Inf, +=1-Inf, @=1, !=ONLY ZERO, [a|b|c]=1 item inside
  # * Normal glob: *=0-Inf, ?=1 EXACTLY, [abc]=1 item inside, [!abc]=ZERO items inside
  # * Special chars: [:alnum:]=(a-z,A-Z,0-9), [:space:] (whtespace), [:digit:]
export PS1='\[\033[1;37m\]\h[\j]:\W \u\$ \[\033[0m\]' # prompt string 1; shows "<comp name>:<work dir> <user>$"
  # style; the \[ \033 chars are escape codes for changing color, then restoring it at end
  # see: https://unix.stackexchange.com/a/124408/112647
# e.g. [[:space:]_-]) = whitespace, underscore, OR dash

# Vim stuff
# Thought about wrapping vim alias in function "tmux set-option mode-mouse off" but realized
# this option would become GLOBAL to other panes, which don't necessarily want
alias vims="vim -S .session.vim" # for working with obsession
export EDITOR=vim # default editor
export LC_ALL=en_US.UTF-8 # needed to make Vim syntastic work
bind -r '\C-s' # to enable C-s in Vim (normally caught by terminal as start/stop signal)
stty -ixon # for putty, have to edit STTY value and set ixon to zero in term options

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
# PATH management
################################################################################
if $macos; then
  # MAC OPTIONS
  # Defaults... but will reset them
  eval `/usr/libexec/path_helper -s`
  # Basics
  export PATH=""
  export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
  # LaTeX and X11
  export PATH="/opt/X11/bin:/Library/TeX/texbin:$PATH"
  # Macports 
  export PATH="/opt/local/bin:/opt/local/sbin:$PATH" # MacPorts compilation locations
  # Homebrew
  export PATH="/usr/local/bin:$PATH" # Homebrew package download locations

else
  # GAUSS OPTIONS
  if [ "$HOSTNAME" == "gauss" ]; then
    # Basics
    export PATH=""
    export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
    # Add all other utilities to path
    export PATH="/usr/local/netcdf4-pgi/bin:$PATH"
    export PATH="/usr/local/hdf5-pgi/bin:$PATH"
    export PATH="/usr/local/mpich3-pgi/bin:$PATH"
    # And PGI utilities, plus Matlab
    export PATH="/opt/pgi/linux86-64/2016/bin:/opt/Mathworks/R2016a/bin:$PATH"
    # And edit the library path
    export LD_LIBRARY_PATH="/usr/local/mpich3-pgi/lib:/usr/local/hdf5-pgi/lib:/usr/local/netcdf4-pgi/lib"
  fi
  
  # EUCLID OPTIONS
  if [ "$HOSTNAME" == "euclid" ]; then
    # Basics; all netcdf, mpich, etc. utilites already in in /usr/local/bin
    export PATH=""
    export PATH="/usr/local/bin:/usr/bin:/bin$PATH"
    # PGI utilites, plus Matlab
    export PATH="/opt/pgi/linux86-64/13.7/bin:/opt/Mathworks/bin:$PATH"
    # And edit the library path
    export LD_LIBRARY_PATH="/usr/local/lib"
  fi

  # MONDE OPTIONS
  if [[ "$HOSTNAME" =~ "monde" ]]; then # is actually monde.atmos.colostate.edu
    # Basics; all netcdf, mpich, etc. utilites already in in /usr/local/bin
    export PATH=""
    export PATH="/usr/lib64/qt-3.3/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin$PATH"
    # PGI utilites, plus Matlab
    source set_pgi.sh # is in /usr/local/bin
    # And edit the library path
    export LD_LIBRARY_PATH="/usr/lib64/mpich/lib:/usr/local/lib"
  fi

  # OLBERS OPTIONS
  if [ "$HOSTNAME" == "olbers" ]; then
    # Add netcdf4 executables to path, for ncdump
    export PATH="/usr/local/netcdf4-pgi/bin:$PATH" # fortran lib
    export PATH="/usr/local/netcdf4/bin:$PATH" # c lib
    # And HDF5 utilities (not needed now, but maybe someday)
    export PATH="/usr/local/hdf5/bin:$PATH"
    # And MPICH utilities
    export PATH="/usr/local/mpich3/bin:$PATH"
    # And PGI utilities
    export PATH="/opt/pgi/linux86-64/2017/bin:$PATH"
    # And edit library path
    export LD_LIBRARY_PATH=/usr/local/mpich3/lib:/usr/local/hdf5/lib:/usr/local/netcdf4/lib:/usr/local/netcdf4-pgi/lib
  fi
fi

# SAVE SIMPLE PATH FOR HOMEBREW
export SIMPLEPATH=$PATH
alias brew="PATH=$SIMPLEPATH brew"
# brew conflicts with anaconda (try "brew doctor" to see); keep those out of path

# EXECUTABLES IN HOME DIRECTORY
export PATH="$HOME:$PATH"

# NCL NCAR command language (had trouble getting it to work on Mac with conda, 
# but on Linux distributions seems to work fine inside anaconda)
# The Euclid/Gauss servers do not have NCL, so need to use conda
if $macos; then
  alias ncl="DYLD_LIBRARY_PATH=\"/usr/local/lib/gcc/4.9\" ncl"
  export PATH="$HOME/ncl/bin:$PATH" # NCL utilities
  export NCARG_ROOT="$HOME/ncl" # critically necessary to run NCL
    # by default, ncl tried to find dyld to /usr/local/lib/libgfortran.3.dylib; actually ends 
    # up in above path after brew install gcc49... and must install this rather than gcc, which 
    # loads libgfortran.3.dylib and yields gcc version 7
elif [[ "$HOSTNAME" =~ "monde" ]]; then # is actually monde.atmos.colostate.edu
  export NCARG_ROOT="/usr/local"
    # need this to function
fi

# ANACONDA options
export PATH="$HOME/anaconda3/bin:$PATH"
export PYTHONPATH="$HOME" # so can import packages in home directory
if [ "$HOSTNAME" == "euclid" ]; then
  # Home directory not backed up, should be thought of as scratch
  export PYTHONPATH="$HOME:/birner-home/ldavis"
fi

# MATLAB options
if $macos; then
  MATLABPATH='/Applications/MATLAB_R2014a.app/bin/matlab'
elif [ "$HOSTNAME" = "olbers" ]; then
  MATLABPATH='/opt/Mathworks/R2016a/bin/matlab'
fi
[ ! -z $MATLABPATH ] && alias matlab="$MATLABPATH -nodesktop -nosplash -r \"run('~/startup.m')\""


################################################################################
# General utilties, and colorizing them
################################################################################
# LS aliases, basic file management, helpful utilities
# * See the README; found the default LSCOLOR for mac, and roughly converted it
#   to be identical in SSH sessions
# * Run "dircolors" to output commands to set up current default LS_COLORS on 
#   Linux macthine. The default Mac LSCOLORS can be found in easy google search.
# * The commented-out export gives ls styles of Linux default, excluding filetype-specific ones
# * This page: https://geoff.greer.fm/lscolors/ gives easy conversion from BSD to
#   the Linux color string.
if $macos; then
  export LSCOLORS='exfxcxdxbxegedabagacad'
  sortcmd='gsort' && lscolor='-G' # GNU utilities, different from mac versions
    # macOS has a BSD ls version with different "show color" specifier
else
#   export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:'\
# 'or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:'
  export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
  lscolor='--color=always' && sortcmd='sort'
fi
alias ls="ls $lscolor -AF"   # ls useful (F differentiates directories from files)
alias ll="ls $lscolor -AFhl" # ls "list", just include details and file sizes
alias lx="ls $lscolor -AF -lsa | grep -E \"\-(([rw\-]{2})x){1,3}\"" # executables only
alias lf="ls -1 | sed -e \"s/\..*$//\"" # shows filenames without extensions
alias ld="find . -maxdepth 1 -mindepth 1 -type d -exec du -hs {} \; | $sortcmd -sh" # directory sizes
  # need COREUTILS for sort -h; use brew install coreutils, they're installed
  # with prefix g (the Linux version; MacOS comes with truncated versions)
alias df="df -h" # disk useage
alias cd="cd -P" # -P follows physical location
alias type="type -a" # alias 'type' to show ALL instances of path/function/variable/file
  # just some simple ones
alias hardware="cat /etc/*-release"  # print out Debian, etc. release info
  # prints out release info
alias ps="ps" # processes in this shell
alias pc="mpstat -P ALL 1" # list individual core usage
alias pt="top"             # table of processes, total
  # examine current proceses
hash colordiff 2>/dev/null && alias diff="colordiff"
  # prettier differencing; use this if it exists
alias difference="diff --brief -x \".*\" -r"
  # difference subdirectories; easier to remember this
function identical() { diff -sq $@ | grep identical; }
  # identical files in two directories
function join() { local IFS="$1"; shift; echo "$*"; }
  # join array elements by some separator
function listjobs() { [ -z "$1" ] && echo "ERROR: Must specify grep pattern." && return 1; ps | grep "$1" | cut -d' ' -f1 | xargs; }
  # list jobs by name
function killjobs() { [ -z "$1" ] && echo "ERROR: Must specify grep pattern." && return 1; kill $(ps | grep "$1" | cut -d' ' -f1 | xargs); }
  # kill jobs by name
# function killjobs() { kill $(jobs -p); }
#   # kill all background processes (sent to background with &)
#   # this function only works if sent to background from shell directly, not from script

# Standardize less/man/etc. colors
# [[ -f ~/.LESS_TERMCAP ]] && . ~/.LESS_TERMCAP # use colors for less, man, etc.
export LESS="--RAW-CONTROL-CHARS"
[ -f ~/.LESS_TERMCAP ] && . ~/.LESS_TERMCAP
if hash tput 2>/dev/null; then
  export LESS_TERMCAP_mb=$(tput setaf 2) # 2=green
  export LESS_TERMCAP_md=$(tput setaf 6) # cyan
    # took off "bold" for these; was too light
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

# Tool for changing iTerm2 profile before command executed, and returning
# after executed (e.g. interactive prompts)
function colorize() {
  # Get current profile name; courtesy of: https://stackoverflow.com/a/34452331/4970632
  # Or that's dumb and just use ITERM_PROFILE
  newprofile=FrontEndDelight
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

################################################################################
# Python workspace setup
################################################################################
# Interactive shell utilities
# Colorize them
# io="import pandas as pd; import xarray as xr; import netCDF4 as nc4; "
io="import pandas as pd; import xarray as xr; "
basic="import numpy as np; from datetime import datetime; from datetime import date; "
magic="get_ipython().magic('load_ext autoreload'); get_ipython().magic('autoreload 2'); "
plots=$($macos && echo "import matplotlib as mpl; mpl.use('MacOSX'); import matplotlib.pyplot as plt; ") # plots
pyfuncs=$($macos && echo "import pyfuncs.plots as py; ") # lots of plot-related stuff in here
alias ipython="colorize ipython --no-banner --no-confirm-exit --pprint -i -c \"$magic\""
alias pypython="colorize ipython --no-banner --no-confirm-exit --pprint -i -c \"$io$basic$magic$plots$pyfuncs\""
alias perl="colorize perl -de1" # pseudo-interactive console; from https://stackoverflow.com/a/73703/4970632
alias R="colorize R"

# Jupyter notebook aliases
# * First will set the jupyter theme. Makes all fonts the same size (10) and makes cells nice and wide (95%)
# * IMPORTANT note: to uninstall nbextensions completely, use `jupyter contrib nbextension uninstall --user` and
#   `pip uninstall jupyter_contrib_nbextensions`; remove the configurator with `jupyter nbextensions_configurator disable`
# * If you have issues where themes is just not changing in Chrome, open Developer tab with Cmd+Opt+I
#   and you can right-click refresh for a hard reset, cache reset
alias jtheme="jt -t grade3 -cellw 95% -nfs 10 -fs 10 -tfs 10 -ofs 10 -dfs 10"
jupyterready=false # theme is not initially setup because takes a long time
function notebook() {
  # Set the jupyter theme
  echo "Configuring jupyter notebook theme."
  ! $jupyterready && $jtheme # make it callable from command line
  jupyterready=true # this value is available for rest of session
  # Test the hostname and get unique port we have picked
  if [ ! -z $1 ]; then
    jupyterremote=$1 # override with user input
  else case ${HOSTNAME%%.*} in
      uriah)  jupyterport=20000;;
      gauss)  jupyterport=20001;;
      euclid) jupyterport=20002;;
      monde)  jupyterport=20003;;
      *)      echo "ERROR: No jupyterport assigned to hostname \"${HOSTNAME%%.*}\". Edit your .bashrc." && return 1 ;;
    esac
  fi
  # Create the notebook
  echo "Initializing jupyter notebook over port port: $jupyterport."
  jupyter notebook --no-browser --port=$jupyterport --NotebookApp.iopub_data_rate_limit=10000000
    # need to extend data rate limit when making some plots with lots of stuff
}
# See current ssh connections
alias connections="ps aux | grep ssh"
# Setup new connection to another server, enables REMOTE NOTEBOOK ACCESS
function connect() { # connect to remove notebook on port
  [ $# -lt 1 ] && echo "ERROR: Need at least 1 argument." && return 1
  local hostname=${1##*@} # the host we connect to, minus username
  if [ ! -z $2 ]; then
    jupyterconnect=$2 # override with user input
  else case ${hostname%%.*} in
      gauss)  jupyterconnect=20001;;
      euclid) jupyterconnect=20002;;
      monde)  jupyterconnect=20003;;
      *)      echo "ERROR: No jupyterport assigned to hostname \"$hostname\". Edit your .bashrc." && return 1
    esac
  fi
  # Establish the connection
  echo "Connecting to $hostname over port $jupyterconnect."
  echo "WARNING: Keep this window open to use your remote jupyter notebook!"
  \ssh -N -f -L localhost:$jupyterconnect:localhost:$jupyterconnect $hostname
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
    echo "ERROR: Must specify a port or make sure port is available from variable \"jupyterconnect\"."
    return 1
  fi
  # Disable the connection
  echo "Cancelling port-forwarding over port $jupyterdisconnect."
  lsof -t -i tcp:$jupyterdisconnect | xargs kill
  [ $? == 0 ] && unset jupyterconnect || echo "ERROR: Could not disconnect from port \"$jupyterdisconnect\"."
}

################################################################################
# Session management
################################################################################
# iTerm2 window title
function title { echo -ne "\033]0;"$*"\007"; } # name terminal title (also, Cmd-I from iterm2)

# Declare some names for active servers
# alias olbers='ssh -XC ldavis@129.82.49.1'
# export ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
export work='ldavis@10.83.16.91' # for scp'ing into my Mac
export home='ldavis@10.253.201.216'
export gauss='ldavis@gauss.atmos.colostate.edu'
export monde='ldavis@monde.atmos.colostate.edu'
export euclid='ldavis@euclid.atmos.colostate.edu'
export olbers='ldavis@olbers.atmos.colostate.edu'
export zephyr='lukelbd@zephyr.meteo.mcgill.ca'
export archive='ldm@ldm.atmos.colostate.edu' # atmos-2012
export ldm='ldm@ldm.atmos.colostate.edu' # atmos-2012
# export archive='/media/archives/reanalyses/era_interim/'
# export olbers='ldavis@129.82.49.159'

# Preface: enabling FILES WITH SPACES is tricky, need: https://stackoverflow.com/a/20364170/4970632
# 1) Basically have to escape the string "twice"; once in this shell, and again once re-interpreted by
# destination shell... however we ACTUALLY *DO* WANT THE TILDE TO EXPAND
# 2) Another weird thing; note we must ESCAPE TILDE IN A PARAMETER EXPANSION, even
# though this is not necessary in double quotes alone; makes sense... maybe...
# 3) BEWARE: replacing string with tilde in parameter expansion seems to behave DIFFERENTLY
# ACROSS DIFFERENT VERSIONS OF BASH. Test this with foo=~/data, foobar="${foo/#$HOME/~}".
#   * On Gauss (bash 4.3), you need to escape the tilde or surround it by quotes.
#   * On Mac (bash 4.4) and Euclid (bash 4.2), the escape \ or quotes "" are interpreted literally; need tilde by itself.

# Functions for scp-ing from local to remote, and vice versa
# For initial idea see: https://stackoverflow.com/a/25486130/4970632
# For exit on forward see: https://serverfault.com/a/577830/427991
# For why we alias the function see: https://serverfault.com/a/656535/427991
# For enter command then remain in shell see: https://serverfault.com/q/79645/427991
#   * Note this has nice side-effect of eliminating annoying "banner message"
#   * Why iterate from ports 10000 upward? Because is even though disable host key
#     checking, still get this warning message every time.
alias ssh="ssh_wrapper" # must be an alias or will fail!
function ssh_wrapper() {
  [ $# -lt 1 ] && echo "ERROR: Need at least 1 argument." && return 1
  port=10000 # starting port
  local listen=22 # default sshd listening port; see the link above
  local args=($@) # all arguments
  [[ ${args[0]} =~ ^[0-9]+$ ]] && port=(${args[0]}) && args=(${args[@]:1}) # override
  while netstat -an | grep ":$port" | grep -i listen &>/dev/null; do
    echo "WARNING: Port $port unavailable." # warning message
    port=$(($port + 1)) # generate new port
  done
  \ssh -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no -t \
    -R localhost:$port:localhost:$listen ${args[@]} \
    "export port=$port && echo Port number: $port && /bin/bash -i" # -t says to stay interactive
}
# Copy from <this server> to local macbook
function rlcp() {    # "copy to local (from remote); 'copy there'"
  [ $# -lt 2 ] && echo "ERROR: Need at least 2 arguments." && return 1
  local p=$port # default port
  local args=(${@:1:$#-2})   # $# stores number of args passed to shell, and perform minus 1
  [[ ${args[0]} =~ ^[0-9]+$ ]] && local p=${args[0]} && local args=(${args[@]:1})
  [ -z $p ] && echo "ERROR: Port unavailable."
  local file="${@:(-2):1}" # second to last
  local dest="${@:(-1)}"   # last value
  local dest="${dest/#$HOME/~}"  # restore expanded tilde
  local dest="${dest/#$HOME/\~}" # if previous one failed/was re-expanded, need to escape the tilde
  local dest="${dest//\ /\\\ }"  # escape whitespace manually
  echo "Copying $file on this server to home server at: $dest..."
  scp -o StrictHostKeyChecking=no -P$p ${args[@]} "$file" ldavis@127.0.0.1:"$dest"
}
# Copy from local macbook to <this server>
function lrcp() {    # "copy to remote (from local); 'copy here'"
  [ $# -lt 2 ] && echo "ERROR: Need at least 2 arguments." && return 1
  local p=$port # default port
  local args=(${@:1:$#-2})   # $# stores number of args passed to shell, and perform minus 1
  [[ ${args[0]} =~ ^[0-9]+$ ]] && local p=${args[0]} && local args=(${args[@]:1})
  [ -z $p ] && echo "ERROR: Port unavailable."
  local file="${@:(-2):1}" # second to last
  local dest="${@:(-1)}"   # last value
  local file="${file/#$HOME/~}"  # restore expanded tilde
  local file="${file/#$HOME/\~}" # if previous one failed/was re-expanded, need to escape the tilde
  local file="${file//\ /\\\ }"  # escape whitespace manually
  echo "Copying $file from home server to this server at: $dest..."
  scp -o StrictHostKeyChecking=no -P$p ${args[@]} ldavis@127.0.0.1:"$file" "$dest"
}
# Copy <file> on this server to another server, preserving full path but 
# RELATIVE TO HOME DIRECTORY; so, for example, from Guass to Home, have "data" folder on
# each and then subfolders with same experiment name
function ccp() {
  [ $# -lt 2 ] && echo "ERROR: Need at least 2 arguments. Final argument is server name." && return 1
  local p=$port # default port
  local args=(${@:1:$#-2})   # $# stores number of args passed to shell, and perform minus 1
  [[ ${args[0]} =~ ^[0-9]+$ ]] && local p=${args[0]} && local args=(${args[@]:1})
  [ -z $p ] && echo "ERROR: Port unavailable."
  local server=${@:(-1):1} # the last one
  local file=${@:(-2):1} # the 2nd to last
  if [[ "${file:0:1}" != "/" ]]; then
    local destfile="$(pwd -P)/$file"
  else local destfile="$file"
  fi
  local destfile=${destfile//\/Dropbox\//\/} # bunch of symlinked stuff in here
  local destfile=${destfile//$HOME/\~} # get error when doing this... for some reason
  echo "Copying $file to $destfile from $HOSTNAME to $server..."
  scp -o StrictHostKeyChecking=no -P$p ${args[@]} "$file" "$server":"$destfile"
    # note $file CANNOT contain the literal/escaped tilde; will not be expanded
    # by scp if quoted, but still need quotes in case name has spaces
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
  cat "$file" | sed '1,/^\\end{abstract}/d;/^\\begin{addendum}/,$d' \
    | sed '/^\\begin{/d;/^\\end{/d;/=/d' | detex -c | wc -w
    # * prints word count between end of abstract and start of methods
    # * explicitly delete begin/end environments because detex won't pick them up
    #   and use the equals sign to exclud equations
    # * note citations are left inside, but they are always right next to other
    #   words/not separated by whitespace so they don't affect wordcounts
}
# Our presentation software; install with commented line below from: http://pygobject.readthedocs.io/en/latest/getting_started.html
# brew install pygobject3 --with-python3 gtk+3 && /usr/local/bin/pip3 install pympress
alias pympress="LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/python3 /usr/local/bin/pympress"

################################################################################
# Dataset utilities
################################################################################
# NetCDF tools (should just remember these)
# NCKS behavior very different between versions, so use ncdump instead
#   * note if HDF4 is installed in your anaconda distro, ncdump will point to *that location* before
#     the homebrew install location 'brew tap homebrew/science, brew install cdo'
#   * this is bad, because the current version can't read netcdf4 files; you really don't need HDF4,
#     so just don't install it
alias ncdump="ncdump -h" # almost always want this; access old versions in functions with backslash
function ncinfo() { # only get text between variables: and linebreak before global attributes
  [ -z "$1" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  \ncdump -h "$1" | sed '/^$/q' | sed '1,1d;$d' # trims first and last lines; do not need these
}
function ncvarsinfo() { # get information for just variables (no dimension/global info)
    # the cdo parameter table actually gives a subset of this information, so don't
    # bother parsing that information
  [ -z "$1" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  \ncdump -h "$1" | grep -A 100 "^variables:$" | grep -B 100 "^$" | sed $'s/^\t//g' | grep -v "^$" | grep -v "^variables:$"
    # the space makes sure it isn't another variable that has trailing-substring
    # identical to this variable; and the $'' is how to insert literal tab
    # -A means print x TRAILING lines starting from FIRST match
    # -B means prinx x PRECEDING lines starting from LAST match
}
function ncdimsinfo() { # get information for just variables (no dimension/global info)
    # the cdo parameter table actually gives a subset of this information, so don't
    # bother parsing that information
  [ -z "$1" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  \ncdump -h "$1" | grep -B 100 "^variables:$" | sed '1,2d;$d' | tr -d ';' | tr -s ' ' | column -t
    # the space makes sure it isn't another variable that has trailing-substring
    # identical to this variable; and the $'' is how to insert literal tab
    # -A means print x TRAILING lines starting from FIRST match
    # -B means prinx x PRECEDING lines starting from LAST match
}
function nclist() { # only get text between variables: and linebreak before global attributes
  [ -z "$1" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  \ncdump -h "$1" | sed -n '/variables:/,$p' | sed '/^$/q' | grep -v '[:=]' \
    | cut -d '(' -f 1 | sed 's/.* //g' | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
function ncdimlist() { # get list of dimensions
  [ -z "$1" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  \ncdump -h "$1" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
    | cut -d '=' -f 1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
function ncvarlist() { # only get text between variables: and linebreak before global attributes
  [ -z "$1" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  # cdo -s showname "$1" # this omits some "weird" variables that don't fit into CDO
  #   # data model, so don't use this approach
  local list=($(nclist "$1"))
  local dmnlist=($(ncdmnlist "$1"))
  local varlist=() # add variables here
  for item in "${list[@]}"; do
    if [[ ! " ${dmnlist[@]} " =~ " $item " ]]; then
      varlist+=("$item")
    fi
  done
  echo "${varlist[@]}" | tr -s ' ' '\n' | grep -v '[{}]' | sort # print results
}
function ncvarinfo() { # as above but just for one variable
  [ -z "$1" ] && { echo "Must declare variable name."; return 1; }
  [ -z "$2" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  \ncdump -h "$2" | grep -A 100 "[[:space:]]$1(" | grep -B 100 "[[:space:]]$1:" | sed "s/$1://g" | sed $'s/^\t//g'
    # the space makes sure it isn't another variable that has trailing-substring
    # identical to this variable; and the $'' is how to insert literal tab
    # -A means print x TRAILING lines starting from FIRST match
    # -B means prinx x PRECEDING lines starting from LAST match
}
function ncvardump() { # dump variable contents (first argument) from file (second argument)
  [ -z "$1" ] && { echo "Must declare variable name."; return 1; }
  [ -z "$2" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  $macos && reverse="tail -r" || reverse="tac"
  # \ncdump -v "$1" "$2" | grep -A 100 "^data:" | tail -n +3 | $reverse | tail -n +2 | $reverse
  \ncdump -v "$1" "$2" | $reverse | egrep -m 1 -B 100 "[[:space:]]$1[[:space:]]" | sed '1,1d' | $reverse
    # shhh... just let it happen baby
    # tail -r reverses stuff, then can grep to get the 1st match and use the before flag to print stuff
    # before (need extended grep to get the coordinate name), then trim the first line (curly brace) and reverse
}
function ncvardata() { # parses the CDO parameter table; ncvarinfo replaces this
  [ -z "$1" ] && { echo "Must declare variable name."; return 1; }
  [ -z "$2" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  cdo infon -seltimestep,1 -selname,"$1" "$2" 2>/dev/null | tr -s ' ' | cut -d ' ' -f 6,8,10-12 | column -t
    # this procedure is ideal for "sanity checks" of data; just test one
    # timestep slice at every level; the tr -s ' ' trims multiple whitespace to single
    # and the column command re-aligns columns
}
function ncvartable() { # as above but show everything
  [ -z "$1" ] && { echo "Must declare variable name."; return 1; }
  [ -z "$2" ] && { echo "Must declare file name."; return 1; }
  [ ! -r "$2" ] && { echo "File \"$2\" not found."; return 1; }
  cdo infon -seltimestep,1 -selname,"$1" "$2" 2>/dev/null
}
# Extract generalized files
function extract() {
  for name in "$@"; do
      # shell actually passes **already expanded** glob pattern when you call it as argument
      # to a function; so, need to cat all input arguments with @ into list
    if [ -f "$name" ] ; then
      case "$name" in
        *.tar.bz2)   tar xvjf "$name"    ;;
        *.tar.xz)    tar xf "$name"      ;;
        *.tar.gz)    tar xvzf "$name"    ;;
        *.bz2)       bunzip2 "$name"     ;;
        *.rar)       unrar x "$name"     ;;
        *.gz)        gunzip "$name"      ;;
        *.tar)       tar xvf "$name"     ;;
        *.tbz2)      tar xvjf "$name"    ;;
        *.tgz)       tar xvzf "$name"    ;;
        *.zip)       unzip "$name"       ;;
        *.Z)         uncompress "$name"  ;;
        *.7z)        7z x "$name"        ;;
        *)           echo "Don't know how to extract '$name'..." ;;
      esac
      echo "'$name' was extracted."
    else
      echo "'$name' is not a valid file!"
    fi
  done
}

################################################################################
# Personal utilities/for MacBook specially
################################################################################
if $macos; then
  # Opening commands for some GUI apps
  alias edit='\open -a TextEdit'
  alias html='\open -a Google\ Chrome'
  alias pdf='\open -a Skim'
  # Fun stuff
  alias music="ls -1 *.{mp3,m4a} | sed -e \"s/\ \-\ .*$//\" | uniq -c | $sortcmd -sn | $sortcmd -sn -r -k 2,1"
  alias weather="curl wttr.in/Fort\ Collins" # list weather information
fi
# Sync a local directory with files on SD card
# This function will only modify files on the SD card, never the local directory
function sdsync() {
  # Behavior option: check for modified files?
  # Only problem: file "modified" every time transferred to SD card
  updateold=true
  # Can change this, but default will be to sync playlist
  sdcard="NO NAME" # edit when get new card
  sdloc="/Volumes/$sdcard/Playlist" # sd data
  locloc="$HOME/Google Drive/Playlist" # local data
  echo "SD Location: $sdloc"
  echo "Local location: $locloc"
  # Iterate through local files
  copied=false # copied anything?
  updated=false # updated anything?
  deleted=false # deleted anything?
  shopt -s nullglob
  $macos && date=gdate || date=date
  for path in "$locloc/"*.{mp3,m4a,m3u8}; do
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
  for path in "$sdloc/"*.{mp3,m4a,m3ua}; do
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
# Tab completion
################################################################################
# Use "complete" command for setup
# -d filters to only directories
# -f filters to only files
# -X filters based on EXTENDED GLOBBING pattern (search that)
complete -d cd # complete changes behavior of "Tab" after command; cd
  # shows only DIRECTORIES now
complete -f -X '!*.pdf' -o plusdirs skim  # changes behavior of my alias "skim"; shows only
  # FILES (-f), REMOVES (-X) entries satsifying glob string "NOT <stuff>.pdf"
complete -f -X '!*.html' -o plusdirs html # for opening HTML files in chrome
complete -f -X '!*.@(avi|mov|mp4)' -o plusdirs vlc # for movies; require one of these
complete -f -X '!*.@(jpg|jpeg|png|gif|eps|dvi|pdf|ps|svg)' -o plusdirs preview
complete -f -X '!*.@(tex|py)' -o plusdirs latex
complete -f -X '!*.m' -o plusdirs matlab # for matlab help documentation
complete -f -X '!*.nc' -o plusdirs ncdump # for matlab help documentation
complete -f -X '*.@(pdf|png|jpg|jpeg|gif|eps|dvi|pdf|ps|svg|nc|aux|hdf|grib)' -o plusdirs vim
# Some shells disable tab-completion of dangerous commands; re-enable
complete -f -o plusdirs mv
complete -f -o plusdirs rm

################################################################################
# Message
# If github push/pulls will require password, configure with SSH (may require
# entering password once) or configure with http (stores information in plaintext
# but only ever have to do this once)
################################################################################
# $macos || { \ssh -oBatchMode=yes -T git@github.com true &>/dev/null; [ $? == 255 ] && eval $(ssh-agent -s) && ssh-add && echo "Added SSH key for github."; }
# $macos || { [ ! -e ~/.git-credentials ] && git config --global credential.helper store && \ssh -T git@github.com; }
$macos || { [ ! -e ~/.git-credentials ] && git config --global credential.helper store && echo "You may be prompted for a username+password when you enter a git command."; }
$macos && { grep '/usr/local/bin/bash' /etc/shells 1>/dev/null || sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'; }
$macos && { [[ $BASH_VERSION =~ ^4.* ]] || chsh -s /usr/local/bin/bash; }
$macos && fortune | lolcat || { curl https://icanhazdadjoke.com/; echo; }
# $macos && fortune | lolcat || echo "Shell configured and namespace populated."
# $macos && { neofetch --config off --color_blocks off --colors 4 1 8 8 8 7 --disable term && fortune | lolcat; } || echo "Shell configured and namespace populated."
# alias clock="while true; do echo \"$(date '+%D %T' | toilet -f term -F border --metal)\"; sleep 1; done"
# alias hack="cmatrix"
# hash powerline-shell 2>/dev/null && { # ooglay so forget it
#   function _update_ps1() {
#     PS1="$(powerline-shell $?)"
#     }
#   if [ "$TERM" != "linux" ]; then
#     PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
#   fi
#   }

################################################################################
# Notes
################################################################################
# BASH NOTES:
#  -prefix key for issuing SSH-session commands is '~'; 'exit' sometimes doesn't work (perhaps because
#   if aliased or some 'exit' is in $PATH
#     C-d/'exit' -- IF AVAILABLE, exit SSH session
#     ~./~C-z -- Exit SSH session
#     ~& -- Puts SSH into background
#     ~# -- Gives list of forwarded connections in this session
#     ~? -- Gives list of these commands
#  -extended globbing explanations, see:
#     http://mywiki.wooledge.org/glob
#  -use '<package_manager> list' for MOST PACKAGE MANAGERS to see what is installed
#     e.g. brew list, conda list, pip list
#  -use unalias <alias> to remove alias name, and use
#       unset <function> to remove function name OR variable
#  -use type <name> for GENERAL variable/alias/function/file/path
#       whereis <name> for FILE/PATH location. alias with -a to show all opts
#
# PYTHON NOTES: python often has many different installations; we try to clear
# pip, easy_install, ipython (python 2.x in /usr/local/bin package management)
# some of that up here; use 'type ipython', 'type python', 'type pip', etc.
# to figure out where the command-line python stuff is; and ONCE INSIDE python,
# type 'import sys; sys.path' to see where PACKAGES are located on OS, and their
# priority. Each python might have a different sys.path. sys.path is populated
# by the WORKING DIRECTORY, followed by DIRECTORIES IN $PYTHONPATH (if any),
# followed by INSTALLATION-DEPENDENT DEFAULTS controlled by site.py file (this
# should be in every directory that has python). for any package, check out
# <pckg_nm>.__file__ to find its location
# * Currently have python in the following directories:
#     /usr/bin (system default; v2.7.10)
#     /usr/local/bin (Homebrew location; v2.7.13)
#       pip ALSO HERE, since it is not included by default; Homebrew installed
#     /opt/local/bin (Macports location; v2.7.12)
#       here it is ONLY IN python2.7 version; nothing with just "python"
#     ~/anaconda/bin (Anaconda location; v3.5.2)
#       pip will GET PUT HERE if you conda install it
# * Using pip install seems to BY DEFAULT go to a site-packages folder (rest of
#       sys.path is included by default, maybe standard library); the locations
#       of each for each distribution are...
#     /usr/bin --> /Library/Python/2.7/site-packages
#       ...maybe goes here with easy_install.sh?
#     /usr/local/bin --> /usr/local/lib/python2.7/site-packages
#       ...which is where HOMEBREW-DOWNLOADED PIP INSTALLS STUFF
#     /opt/local/bin --> none, evidently
#       ...maybe just leave this installation, can't be invoked
#     ~/anaconda/bin --> ~/anaconda/lib/python3.5/site-packages
#       ...where conda install puts stuff
# * Conda NEEDS PIP to operate (under the hood), but we never want to use it
#       ourselves; should alias pip to original Homebrew version.
#       then...
#         -use pip to install/update python 2.x packages
#         -use conda to install/update python 3.x packages in ~/anaconda/bin
# * Various versions are required for various things, so can't delete any of
#   these, but better to modify LOCAL VERSION OF PYTHON2.X (in /usr/local/bin)
#   than SYSTEM-WIDE version; otherwise need sudo pip, which is bad practice
# * So use the /usr/local/bin 'pip', 'python', and 'ipython', and run
#   pip install <pckg_name> with SHEBANG AT THE TOP '#!/usr/local/bin/python
#   (this is important because BY DEFAULT, even with brew install, it sometimes
#   uses #!/usr/bin/python -- pip IS NOT PYTHON SPECIFIC; just installs packages
#   according to WHICHEVER PYTHON THE SHEBANG POINTS TO)
# * Also if NON-EMPTY, /usr/local/bin python or ipython will add to their
#   paths 'Users/ldavis/Library/Python/2.7/lib/python/site-packages'... weird!
#   installation goes there when using 'pip install --user' option
#
# IPYTHON NOTES: for...
#   -ipython, use %matplotlib qt5 or --matplotlib=qt5;
#   -qtconsole, use %matplotlib qt5 or --matplotlib=;
#   -notebook, use %matplotlib notebook in the relavent cell
#   -qt5 better than osx, because gives "save as" options (filetype).
#
# TABLE OF RESULTS:
#  FOR IPYTHON TERMINAL:
#  GUI SPEC:
#    --gui=qt, %matplotlib qt: after trying to declare figure, get "missing 1 requiredositional argument: 'figure'" (um... what?)
#  --gui=qt, --matplotlib=qt: get "no module named PyQt4"
#  --gui=qt, %matplotlib qt5: success; different window format than osx, with save dialogue offering filetype choice
#  --gui=qt, --matplotlib=qt5: success; same as above
#  --gui=qt, %matplotlib osx: success; windowops up as separate application
#  --gui=qt, --matplotlib=osx: QApplication window NEVER STARTS; fig appears asopup/part of terminal application, does not have its own "window"
#  NO GUI SPEC:
#  --matplotlib=qt5 OR %matplotlib qt5: success
#  --matplotlib=qt OR%matplotlib qt: get "no module named PyQt4"
#  --matplotlib=osx OR %matplotlib osx: QApplication window NEVER STARTS; fig appears as temporaryopup
#  FOR JUPYTER QTCONSOLE using jupyter qtconsole -- (args follow)
# GUI SPEC:
#    --gui=qt, %matplotlib qt5: get "RuntimeError: Cannot activate multiple GUI eventloops"
#    --gui=qt, --matplotlib=qt5: works, creates QApplication window for figures (seriously... WHAT? then why the hell doesn't %matplotlib qt5 work?)
#    --gui=qt, --matplotlib=inline OR %matplotlib inline: after trying to uselt.show(), get "matplotlib is currently using a non-GUI backend,"
#  --gui=qt, %matplotlib osx: get "RuntimeError: Cannot activate multiple GUI eventloops"
#  --gui=qt, --matplotlib=osx: works, but NO QApplication window; just a window-lessopup
#  NO GUI SPEC:
#  --matplotlib=qt5 OR %matplotlib qt5: same as above, works
#  --matplotlib=osx OR %matplotlib osx: same as above, NO QApplication
#  --matplotlib=inline OR %matplotlib inline: after trying to uselt.show(), get "matplotlib is currently using a non-GUI backend,"
#  --matplotlib=qt: get "Eventloop or matplotlib integration failed. Is matplotlib installed?"
#  %matplotlib qt: get "no module named PyQt4"
#  ...if behavior different from listed above,erhaps order of loading modules in -r file causes this
#  FOR JUPYTER NOTEBOOK (no command-line options for notebook server, must specify in notebook cells)
#    %matplotlib inline: after trying to uselt.show(), get "matplotlib is currently using a non- GUI backend,"
#  %matplotlib notebook: works fine
