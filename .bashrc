eval `opam config env`

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
alias ls="ls -GFlash"
alias ranger="source ranger"

export EDITOR=nvim

export PROMPT_COMMAND='echo -ne "\033];${PWD##*/}\007"'

tabTitle() { echo -ne "\033]0;"$*"\007"; }
winTitle() { echo -ne "\033]2;"$*"\007"; }
