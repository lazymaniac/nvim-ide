# Self-Healing Neovim Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` to execute this plan task-by-task, `superpowers:test-driven-development` for every behavioral change, and `superpowers:verification-before-completion` before claiming completion.

**Goal:** Preserve the complete polyglot Neovim installation and automatic startup installs while repairing configuration composition, portability, integration correctness, rollback, health, and CI.

**Architecture:** A private no-profile toolchain manifest feeds one startup orchestrator, one Mason owner, one Tree-sitter installer, health, and CI. A separate central LSP registry composes server options and records explicit external ownership. All stateful work is locked, debounced, retryable, and observable through XDG state and health output.

**Tech Stack:** Lua 5.1/LuaJIT, Neovim 0.12 native APIs, lazy.nvim, mason.nvim, mason-tool-installer.nvim, nvim-treesitter `main`, nvim-lspconfig, headless Neovim tests, GitHub Actions.

---

## Execution rules

- Work in `/private/tmp/nvim-config-plan-implementation` on `codex/nvim-plan-implementation`.
- Start every production change with a focused failing headless test and record the expected failure.
- Run all Neovim commands with `NVIM_LOG_FILE` pointing under `/private/tmp` so probes do not dirty the repository.
- Do not install or update the live user's plugins while running unit/headless tests.
- Do not add user-selectable profiles. The manifest is a single complete inventory.
- Do not run `sudo`, system package managers, or destructive Git commands.
- Commit after each task using a concise Conventional Commit subject.

## Standard commands

Run one spec:

```bash
NVIM_LOG_FILE=/private/tmp/nvim-plan-tests.log \
  nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/lsp_registry_spec.lua
```

Run all headless specs:

```bash
NVIM_LOG_FILE=/private/tmp/nvim-plan-tests.log \
  nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua
```

Compile every Lua file:

```bash
NVIM_LOG_FILE=/private/tmp/nvim-plan-syntax.log \
  nvim --clean --headless -u NONE -i NONE \
  -c "lua for _,f in ipairs(vim.fn.glob('**/*.lua', false, true)) do assert(loadfile(f), f) end" \
  -c "qa!"
```

## Task 1: Add the dependency-free headless test harness

**Files:**

- Create: `tests/minimal_init.lua`
- Create: `tests/headless/harness.lua`
- Create: `tests/headless/run.lua`
- Create: `tests/headless/harness_spec.lua`

**Step 1: Write the failing harness self-test**

The self-test must assert that the harness supports nested suites, equality/deep-equality, truthiness, error matching, temporary directories, and deterministic cleanup. Include one intentionally captured failing assertion to prove failure text contains the spec name and actual/expected values without failing the outer run.

**Step 2: Run the self-test and confirm RED**

Run the one-spec command with `tests/headless/harness_spec.lua`. Expected failure: `module 'tests.headless.harness' not found`.

**Step 3: Implement the minimal harness**

`tests/minimal_init.lua` must prepend the repository root to `runtimepath` and `package.path`, disable swap/shada, and avoid loading the user's plugins. `run.lua` must discover `*_spec.lua` in lexical order when no argument is supplied and return a non-zero exit on failure.

**Step 4: Run the self-test and confirm GREEN**

Run the one-spec command, then the all-spec command. Both must exit 0.

**Step 5: Commit**

```bash
git add tests/minimal_init.lua tests/headless
git commit -m "test: add headless Lua harness"
```

## Task 2: Repair the central LSP registry and client/buffer keymaps

**Files:**

- Create: `tests/headless/lsp_registry_spec.lua`
- Create: `tests/headless/lsp_keymaps_spec.lua`
- Create: `lua/plugins/lsp/registry.lua`
- Modify: `lua/plugins/lsp/init.lua`
- Modify: `lua/plugins/lsp/keymaps.lua`
- Modify: `lua/util/lsp.lua`
- Modify: `lua/plugins/lsp/lang/go.lua`
- Modify: `lua/plugins/lsp/lang/clangd.lua`
- Modify: `lua/plugins/lsp/lang/typescript.lua`
- Modify: `lua/plugins/lsp/lang/angular.lua`
- Modify: `lua/plugins/lsp/lang/yaml.lua`
- Modify: `lua/plugins/lsp/lang/haskell.lua`

**Step 1: Write failing registry tests**

Assert that the registry:

- deep-merges shared protocol/Blink capabilities with server capabilities;
- preserves gopls settings, clangd command/options, and vtsls settings from language modules;
- invokes named and wildcard setup hooks once;
- registers and enables each centrally owned server once;
- treats HLS as externally owned and never centrally enables it;
- removes internal `enabled`/ownership metadata before calling `vim.lsp.config`;
- configures clangd extensions through clangd's setup hook.

Use injected `config`, `enable`, and capability providers; test real merge/ownership behavior rather than mock call existence.

**Step 2: Write failing keymap lifecycle tests**

Assert that each client/buffer receives an independent key table, `supports_method` receives the buffer number, dynamic registration reapplies mappings to every attached buffer, and position requests use `client.offset_encoding`.

**Step 3: Run both specs and confirm RED**

Expected failures: missing `lua/plugins/lsp/registry.lua` and current global key-table mutation/current-buffer behavior.

**Step 4: Implement the registry and lifecycle**

Move server registration out of the hard-coded `config` body. Compose options from `opts.servers` and `opts.setup`, deep-copy every table, and explicitly list external owners. Remove duplicate hard-coded Lua/Angular/YAML/TypeScript setup from `init.lua`; keep those settings in language modules. Require Angular-specific roots, compute YAML schemas before registration, and pass the client's encoding in TypeScript requests.

Remove the private global `_watchfiles` monkeypatch from root `init.lua` as part of this task.

**Step 5: Run focused and aggregate specs**

Run `lsp_registry_spec.lua`, `lsp_keymaps_spec.lua`, then all specs. All must pass.

**Step 6: Commit**

```bash
git add init.lua lua/plugins/lsp lua/util/lsp.lua tests/headless/lsp_registry_spec.lua tests/headless/lsp_keymaps_spec.lua
git commit -m "fix(lsp): compose and own servers centrally"
```

## Task 3: Restore Tree-sitter selection, Leap, and quickfix behavior

**Files:**

- Create: `tests/headless/interaction_spec.lua`
- Modify: `lua/plugins/treesitter.lua`
- Modify: `lua/plugins/search.lua`
- Modify: `lua/config/keymaps.lua`

**Step 1: Write failing interaction tests**

Assert from evaluated plugin specs and real Neovim mappings that:

- Leap declares normal/visual/operator-pending `s` and normal `S` triggers;
- no Leap code calls `set_repeat_keys` with Enter or Backspace;
- quickfix buffers retain native Enter behavior;
- `[q` and `]q` resolve to Neovim's native quickfix navigation rather than duplicate custom mappings;
- parser-start setup creates buffer-local normal/visual `<C-Space>` parent selection and visual `<BS>` child selection using `vim.treesitter.select` and `vim.v.count1`.

**Step 2: Run the spec and confirm RED**

Expected failures: Leap has no effective trigger, Enter/Backspace are globally intercepted, and Tree-sitter selection mappings are absent.

**Step 3: Implement the mappings**

Give Leap explicit `s`/`S` keys and delete repeat-key setup. Install Tree-sitter mappings only after parser start and only for that buffer. Remove redundant custom `[q`/`]q` mappings so Neovim 0.12 owns navigation.

**Step 4: Run the interaction spec and all specs**

Both commands must exit 0.

**Step 5: Commit**

```bash
git add lua/plugins/treesitter.lua lua/plugins/search.lua lua/config/keymaps.lua tests/headless/interaction_spec.lua
git commit -m "fix(ui): restore selection and quickfix keys"
```

## Task 4: Create the complete toolchain manifest and early portable environment

**Files:**

- Create: `tests/headless/manifest_spec.lua`
- Create: `tests/headless/environment_spec.lua`
- Create: `lua/nv_ide/toolchain/manifest.lua`
- Create: `lua/nv_ide/toolchain/environment.lua`
- Create: `lua/nv_ide/toolchain/init.lua`
- Modify: `init.lua`
- Modify: `lua/config/options.lua`
- Modify: `lua/config/init.lua`

**Step 1: Write failing manifest tests**

Build exact assertions for the deduplicated union of the current Mason and Tree-sitter declarations, all language runtimes, every executable used by an external mapping, AI CLI/backend checks, stable-branch exceptions, schema version, and deterministic fingerprint. Assert that the manifest exposes one complete inventory and contains no profile selector or profile names.

**Step 2: Write failing environment tests**

With injected filesystem/environment probes, assert deterministic PATH hydration for Darwin/Linux, no nonexistent directory insertion, no login-shell execution, OSC 52 selection for SSH, preservation of a user-provided clipboard provider, and unchanged local clipboard detection.

**Step 3: Run both specs and confirm RED**

Expected failure: the `nv_ide.toolchain` modules do not exist.

**Step 4: Implement manifest and early environment**

Move the complete raw declarations into sorted/deduplicated records. Call `require('nv_ide.toolchain').early()` before Lazy. Remove `/bin/zsh`, replace `vim.loop` with `vim.uv` in touched loaders, honor supplied options in `lua/config/init.lua`, and ensure each module loads once.

**Step 5: Run focused/all specs and syntax compilation**

All commands must exit 0.

**Step 6: Commit**

```bash
git add init.lua lua/config lua/nv_ide tests/headless/manifest_spec.lua tests/headless/environment_spec.lua
git commit -m "feat(toolchain): declare full portable inventory"
```

## Task 5: Make startup installation single-owner, locked, and retryable

**Files:**

- Create: `tests/headless/state_lock_spec.lua`
- Create: `tests/headless/mason_installer_spec.lua`
- Create: `tests/headless/treesitter_installer_spec.lua`
- Create: `tests/headless/orchestrator_spec.lua`
- Create: `lua/nv_ide/toolchain/state.lua`
- Create: `lua/nv_ide/toolchain/lock.lua`
- Create: `lua/nv_ide/toolchain/mason.lua`
- Create: `lua/nv_ide/toolchain/treesitter.lua`
- Create: `lua/nv_ide/toolchain/orchestrator.lua`
- Modify: `lua/nv_ide/toolchain/init.lua`
- Modify: `lua/plugins/lsp/init.lua`
- Modify: `lua/plugins/treesitter.lua`
- Modify: `lua/plugins/dap.lua`

**Step 1: Write failing state/lock tests**

Cover atomic state replacement, schema/fingerprint invalidation, live-lock refusal, stale-lock recovery only after PID verification, token-checked release, retry after failure, and manual repair bypassing debounce.

**Step 2: Write failing installer ownership tests**

Assert that only mason-tool-installer receives the full raw Mason IDs with `run_on_start = true`, a short start delay, project-owned debounce, and `auto_update = false`. Assert no `MasonInstall`, Mason package `install()`, second `mason-lspconfig.ensure_installed`, or automatic DAP installation remains.

Assert that startup Tree-sitter installation requests only missing deduplicated parsers asynchronously, while bang/headless commands wait with a timeout and verify parser availability.

**Step 3: Write failing orchestration tests**

Cover startup success, missing-item discovery despite a prior success, concurrent invocation, stage failure persistence, retry, one failure summary, and command registration for `ToolchainInstall`/`ToolchainRepair`.

**Step 4: Run the four specs and confirm RED**

Expected failures: modules absent and multiple current installer owners detected.

**Step 5: Implement minimal adapters and orchestration**

State lives under `stdpath('state')/nv_ide/toolchain` and uses atomic temporary-file replacement. The orchestrator holds one lock across discovery/install/verification, never invokes system package managers, and leaves Neovim usable on failure.

**Step 6: Run focused/all specs and syntax compilation**

All commands must exit 0.

**Step 7: Commit**

```bash
git add lua/nv_ide/toolchain lua/plugins/lsp/init.lua lua/plugins/treesitter.lua lua/plugins/dap.lua tests/headless
git commit -m "feat(toolchain): repair missing tools at startup"
```

## Task 6: Add latest-first update, rollback, and health diagnostics

**Files:**

- Create: `tests/headless/update_rollback_spec.lua`
- Create: `tests/headless/health_spec.lua`
- Create: `lua/nv_ide/toolchain/plugins.lua`
- Create: `lua/nv_ide/toolchain/smoke.lua`
- Create: `lua/nv_ide/health.lua`
- Modify: `lua/nv_ide/toolchain/orchestrator.lua`
- Modify: `lua/config/lazy.lua`
- Modify: `.gitignore`
- Add: `lazy-lock.json`

**Step 1: Write failing rollback tests**

Assert that update snapshots the current lockfile, runs a blocking Lazy update, waits for Tree-sitter update, validates smoke checks, retains the prior snapshot, and restores plus invokes Lazy restore on validation failure. Assert the fresh-install path resolves current allowed versions rather than restoring the prior snapshot.

**Step 2: Write failing health tests**

Use a complete injected probe to assert required/optional classification, every manifest dependency, Mason/parser states, watchers/inotify, external mappings, local/SSH/tmux clipboard diagnostics, AI backends, and credential-presence booleans. Include sentinel credential values and assert they never occur in collected or rendered output.

**Step 3: Run both specs and confirm RED**

Expected failures: no update command/rollback adapter/health provider.

**Step 4: Implement update and health**

Fix Lazy `checker.enabled`, keep global `version = '*'`, explicitly list verified branch exceptions, check Lazy bootstrap clone exit status, register `ToolchainUpdate`, and expose `collect(probe)` plus `check()` in the health provider.

Generate the current `lazy-lock.json` only after the tested update path is available, and track it as known-good recovery evidence.

On a new-machine fingerprint with no successful state, schedule one latest-first plugin update after Lazy finishes its missing-plugin bootstrap. It must use the same lock/state path as manual updates, remain non-blocking in an interactive editor, and become blocking under headless bootstrap. Ordinary starts must not update plugins automatically after that first successful resolution.

**Step 5: Run focused/all specs, syntax, and isolated health**

```bash
NVIM_LOG_FILE=/private/tmp/nvim-plan-health.log \
  nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -c "checkhealth nv_ide" -c "qa!"
```

All commands must exit 0; health may report optional missing executables but must not throw.

**Step 6: Commit**

```bash
git add .gitignore lazy-lock.json lua/config/lazy.lua lua/nv_ide tests/headless/update_rollback_spec.lua tests/headless/health_spec.lua
git commit -m "feat(toolchain): add rollback and health"
```

## Task 7: Repair formatter and linter policy

**Files:**

- Create: `tests/headless/lint_format_spec.lua`
- Modify: `lua/plugins/lint_and_format.lua`

**Step 1: Write failing policy tests**

Assert real nvim-lint identifiers `ansible_lint` and `golangcilint`, a complete custom kube-linter definition with executable/argv/parser behavior, Python availability-aware registration for ruff/flake8/mypy, `vue` filetype policy, Conform `lsp_format = 'fallback'`, and absence of mason-bridge.

**Step 2: Run the spec and confirm RED**

Expected failures must identify the current wrong names, stale Conform field, and inert bridge.

**Step 3: Implement the explicit policy**

Keep deliberate formatter/linter ordering. Use manifest/executable discovery for optional tools; do not derive behavior dynamically from Mason installation state.

**Step 4: Run focused/all specs and syntax compilation**

All commands must exit 0.

**Step 5: Commit**

```bash
git add lua/plugins/lint_and_format.lua tests/headless/lint_format_spec.lua
git commit -m "fix(tooling): repair lint and format policy"
```

## Task 8: Repair DAP specifications, adapter ownership, and lazy loading

**Files:**

- Create: `tests/headless/dap_spec.lua`
- Modify: `lua/plugins/dap.lua`
- Modify: `lua/plugins/lsp/lang/python.lua`
- Modify: `lua/plugins/lsp/lang/ruby.lua`
- Modify: `lua/plugins/lsp/lang/kotlin.lua`

**Step 1: Write failing DAP tests**

Assert that debug commands/keymaps trigger the main DAP plugin, persistent breakpoints is not eager, Python/Ruby keys/config belong to their nested plugin specs, Kotlin setup is consumed once, every adapter has one owner, Mason DAP does not auto-install, and Python resolution returns an absolute executable chosen in this order: selected environment, `VIRTUAL_ENV`, project environment, `python3`/`python` executable.

**Step 2: Run the spec and confirm RED**

Expected failures: malformed Python/Ruby specs, ignored Kotlin setup, LspAttach/eager load chain, and relative Python path.

**Step 3: Implement adapter composition and triggers**

Make the main DAP `config` consume adapter setup hooks. Keep filetype-specific adapters lazy while ensuring their commands and keys are available.

**Step 4: Run focused/all specs and syntax compilation**

All commands must exit 0.

**Step 5: Commit**

```bash
git add lua/plugins/dap.lua lua/plugins/lsp/lang tests/headless/dap_spec.lua
git commit -m "fix(dap): own and load adapters correctly"
```

## Task 9: Repair Overseer workflows with pure argument builders

**Files:**

- Create: `tests/headless/overseer_spec.lua`
- Create: `lua/overseer/template/user/builders.lua`
- Modify: `lua/overseer/template/user/mvn-workflow.lua`
- Modify: `lua/overseer/template/user/docker-compose.lua`
- Modify: `lua/overseer/template/user/gradle-workflow.lua`
- Modify: `lua/overseer/template/user/init.lua`

**Step 1: Write table-driven failing tests**

Cover Maven boolean `skip_test`, separate profile argv values, split extra args, `JAVA_HOME` in env, Docker `up`/`start` branches, `docker compose` with checked `docker-compose` fallback, Gradle callback on every failure, and a bounded async timeout.

**Step 2: Run the spec and confirm RED**

Expected failures must reproduce each current control-flow/argv defect.

**Step 3: Implement pure builders and thin Overseer templates**

Builders return `{ cmd, args, env }` without shell strings. Templates validate executables and always invoke callbacks exactly once.

**Step 4: Run focused/all specs and syntax compilation**

All commands must exit 0.

**Step 5: Commit**

```bash
git add lua/overseer/template/user tests/headless/overseer_spec.lua
git commit -m "fix(overseer): build reliable task argv"
```

## Task 10: Apply approved plugin ownership and UI consolidation

**Files:**

- Create: `tests/headless/plugin_ownership_spec.lua`
- Create: `tests/headless/snacks_spec.lua`
- Modify: `lua/plugins/comments.lua`
- Modify: `lua/plugins/editor.lua`
- Modify: `lua/plugins/ui.lua`
- Modify: `lua/plugins/lsp/lang/go.lua`
- Modify: `lua/plugins/lsp/lang/flutter.lua`
- Modify: `lua/plugins/coding.lua`
- Modify: `lua/plugins/git.lua`
- Modify: `lua/plugins/snacks.lua`
- Modify: `lua/config/options.lua`
- Modify: `lua/util/ui.lua`

**Step 1: Write failing ownership tests**

Assert removal of todo-comments, gx, Dressing, mason-bridge, Go.nvim/guihua, and direct nvim-web-devicons ownership. Assert mini.icons initializes and calls the compatibility shim before icon consumers. Assert Leap/clangd extensions remain active, tiny diagnostics/hlslens remain, and hlargs is enabled only when semantic-token parameter highlighting is unavailable.

Evaluate every remaining plugin specification and assert it declares `event`, `ft`, `cmd`, `keys`, or an intentional eager marker (`lazy = false`/startup priority). Maintain an explicit allowlist only for Lazy imports and dependency-only fragments that cannot be loaded independently.

Assert representative Go workflow registrations remain for gopls, format, lint, Neotest-Go, and DAP-Go before accepting Go.nvim removal.

**Step 2: Write failing Snacks tests**

Assert valid separate top-level scratch/scroll/statuscolumn overrides, one `<leader>sb` mapping, distinct Gitsigns/Unified mappings, executable-aware external actions with actionable notifications, no copied default schema sentinels, and no second `vim.opt.statuscolumn` owner.

**Step 3: Run both specs and confirm RED**

Expected failures: the approved removal candidates and duplicated/mis-shaped UI configuration remain.

**Step 4: Implement removals and consolidation**

Reduce Snacks to deliberate overrides without removing requested features. Delete `lua/util/ui.lua` statuscolumn code only after a reference search proves it unused; preserve unrelated fold helpers. Keep Flutter's plugin declaration filetype-bound to `dart` after verifying its setup still executes correctly.

**Step 5: Run focused/all specs, syntax, and isolated Snacks health**

The isolated health command must load the locked Snacks plugin state without mutating the live installation. All tests must pass.

**Step 6: Commit**

```bash
git add lua tests/headless/plugin_ownership_spec.lua tests/headless/snacks_spec.lua
git commit -m "refactor(ui): consolidate plugin ownership"
```

## Task 11: Finish privacy, lazy boundaries, portability, and API modernization

**Files:**

- Create: `tests/headless/privacy_loading_spec.lua`
- Create: `tests/headless/deprecated_api_spec.lua`
- Modify: `lua/plugins/ai.lua`
- Modify: `lua/plugins/autocompletion.lua`
- Modify: `lua/plugins/lsp/lang/clojure.lua`
- Modify: `lua/plugins/lsp/lang/flutter.lua`
- Modify: `lua/plugins/lsp/lang/java.lua`
- Modify: `lua/config/autocmds.lua`
- Modify: every Lua file identified by the deprecated-API test
- Modify: `dotfiles/.zshrc`
- Modify: `dotfiles/.zprofile`

**Step 1: Write failing privacy/loading tests**

Assert CodeCompanion error-level logging, `send_code = false`, CodeCompanion's current per-project configuration/trust mechanism enabled only after explicit project trust, no credential values in configuration/health, LuaSnip loader setup inside `config`, Flutter only on `dart`, and Clojure structural tools only on Clojure/Fennel filetypes.

**Step 2: Write failing portability/API tests**

Scan executable Lua for `vim.loop`, deprecated diagnostic goto calls, deprecated `vim.tbl_flatten`, `/Users/sebastian`, `/home/seba`, forced `/bin/zsh`, and literal `~/.config/nvim`. Allow personal paths only in documentation fixtures explicitly named by the test.

Assert Java runtime/lombok discovery uses environment, `vim.fn.exepath`, and `stdpath` without fixed asdf versions.

**Step 3: Run both specs and confirm RED**

Expected failures must list every current match before implementation.

**Step 4: Implement the accepted boundaries**

Move loader calls into plugin `config`, replace deprecated APIs with Neovim 0.12 equivalents, and make shell fragments portable/opt-in without overwriting a user's full shell configuration.

**Step 5: Run focused/all specs and syntax compilation**

All commands must exit 0.

**Step 6: Commit**

```bash
git add lua dotfiles tests/headless/privacy_loading_spec.lua tests/headless/deprecated_api_spec.lua
git commit -m "refactor: modernize portable loading paths"
```

## Task 12: Add documentation, clean-XDG smoke tests, and macOS/Linux CI

**Files:**

- Create: `tests/headless/bootstrap_smoke.lua`
- Create: `tests/headless/no-profile.sh`
- Create: `.github/workflows/neovim.yml`
- Modify: `README.md`

**Step 1: Write the failing bootstrap smoke test**

The script must create a temporary HOME/XDG tree, copy the configuration, disable access to the live user state, and support `preflight`, `representative`, and `full` modes. It must assert the single complete manifest, command registration, isolated startup, LSP composition, mappings, health, and no background privilege escalation.

Run `tests/headless/no-profile.sh preflight`. Expected RED: command/script behavior and CI workflow are not implemented.

**Step 2: Implement smoke modes and CI**

The pull-request matrix on `ubuntu-latest` and `macos-latest` runs Lua syntax, all headless specs, preflight, representative Mason/parser install, `checkhealth nv_ide`, and `checkhealth snacks`. A scheduled/manual job runs the applicable full declaration with caches keyed by OS, lockfile, and manifest fingerprint.

**Step 3: Rewrite README installation and recovery sections**

Document minimal prerequisites for Homebrew and Ubuntu, HTTPS clone, first startup, full automatic ownership, `ToolchainInstall`, `ToolchainRepair`, `ToolchainUpdate`, health, rollback, local/SSH clipboard, and the no-unattended-sudo rule. Remove the recipe that overwrites `.zshrc` or creates a Python environment inside the config repository.

**Step 4: Run preflight and all local verification**

```bash
NVIM_LOG_FILE=/private/tmp/nvim-plan-bootstrap.log tests/headless/no-profile.sh preflight
```

Run all headless specs and syntax compilation. Both platforms' workflow YAML must parse through a Ruby or Python YAML parser available in CI; local absence of a parser is reported, not silently skipped.

**Step 5: Commit**

```bash
git add README.md tests/headless .github/workflows/neovim.yml
git commit -m "ci: verify portable Neovim bootstrap"
```

## Task 13: Final verification and review

**Files:**

- Modify only files required to address verified review findings.

**Step 1: Run the full local verification set**

```bash
NVIM_LOG_FILE=/private/tmp/nvim-plan-tests.log \
  nvim --clean --headless -u tests/minimal_init.lua -i NONE -l tests/headless/run.lua

NVIM_LOG_FILE=/private/tmp/nvim-plan-syntax.log \
  nvim --clean --headless -u NONE -i NONE \
  -c "lua for _,f in ipairs(vim.fn.glob('**/*.lua', false, true)) do assert(loadfile(f), f) end" \
  -c "qa!"

NVIM_LOG_FILE=/private/tmp/nvim-plan-bootstrap.log tests/headless/no-profile.sh preflight
```

**Step 2: Audit invariants**

Search for duplicate Mason/parser declarations, competing install APIs, profile terms in runtime code, private LSP watcher mutation, deprecated APIs, machine paths, global Enter/Backspace Leap mappings, duplicate plugin ownership, and secret values.

**Step 3: Request spec and code-quality review**

Review the complete diff against `docs/superpowers/specs/2026-07-31-neovim-self-healing-configuration-design.md` and this plan. Fix Critical and Important findings with focused red/green tests and rerun all verification.

**Step 4: Confirm repository state**

`git status --short`, `git diff --check`, and `git log --oneline` must show only intentional tracked work and no generated logs/state.

If review fixes changed tracked files, commit them with a focused Conventional Commit before integration. Record a five-run warm headless startup sample and compare its median with the pre-change 71–82 ms observation; report the measurement without hiding installer work behind the benchmark.

**Step 5: Integrate only after all evidence passes**

Fast-forward or merge the verified `codex/nvim-plan-implementation` branch into the live Neovim repository's `master` branch. Do not mutate live plugin/data/state directories during the merge.
