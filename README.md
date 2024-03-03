# NV-IDE personalized mix of available NVIM distros

<!--toc:start-->

- [NV-IDE personalized mix of available NVIM distros](#nv-ide-personalized-mix-of-available-nvim-distros)
  - [TODO](#todo)
  - [Introduction](#introduction)
  - [Installation](#installation)
    - [Requirements](#requirements)
      - [Packages](#packages)
      - [Config paths](#config-paths)
      - [Install script](#install-script)
      - [Post Installation](#post-installation)
  - [Recommended Steps](#recommended-steps)
    - [Configuration And Extension](#configuration-and-extension)
      - [Example: Adding an autopairs plugin](#example-adding-an-autopairs-plugin)
      - [Example: Adding a file tree plugin](#example-adding-a-file-tree-plugin)
<!--toc:end-->

## TODO

- code cleanup
- script installing all the required dependencies for Ubuntu in WSL

## Introduction

- NVIM distribution created to support my workflows. From java, go, rust to
  jupyter notebooks.

## Installation

> **NOTE**
> Backup your previous configuration (if any exists)

### Requirements

- Make sure to review the readmes of the plugins if you are experiencing errors.
  In particular:
  - [ripgrep](https://github.com/BurntSushi/ripgrep#installation) is necessary for
    [telescope](https://github.com/nvim-telescope/telescope.nvim#suggested-dependencies)
    pickers.

#### Packages

- kitty
- zsh
- oh-my-zsh
- oh-my-zsh headline theme
- tmux
- build-essential
- python3-full
- virtualenv
- python3-neovim
- cmake
- pipx
- fzf
- imagemagick
- libmagickwand-dev libgraphicsmagick1-dev
- luarocks
- luajit
- golang
- rustup
- artem (cargo)
- onefetch (cargo)
- ripgrep (cargo)
- treesitter-cli (cargo)
- lazygit (cargo)
- neovide (cargo)
- sdk-man
- java 8, 11, 17, 21
- lazydocker
- lazysql
- bob (cargo)
- btop
- ncdu
- nvm
- node
- zoxide
- bat
- eza
- zip
- unzip
- jupytext
- miniconda
- gradle
- maven
- quarto

#### Config paths

Neovim's configurations are located under the following paths, depending on your
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

## Recommended Steps

[Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo) this repo
(so that you have your own copy that you can modify) and then installing you
can install to your machine using the methods above.

### Configuration And Extension

- Inside of your copy, feel free to modify any file you like! It's your copy!
- Feel free to change any of the default options in `init.lua` to better suit
  your needs.
- For adding plugins, there are 3 primary options:
  - Add new configuration in `lua/custom/plugins/*` files, which will be auto
    sourced using `lazy.nvim` (uncomment the line importing the `custom/plugins`
    directory in the `init.lua` file to enable this)
  - Modify `init.lua` with additional plugins.
  - Include the `lua/kickstart/plugins/*` files in your configuration.

You can also merge updates/changes from the repo back into your fork, to keep
up-to-date with any changes for the default configuration.

#### Example: Adding an autopairs plugin

In the file: `lua/custom/plugins/autopairs.lua`, add:

```lua
-- File: lua/plugins/autopairs.lua

return {
  "windwp/nvim-autopairs",
  -- Optional dependency
  dependencies = { 'hrsh7th/nvim-cmp' },
  config = function()
    require("nvim-autopairs").setup {}
    -- If you want to automatically add `(` after selecting a function or method
    local cmp_autopairs = require('nvim-autopairs.completion.cmp')
    local cmp = require('cmp')
    cmp.event:on(
      'confirm_done',
      cmp_autopairs.on_confirm_done()
    )
  end,
}
```

This will automatically install
[windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs) and enable it
on startup. For more information, see documentation for
[lazy.nvim](https://github.com/folke/lazy.nvim).

#### Example: Adding a file tree plugin

In the file: `lua/plugins/filetree.lua`, add:

```lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  version = "*",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function ()
    require('neo-tree').setup {}
  end,
}
```

This will install the tree plugin and add the command `:Neotree` for you. You
can explore the documentation at
[neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) for more information.
