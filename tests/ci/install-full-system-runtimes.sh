#!/usr/bin/env bash
set -euo pipefail

: "${RUNNER_OS:?RUNNER_OS must be set by GitHub Actions}"
: "${RUNNER_TEMP:?RUNNER_TEMP must be set by GitHub Actions}"
: "${RUNNER_TOOL_CACHE:?RUNNER_TOOL_CACHE must be set by GitHub Actions}"
: "${GITHUB_PATH:?GITHUB_PATH must be set by GitHub Actions}"

KOTLIN_VERSION=2.4.10

append_path() {
  local path=$1
  printf '%s\n' "$path" >> "$GITHUB_PATH"
  export PATH="$path:$PATH"
}

install_kotlin() {
  local install_root="$RUNNER_TOOL_CACHE/kotlin/$KOTLIN_VERSION"
  if [[ ! -x "$install_root/kotlinc/bin/kotlinc" ]]; then
    local staging
    staging="$(mktemp -d "$RUNNER_TEMP/kotlin.XXXXXX")"
    curl --fail --location --retry 4 --silent --show-error \
      "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" \
      --output "$staging/kotlin-compiler-${KOTLIN_VERSION}.zip"
    unzip -q "$staging/kotlin-compiler-${KOTLIN_VERSION}.zip" -d "$staging/unpacked"
    mkdir -p "$(dirname "$install_root")"
    if [[ -e "$install_root" ]]; then
      rm -rf "$install_root"
    fi
    mv "$staging/unpacked" "$install_root"
    rm -rf "$staging"
  fi
  append_path "$install_root/kotlinc/bin"
}

install_ghcup() {
  if ! command -v ghcup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 --fail --location --retry 4 --silent --show-error \
      https://get-ghcup.haskell.org | env \
      BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
      BOOTSTRAP_HASKELL_MINIMAL=1 \
      BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 \
      sh
  fi
  append_path "$HOME/.ghcup/bin"
}

install_common_packages() {
  python3 -m pip install --disable-pip-version-check --no-input ansible-core
  gem install bundler --no-document
  npm install --global tree-sitter-cli@0.26.3
}

case "$RUNNER_OS" in
  Linux)
    sudo apt-get update
    sudo env DEBIAN_FRONTEND=noninteractive apt-get install --yes \
      bash \
      build-essential \
      cmake \
      curl \
      git \
      gzip \
      libffi-dev \
      libgmp-dev \
      libncurses-dev \
      libtinfo-dev \
      lua5.4 \
      luarocks \
      maven \
      ninja-build \
      podman \
      postgresql-client \
      ripgrep \
      ruby-dev \
      tar \
      unzip
    if ! command -v lua >/dev/null 2>&1; then
      sudo ln -s "$(command -v lua5.4)" /usr/local/bin/lua
    fi
    ;;
  macOS)
    export HOMEBREW_NO_AUTO_UPDATE=1
    brew install \
      bash \
      cmake \
      git \
      gzip \
      libpq \
      lua \
      luarocks \
      maven \
      ninja \
      podman \
      ripgrep
    append_path "$(brew --prefix libpq)/bin"
    if [[ "$(uname -m)" == arm64 ]] && ! arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
      sudo softwareupdate --install-rosetta --agree-to-license
    fi
    ;;
  *)
    printf 'Unsupported GitHub runner OS: %s\n' "$RUNNER_OS" >&2
    exit 1
    ;;
esac

install_common_packages
install_kotlin
install_ghcup
