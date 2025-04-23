# NV-IDE personalized mix of available NVIM distros

<!--toc:start-->
- [NV-IDE personalized mix of available NVIM distros](#nv-ide-personalized-mix-of-available-nvim-distros)
  - [Introduction](#introduction)
  - [Installation](#installation)
    - [System Packages](#system-packages)
      - [Config paths](#config-paths)
      - [Install script](#install-script)
      - [Post Installation](#post-installation)
<!--toc:end-->

## Introduction

- NVIM distribution created to support my workflows. From java, go, rust to
  jupyter notebooks.

## Installation

> **NOTE**
> Backup your previous configuration (if any exists)

### System Packages
MacOS setup script:
```bash
#!/bin/bash

# install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Xcode Development Tools
xcode-select --install

git clone git@github.com:lazymaniac/nvim-ide.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim

cp ~/.config/nvim/dotfiles/.zshrc ~/
source ~/.zshrc

brew install --cask iterm2
brew install nvim lazygit lazydocker fzf luajit ripgrep dua-cli zoxide bat eza btop fd fastfetch oh-my-posh bagels podman-tui asdf nap navi
brew install one2nc/cloudlens/cloudlens
brew install derailed/k9s/k9s
brew install dhth/tap/omm
brew install jesseduffield/lazynpm/lazynpm
brew install circumflex

asdf plugin add java
asdf plugin add ruby
asdf plugin add gradle
asdf plugin add maven
asdf plugin add nodejs
asdf plugin add uv
asdf plugin add cmake
asdf plugin add lua
asdf plugin add golang

asdf install cmake latest
asdf set -u cmake latest

asdf install lua latest
asdf set -u lua latest

asdf install golang latest
asdf set -u golang latest

asdf install java temurin-11.0.27+6
asdf install java temurin-17.0.15+6
asdf install java temurin-21.0.7+6.0.LTS
asdf install java temurin-24.0.1+9
asdf set -u java temurin-24.0.1+9

asdf install uv latest
asdf set -u uv latest

uv venv

# Install sql ide
uv tool install harlequin
brew install unixodbc
uv pip install pyodbc
uv tool install 'harlequin[s3,mysql,odbc,databricks,bigquery]'
uv tool install euporie
uv pip install ipykernel
uv run python -m ipykernel install --user
uv tool install toolong
uv tool install poetry
uv tool install posting

asdf install nodejs latest
asdf set -u nodejs latest

npm install -g neovim

npm install -g @perryrh0dan/taskline

#Install termscp
curl --proto '=https' --tlsv1.2 -sSLf "https://git.io/JBhDb" | sh
# Install Rust using official script
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install cargo update extension. Usage cargo install-update -a
cargo install cargo-update
cargo install cargo-selector
cargo install onefetch
cargo install tree-sitter-cli
cargo install oha
cargo install --locked zellij
```

#### Config paths

Neovim's configurations are placed under the following paths, depending on your
OS:

| OS    | PATH                                      |
| :---- | :---------------------------------------- |
| Linux | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |
| MacOS | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |

#### Install script

Clone NV-IDE:

- on Linux and Mac

```sh
  git clone git@github.com:lazymaniac/nvim-ide.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

#### Post Installation

Start Neovim

```sh
nvim
```

The `Lazy` plugin manager will start automatically on the first run and install
the configured plugins. After the installation is complete you can press `q` to
close the `Lazy` UI and **you are ready to go**! Next time you run nvim `Lazy`
will no longer show up.

If you would prefer to hide this step and run the plugin sync from the command
line, you can use:

```sh
nvim --headless "+Lazy! sync" +qa
```
