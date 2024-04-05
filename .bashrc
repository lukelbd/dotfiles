#!/bin/bash
# shellcheck disable=1090,2181,2120,2076
#-----------------------------------------------------------------------------
# This should override defaults in /etc/profile in /etc/bashrc. Check out the system
# default setting before using this and make sure your $PATH is populated. To permit
# pulling from github use ssh-keygen -R github.com and to SSH between servers see below:
# https://github.blog/2023-03-23-we-updated-our-rsa-ssh-host-key/
# https://thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
# * To see what is available for package/environment managers, possibly ignoring
#   dependencies, use e.g. brew (list|leaves|deps --installed) (--cask|--formulae),
#   port installed (requested), tlmgr list --only-installed (tlmgr update --list for
#   'updateable' packages and tlmgr update --all to update), mamba (env) list (or list
#   <package>), mamba env export --from-history (no deps), pip (list|feeze) (or show
#   <package>), pip-chill (no deps), jupyter kernelspec||labextension|nbextension list.
# * For ARM-copatible version of chromium tried 'brew install --cask eloston-chromium'
#   but seems to sometimes download intel version. Instead follow these links:
#   https://github.com/ungoogled-software/ungoogled-chromium#downloads
#   https://ungoogled-software.github.io/ungoogled-chromium-binaries/releases/macos/
#   Then automatically open notebooks and other "localhost" links in popup-style kiosks
#   without menu bars by having Choosy auto-select the pseudo-app "LocalHost" created by
#   platypus when "localhost" is in the URL (simply calls chromium --kiosk "$url").
# * Switch between jupyter kernels in a lab session by installing nb_conda_kernels:
#   https://github.com/Anaconda-Platform/nb_conda_kernels. In some jupyter versions
#   requires removing ~/mambaforge/etc/jupyter/jupyter_config.json to suppress warnings.
#   See: https://fcollonval.medium.com/conda-environments-in-jupyter-ecosystem-without-pain-e9fab3992fb7
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
# * To prevent 'template_path' warning message, edit jupyter_nbconvert_config.json
#   config file in $CONDA_PREFIX/etc/jupyter/, then update latex_envs with:
#   pip uninstall jupyter_latex_envs  # otherwise may not update
#   pip install git+https://github.com/jfbercher/jupyter_latex_envs.git and (if needed)
#   pip install git+https://github.com/ipython-contrib/jupyter_contrib_nbextensions.git.
#   See: https://github.com/ipython-contrib/jupyter_contrib_nbextensions/issues/1529
#   See: https://github.com/jupyter/nbconvert/pull/1310
# * Seems 'ipywidgets' is dependency of a few plugins but can emit annoying
#   'ERROR | No such comm target registered:' messages on first run... tried using
#   'jupyter nbextension install --py widgetsnbextension --user' followed by
#   'jupyter nbextension enable --py widgetsnbextension' to suppress.
#   See: https://github.com/jupyter-widgets/ipywidgets/issues/1720#issuecomment-330598324
#   However this fails. Instead should just ignore message as it is harmless.
#   See: https://github.com/jupyter-widgets/ipywidgets/issues/2257#issuecomment-1110056315
# * Use asciinema for screen recordings: 'brew install asciinema' and run with key
#   presses using 'asciinema rec --stdin [filename]'. For presentations tried pympress
#   and copied impressive and presentation to bin but had issues. Now use Presentation.
#   mamba install gtk3 cairo poppler pygobject && pip install pympress
#   brew install pygobject3 --with-python3 gtk+3 && /usr/local/bin/pip3 install pympress
#   See: http://iihm.imag.fr/blanch/software/osx-presentation/
#   See: https://github.com/asciinema/asciinema/
# * Prefix key for issuing SSH-session commands is '~' ('exit' sometimes
#   fails perhaps because it is aliased or some 'exit' is defined in $PATH).
#   exit -- Terminate SSH session (if available)
#   ~c-z -- Stop current SSH session
#   ~c -- Enter SSH command line
#   ~. -- Terminate SSH session (always available)
#   ~& -- Send SSH session into background
#   ~# -- Give list of forwarded connections in this session
#   ~? -- Give list of these commands
#-----------------------------------------------------------------------------
# Apply prompt "<comp name>[<job count>]:<push dir N>:...:<push dir 1>:<work dir> <user>$"
# Ensure the prompt is applied only once so modules can modify it
# See: https://unix.stackexchange.com/a/124408/112647
# See: https://unix.stackexchange.com/a/420362/112647
_prompt_head() {  # print parentheses around git branch similar to conda environments
  local opt env base branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  base=${CONDA_PREFIX_1:-$CONDA_PREFIX}  # both empty after conda deactivate
  [ -n "$base" ] && [ "$CONDA_PREFIX" == "$base" ] && env=base || env=${CONDA_PREFIX##*/}
  for opt in "$env" "$branch"; do [ -n "$opt" ] && printf "(%s) " "$opt"; done
}
_prompt_tail() {  # prompt string "<push dir N>:...:<push dir 1>:<work dir> <user>$"
  local paths
  IFS=$'\n' read -d '' -r -a paths < <(command dirs -p | tac)
  IFS=: eval 'echo "${paths[*]##*/}"'
}
[[ $- != *i* ]] && return  # not interactive (scp/rscync fail without this line)
[[ "$PS1" =~ _prompt_head ]] && [[ "$PS1" =~ _prompt_tail ]] \
  || PS1='$(_prompt_head)\[\033[1;37m\]\h[\j]:$(_prompt_tail)\$ \[\033[0m\]'

# Apply general shell settings
# Ensure interactive mode present and remove aliases
# See: https://stackoverflow.com/a/28938235/4970632
# See: https://unix.stackexchange.com/a/88605/112647
_setup_message() { printf '%s' "${1}$(seq -s '.' $((30 - ${#1})) | tr -d 0-9)"; }
_setup_message 'General setup'
_setup_shell() {         # apply shell options (list available with shopt -p)
  stty werase undef      # disable ctrl-w word delete function
  stty stop undef        # disable ctrl-s start/stop binding
  stty eof undef         # disable ctrl-d end-of-file binding
  stty -ixon             # disable start stop output control to allow ctrl-s
  shopt -s autocd        # typing naked directry name will cd into it
  shopt -s cdspell       # attempt spelling crrection of cd arguments
  shopt -s cdable_vars   # cd into shell ariable directories, no $ necessary
  shopt -s checkwinsize  # allow window esizing
  shopt -s cmdhist       # save multi-line comands as one command in history
  shopt -s direxpand     # expand directoris
  shopt -s dirspell      # attempt spelling orrection of dirname
  shopt -s globstar      # **/ matches all sbdirectories, searches recursively
  shopt -s histappend    # append to the hstory file, don't overwrite it
  shopt -u dotglob       # include dot patters in glob matches
  shopt -u extglob       # extended globbing;allows use of ?(), *(), +(), +(), @(), and !() with separation "|" for OR options
  shopt -u failglob      # no error message f expansion is empty
  shopt -u nocaseglob    # match case in gob expressions
  shopt -u nocasematch   # match case in ase/esac and [[ =~ ]] instances
  shopt -u nullglob      # turn off nullglob so e.g. no null-expansion of string with ?, * if no matches
  shopt -u no_empty_cmd_completion  # enble empty command completion
  export HISTSIZE=5000  # enable huge hitory
  export HISTFILESIZE=5000  # enable hug history
  export HISTIGNORE='&:bg:fg:exit:clear' # don't record some commands
  export HISTCONTROL=''  # note ignoreboh = ignoredups + ignorespace
  export PROMPT_DIRTRIM=2  # trim long pths in prompt
  bind -i -f ~/.inputrc  # apply inputrc overrides
  bind '"\e[1;2D": unix-line-discard'  # shift arrow overrides
  bind '"\e[1;2C": kill-line'
  bind '"\e[1;2B": backward-kill-word'
  bind '"\e[1;2A": kill-word'
  bind '"\e[1;3A": shell-backward-word'  # alt arrow overrides
  bind '"\e[1;3B": shell-forward-word'
  bind '"\e[1;3C": forward-word'
  bind '"\e[1;3D": backward-word'
}
_setup_shell 2>/dev/null  # ignore if opton unavailable
unalias -a  # critical (also use declare -F for definitions)

# Apply machine dependent settings
# * List homebrew installs with 'brew list' (narrow with --formulae or --casks).
#   Show package info with 'brew info package'. Use 'brew install trash' for trash cmd
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
#   gnu-tar gawk'. Found paths with: https://apple.stackexchange.com/q/69223/214359
#   Also installed access to macOS 'trash' using 'brew install trash'.
# NOTE: Logging into network WiFi sometimes converts hostname to automatic names, e.g.
# DESKTOP-NNN.ColoState.EDU or eduroam-NNN-NNN. Repair with 'sudo hostname HOST'
# See: https://apple.stackexchange.com/q/40734/214359
# NOTE: Fix permission issues after migrating macbooks with following command:
# sudo chown -R $(whoami):admin /usr/local/* && sudo chmod -R g+rwx /usr/local/*
# See: https://stackoverflow.com/a/50219099/4970631
# NOTE: Use rvm below for scripting. Make sure this is the last PATH variable change.
# Critical to install with rvm or get endless issues with MacPorts versus Homebrew
# versions:: https://stackoverflow.com/a/3464303/4970632
# NOTE: Tried exporting DYLD_FALLBACK_LIBRARY_PATH but it screwed up some python
# modules so instead just always invoke ncl with temporarily set DYLD_LIBRARY_PATH.
# Note ncl is realiased below and are careful to preserve any leading paths.
# NOTE: Used to install gcc and gfortran with 'port install libgcc7' then 'port select
# --set gcc mp-gcc7' (needed for ncl) (try 'port select --list gcc') but latest
# versions had issues. Now use 'brew install gcc@7' then add aliases to definitions.
# NOTE: Should not need to edit $MANPATH since man is intelligent and should detect
# 'man' folders automatically even for custom utilities. However if the resuilt of
# 'manpath' is missing something follow these notes: https://unix.stackexchange.com/q/344603/112647
# NOTE: HDF5 setting is for cdo: 'Mac users may need to set the environment variable
# "HDF5_USE_FILE_LOCKING" to the five-character string "FALSE" when accessing network
# mounted files. This is an application run-time setting, not a build setting. Otherwise
# errors such as "unable to open file" or "HDF5 error" may be encountered.'
_macos=false
_load_modules() {
  # module purge 2>/dev/null
  local module   # but _loaded_modules is global
  read -r -a _loaded_modules < <(module --terse list 2>&1)
  for module in "$@"; do [[ " ${_loaded_modules[*]} " =~ " $module " ]] || module load "$module"; done
}
case "${HOSTNAME%%.*}" in
  vortex*|velouria*|maelstrom*|uriah*)  # macbook
    _macos=true
    unset MANPATH  # reset man path
    alias locate='/usr/bin/locate'  # coreutils version fails
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin  # defaults
    export PATH=/Library/TeX/texbin:$PATH  # latex
    export PATH=/opt/X11/bin:$PATH  # X11
    export PATH=/usr/local/bin:/opt/local/bin:/opt/local/sbin:$PATH  # homebrew
    export PATH=/usr/local/opt/grep/libexec/gnubin:$PATH  # macports
    export PATH=/usr/local/opt/gnu-tar/libexec/gnubin:$PATH
    export PATH=/usr/local/opt/gnu-sed/libexec/gnubin:$PATH
    export PATH=/usr/local/opt/findutils/libexec/gnubin:$PATH
    export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
    export PATH=/opt/pgi/osx86-64/2018/bin:$PATH  # pgi compilers
    export PATH=$HOME/builds/matlab-r2019a/bin:$PATH  # local builds
    export PATH=$HOME/builds/ncl-6.6.2/bin:$PATH
    export PATH=/Applications/Skim.app/Contents/MacOS:$PATH  # skim utilities
    export PATH=/Applications/Skim.app/Contents/SharedSupport:$PATH
    export PATH=/Applications/Calibre.app/Contents/MacOS:$PATH
    export NCARG_ROOT=$HOME/builds/ncl-6.6.2  # or macports: /opt/local/lib/libgcc
    alias ncl='DYLD_LIBRARY_PATH=/usr/local/lib/gcc/7/ ncl'  # brew libraries
    alias c++='/usr/local/bin/c++-11'  # point to verion (see above)
    alias cpp='/usr/local/bin/cpp-11'  # point to verion (see above)
    alias gcc='/usr/local/bin/gcc-11'  # point to verion (see above)
    alias gfortran='/usr/local/bin/gfortran-11'  # alias already present but why not
    export LM_LICENSE_FILE=/opt/pgi/license.dat-COMMUNITY-18.10
    export PKG_CONFIG_PATH=/opt/local/bin/pkg-config
    export HDF5_USE_FILE_LOCKING=FALSE  # required for cdo (see above)
    if [ -d ~/.rvm/bin ]; then  # install with: \curl -sSL https://get.rvm.io | bash -s stable --ruby
      [ -s ~/.rvm/scripts/rvm ] && source ~/.rvm/scripts/rvm  # load RVM into a shell session *as a function*
      export PATH=$PATH:$HOME/.rvm/bin:$HOME/.rvm/gems/default/bin
      export rvm_silence_path_mismatch_check_flag=1
      rvm use ruby 1>/dev/null  # test with ruby -ropen-uri -e 'eval open("https://git.io/vQhWq").read'
    fi
    ;;
  monde)  # could use 'source set_pgi.sh' but instead do manually
    _pgi_version='19.10'  # increment this as needed
    export PATH=/usr/bin:/usr/local/sbin:/usr/sbin  # general
    export PATH=/usr/local/bin:$PATH  # general
    export PATH=/usr/lib64/mpich/bin:/usr/lib64/qt-3.3/bin:$PATH  # pgi compilers
    export PATH=/opt/pgi/linux86-64/$_pgi_version/bin:$PATH  # pgi utilities
    export PGI=/opt/pgi
    export LD_LIBRARY_PATH=/usr/lib64/mpich/lib:/usr/local/lib
    export LM_LICENSE_FILE=/opt/pgi/license.dat-COMMUNITY-$_pgi_version
    export GFDL_BASE=$HOME/isca  # isca environment
    export GFDL_ENV=monde  # configuration for emps-gv4
    export GFDL_WORK=/mdata1/ldavis/isca_work  # temporary working directory used in running the model
    export GFDL_DATA=/mdata1/ldavis/isca_data  # directory for storing model output
    export NCARG_ROOT=/usr/local  # ncl root
    ;;
  euclid*)  # all netcdf/mpich utilities already in /usr/local/bin
    export PATH=/usr/local/bin:/usr/bin:/bin:$PATH
    export PATH=/opt/pgi/linux86-64/13.7/bin:/opt/Mathworks/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/lib
    ;;
  cheyenne*)  # cheyenne supercomputer (use 'sinteractive' for interactive mode)
    INTEL=/glade/u/apps/ch/opt/netcdf/4.6.1/intel/17.0.1/lib  # compilers
    export TMPDIR=/glade/scratch/$USER/tmp  # see: https://www2.cisl.ucar.edu/user-support/storing-temporary-files-tmpdir
    export LD_LIBRARY_PATH=$INTEL:$LD_LIBRARY_PATH  # compilers
    _load_modules netcdf tmux intel impi  # cdo and nco via conda
    ;;
  midway*)  # chicago supercomputer
    export PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
    export PROMPT_COMMAND=${PROMPT_COMMAND//printf*\";/}  # remove print statement
    _load_modules mlk intel  # cdo and nco via conda
    ;;
  *)  # unknown
    echo "Warning: Host '$HOSTNAME' does not have any custom bashrc settings."
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
export PATH=$HOME/bin:$PATH  # custom scripts

# Various python stuff
# NOTE: Could not get itermplot to work. Inline figures too small.
# NOTE: For download stats use 'condastats overall <package>' or 'pypistats <package>'.
# As of 2023-03-21 for proplot get 51k all-time conda downloads and 10k 180-day proplot
# downloads equals approximately (since 2019?) 80k pypi downloads?
unset MPLBACKEND
unset PYTHONPATH
export PYTHONUNBUFFERED=1  # must set this or python prevents print statements from getting flushed to stdout until exe finishes
export PYTHONBREAKPOINT=IPython.embed  # use ipython for debugging! see: https://realpython.com/python37-new-features/#the-breakpoint-built-in
export MAMBA_NO_BANNER=1  # suppress goofy banner as shown here: https://github.com/mamba-org/mamba/pull/444
export MPLCONFIGDIR=$HOME/.matplotlib  # same on every machine

# Add custom research pathsw
# NOTE: Paradigm is to put models in 'models', raw data in 'data' or scratch, shared
# research utilities or general ideas in 'shared', and project-specific utilities
# and ideas in 'research'. Could also try 'papers' and 'projects' but this works.
_dirs_models=(ncparallel mppnccombine)
_dirs_shared=(climate-data cmip-data observed idealized coupled)
_dirs_research=(timescales persistence constraints relationships hierarchy carbon-cycle)
for _name in "${_dirs_models[@]}"; do
  if [ -r "$HOME/models/$_name" ]; then
    export PATH=$HOME/models/$_name:$PATH
  elif [ -r "$HOME/$_name" ]; then
    export PATH=$HOME/$_name:$PATH
  fi
done
for _name in "${_dirs_shared[@]}"; do
  if [ -r "$HOME/shared/$_name" ]; then
    export PYTHONPATH=$HOME/shared/$_name:$PYTHONPATH
  elif [ -r "$HOME/$_name" ]; then
    export PYTHONPATH=$HOME/$_name:$PYTHONPATH
  fi
done
for _name in "${_dirs_research[@]}"; do
  if [ -r "$HOME/research/$_name" ]; then
    export PYTHONPATH=$HOME/research/$_name:$PYTHONPATH
  elif [ -r "$HOME/$_name" ]; then
    export PYTHONPATH=$HOME/$_name:$PYTHONPATH
  fi
done

# Adding additional flags for building C++ stuff
# NOTE: This is required for e.g. pypinfo and other commands
# https://github.com/matplotlib/matplotlib/issues/13609
# https://github.com/huggingface/neuralcoref/issues/97#issuecomment-436638466
export CFLAGS=-stdlib=libc++
export GOOGLE_APPLICATION_CREDENTIALS=$HOME/pypi-downloads.json  # for pypinfo
echo 'done'

#-----------------------------------------------------------------------------
# General aliases and functions
#-----------------------------------------------------------------------------
# Standardize colors and configure ls and cd commands
# For less/man/etc. colors see: https://unix.stackexchange.com/a/329092/112647
_setup_message 'Utility setup'
[ -r "$HOME/.dircolors.ansi" ] && eval "$(dircolors ~/.dircolors.ansi)"
alias cd='cd -P'                    # don't want this on my mac temporarily
alias ls='ls --color=always -AF'    # ls with dirs differentiate from files
alias ld='ls --color=always -AFd'   # ls with details and file sizes
alias ll='ls --color=always -AFhl'  # ls with details and file sizes
alias curl='curl -O'                # always download associated file
alias dirs='dirs -p | tac | xargs'  # show dir stack matching prompt order
alias ctime='date +%s'              # current time in seconds since epoch
alias mtime='date +%s -r'           # modification time of input file
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
alias binds='bind -P'  # the functions, for example 'forward-char'
alias inputs='bind -v'  # the 'set' options, and their values
alias actions='bind -l'  # the functions, for example 'forward-char'
alias aliases='compgen -a'  # shell aliases
alias variables='compgen -v'  # shell variables
alias functions='compgen -A function'  # shell functions
alias builtins='compgen -b'  # bash builtins
alias commands='compgen -c'  # bash commands
alias keywords='compgen -k'  # bash commands
alias modules='module avail 2>&1 | cat '
alias bindings_stty='stty -a'  # show bindings (linux and coreutils)
kinds() { ctags --list-kinds="$*"; }  # list language shortcuts
kinds-all() { ctags --list-kinds-full="$*"; }  # list language shortcuts
# alias bindings_stty='stty -e'  # show bindings (native mac)
if $_macos; then  # see https://apple.stackexchange.com/a/352770/214359
  alias cores="sysctl -a | grep -E 'machdep.cpu.*(brand|count)'"
  alias hardware='sw_vers'  # see https://apple.stackexchange.com/a/255553/214359
  alias bindings="bind -Xps | egrep '\\\\C|\\\\e' | grep -v do-lowercase-version | sort"
else  # shellcheck disable=2142
  alias cores="cat /proc/cpuinfo | awk '/^processor/{print \$3}' | wc -l"
  alias hardware="cat /etc/*-release"  # print operating system info
  alias bindings="bind -ps | egrep '\\\\C|\\\\e' | grep -v do-lowercase-version | sort"
fi

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
alias du='du -h'
alias d0='du -h -d 1'  # single directory, see also r0 a0
alias df='df -h'
function mv() {
  git mv "$@" 2>/dev/null || command mv "$@"
}
dl() {
  local dir='.'
  [ $# -gt 1 ] && echo "Too many directories." && return 1
  [ $# -eq 1 ] && dir="$1"
  find "$dir" -maxdepth 1 -mindepth 1 -type d -print \
    | sed 's|^\./||' | sed 's| |\\ |g' | _columnize
}
dh() {
  local dir='.'
  [ $# -gt 1 ] && echo "Too many directories." && return 1
  [ $# -eq 1 ] && dir="$1";  # shellcheck disable=2033
  find "$dir" -maxdepth 1 -mindepth 1 -type d -exec du -hs {} \; \
    | sort -sh
}

# Save a log of directory space to home directory
# NOTE: This relies on workflow where ~/scratch folders are symlinks pointing
# to data storage hard disks. Otherwise need to hardcode server-specific folders.
space() {
  local init log sub dir
  log=$HOME/storage.log
  [ -r "$log" ] && init='\n\n' || init=''
  printf "$init"'Timestamp:\n%s\n' "$(date +%s)" >>$log
  for sub in '' '..'; do
    for dir in ~/ ~/scratch*; do
      [ -d "$dir" ] || continue
      printf 'Directory: %s\n' "${dir##*/}/$sub" >>$log
      du -h -d 1 "$dir/$sub" 2>/dev/null >>$log
    done
  done
}

# Listing jobs
# TODO: Add to these utilities?
alias toc='mpstat -P ALL 1'  # table of core processes (similar to 'top')
alias restarts='last reboot | less'
log() {
  while ! [ -r "$1" ]; do
    echo "Waiting..."
    sleep 3
  done
  tail -f "$1"
}
tos() {  # table of shell processes (similar to 'top')
  if [ -z "$1" ]; then
    regex='$4 !~ /^(bash|ps|awk|grep|xargs|tr|cut)$/'
  else
    regex='$4 == "$1"'
  fi
  ps | awk 'NR == 1 {next}; '"$regex"'{print $1 " " $4}'
}

# Killing jobs and supercomputer stuff
 # NOTE: Any background processes started by scripts are not included in pskill!
alias qrm='rm ~/*.[oe][0-9][0-9][0-9]* ~/.qcmd*'  # remove (empty) job logs
qls() {
  qstat -f -w \
    | grep -v '^\s*[A-IK-Z]' \
    | grep -E '^\s*$|^\s*[jJ]ob|^\s*resources|^\s*queue|^\s*[mqs]time'
}
qkill() {  # kill PBS processes at once, useful when debugging and submitting teeny jobs
  local proc
  for proc in $(qstat | tail -n +3 | cut -d' ' -f1 | cut -d. -f1); do  # start at line 3
    qdel "$proc"
    echo "Deleted job $proc"
  done
}
jkill() {  # background jobs by percent sign
  local count
  count=$(jobs | wc -l | xargs)
  for i in $(seq 1 "$count"); do
    echo "Killing job $i..."
    eval "kill %$i"
  done
}
pskill() {  # jobs by ps name
  local strs
  $_macos && echo "Error: Mac ps does not list only shell processes." && return 1
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

#-----------------------------------------------------------------------------
# Editing and scripting utilities
#-----------------------------------------------------------------------------
# Environment variables
export EDITOR='command vim'  # default editor, nice and simple
export LC_ALL=en_US.UTF-8  # needed to make Vim syntastic work

# Receive affirmative or negative response using input message
# Exit according to user input
_confirm() {
  local default paren
  mode=$1 && shift  # whether default is yes or no
  [ "$mode" -eq 1 ] && default=y || default=n
  [ "$mode" -eq 1 ] && paren='[y]/n' || paren='[n]/y'
  [[ $- == *i* ]] && action=return || action=exit  # don't want to quit an interactive shell!
  [[ $# -eq 0 ]] && prompt=Confirm || prompt=$*
  while true; do
    read -r -p "$prompt ($paren) " response
    if [ -n "$response" ] && [[ ! "$response" =~  ^[NnYy]$ ]]; then
      echo "Invalid response."
      continue  # try again
    fi
    if [ -z "$response" ]; then
      response=$default
    fi
    if [[ "$response" =~ ^[Yy]$ ]]; then
      $action 0  # 'good' exit, i.e. yes
    else
      $action 1  # 'bad' exit, i.e. no
    fi
    break
  done
}
confirm-no() { _confirm 0 "$@"; }
confirm-yes() { _confirm 1 "$@"; }

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

# Convert bytes to human
# From: https://unix.stackexchange.com/a/259254/112647
# NOTE: Used to use this in a couple awk scripts in git config aliases
bytes2human() {
  local nums
  # shellcheck disable=2015
  [ $# -gt 0 ] && nums=("$@") || read -r -a nums  # from stdin
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

# Helper function: return if directory is empty or essentially
# empty. See: https://superuser.com/a/352387/506762
isempty() {
  local item items
  read -r -a items < <(find "$1" -maxdepth 1 -mindepth 1 2>/dev/null)
  item="${items[0]##*/}"
  if [ ${#items[@]} -le 1 ] && { [ -z "$item" ] || [ "$item" == .DS_Store ]; }; then
    echo "Path '$1' is empty." && return 0
  else
    echo "Path '$1' is not empty." && return 1
  fi
}

# Either pipe the output of the remaining commands into the less pager
# or open the files. Use the latter only for executables on $PATH
function less() {
  if command -v "$1" &>/dev/null && ! [[ "$1" =~ '/' ]]; then
    "$@" 2>&1 | command less  # pipe output of command
  else
    command less "$@"  # show files in less
  fi
}

# Help page display
# To avoid recursion see: http://blog.jpalardy.com/posts/wrapping-command-line-tools/
# Note some commands (e.g. latexdiff) return bad exit code when using --help so instead
# test line length to guess if it is an error message stub or contains desired info.
function help() {
  local result
  [ $# -eq 0 ] && echo "Requires argument." && return 1
  if builtin help "$@" &>/dev/null; then
    builtin help "$@" 2>&1 | less
  else
    [ "$1" == cdo ] && result=$("$1" --help "${@:2}" 2>&1) || result=$("$@" --help 2>&1)
    if [ "$(echo "$result" | wc -l)" -gt 2 ]; then
      command less <<< "$result"
    else
      echo "No help information for $*."
    fi
  fi
}

# Man page display with auto jumping to relevant info. On macOS man may direct to
# 'builtin' page when 'bash' page actually has relevent docs whiole on linux 'builtin'
# has the docs. Also note man command should print nice error message if nothing found.
# See this answer and comments: https://unix.stackexchange.com/a/18092/112647
function man() {
  local search arg="$*"
  [[ "$arg" =~ " " ]] && arg=${arg//-/ }
  [ $# -eq 0 ] && echo "Requires one argument." && return 1
  if command man "$arg" 2>/dev/null | head -2 | grep "BUILTIN" &>/dev/null; then
    $_macos && [ "$arg" != "builtin" ] && search=bash || search=$arg
    LESS=-p"^ *$arg.*\[.*$" command man "$search" 2>/dev/null
  else
    command man "$arg"  # could display error message
  fi
}


# Prevent git stash from running without 'git stash push' and test message length.
# Note 'git stash --staged push' will stash only staged changes. Should use more often.
# https://stackoverflow.com/q/48751491/4970632
git() {
  local idx arg1 arg2
  if [ "$#" -eq 1 ] && [ "$1" == stash ]; then
    echo 'Error: Run "git stash push --flags" instead.' 1>&2
    return 1
  fi
  if [ "$#" -ge 3 ] && [[ "$1" =~ commit|oops ]]; then
    for idx in $(seq 2 $#); do
      arg1=${*:$idx:1}
      arg2=${*:$((idx+1)):1}
      if [ "$arg1" == '-m' ] || [ "$arg1" == '--message' ] && [ "${#arg2}" -gt 50 ]; then
        echo "Error: Message has length ${#arg2}. Must be less than or equal to 50."
        return 1
      fi
    done
  fi
  command git "$@"
}

# Open one tab per file. Previously cleared screen and deleted scrollback
# history but now just use &restorescreen=1 and &t_ti and &t_te escape codes.
# See: https://vi.stackexchange.com/a/6114
vi() {
  HOME=/dev/null command vim -i NONE -u NONE "$@"
}
vim() {
  [ "${#files[@]}" -gt 0 ] && flags+=(-p)
  command vim --cmd 'set restorescreen' -p "$@"
  [[ " $* " =~ (--version|--help|-h) ]] && return
}

# Vim session initiation and restoration
# See: https://apple.stackexchange.com/q/31872/214359
# NOTE: Previously had manual overrides for various fold commands. But not
# anymore, seems unnecessary with simple FastFold + native folding.
# some reason folds are otherwise re-closed upon openening each file.
# sed -i '/zt/a setlocal nofoldenable' "$path"  # disable folds after opening file
# sed -i 'N;/normal! z[oc]/!P;D' "$path"  # remove previous fold commands
# sed -i '/^[0-9]*,[0-9]*fold$/d' "$path"  # remove manual fold definitions
vim-session() {
  local arg path flags root alt  # flags and session file
  for arg in "$@"; do
    if [[ "$arg" =~ ^-.* ]]; then
      flags+=("$arg")
    elif [ -z "$path" ]; then
      path="$arg"
    else
      echo 'Error: Too many input args.'
      return 1
    fi
  done
  [ -z "$path" ] && path=.vimsession
  [ -r ".vimsession-$path" ] && path=.vimsession-$path
  [ -r ".vimsession_$path" ] && path=.vimsession_$path
  [ -r "$path" ] || { echo "Error: Session file '$path' not found."; return 1; }
  root=$(abspath "$path")  # absolute path with slashes
  root=${root%/*}  # root directory to detect
  alt=${root/$HOME/\~}  # alternative root with tilde
  sed -i "\\:^lcd \\($root\\|$alt\\)\$:d" "$path"  # remove outdated lcd calls
  vim -S "$path" "${flags[@]}"  # call above function
}

# Vim version of help and man page
# NOTE: No longer default. Prefer pagers in general.
vh() {
  local result
  [ $# -eq 0 ] && echo "Requires argument." && return 1
  [ "$1" == cdo ] && result=$("$1" --help "${@:2}" 2>&1) || result=$("$@" --help 2>&1)
  if [ "$(echo "$result" | wc -l)" -gt 2 ]; then
    vim --cmd 'set buftype=nofile' -c "call shell#help_page(0, '$*')"
  else
    echo "No help information for $*."
  fi
}
vm() {
  local search arg="$*"
  [[ "$arg" =~ " " ]] && arg=${arg//-/ }
  [ $# -eq 0 ] && echo "Requires one argument." && return 1
  if command man "$arg" 1>/dev/null; then  # could display error message
    vim --cmd 'set buftype=nofile' -c "call shell#man_page(0, '$*')"
  fi
}

# Open files optionally based on name
# Revert to default behavior if -a specified
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

#-----------------------------------------------------------------------------
# Searching utilities
#-----------------------------------------------------------------------------
# Parse .ignore file for custom utilities (compare to vim tags#ignores())
# TODO: Add utility for *just* ignoring directories not others. Or add utility
# for ignoring absolutely nothing but preserving syntax of other utilities.
# NOTE: Overarching rule is that we do *not* descend into giant subfolders containing
# distributions e.g. mambaforge or plugged unless explicitly go inside them.
# NOTE: This supports internal grepping and finding utilities. Could also be
# expanded to support .fzf finding utilities by setting the ignored files.
ignores() {
  local path line args files folders format exclude
  format=${1:-0}  # whether to format result into find filter
  exclude=$(printf '|%s' "${@:2}")  # patterns to exclude from search
  for path in ~/.ignore ~/.wildignore; do
    while read -r line; do
      [[ "$line" =~ ^! ]] && continue
      [[ "$line" =~ ${exclude:1} ]] && continue
      [[ "$line" =~ ^(\s*\#.*|\s*)$ ]] && continue
      if [[ "$line" =~ / ]]; then
        if [ "$format" -eq 0 ]; then
          folders+=(--exclude-dir "$line")
        else  # 'find' already supports sub directories
          [ ${#folders[@]} -eq 0 ] && args=(-name) || args=(-o -name)
          folders+=("${args[@]}" "*${line//\//}*")
        fi
      else
        if [ "$format" -eq 0 ]; then
          files+=(--exclude "$line")
        else  # 'find' already supports sub directories
          [ ${#files[@]} -eq 0 ] && args=(-name) || args=(-o -name)
          files+=("${args[@]}" "${line}")
        fi
      fi
    done < "$path"
  done
  files=("${files[@]//\*/\\*}")  # prevent expansion after capture
  files=("${files[@]//\?/\\?}")
  folders=("${folders[@]//\*/\\*}")  # prevent expansion after capture
  folders=("${folders[@]//\?/\\?}")
  if [ "$format" -eq 0 ]; then
    echo "${folders[*]} ${files[*]}"
  else  # ignore folders and files
    echo "-type d ( ${folders[*]} ) -prune -o -type f ( ${files[*]} ) -prune -o"
  fi
}

# Grep or find files and pattern
# NOTE: Currently silver searcher does not respect global '~/.ignore' folder in $HOME
# so use override. See: https://github.com/ggreer/the_silver_searcher/issues/1097
# NOTE: Exclude list should be kept in sync with '.ignore' for ripgrep 'rg' and silver
# searcher 'ag'. Should install with 'mamba install the_silver_searcher ripgrep'. Also
# note that directories are only excluded if they are *not below* current directory.
# NOTE: Include list should be kept in sync with 'dircolors.ansi'. Seems 'grep' has no
# way to include extensionless executables. Note when trying to skip hidden files,
# grep --exclude=.* will skip current directory (so require subsequent character [^.])
# and if dotglob is unset then 'find' cannot match hidden files with [.]* (so use .*)
_ignore_ag='--path-to-ignore ~/.ignore --path-to-ignore ~/.wildignore'
_ignore_rg='--ignore-file ~/.ignore --ignore-file ~/.wildignore'
alias ag="ag $_ignore_ag --skip-vcs-ignores --hidden"  # see also .vimrc, .ignore
alias rg="rg $_ignore_rg --no-ignore-vcs --hidden"  # see also .vimrc, .ignore
alias a0="ag $_ignore_ag --skip-vcs-ignores --hidden --depth 0"  # see also 'd0'
alias r0="rg $_ignore_rg --no-ignore-vcs --hidden --max-depth 1"  # see also 'd0'
_find() {
  local commands exclude include header
  include="$1"
  shift  # internal argument
  case "$#" in
    0) commands=(. '*' -print) ;;  # everything
    1) commands=(. "$1" -print) ;;  # path
    2) commands=("$1" "$2" -print) ;;  # path pattern
    *) commands=("$@") ;;  # path pattern (commands)
  esac
  [ "$include" -le 1 ] && exclude=($(ignores 1))  # glob patterns should be escaped
  [ "$include" -le 0 ] && header=(-path '*/.*' -prune -o -name '[A-Z_]*' -prune -o)
  exclude=("${exclude[@]//\\\*/*}") && exclude=("${exclude[@]//\\\?/?}")
  command find "${commands[0]}" "${header[@]}" \
    "${exclude[@]}" -name "${commands[@]:1}"  # arguments after directory
}
_grep() {
  local commands exclude include
  include="$1"
  shift  # internal argument
  case "$#" in
    0) echo 'Error: qgrep() requires at least 1 arg (the pattern).' && return 1 ;;
    1) commands=("$1" .) ;;  # pattern
    *) commands=("$@") ;;  # pattern path(s)
  esac
  [ "$include" -le 1 ] && exclude+=($(ignores 0))  # glob patterns should be escaped
  [ "$include" -le 0 ] && exclude+=(--exclude='[A-Z_.]*')
  [ "$include" -le 0 ] && exclude+=(--exclude-dir='.[^.]*')
  exclude=("${exclude[@]//\\\*/*}") && exclude=("${exclude[@]//\\\?/?}")
  command grep -i -r -E --color=auto --exclude-dir='_*' \
    "${exclude[@]}" "${commands[@]}"  # only regex and paths allowed
}
g0() { _grep 0 "$@"; }  # custom grep with ignore excludes and no hidden files
f0() { _find 0 "$@"; }  # custom find with ignore excludes and no hidden files
g1() { _grep 1 "$@"; }  # custom grep with ignore excludes and hidden files
f1() { _find 1 "$@"; }  # custom find with ignore excludes and hidden files
g2() { _grep 2 "$@"; }  # custom grep with no excludes
f2() { _find 2 "$@"; }  # custom find with no excludes

#-----------------------------------------------------------------------------#
# Git-related utilities
#-----------------------------------------------------------------------------#
# Differencing utilities. Here 'fs' prints git status-style directory diffs,
# 'fd' prints git diff-style file diffs, 'ds' prints recursive directory status
# differences, and 'dd' prints basic directory modification time diferences.
# NOTE: The --textconv option described here: https://stackoverflow.com/a/52201926/4970632
# NOTE: Tried using :(exclude) and :! but does not work with no-index. See following:
# https://stackoverflow.com/a/58845608/4970632 and https://stackoverflow.com/a/53475515/4970632
hash colordiff 2>/dev/null && alias diff='command colordiff'  # use --name-status to compare directories
fs() {  # git status-style file differences
  command git --no-pager diff \
    --textconv --no-index --color=always --name-status "$@" 2>&1 | \
    grep -v -e 'warning:' -e '.vimsession' -e '*.git' -e '*.svn' -e '*.sw[a-z]' \
    -e '*.DS_Store' -e '*.ipynb_checkpoints' -e '.*__pycache__'
}
fd() {  # git diff-style file differences
  command git --no-pager diff \
    --textconv --no-index --color=always "$@" 2>&1 \
    | grep -v -e 'warning:' | \
    tac | sed -e '/Binary files/,+3d' | tac
}
ds() {  # git status-style directory differences
  [ $# -ne 2 ] && echo "Usage: ds DIR1 DIR2" && return 1
  echo "Directory: $1"
  echo "Directory: $2"
  command diff -rq \
    -x '.vimsession' \
    "$1" "$2"
}
dd() {  # directory modification time differences
  [ $# -ne 2 ] && echo "Usage: dt DIR1 DIR2" && return 1
  local dir dir1 dir2 cat1 cat2 cat3 cat4 cat5 file files
  dir1=${1%/}
  dir2=${2%/}
  for dir in "$dir1" "$dir2"; do
    echo "Directory: $dir"
    ! [ -d "$dir" ] && echo "Error: $dir is not an existing directory." && return 1
    files+=$'\n'$( \
      find "$dir" -mindepth 1 \( \
      -path '*.vimsession' -o -path '*.git' -o -path '*.svn' -o -path '*.sw[a-z]' \
      -o -path '*.DS_Store' -o -path '*.ipynb_checkpoints' -o -path '*__pycache__' \
      -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \
      \) -prune -o -print)
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
  [[ ! -r $1 || ! -r $2 ]] && echo "Error: File(s) are not readable." && return 1
  local ext out  # no extension
  if [[ "${1##*/}" =~ \. || "${2##*/}" =~ \. ]]; then
    [ "${1##*.}" != "${2##*.}" ] && echo "Error: Files need same extension." && return 1
    ext=.${1##*.}
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

# Refactor, coding, and logging tools
# TODO: Use vim-lsp rename utility instead? Figure out how to preview?
# NOTE: The awk script builds a hash array (i.e. dictionary) that records number of
# occurences of file paths (should be 1 but this is convenient way to record them).
note() { f0 "${1:-.}" '*' -a -type f -print -a -exec grep -i -n '\bnote:' {} \;; }
todo() { f0 "${1:-.}" '*' -a -type f -print -a -exec grep -i -n '\btodo:' {} \;; }
error() { f0 "${1:-.}" '*' -a -type f -print -a -exec grep -i -n '\berror:' {} \;; }
warning() { f0 "${1:-.}" '*' -a -type f -print -a -exec grep -i -n '\bwarning:' {} \;; }
refactor() {
  local cmd file files result
  $_macos && cmd=gsed || cmd=sed
  [ $# -eq 2 ] \
    || { echo 'Error: refactor() requires two input arguments.'; return 1; }
  result=$(f0 . '*' -print -exec $cmd -E -n "s@^@  @g;s@$1@$2@gp" {} \;) \
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

#-----------------------------------------------------------------------------
# Remote session utilities
#-----------------------------------------------------------------------------
# Supercomputer queue utilities
alias suser="squeue -u \$USER"
alias sjobs="squeue -u \$USER | tail -1 | tr -s ' ' | cut -s -d' ' -f2 | tr -d a-z"

# Current ssh connection viewing
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
    vortex*|velouria*|maelstrom*|uriah*)
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
address() {
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
  local address port nport flags
  if ! $_macos; then
    ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 "$@"
    return $?
  fi
  [[ $# -gt 2 || $# -lt 1 ]] && { echo 'Usage: _ssh HOST [PORT]'; return 1; }
  nport=6  # or just 3?
  address=$(_address "$1") || { echo 'Error: Invalid address.'; return 1; }
  if [ -n "$2" ]; then
    ports=($2)  # custom
  else
    port=$(_port "$1")
    ports=($(seq $port $((port + nport))))
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
  local host port ports address stat flags linux cmd
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
  linux=(-o StrictHostKeyChecking=no -p "${ports[0]}")
  if $_macos; then
    stat=$(eval "$cmd")
  else
    stat=$(command ssh "${linux[@]}" "$USER@localhost" "$cmd")
  fi
  echo "Exit status $stat for connection over ports: ${ports[*]:1}."
}

# Trigger ssh-agent if not already running and add the Github private key. Make sure
# to make private key passwordless for easy login. All we want is to avoid storing
# plaintext username/password in ~/.git-credentials, but free private key is fine.
# See: https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#platform-linux
# For AUTH_SOCK see: https://unix.stackexchange.com/a/90869/112647
ssh-init() {
  local path
  path=$HOME/.ssh/id_rsa_github
  if [ -f "$path" ]; then
    command ssh-agent | sed 's/^echo/#echo/' >"$SSH_ENV"
    chmod 600 "$SSH_ENV"
    source "$SSH_ENV" >/dev/null
    command ssh-add "$path" &>/dev/null  # add Github private key; assumes public key has been added to profile
  else
    echo "Warning: Github private SSH key '$path' is not available." && return 1
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
  local processes pids port=$1
  [ $# -ne 1 ] && echo "Usage: disconnect PORT" && return 1
  processes=$(lsof -i "tcp:$port" | grep ssh)
  pids=$(echo "$processes" | sed "s/^[ \t]*//" | tr -s ' ' | cut -d' ' -f2 | xargs)
  [ -z "$pids" ] && echo "Error: Connection over port \"$port\" not found." && return 1
  echo "$pids" | xargs kill  # kill the ssh processes
  echo "Processes $pids killed. Connections over port $port removed."
}

#-----------------------------------------------------------------------------#
# Copying utilities
#-----------------------------------------------------------------------------#
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
  echo "Args: ${*}"
  while [ $# -gt 0 ]; do
    if [[ "$1" =~ ^\- ]]; then
      flags+=("$1")  # flag arguments must be specified with equals
    elif [ -z "$forward" ]; then
      forward=$1; [[ "$forward" =~ ^[01]$ ]] || {
        echo "Error: Invalid forward address $forward."; return 1
      }
    elif [ $remote -eq 0 ] && [ -z "$address" ]; then
      address=$(_address "$1") || {
        echo "Error: Invalid remote address $1."; return 1
      }
    else
      paths+=("$1")  # the source and destination paths
    fi
    shift
  done
  if [ "$remote" -eq 1 ]; then  # handle ssh tunnel
    address=$USER@localhost  # use port tunnel for copying on remote server
    port=$(_port) || { echo "Error: Port unknown."; return 1; }
    flags+=(-e "ssh -o StrictHostKeyChecking=no -p $port")
  fi
  # Sanitize paths and execute
  [ ${#paths[@]} -lt 2 ] && {
    echo "Usage: _scp_bulk [FLAGS] SOURCE_PATH1 [SOURCE_PATH2 ...] DEST_PATH"
    return 1
  }
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
  local flags forward address path
  $_macos && forward=1 || forward=0
  flags=(--include={fig,vid,meet}'*/***' --exclude={,.}'*')
  [ $# -eq $forward ] || { echo "Error: Expected argument count $#."; return 1; }
  path=$(git rev-parse --show-toplevel)/  # assumes identical paths (note trailing slash is critical)
  _scp_bulk "${flags[@]}" "$forward" $@ "$path" "$path"  # address may expand to nothing
}

#-----------------------------------------------------------------------------
# REPLs and interactive servers
#-----------------------------------------------------------------------------
# Add jupyter kernels with custom profiles. Goal is to have all kernels managed
# by conda using nb_conda_kernels (see above). Installing julia using conda then
# running Pkg.add('IJulia') should create julia kernel also managed by conda.
# See: https://github.com/minrk/a2km
# See: https://stackoverflow.com/a/46370853/4970632
# See: https://stackoverflow.com/a/50294374/4970632
alias jupyter-kernels='jupyter kernelspec list'  # kernel.json files in directories
# a2km clone python3 python3-climopy && a2km add-argv python3-climopy -- --profile=climopy
# a2km clone python3 python3-proplot && a2km add-argv python3-proplot -- --profile=proplot

# Jupyter profile shorthands requiring custom kernels that launch ipykernel
# with a --profile argument... otherwise only the default profile is run and the
# 'jupyter --config=file' file is confusingly not used in the resulting ipython session.
alias jupyter-climopy='jupyter console --kernel=python3-climopy'
alias jupyter-proplot='jupyter console --kernel=python3-proplot'

# Ipython profile shorthands (see ipython_config.py in .ipython profile subfolders)
# For tests we automatically print output and increase verbosity
alias pytest='pytest -s -v'
alias ipython-climopy='ipython --profile=climopy'
alias ipython-proplot='ipython --profile=proplot'

# Julia utility
# Include paths in current directory and auto update modules
# Remember to include IJulia AxisArrays NamedArrays
_julia_start='push!(LOAD_PATH, "./"); using Revise'
alias julia="command julia -e '$_julia_start' -i -q --color=yes"

# Matlab utilitiy
# Load the startup script and skip the gui stuff
alias matlab="matlab -nodesktop -nosplash -r '$_matlab_start'"
_matlab_start='run("~/matfuncs/init.m")'

# NCL interactive environment
# Make sure that we encapsulate any other alias -- for example, on Macs,
# will prefix ncl by setting DYLD_LIBRARY_PATH, so want to keep that.
_dyld_ncl=$(alias ncl 2>/dev/null | cut -d= -f2- | cut -d\' -f2)
# shellcheck disable=2015
[ -n "$_dyld_ncl" ] && alias ncl="$_dyld_ncl -Q -n" || alias ncl='ncl -Q -n'

# R utility
# Note using --slave or --interactive makes quiting impossible. And ---always-readline
# prevents prompt from switching to default prompt but disables ctrl-d from exiting.
# alias R='rlwrap --always-readline -A -p"green" -R -S"R> " R -q --no-save'
alias r='command R -q --no-save'
alias R='command R -q --no-save'

# Perl -- hard to understand, but here it goes. The first args are passed to rlwrap
# (install with 'mamba install rlwrap'). The flags -A set ANSI-aware colors and
# -pgreen apply a green prompt. The next args are perl args. Flags -w print more
# warnings, -n is more obscure, and -E evaluates an expression -- say eval() prints
# result of $_ (default searching and pattern space, whatever that means), and $@ is
# set if eval string failed so the // checks for success, and if not prints error
# message. This is a build-your-own eval.
iperl() {  # see this answer: https://stackoverflow.com/a/22840242/4970632
  ! hash rlwrap &>/dev/null && echo "Error: Must install rlwrap." && return 1
  rlwrap -A -p"green" -S"perl> " perl -wnE'say eval()//$@'  # rlwrap stands for readline wrapper
}

# Set up jupyter lab with necessary port-forwarding connections
# Install nbstripout with 'pip install nbstripout', then add to global .gitattributes
# for automatic stripping during git differencing. No need for 'jupyter contrib
# nbextensions install --user', creates duplicate installation in ~/Library. Fix with
# 'jupyter contrib nbextensions uninstall --user' If you have issues where themes are
# just not changing in Chrome, open Developer tab with Cmd+Opt+I and you can
# right-click refresh for a hard reset, cache reset.
# See: https://github.com/Jupyter-contrib/jupyter_nbextensions_configurator/issues/25#issuecomment-287730514
# See: https://github.com/ipython-contrib/jupyter_contrib_nbextensions/issues/1529#issuecomment-1134250842
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
# NOTE: The PDF version requires xelatex. Try to use drop-in xelatex replacement
# tectonic for speed. Install with 'mamba install tectonic' and correspondingly update
# jupyter_nbconvert_config.py. See: https://github.com/jupyter/nbconvert/issues/808
# NOTE: The HTML version can only use the jupyter notebook toc2-style table of contents.
# Requires installing nbextensions and enabling extension in classic jupyter interface
# (see above and https://stackoverflow.com/a/63123831/4970632but but skip 'contrib
# install' step to avoid duplicate installations), then adding cell metadata
# "toc": {"number_sections": false, "sideBar": true} in jupyterlab notebook
# 'advanced tools' panel (see https://stackoverflow.com/a/59286150/4970632).
# TODO: Table of contents still *does not work* as of 2023-09-17. Previously had issues
# with nbconvert >= 6.0.0 and downgrading fixed things, but no longer possible due to
# dependencies. Tried template from issue pages, and template compiles, but with no
# table of contents. The nbextensions tab had some 'load errors'. Could continue there.
# See: https://github.com/ipython-contrib/jupyter_contrib_nbextensions/issues/1533#issuecomment-1195067419
# See: https://nbconvert.readthedocs.io/en/latest/customizing.html#adding-additional-template-paths
jupyter-convert() {
  # flags+=(--no-input)  # remove code (useful for huge files, but harder to understand)
  # flags+=(--no-prompt)  # remove prompt (possibly cleaner, but harder to understand)
  # flags+=(--TemplateExporter.extra_template_basedirs=$HOME/.jupyter)  # set in config
  local ext fmt zips base input output flags
  fmt=html  # 'html_toc' for table of contents
  ext=${fmt%_*}  # extension
  flags+=(--to "$fmt")
  flags+=(--template classic)  # 'lab' for no centering, 'custom' for failed toc fix
  flags+=(--ExtractOutputPreprocessor.enabled=False)  # embed figures in html file
  for input in "$@"; do
    base=$(abspath ${input%/*})  # default base directory
    [ -d "${base%/notebooks}/meetings" ] && base=${base%/notebooks}/meetings
    [ -r "$input" ] || { echo "Error: Notebook $input does not exist."; return 1; }
    [[ "$input" =~ .*\.ipynb ]] || { echo "Error: Invalid filename $input."; return 1; }
    output=${input%.ipynb}_$(date +%Y-%m-%d).$ext
    output=${output##*/}  # strip directory
    jupyter nbconvert "${flags[@]}" --output-dir "$base" --output "$output" "$input" || return 1
    zips=("${output/.${ext}/}"*)  # include _files subfolder
    if [ "${#zips[@]}" -gt 1 ] && pushd "$base"; then
      zip -r "${output/.${ext}/.zip}" "${zips[@]}"
      popd || continue
    fi
  done
}

# Refresh stale connections from macbook to server
# WARNING: Using pseudo-tty allocation, i.e. simulating active shell with
# -t flag, causes ssh command to mess up. Skip this flag.
jupyter-connect() {
  local cmd ports
  cmd="ps -u | grep jupyter- | tr ' ' '\n' | grep -- --port | cut -d= -f2 | xargs"
  if $_macos; then  # find ports for existing notebooks
    [ $# -eq 1 ] || { echo "Error: Must input server."; return 1; }
    server=$1
    ports=$(command ssh -o StrictHostKeyChecking=no "$server" "$cmd") \
      || { echo "Error: Failed to get list of ports."; return 1; }
  else
    ports=$(eval "$cmd")
  fi
  [ -n "$ports" ] || { echo "Error: No active jupyter notebooks found."; return 1; }
  echo "Connecting to jupyter notebook(s) over port(s) $ports."
  if $_macos; then
    _ssh "$server" "$ports"
  else
    _ssh "$ports"
  fi
}

# Change the jupytext kernel for all notebooks
# NOTE: To get jupytext conversion and .py file reading inside jupyter noteboks need
# the extensions: https://github.com/mwouts/jupytext/tree/main/packages/labextension
# Install jupyter notebook and jupyter lab extensions with mamba install jupytext;
# 'jupyter nbextension install --py jupytext --user; jupyter nbextension enable
# --py jupytext --user; jupyter labextension install jupyterlab-jupytext'.
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

# Professional website server
# Use 'brew install ruby-bundler nodejs' then 'bundle install' first
# See README.md in website directory
# NOTE: CSS variables are in _sass/_variables. Below does live updates (watch)
# and incrementally builds website (incremental) as files are edited.
# Ignore standard error because of annoying deprecation warnings:
# https://github.com/academicpages/academicpages.github.io/issues/54
# Website template idea:
# http://briancaffey.github.io/2016/03/14/ipynb-with-jekyll.html
# Another template idea:
# http://www.leeclemmer.com/2017/07/04/how-to-publish-jupyter-notebooks-to-your-jekyll-static-website.html
# For fixing tiny font size in code cells see:
# http://purplediane.github.io/jekyll/2016/04/10/syntax-hightlighting-in-jekyll.html
_jekyll_flags="--incremental --watch --config '_config.yml,_config.dev.yml'"
alias server="python -m http.server"
alias jekyll="bundle exec jekyll serve $_jekyll_flags 2>/dev/null"  # ignore deprecations

#-----------------------------------------------------------------------------
# Dataset utilities
#-----------------------------------------------------------------------------
# Code parsing tools
namelist() {  # list all namelist parameters
  local file files
  files=("$@")
  [ $# -eq 0 ] && files=(input.nml)
  for file in "${files[@]}"; do
    echo "Params in namelist '$file':"
    cut -d= -f1 -s "$file" | grep -v '!' | xargs
  done
}
graphicspath() {  # list all graphics paths (used in autoload tex.vim)
  awk -v RS='[^\n]*{' '
    inside && /}/ {path=$0; if(init) inside=0} {init=0}
    inside && /(\n|^)}/ {inside=0}
    path {sub(/}.*/, "}", path); print "{" path}
    RT ~ /graphicspath/ {init=1; inside=1}
    /document}/ {exit} {path=""}
  ' "$@"  # RS is the 'record separator' and RT is '*this* record separator'
}

# Extract generalized files
# Shell actually passes *already expanded* glob pattern when you call it as
# argument to a function; so, need to cat all input arguments with @ into list
extract() {
  for name in "$@"; do
    if [ -f "$name" ]; then
      case "$name" in
        *.tar.bz2) tar xvjf "$name" ;;
        *.tar.xz) tar xf "$name" ;;
        *.tar.gz) tar xvzf "$name" ;;
        *.bz2) bunzip2 "$name" ;;
        *.rar) unrar x "$name" ;;
        *.gz) gunzip "$name" ;;
        *.tar) tar xvf "$name" ;;
        *.tbz2) tar xvjf "$name" ;;
        *.tgz) tar xvzf "$name" ;;
        *.zip) unzip "$name" ;;
        *.Z) uncompress "$name" ;;
        *.7z) 7z x "$name" ;;
        *) echo "Don't know how to extract '$name'..." ;;
      esac
      echo "'$name' was extracted."
    else
      echo "'$name' is not a valid file!"
    fi
  done
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
  # Show just the variable info (and linebreak before global attributes)
  # ncdump -h "$1" | sed '/^$/q' | sed '1,1d;$d'
  local file
  [ $# -lt 1 ] && echo "Usage: ncinfo FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | sed '1,1d;$d'
  done
}
ncdims() {
  # Show just the dimension header.
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
  # Space makes sure it isn't another variable that has trailing-substring identical
  # to this variable, -A prints TRAILING lines starting from FIRST match, -B means
  # prinx x PRECEDING lines starting from LAST match.
  local file
  [ $# -lt 1 ] && echo "Usage: ncvars FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | grep -A100 "^variables:$" | sed '/^$/q' | \
      sed $'s/^\t//g' | grep -v "^$" | grep -v "^variables:$"
  done
}
ncglobals() {
  # Show just the global attributes.
  local file
  [ $# -lt 1 ] && echo "Usage: ncglobals FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | grep -A100 ^//
  done
}

# Listing stuff
nclist() {
  # Only get text between variables: and linebreak before global attributes
  # note variables don't always have dimensions (i.e. constants). For constants
  # will look like " double var ;" instead of " double var(x,y) ;"
  local file
  [ $# -lt 1 ] && echo "Usage: nclist FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | sed -n '/variables:/,$p' | sed '/^$/q' \
      | grep -v '[:=]' | cut -d';' -f1 | cut -d'(' -f1 | sed 's/ *$//g;s/.* //g' \
      | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
  done
}
ncdimlist() {
  # Get list of dimensions.
  local file
  [ $# -lt 1 ] && echo "Usage: ncdimlist FILE" && return 1
  for file in "$@"; do
    echo "File: $file"
    command ncdump -h "$file" | sed -n '/dimensions:/,$p' | sed '/variables:/q' \
      | cut -d'=' -f1 -s | xargs | tr ' ' '\n' | grep -v '[{}]' | sort
  done
}
ncvarlist() {
  # Only get text between variables: and linebreak before global attributes.
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
  # As above but just for one variable.
  # See: https://docs.unidata.ucar.edu/nug/current/_c_d_l.html#cdl_data_types).
  # See: https://docs.unidata.ucar.edu/nug/current/md_types.html
  local file types
  types='(char|byte|short|ushort|int|uint|long|int64|uint64|float|real|double)'
  [ $# -lt 2 ] && echo "Usage: ncvarinfo VAR FILE" && return 1
  for file in "${@:2}"; do
    echo "File: $file"
    command ncdump -h "$file" \
      | grep -E -A100 "$types $1(\\(.*\\)| ;)" | grep -E -B100 $'\t\t'"$1:" \
      | sed "s/$1://g" | sed $'s/^\t//g'
  done
}
ncvardump() {
  # Dump variable contents (first argument) from file (second argument), using grep
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
  # Print a summary table of the data at each level for "sanity checking"
  # just tests one timestep slice at every level; the tr -s ' ' trims multiple
  # whitespace to single and the column command re-aligns columns after filtering.
  local file
  [ $# -lt 2 ] && echo "Usage: ncvartable VAR FILE" && return 1
  for file in "${@:2}"; do
    echo "File: $file"
    cdo -s infon -seltimestep,1 -selname,"$1" "$file" 2>/dev/null \
      | tr -s ' ' | cut -d ' ' -f 6,8,10-12 | column -t
  done
}
ncvardetails() {
  # As above but show everything. Note we show every column instead of hiding stuff.
  local file
  [ $# -lt 2 ] && echo "Usage: ncvardetails VAR FILE" && return 1
  for file in "${@:2}"; do
    echo "File: $file"
    cdo -s infon -seltimestep,1 -selname,"$1" "$file" 2>/dev/null \
      | tr -s ' ' | column -t | less
    done
}

#-----------------------------------------------------------------------------
# PDF and image utilities
#-----------------------------------------------------------------------------
# Converting between things
# Flatten gets rid of transparency/renders it against white background, and
# the units/density specify a <N>dpi resulting bitmap file. Another option
# is "-background white -alpha remove", try this. Note imagemagick does *not* handle
# vector formats; will rasterize output image and embed in a pdf, so cannot flatten
# transparent components with convert -flatten in.pdf out.pdf. Note the PNAS journal
# says 1000-1200dpi recommended for line art images and stuff with text.
pdf2text() {  # extracting text (including appropriate newlines, etc.) from file
  # See: https://stackoverflow.com/a/52184549/4970632
  # See: https://pypi.org/project/pdfminer/
  # Note command 'pdf2text.py' was renamed to bin file.
  command pdf2txt "$@"
}
gif2png() {  # often needed because LaTeX can't read gif files
  for f in "$@"; do
    ! [[ "$f" =~ .gif$ ]] \
      && echo "Warning: Skipping ${f##*/} (must be .gif)" && continue
    echo "Converting ${f##*/}..."
    convert "$f" "${f%.gif}.png"
  done
}
pdf2png() {
  for f in "$@"; do
    ! [[ "$f" =~ .pdf$ ]] \
      && echo "Warning: Skipping ${f##*/} (must be .pdf)" && continue
    echo "Converting ${f##*/}..."
    convert -flatten \
      -units PixelsPerInch -density 1200 -background white "$f" "${f%.pdf}.png"
  done
}
svg2png() {
  # See: https://stackoverflow.com/a/50300526/4970632 (python is faster and convert 'dpi' is ignored)
  for f in "$@"; do
    ! [[ "$f" =~ .svg$ ]] \
      && echo "Warning: Skipping ${f##*/} (must be .svg)" && continue
    echo "Converting ${f##*/}..."
    python -c "
      import cairosvg
      cairosvg.svg2png(
        url='$f', write_to='${f%.svg}.png', scale=3, background_color='white'
      )"
    # && convert -flatten -units PixelsPerInch -density 1200 -background white "$f" "${f%.svg}.png"
  done
}
webm2mp4() {
  for f in "$@"; do
    # See: https://stackoverflow.com/a/49379904/4970632
    ! [[ "$f" =~ .webm$ ]] \
      && echo "Warning: Skipping ${f##*/} (must be .webm)" && continue
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
    ! [[ "$f" =~ .pdf$ ]] \
      && echo "Warning: Skipping ${f##*/} (must be .pdf)" && continue
    [[ "$f" =~ _flat ]] \
      && echo "Warning: Skipping ${f##*/} (has 'flat' in name)" && continue
    echo "Converting $f..." && pdf2ps "$f" - | ps2pdf - "${f%.pdf}_flat.pdf"
  done
}
png2flat() {
  # See: https://stackoverflow.com/questions/46467523/how-to-change-picture-background-color-using-imagemagick
  for f in "$@"; do
    ! [[ "$f" =~ .png$ ]] \
      && echo "Warning: Skipping ${f##*/} (must be .png)" && continue
    [[ "$f" =~ _flat ]] \
      && echo "Warning: Skipping ${f##*/} (has 'flat' in name)" && continue
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
    ! [[ "$f" =~ .otf$ ]] \
      && echo "Warning: Skipping ${f##*/} (must be .otf)" && continue
    echo "Converting ${f##*/}..."
    fontforge -c "
      import fontforge
      from sys import argv
      f = fontforge.open(argv[1])
      f.generate(argv[2])
    " "${f%.*}.otf" "${f%.*}.ttf"
  done
}
ttf2otf() {
  for f in "$@"; do
    ! [[ "$f" =~ .ttf$ ]] \
      && echo "Warning: Skipping ${f##*/} (must be .ttf)" && continue
    fontforge -c "
      import fontforge
      from sys import argv
      f = fontforge.open(argv[1])
      f.generate(argv[2])
    " "${f%.*}.ttf" "${f%.*}.otf"
  done
}

# Rudimentary wordcount with detex
# The -e flag ignores certain environments (e.g. abstract environment)
wctex() {
  local detexed
  detexed=$( \
    detex -e 'abstract,addendum,tabular,align,equation,align*,equation*' "$1" \
    | grep -v .pdf | grep -v 'fig[0-9]' \
  )
  echo "$detexed" | xargs  # print result in one giant line
  echo "$detexed" | wc -w  # get word count
}

# This is *the end* of all function and alias declarations
echo 'done'

#-----------------------------------------------------------------------------
# FZF fuzzy file completion tool
#-----------------------------------------------------------------------------
# Default fzf flags (see man page for more info, e.g. --bind and --select-1)
# Inline info puts the number line thing on same line as text. Bind slash to accept
# so behavior matches shell completion behavior. Enforce terminal background default
# color using -1 below. ANSI codes: https://stackoverflow.com/a/33206814/4970632
# NOTE: General idea is <F1> and <F2> i.e. <Ctrl-,> and <Ctrl-.> should be tab-like
# for command mode cycling. See top of .vimrc for details.
_fzf_options=" \
--ansi --color=bg:-1,bg+:-1 --layout=default --exit-0 --inline-info --height=6 \
--bind=ctrl-k:up,ctrl-j:down,btab:clear-query,tab:accept,f1:clear-query,f2:accept,\
f3:preview-page-up,f4:preview-page-down,ctrl-g:jump,ctrl-s:toggle,ctrl-a:toggle-all,\
ctrl-u:half-page-up,ctrl-d:half-page-down,ctrl-b:page-up,ctrl-f:page-down,\
ctrl-r:clear-query,ctrl-q:cancel,ctrl-w:cancel,ctrl-e:cancel\
"  # critical to export so used by vim

# Defualt fzf find commands. The compgen ones were addd by fork, others are native.
# Adapted defaults from defaultCommand in .fzf/src/constants.go and key-bindings.bash
# NOTE: Only apply universal 'ignore' file to default command used by vim fzf file
# searching utility. Exclude common external packages for e.g. :Files.
_fzf_prune_names=$(ignores 1 plugged packages | sed 's/(/\\(/g;s/)/\\)/g')
_fzf_prune_bases=" \
\\( -fstype devfs -o -fstype devtmpfs -o -fstype proc -o -fstype sysfs \\) -prune -o \
"

# Run installation script; similar to the above one
# if [ -f ~/.fzf.bash ] && ! [[ "$PATH" =~ fzf ]]; then
if [ "${FZF_SKIP:-0}" == 0 ] && [ -f ~/.fzf.bash ]; then
  # Apply default fzf marks options
  # Download repo with 'git clone https://github.com/lukelbd/fzf-marks.git .fzf-marks'
  # then run 'push .fzf-marks && git switch config-edits' fur custom configuration.
  # NOTE: The default .fzf-marks storage file conflicts with the repo name we use
  # so have changed this on branch. See https://github.com/urbainvaes/fzf-marks
  _setup_message 'Enabling fzf'
  # shellcheck disable=2034
  {
    FZF_MARKS_FILE=${HOME}/.fzf.marks
    FZF_MARKS_COMMAND='fzf --height 40% --reverse'
    FZF_MARKS_JUMP="\C-g"
    FZF_MARKS_COLOR_LHS=39
    FZF_MARKS_COLOR_RHS=36
    FZF_MARKS_COLOR_COLON=33
    FZF_MARKS_NO_COLORS=0
    FZF_MARKS_KEEP_ORDER=0
  }

  # Apply default fzf options
  # Download repo with 'git clone https://github.com/lukelbd/fzf-marks.git .fzf'
  # then run 'pushd .fzf && git switch completion-edits' for custom completion behavior
  # NOTE: To make completion trigger after single tab press, must set to literal empty
  # string rather than leaving the variable unset (or else it uses default).
  # shellcheck disable=2034
  {  # first option requires export
    export FZF_DEFAULT_OPTS=$_fzf_options
    FZF_ALT_C_OPTS=$_fzf_options
    FZF_CTRL_T_OPTS=$_fzf_options
    FZF_COMPLETION_OPTS=$_fzf_options
    FZF_COMPLETION_TRIGGER=''
  }

  # Apply default fzf commands
  # NOTE: The compgen commands were added in completion-edits fzf branch
  # shellcheck disable=2034
  {  # first option requires export
    export FZF_DEFAULT_COMMAND=" \
      set -o pipefail; command find . -mindepth 1 $_fzf_prune_bases $_fzf_prune_names \
      -type f -print -o -type l -print 2>/dev/null | cut -b3- \
    "
    FZF_ALT_C_COMMAND=" \
      command find -L . -mindepth 1 $_fzf_prune_bases \
      -type d -print 2>/dev/null | cut -b3- \
    "  # recursively search directories and cd into them
    FZF_CTRL_T_COMMAND=" \
      command find -L . -mindepth 1 $_fzf_prune_bases \
      \\( -type d -o -type f -o -type l \\) -print 2>/dev/null | cut -b3- \
    "  # recursively search files
    FZF_COMPGEN_DIR_COMMAND=" \
      command find -L \"\$1\" -maxdepth 1 -mindepth 1 $_fzf_prune_bases \
      -type d -print 2>/dev/null | sed 's@^.*/@@' \
    "  # complete directories with tab
    FZF_COMPGEN_PATH_COMMAND=" \
      command find -L \"\$1\" -maxdepth 1 -mindepth 1 $_fzf_prune_bases \
      \\( -type d -o -type f -o -type l \\) -print 2>/dev/null | sed 's@^.*/@@' \
    "  # complete paths with tab
  }

  # Source bash file
  # NOTE: Previously also tried to override completion here but no longer.
  # See: https://stackoverflow.com/a/42085887/4970632
  # See: https://unix.stackexchange.com/a/217916/112647
  complete -r  # reset first
  source ~/.fzf.bash
  alias drop=dmark  # 'delete' mark (for consistency with 'jump')
  alias marks=pmark  # 'paste' or 'print' mark (for consistency with 'marks')
  _fzf_marks=~/.fzf-marks/fzf-marks.plugin.bash
  [ -f "$_fzf_marks" ] && source "$_fzf_marks"
  echo 'done'
fi

#-----------------------------------------------------------------------------
# Conda stuff
#-----------------------------------------------------------------------------
# Add conda base
# NOTE: Must save brew path before setup (conflicts with conda; try 'brew doctor')
# See: https://github.com/conda-forge/miniforge
alias brew="PATH=\"$PATH\" brew"
if [ -d "$HOME/mambaforge" ]; then
  _conda=$HOME/mambaforge
elif [ -d "$HOME/miniforge" ]; then
  _conda=$HOME/miniforge
else
  unset _conda
fi

# Pip install static copy of specific branch
# See: https://stackoverflow.com/a/27134362/4970632
# NOTE: Resulting install will not be editable. But could be useful for awaiting
# PRs or new versions after submitting feature to community project.
pip-branch() {
  [ $# -eq 2 ] && echo "Usage: pip-branch PACKAGE BRANCH" && return 1
  [ -d "$1" ] || { echo "Error: Package path '$1' not found."; return 1; }
  pip install --editable git+file://"$1"@"$2"
}

# List available packages
# NOTE: This takes really long even with mamba
mamba-avail() {
  local version versions
  [ $# -ne 1 ] && echo "Usage: avail PACKAGE" && return 1
  echo "Package:            $1"
  version=$(mamba list "^$1$" 2>/dev/null)
  [[ "$version" =~ "$1" ]] && version=$( \
    echo "$version" | grep "$1" | awk 'NR == 1 {print $2}' \
  ) || version="N/A"  # get N/A if not installed
  echo "Current version:    $version"
  versions=$( \
    mamba search -c conda-forge "$1" 2>/dev/null \
  ) || { echo "Error: Package \"$1\" not found."; return 1; }
  versions=$( \
    echo "$versions" | grep "$1" | awk '!seen[$2]++ {print $2}' | tac | sort | xargs \
  )
  echo "Available versions: $versions"
}

# Fucntions to backup and restore conda environments. This is useful when conda breaks
# due to usage errors or issues with permissions after a crash and backblaze restore.
# NOTE: This can also be used to sync across macbooks. Just clone 'dotfiles' there.
mamba-backup() {
  local env dest
  dest=$HOME/dotfiles/
  [ -d "$dest" ] || { echo " Error: Cannot find icloud directory $dest."; return 1; }
  [ -d "$dest/envs" ] || mkdir "$dest/envs"
  for env in $(mamba env list | cut -d" " -f1); do
    [[ ${env:0:1} == "#" ]] && continue
    echo "Creating file: $dest/envs/${env}.yml"
    mamba env export -n $env > "$dest/envs/${env}.yml"
  done
}
mamba-restore() {
  local envs path src
  src=$HOME/dotfiles/
  [ -d "$src" ] || { echo " Error: Cannot find icloud directory $src."; return 1; }
  envs=($(mamba env list | cut -d' ' -f1))
  for path in "$src"/*.yml; do
    name=${path##*/}
    name=${name%.yml}
    # shellcheck disable=2076
    if [[ " ${envs[*]} " =~ " $name " ]]; then
      echo "Updating environment: $name"
      mamba env update -n "$name" --file "$path"
    else
      echo "Creating environment: $name"
      mamba env create -n "$name" --file "$path"
    fi
  done
}

# Optionally initiate conda (generate this code with 'mamba init')
# WARNING: Making conda environments work with jupyter is complicated. Have
# to remove stuff from ipykernel and then install them manually.
# See: https://stackoverflow.com/a/54985829/4970632
# See: https://stackoverflow.com/a/48591320/4970632
# See: https://medium.com/@nrk25693/how-to-add-your-conda-environment-to-your-jupyter-notebook-in-just-4-steps-abeab8b8d084
if [ "${CONDA_SKIP:-0}" == 0 ] && [ -n "$_conda" ] && ! [[ "$PATH" =~ conda|mamba ]]; then
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
  mamba activate base  # calls '__conda_activate activate' which runs the
  echo 'done' # commands returned by '__conda_exe shell.posix activate'
fi

#-----------------------------------------------------------------------------
# Shell integration and session management
#-----------------------------------------------------------------------------
# Enable shell integration and show inline figures with fixed 300dpi
# Pane badges: https://iterm2.com/documentation-badges.html
# Prompt markers: https://stackoverflow.com/a/38913948/4970632
# Use `printf "\e]1337;SetBadgeFormat=%s\a" $(echo -n "\(path)" | base64)` to print
# current directory when debugging: https://gitlab.com/gnachman/iterm2/-/issues/11073
if [ "${ITERM_SHELL_INTEGRATION_SKIP:-0}" == 0 ] \
  && [ -z "$ITERM_SHELL_INTEGRATION_INSTALLED" ] \
  && [ -r ~/.iterm2_shell_integration.bash ] \
  && [ -z "$VIMRUNTIME" ]; then
  _setup_message 'Enabling shell integration'
  source ~/.iterm2_shell_integration.bash
  unalias imgcat imgls
  _imgshow() {
    local cmd temp files
    cmd="$1"
    files=("${@:2}")  # start at second arg
    for file in "${files[@]}"; do
      if [ "${file##*.}" == pdf ]; then
        temp=./tmp.${file%.*}.png  # convert to png
        convert -flatten -units PixelsPerInch -density 300 -background white "$file" "$temp"
      else
        temp=./tmp.${file}
        convert -flatten "$file" "$temp"
      fi
      ~/.iterm2/$cmd "$temp"
      rm "$temp"
    done
  }
  imgcat() { _imshow imgcat "$@"; }
  imgls() { _imshow imgls "$@"; }
  echo 'done'
fi

# Change directory based on session title
_title_cwd() {
  local _ sub dir title
  title=$(_title_get)
  $_macos && [ -n "$title" ] || return 1
  for sub in '' research shared school software; do
    while read -r -d '' _ dir; do  # 'seconds.fraction' 'path'
      cd "$dir" && break
    done < <(find "$HOME/$sub" \
      -maxdepth 1 -name "*${title%%-*}*" \
      -type d -printf "%T@ %p\0" \
      | sort -z -k1,1gr)  # reverse floating
  done
}

# Get session title from path
_title_get() {
  local idx title
  idx=${TERM_SESSION_ID%%t*}
  idx=${idx#w}; idx=${idx:-0}
  if [ -r "$_title_path" ]; then
    if $_macos; then
      title=$(grep "^$idx:.*$" "$_title_path" 2>/dev/null | cut -d: -f2-)
    else
      title=$(cat "$_title_path")  # only text in file, is this current session's title
    fi
  fi
  echo "$title" | sed $'s/^[ \t]*//;s/[ \t]*$//'
}

# Set session title from user input or prompt
_title_set() {
  local idx title
  $_macos && [ -n "$TERM_SESSION_ID" ] || return 1
  idx=${TERM_SESSION_ID%%t*}
  idx=${idx#w}; idx=${idx:-0}
  [ $# -gt 0 ] && title="$*" || read -r -p "Title (window $idx):" title
  title=${title:-window $idx}
  [ -e "$_title_path" ] || touch "$_title_path"
  sed -i '/^'"$idx"':.*$/d' "$_title_path"  # remove existing title from file
  echo "$idx: $title" >> "$_title_path"  # add to file
}
alias title='_title_set'  # easier for user

# Update the iterm2 window title
# See: https://superuser.com/a/560393/506762
_prompt_append() {  # input argument should be new command
  PROMPT_COMMAND=$(echo "$PROMPT_COMMAND; $1" | sed 's/;[ \t]*;/;/g;s/^[ \t]*;//g')
}
_prompt_title() {
  $_macos || return 1; local title=$(_title_get)
  [ -z "$title" ] && _title_set && title=$(_title_get)
  [ -n "$title" ] && echo -ne "\033]0;$title\007"  # re-assert title
}
if $_macos; then
  _title_path=$HOME/.title
  PROMPT_COMMAND=${PROMPT_COMMAND/_title_get/_prompt_title}
  [[ "$PROMPT_COMMAND" =~ _prompt_title ]] || _prompt_append _prompt_title
  [[ "$TERM_SESSION_ID" =~ w?t?p0: ]] && _prompt_title
fi

# Source other commands and print message
# NOTE: This also fixes bug from restarting iterm sessions
[ -n "$VIMRUNTIME" ] \
  && unset PROMPT_COMMAND
$_macos && [ -z "$OLDPWD" ] && [ "$PWD" == "$HOME" ] \
  && _title_cwd
$_macos && [ -r $HOME/mackup/shell.sh ] \
  && source $HOME/mackup/shell.sh
[ -z "$_bashrc_loaded" ] && [[ "$(hostname)" =~ "$HOSTNAME" ]] \
  && command curl https://icanhazdadjoke.com/ 2>/dev/null && echo
_bashrc_loaded=true
