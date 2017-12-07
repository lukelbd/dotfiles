#!/bin/bash
#.bashrc
# This file should override defaults in /etc/profile in /etc/bashrc.
# Check out what is in the system defaults before using this, make sure
# your $PATH is populated.

################################################################################
# Bail out, if not running interactively (e.g. when sending data packets over with scp/rsync)
# Known bug, scp/rsync fail without this line due to greeting message: 
# 1) https://unix.stackexchange.com/questions/88602/scp-from-remote-host-fails-due-to-login-greeting-set-in-bashrc
# 2) https://unix.stackexchange.com/questions/18231/scp-fails-without-error
################################################################################
[[ $- != *i* ]] && return

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
shopt -u extglob # extended globbing; allows use of ?(), *(), +(), +(), @(), and !() with
  # separation OR using |; EXTENDED allows e.g. rm !(*.jpg|*.gif|*.png);
# Yes extglob: ?=0-1, *=0-Inf, +=1-Inf, @=1, !=ONLY ZERO, [a|b|c]=1 item inside
# No extglob: *=0-Inf, ?=1 EXACTLY, [abc]=1 item inside, [!abc]=ZERO items inside
# Special chars: [:alnum:]=(a-z,A-Z,0-9), [:space:] (whtespace), [:digit:]
# e.g. [[:space:]_-]) = whitespace, underscore, OR dash

# Left-hand prompt style
export PS1='\h[\j]:\W \u\$ ' # prompt string 1; shows "<comp name>:<work dir> <user>$"

# Vim stuff
alias vims="vim -S .session.vim" # for working with obsession
export EDITOR=vim # default editor
export LC_ALL=en_US.UTF-8 # needed to make Vim syntastic work
bind -r '\C-s' # to enable C-s in Vim (normally caught by terminal as start/stop signal)
stty -ixon # for putty, have to edit STTY value and set ixon to zero in term options

# Magic changing stderr color
# See comment: https://stackoverflow.com/a/21320645/4970632
# See exec summary: https://stackoverflow.com/a/18351547/4970632
# For trap info: https://www.computerhope.com/unix/utrap.htm
# But unreliable; there is issue with sometimes no newline generated
export COLOR_RED="$(tput setaf 1)"
export COLOR_RESET="$(tput sgr0)"
exec 9>&2 # copy error descriptor onto write file descriptor 9
exec 8> >( # open this "process substitution" for writing on descriptor 8
  # while IFS='' read -r -d $'\0' line || [ -n "$line" ]; do
  while IFS='' read -r line || [ -n "$line" ]; do
    echo -e "${COLOR_RED}${line}${COLOR_RESET}" # -n is non-empty; this terminates at end
  done # "read" reads from standard input (whatever stream fed into this process)
)
# function undirect(){ echo -ne '\0'; exec 2>&9; } # return stream 2 to "dummy stream" 9
function undirect(){ exec 2>&9; } # return stream 2 to "dummy stream" 9
function redirect(){
  local PRG="${BASH_COMMAND%% *}" # ignore flags/arguments
  for X in ${STDERR_COLOR_EXCEPTIONS[@]}; do
    [ "$X" == "${PRG##*/}" ] && return 1; # trim directories
  done # if special program, don't send to coloring stream
  exec 2>&8 # send stream 2 to the coloring stream
}
trap "redirect;" DEBUG # trap executes whenever receiving signal <ARG> (here, "DEBUG"==every simple command)
export PROMPT_COMMAND="undirect;" # execute this just before prompt PS1 is printed (so after stderr/stdout printing)
export STDERR_COLOR_EXCEPTIONS=(wget scp ssh mpstat top source .  diff sdsync # commands
  node rhino ncl matlab # misc languages; javascript, NCL, matlab
  cdo conda pip easy_install python ipython jupyter notebook qtpython) # python stuff
  # interactive stuff gets SUPER WONKY if you try to redirect it with this script

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
if $macos; then
  alias ncl="DYLD_LIBRARY_PATH=\"/usr/local/lib/gcc/4.9\" ncl"
  export PATH="$HOME/ncl/bin:$PATH" # NCL utilities
  export NCARG_ROOT="$HOME/ncl" # critically necessary to run NCL
    # by default, ncl tried to find dyld to /usr/local/lib/libgfortran.3.dylib; actually ends 
    # up in above path after brew install gcc49... and must install this rather than gcc, which 
    # loads libgfortran.3.dylib and yields gcc version 7
fi

# ANACONDA options
export PATH="$HOME/anaconda3/bin:$PATH"
export PYTHONPATH="$HOME" # so can import packages in home directory
if [ "$HOSTNAME" == "euclid" ]; then
  # Home directory not backed up, should be thought of as scratch
  export PYTHONPATH="$HOME:/birner-home/ldavis"
fi

################################################################################
# More general utilties
################################################################################
if $macos; then
  # Programs from command line
  alias preview='open -a Preview'
  alias chrome='open -a Google\ Chrome'
  alias skim='open -a Skim'
fi

# Matlab
if $macos; then
  bmatlab='/Applications/MATLAB_R2014a.app/bin/matlab'
  bmatlab2012='/Applications/MATLAB_R2012b.app/bin/matlab'
elif [ "$HOSTNAME" = "olbers" ]; then
  bmatlab='/opt/Mathworks/R2016a/bin/matlab'
fi
alias matlab="$bmatlab -nodesktop -nosplash -r \"run('~/startup.m')\""
alias matlab2012="$bmatlab2012 -nodesktop -nosplash -r \"run('~/startup.m')\""

# Python aliases, 0) Anaconda distro
# ...anaconda versions should be defaults, since prepended the conda bin to $PATH
# io="import pandas as pd; import xarray as xr; import netCDF4 as nc4; "
io="import pandas as pd; import xarray as xr; "
basic="import numpy as np; from datetime import datetime; from datetime import date; "
magic="get_ipython().magic('load_ext autoreload'); get_ipython().magic('autoreload 2'); "
plots=$($macos && echo "import matplotlib as mpl; mpl.use('MacOSX'); import matplotlib.pyplot as plt; ") # plots
pyfuncs=$($macos && echo "import pyfuncs.plots as py; ") # lots of plot-related stuff in here
alias ipython="ipython --no-banner --no-confirm-exit --pprint -i -c \"$magic\""
alias pypython="ipython --no-banner --no-confirm-exit --pprint -i -c \"$io$basic$magic$plots$pyfuncs\""
alias perl="perl -de1" # pseudo-interactive console; from https://stackoverflow.com/a/73703/4970632
# Start up notebook; optionally specify port
function notebook() {
  [ ! -z $1 ] && port="--port=$1"
  echo "Using port: $1"
  jupyter notebook --no-browser $port --NotebookApp.iopub_data_rate_limit=10000000
  } # need to extend data rate limit when making some plots with lots of stuff
# Set up connection to another server, enables REMOTE NOTEBOOK ACCESS
function connect() { # connect to remove notebook on port
  if [ -z $1 ]; then
    echo "Must enter the hostname."
  else
  \ssh -N -f -L localhost:8880:localhost:8880 $1 # backslash says to ignore aliases
      # necessary because have ssh alias to allow for port forwarding back to localhost from
      # a remote host, for easy/simplified file transfer
  fi
}

################################################################################
# General utilties
################################################################################
# LS aliases, basic file management, helpful utilities
if [[ "$OSTYPE" =~ darwin ]]; then
  lscolor='-G'    # macOS has a BSD ls version with different "show color" specifier
  sortcmd='gsort' # GNU utilities, different from mac versions
else
  lscolor='--color=always'
  sortcmd='sort'
fi
alias ls="ls $lscolor -AF"   # ls useful (F differentiates directories from files)
alias ll="ls $lscolor -AFhl" # ls "list", just include details and file sizes
alias lx="ls $lscolor -AF -lsa | grep -E \"\-(([rw\-]{2})x){1,3}\"" # executables only
alias lf="ls -1 | sed -e \"s/\..*$//\"" # shows filenames without extensions
alias ld="find . -maxdepth 1 -type d -mindepth 1 -exec du -hs {} \; | $sortcmd -sh" # directory sizes
  # need COREUTILS for sort -h; use brew install coreutils, they're installed
  # with prefix g (the Linux version; MacOS comes with truncated versions)
alias df="df -h"          # disk useage
alias cd="cd -P" # -P follows physical location
alias type="type -a" # alias 'type' to show ALL instances of path/function/variable/file
  # just some simple ones
alias hardware="cat /etc/*-release"  # print out Debian, etc. release info
  # prints out release info
alias ps="ps" # processes in this shell
alias pc="mpstat -P ALL 1" # list individual core usage
alias pt="top"             # table of processes, total
  # examine current proceses
alias music="ls -1 *.{mp3,m4a} | sed -e \"s/\ \-\ .*$//\" | uniq -c | $sortcmd -sn | $sortcmd -sn -r -k 2,1"
  # list number of songs per artist; can't have leading spaces in line continuation
alias weather="curl wttr.in/Fort\ Collins" # list weather information
#   # shows filenames without extensions; isn't SED awesome? the -1 forces
#   # one-per-line output, the -e appends command to each line in pipe,
alias gitt="git log --graph --pretty=format:\"%h %d - %an, %ar : %s\""
  # nice git log (should maybe use git-config instead; check stack overflow,
  # but not sure how to SAVE those shortcuts)

# NetCDF tools (should just remember these)
# NCKS behavior very different between versions, so use ncdump instead
function ncdmnlist() {
  ncdump -h $1 | sed -n '/dimensions:/,$p' | sed '/variables:/q' | cut -d '=' -f 1 -s | xargs;
}
function ncvarlist() { # only get text between variables: and linebreak before global attributes
  ncdump -h $1 | sed -n '/variables:/,$p' | sed '/^$/q' | grep -v '[:=]' \
    | cut -d '(' -f 1 | sed 's/.* //g' | xargs;
}
function ncvardump() {
  ncks -s "%f " -H -C -v $1 $2;
}
# function ncdmnlist() { ncks -m $1 | cut -d ':' -f 1 | cut -d '=' -s -f 1 | xargs; }
# function ncvarlist() { ncks -m $1 | grep -v '[:=]' | cut -d '(' -f 1 -s | sed 's/.* //g' | xargs; }
# function ncvarlist2() { ncks -m $1 | grep "^\S*:" | cut -d ':' -f 1 -s | xargs; }
# alias ln="cdo sinfon" # list netcdf information with CDO; this is my favorite format
# alias lh="ncdump -h"  # with ncdump; h for 'headers'
# function lv() { ncdump -t "-v,$1" "$2"; } # list variable
#   # note if HDF4 is installed in your anaconda distro, ncdump will point to *that location* before
#   # the homebrew install location 'brew tap homebrew/science, brew install cdo'...which is bad, because
#   # the current version can't read netcdf4 files; you really don't need HDF4, so just don't install it

# Session management
# alias olbers='ssh -XC ldavis@129.82.49.1'
# export ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
export work='ldavis@10.83.16.91' # for scp'ing into my Mac
export home='ldavis@10.253.201.216'
export gauss='ldavis@gauss.atmos.colostate.edu'
export monde='ldavis@monde.atmos.colostate.edu'
export euclid='ldavis@euclid.atmos.colostate.edu'
export olbers='ldavis@olbers.atmos.colostate.edu'
export zephyr='lukelbd@zephyr.meteo.mcgill.ca'
export archive='/media/archives/reanalyses/era_interim/'
# export olbers='ldavis@129.82.49.159'
function title { echo -ne "\033]0;"$*"\007"; } # name terminal title (also, Cmd-I from iterm2)

# Tab completion control; use "complete" command
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

# Functions for scp-ing from local to remote, and vice versa
# See: https://stackoverflow.com/a/25486130/4970632
alias ssh="ssh -R 127.0.0.1:2222:127.0.0.1:22" # enables remote forwarding through port 2222... not sure exactly how it works
# Copy from <this server> to local macbook
function rlcp() {    # "copy to local (from remote); 'copy there'"
  args=${@:1:$#-2}  # $# stores number of args passed to shell, and perform minus 1
  file="${@:(-2):1}"  # second to last
  dest="${@:(-1)}"    # !# apparently gets last value
  dest="${dest/#$HOME/\~}" # ~ will be expanded before passing to variable; if in destination argument, put ~ back
  echo "Copying $file on this server to home server at: $dest..."
  scp -P2222 $args "$file" ldavis@127.0.0.1:"$dest"
}
# Copy from local macbook to <this server>
function lrcp() {    # "copy to remote (from local); 'copy here'"
  args=${@:1:$#-2}  # $# stores number of args passed to shell, and perform minus 1
  file="${@:(-2):1}"  # second to last value
  dest="${@:(-1)}"    # !# apparently gets last value
  file="${file/#$HOME/\~}"
  echo "Copying $file from home server to this server at: $dest..."
  scp -P2222 $args ldavis@127.0.0.1:"$file" "$dest"
    # quote stuff we want to be ONE argument
}
# Copy <file> on this server to another server, preserving full path but 
# RELATIVE TO HOME DIRECTORY; so, for example, from Guass to Home, have "data" folder on
# each and then subfolders with same experiment name
function ccp() {
  if [ $# -lt 2 ]; then # number of args < 2
    echo "ERROR: Need at least two arguments. Final argument is server name."
    return 1
  fi
  args=${@:1:$#-2} # up to 2nd from last
  server=${@:(-1):1} # the last one
  file=${@:(-2):1} # the 2nd to last
  if [[ "${file:0:1}" != "/" ]]; then
    destfile="$(pwd -P)/$file"
  else
    destfile="$file"
  fi
  destfile=${destfile//\/Dropbox\//\/} # bunch of symlinked stuff in here
  destfile=${destfile//$HOME/\~} # get error when doing this... for some reason
  echo "Copying $file to $destfile from $HOSTNAME to $server..."
  scp $args "$file" "$server":"$destfile"
    # note $file CANNOT contain the literal/escaped tilde; will not be expanded
    # by scp if quoted, but still need quotes in case name has spaces
}

# Extract generalized files
function extract() {
  for name in "$@"; do
      # shell actually passes **already expanded** glob pattern when you call it as argument
      # to a function; so, need to cat all input arguments with @ into list
    if [[ -f $name ]] ; then
        case $name in
            *.tar.bz2)   tar xvjf $name    ;;
            *.tar.xz)    tar xf $name      ;;
            *.tar.gz)    tar xvzf $name    ;;
            *.bz2)       bunzip2 $name     ;;
            *.rar)       unrar x $name     ;;
            *.gz)        gunzip $name      ;;
            *.tar)       tar xvf $name     ;;
            *.tbz2)      tar xvjf $name    ;;
            *.tgz)       tar xvzf $name    ;;
            *.zip)       unzip $name       ;;
            *.Z)         uncompress $name  ;;
            *.7z)        7z x $name        ;;
            *)           echo "don't know how to extract '$name'..." ;;
        esac
        echo "$name was extracted."
    else
        echo "'$name' is not a valid file!"
    fi
  done
}

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
  for path in "$locloc/"*.{mp3,m4a}; do
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
  for path in "$sdloc/"*.{mp3,m4a}; do
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

# Color support for less, man, etc.
# [[ -f ~/.LESS_TERMCAP ]] && . ~/.LESS_TERMCAP # use colors for less, man, etc.
export LESS="--RAW-CONTROL-CHARS"
if [ -f ~/.LESS_TERMPCAMP ]; then
  . ~/.LESS_TERMCAP
fi
if hash tput 2>/dev/null; then
  # Color configuration
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
  # export LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
  # export LESS_TERMCAP_md=$(tput bold; tput setaf 6) # cyan
  # From general .bashrc StackOverflow thread
  #export LESS_TERMCAP_mb=$'\E[01;31m'
  #export LESS_TERMCAP_md=$'\E[01;31m'
  #export LESS_TERMCAP_me=$'\E[0m'
  #export LESS_TERMCAP_se=$'\E[0m'
  #export LESS_TERMCAP_so=$'\E[01;44;33m'
  #export LESS_TERMCAP_ue=$'\E[0m'
  #export LESS_TERMCAP_us=$'\E[01;32m'
fi

# Powerline-shell prompt (ugly, so forget it)
# hash powerline-shell 2>/dev/null && {
#   function _update_ps1() {
#     PS1="$(powerline-shell $?)"
#     }
#   if [ "$TERM" != "linux" ]; then
#     PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
#   fi
#   }

echo 'Custom .bashrc loaded; aliases/functions declared.'

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
# ....
#   -currently have python in the following directories:
#     /usr/bin (system default; v2.7.10)
#     /usr/local/bin (Homebrew location; v2.7.13)
#       pip ALSO HERE, since it is not included by default; Homebrew installed
#     /opt/local/bin (Macports location; v2.7.12)
#       here it is ONLY IN python2.7 version; nothing with just "python"
#     ~/anaconda/bin (Anaconda location; v3.5.2)
#       pip will GET PUT HERE if you conda install it
#   -pip install seems to BY DEFAULT go to a site-packages folder (rest of
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
#   -conda NEEDS PIP to operate (under the hood), but we never want to use it
#       ourselves; should alias pip to original Homebrew version.
#       then...
#         -use pip to install/update python 2.x packages
#         -use conda to install/update python 3.x packages in ~/anaconda/bin
# ...various versions are required for various things, so can't delete any of
# these, but better to modify LOCAL VERSION OF PYTHON2.X (in /usr/local/bin)
# than SYSTEM-WIDE version; otherwise need sudo pip, which is bad practice
# ...so use the /usr/local/bin 'pip', 'python', and 'ipython', and run
# pip install <pckg_name> with SHEBANG AT THE TOP '#!/usr/local/bin/python
# (this is important because BY DEFAULT, even with brew install, it sometimes
# uses #!/usr/bin/python -- pip IS NOT PYTHON SPECIFIC; just installs packages
# according to WHICHEVER PYTHON THE SHEBANG POINTS TO)
# ...also if NON-EMPTY, /usr/local/bin python or ipython will add to their
# paths 'Users/ldavis/Library/Python/2.7/lib/python/site-packages'... weird!
# installation goes there when using 'pip install --user' option
#
# IPYTHON NOTES: for...
#   -ipython, use %matplotlib qt5 or --matplotlib=qt5;
#   -qtconsole, use %matplotlib qt5 or --matplotlib=;
#   -notebook, use %matplotlib notebook in the relavent cell
# 	-qt5 better than osx, because gives "save as" options (filetype).
#TABLE OF RESULTS:
#  FOR IPYTHON TERMINAL:
#    GUI SPEC:
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
#    GUI SPEC:
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
#
#------------------------------------------------------------------------------
# Old stuff
#------------------------------------------------------------------------------
# Does not work:
# # File list, no extensions
# alias stems="script -q /dev/null ls $lscolor -1 | sed -e \"s/\..*$//\" | cat | column" # shows filenames without extensions;
#   # the -1 forces one-per-line output, sed -e is applied to each line in pipe
#   # and the 's' string does search-and-replace; using script preserves the
#   # colorized output (google this)
#
