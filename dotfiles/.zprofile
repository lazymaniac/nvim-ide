
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

for directory in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin"; do
  [[ -d "$directory" ]] && export PATH="$PATH:$directory"
done

ASDF_HOME="${ASDF_DATA_DIR:-$HOME/.asdf}"
[[ -d "$ASDF_HOME/shims" ]] && export PATH="$ASDF_HOME/shims:$PATH"
[[ -r "$ASDF_HOME/plugins/java/set-java-home.zsh" ]] && . "$ASDF_HOME/plugins/java/set-java-home.zsh"
