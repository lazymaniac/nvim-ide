
eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="$PATH:/Users/sebastian/.local/bin"

export PATH="$PATH:/Users/sebastian/.cargo/bin"

export PATH="$PATH:/Users/sebastian/go/bin"

export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

. ~/.asdf/plugins/java/set-java-home.zsh
