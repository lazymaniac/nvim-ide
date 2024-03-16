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

Fedora script for dependencies Installation.

```sh
#!/bin/bash
# TODO Font, jupyter notebooks, quarto, elixir, padas, pytorch, marplotlib, magic using lua 5.1
# Update package lists
sudo dnf update

# Install packages
sudo dnf copr enable atim/lazygit -y
sudo dnf install -y kitty zsh tmux virtualenv python3-neovim python3-pip cmake fzf luarocks luajit golang ripgrep lazygit ncdu unzip zip zoxide bat eza btop lazygit fd-find xcli libX11-devel
sudo dnf group install "C Development Tools and Libraries" "Development Tools"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install oh-my-zsh headline theme
git clone https://github.com/moarram/headline.git "$ZSH_CUSTOM/themes/headline"
ln -s "$ZSH_CUSTOM/themes/headline/headline.zsh-theme" "$ZSH_CUSTOM/themes/headline.zsh-theme"

# Install sdk-man
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Install Rust using official script
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Java versions
sdk install java 8.0.402-tem
sdk install java 11.0.22-tem
sdk install java 17.0.10-tem
sdk install java 21.0.2-tem
sdk install gradle
sdk install maven

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install node using nvm
nvm install --lts

npm install -g neovim

# Install molten deps
pip install jupytext pynvim pnglatex plotly kaleido pyperclip nbformat

# Install one fetch
cargo install onefetch

# Install treesitter-cli
cargo install tree-sitter-cli

# Install bob
cargo install bob-nvim
bob install nightly
bob use nightly

# Install lazydocker
go install github.com/jesseduffield/lazydocker@latest

# Install lazysql
go install github.com/jorgerojas26/lazysql@latest

# Install magick
sudo luarocks install magick

# Install miniconda
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh
~/miniconda3/bin/conda init zsh

echo "Installation complete."
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
