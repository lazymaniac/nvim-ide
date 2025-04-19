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

brew install lazygit virtualenv cmake fzf luarocks luajit golang ripgrep ncdu zoxide bat eza btop fd fastfetch oh-my-posh bagels podman-tui
brew install --cask iterm2
brew install one2nc/cloudlens/cloudlens
brew install derailed/k9s/k9s

# Install sdk-man
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Install Java versions
sdk install java 8.0.442-tem
sdk install java 11.0.26-tem
sdk install java 17.0.14-tem
sdk install java 21.0.6-tem
sdk install gradle
sdk install maven

# Install UV
curl -LsSf https://astral.sh/uv/install.sh | sh
# Install sql ide
uv tool install harlequin
brew install unixodbc
uv pip install pyodbc
uv tool install 'harlequin[s3,mysql,odbc,databricks,bigquery]'
uv tool install euporie
uv pip install ipykernel
uv run python -m ipykernel install --user
uv tool install toolong

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install node using nvm
nvm install --lts

npm install -g neovim

npm install --global @perryrh0dan/taskline

# Install molten deps
pip install pynvim pnglatex plotly kaleido nbformat yarp

# Install poetry
pipx install poetry jupytext jupyter-client notebook posting

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

# Install bob
cargo install bob-nvim
bob install stable
bob use stable

# Install lazydocker
go install github.com/jesseduffield/lazydocker@latest
```

- quarto [https://quarto.org/docs/download/]

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
