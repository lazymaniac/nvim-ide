# Production IDE Correctness and Integrations Design

Date: 2026-08-01

## Goal

Repair the confirmed editor-facing correctness, safety, project-awareness, and lazy-loading defects in NV-IDE, then add MiniSurround, Diffview+, Just, Delta, and Ruff without replacing the existing IDE stack or broadening the custom toolchain architecture.

## Scope boundary

This work changes editor behavior, plugin declarations, project discovery, lint/format policy, and the minimum dependency inventory needed by the requested tools.

It deliberately does **not** change:

- Lazy bootstrap or first-run update semantics;
- toolchain update, snapshot, or rollback behavior;
- process-lock architecture or contention behavior;
- early `PATH` hydration or version-manager precedence;
- GitHub Actions reference pinning;
- tracked shell bootstrap behavior;
- general health-report parsing or CI failure policy;
- language profiles, the complete-inventory policy, or unrelated plugin consolidation.

`lua/nv_ide/toolchain/manifest.lua`, health metadata, and related tests may change only to declare Ruff, Just, Delta, or a dependency required by the selected Diffview implementation.

## Non-negotiable decisions

- Keep Neovim 0.12 as the minimum editor version.
- Keep Lazy, Mason, native Neovim LSP, Blink, Conform, nvim-lint, nvim-dap, Neotest, Overseer, Snacks, Gitsigns, Unified, and LazyGit as the owning integrations.
- Preserve format-on-save as disabled by default. The global and buffer-local toggles must become functional.
- Preserve `[d` and `]d` for conventional diagnostic navigation.
- Never execute repository-controlled lint or task configuration automatically until the project directory is trusted through `vim.secure.read()`.
- Prefer project-local executables and repository configuration over editor-global assumptions when selecting test and debug commands.
- Use `dlyongemallo/diffview-plus.nvim`, the maintained Diffview fork, behind the standard Diffview command API.
- Use `ys`, `ds`, and `cs` for MiniSurround. Disable Markdown-local mappings that claim `ds` and `cs`.
- Use Ruff as the only automatic Python linter, Pyright as the Python type LSP, and the existing Black plus docformatter sequence for Python formatting.
- Do not mutate global Git configuration. Delta is configured only in the tracked LazyGit configuration.
- Justfiles are user-triggered through Overseer; opening a project never runs a recipe.

## Architecture

### Shared project context

Add a small `lua/nv_ide/project.lua` module that owns project-root and executable discovery used by tests, debuggers, and automatic linting.

The module exposes pure or dependency-injected helpers for:

- deriving the nearest normalized root from the current buffer and a marker list;
- testing whether a file is inside a root without string-prefix mistakes;
- choosing an executable from an activated environment, project-local path, then ambient `PATH`;
- locating common JavaScript package-manager, launch, and test configuration markers, including hoisted tooling up to the containing Git boundary;
- querying directory trust with `vim.secure.read(root)` and caching only a positive decision for the current process.

Callers pass a buffer or path at execution time. No helper captures `vim.fn.getcwd()` while a plugin specification is evaluated.

### Formatting ownership

Create `lua/util/format.lua` as the sole adapter between core options/keymaps and Conform.

It provides:

- `formatexpr()` delegating to `require('conform').formatexpr()`;
- `enabled(bufnr)` honoring a buffer override before the global default;
- `toggle(buffer_local)` for the existing `<leader>uf` and `<leader>uF` mappings;
- `format_on_save(bufnr)` returning Conform's fallback-LSP options only when formatting is enabled.

Global state remains `vim.g.autoformat = false`. A buffer override uses `vim.b[bufnr].autoformat`; clearing the override restores the global policy. Conform receives a function for `format_on_save`, not an unconditional formatter invocation.

The formatter table gains aliases for `sh`, JSX/TSX, Svelte, JSONC, ERB, CMake, and XML where an already-declared formatter exists. Alternative formatters use `stop_after_first`; deliberate transforms such as Black followed by docformatter remain sequential. No new formatter package is introduced solely to fill Dockerfile support.

### Lint policy and trust

Automatic linting moves from `BufEnter` plus `BufWritePost` to a single named-augroup `BufWritePost` handler.

The handler:

1. resolves the buffer path and project root;
2. asks Neovim's trust database about that directory;
3. returns without executing a linter when trust is denied or unavailable;
4. selects the exact linter set for the buffer and path;
5. calls `lint.try_lint()` once with that set and the resolved root as its process `cwd`.

Policy is deterministic:

- Python uses Ruff only;
- ordinary YAML uses yamllint, while files under `.github/workflows/` additionally use actionlint;
- Trivy and other project-wide security scanners are removed from per-buffer lint lists and remain explicit Overseer/terminal work;
- slow type or project analyzers do not run merely because a buffer receives focus.

Ruff replaces Pylint in the Mason inventory. JavaScript formatter/linter daemons are required to resolve project-local Prettier/ESLint packages rather than silently using daemon-bundled versions; `eslint_d` treats a missing local ESLint as a failure.

### Project-aware tests and debugging

Neotest Python uses the same executable-resolution policy as Python DAP: activated selector environment, project `.venv`, then `python3`. Jest no longer hardcodes `custom.jest.config.ts` or the editor's global CWD; the adapter resolves the nearest package root and lets Jest discover its standard configuration unless a detected config is supplied.

Kotlin DAP computes `projectRoot` when a session launches. It uses the nearest Gradle/Maven/Kotlin project root and never appends `/app`. Host and port remain overridable inputs, with localhost and 5005 as attach defaults.

JavaScript DAP retains generic launch-current-file and attach-process fallbacks. The built-in launch provider is narrowed to the active package or containing workspace `.vscode/launch.json` and filters unsupported adapter types; a second provider owns framework entries, so workspace configurations appear exactly once. Framework-specific Mocha, Jest, Karma, or Jasmine entries are registered only when a local or hoisted executable exists, or when a detected config can be launched through the detected package manager. Duplicate fields and global package assumptions are removed.

TypeScript's move-file command validates command arguments, request errors, response shape, and `body.files` before opening selection UI. Invalid responses produce a concise warning instead of a Lua exception. Rust enables inlay hints for the attached buffer only.

### Java and Mason paths

Java discovery moves from module evaluation into the Java filetype-triggered options/configuration boundary. External `asdf` and macOS Java-home probes receive a bounded timeout and return a descriptive discovery error.

JDTLS derives its cache identity from the normalized absolute project root: a readable basename plus a short SHA-256 suffix. Distinct same-named repositories therefore cannot share a workspace, while repeated launches of one root remain stable.

Sonar analyzer paths and Java debug/test bundles resolve the Mason root with `vim.env.MASON or vim.fs.joinpath(vim.fn.stdpath('data'), 'mason')`, using the existing utility rather than expanding an unset `$MASON` variable.

### Interaction and startup correctness

Tree-sitter conditional motions move from `[d` and `]d` to `[C` and `]C`. Diagnostic mappings retain the lowercase pair. A test checks the combined core and Lazy key declarations for ownership conflicts.

Terminal mappings and options use a dedicated augroup and `nvim_create_autocmd`; reloading config cannot clear another plugin's `TermOpen` handlers. The default terminal mapping opens the user's ordinary shell through Snacks. Zellij remains a separate optional tool mapping.

The statusline consults `package.loaded.dap` before asking for debug status. Merely rendering the statusline cannot load nvim-dap.

Default Snacks file and explorer sources respect ignore files and do not follow symlinks. A separate explicitly named “all files” mapping enables ignored-file search without changing the safe default.

Base46 cache loading moves to `lua/nv_ide/cache.lua`. The loader has an explicit allowlist covering the theme color/terminal caches plus configured Base46 integrations, sorts names, requires regular files inside the configured cache directory, and wraps execution with an actionable cache-regeneration error. Direct iteration over arbitrary directory entries is removed from `init.lua`.

### Requested integrations

#### MiniSurround

Add `nvim-mini/mini.surround` with a `VeryLazy` boundary and explicit mappings:

- `ys`: add surrounding in normal/operator use;
- `ds`: delete surrounding;
- `cs`: replace surrounding.

Search/highlight/update helper mappings not requested by this design remain disabled. Markdown rendering's local `ds`/`cs` behavior is disabled so one owner exists in every buffer.

#### Diffview+

Add `dlyongemallo/diffview-plus.nvim`, lazy-loaded by the standard Diffview commands. Existing Mini Icons provides icon compatibility.

- `<leader>gv` opens the repository diff view;
- `<leader>gh` opens history for the current file;
- standard `:DiffviewClose`, `:DiffviewToggleFiles`, `:DiffviewFocusFiles`, and `:DiffviewRefresh` commands remain available.

Gitsigns continues to own hunk operations and `<leader>gd`; Unified continues to own its single-file diff mapping. The new mappings must not overlap either integration.

#### Just

Declare `just` as an optional external executable with health remediation and README installation guidance. Overseer's builtin provider remains the execution UI through the existing `<leader>rr` mapping. No recipe runs automatically and no separate Just plugin is added.

#### Delta

Declare `delta` as an optional external executable with health remediation and README installation guidance. The tracked LazyGit configuration uses Delta for colorized, non-paging diffs. Until Delta is installed, health reports the missing pager and LazyGit diff rendering is the only affected workflow. The Neovim configuration never writes `~/.gitconfig`; command-line Git users can opt in separately.

#### Ruff

Replace the Mason `pylint` declaration with `ruff`. nvim-lint owns Ruff diagnostics, Pyright owns type diagnostics, and Conform retains Black/docformatter formatting. This avoids duplicate host-dependent Python diagnostics and keeps responsibilities explicit.

## Error handling

- A denied/untrusted project silently skips automatic linting and can be trusted explicitly with Neovim's normal trust workflow.
- Missing optional Just or Delta executables appear in health output but do not prevent Neovim startup.
- Missing project-local test/debug tools omit only the affected framework configuration; generic adapters remain available.
- Invalid TypeScript LSP responses warn and return without opening incomplete UI.
- Java discovery timeouts report the failed probe and do not hang startup.
- Invalid Base46 cache content stops at the named cache entry with a regeneration instruction rather than executing later arbitrary entries.
- Missing Ruff is reported by the existing Mason/toolchain health path; automatic linting does not fall back to whatever Python linters happen to be installed globally.

## Verification strategy

All behavior changes follow red-green-refactor. Existing headless suites are extended rather than replaced:

- `lint_format_spec.lua`: missing format module regression, global/buffer toggles, disabled default, formatter aliases and alternatives, trusted save-only lint routing, Ruff-only Python, workflow-only actionlint, and no automatic Trivy;
- `interaction_spec.lua`: final diagnostic/Tree-sitter key ownership, isolated terminal autocmds, shell fallback, and MiniSurround/Markdown mapping ownership;
- `dap_spec.lua`: project-time Kotlin roots, project-aware adapter selection, and statusline DAP lazy loading;
- `lsp_registry_spec.lua`: defensive TypeScript move-file responses;
- `privacy_loading_spec.lua`: deferred Java discovery and buffer-local Rust inlay hints;
- `deprecated_api_spec.lua`: bounded Java probes and collision-free JDTLS identities;
- `snacks_spec.lua`: safe default picker boundaries, explicit all-files search, and non-overlapping Diffview mappings;
- `plugin_ownership_spec.lua`: MiniSurround and Diffview+ lazy-loading boundaries;
- `manifest_spec.lua` and `health_spec.lua`: Ruff ownership plus optional Just/Delta reporting;
- a focused cache-loader spec: deterministic allowlisted Base46 execution and actionable failures;
- clean-XDG startup/preflight: real config composition after the unit/headless suite.

The lockfile is updated through the repository's normal resolved-plugin workflow after plugin declarations pass local tests. The final verification includes Lua compilation, the complete headless suite, isolated preflight, a fresh startup smoke test, and `git diff --check`.

## Success criteria

- `gq`, global autoformat toggle, and buffer autoformat toggle work without missing modules; autoformat remains off by default.
- Diagnostic navigation and Tree-sitter motions have distinct final mappings.
- Opening or saving an untrusted repository cannot automatically execute its lint toolchain.
- Python lint output is deterministic and owned by Ruff.
- Tests and debuggers resolve roots and executables from the active project rather than editor startup CWD.
- Same-named Java repositories receive distinct JDTLS workspaces.
- Statusline rendering and Java plugin-spec evaluation do not defeat lazy loading.
- Default file search respects ignore and symlink boundaries.
- Base46 cache loading is deterministic and constrained.
- MiniSurround and Diffview+ load only at their declared boundaries and have non-conflicting mappings.
- Just recipes are available through Overseer when Just is installed.
- LazyGit uses Delta when the declared optional dependency is installed, without modifying global Git state.
- All changed behavior has a regression test and the complete isolated verification is green.
