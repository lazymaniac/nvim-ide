# Self-Healing Neovim Configuration Design

Date: 2026-07-31

## Scope

This design implements the decisions accepted in the reviewed Neovim configuration plan. The configuration remains a complete polyglot IDE. It does not introduce profiles, does not reduce the declared language/tool inventory, and preserves automatic discovery and installation during startup.

The work repairs integration correctness, makes first-run behavior safe and observable, and gives every integration a single owner.

## Non-negotiable decisions

- Install the complete applicable user-owned toolchain; there are no selectable profiles.
- Keep startup-time installation for missing Lazy plugins, Mason packages, and Tree-sitter parsers.
- Never run unattended `sudo` or mutate system packages from a background startup task.
- Prefer current stable plugin versions. Keep a last-known-good Lazy lock snapshot for rollback.
- Use `mason-tool-installer.nvim` as the only Mason installation owner.
- Keep explicit Conform and `nvim-lint` behavior tables; remove `mason-bridge.nvim`.
- Repair and retain `clangd_extensions.nvim`.
- Activate Leap using explicit `s`/`S` mappings; never reserve Enter or Backspace globally.
- Remove `todo-comments.nvim`, `gx.nvim`, Dressing, Go.nvim, and `guihua.lua` after their replacement behavior is tested.
- Keep tiny inline diagnostics and hlslens. Use `hlargs.nvim` only when semantic-token parameter highlighting is unavailable.
- Use Snacks as the single statuscolumn owner and retain intentional Snacks features.
- Restore Tree-sitter `<C-Space>` growth and visual `<BS>` shrink behavior.
- Preserve native quickfix Enter, single-click selection, and double-click activation.
- Support local macOS/Linux clipboard providers and OSC 52 for SSH sessions.

## Architecture

### Toolchain ownership

One internal declaration, `lua/nv_ide/toolchain/manifest.lua`, describes the complete inventory. It is not a user-facing profile system. It exists to eliminate duplicate lists and to let installation, health, and CI inspect the same data.

Ownership is strict:

| Resource | Owner | Startup behavior |
|---|---|---|
| Plugins | Lazy | Bootstrap/install missing plugins and check for updates |
| LSP/DAP/formatter/linter tools | mason-tool-installer | Install missing applicable packages once per discovery cycle |
| Tree-sitter parsers | toolchain Tree-sitter adapter | Asynchronously install missing parsers; wait in explicit/headless commands |
| OS packages and language runtimes | Operator | Health reports exact missing prerequisites; no unattended privilege escalation |
| LSP configuration and enablement | central LSP registry | Compose and register once, with explicit external ownership exceptions |
| Formatter/linter policy | Conform and nvim-lint tables | Deliberate filetype-specific ordering and fallback |

### Startup flow

1. `init.lua` calls the early environment adapter before Lazy and ordinary options.
2. The adapter adds existing portable binary directories to `PATH` without starting a login shell and selects OSC 52 when running over SSH and no provider was supplied.
3. Lazy bootstraps itself, installs missing plugins, and loads the toolchain orchestrator.
4. The orchestrator computes a manifest/platform fingerprint and performs cheap local discovery.
5. A state lock prevents concurrent Neovim processes from running installers.
6. mason-tool-installer receives the complete deduplicated package list with startup installation enabled.
7. The Tree-sitter adapter asynchronously requests only missing parsers.
8. Completion and failures are recorded atomically under `stdpath('state')/nv_ide/toolchain`.
9. A single notification summarizes failures while leaving the editor usable.

Startup work is skipped only when the fingerprint is unchanged, the debounce window is valid, and verification finds nothing missing. A manifest change or newly missing dependency invalidates the cached success.

### Explicit commands

- `:ToolchainInstall[!]` discovers and installs missing plugins, Mason packages, and parsers. Bang/headless mode waits and verifies.
- `:ToolchainRepair[!]` bypasses debounce and retries missing or failed resources.
- `:ToolchainUpdate[!]` snapshots the current Lazy lockfile, resolves current allowed plugin versions, updates parsers, runs smoke checks, and restores the snapshot if validation fails.

No command installs privileged system packages. Health output supplies platform-specific remediation commands.

### Rollback

`lazy-lock.json` is tracked as the repository's known-good evidence. Fresh installation still resolves current allowed versions; it is not forced to restore a stale snapshot. Before an intentional update, the orchestrator writes a timestamped copy under XDG state. If validation fails, it restores the previous lockfile and invokes a blocking Lazy restore.

Exact Mason and parser downgrades are not guaranteed by their upstream managers. State records observed before/after versions and reports that limitation.

### LSP registry

The central registry:

1. Builds protocol and Blink capabilities.
2. Deep-merges shared and per-server configuration.
3. Executes named or wildcard setup hooks.
4. Treats a successful ownership hook as externally managed.
5. Removes internal metadata before registration.
6. Calls `vim.lsp.config(server, config)` once.
7. Calls `vim.lsp.enable(server)` once for centrally owned enabled servers.

`haskell-tools.nvim` owns HLS. Java, Rust, and other integrations that own their server explicitly use the same ownership mechanism. The registry is responsible for gopls, clangd, and vtsls composition, while clangd's hook loads `clangd_extensions.nvim` through a real trigger.

LSP keymaps are derived per client/buffer from an immutable base table. Dynamic capability registration reapplies mappings to all buffers attached to the client. Method checks include the buffer number, and position parameters use the client's encoding.

### Interaction behavior

When a Tree-sitter parser starts for a buffer, buffer-local mappings provide:

- Normal/visual `<C-Space>`: select the parent node using `vim.treesitter.select()`.
- Visual `<BS>`: select the child node.

Leap owns explicit `s` and `S` mappings only. Removing its deprecated repeat-key call returns Enter and Backspace to native contexts, including quickfix. Native `[q` and `]q` mappings remain the quickfix navigation authority.

### Health

`lua/nv_ide/health.lua` exposes a pure `collect(probe)` layer and a `check()` renderer. It reports:

- OS, architecture, and Neovim version;
- required compiler, archive, Git, curl, and Tree-sitter CLI prerequisites;
- Mason packages and Tree-sitter parsers;
- language runtimes used by the complete inventory;
- file watcher/inotify state;
- external terminal mappings;
- local clipboard provider or SSH OSC 52/tmux constraints;
- AI backends, CLI agents, and only credential-presence booleans.

It never displays credential values.

### Integration repairs

- Conform uses `lsp_format = 'fallback'`; nvim-lint uses real identifiers and a defined kube-linter adapter.
- DAP loads from debug commands/keymaps, consumes language adapter hooks, and resolves Python to an executable absolute path.
- Overseer templates delegate argv/env construction to pure functions covered by table-driven tests.
- CodeCompanion defaults to error-level logging and does not send code by default.
- LuaSnip, Flutter, and structural-editing plugins respect their intended event/filetype boundaries.
- Deprecated Neovim APIs are removed while keeping the Neovim 0.12 baseline.

### UI/plugin consolidation

Snacks keeps only deliberate overrides. Its `scratch`, `scroll`, and `statuscolumn` options remain separate and valid. Duplicate mappings are eliminated, and Snacks owns statuscolumn rendering.

`mini.icons` initializes early and provides the web-devicons compatibility shim before `nvim-web-devicons` is removed. Dressing and gx are removed only after Snacks/native replacements are asserted. Go.nvim/guihua are removed after representative Go LSP, format, lint, test, and debug registrations pass.

## Verification strategy

A dependency-free headless harness runs with `nvim --clean` and isolated XDG paths. Tests assert behavior, not plugin mocks. External operations are isolated behind injected probes/adapters while real composition, state, mapping, and argument-building logic is exercised.

Fast CI runs on macOS and Ubuntu and covers syntax, unit/headless behavior, representative installs, startup, health, and smoke validation. A scheduled job exercises the full applicable declaration.

## Success criteria

- The complete inventory is default and contains no profiles.
- New and existing machines discover missing user-owned dependencies at startup.
- Concurrent starts do not launch competing installation work.
- gopls, clangd, and vtsls receive their intended settings and each server has one owner.
- Watchers are not globally disabled.
- Tree-sitter and quickfix interactions match the accepted mappings.
- Health explains every missing dependency without exposing secrets.
- macOS, Linux, and SSH clipboard paths are diagnosed and selected correctly.
- Snacks is the only statuscolumn owner.
- Tests and CI cover the repaired integration boundaries.
