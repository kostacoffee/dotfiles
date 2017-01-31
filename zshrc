# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

export VISUAL=nvim
export EDITOR="$VISUAL"

alias vim=nvim
alias ssh='TERM=xterm-256color ssh'

export TERM='xterm-256color-italic'
