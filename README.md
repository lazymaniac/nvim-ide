# NV-IDE

NV-IDE is a personal, full polyglot Neovim configuration for Java, Go, Rust, web development, notebooks, cloud tooling, and the rest of the declared language inventory. It has one complete configuration: there are no selectable dependency profiles.

## Requirements

NV-IDE targets Neovim 0.12 or newer. Git 2.31 or newer, curl, tar, gzip, unzip, ripgrep, Bash, a C compiler, LuaRocks, RubyGems, and Tree-sitter CLI 0.26.1 or newer are required for a complete first run. The full configuration also requires the declared language runtimes; optional terminal programs remain operator-owned. `:checkhealth nv_ide` reports every missing executable, version, capability, and platform-specific repair without exposing credentials.

The versioned runtime floor is Go 1.26, Node.js 24.15, JDK/Javac 21, Python 3.10–3.13 with `venv`, Ruby 3 with development headers, Rust 1.42, GHC 8.10, and Cabal 3.0. The complete inventory also includes Ansible, one Clojure runtime, CMake/Ninja, a container runtime, Dart/Flutter, Maven, Gradle, Kotlin, Lua, R, Scala/SBT, PostgreSQL client tools, and Terraform. These are intentionally not hidden behind profiles.

### macOS with Homebrew

Install Apple's command-line tools once, then install the unprivileged prerequisites:

```sh
xcode-select --install
brew install neovim bash git curl gzip unzip ripgrep fd fzf luarocks ruby tree-sitter-cli
```

Local clipboard integration uses the built-in `pbcopy` and `pbpaste` commands.

For the complete runtime inventory, Homebrew users can install current packages and then let health verify the exact versions:

```sh
brew install ansible cmake ninja go ghcup openjdk@21 maven gradle node kotlin lua luajit python@3.13 ruby rustup-init scala sbt libpq podman clojure/tools/clojure
brew install --cask flutter r
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
gem install bundler
rustup-init -y
ghcup install ghc recommended && ghcup set ghc recommended
ghcup install cabal recommended && ghcup set cabal recommended
```

On Apple Silicon, Mason's current `hlint` artifact also needs Rosetta: `softwareupdate --install-rosetta --agree-to-license`. NV-IDE hydrates existing Homebrew keg paths and the standard Cargo, Go, and GHCup user paths for GUI launches; it does not edit shell startup files.

### Ubuntu

Install the base tools explicitly from a terminal you control:

```sh
sudo apt-get update
sudo apt-get install bash git curl tar gzip unzip build-essential ripgrep fd-find fzf cargo luarocks ruby ruby-dev bundler xclip
cargo install tree-sitter-cli --version 0.26.3 --locked
```

Ubuntu's packaged Neovim and language runtimes may be below the supported floors. Install compatible releases using their official installers or your preferred version manager, then use `:checkhealth nv_ide` as the authoritative verification. Install a current Neovim from the [official Neovim installation page](https://neovim.io/doc/install/) when the distro package is older than 0.12. Wayland users should install `wl-clipboard`; X11 users can use `xclip`.

These are deliberate operator commands. Neovim never invokes `sudo`, Homebrew, apt, dnf, or pacman in the background.

### Optional Just and Delta integrations

Install the optional task runner and LazyGit diff pager:

- macOS: `brew install just git-delta`
- Debian 13/Ubuntu 24.04+: `sudo apt install just`; install Delta's release `.deb` or use `cargo install git-delta`
- Fedora: `sudo dnf install just git-delta`
- Arch: `sudo pacman -S just git-delta`

Overseer's builtin provider discovers justfiles and exposes recipes through
`<leader>rr` / `:OverseerRun`; opening a project never runs a recipe.

The tracked LazyGit configuration uses `delta --dark --paging=never`.
This does not write or require a global `~/.gitconfig`; command-line Git users
may configure Delta separately.

## Install

Preserve an existing configuration before cloning. NV-IDE does not replace `.zshrc`, `.zprofile`, or any other shell configuration.

```sh
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$config_home"
git clone https://github.com/lazymaniac/nvim-ide.git "$config_home/nvim"
nvim
```

On first startup:

1. Lazy installs the declared plugins.
2. The toolchain discovers the complete missing Mason and Tree-sitter inventory.
3. Missing Mason tools and Tree-sitter parsers install automatically without blocking the editor UI.
4. After the first install cycle releases its lock, one latest-first plugin resolution runs for that manifest fingerprint, even if a Mason tool or parser still needs repair.
5. Installation and update failures are summarized independently under the XDG state directory so they can be diagnosed and retried without hiding either result.

Normal startup never installs system packages or language runtimes. It only manages plugin, Mason, and parser state owned by this configuration.

## Toolchain commands

- `:ToolchainInstall` discovers and asynchronously installs missing plugins, Mason tools, and Tree-sitter parsers.
- `:ToolchainInstall!` waits for installation and verifies the result; headless use waits automatically.
- `:ToolchainRepair` bypasses the successful-run debounce and retries failed or missing items.
- `:ToolchainRepair!` retries, waits, and verifies.
- `:ToolchainUpdate` snapshots the current Lazy lockfile, updates allowed plugin versions and parsers, then runs smoke validation.
- `:ToolchainUpdate!` performs the update synchronously.

Only one install or update owns the XDG-state lock at a time, so opening several Neovim processes cannot launch competing repairs.

## Health and recovery

Run the project health provider after installation or whenever an integration is unavailable:

```vim
:checkhealth nv_ide
:checkhealth snacks
```

The report distinguishes required and optional dependencies, Mason tools, parsers, runtimes, external mappings, file watching, clipboard support, and AI adapter availability. Credential checks reveal presence only; values are never displayed.

`lazy-lock.json` is the tracked known-good plugin record. Before `:ToolchainUpdate`, NV-IDE retains a timestamped snapshot under `stdpath('state')/nv_ide/toolchain`. If validation fails, the command restores the external `lazy.nvim` checkout, restores the previous lockfile byte-for-byte, and runs a blocking Lazy restore automatically. Mason packages and parsers do not guarantee exact upstream downgrades, so health reports their observed state rather than promising a bit-for-bit rollback.

For a manual plugin rollback, restore the desired Git revision of `lazy-lock.json`, then run:

```vim
:Lazy restore
```

Use `:ToolchainRepair!` afterward to verify Mason and parser availability.

## Clipboard behavior

- Local macOS uses `pbcopy`/`pbpaste`.
- Local Linux uses `wl-copy`/`wl-paste` on Wayland or `xclip` on X11.
- SSH sessions without an explicitly configured provider use OSC 52, so copied text travels through the terminal instead of requiring a remote desktop clipboard package.
- When SSH runs inside tmux, enable terminal passthrough if OSC 52 is blocked. `:checkhealth nv_ide` reports the constraint.

An explicitly supplied `g:clipboard` always wins over automatic selection.

## Isolated verification

The smoke runner copies the checkout into a temporary HOME/XDG tree. It never reads or mutates the normal Neovim data or state directories.

```sh
tests/headless/no-profile.sh preflight
NV_IDE_SMOKE_ALLOW_INSTALL=1 tests/headless/no-profile.sh representative
NV_IDE_SMOKE_ALLOW_INSTALL=1 tests/headless/no-profile.sh resolve
NV_IDE_SMOKE_ALLOW_INSTALL=1 NV_IDE_SMOKE_FULL=1 tests/headless/no-profile.sh full
```

`preflight` is offline. `representative` performs a real isolated Mason and parser install. `resolve` starts from the tracked lock, resolves the latest plugin versions allowed by the declarations, refreshes the external Lazy bootstrap checkout to the newest stable semantic-version tag, and launches a second bounded Neovim process from those resolved checkouts. The lockfile is copied outside the disposable XDG tree only after that process validates startup plus the representative `gopls`, `clangd`, and `vtsls` compositions. Set `NV_IDE_SMOKE_LOCK_OUTPUT` to choose that absolute destination; otherwise the runner prints the surviving temporary path.

`full` is intentionally double-gated because it is network- and time-intensive. It first prepares plugins at the exact commits in `lazy-lock.json`, then starts the real `init.lua` with `NVIM_TOOLCHAIN_AUTORUN=1`. That VimEnter cycle installs and verifies the complete missing Mason and Tree-sitter declaration, performs the first-run update, and must persist successful repair and update evidence before the smoke process exits. Full mode then applies the same stable-Lazy and fresh-process publication gate used by `resolve`. Pull requests run preflight, representative, and bounded plugin-resolution modes on Ubuntu and macOS; scheduled or explicitly requested CI runs full mode with caches keyed by operating system, lockfile, and manifest fingerprint. Every OS job uploads its resolved lockfile as a CI artifact. Cached smoke dependencies are checked out to the tracked lockfile commits again on every run, so warm and cold caches exercise the same plugin code.

## Updating the configuration

Pull configuration changes normally, inspect the diff, start Neovim, and run `:ToolchainUpdate!` when you intentionally want current plugin/parser versions. Keep personal shell setup, credentials, and language environments outside this repository.
