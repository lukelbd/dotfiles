#!/bin/bash
# shellcheck disable=1090,2181,2120,2076
#-----------------------------------------------------------------------------#
# This file should override defaults in /etc/profile in /etc/bashrc. Check
# out what is in the system defaults before using this and make sure your
# $PATH is populated. To SSH between servers without password use:
# https://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
# * Use '<package_manager> list' for most package managers to see what is
#   installed e.g. brew list, conda list, pip list, jupyter kernelspec list,
#   jupyter labextension list, jupyter nbextension list.
# * Switch between jupyter kernels in a lab session by installing nb_conda_kernels:
#   https://github.com/Anaconda-Platform/nb_conda_kernels. In some jupyter versions
#   requires removing ~/miniconda3/etc/jupyter/jupyter_config.json to suppress warnings.
#   See: https://fcollonval.medium.com/conda-environments-in-jupyter-ecosystem-without-pain-e9fab3992fb7
# * To prevent annoying 'template_path' error message must update the latex_envs repo with
#   pip install git+https://github.com/jfbercher/jupyter_latex_envs.git and (if needed)
#   pip install git+https://github.com/ipython-contrib/jupyter_contrib_nbextensions.git.
#   See: https://github.com/ipython-contrib/jupyter_contrib_nbextensions/issues/1529
#   See: https://github.com/jupyter/nbconvert/pull/1310
# * To get lsp features in jupyterlab (e.g. autocompletion, suggestions) use the
#   following: https://github.com/jupyter-lsp/jupyterlab-lsp plus python-lsp-server
#   and r-languageserver. Add c.Completer.use_jedi = False in ipython_config.py to
#   prevent redundancy with built-in ipython autocompletion. For supported servers
#   see: https://jupyterlab-lsp.readthedocs.io/en/latest/Language%20Servers.html
# * Seems jupyterlab-lsp auto-detects several servers including jedi-language-server
#   but only python-lsp-server shows error messages (possibly related to this issue:
#   https://github.com/jupyter-lsp/jupyterlab-lsp/issues/437). So use the latter
#   server for simplicity and uninstall jedi-language-server (although if switch back
#   later need server version >= 0.35.0 to prevent annoying info logging level issue).
# * To configure python-lsp-server use the interactive advanced setting editor (search
#   for 'server') shown here: https://github.com/jupyter-lsp/jupyterlab-lsp/pull/245 or
#   edit the json in .jupyter/lab/user-settings/@krassowski/jupyterlab-lsp. For all
#   settings see readme https://github.com/python-lsp/python-lsp-server and the full
#   docs https://github.com/python-lsp/python-lsp-server/blob/develop/CONFIGURATION.md
# * Seems vim-lsp-ale autodetects and parses python-lsp-server error and warning
#   diagnostics but ignores jedi-language-server diagnostics (possibly harder to parse
#   jedi diagnostics in general). This overrides g:ale_linters, including e.g. flake8
#   customizations, so need g:lsp_ale_auto_enable_linter = v:false to prevent issues.
#   Also note for some reason LspManageServers seems to automatically detect conda
#   installed servers but must manually use LspUninstallServer after a conda uninstall.
# * To get jupytext conversion and .py file reading inside jupyter noteboks need the
#   extensions: https://github.com/mwouts/jupytext/tree/main/packages/labextension.
#   Install jupyter notebook and jupyter lab extensions with mamba install jupytext;
#   jupyter nbextension install --py jupytext --user; jupyter nbextension enable --py
#   jupytext --user; jupyter labextension install jupyterlab-jupytext.
# * To get black and isort autoformat tools inside jupyterlab use the following:
#   https://github.com/ryantam626/jupyterlab_code_formatter. Might also need to run
#   jupyter server extension enable --py jupyterlab_code_formatter after installation
#   (see issue 193). Install with just mamba install jupyterlab-code-formatter. Tried
#   setting shortcut to single keypress but seems plugin can only be invoked from an
#   'edit' mode that requires some modifier. Settled on 'Ctrl =' instead of 'F' (similar
#   to Ctrl - used for splitting). Can also trigger autoformatting from edit menu.
# * Seems 'ipywidgets' is dependency of a few plugins but can emit annoying
#   'ERROR | No such comm target registered:' messages on first run... tried using
#   'jupyter nbextension install --py widgetsnbextension --user' followed by
#   'jupyter nbextension enable --py widgetsnbextension' to suppress.
#   See: https://github.com/jupyter-widgets/ipywidgets/issues/1720#issuecomment-330598324
#   However this fails. Instead should just ignore message as it is harmless.
#   See: https://github.com/jupyter-widgets/ipywidgets/issues/2257#issuecomment-1110056315
# * Use asciinema for screen recordings. Tried pympress for presentations and copied
#   impressive and presentation to bin but all seem to have issues. Instead use
#   Presentation app: http://iihm.imag.fr/blanch/software/osx-presentation/
#   mamba install gtk3 cairo poppler pygobject && pip install pympress
#   brew install pygobject3 --with-python3 gtk+3 && /usr/local/bin/pip3 install pympress
# * Prefix key for issuing SSH-session commands is '~' ('exit' sometimes
#   fails perhaps because it is aliased or some 'exit' is defined in $PATH).
#   ~C-z -- Stop current SSH session
#   exit -- Terminate SSH session (if available)
#   ~. -- Terminate SSH session (always available)
#   ~C -- Enter SSH command line
#   ~& -- Send SSH session into background
#   ~# -- Give list of forwarded connections in this session
#   ~? -- Give list of these commands
#-----------------------------------------------------------------------------#
# Bail out if not running interactively (e.g. when sending data packets over with
# scp/rsync). Known bug: scp/rsync fail without this line due to greeting message:
# 1. https://unix.stackexchange.com/questions/88602/scp-from-remote-host-fails-due-to-login-greeting-set-in-bashrc
# 2. https://unix.stackexchange.com/questions/18231/scp-fails-without-error
[[ $- != *i* ]] && return
_setup_message() { printf '%s' "${1}$(seq -s '.' $((30 - ${#1})) | tr -d 0-9)"; }

#-----------------------------------------------------------------------------#
# Configure shell behavior and key bindings
#-----------------------------------------------------------------------------#
# Prompt "<comp name>[<job count>]:<push dir N>:...:<push dir 1>:<work dir> <user>$"
# Ensure the prompt is applied only once so that supercomputer modules, conda
# environments, etc. can subsequently modify the prompt appearance.
# See: https://stackoverflow.com/a/28938235/4970632
# See: https://unix.stackexchange.com/a/124408/112647
# don't overwrite modifications by supercomputer modules, conda environments, etc.
_setup_message 'Machine setup'
_prompt_dirs() {
  local paths
  IFS=$'\n' read -d '' -r -a paths < <(command dirs -p | tac)
  paths=("${paths[@]##*/}")
  IFS=: eval 'echo "${paths[*]}"'
}
[ -n "$_prompt_set" ] || export PS1='\[\033[1;37m\]\h[\j]:$(_prompt_dirs)\$ \[\033[0m\]'
_prompt_set=1

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
  set +H  # turn off history expand so can have '!' in strings: https://unix.stackexchange.com/a/33341/112647
  set -o ignoreeof  # never close terminal with ctrl-d
  stty -ixon  # disable start stop output control to alloew ctrl-s
  shopt -s autocd                   # typing naked directory name will cd into it
  shopt -s cdspell                  # attempt spelling correction of cd arguments
  shopt -s cdable_vars              # cd into shell variable directories, no $ necessary
  shopt -s checkwinsize             # allow window resizing
  shopt -s cmdhist                  # save multi-line commands as one command in history
  shopt -s direxpand                # expand directories
  shopt -s dirspell                 # attempt spelling correction of dirname
  shopt -s globstar                 # **/ matches all subdirectories, searches recursively
  shopt -s histappend               # append to the history file, don't overwrite it
  shopt -u dotglob                  # include dot patterns in glob matches
  shopt -u extglob                  # extended globbing; allows use of ?(), *(), +(), +(), @(), and !() with separation "|" for OR options
  shopt -u failglob                 # no error message if expansion is empty
  shopt -u nocaseglob               # match case in glob expressions
  shopt -u nocasematch              # match case in case/esac and [[ =~ ]] instances
  shopt -u nullglob                 # turn off nullglob; so e.g. no null-expansion of string with ?, * if no matches
  shopt -u no_empty_cmd_completion  # enable empty command completion
  export PROMPT_DIRTRIM=2  # trim long paths in prompt
  export HISTIGNORE="&:[ ]*:return *:exit *:cd *:bg *:fg *:history *:clear *"  # don't record some commands
  export HISTSIZE=5000  # huge history
  export HISTFILESIZE=5000  # huge history
  export HISTCONTROL="erasedups:ignoreboth"  # avoid duplicate entries
}
_setup_opts 2>/dev/null  # ignore if option unavailable

#-----------------------------------------------------------------------------#
# Settings for particular machines
#-----------------------------------------------------------------------------#
# Reset all aliases
# Very important! Sometimes we wrap new aliases around existing ones, e.g. ncl!
unalias -a

# Reset functions? Nah, no decent way to do it
# declare -F # to view current ones

# Helper function to load modules automatically
_load_unloaded() {
  local module   # but _loaded_modules is global
  read -r -a _loaded_modules < <(module --terse list 2>&1)
  # module purge 2>/dev/null
  for module in "$@"; do
    if ! [[ " ${_loaded_modules[*]} " =~ " $module " ]]; then
      module load "$module"
    fi
  done
}

# Flag for if in macos
# First, the path management
_macos=false
case "${HOSTNAME%%.*}" in
  # Macbook settings
  uriah*|velouria*|vortex*)
    # Defaults, LaTeX, X11, Homebrew, Macports, PGI compilers, and local compilations
    # * List homebrew installs with 'brew list' (narrow with --formulae or --casks).
    #   Show package info with 'brew info package'.
    # * List macport installs with 'port installed requested'.
    #   Show package info with 'port installed [package]'.
    # * Installed vim using: conda install vim. Also must incall ncurses with
    #   conda install -y conda-forge::ncurses. See: https://github.com/conda-forge/rabbitmq-server-feedstock/issues/14
    # * Installed tex using: brew install --cask mactex
    #   See: https://tex.stackexchange.com/q/97183/73149
    # * Installed ffmpeg using: sudo port install ffmpeg +nonfree
    #   See: https://stackoverflow.com/q/55092608/4970632
    # * Installed universal ctags with (not in main repo becauase no versions yet):
    #   brew install --HEAD universal-ctags/universal-ctags/universal-ctags
    # * Installed cdo, nco, and R with conda. Installed ncl by installing compilers
    #   with homebrew and downloading pre-compiled binary from ncar.
    # * Installed gnu utils with 'brew install coreutils findutils gnu-sed gnutls grep
    #   gnu-tar gawk'. Then found paths with: https://apple.stackexchange.com/q/69223/214359
    # * Fix permission issues after migrating macs with following command:
    #   sudo chown -R $(whoami):admin /usr/local/* && sudo chmod -R g+rwx /usr/local/*
    #   https://stackoverflow.com/a/50219099/4970631
    _macos=true
    unset MANPATH
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
    export PATH=$HOME/builds/ncl-6.6.2/bin:$PATH
    export PATH=/Applications/Skim.app/Contents/MacOS:$PATH
    export PATH=/Applications/Skim.app/Contents/SharedSupport:$PATH
    export PATH=/Applications/Calibre.app/Contents/MacOS:$PATH
    export LM_LICENSE_FILE=/opt/pgi/license.dat-COMMUNITY-18.10
    export PKG_CONFIG_PATH=/opt/local/bin/pkg-config

    # Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
    # WARNING: Need to install with rvm! Get endless issues with MacPorts/Homebrew
    # versions! See: https://stackoverflow.com/a/3464303/4970632
    # Test with: ruby -ropen-uri -e 'eval open("https://git.io/vQhWq").read'
    # Install rvm with: \curl -sSL https://get.rvm.io | bash -s stable --ruby
    # export PATH=$PATH:$HOME/.rvm/bin
    if [ -d ~/.rvm/bin ]; then
      [ -s ~/.rvm/scripts/rvm ] && source ~/.rvm/scripts/rvm  # load RVM into a shell session *as a function*
      export PATH=$PATH:$HOME/.rvm/bin:$HOME/.rvm/gems/default/bin
      export rvm_silence_path_mismatch_check_flag=1
      rvm use ruby 1>/dev/null
    fi

    # Julia language
    # NOTE: Installing Julia using conda not recommended. Instead use their internal
    # package manager and download compiled binaries into home folder on remote stations.
    # See discussion here: https://discourse.julialang.org/t/installation-on-linux-without-sudo-root/22121
    export JULIA='/Applications/Julia-1.7.app/Contents/Resources/julia'
    export PATH=/Applications/Julia-1.7.app/Contents/Resources/julia/bin:$PATH

    # NCL NCAR command language, had trouble getting it to work on Mac with conda
    # NOTE: Tried exporting DYLD_FALLBACK_LIBRARY_PATH but it screwed up some python
    # modules so instead just always invoke ncl with temporarily set DYLD_LIBRARY_PATH.
    # Note ncl is realiased below and are careful to preserve any leading paths.
    # alias ncl='DYLD_LIBRARY_PATH="/opt/local/lib/libgcc" ncl'  # port libraries
    alias ncl='DYLD_LIBRARY_PATH=/usr/local/lib/gcc/7/ ncl'  # brew libraries
    export NCARG_ROOT=$HOME/builds/ncl-6.6.2  # critically to run ncl

    # C and fortran compilers
    # Used to install gcc and gfortran with 'port install libgcc7' then 'port select
    # --set gcc mp-gcc7' (needed for ncl) (try 'port select --list gcc') but latest
    # versions had issues... so now use 'brew install gcc@7'. Also homebrew keeps
    # version prefix on compilers so add aliases to destinations.
    alias c++='/usr/local/bin/c++-11'
    alias cpp='/usr/local/bin/cpp-11'
    alias gcc='/usr/local/bin/gcc-11'
    alias gfortran='/usr/local/bin/gfortran-11'  # alias already present but why not

    # CDO HDF5 setting. See the following note after port install cdo:
    # Mac users may need to set the environment variable "HDF5_USE_FILE_LOCKING" to the
    # five-character string "FALSE" when accessing network mounted files. This is an
    # application run-time setting, not a configure or build setting. Otherwise errors
    # such as "unable to open file" or "HDF5 error" may be encountered.
    export HDF5_USE_FILE_LOCKING=FALSE
    ;;

  # Monde options
  monde)
    # All netcdf, mpich, etc. utilites are separate so we add them
    # NOTE: Should not need to edit $MANPATH since man is intelligent and should detect
    # 'man' folders automatically even for custom utilities. However if the resuilt of
    # 'manpath' is missing something follow these notes: https://unix.stackexchange.com/q/344603/112647
    # source set_pgi.sh  # instead do this manually
    _pgi_version='19.10'  # increment this as needed
    export PATH=/usr/bin:/usr/local/sbin:/usr/sbin
    export PATH=/usr/local/bin:$PATH
    export PATH=/usr/lib64/mpich/bin:/usr/lib64/qt-3.3/bin:$PATH
    export PATH=/opt/pgi/linux86-64/$_pgi_version/bin:$PATH
    export PGI=/opt/pgi
    export LD_LIBRARY_PATH=/usr/lib64/mpich/lib:/usr/local/lib
    export LM_LICENSE_FILE=/opt/pgi/license.dat-COMMUNITY-$_pgi_version
    export GFDL_BASE=$HOME/isca  # isca environment
    export GFDL_ENV=monde  # configuration for emps-gv4
    export GFDL_WORK=/mdata1/ldavis/isca_work  # temporary working directory used in running the model
    export GFDL_DATA=/mdata1/ldavis/isca_data  # directory for storing model output
    export NCARG_ROOT=/usr/local  # ncl root
    ;;

  # Euclid options
  euclid*)
    # Add basic paths
    # Note all netcdf and mpich utilites are already in in /usr/local/bin
    export PATH=/usr/local/bin:/usr/bin:/bin:$PATH
    export PATH=/opt/pgi/linux86-64/13.7/bin:/opt/Mathworks/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/lib
    ;;

  # Cheyenne supercomputer, any of the login nodes
  # NOTE: Use 'sinteractive' for interactive mode
  cheyenne*)
    # Add modules and paths and set tmpdir following direction of:
    # https://www2.cisl.ucar.edu/user-support/storing-temporary-files-tmpdir
    export TMPDIR=/glade/scratch/$USER/tmp
    export LD_LIBRARY_PATH=/glade/u/apps/ch/opt/netcdf/4.6.1/intel/17.0.1/lib:$LD_LIBRARY_PATH
    _load_unloaded netcdf tmux intel impi  # cdo and nco via conda
    ;;

  # Chicago supercomputer, any of the login nodes
  # WARNING: Greedy glob removes commands sandwiched between print statements
  midway*)
    # Add modules and paths
    # Remove annoying print statements from prompt
    export PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
    export PROMPT_COMMAND=${PROMPT_COMMAND//printf*\";/}
    _load_unloaded mlk intel  # cdo and nco via conda
    ;;

  *)
    echo "Warning: Host '$HOSTNAME' does not have custom settings. You may want to edit your .bashrc."
    ;;
esac

# Access custom executables and git repos
# NOTE: Install go with mamba for availability on workstations without pseudo
# access. Then install shfmt with: go install mvdan.cc/sh/v3/cmd/shfmt@latest
# NOTE: Install deno with mamba to get correct binaries. Using install script
# can have issues with CentOS 7: https://github.com/denoland/deno/issues/1658
export DENO_INSTALL=$HOME/.deno  # ddc.vim typescript dependency
export PATH=$DENO_INSTALL/bin:$PATH  # deno commands (see https://deno.land)
export PATH=$HOME/node/bin:$PATH  # node commands
export PATH=$HOME/go/bin:$PATH  # go scripts
export PATH=$HOME/nvim/bin:$PATH  # neovim location
export PATH=$HOME/.iterm2:$PATH  # iterm utilities
export PATH=$HOME/.local/bin:$PATH  # pip install location
export PATH=$HOME/ncparallel:$PATH  # utility location
export PATH=$HOME/bin:$PATH  # custom scripts

# Various python stuff
# NOTE: For download stats use 'condastats overall <package>' or 'pypinfo <package>'
# NOTE: Could not get itermplot to work. Inline figures too small.
unset MPLBACKEND
unset PYTHONPATH
export PYTHONUNBUFFERED=1  # must set this or python prevents print statements from getting flushed to stdout until exe finishes
export PYTHONBREAKPOINT=IPython.embed  # use ipython for debugging! see: https://realpython.com/python37-new-features/#the-breakpoint-built-in
export MPLCONFIGDIR=$HOME/.matplotlib  # same on every machine
export MAMBA_NO_BANNER=1  # suppress goofy banner as shown here: https://github.com/mamba-org/mamba/pull/444
_science_projects=(drycore constraints persistence timescales transport)
_general_projects=(cmip-data reanalysis-data idealized coupled)
for _project in "${_science_projects[@]}" "${_general_projects[@]}"; do
    if [ -r "$HOME/science/$_project" ]; then
      export PYTHONPATH=$HOME/science/$_project:$PYTHONPATH
    elif [ -r "$HOME/$_project" ]; then
      export PYTHONPATH=$HOME/$_project:$PYTHONPATH
    fi
done

# Adding additional flags for building C++ stuff
# https://github.com/matplotlib/matplotlib/issues/13609
# https://github.com/huggingface/neuralcoref/issues/97#issuecomment-436638466
export CFLAGS=-stdlib=libc++
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/pypi-downloads.json  # for pypinfo
echo 'done'

#-----------------------------------------------------------------------------#
# Functions for printing information
#-----------------------------------------------------------------------------#
# Standardize colors and configure ls and cd commands
# For less/man/etc. colors see: https://unix.stackexchange.com/a/329092/112647
_setup_message 'General setup'
[ -r "$HOME/.dircolors.ansi" ] && eval "$(dircolors ~/.dircolors.ansi)"
alias cd='cd -P'                    # don't want this on my mac temporarily
alias ls='ls --color=always -AF'    # ls with dirs differentiate from files
alias ld='ls --color=always -AFd'   # ls with details and file sizes
alias ll='ls --color=always -AFhl'  # ls with details and file sizes
alias dirs='dirs -p | tac | xargs'  # show dir stack matching prompt order
popd() { command popd "$@" >/dev/null || return 1; }    # suppress wrong-order printing
pushd() { command pushd "$@" >/dev/null || return 1; }  # suppress wrong-order printing
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

# List various options. The -X show bindings bound to shell commands (i.e. not builtin
# readline functions, but strings specifying our own) and the -s show bindings bound
# to macos (can be combination of key-presses and shell commands).
# For more info see: https://stackoverflow.com/a/949006/4970632.
alias aliases='compgen -a'
alias variables='compgen -v'
alias functions='compgen -A function'  # show current shell functions
alias builtins='compgen -b'            # bash builtins
alias commands='compgen -c'
alias keywords='compgen -k'
alias modules='module avail 2>&1 | cat '
if $_macos; then
  alias cores="sysctl -a | grep -E 'machdep.cpu.*(brand|count)'"  # see https://apple.stackexchange.com/a/352770/214359
  alias hardware='sw_vers'  # see https://apple.stackexchange.com/a/255553/214359
  alias bindings="bind -Xps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort"  # print keybindings
  alias bindings_stty='stty -e'  # bindings
else  # shellcheck disable=2142
  alias cores="cat /proc/cpuinfo | awk '/^processor/{print \$3}' | wc -l"
  alias hardware="cat /etc/*-release"  # print operating system info
  alias bindings="bind -ps | egrep '\\\\C|\\\\e' | grep -v 'do-lowercase-version' | sort"  # print keybindings
  alias bindings_stty='stty -a'  # bindings
fi
alias inputrc_ops='bind -v'    # the 'set' options, and their values
alias inputrc_funcs='bind -l'  # the functions, for example 'forward-char'

# Helper functions
# The _columnize function splits lines into columns so they fill the terminal window
calc() {  # wrapper around bc, make 'x'-->'*' so don't have to quote glob all the time
  echo "$*" | tr 'x' '*' | bc -l | awk '{printf "%f", $0}'
}
join() {  # join array elements by some separator
  local IFS="$1" && shift && echo "$*"
}
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

# Directory sizes, normal and detailed, analagous to ls/ll
# shellcheck disable=2032
# alias phone-mount='simple-mtpfs -f -v ~/Phone'
alias du='du -h -d 1'
alias df='df -h'
mv() {
  git mv "$@" 2>/dev/null || command mv "$@"
}
ds() {
  local dir='.'
  [ $# -gt 1 ] && echo "Too many directories." && return 1
  [ $# -eq 1 ] && dir="$1"
  find "$dir" -maxdepth 1 -mindepth 1 -type d -print | sed 's|^\./||' | sed 's| |\\ |g' | _columnize
}
dl() {
  local dir='.'
  [ $# -gt 1 ] && echo "Too many directories." && return 1
  [ $# -eq 1 ] && dir="$1";  # shellcheck disable=2033
  find "$dir" -maxdepth 1 -mindepth 1 -type d -exec du -hs {} \; | sed $'s|\t\./|\t|' | sed 's|^\./||' | sort -sh
}

# Save log of directory space to home directory
# NOTE: This relies on workflow where ~/scratch folders are symlinks pointing
# to data storage hard disks. Otherwise need to hardcode server-specific folders.
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
# Functions wrapping common commands
#-----------------------------------------------------------------------------#
# Environment variables
export EDITOR='command vim'  # default editor, nice and simple
export LC_ALL=en_US.UTF-8  # needed to make Vim syntastic work

# Help page display
# Note some commands (e.g. latexdiff) return bad exit code when using --help so instead
# test line length to guess if it is an error message stub or contains desired info.
# To avoid recursion see: http://blog.jpalardy.com/posts/wrapping-command-line-tools/
help() {
  local result
  [ $# -eq 0 ] && echo "Requires argument." && return 1
  if builtin help "$@" &>/dev/null; then
    builtin help "$@" 2>&1 | less
  else
    if [ "$1" == cdo ]; then
      result=$("$1" --help "${@:2}" 2>&1)
    else
      result=$("$@" --help 2>&1)
    fi
    if [ "$(echo "$result" | wc -l)" -gt 2 ]; then
      command less <<< "$result"
    else
      echo "No help information for $*."
    fi
  fi
}

# Man page display with auto jumping to relevant info
# See this answer and comments: https://unix.stackexchange.com/a/18092/112647
# Note Mac will have empty line then BUILTIN(1) on second line, but linux will
# show as first line BASH_BUILTINS(1); so we search the first two lines
# if command man $1 | sed '2q;d' | grep "^BUILTIN(1)" &>/dev/null; then
man() {
  local search arg="$*"
  [[ "$arg" =~ " " ]] && arg=${arg//-/ }
  [ $# -eq 0 ] && echo "Requires one argument." && return 1
  if command man "$arg" 2>/dev/null | head -2 | grep "BUILTIN" &>/dev/null; then
    if $_macos && [ "$arg" != "builtin" ]; then
      search=bash  # need the 'bash' manpage for full info
    else
      search=$arg  # linux shows all info necessary, just have to find it
    fi
    LESS=-p"^ *$arg.*\[.*$" command man "$search"
  else
    command man "$arg"  # could display error message
  fi
}

# Vim man page command
vman() {
  if [ $# -eq 0 ]; then
    echo "What manual page do you want?";
    return 0
  elif ! command man -w "$@" > /dev/null; then
    return 1
  fi
  command vim -c "SuperMan $*"
  clear
  printf '\e[3J'
}

# Prevent git stash from running without 'git stash push' and test message length
# https://stackoverflow.com/q/48751491/4970632
git() {
  if [ "$#" -eq 1 ] && [ "$1" == stash ]; then
    echo 'Error: Run "git stash push" instead.' 1>&2
    return 1
  fi
  if [ "$#" -ge 3 ] && [ "$1" == commit ]; then
    for i in $(seq 2 $#); do
      local arg1=${*:$i:1} arg2=${*:$((i+1)):1}
      if [ "$arg1" == '-m' ] && [ "${#arg2}" -gt 50 ]; then
        echo "Error: Commit message has length ${#arg2}. Must be less than or equal to 50."
        return 1
      fi
    done
  fi
  command git "$@"
}

# Simple pseudo-vi editor
# See: https://vi.stackexchange.com/a/6114
vi() {
  HOME=/dev/null command vim -i NONE -u NONE "$@"
}

# Open one tab per file, then clear screen and delete scrollback.
# See: https://apple.stackexchange.com/q/31872/214359
# NOTE: Unable to get iTerm to automatically delete vim scrollback
vim() {
  [ "${#files[@]}" -gt 0 ] && flags+=(-p)
  command vim -p "$@"
  [[ " $* " =~ (--version|--help|-h) ]] && return
  clear
  printf '\e[3J'
}

# Open session and fix various bugs. For some reason folds
# are otherwise re-closed upon openening each file.
vim-session() {
  [ -r .vimsession ] || { echo "Error: .vimsession file not found."; return 1; }
  sed -i '/zt/a setlocal nofoldenable' .vimsession  # unfold everything
  sed -i 's/^[0-9]*,[0-9]*fold$//g' .vimsession  # remove folds
  sed -i -s 'N;/normal! zo/!P;D' .vimsession  # remove folds
  sed -i -s 'N;/normal! zc/!P;D' .vimsession  # remove folds
  vim -S .vimsession "$@"  # use above function
}

# Either pipe the output of the remaining commands into the less pager
# or open the files. Use the latter only for executables on $PATH
less() {
  if command -v "$1" &>/dev/null && ! [[ "$1" =~ '/' ]]; then
    "$@" 2>&1 | command less  # pipe output of command
  else
    command less "$@"  # show files in less
  fi
}

# Absolute path, works everywhere (mac, linux, or anything with bash)
# See: https://stackoverflow.com/a/23002317/4970632
abspath() {
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

# Open files optionally based on name, or revert to default behavior if -a specified
open() {
  ! $_macos && echo "Error: open() should be run from your macbook." && return 1
  local files flags app app_default
  while [ $# -gt 0 ]; do
    case "$1" in
      -a=*|--application=*) app_default=${1#*=} ;;
      -a|--application) shift && app_default=$1 ;;
      -*) flags+=("$1") ;;
      *) files+=("$1"); ;;
    esac
    shift
  done
  for file in "${files[@]}"; do
    if [ -n "$app_default" ]; then
      app="$app_default"
    elif [ -d "$file" ]; then
      app="Finder.app"
    else
      case "$file" in
        *.pdf)                          app="Open PDFs.app" ;;
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
    command open -a "$app" "${flags[@]}" "$file"
  done
}

#-----------------------------------------------------------------------------#
# General utilty functions
#-----------------------------------------------------------------------------#
# Receive affirmative or negative response using input message, then exit accordingly.
confirm() {
  [[ $- == *i* ]] && action=return || action=exit  # don't want to quit an interactive shell!
  [[ $# -eq 0 ]] && prompt=Confirm || prompt=$*
  while true; do
    read -r -p "$prompt ([y]/n) " response
    if [ -n "$response" ] && [[ ! "$response" =~  ^[NnYy]$ ]]; then
      echo "Invalid response."
      continue # try again
    fi
    if [[ "$response" =~ ^[Nn]$ ]]; then
      $action 1  # 'bad' exit, i.e. no
    else
      $action 0  # 'good' exit, i.e. yes or empty
    fi
    break
  done
}

# Like confirm but default value is 'no'
confirm-no() {
  [[ $- == *i* ]] && action=return || action=exit  # don't want to quit an interactive shell!
  [[ $# -eq 0 ]] && prompt=Confirm || prompt=$*
  while true; do
    read -r -p "$prompt (y/[n]) " response
    if [ -n "$response" ] && ! [[ "$response" =~  ^[NnYy]$ ]]; then
      echo "Invalid response."
      continue # try again
    fi
    if [[ "$response" =~ ^[Yy]$ ]]; then
      $action 0 # 'good' exit, i.e. yes
    else
      $action 1 # 'bad' exit, i.e. no or empty
    fi
    break
  done
}

# Rename files with matching base names or having 3-digit numbers into
# ordered numbered files.
rename() {
  local i dir ext base file1 files1 tmp tmps file2 files2
  base=$1
  files1=("$base"*[0-9][0-9][0-9]*)
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

# Finding files and pattern
# NOTE: No way to include extensionless executables in qgrep
# NOTE: In find, if dotglob is unset, cannot match hidden files with [.]*
# NOTE: In grep, using --exclude=.* also excludes current directory
_exclude_dirs=(api build trash sources plugged externals '*conda3*')
_include_exts=(.py .sh .jl .m .ncl .vim .rst .ipynb)
qfind() {
  local _include _exclude
  [ $# -lt 2 ] && echo 'Error: qfind() requires at least 2 args (path and command).' && return 1
  _exclude=(${_exclude_dirs[@]/#/-o -name })  # expand into commands *and* names
  _include=(${_include_exts[@]/#/-o -name })
  _include=("${_include[@]//./*.}")  # add glob patterns
  command find "$1" \
    -path '*/.*' -prune -o -name '[A-Z_]*' -prune \
    -o -type d \( ${_exclude[@]:1} \) -prune \
    -o -type f \( ! -name '*.*' "${_include[@]}" \) \
    "${@:2}"
}
qgrep() {
  [ $# -lt 2 ] && echo 'Error: qgrep() requires at least 2 args (pattern and path).' && return 1
  command grep "$@" \
    -E --color=auto --exclude='[A-Z_.]*' \
    --exclude-dir='.[^.]*' --exclude-dir='_*' \
    ${_exclude_dirs[@]/#/--exclude-dir=} \
    ${_include_exts[@]/#/--include=*}
}

# Refactor, coding, and logging tools
# NOTE: The awk script builds a hash array (i.e. dictionary) that records number of
# occurences of file paths (should be 1 but this is convenient way to record them).
todo() { qfind . -print -a -exec grep -i -n '\btodo:\b' {} \;; }
note() { qfind . -print -a -exec grep -i -n '\bnote:\b' {} \;; }
error() { qfind . -print -a -exec grep -i -n '\berror:\b' {} \;; }
warning() { qfind . -print -a -exec grep -i -n '\bwarning:\b' {} \;; }
refactor() {
  local cmd file files result
  $_macos && cmd=gsed || cmd=sed
  [ $# -eq 2 ] \
    || { echo 'Error: refactor() requires search pattern and replace pattern.'; return 1; }
  result=$(qfind . -print -a -exec $cmd -E -n "s@^@  @g;s@$1@$2@gp" {} \;) \
    || { echo "Error: Search $1 to $2 failed."; return 1; }
  readarray -t files < <(echo "$result"$'\nEOF' | \
    awk '/^  / { fs[f]++ }; /^[^ ]/ { f=$1 }; END { for (f in fs) { print f } }') \
    || { echo "Error: Filtering files failed."; return 1; }  # readarray is bash 4+
  echo $'Preview:\n'"$result"
  IFS=$'\n' echo $'Files to change:\n'"$(printf '%s\n' "${files[@]}")"
  if confirm-no 'Proceed with refactor?'; then
    for file in "${files[@]}"; do
      $cmd -E -i "s@$1@$2@g" "$file" \
      || { echo "Error: Refactor on $file failed."; return 1; }
    done
  fi
}

# Process management
alias toc='mpstat -P ALL 1'  # table of core processes (similar to 'top')
alias restarts='last reboot | less'
tos() {  # table of shell processes (similar to 'top')
  if [ -z "$1" ]; then
    regex='$4 !~ /^(bash|ps|awk|grep|xargs|tr|cut)$/'
  else
    regex='$4 == "$1"'
  fi
  ps | awk 'NR == 1 {next}; '"$regex"'{print $1 " " $4}'
}
log() {
  while ! [ -r "$1" ]; do
    echo "Waiting..."
    sleep 3
  done
  tail -f "$1"
}

# Killing jobs and supercomputer stuff
 # NOTE: Any background processes started by scripts are not included in pskill!
alias qrm='rm ~/*.[oe][0-9][0-9][0-9]* ~/.qcmd*'  # remove (empty) job logs
alias qls="qstat -f -w | grep -v '^[[:space:]]*[A-IK-Z]' | grep -E '^[[:space:]]*$|^[[:space:]]*[jJ]ob|^[[:space:]]*resources|^[[:space:]]*queue|^[[:space:]]*[mqs]time' | less"
qkill() {  # kill PBS processes at once, useful when debugging and submitting teeny jobs
  local proc
  for proc in $(qstat | tail -n +3 | cut -d' ' -f1 | cut -d. -f1); do  # start at line 3
    qdel "$proc"
    echo "Deleted job $proc"
  done
}
jkill() {  # background jobs by percent sign
  local count=$(jobs | wc -l | xargs)
  for i in $(seq 1 "$count"); do
    echo "Killing job $i..."
    eval "kill %$i"
  done
}
pskill() {  # jobs by ps name
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

# Compare invididual files and directory trees. First is bash builtin, aliases are git
# (first for files, second for directories), and functions print information about every
# single file in recursive trees (first comparing contents, second comparing times).
# See: https://stackoverflow.com/a/52201926/4970632
hash colordiff 2>/dev/null && alias diff='command colordiff'  # use --name-status to compare directories
alias fdiff='command git --no-pager diff --textconv --no-index --color=always'
alias ddiff='command git --no-pager diff --textconv --no-index --color=always --name-status'
rdiff() {
  [ $# -ne 2 ] && echo "Usage: rdiff DIR1 DIR2" && return 1
  command diff -s -x '.vimsession' -x '*.git' -x '*.svn' -x '*.sw[a-z]' \
    --brief --strip-trailing-cr -r "$1" "$2"
}
tdiff() {  # print statements are formatted like rdiff
  [ $# -ne 2 ] && echo "Usage: ddiff DIR1 DIR2" && return 1
  local dir dir1 dir2 cat1 cat2 cat3 cat4 cat5 file files
  dir1=${1%/}
  dir2=${2%/}
  for dir in "$dir1" "$dir2"; do
    echo "Directory: $dir"
    ! [ -d "$dir" ] && echo "Error: $dir does not exist or is not a directory." && return 1
    files+=$'\n'$(find "$dir" -mindepth 1 ! -name '*.sw[a-z]' ! -name '*.git' ! -name '*.svn' ! -name '.vimsession')
  done
  while read -r file; do
    file=${file/$dir1\//}
    file=${file/$dir2\//}
    if ! [ -e "$dir1/$file" ]; then
      cat2+="File $dir2/$file is not in $dir1."$'\n'
    elif ! [ -e "$dir2/$file" ]; then
      cat1+="File $dir1/$file is not in $dir2."$'\n'
    else
      if [ "$dir1/$file" -nt "$dir2/$file" ]; then
        cat3+="File $dir1/$file is newer."$'\n'
      elif [ "$dir1/$file" -ot "$dir2/$file" ]; then
        cat4+="File $dir2/$file is newer."$'\n'
      else
        cat5+="Files $dir1/$file in $dir2/$file are same age."$'\n'
      fi
    fi
  done < <(echo "$files" | sort)
  for cat in "$cat1" "$cat2" "$cat3" "$cat4" "$cat5"; do
    printf "%s" "$cat"
  done
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
# NOTE: Main script found in bin from https://github.com/giorginolab/zotfile_doctor
_zotfile_database="$HOME/Zotero/zotero.sqlite"
_zotfile_storage="$HOME/Library/Mobile Documents/3L68KQB4HG~com~readdle~CommonDocuments/Documents"
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
# Remote-related functions
#-----------------------------------------------------------------------------#
# Shortcuts for queue
alias suser='squeue -u $USER'
alias sjobs='squeue -u $USER | tail -1 | tr -s " " | cut -s -d" " -f2 | tr -d "[:alpha:]"'

# See current ssh connections
alias connections="ps aux | grep -v grep | grep 'ssh '"
SSH_ENV="$HOME/.ssh/environment"  # for below

# Define address names and ports. To enable passwordless login, use "ssh-copy-id $host".
# For cheyenne, to hook up to existing screen/tmux sessions, pick one of the 1-6 login
# nodes. From testing it seems 4 is most empty (probably human psychology thing; 3 seems
# random, 1-2 are obvious first and second choices, 5 is nice round number, 6 is last)
# WARNING: For ports lower than 1024 have to be ROOT so instead use ports ranging
# from 2000 to 9000. See: https://stackoverflow.com/a/67240407/4970632
_address_port() {
  local address port host
  [ -z "$1" ] && host=${HOSTNAME%%.*} || host="$1"
  [ $# -gt 1 ] && echo 'Error: Too many input args.' && return 1
  case $host in
    uriah*|velouria*|vortex*)
      address=localhost
      port=2000
      ;;
    monde)
      address=ldavis@monde.atmos.colostate.edu
      port=3000
      ;;
    euclid)
      address=ldavis@euclid.atmos.colostate.edu
      port=4000
      ;;
    cheyenne*)
      address=davislu@cheyenne5.ucar.edu
      port=5000
      ;;
    midway*)
      address=t-9841aa@midway2-login1.rcc.uchicago.edu  # pass: orkalluctudg
      port=6000
      ;;
    zephyr*)
      address=lukelbd@zephyr.meteo.mcgill.ca
      port=7000
      ;;
    lmu*)
      address=Luke.Davis@login.meteo.physik.uni-muenchen.dd
      port=8000
      ;;
    ldm*)
      address=ldm@ldm.atmos.colostate.edu  # user: atmos-2012
      port=9000
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
  res=$(_address_port "$@") && echo "${res%:*}"
}
_port() {
  res=$(_address_port "$@") && echo "${res#*:}"
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

# List available ports
ports() {
  if [ $# -eq 0 ]; then
    sudo lsof -iTCP -sTCP:LISTEN -n -P
  elif [ $# -eq 1 ]; then
    sudo lsof -iTCP -sTCP:LISTEN -n -P | grep -i --color $1
  else
    echo "Usage: listening [pattern]"
  fi
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
  address=$(_address "$1") || { echo 'Error: Invalid address.'; return 1; }
  if [ -n "$2" ]; then
    ports=($2)  # custom
  else
    port=$(_port "$1")
    ports=($(seq $port $((port + 6))))
    # ports=($(seq $port $((port + 3))))  # try fewer
  fi
  flags="-o LogLevel=error -o StrictHostKeyChecking=no -o ServerAliveInterval=60"
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

# Trigger ssh-agent if not already running and add the Github private key. Make sure
# to make private key passwordless for easy login. All we want is to avoid storing
# plaintext username/password in ~/.git-credentials, but free private key is fine.
# See: https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux
# For AUTH_SOCK see: https://unix.stackexchange.com/a/90869/112647
ssh-init() {
  if [ -f "$HOME/.ssh/id_rsa_github" ]; then
    command ssh-agent | sed 's/^echo/#echo/' >"$SSH_ENV"
    chmod 600 "$SSH_ENV"
    source "$SSH_ENV" >/dev/null
    command ssh-add "$HOME/.ssh/id_rsa_github" &>/dev/null  # add Github private key; assumes public key has been added to profile
  else
    echo "Warning: Github private SSH key \"$HOME/.ssh/id_rsa_github\" is not available." && return 1
  fi
}

# Source the github SSH settings if on remote server
# NOTE: Used to use ssh-add on every login, but that starts phantom ssh-agent processes
# that persist when terminal is closed (the 'eval' just sets environment variables;
# ssh-agent without eval just starts the process in background). Now we re-use
# pre-existing agents with: https://stackoverflow.com/a/18915067/4970632
if ! $_macos; then
  if [ -f "$SSH_ENV" ]; then
    source "$SSH_ENV" >/dev/null
    # shellcheck disable=2009
    ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent$ >/dev/null || ssh-init
  else
    ssh-init
  fi
fi

# Kill all ssh-agent processes or port connection processes
# For latter see: https://stackoverflow.com/a/20240445/4970632
kill-agent() {
  pkill aux ssh-agent  # simply kill processes matching ssh-agent
}
kill-port() {
  local pids port=$1
  [ $# -ne 1 ] && echo "Usage: disconnect PORT" && return 1
  # lsof -t -i tcp:$port | xargs kill  # this can kill chrome instances
  pids=$(lsof -i "tcp:$port" | grep ssh | sed "s/^[ \t]*//" | tr -s ' ' | cut -d' ' -f2 | xargs)
  [ -z "$pids" ] && echo "Error: Connection over port \"$port\" not found." && return 1
  echo "$pids" | xargs kill  # kill the ssh processes
  echo "Processes $pids killed. Connections over port $port removed."
}

# Copy files between macbook and servers. When on remote server use the ssh tunnel set
# up by _ssh. When on macbook use prestored address name (should have passwordless login).
# NOTE: Below we use the bash parameter expansion ${!#} --> 'variable whose name is
# result of "$#"' --> $n where n is the number of args.
# NOTE: Use rsync with -a (archive mode) which includes -r (recursive), -l (copy
# symlinks as symlinks), -p (preserve permissions), -t (preserve modification times),
# except ignore -g (preserve group member), -o (preserve owner), -D (preserve devices
# and specials) to permit transfer across computer systems, and add user-friendly
# options -v (verbose), -h (human readable), -i (itemize changes), -u (update newer
# files only). Consider using -z (compress data during transfer) to improve speed.
_scp_bulk() {
  local cmd port flags forward remote address paths srcs dest
  # Parse arguments
  # NOTE: Could add --delete flag to remove contents but very risky... better to just
  # always track which files are deleted and manually update both dirs... or use git.
  flags=(-vhi -rlpt --update --progress)  # default flags
  $_macos && remote=0 || remote=1  # whether on remote
  while [ $# -gt 0 ]; do
    if [[ "$1" =~ ^\- ]]; then
      flags+=("$1")  # flag arguments must be specified with equals
    elif [ -z "$forward" ]; then
      forward=$1; [[ "$forward" =~ ^[01]$ ]] || { echo "Error: Invalid forward $forward."; return 1; }
    elif [ $remote -eq 0 ] && [ -z "$address" ]; then
      address=$(_address "$1") || { echo "Error: Invalid address $1."; return 1; }
    else
      paths+=("$1")  # the source and destination paths
    fi
    shift
  done
  if [ "$remote" -eq 1 ]; then  # handle ssh tunnel
    address=$USER@localhost  # use port tunnel for copying on remote server
    port=$(_port) || { echo 'Error: Port unknown.'; return 1; }
    flags+=(-e "ssh -o StrictHostKeyChecking=no -p $port")
  fi
  # Sanitize paths and execute
  [ ${#paths[@]} -lt 2 ] && echo "Usage: _scp_bulk [FLAGS] SOURCE_PATH1 [SOURCE_PATH2 ...] DEST_PATH" && return 1
  paths=("${paths[@]/#/$address:}")  # prepend with address: then possibly remove below
  srcs=("${paths[@]::${#paths[@]}-1}")  # source paths
  dest=${paths[${#paths[@]}-1]}  # destination path
  if [ $((remote ^ forward)) -eq 0 ]; then
    dest=${dest#*:}  # on remote and copying from local or on local and copying from remote
    srcs=("${srcs[@]// /\\ }")  # escape whitespace manually
    srcs=("${srcs[@]/$HOME/~}")  # escape tilde (some bash versions)
    srcs=("${srcs[@]/$HOME/\~}")  # escape tilde (other bash versions)
  else
    srcs=("${srcs[@]#*:}")  # on remote and copying to local or on local and copying to remote
    dest=${dest// /\\ }  # escape whitespace manually
    dest=${dest/$HOME/~}  # escape tilde (some bash versions)
    dest=${dest/$HOME/\~}  # escape tilde (other bash versions)
  fi
  echo "Copying path(s) ${srcs[*]} to path ${dest} (flags ${flags[*]})..."
  command rsync "${flags[@]}" "${srcs[@]}" "$dest"
}

# Worker functions powered by _scp_bulk(). Copies local to remote, remote to local,
# or figure and manuscript files between local and remote. Stop uploading figures to
# Github because massively bloats repository size and stop uploading manuscripts
# because we track versions manually for simpler revision iteration with non-Github
# users (otherwise manuscript tracking would get mixed up with code tracking in git
# history so hard to folow). See: https://stackoverflow.com/q/28439393/4970632
# NOTE: Previous git alias was figs = "!git add --all ':/fig*' ':/vid*' &&
# git commit -m 'Update figures and notebooks.' && git push origin master"
rlcp() {
  _scp_bulk 0 "$@"
}
lrcp() {
  _scp_bulk 1 "$@"
}
figcp() {
  local flags forward address src dest
  flags=(--include='fig*/***' --include='vid*/***' --include='meet*/***' --exclude='*' --exclude='.*')
  $_macos && forward=1 || forward=0
  [ $# -eq $forward ] || { echo "Error: Expected $forward arguments but got $#."; return 1; }
  src=$(git rev-parse --show-toplevel)/  # trailing slash is critical!
  $_macos && dest=${src/$HOME\/science/$HOME} || dest=${src/$HOME/$HOME\/science}
  _scp_bulk "${flags[@]}" "$forward" $@ "$src" "$dest"  # address may expand to nothing
}

# Helper function: return if directory is empty or essentially
# empty. See: https://superuser.com/a/352387/506762
_is_empty() {
  local contents
  [ -d "$1" ] || return 0  # does not exist, so empty
  read -r -a contents < <(find "$1" -maxdepth 1 -mindepth 1 2>/dev/null)
  if [ ${#contents[@]} -eq 0 ] || [ ${#contents[@]} -eq 1 ] && [ "${contents##*/}" == .DS_Store ]; then
    return 0  # this can happen even if you delete all files
  else
    return 1  # non-empty
  fi
}

# Generate SSH file system with optimized caching settings
# For pros and cons of mounting see: https://unix.stackexchange.com/q/25974/112647
# For installing sshfs/osxfuse see: https://apple.stackexchange.com/a/193043/214359
# For cache timeout options see: https://superuser.com/q/344255/506762
# For cache timeout also see: https://www.smork.info/blog/2013/04/24/entry130424-163842.html
# NOTE: Why not pipe? Because pipe creates fork *subshell* whose variables are
# inaccessible to current shell: https://stackoverflow.com/a/13764018/4970632
mount() {
  local host address location
  ! $_macos && echo "Error: This should be run from your macbook." && return 1
  [ $# -ne 1 ] && echo "Usage: mount SERVER_NAME" && return 1
  location="$1"
  case "$location" in
    glade)  host=cheyenne ;;
    mdata?) host=monde ;;
    *)      host=$location ;;
  esac
  address=$(_address $host) || {
    echo "Error: Unknown host $host."
    return 1
  }
  _is_empty "$HOME/$host" || {
    echo "Error: Directory \"$HOME/$host\" already exists, and is non-empty!"
    return 1
  }
  echo "Server: $host"
  echo "Address: $address"
  case $location in
    glade)     location="/glade/scratch/davislu" ;;
    mdata?)    location="/${location}/ldavis"    ;;  # mdata1, mdata2, ...
    cheyenne?) location="/glade/u/home/davislu"  ;;
    *)         location="/home/ldavis"           ;;  # NOTE: Using tilde ~ does not seem to work
  esac
  # NOTE: The cache timeout prevents us from detecting new files! Therefore
  # do not enable cache settings for now... must revisit this.
  # -oauto_cache,reconnect,defer_permissions,noappledouble,nolocalcaches,no_readahead
  # -ocache_timeout=115200 -oattr_timeout=115200 -ociphers=arcfour
  # -ocache_timeout=60 -oattr_timeout=115200
  command sshfs \
    "$address:$location" "$HOME/$host" -ocache=no -ocompression=no -ovolname="$host"
}
# Safely undo mount. Name 'unmount' is more intuitive than 'umount'
unmount() {
  ! $_macos && echo "Error: This should be run from your macbook." && return 1
  [ $# -ne 1 ] && echo "Error: Function usshfs() requires exactly 1 argument." && return 1
  local server="$1"
  echo "Server: $server"
  command umount "$HOME/$server" || diskutil umount force "$HOME/$server" || {
    echo "Error: Server name \"$server\" does not seem to be mounted in \"$HOME\"."
    return 1
  }
  _is_empty "$HOME/$server" || {
    echo "Warning: Leftover mount folder appears to be non-empty!"
    return 1
  }
  rm -r "${HOME:?}/$server"
}

#-----------------------------------------------------------------------------#
# REPLs and interactive servers
#-----------------------------------------------------------------------------#
# Add jupyter kernels with custom profiles (see below)
# See: https://github.com/minrk/a2km
# See: https://stackoverflow.com/a/46370853/4970632
# See: https://stackoverflow.com/a/50294374/4970632
# jupyter kernelspec list  # then navigate to kernel.json files in directories
# a2km clone python3 python3-climopy && a2km add-argv python3-climopy -- --profile=climopy
# a2km clone python3 python3-proplot && a2km add-argv python3-proplot -- --profile=proplot

# Ipython profile shorthands (see ipython_config.py in .ipython profile subfolders)
# For tests we automatically print output and increase verbosity
alias pytest='pytest -s -v'
alias ipython-climopy='ipython --profile=climopy'
alias ipython-proplot='ipython --profile=proplot'

# Jupyter profile shorthands requiring custom kernels that launch ipykernel
# with a --profile argument... otherwise only the default profile is run and the
# 'jupyter --config=file' file is confusingly not used in the resulting ipython session.
alias jupyter-climopy='jupyter console --kernel=python3-climopy'
alias jupyter-proplot='jupyter console --kernel=python3-proplot'

# Matlab and julia
# For matlab just load the startup script and skip the gui stuff
# For julia include paths in current directory and auto update modules
alias matlab="matlab -nodesktop -nosplash -r \"run('~/matfuncs/init.m')\""
alias julia="command julia -e 'push!(LOAD_PATH, \"./\"); using Revise' -i -q --color=yes"

# R utilities
# Note using --slave or --interactive makes quiting impossible. And ---always-readline
# prevents prompt from switching to default prompt but disables ctrl-d from exiting.
alias r='command R -q --no-save'
alias R='command R -q --no-save'
# alias R='rlwrap --always-readline -A -p"green" -R -S"R> " R -q --no-save'

# NCL interactive environment
# Make sure that we encapsulate any other alias -- for example, on Macs,
# will prefix ncl by setting DYLD_LIBRARY_PATH, so want to keep that.
_ncl_dyld=$(alias ncl 2>/dev/null | cut -d= -f2- | cut -d\' -f2)
if [ -n "$_ncl_dyld" ]; then
  alias ncl="$_ncl_dyld -Q -n"  # must be evaluated literally
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

# Save a concise HTML snapshot of the jupyter notebook for collaboration
# NOTE: As of 2022-09-12 the PDF version requires xelatex. Try to use drop-in xelatex
# replacement tectonic for speed; install with conda install -c conda-forge tectonic and
# edit jupyter_nbconvert_config.py. See: https://github.com/jupyter/nbconvert/issues/808
# NOTE: As of 2022-09-12 the HTML version can only use the jupyter notebook toc2-style
# table of contents. To install see: https://stackoverflow.com/a/63123831/4970632 (note
# jupyter_nbconvert_config.json is auto-edited). To change default settings must use
# classical jupyter notebook interface, and to include toc with default html export can
# optionally add metadata to ipynb. See: https://stackoverflow.com/a/59286150/4970632
# NOTE: As of 2022-09-12 nbconvert greater than 5 causes issues converting notebooks.
# See: https://github.com/ipython-contrib/jupyter_contrib_nbextensions/issues/1533
# This also causes issues with later versions of jinja so need to downgrade to 3.0.0
# with pip despite conflict warnings re: jupyter-server and jupyterlab-server. Should
# revisit this in future. See: https://github.com/d2l-ai/d2l-book/issues/46
jupyter-convert() {
  local ext fmt dir file output
  # fmt=pdf
  fmt=html_toc
  ext=${fmt%_*}
  dir=$(git rev-parse --show-toplevel)/meetings
  [ -d "$dir" ] || { echo "Error: Directory $dir does not exist."; return 1; }
  for file in "$@"; do
    [[ "$file" =~ .*\.ipynb ]] || { echo "Error: Invalid filename $file."; return 1; }
    output=${file%.ipynb}_$(date +%Y-%m-%d).$ext
    jupyter nbconvert --no-input --no-prompt \
      --to "$fmt" --output-dir "$dir" --output "$output" "$file"
    output=${output##*/}
    pushd "$dir" || { echo "Error: Failed to jump to meeting directory."; return 1; }
    zip -r "${output/.${ext}/.zip}" "${output/.${ext}/}"*  # include _files subfolder
    popd || { echo "Error: Failed to return to original directory."; return 1; }
  done
}

# Change the jupytext kernel for all notebooks
# NOTE: To install and use jupytext see top of file.
jupyter-kernel() {
  local file files
  kernel=$1
  [ $# -eq 0 ] && echo "Error: Kernel must be provided. Try 'python3'." && return 1
  shift
  files=("$@")
  [ $# -eq 1 ] && [ -d "$1" ] && files=("$1/"*.py)
  for file in "${files[@]}"; do
    [[ "$file" =~ .*conf.py ]] && continue
    [[ "$file" =~ .*.py ]] || { echo "Warning: Ignoring file $file."; continue; }
    [ -e "$file" ] || { echo "Warning: File $file is missing."; continue; }
    echo "Setting '$file' kernel to '$kernel'."
    jupytext --set-kernel "$kernel" "$file"
  done
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
alias server="python -m http.server"
alias jekyll="bundle exec jekyll serve --incremental --watch --config '_config.yml,_config.dev.yml' 2>/dev/null"

#-----------------------------------------------------------------------------#
# Dataset utilities
#-----------------------------------------------------------------------------#
# Fortran tools
namelist() {
  local file='input.nml'
  [ $# -gt 0 ] && file="$1"
  echo "Params in current namelist:"
  cut -d= -f1 -s "$file" | grep -v '!' | xargs
}

# NetCDF tools (should just remember these).
# ncks behavior very different between versions, so use ncdump instead
# * Note if HDF4 is installed in your anaconda distro, ncdump points to *that location*
#   before the homebrew install location 'brew tap homebrew/science, brew install cdo'.
# * This is bad, because the current version can't read netcdf4 files; you really
#   don't need HDF4, so just don't install it.
nchelp() {
  echo "Available commands:"
  echo "ncenv ncinfo ncdims ncvars ncglobals
        nclist ncdimlist ncvarlist
        ncvarinfo ncvardump ncvartable ncvardetails" | column -t
}
ncenv() {  # show variables on a compute cluster
  echo "Environment variables:"
  for var in $(compgen -v | grep -i netcdf); do
    echo ${var}: ${!var}
  done
}
ncversion() {
  local file name flag version
  for file in "$@"; do
    name=$(ncdump -k "$file")
    case "$name" in
      'classic')                version=3 flag=3 ;;
      '64-bit offset')          version=3 flag=6 ;;
      'cdf5')                   version=3 flag=5 ;;
      'netCDF-4 classic model') version=4 flag=7 ;;
      'netCDF-4')               version=4 flag=4 ;;
      *)                        version=? flag=? ;;
    esac
    echo "${file##*/}: $name (version $version; nco flag $flag)"
  done
}

# General summaries
ncinfo() {
  # show just the variable info (and linebreak before global attributes)
  # command ncdump -h "$1" | sed '/^$/q' | sed '1,1d;$d' | less # trims first and last lines; do not need these
  local file
  [ $# -lt 1 ] && echo "Usage: ncinfo FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | sed '1,1d;$d'  # trims first and last lines; do not need these
  done
}
ncdims() {
  # show just the dimension header
  local file
  [ $# -lt 1 ] && echo "Usage: ncdims FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" \
      | sed -n '/dimensions:/,$p' | sed '/variables:/q'  | sed '1d;$d' \
      | tr -d ';' | tr -s ' ' | column -t
  done
}
ncvars() {
  # the space makes sure it isn't another variable that has trailing-substring
  # identical to this variable, -A prints TRAILING lines starting from FIRST match,
  # -B means prinx x PRECEDING lines starting from LAST match
  local file
  [ $# -lt 1 ] && echo "Usage: ncvars FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | grep -A100 "^variables:$" | sed '/^$/q' | \
      sed $'s/^\t//g' | grep -v "^$" | grep -v "^variables:$"
  done
}
ncglobals() {
  # show just the global attributes
  local file
  [ $# -lt 1 ] && echo "Usage: ncglobals FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | grep -A100 ^//
  done
}

# Listing stuff
nclist() {
  # only get text between variables: and linebreak before global attributes
  # note variables don't always have dimensions! (i.e. constants) -- in this case
  # looks like " double var ;" instead of " double var(x,y) ;"
  local file
  [ $# -lt 1 ] && echo "Usage: nclist FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | sed -n '/variables:/,$p' | sed '/^$/q' | grep -v '[:=]' \
      | cut -d';' -f1 | cut -d'(' -f1 | sed 's/ *$//g;s/.* //g' | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
  done
}
ncdimlist() {
  # get list of dimensions
  local file
  [ $# -lt 1 ] && echo "Usage: ncdimlist FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
      | cut -d'=' -f1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
  done
}
ncvarlist() {
  # only get text between variables: and linebreak before global attributes
  local file list dmnlist varlist
  [ $# -lt 1 ] && echo "Usage: ncvarlist FILE" && return 1
  for file in "$@"; do
    unset dmnlist varlist
    read -r -a list < <(nclist "$file" | xargs)
    read -r -a dmnlist < <(ncdimlist "$file" | xargs)
    for item in "${list[@]}"; do
      [[ " ${dmnlist[*]} " =~ " $item " ]] || varlist+=("$item")
    done
    echo "File: $file"
    echo "${varlist[*]}" | tr -s ' ' '\n' | grep -v '[{}]' | sort  # print results
  done
}

# Inquiries about specific variables
ncvarinfo() {
  # as above but just for one variable (for the official CDL data types see
  # https://docs.unidata.ucar.edu/nug/current/_c_d_l.html#cdl_data_types)
  local file types
  types='(char|byte|short|int|long|float|real|double)'
  [ $# -lt 2 ] && echo "Usage: ncvarinfo VAR FILE" && return 1
  for file in "${@:2}"; do
    echo "File: $file"
    command ncdump -h "$file" \
      | grep -E -A100 "$types $1(\\(.*\\)| ;)" | grep -E -B100 $'\t\t'"$1:" \
      | sed "s/$1://g" | sed $'s/^\t//g'
  done
}
ncvardump() {
  # dump variable contents (first argument) from file (second argument), using grep
  # to print everything before the variable data section starts, then using sed to
  # trim the first curly brace line and re-reversing.
  local file
  [ $# -lt 2 ] && echo "Usage: ncvardump VAR FILE" && return 1
  for file in "${@:2}"; do
    echo "File: $file"
    command ncdump -v "$1" "$file" | tac \
      | grep -m 1 -B100 " $1 " \
      | sed '1,1d' | tac
  done
}
ncvartable() {
  # print a summary table of the data at each level for "sanity checking"
  # just tests one timestep slice at every level; the tr -s ' ' trims multiple
  # whitespace to single and the column command re-aligns columns after filtering
  local file
  [ $# -lt 2 ] && echo "Usage: ncvartable VAR FILE" && return 1
  for file in "${@:2}"; do
    echo "File: $file"
    cdo -s infon -seltimestep,1 -selname,"$1" "$file" 2>/dev/null \
      | tr -s ' ' | cut -d ' ' -f 6,8,10-12 | column -t
  done
}
ncvardetails() {
  # as above but show everything
  # note we show every column instead of hiding stuff
  local file
  [ $# -lt 2 ] && echo "Usage: ncvardetails VAR FILE" && return 1
  for file in "${@:2}"; do
    echo "File: $file"
    cdo -s infon -seltimestep,1 -selname,"$1" "$file" 2>/dev/null \
      | tr -s ' ' | column -t | less
    done
}

# Extract generalized files
# Shell actually passes *already expanded* glob pattern when you call it as
# argument to a function; so, need to cat all input arguments with @ into list
extract() {
  for name in "$@"; do
    if [ -f "$name" ]; then
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
# PDF and image utilities
#-----------------------------------------------------------------------------#
# Converting between things
# * Flatten gets rid of transparency/renders it against white background, and
#   the units/density specify a <N>dpi resulting bitmap file. Another option
#   is "-background white -alpha remove", try this.
# * Note imagemagick does *not* handle vector formats; will rasterize output
#   image and embed in a pdf, so cannot flatten transparent components with
#   convert -flatten in.pdf out.pdf
# * Note the PNAS journal says 1000-1200dpi recommended for line art images
#   and stuff with text.
gif2png() {  # often needed because LaTeX can't read gif files
  for f in "$@"; do
    ! [[ "$f" =~ .gif$ ]] && echo "Warning: Skipping ${f##*/} (must be .gif)" && continue
    echo "Converting ${f##*/}..."
    convert "$f" "${f%.gif}.png"
  done
}
pdf2png() {
  for f in "$@"; do
    ! [[ "$f" =~ .pdf$ ]] && echo "Warning: Skipping ${f##*/} (must be .pdf)" && continue
    echo "Converting ${f##*/}..."
    convert -flatten -units PixelsPerInch -density 1200 -background white "$f" "${f%.pdf}.png"
  done
}
svg2png() {
  # See: https://stackoverflow.com/a/50300526/4970632 (python is faster and convert 'dpi' is ignored)
  for f in "$@"; do
    ! [[ "$f" =~ .svg$ ]] && echo "Warning: Skipping ${f##*/} (must be .svg)" && continue
    echo "Converting ${f##*/}..."
    python -c "import cairosvg; cairosvg.svg2png(url='$f', write_to='${f%.svg}.png', scale=3, background_color='white')"
    # && convert -flatten -units PixelsPerInch -density 1200 -background white "$f" "${f%.svg}.png"
  done
}
webm2mp4() {
  for f in "$@"; do
    # See: https://stackoverflow.com/a/49379904/4970632
    ! [[ "$f" =~ .webm$ ]] && echo "Warning: Skipping ${f##*/} (must be .webm)" && continue
    echo "Converting ${f##*/}..."
    ffmpeg -i "$f" -crf 18 -c:v libx264 "${f%.webm}.mp4"
  done
}

# Modifying and merging pdfs
pdf2flat() {
  # This page is helpful:
  # https://unix.stackexchange.com/a/358157/112647
  # 1. pdftk keeps vector graphics
  # 2. convert just converts to bitmap and eliminates transparency
  # 3. pdf2ps piping retains quality (ps uses vector graphics, but can't do transparency)
  # convert "$f" "${f}_flat.pdf"
  # pdftk "$f" output "${f}_flat.pdf" flatten
  for f in "$@"; do
    ! [[ "$f" =~ .pdf$ ]] && echo "Warning: Skipping ${f##*/} (must be .pdf)" && continue
    [[ "$f" =~ _flat ]] && echo "Warning: Skipping ${f##*/} (has 'flat' in name)" && continue
    echo "Converting $f..." && pdf2ps "$f" - | ps2pdf - "${f%.pdf}_flat.pdf"
  done
}
png2flat() {
  # See: https://stackoverflow.com/questions/46467523/how-to-change-picture-background-color-using-imagemagick
  for f in "$@"; do
    ! [[ "$f" =~ .png$ ]] && echo "Warning: Skipping ${f##*/} (must be .png)" && continue
    [[ "$f" =~ _flat ]] && echo "Warning: Skipping ${f##*/} (has 'flat' in name)" && continue
    convert "$f" -opaque white -flatten "${f%.png}_flat.png"
  done
}
pdfmerge() {
  # See: https://stackoverflow.com/a/2507825/4970632
  # NOTE: Unlike bash arrays argument arrays are 1-indexed since $0 is -bash
  [ $# -lt 2 ] && echo "Error: At least 3 arguments required." && return 1
  for file in "$@"; do
    ! [[ "$file" =~ .pdf$ ]] && echo "Error: Files must be PDFs." && return 1
    ! [ -r "$file" ] && echo "Error: File '$file' does not exist." && return 1
  done
  pdftk "$@" cat output "${1%.pdf} (merged).pdf"
}

# Converting between fonts
# Requires brew install fontforge
otf2ttf() {
  for f in "$@"; do
    ! [[ "$f" =~ .otf$ ]] && echo "Warning: Skipping ${f##*/} (must be .otf)" && continue
    echo "Converting ${f##*/}..."
    fontforge -c \
      "import fontforge; from sys import argv; f = fontforge.open(argv[1]); f.generate(argv[2])" \
      "${f%.*}.otf" "${f%.*}.ttf"
  done
}
ttf2otf() {
  for f in "$@"; do
    ! [[ "$f" =~ .ttf$ ]] && echo "Warning: Skipping ${f##*/} (must be .ttf)" && continue
    fontforge -c \
      "import fontforge; from sys import argv; f = fontforge.open(argv[1]); f.generate(argv[2])" \
      "${f%.*}.ttf" "${f%.*}.otf"
  done
}

# Rudimentary wordcount with detex
# The -e flag ignores certain environments (e.g. abstract environment)
wctex() {
  local detexed=$( \
    detex -e 'abstract,addendum,tabular,align,equation,align*,equation*' "$1" \
    | grep -v .pdf | grep -v 'fig[0-9]' \
  )
  echo "$detexed" | xargs  # print result in one giant line
  echo "$detexed" | wc -w  # get word count
}

# This is *the end* of all function and alias declarations
echo 'done'

#-----------------------------------------------------------------------------#
# FZF fuzzy file completion tool
#-----------------------------------------------------------------------------#
# Run installation script; similar to the above one
# if [ -f ~/.fzf.bash ] && ! [[ "$PATH" =~ fzf ]]; then
if [ "${FZF_SKIP:-0}" == 0 ] && [ -f ~/.fzf.bash ]; then
  # Various default settings (see man page for --bind information)
  # * Inline info puts the number line thing on same line as text.
  # * Bind slash to accept so behavior matches shell completion behavior.
  # * Enforce terminal background default color using -1 below.
  # * For ANSI color codes see: https://stackoverflow.com/a/33206814/4970632
  _setup_message 'Enabling fzf'
  # shellcheck disable=2034
  {
    _fzf_opts=" \
    --ansi --color=bg:-1,bg+:-1 --layout=default \
    --select-1 --exit-0 --inline-info --height=6 \
    --bind=tab:accept,ctrl-a:toggle-all,ctrl-s:toggle,ctrl-g:jump,ctrl-j:down,ctrl-k:up \
    "
    export FZF_DEFAULT_OPTS="$_fzf_opts"  # critical to export so used by vim
    FZF_COMPLETION_TRIGGER=''  # must be literal empty string rather than unset
    FZF_COMPLETION_OPTS="$_fzf_opts"  # tab triggers completion
    FZF_CTRL_T_OPTS="$_fzf_opts"
    FZF_ALT_C_OPTS="$_fzf_opts"
  }

  # Defualt find commands. The compgen ones were addd by my fork, others are native, we
  # adapted defaults from defaultCommand in .fzf/src/constants.go and key-bindings.bash
  # shellcheck disable=2034
  {
    _fzf_prune="\\( \
    -path '*.git' -o -path '*.svn' \
    -o -path '*.ipynb_checkpoints' -o -path '*__pycache__' \
    -o -path '*.DS_Store' -o -path '*.vimsession' \
    -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \
    \\) -prune \
    "
    export FZF_DEFAULT_COMMAND="set -o pipefail; command find -L . -mindepth 1 $_fzf_prune \
    -o -type f -print -o -type l -print 2>/dev/null | cut -b3- \
    "
    FZF_ALT_C_COMMAND="command find -L . -mindepth 1 $_fzf_prune \
    -o -type d -print 2>/dev/null | cut -b3- \
    "  # recursively search directories and cd into them
    FZF_CTRL_T_COMMAND="command find -L . -mindepth 1 $_fzf_prune \
    -o \\( -type d -o -type f -o -type l \\) -print 2>/dev/null | cut -b3- \
    "  # recursively search files
    FZF_COMPGEN_DIR_COMMAND="command find -L \"\$1\" -maxdepth 1 -mindepth 1 $_fzf_prune \
    -o -type d -print 2>/dev/null | sed 's@^.*/@@' \
    "
    FZF_COMPGEN_PATH_COMMAND="command find -L \"\$1\" -maxdepth 1 -mindepth 1 $_fzf_prune \
    -o \\( -type d -o -type f -o -type l \\) -print 2>/dev/null | sed 's@^.*/@@' \
    "
  }

  # Source bash file
  complete -r  # reset first
  source ~/.fzf.bash
  echo 'done'

  # FZF tab completion for non-empty line that is not preceded by word + space.
  # See: https://stackoverflow.com/a/42085887/4970632
  # See: https://unix.stackexchange.com/a/217916/112647
  # NOTE: This prevents '-o' options from getting used becuase we call the functions
  # directly... but perhaps better to relegate everything to the functions, and not
  # sure when -o default and -o bashdefault even get used.
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
# Shell integration for iTerm2
#-----------------------------------------------------------------------------#
# Show inline figures with fixed 300dpi
# Make sure it was not already installed and we are not inside vim :terminal
# Turn off prompt markers with: https://stackoverflow.com/questions/38136244/iterm2-how-to-remove-the-right-arrow-before-the-cursor-line
if [ "${ITERM_SHELL_INTEGRATION_SKIP:-0}" == 0 ] \
  && [ -z "$ITERM_SHELL_INTEGRATION_INSTALLED" ] \
  && [ -f ~/.iterm2_shell_integration.bash ] \
  && [ -z "$VIMRUNTIME" ]; then
  # Enable shell integration
  _setup_message 'Enabling shell integration'
  source ~/.iterm2_shell_integration.bash

  # Add helper functions
  for func in imgcat imgls; do
    unalias $func
    eval 'function '$func'() {
      local i tmp files
      i=0
      files=("$@")
      for file in "${files[@]}"; do
        if [ "${file##*.}" == pdf ]; then
          tmp=./tmp.${file%.*}.png  # convert to png
          convert -flatten -units PixelsPerInch -density 300 -background white "$file" "$tmp"
        else
          tmp=./tmp.${file}
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
#-----------------------------------------------------------------------------#
# Find conda base
# NOTE: Must save brew path before setup (conflicts with conda; try 'brew doctor')
alias brew="PATH=\"$PATH\" brew"
if [ -d "$HOME/anaconda3" ]; then
  _conda=$HOME/anaconda3
elif [ -d "$HOME/miniconda3" ]; then
  _conda=$HOME/miniconda3
else
  unset _conda
fi

# Optionally initiate conda
# WARNING: This must come after shell integration or gets overwritten
# WARNING: Making conda environments work with jupyter is complicated. Have
# to remove stuff from ipykernel and then install them manually.
# See: https://stackoverflow.com/a/54985829/4970632
# See: https://stackoverflow.com/a/48591320/4970632
# See: https://medium.com/@nrk25693/how-to-add-your-conda-environment-to-your-jupyter-notebook-in-just-4-steps-abeab8b8d084
if [ "${CONDA_SKIP:-0}" == 0 ] && [ -n "$_conda" ] && ! [[ "$PATH" =~ conda3 ]]; then
  # Initialize conda. Generate this code with 'mamba init'
  _setup_message 'Enabling conda'
  __conda_setup=$("$_conda/bin/conda" 'shell.bash' 'hook' 2>/dev/null)
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "$_conda/etc/profile.d/conda.sh" ]; then
      source "$_conda/etc/profile.d/conda.sh"
    else
      export PATH="$_conda/bin:$PATH"
    fi
  fi
  unset __conda_setup
  if [ -f "$_conda/etc/profile.d/mamba.sh" ]; then
    source "$_conda/etc/profile.d/mamba.sh"
  fi
  if ! [[ "$PATH" =~ condabin ]]; then
    export PATH=$_conda/condabin:$PATH
  fi

  # Function to list available packages
  conda-avail() {
    local version versions
    [ $# -ne 1 ] && echo "Usage: avail PACKAGE" && return 1
    echo "Package:            $1"
    version=$(mamba list "^$1$" 2>/dev/null)
    [[ "$version" =~ "$1" ]] \
      && version=$(echo "$version" | grep "$1" | awk 'NR == 1 {print $2}') \
      || version="N/A"  # get N/A if not installed
    echo "Current version:    $version"
    versions=$(mamba search -c conda-forge "$1" 2>/dev/null) \
      || { echo "Error: Package \"$1\" not found."; return 1; }
    versions=$(echo "$versions" | grep "$1" | awk '!seen[$2]++ {print $2}' | tac | sort | xargs)
    echo "Available versions: $versions"
  }

  # Activate conda
  # NOTE: This calls '__conda_activate activate' which runs the command list returned
  # by '__conda_exe shell.posix activate'. Can time things by inspecting this list.
  mamba activate base
  echo 'done'
fi

#-----------------------------------------------------------------------------#
# Prompt and title management
#-----------------------------------------------------------------------------#
# Safely add a prompt command
_prompt() {  # input argument should be new command
  export PROMPT_COMMAND=$(echo "$PROMPT_COMMAND; $1" | sed 's/;[ \t]*;/;/g;s/^[ \t]*;//g')
}

# Set the iTerm2 window title; see https://superuser.com/a/560393/506762
# 1. First was idea to make title match working directory but fails inside tmux
#    export PROMPT_COMMAND='echo -ne "\033]0;${PWD/#$HOME/~}\007"'
# 2. Next idea was to use environment variabbles -- TERM_SESSION_ID/ITERM_SESSION_ID
#    indicate the window/tab/pane number so we can grep and fill.
_title_file=$HOME/.title
if [[ "$TERM_PROGRAM" =~ Apple_Terminal ]]; then
  _win_num=0
else
  _win_num=${TERM_SESSION_ID%%t*}
fi
_win_num=${_win_num#w}

# First function that sets title
# Record title from user input, or as user argument
_title_set() {  # default way is probably using Cmd-I in iTerm2
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
alias title='_title_set'  # easier for user
if $_macos; then
  [[ "$PROMPT_COMMAND" =~ "_title_update" ]] || _prompt _title_update
  [[ "$TERM_SESSION_ID" =~ w?t?p0: ]] && _title_update
fi

#-----------------------------------------------------------------------------#
# Mac stuff
#-----------------------------------------------------------------------------#
# TODO: This hangs when run from interactive cluster node, we test by comparing
# hostname variable with command (variable does not change)
if $_macos; then # first the MacOS options
  # Homebrew-bash as default shell
  grep '/usr/local/bin/bash' /etc/shells 1>/dev/null \
    || sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'  # add to valid list
  [ -n "$TERM_PROGRAM" ] && ! [[ $BASH_VERSION =~ ^[4-9].* ]] \
    && chsh -s /usr/local/bin/bash  # change shell to Homebrew-bash, if not in MacVim

  # Audio and video
  enable_sleep() {
    sudo pmset -a sleep 1
    sudo pmset -a hibernatemode 1
    sudo pmset -a disablesleep 0
  }
  disable_sleep() {  # see: https://gist.github.com/pwnsdx/2ae98341e7e5e64d32b734b871614915
    sudo pmset -a sleep 0
    sudo pmset -a hibernatemode 0
    sudo pmset -a disablesleep 1
  }
  print_weather() {
    curl 'wttr.in/Fort Collins'
  }
  print_artists() {
    find ~/Music -mindepth 2 -type f -printf "%P\n" \
      | cut -d/ -f1 \
      | grep -v ^Media$ \
      | uniq -c \
      | sort -n
  }
  sort_artists() {
    local base artist title
    for file in "$@"; do
      # shellcheck disable=SC2049
      [[ "$file" =~ \.m4a$|\.mp3$ ]] || continue
      base=${file##*/}
      artist=${base% - *}
      title=${base##* - }
      [ -d "$artist" ] || mkdir "$artist"
      mv "$file" "$artist/$title"
      echo "Moved '$base' to '$artist/$title'."
    done
  }
  strip_audio() {
    local file
    for file in "$@"; do
      ffmpeg -i "$file" -vcodec copy -an "${file%.*}_stripped.${file##*.}"
    done
  }
fi

#-----------------------------------------------------------------------------#
# Message
#-----------------------------------------------------------------------------#
[ -n "$VIMRUNTIME" ] \
  && unset PROMPT_COMMAND
[ -z "$_bashrc_loaded" ] && [ "$(hostname)" == "$HOSTNAME" ] \
  && curl https://icanhazdadjoke.com/ 2>/dev/null && echo  # yay dad jokes
_bashrc_loaded=true
