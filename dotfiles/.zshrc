if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [[ ! -d "$ZINIT_HOME" ]] && command -v git >/dev/null 2>&1; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
[[ -r "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"

if command -v zinit >/dev/null 2>&1; then
  zinit ice depth=1

  # Add in zsh plugins
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light Aloxaf/fzf-tab

  # Add in snippets
  zinit snippet OMZL::git.zsh
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::aws
  zinit snippet OMZP::kubectl
  zinit snippet OMZP::kubectx
  zinit snippet OMZP::command-not-found

  zinit cdreplay -q
fi

#asdf completions
fpath=(${ASDF_DATA_DIR:-$HOME/.asdf}/completions $fpath)

# Load completions
autoload -Uz compinit && compinit

if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]] && command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init zsh)"
fi

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -alG'
else
  alias ls='ls -al --color=auto'
fi
alias vim='nvim'
alias c='clear'

# Shell integrations
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"

for directory in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin"; do
  [[ -d "$directory" ]] && export PATH="$PATH:$directory"
done

ASDF_HOME="${ASDF_DATA_DIR:-$HOME/.asdf}"
[[ -d "$ASDF_HOME/shims" ]] && export PATH="$ASDF_HOME/shims:$PATH"
[[ -r "$ASDF_HOME/plugins/java/set-java-home.zsh" ]] && . "$ASDF_HOME/plugins/java/set-java-home.zsh"
