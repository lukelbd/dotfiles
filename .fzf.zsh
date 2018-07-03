# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/ldavis/dotfiles/.fzf/bin* ]]; then
  export PATH="$PATH:/Users/ldavis/dotfiles/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/ldavis/dotfiles/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/Users/ldavis/dotfiles/.fzf/shell/key-bindings.zsh"

