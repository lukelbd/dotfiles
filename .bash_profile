# Dummy file; keep startup preferences in .bashrc
# * On most Linux/Unix machines, bashrc is bypassed, and only runs if they
#   are logged into a desktop already, then open up a terminal.
# * macOS "runs a login shell every time", so bash_profile always runs. See:
#   http://apple.stackexchange.com/questions/51036/what-is-the-difference-between-bash-profile-and-bashrc
# * On cheyenne supercomputer, would load bashrc *and* bash_profile, so need
#   this backstop to prevent multiple loading.
if [ -f "$HOME/.bashrc" ] && [ -z "$_bashrc_loaded" ]; then
  . "$HOME/.bashrc"
fi

