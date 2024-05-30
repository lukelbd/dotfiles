# Source .bashrc configuration
# shellcheck disable=2154
# * Most Linux/Unix machines bypass .bashrc and only run if already
#   logged into a desktop, then open up terminal.
# * Mac runs a login shell every time, so bash_profile always runs.
#   See: http://apple.stackexchange.com/questions/51036/what-is-the-difference-between-bash-profile-and-bashrc
# * Cheyenne supercomputer would load bashrc *and* bash_profile so need
#   below backstop to prevent multiple loading.
if [ -f "$HOME/.bashrc" ] && [ -z "$_bashrc_loaded" ]; then
  . "$HOME/.bashrc"
fi
