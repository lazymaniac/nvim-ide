#!/usr/bin/env bash
set -euo pipefail

mode="${1:-preflight}"
case "$mode" in
  preflight) ;;
  representative|resolve)
    if [[ "${NV_IDE_SMOKE_ALLOW_INSTALL:-}" != "1" ]]; then
      printf '%s mode requires NV_IDE_SMOKE_ALLOW_INSTALL=1\n' "$mode" >&2
      exit 2
    fi
    ;;
  full)
    if [[ "${NV_IDE_SMOKE_ALLOW_INSTALL:-}" != "1" || "${NV_IDE_SMOKE_FULL:-}" != "1" ]]; then
      printf '%s\n' 'full mode requires NV_IDE_SMOKE_ALLOW_INSTALL=1 and NV_IDE_SMOKE_FULL=1' >&2
      exit 2
    fi
    ;;
  *)
    printf 'usage: %s {preflight|representative|resolve|full}\n' "$0" >&2
    exit 2
    ;;
esac

if ! command -v nvim >/dev/null 2>&1; then
  printf '%s\n' 'nvim is required for the bootstrap smoke test' >&2
  exit 127
fi

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)"
source_root="$(CDPATH= cd -- "$script_dir/../.." && pwd -P)"
tmp_base="${TMPDIR:-/tmp}"
tmp_base="${tmp_base%/}"
smoke_prefix="$tmp_base/nv-ide-smoke."
smoke_root="$(mktemp -d "${smoke_prefix}XXXXXX")"
cleanup() {
  case "$smoke_root" in
    "$smoke_prefix"*) rm -rf -- "$smoke_root" ;;
    *) printf 'refusing to remove unexpected smoke path: %s\n' "$smoke_root" >&2 ;;
  esac
}
trap cleanup EXIT INT TERM

resolved_lock_output="${NV_IDE_SMOKE_LOCK_OUTPUT:-}"
if [[ "$mode" == "resolve" || "$mode" == "full" ]]; then
  resolved_lock_output="${resolved_lock_output:-$tmp_base/nv-ide-$mode-lazy-lock-$$.json}"
  case "$resolved_lock_output" in
    /*) ;;
    *)
      printf 'resolved lockfile output must be absolute: %s\n' "$resolved_lock_output" >&2
      exit 2
      ;;
  esac
  case "$resolved_lock_output/" in
    "$smoke_root/"*|"$source_root/"*)
      printf 'resolved lockfile output must survive cleanup and stay outside the checkout: %s\n' \
        "$resolved_lock_output" >&2
      exit 2
      ;;
  esac
  export NV_IDE_SMOKE_LOCK_OUTPUT="$resolved_lock_output"
fi

cache_root="${NV_IDE_SMOKE_CACHE_ROOT:-$smoke_root/cache}"
live_data_home="${XDG_DATA_HOME:-${HOME:-}/.local/share}"
live_state_home="${XDG_STATE_HOME:-${HOME:-}/.local/state}"

case "$cache_root" in
  /)
    printf 'refusing unsafe smoke cache path: %s\n' "$cache_root" >&2
    exit 2
    ;;
  /*) ;;
  *)
    printf 'smoke cache path must be absolute: %s\n' "$cache_root" >&2
    exit 2
    ;;
esac
case "$cache_root/" in
  "$source_root/"*|"${live_data_home%/}/"*|"${live_state_home%/}/"*)
    printf 'refusing unsafe smoke cache path: %s\n' "$cache_root" >&2
    exit 2
    ;;
esac

export NV_IDE_SMOKE_ROOT="$smoke_root"
export NV_IDE_SMOKE_SOURCE_ROOT="$source_root"
export HOME="$smoke_root/home"
export XDG_CONFIG_HOME="$smoke_root/xdg/config"
export XDG_DATA_HOME="$smoke_root/xdg/data"
export XDG_STATE_HOME="$smoke_root/xdg/state"
export XDG_CACHE_HOME="$smoke_root/xdg/cache"
export NVIM_APPNAME=nvim
export NVIM_LOG_FILE="${NVIM_LOG_FILE:-$smoke_root/nvim.log}"

config_root="$XDG_CONFIG_HOME/$NVIM_APPNAME"
mkdir -p "$HOME" "$config_root" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
cp -R "$source_root/." "$config_root"
rm -rf -- "$config_root/.git"

if [[ "$mode" != "preflight" ]]; then
  plugin_root="$cache_root/plugins"
  install_cache="$cache_root/install-data"
  mkdir -p "$plugin_root" "$install_cache"
  if [[ -n "$(ls -A "$install_cache")" ]]; then
    cp -R "$install_cache/." "$XDG_DATA_HOME"
  fi

  locked_plugin_entry() {
    local name="$1"
    nvim --clean --headless -u NONE -i NONE \
      -l "$config_root/tests/headless/locked_plugin.lua" "$config_root/lazy-lock.json" "$name"
  }

  clone_plugin() {
    local name="$1"
    local url="$2"
    local entry branch commit
    local destination="$plugin_root/$name"
    entry="$(locked_plugin_entry "$name")"
    IFS=$'\t' read -r branch commit <<<"$entry"
    if [[ ! "$commit" =~ ^[0-9a-fA-F]{40}$ || -z "$branch" ]]; then
      printf 'invalid lazy-lock.json entry for %s: %s\n' "$name" "$entry" >&2
      exit 1
    fi

    if [[ -e "$destination" ]]; then
      if [[ ! -d "$destination/.git" ]]; then
        printf 'invalid cached plugin path: %s\n' "$destination" >&2
        exit 1
      fi
    else
      mkdir -p "$destination"
      git -C "$destination" init --quiet
    fi

    if git -C "$destination" remote get-url origin >/dev/null 2>&1; then
      git -C "$destination" remote set-url origin "$url"
    else
      git -C "$destination" remote add origin "$url"
    fi
    if ! git -C "$destination" cat-file -e "$commit^{commit}" 2>/dev/null; then
      if ! git -C "$destination" fetch --quiet --filter=blob:none --depth 1 origin "$commit"; then
        if [[ "$(git -C "$destination" rev-parse --is-shallow-repository)" == "true" ]]; then
          git -C "$destination" fetch --quiet --filter=blob:none --unshallow origin \
            "+refs/heads/$branch:refs/remotes/origin/$branch"
        else
          git -C "$destination" fetch --quiet --filter=blob:none origin \
            "+refs/heads/$branch:refs/remotes/origin/$branch"
        fi
      fi
    fi
    git -C "$destination" cat-file -e "$commit^{commit}"
    git -C "$destination" checkout --quiet --force --detach "$commit"
    if [[ "$(git -C "$destination" rev-parse HEAD)" != "$commit" ]]; then
      printf 'cached plugin did not checkout its locked commit: %s\n' "$name" >&2
      exit 1
    fi
  }

  clone_plugin mason.nvim https://github.com/mason-org/mason.nvim.git
  clone_plugin mason-tool-installer.nvim https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim.git
  clone_plugin nvim-treesitter https://github.com/nvim-treesitter/nvim-treesitter.git
  clone_plugin snacks.nvim https://github.com/folke/snacks.nvim.git
  clone_plugin lazy.nvim https://github.com/folke/lazy.nvim.git
  export NV_IDE_SMOKE_PLUGIN_ROOT="$plugin_root"
fi

cd "$config_root"
smoke_mode="$mode"
if [[ "$mode" == "resolve" || "$mode" == "full" ]]; then
  # The full path leaves Mason and parser installation to the real VimEnter
  # autorun below. Resolve mode is intentionally plugin-only, while
  # representative mode covers the direct adapter smoke.
  smoke_mode="preflight"
fi
nvim --clean --headless -u "$config_root/tests/minimal_init.lua" -i NONE \
  -l "$config_root/tests/headless/bootstrap_smoke.lua" "$smoke_mode"

verify_codecompanion_reasoning_startup_guard() {
  local log="$smoke_root/codecompanion-reasoning-startup-guard.log"
  if nvim --headless -u "$config_root/tests/headless/codecompanion_reasoning_failing_init.lua" -i NONE \
    -l "$config_root/tests/headless/codecompanion_reasoning_runtime.lua" >"$log" 2>&1; then
    tail -n 200 "$log" >&2
    printf '%s\n' 'failing init unexpectedly passed CodeCompanion reasoning verification' >&2
    return 1
  fi
  if ! grep -Fq 'Neovim startup failed before CodeCompanion reasoning verification' "$log"; then
    tail -n 200 "$log" >&2
    return 1
  fi
  if grep -Fq 'CODECOMPANION REASONING PASS' "$log"; then
    tail -n 200 "$log" >&2
    return 1
  fi
  printf '%s\n' 'CODECOMPANION STARTUP GUARD PASS'
}

verify_codecompanion_reasoning_startup_guard

prepare_locked_plugins() {
  run_lazy_resolution seed 'LAZY SEED PASS'
  verify_codecompanion_reasoning
}

run_lazy_resolution() {
  local action="$1"
  shift
  local log="$smoke_root/lazy-$action.log"
  if ! LAZY="$plugin_root/lazy.nvim" NVIM_TOOLCHAIN_AUTORUN=0 \
    nvim --headless -u "$config_root/init.lua" -i NONE \
      -l "$config_root/tests/headless/lazy_resolution.lua" "$action" >"$log" 2>&1; then
    tail -n 200 "$log" >&2
    return 1
  fi
  for marker in "$@"; do
    if ! grep -Fq "$marker" "$log"; then
      tail -n 200 "$log" >&2
      return 1
    fi
    printf '%s\n' "$marker"
  done
}

verify_codecompanion_reasoning() {
  local log="$smoke_root/codecompanion-reasoning.log"
  if ! LAZY="$plugin_root/lazy.nvim" NVIM_TOOLCHAIN_AUTORUN=0 \
    nvim --headless -u "$config_root/init.lua" -i NONE \
      -l "$config_root/tests/headless/codecompanion_reasoning_runtime.lua" >"$log" 2>&1; then
    tail -n 200 "$log" >&2
    return 1
  fi
  if ! grep -Fq 'CODECOMPANION REASONING PASS' "$log"; then
    tail -n 200 "$log" >&2
    return 1
  fi
  printf '%s\n' 'CODECOMPANION REASONING PASS'
}

if [[ "$mode" == "resolve" ]]; then
  prepare_locked_plugins
  run_lazy_resolution update 'LAZY UPDATE PASS' 'LAZY STABLE PASS' 'FRESH STARTUP PASS'
  if [[ ! -s "$resolved_lock_output" ]]; then
    printf 'fresh startup did not publish a resolved lockfile: %s\n' "$resolved_lock_output" >&2
    exit 1
  fi
  printf 'RESOLVED LOCKFILE %s\n' "$resolved_lock_output"
elif [[ "$mode" == "full" ]]; then
  prepare_locked_plugins
  startup_log="$smoke_root/startup-autorun.log"
  if ! LAZY="$plugin_root/lazy.nvim" NVIM_TOOLCHAIN_AUTORUN=1 \
    nvim --headless -u "$config_root/init.lua" -i NONE \
      -c "lua dofile(vim.fs.joinpath(vim.fn.stdpath('config'), 'tests', 'headless', 'startup_smoke.lua'))" \
      >"$startup_log" 2>&1; then
    tail -n 200 "$startup_log" >&2
    exit 1
  fi
  if ! grep -Fq 'STARTUP AUTORUN PASS' "$startup_log"; then
    tail -n 200 "$startup_log" >&2
    exit 1
  fi
  printf '%s\n' 'STARTUP AUTORUN PASS'
  run_lazy_resolution publish 'LAZY STABLE PASS' 'FRESH STARTUP PASS'
  if [[ ! -s "$resolved_lock_output" ]]; then
    printf 'fresh startup did not publish a resolved lockfile: %s\n' "$resolved_lock_output" >&2
    exit 1
  fi
  printf 'RESOLVED LOCKFILE %s\n' "$resolved_lock_output"
fi

if [[ "$mode" != "preflight" ]]; then
  # Git packfiles copied from a previous run can be read-only. Make this
  # operator-owned smoke cache writable before refreshing it in place.
  chmod -R u+w "$cache_root/install-data"
  cp -R "$XDG_DATA_HOME/." "$cache_root/install-data"
fi
