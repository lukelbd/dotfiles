## Personal bash_profile, run for login shells (when user logs in).
## On most Linux/Unix machines, this means bash_profile is bypassed and
## only .bashrc run if they have already logged into a desktop to open a
## terminal; however macOS "runs a login shell every time". 
## See:
## http://apple.stackexchange.com/questions/51036/what-is-the-difference-between-bash-profile-and-bashrc

# Load .bashrc
if [ -f $HOME/.bashrc ]; then
  . ~/.bashrc
fi

# ...and that's it. This will keep startup properties
# in ONE FILE, loaded no matter what
