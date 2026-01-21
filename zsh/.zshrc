eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

alias ls='eza'
alias ll='eza -al'
alias lg='lazygit'

fastfetch

