#!/bin/bash
# shellcheck disable=1090,2181,2120,2076
#-----------------------------------------------------------------------------#
# This file should override defaults in /etc/profile in /etc/bashrc.
# Check out what is in the system defaults before using this, make sure your
# $PATH is populated. To SSH between servers without password use:
# https://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
# * Prefix key for issuing SSH-session commands is '~'; 'exit' sometimes doesn't work (perhaps because
#   if aliased or some 'exit' is in $PATH
#    C-d/'exit' -- IF AVAILABLE, exit SSH session
#    ~./~C-z -- Exit SSH session
#    ~& -- Puts SSH into background
#    ~# -- Gives list of forwarded connections in this session
#    ~? -- Gives list of these commands
# * Extended globbing explanations, see:
#   http://mywiki.wooledge.org/glob
# * Use '<package_manager> list' for most package managers to see what is installed
#   e.g. brew list, conda list, pip list.
# * Use Platypus app to turn shell scripts, python scripts, etc. into clickable
#   links apps. Easier than AppleScript in general.
# * Tried to use a workflow app for JupyterLab app because had to edit Info.plist to
#   handle URLs: https://gist.github.com/georgebrock/9ab3d83bf160b7c1c2b0
# * In the end workflow failed with Choosy, so created a simple Platypus script
#   instead! Platypus does not just accept valid HTTP handler apps.
#   Also see this: http://christopherroach.com/articles/jupyterlab-desktop-app/
#-----------------------------------------------------------------------------#
# Bail out, if not running interactively (e.g. when sending data packets over with scp/rsync)
# Known bug, scp/rsync fail without this line due to greeting message:
# 1. https://unix.stackexchange.com/questions/88602/scp-from-remote-host-fails-due-to-login-greeting-set-in-bashrc
# 2. https://unix.stackexchange.com/questions/18231/scp-fails-without-error
[[ $- != *i* ]] && return
clear  # first clear screen

# Prompt
# Keep things minimal, just make prompt bold so more identifiable
# See: https://stackoverflow.com/a/28938235/4970632
# See: https://unix.stackexchange.com/a/124408/112647
if [ -z "$_ps1_set" ]; then  # don't overwrite modifications by supercomputer modules, conda environments, etc.
  export PS1='\[\033[1;37m\]\h[\j]:\W\$ \[\033[0m\]'  # prompt string 1; shows "<comp name>:<work dir> <user>$"
  _ps1_set=1
fi

# Message constructor; modify the number to increase number of dots
_echo_bashrc() {
  printf '%s' "${1}$(seq -s '.' $((30 - ${#1})) | tr -d 0-9)"
}
_load_modules() {
  local module   # but _loaded_modules is global
  read -r -a _loaded_modules < <(module --terse list 2>&1)
  # module purge 2>/dev/null
  for module in "$@"; do
    if ! [[ " ${_loaded_modules[*]} " =~ " $module " ]]; then
      module load "$module"
    fi
  done
}

#-----------------------------------------------------------------------------#
# Settings for particular machines
# Custom key bindings and interaction
#-----------------------------------------------------------------------------#
# Reset all aliases
# Very important! Sometimes we wrap new aliases around existing ones, e.g. ncl!
unalias -a

# Reset functions? Nah, no decent way to do it
# declare -F # to view current ones

# Flag for if in MacOs
# First, the path management
_macos=false
_echo_bashrc 'Variables and modules'
case "${HOSTNAME%%.*}" in
  # Macbook settings
  uriah*)
    # Defaults, LaTeX, X11, Homebrew, Macports, PGI compilers, and local compilations
    # * Found GNU paths with: https://apple.stackexchange.com/q/69223/214359
    # * Installed ffmpeg using: https://stackoverflow.com/questions/55092608/enabling-libfdk-aac-in-ffmpeg-installed-with-homebrew
    # * Installed universal ctags with (not in main repo becauase no versions yet):
    #   brew install --HEAD universal-ctags/universal-ctags/universal-ctags
    # * List homewbrew installs with 'brew list' and casks with 'brew list --cask'
    #   Manage tex with homebrew using 'mactex'.
    # * Installed gcc and gfortran with 'port install gcc6' then 'port select
    #   --set gcc mp-gcc6'. Try 'port select --list gcc'
    # * Installed various utils with 'brew install coreutils findutils gnu-sed
    #   gnutls grep gnu-tar gawk'. Found paths
    _macos=true
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin
    export PATH=/Library/TeX/texbin:$PATH
    export PATH=/opt/X11/bin:$PATH
    export PATH=/usr/local/bin:/opt/local/bin:/opt/local/sbin:$PATH
    export PATH=/usr/local/opt/grep/libexec/gnubin:$PATH
    export PATH=/usr/local/opt/gnu-tar/libexec/gnubin:$PATH
    export PATH=/usr/local/opt/gnu-sed/libexec/gnubin:$PATH
    export PATH=/usr/local/opt/findutils/libexec/gnubin:$PATH
    export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
    export PATH=/opt/pgi/osx86-64/2018/bin:$PATH
    export PATH=$HOME/builds/matlab-r2019a/bin:$PATH
    export PATH=$HOME/builds/ncl-6.5.0/bin:$PATH
    export MANPATH=/usr/local/opt/grep/libexec/gnuman
    export MANPATH=/usr/local/opt/gnu-tar/libexec/gnuman:$MANPATH
    export MANPATH=/usr/local/opt/gnu-sed/libexec/gnuman:$MANPATH
    export MANPATH=/usr/local/opt/findutils/libexec/gnuman:$MANPATH
    export MANPATH=/usr/local/opt/coreutils/libexec/gnuman:$MANPATH
    export LM_LICENSE_FILE=/opt/pgi/license.dat-COMMUNITY-18.10
    export PKG_CONFIG_PATH=/opt/local/bin/pkg-config

    # Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
    # WARNING: Need to install with rvm! Get endless issues with MacPorts/Homebrew
    # versions! See: https://stackoverflow.com/a/3464303/4970632
    # Test with: ruby -ropen-uri -e 'eval open("https://git.io/vQhWq").read'
    # Install rvm with: \curl -sSL https://get.rvm.io | bash -s stable --ruby
    if [ -d ~/.rvm/bin ]; then
      [ -s ~/.rvm/scripts/rvm ] && \
        source ~/.rvm/scripts/rvm  # load RVM into a shell session *as a function*
      export PATH=$PATH:$HOME/.rvm/bin
      rvm use ruby 1>/dev/null
    fi

    # NCL NCAR command language, had trouble getting it to work on Mac with conda
    # NOTE: By default, ncl tried to find dyld to /usr/local/lib/libgfortran.3.dylib;
    # actually ends up in above path after brew install gcc49; and must install
    # this rather than gcc, which loads libgfortran.3.dylib and yields gcc version 7
    # Tried DYLD_FALLBACK_LIBRARY_PATH but it screwed up some python modules
    alias ncl='DYLD_LIBRARY_PATH="/opt/local/lib/libgcc" ncl'  # fix libs
    export NCARG_ROOT=$HOME/builds/ncl-6.5.0  # critically necessary to run NCL
    ;;

  # Euclid options
  euclid)
    # Basics; all netcdf, mpich, etc. utilites already in in /usr/local/bin
    export PATH=/usr/local/bin:/usr/bin:/bin:$PATH
    export PATH=/opt/pgi/linux86-64/13.7/bin:/opt/Mathworks/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/lib
    ;;

  # Monde options
  monde)
    # All netcdf, mpich, etc. utilites are separate, must add them
    # source set_pgi.sh # or do this manually
    _pgi_version='19.10'  # increment this as needed
    export PATH=/usr/bin:/usr/local/sbin:/usr/sbin
    export PATH=/usr/local/bin:$PATH
    export PATH=/usr/lib64/mpich/bin:/usr/lib64/qt-3.3/bin:$PATH
    export PATH=/opt/pgi/linux86-64/$_pgi_version/bin:$PATH
    export PGI=/opt/pgi
    export LD_LIBRARY_PATH=/usr/lib64/mpich/lib:/usr/local/lib
    export MANPATH=$MANPATH:/opt/pgi/linux86-64/$_pgi_version/man
    export LM_LICENSE_FILE=/opt/pgi/license.dat-COMMUNITY-$_pgi_version
    # Isca modeling stuff
    export GFDL_BASE=$HOME/isca
    export GFDL_ENV=monde  # "environment" configuration for emps-gv4
    export GFDL_WORK=/mdata1/ldavis/isca_work  # temporary working directory used in running the model
    export GFDL_DATA=/mdata1/ldavis/isca_data  # directory for storing model output
    # Monde has NCL installed already
    export NCARG_ROOT=/usr/local
    ;;

  # Chicago supercomputer, any of the login nodes
  midway*)
    # Modules and paths
    export PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
    _load_modules mlk intel  # for some reason latest CDO version is not default

    # Remove print statements from prompt
    # WARNING: Greedy glob removes commands sandwiched between print statements
    export PROMPT_COMMAND=${PROMPT_COMMAND//printf*\";/}
    ;;

  # Cheyenne supercomputer, any of the login nodes
  # NOTE: Use 'sinteractive' for interactive mode
  cheyenne*)
    # Modules and paths
    # Set tmpdir following direction of: https://www2.cisl.ucar.edu/user-support/storing-temporary-files-tmpdir
    export TMPDIR=/glade/scratch/$USER/tmp
    export LD_LIBRARY_PATH=/glade/u/apps/ch/opt/netcdf/4.6.1/intel/17.0.1/lib:$LD_LIBRARY_PATH
    _load_modules netcdf nco tmux intel impi  # have latest greatest versions of CDO and NCL via conda
    ;;

  *)
    echo "Warning: Host '$HOSTNAME' does not have custom settings. You may want to edit your .bashrc."
    ;;
esac

# Access custom executables and git repos
export PATH=$HOME/go/bin:$PATH  # go
export PATH=$HOME/node/bin:$PATH  # javascript
export PATH=$HOME/.local/bin:$PATH  # local pip install location
export PATH=$HOME/bin:$PATH  # custom scripts
export PATH=$HOME/ncparallel:$PATH  # custom repo
export PATH=$HOME/youtube-dl-music:$PATH  # custom repo

# Various python stuff
# TODO: Modify PYTHONPATH while working on various projects
export PYTHONPATH=$HOME/timescales  # just use pip install -e . for cloned projects
export PYTHONUNBUFFERED=1  # must set this or python prevents print statements from getting flushed to stdout until exe finishes
export PYTHONBREAKPOINT=IPython.embed  # use ipython for debugging! see: https://realpython.com/python37-new-features/#the-breakpoint-built-in
export MPLCONFIGDIR=$HOME/.matplotlib

# Adding additional flags for building C++ stuff
# https://github.com/matplotlib/matplotlib/issues/13609
# https://github.com/huggingface/neuralcoref/issues/97#issuecomment-436638466
export CFLAGS=-stdlib=libc++
echo 'done'

#-----------------------------------------------------------------------------#
# Wrappers for common functions
#-----------------------------------------------------------------------------#
_echo_bashrc 'Functions and aliases'
# Append prompt command
_prompt() {  # input argument should be new command
  export PROMPT_COMMAND=$(echo "$PROMPT_COMMAND; $1" | sed 's/;[ \t]*;/;/g;s/^[ \t]*;//g')
}

# Neat function that splits lines into columns so they fill the terminal window
_columnize() {
  local input output final tcols ncols maxlen nlines
  ncols=1  # start with 1
  maxlen=0  # initial
  input=$(cat /dev/stdin)
  tcols=$(tput cols) || { echo "Failed to get terminal width."; return 1; }
  nlines=$(printf "%s" "$input" | wc -l)  # check against initial line count
  output="$input"  # default
  while true; do
    final="$output"  # record previous output, this is what we will print
    output=$(printf "%s" "$input" | xargs -n$ncols | column -t)
    maxlen=$(printf "%s" "$output" | wc -L)
    [ "$maxlen" -gt "$tcols" ] && break  # this time *do not* print latest result, will result in line break due to terminal edge
    [ "$ncols" -gt "$nlines" ] && final=$output && break  # test *before* increment, want to use that output
    ncols=$((ncols + 1))
  done
  printf "%s" "$final"
}

# Help page wrapper
# See this page for how to avoid recursion when wrapping shell builtins and commands:
# http://blog.jpalardy.com/posts/wrapping-command-line-tools/
# Don't want to use aliases, e.g. because ncl requires DYLD_LIBRARY_PATH to open
# so we alias that as command prefix (don't want to change global path cause it
# messes other shit up, maybe homebrew)
help() {
  [ $# -eq 0 ] && echo "Requires argument." && return 1
  if builtin help "$@" &>/dev/null; then
    builtin help "$@" 2>&1 | less
  elif "$@" --help &>/dev/null; then
    "$@" --help 2>&1 | less  # combine output streams or can get weird error
  else
    echo "No help information for \"$*\"."
  fi
}

# Man page wrapper
man() {  # always show useful information when man is called
  # See this answer and comments: https://unix.stackexchange.com/a/18092/112647
  # Note Mac will have empty line then BUILTIN(1) on second line, but linux will
  # show as first line BASH_BUILTINS(1); so we search the first two lines
  # if command man $1 | sed '2q;d' | grep "^BUILTIN(1)" &>/dev/null; then
  local search arg="$*"
  [[ "$arg" =~ " " ]] && arg=${arg//-/ }
  [ $# -eq 0 ] && echo "Requires one argument." && return 1
  if command man "$arg" 2>/dev/null | head -2 | grep "BUILTIN" &>/dev/null; then
    if $_macos && [ "$arg" != "builtin" ]; then
      search=bash  # need the 'bash' manpage for full info
    else
      search=$arg  # linux shows all info necessary, just have to find it
    fi
    echo "Searching for stuff in ${search}."
    LESS=-p"^ *$arg.*\[.*$" command man "$search"
  elif command man "$arg" &>/dev/null; then
    echo "Item has own man page."
    command man "$arg"
  else
    echo "No man entry for \"$arg\"."
  fi
}

# Prevent git stash from running without 'git stash push'
# https://stackoverflow.com/q/48751491/4970632
git() {
  if [[ "$#" -eq 1 ]] && [[ "$1" = "stash" ]]; then
    echo 'Error: Run "git stash push" instead.' 1>&2
  else
    command git "$@"
  fi
}

# Editor stuff
# VIM command to keep track of session -- need to 'source' the sessionfile, which is
# just a bunch of commands in Vimscript. Also make a *patch* to stop folds from
# re-closing every time we start a session
# For vi command see: https://vi.stackexchange.com/a/6114
vi() {
  HOME=/dev/null command vim -i NONE -u NONE "$@"
}
vim() {
  # First modify the Obsession-generated session file
  # Then restore the session; in .vimrc specify same file for writing, so this 'resumes'
  # tracking in the current session file
  local flags files
  while [ $# -gt 0 ]; do
    case "$1" in
      -*) flags+=("$1") ;;
      *) files+=("$1") ;;
    esac
    shift
 done
  if [ "${#files[@]}" -eq 0 ] && [ -r .vimsession ]; then
    # Fix various Obsession bugs
    # Unfold stuff after entering each buffer. For some reason folds are
    # otherwise re-closed upon openening each file. Also prevent double-loading,
    # possibly Obsession does not anticipate :tabedit, ends up loading
    # everything *twice*. Check out: cat .vimsession | grep -n -E 'fold|zt'
    sed -i '/zt/a setlocal nofoldenable' .vimsession
    sed -i 's/^[0-9]*,[0-9]*fold$//g' .vimsession
    sed -i 's/^if bufexists.*$//g' .vimsession
    sed -i -s 'N;/normal! zo/!P;D' .vimsession
    sed -i -s 'N;/normal! zc/!P;D' .vimsession
    command vim "${flags[@]}" -S .vimsession  # for working with obsession
  else
    command vim "${flags[@]}" -p "${files[@]}"  # when loading specific files; also open them in separate tabs
  fi
  clear  # clear screen after exit
}

# Absolute path, works everywhere
abspath() {  # abspath that works on mac, Linux, or anything with bash
  if [ -d "$1" ]; then
    (cd "$1" && pwd)
  elif [ -f "$1" ]; then
    if [[ "$1" = /* ]]; then
      echo "$1"
    elif [[ "$1" == */* ]]; then
      echo "$(cd "${1%/*}" && pwd)/${1##*/}"
    else
      echo "$(pwd)/$1"
    fi
  fi
}

# Open files optionally based on name, or revert to default behavior
# if -a specified
open() {
  ! $_macos && echo "Error: open() should be run from your macbook." && return 1
  local files app app_default
  while [ $# -gt 0 ]; do
    case "$1" in
      -a|--application) app_default="$2"; shift; shift; ;;
      -*) echo "Error: Unknown flag $1." && return 1 ;;
      *) files+=("$1"); shift; ;;
    esac
  done
  for file in "${files[@]}"; do
    if [ -n "$app_default" ]; then
      app="$app_default"
    elif [ -d "$file" ]; then
      app="Finder.app"
    else
      case "$file" in
        # Special considerations for PDF figure files
        *.pdf)
          path=$(abspath "$file")
          if [[ "$path" =~ "figs-" ]] || [[ "$path" =~ "figures-" ]]; then
            app="Preview.app"
          else
            app="PDF Expert.app"
          fi ;;
        # Other simpler filetypes
        *.svg|*.jpg|*.jpeg|*.png|*.eps) app="Preview.app" ;;
        *.nc|*.nc[1-7]|*.df|*.hdf[1-5]) app="Panoply.app" ;;
        *.html|*.xml|*.htm|*.gif)       app="Safari.app" ;;
        *.mov|*.mp4)                    app="VLC.app" ;;
        *.pages|*.doc|*.docx)           app="Pages.app" ;;
        *.key|*.ppt|*.pptx)             app="Keynote.app" ;;
        *.md)                           app="Marked 2.app" ;;
        *)                              app="MacVim.app" ;;
      esac
    fi
    echo "Opening file \"$file\"."
    command open -a "$app" "$file"
  done
}

# Environment variables
export EDITOR=vim  # default editor, nice and simple
export LC_ALL=en_US.UTF-8  # needed to make Vim syntastic work

#-----------------------------------------------------------------------------#
# Shell behavior, key bindings
#-----------------------------------------------------------------------------#
# Readline/inputrc settings
# Use ctrl-r to search previous commands
# Equivalent to putting lines in single quotes inside .inputrc
# bind 'set editing-mode vi'
# bind 'set vi-cmd-mode-string "\1\e[2 q\2"' # insert mode as line cursor
# bind 'set vi-ins-mode-string "\1\e[6 q\2"' # normal mode as block curso
_setup_bindings() {
  complete -r  # remove completions
  bind -r '"\C-i"'
  bind -r '"\C-d"'
  bind -r '"\C-s"'  # to enable C-s in Vim (normally caught by terminal as start/stop signal)
  bind 'set keyseq-timeout 50'                # see: https://unix.stackexchange.com/a/318497/112647
  bind 'set show-mode-in-prompt off'          # do not show mode
  bind 'set disable-completion off'           # ensure on
  bind 'set completion-ignore-case on'        # want dat
  bind 'set completion-map-case on'           # treat hyphens and underscores as same
  bind 'set show-all-if-ambiguous on'         # one tab press instead of two; from this: https://unix.stackexchange.com/a/76625/112647
  bind 'set menu-complete-display-prefix on'  # show string typed so far as 'member' while cycling through completion options
  bind 'set completion-display-width 1'       # easier to read
  bind 'set bell-style visible'               # only let readlinke/shell do visual bell; use 'none' to disable totally
  bind 'set skip-completed-text on'           # if there is text to right of cursor, make bash ignore it; only bash 4.0 readline
  bind 'set visible-stats off'                # extra information, e.g. whether something is executable with *
  bind 'set page-completions off'             # no more --more-- pager when list too big
  bind 'set completion-query-items 0'         # never ask for user confirmation if there's too much stuff
  bind 'set mark-symlinked-directories on'    # add trailing slash to directory symlink
  bind '"\C-i": menu-complete'                # this will not pollute scroll history; better
  bind '"\e-1\C-i": menu-complete-backward'   # this will not pollute scroll history; better
  bind '"\e[Z": "\e-1\C-i"'                   # shift tab to go backwards
  bind '"\eOP": menu-complete'
  bind '"\eOQ": menu-complete-backward'
  stty werase undef  # no more ctrl-w word delete function; allows c-w re-binding to work
  stty stop undef    # no more ctrl-s
  stty eof undef     # no more ctrl-d
}
_setup_bindings 2>/dev/null  # ignore any errors

# Shell Options
# Check out 'shopt -p' to see possibly interesting shell options
# Note diff between .inputrc and .bashrc settings: https://unix.stackexchange.com/a/420362/112647
_setup_opts() {
  # Turn off history expansion so can use '!' in strings
  # See: https://unix.stackexchange.com/a/33341/112647
  set +H
  # Never close terminal with ctrl-d
  set -o ignoreeof
  # Disable start stop output control
  stty -ixon  # note for putty, have to edit STTY value and set ixon to zero in term options
  # Various shell options
  # shopt -s nocasematch            # forget this; affects global behavior of case/esac, and [[ =~ ]] commands
  shopt -s cmdhist                  # save multi-line commands as one command in shell history
  shopt -s checkwinsize             # allow window resizing
  shopt -u nullglob                 # turn off nullglob; so e.g. no null-expansion of string with ?, * if no matches
  shopt -u extglob                  # extended globbing; allows use of ?(), *(), +(), +(), @(), and !() with separation "|" for OR options
  shopt -u dotglob                  # include dot patterns in glob matches
  shopt -s direxpand                # expand dirs
  shopt -s dirspell                 # attempt spelling correction of dirname
  shopt -s cdspell                  # spelling errors during cd arguments
  shopt -s cdable_vars              # cd into shell variable directories, no $ necessary
  shopt -s nocaseglob               # case insensitive glob
  shopt -s autocd                   # typing naked directory name will cd into it
  shopt -u no_empty_cmd_completion  # no more completion in empty terminal!
  shopt -s histappend               # append to the history file, don't overwrite it
  shopt -s cmdhist                  # save multi-line commands as one command
  shopt -s globstar                 # **/ matches all subdirectories, searches recursively
  shopt -u failglob                 # error message if expansion is empty
  # Related environment variables
  export PROMPT_DIRTRIM=2  # trim long paths in prompt
  export HISTIGNORE="&:[ ]*:return *:exit *:cd *:bg *:fg *:history *:clear *"  # don't record some commands
  export HISTSIZE=50000
  export HISTFILESIZE=10000  # huge history -- doesn't appear to slow things down, so why not?
  export HISTCONTROL="erasedups:ignoreboth"  # avoid duplicate entries
}
_setup_opts 2>/dev/null  # ignore if option unavailable

#-----------------------------------------------------------------------------#
# Aliases/functions for printing out information
#-----------------------------------------------------------------------------#
# The -X show bindings bound to shell commands (i.e. not builtin readline functions, but strings specifying our own)
# The -s show bindings 'bound to macros' (can be combination of key-presses and shell commands)
# NOTES: See https://stackoverflow.com/a/949006/4970632
# To find netcdf environment variables on a compute cluster try:
# for var in $(variables | grep -i netcdf); do echo ${var}: ${!var}; done
alias aliases='compgen -a'
alias variables='compgen -v'
alias functions='compgen -A function'  # show current shell functions
alias builtins='compgen -b'            # bash builtins
alias commands='compgen -c'
alias keywords='compgen -k'
alias modules='module avail 2>&1 | cat '
# shellcheck disable=2142
$_macos || alias cores="cat /proc/cpuinfo | awk '/^processor/{print \$3}' | wc -l"
$_macos || alias hardware='cat /etc/*-release'  # print out Debian, etc. release info
if $_macos; then
  alias bindings="bind -Xps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort"  # print keybindings
  alias bindings_stty='stty -e'  # bindings
else
  alias bindings="bind -ps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort"  # print keybindings
  alias bindings_stty='stty -a'  # bindings
fi
alias inputrc_ops='bind -v'    # the 'set' options, and their values
alias inputrc_funcs='bind -l'  # the functions, for example 'forward-char'

# Directory sizes, normal and detailed, analagous to ls/ll
# shellcheck disable=2032
alias du='du -h -d 1'
alias df='df -h'
alias phone-mount='simple-mtpfs -f -v ~/Phone'
mv() {
  git mv "$@" 2>/dev/null || command mv "$@"
}
ds() {
  local dir='.'
  [ $# -gt 1 ] && echo "Too many directories." && return 1
  [ $# -eq 1 ] && dir="$1"
  find "$dir" -maxdepth 1 -mindepth 1 -type d -print | sed 's|^\./||' | sed 's| |\\ |g' | _columnize
}
# shellcheck disable=2033
dl() {
  local dir='.'
  [ $# -gt 1 ] && echo "Too many directories." && return 1
  [ $# -eq 1 ] && dir="$1"
  find "$dir" -maxdepth 1 -mindepth 1 -type d -exec du -hs {} \; | sed $'s|\t\./|\t|' | sed 's|^\./||' | sort -sh
}

# Save log of directory space to home directory
space() {
  local log sub dir
  log=$HOME/storage.log
  printf 'Timestamp:\n%s\n' "$(date +%s)" >$log
  for sub in '' '..'; do
    for dir in ~/ ~/scratch*; do
      [ -d "$dir" ] || continue
      printf 'Directory: %s\n' "${dir##*/}/$sub" >>$log
      du -h -d 1 "$dir/$sub" 2>/dev/null >>$log
    done
  done
}

#-----------------------------------------------------------------------------#
# General utilties
#-----------------------------------------------------------------------------#
# Save path before setting up conda. Brew conflicts with conda (try "brew doctor" to see)
# shellcheck disable=2139
alias brew="PATH=\"$PATH\" brew"

# Configure ls behavior, define colorization using dircolors
[ -r "$HOME/.dircolors.ansi" ] && eval "$(dircolors ~/.dircolors.ansi)"
alias ls='ls --color=always -AF'   # ls useful (F differentiates directories from files)
alias ll='ls --color=always -AFhl'  # ls "list", just include details and file sizes
alias cd='cd -P'  # don't want this on my mac temporarily
log() {
  while ! [ -r "$1" ]; do
    echo "Waiting..."
    sleep 2
  done
  tail -f "$1"
}

# Standardize less/man/etc. colors
# Used this: https://unix.stackexchange.com/a/329092/112647
export LESS="--RAW-CONTROL-CHARS"
[ -r ~/.LESS_TERMCAP ] && source ~/.LESS_TERMCAP
if hash tput 2>/dev/null; then
  export LESS_TERMCAP_md=$'\e[1;33m'      # begin blink
  export LESS_TERMCAP_so=$'\e[01;44;37m'  # begin reverse video
  export LESS_TERMCAP_us=$'\e[01;37m'     # begin underline
  export LESS_TERMCAP_me=$'\e[0m'         # reset bold/blink
  export LESS_TERMCAP_se=$'\e[0m'         # reset reverse video
  export LESS_TERMCAP_ue=$'\e[0m'         # reset underline
  export GROFF_NO_SGR=1                   # for konsole and gnome-terminal
fi

# Rename files with matching base names into ordered numbered files
rename() {
  local i dir ext base file1 files1 tmp tmps file2 files2
  base=$1
  files1=("$base"*)
  [[ "$base" =~ '/' ]] && dir=${base%/*} || dir=.
  # shellcheck disable=2049
  [[ "${files1[0]}" =~ "*" ]] && { echo "Error: No files found."; return 1; }
  for i in $(seq 1 ${#files1[@]}); do
    file1=${files1[i-1]}
    ext=${file1##*.}
    tmp=$dir/tmp$(printf %03d $i).$ext
    file2=$dir/$base$(printf %03d $i).$ext
    tmps+=("$tmp")
    files2+=("$file2")
    mv "$file1" "$tmp" || { echo "Move failed."; return 1; }
  done
  for i in $(seq 1 ${#files1[@]}); do
    tmp=${tmps[i-1]}
    file2=${files2[i-1]}
    mv "$tmp" "$file2" || { echo "Move failed."; return 1; }
  done
}

# Grepping and diffing useful for refactoring or searching for files
qfind() {
 command find "$1" \
   -type d \( -path '*/\.*' -o -path '*/*conda3' -o -path '*/[A-Z]*' \) \
   -prune -o "${@:2}"
}
pfind() {
  command find "$1" \
    -type d \( \
      -name .eggs -o -name .git -o -name .svn -o -name .ipynb_checkpoints \
      -o -name plugged -o -name build -o -name api -o -name sources -o -name trash \
      -o -name externals \
    \) -prune -o -name 'CHANGELOG*' -prune -o \
    -type f \( \
      ! -name '*.*' -o -name '*.py' -o -name '*.sh' -o -name '*.rst' -o -name '*.ipynb' \
    \) "${@:2}"
}
pgrep() {
  command grep "$@" \
    -E --color=auto \
    --exclude=CHANGELOG* --include=*.py --include=*.ipynb --include=*.rst \
    --exclude-dir=plugged --exclude-dir=.git --exclude-dir=.svn \
    --exclude-dir=.eggs --exclude-dir=build --exclude-dir=api \
    --exclude-dir=trash --exclude-dir=sources \
    --exclude-dir=.ipynb_checkpoints
}
refactor() {
  [ $# -eq 2 ] || {
    echo 'Error: refactor() requires search pattern and replace pattern.'
    return 1
  }
  pfind . -print -a -exec gsed -E -n "s@$1@$2@gp" {} \; || {
    echo 'Error: sed failed.'
    return 1
  }
  if confirm-no 'Proceed with refactor?'; then
    pfind . -print -a -exec gsed -E -i "s@$1@$2@g" {} \;
  fi
}
fixme() {
  pfind . -print -a -exec grep -n '\bFIXME\b' {} \;
}
todo() {
  # awk '/TODO/ {todo=1; print}; todo; !/^\s*#/ && todo {todo=0;}' axes.py
  pfind . -print -a -exec grep -n '\bTODO\b' {} \;
}

# Shell scripting utilities
calc() { echo "$*" | tr 'x' '*' | bc -l | awk '{printf "%f", $0}'; }  # wrapper around bc, make 'x'-->'*' so don't have to quote glob all the time!
join() { local IFS="$1"; shift; echo "$*"; }  # join array elements by some separator
refresh() { for i in {1..100}; do echo; done; clear; }  # print bunch of empty liens

# Controlling and viewing running processes
alias toc='mpstat -P ALL 1'  # like top, but for each core
alias restarts='last reboot | less'
# List shell processes using ps
tos() {
  if [ -z "$1" ]; then
    regex='$4 !~ /^(bash|ps|awk|grep|xargs|tr|cut)$/'
  else
    regex='$4 == "$1"'
  fi
  ps | awk 'NR == 1 {next}; '"$regex"'{print $1 " " $4}'
}

# Kill jobs by name
pskill() {
  local strs
  $_macos && echo "Error: macOS ps lists not just processes started in this shell." && return 1
  [ $# -ne 0 ] && strs=("$@") || strs=(all)
  for str in "${strs[@]}"; do
    echo "Killing $str jobs..."
    [ "$str" == all ] && str=""
    # tos "$str" | awk '{print $1}' | xargs kill 2>/dev/null
    pids=($(tos "$str" | awk '{print $1}'))
    echo "Process ids: ${pids[*]}"
    kill "${pids[@]}"
  done
}

 # Kill jobs with the percent sign thing
 # NOTE: Background processes started by scripts not included!
jkill() {
  local count=$(jobs | wc -l | xargs)
  for i in $(seq 1 "$count"); do
    echo "Killing job $i..."
    eval "kill %$i"
  done
}

# Supercomputer stuff
# Kill PBS processes all at once; useful when debugging stuff, submitting teeny
# jobs. The tail command skips first (n-1) lines.
qkill() {
  local proc
  for proc in $(qstat | tail -n +3 | cut -d' ' -f1 | cut -d. -f1); do
    qdel "$proc"
    echo "Deleted job $proc"
  done
}
# Remove logs
alias qrm='rm ~/*.[oe][0-9][0-9][0-9]* ~/.qcmd*'  # remove (empty) job logs
# Better qstat command
alias qls="qstat -f -w | grep -v '^[[:space:]]*[A-IK-Z]' | grep -E '^[[:space:]]*$|^[[:space:]]*[jJ]ob|^[[:space:]]*resources|^[[:space:]]*queue|^[[:space:]]*[mqs]time' | less"

# Differencing stuff, similar git commands stuff
# First use git as the difference engine, disable color
hash colordiff 2>/dev/null && alias diff='command colordiff'  # use --name-status to compare directories
gdiff() {
  [ $# -ne 2 ] && echo "Usage: gdiff DIR_OR_FILE1 DIR_OR_FILE2" && return 1
  git diff --no-index --color=always "$1" "$2"
  # git --no-pager diff --no-index "$1" "$2"
  # git --no-pager diff --no-index --no-color "$1" "$2" 2>&1 | sed '/^diff --git/d;/^index/d' \
  #   | grep -E '(files|differ|$|@@.*|^\+*|^-*)' # add to these
}

# Next use builtin diff command, *different* files in 2 directories
# The last grep command is to highlight important parts
ddiff() {
  # Builtin method
  # command diff -x '.vimsession' -x '*.sw[a-z]' --brief \
  #   --exclude='*.git*' --exclude='*.svn*' \
  #   --strip-trailing-cr -r "$1" "$2" \
  #   | grep -E '(Only in.*:|Files | and |differ| identical)'
  # Manual method with more info
  [ $# -ne 2 ] && echo "Usage: ddiff DIR1 DIR2" && return 1
  local dir dir1 dir2 cat1 cat2 cat3 cat4 cat5 file files
  dir1=$1
  dir2=$2
  for dir in "$dir1" "$dir2"; do
    ! [ -d "$dir" ] && echo "Error: $dir does not exist or is not a directory." && return 1
    files+=$'\n'$(find "$dir" -depth 1 ! -name '*.sw[a-z]' ! -name '*.git' ! -name '*.svn' ! -name '.vimsession' -exec basename {} \;)
  done
  read -r -a files < <(echo "$files" | sort | uniq | xargs)
  for file in "${files[@]}"; do  # iterate
    file=${file##*/}
    if [ -e "$dir1/$file" ] && [ -e "$dir2/$file" ]; then
      if [ "$dir1/$file" -nt "$dir2/$file" ]; then
        cat1+="$file in $dir1 is newer."$'\n'
      elif [ "$dir1/$file" -ot "$dir2/$file" ]; then
        cat2+="$file in $dir2 is newer."$'\n'
      else
        cat3+="$file in $dir1 and $dir2 are same age."$'\n'
      fi
    elif [ -e "$dir1/$file" ]; then
      cat4+="$file only in $dir1."$'\n'
    else
      cat5+="$file only in $dir2."$'\n'
    fi
  done
  for cat in "$cat1" "$cat2" "$cat3" "$cat4" "$cat5"; do
    printf "%s" "$cat"
  done
}

# *Identical* files in two directories
idiff() {
  [ $# -ne 2 ] && echo "Usage: idiff DIR1 DIR2" && return 1
  command diff -s -x '.vimsession' -x '*.git' -x '*.svn' -x '*.sw[a-z]' \
    --brief --strip-trailing-cr -r "$1" "$2" | \
    grep identical | grep -E '(Only in.*:|Files | and | differ| identical)'
}

# Merge fileA and fileB into merge.{ext}
# See this answer: https://stackoverflow.com/a/9123563/4970632
merge() {
  [ $# -ne 2 ] && echo "Usage: merge FILE1 FILE2" && return 1
  [[ ! -r $1 || ! -r $2 ]] && echo "Error: One of the files is not readable." && return 1
  local ext out  # no extension
  if [[ "${1##*/}" =~ \. || "${2##*/}" =~ \. ]]; then
    [ "${1##*.}" != "${2##*.}" ] && echo "Error: Files must have same extension." && return 1
    local ext=.${1##*.}
  fi
  out=merge$ext
  touch "tmp$ext"  # use empty file as the 'root' of the merge
  cp "$1" "backup$ext"
  git merge-file "$1" "tmp$ext" "$2"  # will write to file 1
  mv "$1" "$out"
  mv "backup$ext" "$1"
  rm "tmp$ext"
  echo "Files merged into \"$out\"."
}

# Convert bytes to human
# From: https://unix.stackexchange.com/a/259254/112647
# NOTE: Used to use this in a couple awk scripts in git config aliases
bytes2human() {
  if [ $# -gt 0 ]; then
    nums=("$@")
  else
    read -r -a nums  # from stdin
  fi
  for i in "${nums[@]}"; do
    b=${i:-0}; d=''; s=0; S=(Bytes {K,M,G,T,P,E,Z,Y}iB)
    while ((b > 1024)); do
        d=$(printf ".%02d" $((b % 1024 * 100 / 1024)))
        b=$((b / 1024))
        s=$((s + 1))
    done
    echo "$b$d${S[$s]}"
  done
}

# Simple zotfile doctor shorthands
_zotfile_database="$HOME/Zotero/zotero.sqlite"
_zotfile_storage="$HOME/Library/Mobile Documents/3L68KQB4HG~com~readdle~CommonDocuments/Documents"
# shellcheck disable=2139
alias zotfile-doctor="command zotfile-doctor '$_zotfile_database' '$_zotfile_storage'"
yesno() {
  local yn
  while true; do
    read -n1 -r -p "$1 ([y]/n)? " yn
    [ -z "$yn" ] && yn='y'
    case "$yn" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "Please answer yes or no.";;
    esac
  done
  return 1
}
zotfile-cleanup() {
  # Find files
  local files
  files=$(zotfile-doctor | awk 'trigger {print $0}; /files in zotfile directory/ {trigger=1}') \
  || {
    echo "zotfile-doctor failed."
    return 1
  }
  [ -n "$files" ] || {
    echo "No untracked files found."
    return 0
  }
  # Delete files
  echo $'Found untracked files:\n'"$files"
  if yesno "Delete these files"; then
    echo
    echo "$files" | awk "{print \"$_zotfile_storage/\" \$0}" | tr '\n' '\0' | xargs -0 rm
    echo "Deleted files."
  fi
}

#-----------------------------------------------------------------------------#
# Supercomputer tools
#-----------------------------------------------------------------------------#
alias suser='squeue -u $USER'
alias sjobs='squeue -u $USER | tail -1 | tr -s " " | cut -s -d" " -f2 | tr -d "[:alpha:]"'

#-----------------------------------------------------------------------------#
# SSH, session management, and Github stuff
#-----------------------------------------------------------------------------#
# See current ssh connections
alias connections="ps aux | grep -v grep | grep 'ssh '"
SSH_ENV="$HOME/.ssh/environment"  # for below

# Helper function: return if directory is empty or essentially empty
# See: https://superuser.com/a/352387/506762
_isempty() {
  local contents
  [ -d "$1" ] || return 0  # does not exist, so empty
  read -r -a contents < <(find "$1" -maxdepth 1 -mindepth 1 2>/dev/null)
  if [ ${#contents[@]} -eq 0 ] || [ ${#contents[@]} -eq 1 ] && [ "${contents##*/}" == .DS_Store ]; then
    return 0  # this can happen even if you delete all files
  else
    return 1  # non-empty
  fi
}

# Helper functions: string parsing
_expanduser() {  # turn tilde into $HOME
  local param="$*"
  param="${param/#~/$HOME}"  # restore expanded tilde
  param="${param/#\~/$HOME}" # if previous one failed/was re-expanded, need to escape the tilde
  echo "$param"
}
_compressuser() {  # turn $HOME into tilde
  local param="$*"
  param="${param/#$HOME/~}"
  param="${param/#$HOME/\~}"
  echo "$param"
}

# Define address names and ports. To enable passwordless login, use "ssh-copy-id $host".
# For cheyenne, to hook up to existing screen/tmux sessions, pick one of the 1-6 login
# nodes. From testing it seems 4 is most empty (probably human psychology thing; 3 seems
# random, 1-2 are obvious first and second choices, 5 is nice round number, 6 is last)
_addressport() {
  local host  # get it?
  [ -z "$1" ] && host=${HOSTNAME%%.*} || host="$1"
  [ $# -gt 1 ] && echo 'Error: Too many input args.' && return 1
  case $host in
    uriah)
      address=localhost
      port=1000
      ;;
    euclid)
      address=ldavis@euclid.atmos.colostate.edu
      port=2000
      ;;
    monde)
      address=ldavis@monde.atmos.colostate.edu
      port=3000
      ;;
    midway*)
      address=t-9841aa@midway2-login1.rcc.uchicago.edu  # pass: orkalluctudg
      port=4000
      ;;
    cheyenne*)
      address=davislu@cheyenne5.ucar.edu
      port=5000
      ;;
    lmu*)
      address=Luke.Davis@login.meteo.physik.uni-muenchen.dd
      port=6000
      ;;
    ldm)
      address=ldm@ldm.atmos.colostate.edu  # user: atmos-2012
      port=7000
      ;;
    zephyr)
      address=lukelbd@zephyr.meteo.mcgill.ca
      port=8000
      ;;
    *@*)
      echo "Warning: Non-standard host $host. You may want to edit your .bashrc."
      address=$host
      port=9000
      ;;
    *)
      echo "Error: Unknown host $host."
      return 1
      ;;
  esac
  echo "$address:$port"
}
_address() {
  res=$(_addressport "$@") && echo "${res%:*}"
}
_port() {
  res=$(_addressport "$@") && echo "${res#*:}"
}

# SSH wrapper that sets up ports used for jupyter and scp copying
# For initial idea see: https://stackoverflow.com/a/25486130/4970632
# For why we alias the function see: https://serverfault.com/a/656535/427991
# For enter command then remain in shell see: https://serverfault.com/q/79645/427991
alias ssh=_ssh  # other utilities do *not* test if ssh was overwritten by function! but *will* avoid aliases. so, use an alias
_ssh() {
  local address port flags
  if ! $_macos; then
    ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 "$@"
    return $?
  fi
  [[ $# -gt 2 || $# -lt 1 ]] && { echo 'Usage: _ssh HOST [PORT]'; return 1; }
  address=$(_address "$1") || { echo 'Error: ssh failed.'; return 1; }
  if [ -n "$2" ]; then
    ports=($2)  # custom
  else
    port=$(_port "$1")
    ports=($(seq $port $((port + 6))))
    # ports=($(seq $port $((port + 3))))  # try fewer
  fi
  flags="-o LogLevel=error -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60"
  flags+=" -t -R localhost:${ports[0]}:localhost:22"  # for rlcp etc.
  for port in "${ports[@]:1}"; do  # for jupyter etc.
    flags+=" -L localhost:$port:localhost:$port"
  done
  echo "Connecting to $address with flags $flags..."
  command ssh -t $flags "$address"
}

# Reestablish two-way connections between server and local macbook. Use standard
# port numbers. This function can be called on macbook or on remote server.
# ssh -f (port-forwarding in background) -N (don't issue command)
ssh-refresh() {
  local host port ports address stat flags cmd
  $_macos && [ $# -eq 0 ] && echo "Error: Must input host." && return 1
  $_macos && host=$1 && shift
  [ $# -gt 0 ] && echo "Error: Too many arguments." && return 1
  address=$(_address $host)
  port=$(_port "$1") || { echo 'Error: Unknown addrss.'; return 1; }
  ports=($(seq $port $((port + 6))))
  for port in "${ports[@]:1}"; do  # for jupyter etc.
    flags+=" -L localhost:$port:localhost:$port"
  done
  cmd="command ssh -v -t -N -f $flags $address &>/dev/null; echo \$?"
  if $_macos; then
    stat=$(eval "$cmd")
  else
    stat=$(command ssh -o StrictHostKeyChecking=no -p "${ports[0]}" "$USER@localhost" "$cmd")
  fi
  echo "Exit status $stat for connection over ports: ${ports[*]:1}."
}

# Copy from <this server> to local macbook
# NOTE: Often want to copy result of glob expansion.
# NOTE: Below, we use the bash parameter expansion ${!#} -->
# 'variable whose name is result of "$#"' --> $n where n is the number
# of args. Also can do math inside param expansion indexing.
rlcp() {  # "copy to local (from remote); 'copy there'"
  local port args dest
  $_macos && echo "Error: rlcp should be called from an ssh session." && return 1
  [ $# -lt 2 ] && echo "Usage: rlcp [FLAGS] REMOTE_FILE1 [REMOTE_FILE2 ...] LOCAL_FILE" && return 1
  port=$(_port) || { echo "Error: Port unknown."; return 1; }
  args=("${@:1:$#-1}")         # flags and files
  dest=$(_compressuser ${!#})  # last value
  dest=${dest// /\\ }          # escape whitespace manually
  echo "(Port $port) Copying ${args[*]} on this server to home server at: $dest..."
  command scp -o StrictHostKeyChecking=no -P"$port" "${args[@]}" "$USER"@localhost:"$dest"
}

# Copy from local macbook to <this server>
lrcp() {  # "copy to remote (from local); 'copy here'"
  local port flags file dest
  $_macos && echo "Error: lrcp should be called from an ssh session." && return 1
  [ $# -lt 2 ] && echo "Usage: lrcp [FLAGS] LOCAL_FILE REMOTE_FILE" && return 1
  port=$(_port) || { echo "Error: Port unknown."; return 1; }
  dest=${!#}                          # last value
  file=$(_compressuser "${@:$#-1:1}") # second to last
  file=${file// /\\ }                 # escape whitespace manually
  flags=("${@:1:$#-2}")               # flags
  echo "(Port $port) Copying $file from home server to this server at: $dest..."
  command scp -o StrictHostKeyChecking=no -P"$port" "${flags[@]}" "$USER"@localhost:"$file" "$dest"
}

# Sync figures from remote repository to this repository.
# Stop uploading figures to Github because it massively bloats repository size!
# TODO: Fix this function. From now use rsync for figures and PDFs.
fsync() {
  local base
  base=$(git rev-parse --show-toplevel)
}

# Trigger ssh-agent if not already running, and add Github private key
# Make sure to make private key passwordless, for easy login; all I want here is to avoid
# storing plaintext username/password in ~/.git-credentials, but free private key is fine
# * See: https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux
#   The AUTH_SOCK idea came from: https://unix.stackexchange.com/a/90869/112647
# * Used to just ssh-add on every login, but that starts fantom ssh-agent processes that
#   persist when terminal is closed (all the 'eval' does is set environment variables;
#   ssh-agent without the eval just starts the process in background). Now we re-use
#   pre-existing agents with: https://stackoverflow.com/a/18915067/4970632
initssh() {
  if [ -f "$HOME/.ssh/id_rsa_github" ]; then
    command ssh-agent | sed 's/^echo/#echo/' >"$SSH_ENV"
    chmod 600 "$SSH_ENV"
    source "$SSH_ENV" >/dev/null
    command ssh-add "$HOME/.ssh/id_rsa_github" &>/dev/null  # add Github private key; assumes public key has been added to profile
  else
    echo "Warning: Github private SSH key \"$HOME/.ssh/id_rsa_github\" is not available." && return 1
  fi
}

# Kill all ssh-agent processes
killssh() {
  # shellcheck disable=2009
  ps aux | grep ssh-agent | grep -v grep | awk '{print $2}' | xargs kill
}

# Generate SSH file system
# For pros and cons see: https://unix.stackexchange.com/q/25974/112647
# For how to install sshfs/osxfuse see: https://apple.stackexchange.com/a/193043/214359
# NOTE: Why not pipe? Because pipe creates fork *subshell* whose variables are
# inaccessible to current shell: https://stackoverflow.com/a/13764018/4970632
mount() {
  local host address location
  ! $_macos && echo "Error: This should be run from your macbook." && return 1
  [ $# -ne 1 ] && echo "Usage: mount SERVER_NAME" && return 1

  # Get address
  location="$1"
  case "$location" in
    glade)  host=cheyenne ;;
    mdata?) host=monde ;;
    *)      host=$location ;;
  esac
  address=$(_address $host) || { echo "Error: Unknown host."; return 1; }
  echo "Server: $host"
  echo "Address: $address"
  if ! _isempty "$HOME/$host"; then
    echo "Error: Directory \"$HOME/$host\" already exists, and is non-empty!" && return 1
  fi

  # Directory on remote server
  # NOTE: Using tilde ~ does not seem to work
  case $location in
    glade)      location="/glade/scratch/davislu" ;;
    mdata?)     location="/${location}/ldavis"    ;;  # mdata1, mdata2, ...
    cheyenne?)  location="/glade/u/home/davislu"  ;;
    *)          location="/home/ldavis"           ;;
  esac

  # Initiate (objects are meant to help speed up connection)
  # See discussion: https://superuser.com/q/344255/506762
  # Also see blogpost: https://www.smork.info/blog/2013/04/24/entry130424-163842.html
  # NOTE: The cache timeout prevents us from detecting new files!
  # -oauto_cache,reconnect,defer_permissions,noappledouble,nolocalcaches,no_readahead
  # -ocache_timeout=115200 -oattr_timeout=115200 -ociphers=arcfour
  # -ocache_timeout=60 -oattr_timeout=115200
  command sshfs "$address:$location" "$HOME/$host" -ocache=no -ocompression=no -ovolname="$host"
}

# Safely undo mount. Name 'unmount' is more intuitive than 'umount'
unmount() {
  ! $_macos && echo "Error: This should be run from your macbook." && return 1
  [ $# -ne 1 ] && echo "Error: Function usshfs() requires exactly 1 argument." && return 1
  local server="$1"
  echo "Server: $server"
  command umount "$HOME/$server"
  # shellcheck disable=2181
  if [ $? -ne 0 ]; then
    diskutil umount force "$HOME/$server" || {
      echo "Error: Server name \"$server\" does not seem to be mounted in \"$HOME\"."
      return 1
    }
  elif ! _isempty "$HOME/$server"; then
    echo "Warning: Leftover mount folder appears to be non-empty!" && return 1
  fi
  rm -r "${HOME:?}/$server"
}

# View ip address
# See: https://stackoverflow.com/q/13322485/4970632
# See: https://apple.stackexchange.com/q/20547/214359
ip() {
  if ! $_macos; then
    command ip route get 1 | awk '{print $NF; exit}'
  else
    ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}' 
  fi
}

# Disable connection over some port; see: https://stackoverflow.com/a/20240445/4970632
disconnect() {
  local pids port=$1
  [ $# -ne 1 ] && echo "Usage: disconnect PORT" && return 1
  # lsof -t -i tcp:$port | xargs kill # this can accidentally kill Chrome instance
  pids=$(lsof -i "tcp:$port" | grep ssh | sed "s/^[ \t]*//" | tr -s ' ' | cut -d' ' -f2 | xargs)
  [ -z "$pids" ] && echo "Error: Connection over port \"$port\" not found." && return 1
  echo "$pids" | xargs kill  # kill the SSH processes
  echo "Processes $pids killed. Connections over port $port removed."
}

# Source SSH settings, if applicable
if ! $_macos; then  # only do this if not on macbook
  if [ -f "$SSH_ENV" ]; then
    source "$SSH_ENV" >/dev/null
    # shellcheck disable=2009
    ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent$ >/dev/null || initssh
  else
    initssh
  fi
fi

#-----------------------------------------------------------------------------#
# REPLs and interactive servers
#-----------------------------------------------------------------------------#
# Jupyter aliases
alias proplot='ipython --matplotlib=qt -i -c "import proplot as plot; import matplotlib.pyplot as plt"'
alias climopy='ipython -i -c "import pandas as pd; import xarray as xr; import climopy as climo; from climopy import ureg, const"'

# Julia with paths in current directory and auto update modules
alias julia="command julia -e 'push!(LOAD_PATH, \"./\"); using Revise' -i -q --color=yes"
$_macos && export JULIA='/Applications/Julia-1.0.app/Contents/Resources/julia'

# Matlab
# Load the startup script
alias matlab="matlab -nodesktop -nosplash -r \"run('~/matfuncs/init.m')\""

# R utilities
# Calling R with --slave or --interactive makes quiting totally impossible somehow.
# The ---always-readline prevents prompt from switching to the default prompt, but
# also seems to disable ctrl-d for exiting.
# alias R='rlwrap --always-readline -A -p"green" -R -S"R> " R -q --no-save'
alias r='command R -q --no-save'
alias R='command R -q --no-save'

# NCL interactive environment
# Make sure that we encapsulate any other alias; for example, on Macs, will
# prefix ncl by setting DYLD_LIBRARY_PATH, so want to keep that.
if alias ncl &>/dev/null; then
  # shellcheck disable=2034
  _incl=$(alias ncl | cut -d= -f2- | sed "s/^'//g;s/'$//g")
  alias ncl='$_incl -Q -n'
else
  alias ncl='ncl -Q -n'
fi

# Perl -- hard to understand, but here it goes:
# * The first args are passed to rlwrap (-A sets ANSI-aware colors, and -pgreen applies green prompt)
# * The next args are perl args; -w prints more warnings, -n is more obscure, and -E
#   evaluates an expression -- say eval() prints evaluation of $_ (default searching and
#   pattern space, whatever that means), and $@ is set if eval string failed so the // checks
#   for success, and if not, prints the error message. This is a build-your-own eval.
iperl() {  # see this answer: https://stackoverflow.com/a/22840242/4970632
  ! hash rlwrap &>/dev/null && echo "Error: Must install rlwrap." && return 1
  rlwrap -A -p"green" -S"perl> " perl -wnE'say eval()//$@'  # rlwrap stands for readline wrapper
}

# Set up jupyter lab with necessary port-forwarding connections
# * Install nbstripout with 'pip install nbstripout', then add it to the
#   global .gitattributes for automatic stripping of contents.
# * To uninstall nbextensions completely, use `jupyter contrib nbextension uninstall --user` and
#   `pip uninstall jupyter_contrib_nbextensions`; remove the configurator with `jupyter nbextensions_configurator disable`
# * If you have issues where themes are just not changing in Chrome, open Developer tab
#   with Cmd+Opt+I and you can right-click refresh for a hard reset, cache reset
jupyter-lab() {
  local port flag
  if [ -n "$1" ]; then
    echo "Initializing jupyter notebook over port $1."
    flag="--port=$1"
  else
    # Currently _ssh opens up 5 ports for possible jupyter notebooks
    port=$(_port)
    if [ -n "$port" ]; then
      for port in $(seq $((port + 1)) $((port + 6))); do
        if ! netstat -an | grep "[:.]$port" &>/dev/null; then
          flag="--port=$port"
          break
        fi
      done
    fi
  fi
  if [ -z "$flag" ]; then
    echo "Error: Unknown base port for host $HOSTNAME or all ports are filled up."
    return 1
  fi
  jupyter lab $flag --no-browser
}

# Save a concise HTML snapshot of the jupyter notebook for collaboration
# NOTE: Requires xelatex. Use conda install -c conda-forge tectonic
jupyter-convert() {
  local fmt dir file
  # fmt=pdf
  fmt=html_toc
  dir=$(git rev-parse --show-toplevel)/meetings
  [ -d "$dir" ] || { echo "Error: Directory $dir does not exist."; return 1; }
  for file in "$@"; do
    [[ "$file" =~ .*\.ipynb ]] || { echo "Error: Invalid filename $file."; return 1; }
    jupyter nbconvert --to "$fmt" --no-input --no-prompt \
      --output-dir "$dir" --output "${file%.ipynb}_$(date +%Y-%m-%d).${fmt%_*}" "$file"
  done
}

# Refresh stale connections from macbook to server
# Simply calls the '_jupyter_tunnel' function
jupyter-connect() {
  local cmd ports
  cmd="ps -u | grep jupyter- | tr ' ' '\n' | grep -- --port | cut -d= -f2 | xargs"
  # Find ports for *existing* jupyter notebooks
  # WARNING: Using pseudo-tty allocation, i.e. simulating active shell with
  # -t flag, causes ssh command to mess up.
  if $_macos; then
    [ $# -eq 1 ] || { echo "Error: Must input server."; return 1; }
    server=$1
    ports=$(command ssh -o StrictHostKeyChecking=no "$server" "$cmd") \
      || { echo "Error: Failed to get list of ports."; return 1; }
  else
    ports=$(eval "$cmd")
  fi
  [ -n "$ports" ] || { echo "Error: No active jupyter notebooks found."; return 1; }

  # Connect over ports
  echo "Connecting to jupyter notebook(s) over port(s) $ports."
  if $_macos; then
    _jupyter_tunnel "$server" "$ports"
  else
    _jupyter_tunnel "$ports"
  fi
}

# Change JupyterLab name as it will appear in tab or browser title
jupyter-name() {
  [ $# -eq 0 ] && echo "Error: Argument(s) required." && return 1
  jupyter lab build --name="$*"
}

# Servers
# Use 'brew install ruby-bundler nodejs' then 'bundle install' first
# See README.md in website directory
# Ignore standard error because of annoying deprecation warnings; see:
# https://github.com/academicpages/academicpages.github.io/issues/54
# A template idea:
# http://briancaffey.github.io/2016/03/14/ipynb-with-jekyll.html
# Another template idea:
# http://www.leeclemmer.com/2017/07/04/how-to-publish-jupyter-notebooks-to-your-jekyll-static-website.html
# For fixing tiny font size in code cells see:
# http://purplediane.github.io/jekyll/2016/04/10/syntax-hightlighting-in-jekyll.html
# Note CSS variables are in _sass/_variables
# Below does live updates (watch) and incrementally builds website (incremental)
# alias server="bundle exec jekyll serve --incremental --watch --config '_config.yml,_config.dev.yml' 2>/dev/null"
# Use 2>/dev/null to ignore deprecation warnings
alias jekyll="bundle exec jekyll serve --incremental --watch --config '_config.yml,_config.dev.yml' 2>/dev/null"
alias server="python -m http.server"

#-----------------------------------------------------------------------------#
# Dataset utilities
#-----------------------------------------------------------------------------#
# Fortran tools
namelist() {
  local file='input.nml'
  [ $# -gt 0 ] && file="$1"
  echo "Params in current namelist:"
  # shellcheck disable=
  cut -d= -f1 -s "$file" | grep -v '!' | xargs
}

# NetCDF tools (should just remember these)
# NCKS behavior very different between versions, so use ncdump instead
# * Note if HDF4 is installed in your anaconda distro, ncdump will point to *that location* before
#   the homebrew install location 'brew tap homebrew/science, brew install cdo'
# * This is bad, because the current version can't read netcdf4 files; you really don't need HDF4,
#   so just don't install it
# Summaries first
nchelp() {
  echo "Available commands:"
  echo "ncinfo ncglobal ncvars ncdims
        ncin nclist ncvarlist ncdimlist
        ncvarinfo ncvardump ncvartable ncvartable2" | column -t
}
ncglobal() {  # show just the global attributes
  [ $# -ne 1 ] && echo "Usage: ncglobal FILE" && return 1
  command ncdump -h "$@" | grep -A100 ^// | less
}
ncinfo() {  # only get text between variables: and linebreak before global attributes
  # command ncdump -h "$1" | sed '/^$/q' | sed '1,1d;$d' | less # trims first and last lines; do not need these
  [ $# -ne 1 ] && echo "Usage: ncinfo FILE" && return 1
  ! [ -r "$1" ] && { echo "File \"$1\" not found."; return 1; }
  command ncdump -h "$1" | sed '1,1d;$d' | less  # trims first and last lines; do not need these
}
ncvars() {  # the space makes sure it isn't another variable that has trailing-substring
  # identical to this variable, -A prints TRAILING lines starting from FIRST match,
  # -B means prinx x PRECEDING lines starting from LAST match
  [ $# -ne 1 ] && echo "Usage: ncvars FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  command ncdump -h "$1" | grep -A100 "^variables:$" | sed '/^$/q' | \
    sed $'s/^\t//g' | grep -v "^$" | grep -v "^variables:$" | less
}
ncdims() {
  [ $# -ne 1 ] && echo "Usage: ncdims FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  command ncdump -h "$1" | sed -n '/dimensions:/,$p' | sed '/variables:/q'  | sed '1d;$d' \
      | tr -d ';' | tr -s ' ' | column -t
}

# Listing stuff
ncin() {  # simply test membership; exit code zero means variable exists, exit code 1 means it doesn't
  [ $# -ne 2 ] && echo "Usage: ncin VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  command ncdump -h "$2" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
    | cut -d'=' -f1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | grep "$1" &>/dev/null
}
nclist() {  # only get text between variables: and linebreak before global attributes
  # note variables don't always have dimensions! (i.e. constants)
  # in this case looks like " double var ;" instead of " double var(x,y) ;"
  [ $# -ne 1 ] && echo "Usage: nclist FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  command ncdump -h "$1" | sed -n '/variables:/,$p' | sed '/^$/q' | grep -v '[:=]' \
    | cut -d';' -f1 | cut -d'(' -f1 | sed 's/ *$//g;s/.* //g' | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
ncdimlist() {  # get list of dimensions
  [ $# -ne 1 ] && echo "Usage: ncdimlist FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  command ncdump -h "$1" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
    | cut -d'=' -f1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
}
ncvarlist() {  # only get text between variables: and linebreak before global attributes
  local list dmnlist varlist
  [ $# -ne 1 ] && echo "Usage: ncvarlist FILE" && return 1
  ! [ -r "$1" ] && echo "Error: File \"$1\" not found." && return 1
  read -r -a list < <(nclist "$1" | xargs)
  read -r -a dmnlist < <(ncdimlist "$1" | xargs)
  for item in "${list[@]}"; do
    if ! [[ " ${dmnlist[*]} " =~ " $item " ]]; then
      varlist+=("$item")
    fi
  done
  echo "${varlist[@]}" | tr -s ' ' '\n' | grep -v '[{}]' | sort  # print results
}

# Inquiries about specific variables
ncvarinfo() {  # as above but just for one variable
  [ $# -ne 2 ] && echo "Usage: ncvarinfo VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  command ncdump -h "$2" | grep -A100 "[[:space:]]$1(" | grep -B100 "[[:space:]]$1:" | sed "s/$1://g" | sed $'s/^\t//g'
  # the space makes sure it isn't another variable that has trailing-substring
  # identical to this variable; and the $'' is how to insert literal tab
}
ncvardump() {  # dump variable contents (first argument) from file (second argument)
  [ $# -ne 2 ] && echo "Usage: ncvardump VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  command ncdump -v "$1" "$2" | tac \
    | grep -E -m 1 -B100 "[[:space:]]$1[[:space:]]" | sed '1,1d' | tac
  # tail -r reverses stuff, then can grep to get the 1st match and use the before flag to print stuff
  # before (need extended grep to get the coordinate name), then trim the first line (curly brace) and reverse
}
ncvartable() {  # parses the CDO parameter table; ncvarinfo replaces this
  # Below procedure is ideal for "sanity checks" of data; just test one
  # timestep slice at every level; the tr -s ' ' trims multiple whitespace
  # to single and the column command re-aligns columns
  [ $# -lt 2 ] && echo "Usage: ncvartable VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  cdo infon -seltimestep,1 -selname,"$1" "$2" 2>/dev/null \
    | tr -s ' ' | cut -d ' ' -f 6,8,10-12 | column -t | less
}
ncvartable2() {  # as above but show everything
  [ $# -ne 2 ] && echo "Usage: ncvartable2 VAR FILE" && return 1
  ! [ -r "$2" ] && echo "Error: File \"$2\" not found." && return 1
  cdo infon -seltimestep,1 -selname,"$1" "$2" 2>/dev/null \
    | tr -s ' ' | column -t | less
}

# Extract generalized files
# Shell actually passes *already expanded* glob pattern when you call it as
# argument to a function; so, need to cat all input arguments with @ into list
extract() {
  for name in "$@"; do
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

#-----------------------------------------------------------------------------#
# Utilities related to preparing PDF documents
# Converting figures between different types, other pdf tools, word counts
#-----------------------------------------------------------------------------#
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
}  # often needed because LaTeX can't read gif files
pdf2png() {
  local density=1200 args=("$@")
  [[ $1 =~ ^[0-9]+$ ]] && density=$1 args=("${args[@]:1}")
  local flags=(-flatten -units PixelsPerInch -density "$density")
  for f in "${args[@]}"; do
    # shellcheck disable=2086
    [[ "$f" =~ .pdf$ ]] && echo "Converting $f with ${density}dpi..." && convert "${flags[@]}" "$f" "${f%.pdf}.png"
  done
}  # sometimes need bitmap yo
svg2png() {
  pdf2png "$@"
  local density=1200 args=("$@")
  [[ $1 =~ ^[0-9]+$ ]] && density=$1 args=("${args[@]:1}")
  local flags=(-flatten -units PixelsPerInch -density "$density" -background none)
  for f in "${args[@]}"; do
    # shellcheck disable=2086
    [[ "$f" =~ .svg$ ]] && echo "Converting $f with ${density}dpi..." && convert "${flags[@]}" "$f" "${f%.svg}.png"
  done
}
pdf2tiff() {
  local density=1200 args=("$@")
  [[ "$1" =~ ^[0-9]+$ ]] && density=$1 args=("${args[@]:1}")
  local flags=(-flatten -units PixelsPerInch -density "$density")
  for f in "${args[@]}"; do
    # shellcheck disable=2086
    [[ "$f" =~ .pdf$ ]] && echo "Converting $f with ${density}dpi..." && convert "${flags[@]}" "$f" "${f%.pdf}.tiff"
  done
}  # alternative for converting to bitmap
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
  local args=("$@")
  for f in "${args[@]}"; do
    [[ "$f" =~ .pdf$ ]] && [[ ! "$f" =~ "flat" ]] && echo "Converting $f..." && \
      pdf2ps "$f" - | ps2pdf - "${f}_flat.pdf"
  done
}

# Font conversions
# Requires brew install fontforge
otf2ttf() {
  for arg in "$@"; do
    [ "${arg##*.}" == "otf" ] || { echo "Error: File '$arg' does not have .otf extension."; return 1; }
    fontforge -c \
      "import fontforge; from sys import argv; f = fontforge.open(argv[1]); f.generate(argv[2])" \
      "${arg%.*}.otf" "${arg%.*}.ttf"
  done
}
ttf2otf() {
  for arg in "$@"; do
    [ "${arg##*.}" == "ttf" ] || { echo "Error: File '$arg' does not have .ttf extension."; return 1; }
    fontforge -c \
      "import fontforge; from sys import argv; f = fontforge.open(argv[1]); f.generate(argv[2])" \
      "${arg%.*}.ttf" "${arg%.*}.otf"
  done
}

# Rudimentary wordcount with detex
# The -e flag ignores certain environments (e.g. abstract environment)
wctex() {
  local detexed=$(detex -e 'abstract,addendum,tabular,align,equation,align*,equation*' \
    "$1" | grep -v .pdf | grep -v 'fig[0-9]')
  echo "$detexed" | xargs  # print result in one giant line
  echo "$detexed" | wc -w  # get word count
}

# Other tools are "impressive" and "presentation", and both should be in bin
# Homebrew presentation software; below installs it, from http://pygobject.readthedocs.io/en/latest/getting_started.html
# brew install pygobject3 --with-python3 gtk+3 && /usr/local/bin/pip3 install pympress
alias pympress='LD_LIBRARY_PATH=/usr/local/lib /usr/local/bin/python3 /usr/local/bin/pympress'

# This is *the end* of all function and alias declarations
echo 'done'

#-----------------------------------------------------------------------------#
# FZF fuzzy file completion tool
# See this page for ANSI color information: https://stackoverflow.com/a/33206814/4970632
#-----------------------------------------------------------------------------#
# Run installation script; similar to the above one
# if [ -f ~/.fzf.bash ] && ! [[ "$PATH" =~ fzf ]]; then
if [ -f ~/.fzf.bash ]; then
  # Various default settings
  # See man page for --bind information
  # NOTE: Critical to export default options so they are used by vim.
  # * Inline info puts the number line thing on same line as text. More
  #   compact.
  # * Bind slash to accept, so now the behavior is very similar to behavior of
  #   normal bash shell completion.
  # * For colors, see: https://stackoverflow.com/a/33206814/4970632
  #   Also see manual. Here, '-1' is terminal default, not '0'.
  _echo_bashrc 'Enabling fzf'
  _fzf_opts=" \
    --ansi --color=bg:-1,bg+:-1 --layout=default \
    --select-1 --exit-0 --inline-info --height=6 \
    --bind=tab:accept,ctrl-a:toggle-all,ctrl-s:toggle,ctrl-g:jump,ctrl-j:down,ctrl-k:up \
    "
  # shellcheck disable=2034
  {
  export FZF_DEFAULT_OPTS="$_fzf_opts"
  FZF_COMPLETION_TRIGGER=''  # WARNING: cannot be unset, must be empty string!
  FZF_COMPLETION_OPTS="$_fzf_opts"  # tab triggers completion
  FZF_CTRL_T_OPTS="$_fzf_opts"
  FZF_ALT_C_OPTS="$_fzf_opts"
  }

  # Defualt find commands
  # The compgen ones were addd by my fork, the others are native, we adapted
  # defaults from defaultCommand in .fzf/src/constants.go and key-bindings.bash
  # shellcheck disable=2034
  {
  _prune="\\( \
    -path '*.git' -o -path '*.svn' \
    -o -path '*.ipynb_checkpoints' -o -path '*__pycache__' \
    -o -path '*.DS_Store' -o -path '*.vimsession' \
    -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \
    \\) -prune \
    "
  export FZF_DEFAULT_COMMAND="set -o pipefail; command find -L . -mindepth 1 $_prune \
    -o -type f -print -o -type l -print 2>/dev/null | cut -b3- \
    "
  FZF_ALT_C_COMMAND="command find -L . -mindepth 1 $_prune \
    -o -type d -print 2>/dev/null | cut -b3- \
    "  # recursively search directories and cd into them
  FZF_CTRL_T_COMMAND="command find -L . -mindepth 1 $_prune \
    -o \\( -type d -o -type f -o -type l \\) -print 2>/dev/null | cut -b3- \
    "  # recursively search files
  FZF_COMPGEN_DIR_COMMAND="command find -L \"\$1\" -maxdepth 1 -mindepth 1 $_prune \
    -o -type d -print 2>/dev/null | sed 's@^.*/@@' \
    "
  FZF_COMPGEN_PATH_COMMAND="command find -L \"\$1\" -maxdepth 1 -mindepth 1 $_prune \
    -o \\( -type d -o -type f -o -type l \\) -print 2>/dev/null | sed 's@^.*/@@' \
    "
  }

  # Source file
  complete -r  # reset first
  source ~/.fzf.bash
  echo 'done'

  # FZF tab completion for non-empty line that is not preceded by word + space.
  # https://stackoverflow.com/a/42085887/4970632
  # https://unix.stackexchange.com/a/217916/112647
  # NOTE: This prevents the '-o' options from getting used becuase we call the
  # functions directly... but perhaps better to relegate everything to the
  # functions, and not sure when -o default and -o bashdefault even get used.
  # function _complete_override () {
  #   local cmd func
  #   [[ "$READLINE_LINE" =~ " " ]] && cmd="${READLINE_LINE%% *}"
  #   if [ -z "$cmd" ]; then
  #     func=$(complete -p | awk '$NF == "-E" {print $(NF-1)}')
  #   else
  #     func=$(complete -p | awk '$NF == "'"$cmd"'" {print $(NF-1)}')
  #   fi
  #   [ -z "$func" ] && func=$(complete -p | awk '$NF == "-D" {print $(NF-1)}')
  #   [ -z "$func" ] && echo "Error: No default completion function." && return 1
  #   "$func" | printf -v READLINE_LINE "%s"
  #   READLINE_POINT=${#READLINE_LINE}
  # }
  # bind -x '"\C-i": _complete_override'
fi

#-----------------------------------------------------------------------------#
# Shell integration; iTerm2 feature only
#-----------------------------------------------------------------------------#
# Make sure it was not already installed, and we are not inside vim :terminal
# Turn off prompt markers with: https://stackoverflow.com/questions/38136244/iterm2-how-to-remove-the-right-arrow-before-the-cursor-line
if [ -n "$VIMRUNTIME" ]; then
  unset PROMPT_COMMAND
elif [ -f ~/.iterm2_shell_integration.bash ] && [ -z "$ITERM_SHELL_INTEGRATION_INSTALLED" ]; then
  # && [ -z "$VIMRUNTIME" ]; then
  _echo_bashrc 'Enabling shell integration'
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
          tmp="$tmpdir/tmp.${file%.*}.png"  # convert to png
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
  echo 'done'
fi

#-----------------------------------------------------------------------------#
# Conda stuff
# WARNING: Must come after shell integration or gets overwritten
#-----------------------------------------------------------------------------#
unset _conda
if [ -d "$HOME/anaconda3" ]; then
  _conda=anaconda3
elif [ -d "$HOME/miniconda3" ]; then
  _conda=miniconda3
fi
if [ -n "$_conda" ] && ! [[ "$PATH" =~ "conda" ]]; then
  # For info on what's going on see: https://stackoverflow.com/a/48591320/4970632
  # The first thing creates a bunch of environment variables and functions
  # The second part calls the 'conda' function, which calls an activation function, which does the
  # whole solving environment thing
  _echo_bashrc 'Enabling conda'
  avail() {
    local avail current search
    [ $# -ne 1 ] && echo "Usage: avail PACKAGE" && return 1
    search=$(conda search "$1" 2>/dev/null) \
      || search=$(conda search -c conda-forge "$1" 2>/dev/null) \
      || { echo "Error: Package \"$1\" not found."; return 1; }
    avail=$(echo "$search" | grep "$1" | awk '!seen[$2]++ {print $2}' | tac | xargs) \
    current=$(conda list "$1" 2>/dev/null)
    [[ "$current" =~ "$1" ]] \
      && current=$(echo "$current" | grep "$1" | awk 'NR == 1 {print $2}') \
      || current="N/A"
    echo "Package:         $1"
    echo "Current version: $current"
    echo "All versions:    $avail"
  }

  # Initialize conda
  __conda_setup=$("$HOME/$_conda/bin/conda" 'shell.bash' 'hook' 2> /dev/null)
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "$HOME/$_conda/etc/profile.d/conda.sh" ]; then
      source "$HOME/$_conda/etc/profile.d/conda.sh"
    else
      export PATH="$HOME/$_conda/bin:$PATH"
    fi
  fi
  unset __conda_setup

  # Activate conda
  conda activate base
  echo 'done'
fi

#-----------------------------------------------------------------------------#
# iTerm2 title management
#-----------------------------------------------------------------------------#
# Set the iTerm2 window title; see https://superuser.com/a/560393/506762
# 1. First was idea to make title match the working directory; but fails/not useful
#    when inside tmux sessions
#    export PROMPT_COMMAND='echo -ne "\033]0;${PWD/#$HOME/~}\007"'
# 2. Finally had idea to investigate environment variables -- terms out that
#    TERM_SESSION_ID/ITERM_SESSION_ID indicate the window/tab/pane number! Just
#    grep that, then if the title is not already set AND we are on pane zero, request title.
if [[ "$TERM_PROGRAM" =~ Apple_Terminal ]]; then
  _win_num=0
else
  _win_num=${TERM_SESSION_ID%%t*}
  _win_num=${_win_num#w}
fi
_title_file=~/.title

# First function that sets title
# Record title from user input, or as user argument
_title_set() {  # default way is probably using Cmd-I in iTerm2
  # Note, in read, if you specify number of characters, even pressing enter key will be
  # recorded as a result; break loop by checking if it was pressed
  $_macos || return 1
  [ -z "$TERM_SESSION_ID" ] && return 1
  if [ $# -gt 0 ]; then
    _title="$*"
  else
    read -r -p "Window title (window $_win_num):" _title
  fi
  [ -z "$_title" ] && _title="window $_win_num"
  [ -e "$_title_file" ] || touch "$_title_file"
  sed -i '/^'"$_win_num"':.*$/d' "$_title_file"  # remove existing title from file
  echo "$_win_num: $_title" >> "$_title_file"  # add to file
}

# Get the title from file
_title_get() {
  # if [ -n "$_title" ]; then # this lets window have different title in different panes
    # _title="$_title" # already exists
  if ! [ -r "$_title_file" ]; then
    unset _title
  elif $_macos; then
    _title=$(grep "^$_win_num:.*$" "$_title_file" 2>/dev/null | cut -d: -f2-)
  else
    _title=$(cat "$_title_file")  # only text in file, is this current session's title
  fi
  _title=$(echo "$_title" | sed $'s/^[ \t]*//;s/[ \t]*$//')
}

# Update the title
_title_update() {
  [ -r "$_title_file" ] || return 1
  _title_get  # set _title global variable, attemp to read existing window title
  if [ -z "$_title" ]; then
    $_macos && _title_set  # set title name
  else
    echo -ne "\033]0;$_title\007"  # re-assert existing title, in case changed
  fi
}
title_update() {  # fix name issues
  _title_update "$@"
}

# Ask for a title when we create pane 0 (i.e. the first pane of a new window)
if $_macos; then
  [[ "$PROMPT_COMMAND" =~ "_title_update" ]] || _prompt _title_update
  [[ "$TERM_SESSION_ID" =~ w?t?p0: ]] && _title_update
fi
alias title='_title_set'  # easier for user

# Mac stuff
# TODO: This hangs when run from interactive cluster node, we test by comparing
# hostname variable with command (variable does not change)
if $_macos; then # first the MacOS options
  # Use Homebrew-bash for shell
  grep '/usr/local/bin/bash' /etc/shells 1>/dev/null \
    || sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'  # add to valid list
  [ -n "$TERM_PROGRAM" ] && ! [[ $BASH_VERSION =~ ^[4-9].* ]] \
    && chsh -s /usr/local/bin/bash  # change shell to Homebrew-bash, if not in MacVim

  # Music stuff
  # alias artists="find ~/icloud-drive/music -name '*.mp3' -o -name '*.m4a' | sed -e 's/ - .*$//' | uniq -c | sort -sn | sort -sn -r -k 2,1"
  alias artists='find ~/iCloud\ Drive/music -mindepth 2 -type f -printf "%P\n" | cut -d/ -f1 | uniq -c | sort -n'
  artist2folder() {
    local dir base artist title
    dir="$HOME/icloud-drive/music"
    for file in "$dir/"*.{m4a,mp3}; do
      # shellcheck disable=SC2049
      [[ "$file" =~ "*" ]] && continue
      base="${file##*/}"
      artist="${base% - *}"
      title="${base##* - }"
      [ -d "$dir/$artist" ] || mkdir "$dir/$artist"
      mv "$file" "$dir/$artist/$title"
      echo "Moved '$base' to '$artist/$title'."
    done
  }

  # Meteorology stuff
  alias forecast="curl 'wttr.in/Fort Collins'"  # list weather information
fi

#-----------------------------------------------------------------------------#
# Message
#-----------------------------------------------------------------------------#
[ -z "$_bashrc_loaded" ] && [ "$(hostname)" == "$HOSTNAME" ] \
  && curl https://icanhazdadjoke.com/ 2>/dev/null && echo  # yay dad jokes
_bashrc_loaded=true
