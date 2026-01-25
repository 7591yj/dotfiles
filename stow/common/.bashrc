#
# ~/.bashrc
#

[[ $- == *i* ]] && source -- /usr/share/blesh/ble.sh --attach=none
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='eza --color=auto'
alias ll='eza -al --color=auto'
alias grep='grep --color=auto'
alias lg='lazygit'
PS1='[\u@\h \W]\$ '

eval "$(zoxide init bash)"
eval "$(starship init bash)"

fastfetch

[[ ! ${BLE_VERSION-} ]] || ble-attach
