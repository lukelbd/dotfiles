# Dummy file, keep startup preferences in .bashrc
# * For most Linux/Unix machines, bashrc is bypassed, and only runs if they
#   are logged into a desktop already, then open up a terminal.
# * Mac runs a login shell every time, so bash_profile always runs.
#   See: http://apple.stackexchange.com/questions/51036/what-is-the-difference-between-bash-profile-and-bashrc
# * For cheyenne supercomputer, would load bashrc *and* bash_profile, so need
#   this backstop to prevent multiple loading.
# shellcheck disable=2154
if [ -f "$HOME/.bashrc" ] && [ -z "$_bashrc_loaded" ]; then
  . "$HOME/.bashrc"
fi
