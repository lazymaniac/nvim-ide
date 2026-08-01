# Requested IDE Integrations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add MiniSurround, Diffview+, Ruff, Just, and Delta with explicit ownership, lazy-loading boundaries, dependency health, documentation, and locked plugin revisions.

**Architecture:** MiniSurround and Diffview+ are ordinary Lazy specs with non-overlapping mappings. Ruff is Mason-managed and remains the single Python linter selected by the editor-correctness plan. Just and Delta are optional, operator-installed prerequisites exposed through existing Overseer and LazyGit workflows.

**Tech Stack:** Neovim 0.12 Lua, lazy.nvim, MiniSurround, Diffview+, Mason, nvim-lint, Overseer, LazyGit, headless Lua test harness.

**Prerequisite:** Complete `2026-08-01-editor-correctness.md` first so `lint_and_format.lua` already owns deterministic Ruff routing.

## File map

- `lua/plugins/coding.lua`: MiniSurround declaration and mappings.
- `lua/plugins/lsp/lang/markdown.lua`: Markdown-local surround ownership.
- `lua/plugins/git.lua`: Diffview+ declaration, commands, and keys.
- `lua/nv_ide/toolchain/manifest.lua`: Ruff and system dependency inventory.
- `lua/nv_ide/health.lua`: Git version metadata plus Just/Delta remediation.
- `dotfiles/.config/lazygit/config.yml`: Delta-only LazyGit pager configuration.
- `README.md`: operator installation and behavior for Just and Delta.
- `tests/headless/*_spec.lua`: mapping, ownership, manifest, health, and tracked-config regressions.
- `lazy-lock.json`: resolver-generated MiniSurround and Diffview+ revisions.

---

### Task 1: Give MiniSurround exclusive mapping ownership

**Files:**
- Modify: `tests/headless/interaction_spec.lua`
- Modify: `tests/headless/plugin_ownership_spec.lua`
- Modify: `lua/plugins/coding.lua`
- Modify: `lua/plugins/lsp/lang/markdown.lua`

- [ ] **Step 1: Write the failing mapping and load-boundary tests**

Use the existing `plugin()` helper in `interaction_spec.lua`, then add:

```lua
h.it('gives MiniSurround sole ownership of ys, ds, and cs', function()
  local surround = plugin(dofile('lua/plugins/coding.lua'), 'nvim-mini/mini.surround')
  h.deep_equal(surround.opts.mappings, {
    add = 'ys',
    delete = 'ds',
    find = '',
    find_left = '',
    highlight = '',
    replace = 'cs',
    suffix_last = '',
    suffix_next = '',
  })

  local markdown = plugin(dofile('lua/plugins/lsp/lang/markdown.lua'), 'tadmccorkle/markdown.nvim')
  h.equal(markdown.opts.mappings.inline_surround_delete, false)
  h.equal(markdown.opts.mappings.inline_surround_change, false)
end)
```

Add to `plugin_ownership_spec.lua`:

```lua
h.it('loads MiniSurround only at its explicit stable boundary', function()
  local surround = plugin(dofile 'lua/plugins/coding.lua', 'nvim-mini/mini.surround')
  h.truthy(surround, 'MiniSurround is missing')
  h.equal(surround.version, '*')
  h.equal(surround.event, 'VeryLazy')
end)
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/interaction_spec.lua \
  tests/headless/plugin_ownership_spec.lua
```

Expected: FAIL with `plugin spec not found: nvim-mini/mini.surround` or `MiniSurround is missing`.

- [ ] **Step 3: Add MiniSurround and disable Markdown conflicts**

Add this standalone spec to `lua/plugins/coding.lua`:

```lua
{
  'nvim-mini/mini.surround',
  version = '*',
  event = 'VeryLazy',
  opts = {
    mappings = {
      add = 'ys',
      delete = 'ds',
      find = '',
      find_left = '',
      highlight = '',
      replace = 'cs',
      suffix_last = '',
      suffix_next = '',
    },
  },
},
```

Change only the conflicting Markdown mappings:

```lua
inline_surround_delete = false,
inline_surround_change = false,
```

Keep Markdown's `gs` and `gss` mappings.

- [ ] **Step 4: Run the focused tests and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/interaction_spec.lua \
  tests/headless/plugin_ownership_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit the isolated integration**

```sh
git add tests/headless/interaction_spec.lua tests/headless/plugin_ownership_spec.lua lua/plugins/coding.lua lua/plugins/lsp/lang/markdown.lua
git commit -m "feat: add MiniSurround mappings"
```

### Task 2: Add Diffview+ behind the standard command API

**Files:**
- Modify: `tests/headless/plugin_ownership_spec.lua`
- Modify: `tests/headless/snacks_spec.lua`
- Modify: `lua/plugins/git.lua`

- [ ] **Step 1: Write failing command and mapping tests**

Add to `plugin_ownership_spec.lua`:

```lua
h.it('lazy-loads Diffview+ through its standard command API', function()
  local diffview = plugin(dofile 'lua/plugins/git.lua', 'dlyongemallo/diffview-plus.nvim')
  h.truthy(diffview, 'Diffview+ is missing')
  h.equal(diffview.version, '*')
  h.equal(diffview.main, 'diffview')
  h.deep_equal(diffview.cmd, {
    'DiffviewOpen',
    'DiffviewFileHistory',
    'DiffviewClose',
    'DiffviewToggleFiles',
    'DiffviewFocusFiles',
    'DiffviewRefresh',
  })
end)
```

Extend the existing Gitsigns/Unified mapping test in `snacks_spec.lua`:

```lua
local diffview = plugin(git, 'dlyongemallo/diffview-plus.nvim')
local open = mapping(diffview, '<leader>gv')
local history = mapping(diffview, '<leader>gh')
h.equal(#open, 1)
h.equal(open[1][2], '<cmd>DiffviewOpen<cr>')
h.equal(#history, 1)
h.equal(history[1][2], '<cmd>DiffviewFileHistory %<cr>')
h.falsy(open[1][1] == '<leader>gd' or open[1][1] == '<leader>gU')
h.falsy(history[1][1] == '<leader>gd' or history[1][1] == '<leader>gU')
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/plugin_ownership_spec.lua \
  tests/headless/snacks_spec.lua
```

Expected: FAIL with `Diffview+ is missing`.

- [ ] **Step 3: Add the command-lazy Diffview+ spec**

Add to `lua/plugins/git.lua`:

```lua
{
  'dlyongemallo/diffview-plus.nvim',
  version = '*',
  main = 'diffview',
  cmd = {
    'DiffviewOpen',
    'DiffviewFileHistory',
    'DiffviewClose',
    'DiffviewToggleFiles',
    'DiffviewFocusFiles',
    'DiffviewRefresh',
  },
  keys = {
    { '<leader>gv', '<cmd>DiffviewOpen<cr>', desc = 'Diff view [gv]' },
    { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'File history [gh]' },
  },
  opts = {},
},
```

`main = 'diffview'` is required because the repository basename differs from the official `require('diffview').setup()` module.

- [ ] **Step 4: Run the focused tests and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/plugin_ownership_spec.lua \
  tests/headless/snacks_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit the plugin integration**

```sh
git add tests/headless/plugin_ownership_spec.lua tests/headless/snacks_spec.lua lua/plugins/git.lua
git commit -m "feat: add Diffview integration"
```

### Task 3: Manage Ruff and declare the companion prerequisites

**Files:**
- Modify: `tests/headless/manifest_spec.lua`
- Modify: `tests/headless/health_spec.lua`
- Modify: `lua/nv_ide/toolchain/manifest.lua`
- Modify: `lua/nv_ide/health.lua`

- [ ] **Step 1: Write failing manifest and health expectations**

In `expected_tools`, replace `'pylint'` with `'ruff'`. In `expected_prerequisites`, keep the surrounding records and use this exact order from Curl through LuaRocks:

```lua
{ id = 'curl', executables = { 'curl' }, required = true },
{ id = 'delta', executables = { 'delta' }, required = false },
{
  id = 'git',
  executables = { 'git' },
  required = true,
  version = {
    command = { 'git', '--version' },
    pattern = 'git version%s+(%d+%.%d+%.%d+)',
    minimum = '2.31.0',
  },
},
{ id = 'gzip', executables = { 'gzip' }, required = true },
{ id = 'just', executables = { 'just' }, required = false },
{ id = 'lua_package_manager', executables = { 'luarocks' }, required = true },
```

Add this test to `health_spec.lua`:

```lua
h.it('requires Diffview-compatible Git and reports optional Just and Delta', function()
  local health = require 'nv_ide.health'
  local probe = complete_probe {
    versions = { git = '2.30.9' },
    unsupported_versions = { git = true },
    unavailable = { just = true, delta = true },
  }
  local report = health.collect(probe)
  local git = find(report.prerequisites, 'git')
  local just = find(report.prerequisites, 'just')
  local delta = find(report.prerequisites, 'delta')

  h.falsy(git.available)
  h.equal(git.minimum_version, '2.31.0')
  h.falsy(just.required)
  h.falsy(just.available)
  h.falsy(delta.required)
  h.falsy(delta.available)
end)
```

Add this exact remediation test:

```lua
h.it('renders Git, Just, and Delta remediation exactly', function()
  local health = require 'nv_ide.health'
  local probe = complete_probe {
    os = 'Darwin',
    versions = { git = '2.30.9' },
    unsupported_versions = { git = true },
    unavailable = { just = true, delta = true },
  }
  local messages, reporter = {}, {}
  for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
    reporter[level] = function(message) messages[#messages + 1] = tostring(message) end
  end

  health.check(probe, reporter)
  local output = table.concat(messages, '\n')
  h.matches(output, 'Git 2.30.9 requires >= 2.31.0')
  h.matches(output, 'brew install git-delta')
  h.matches(output, 'brew install just')
end)
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/manifest_spec.lua \
  tests/headless/health_spec.lua
```

Expected: FAIL because the manifest still contains Pylint, lacks optional Just/Delta records, and has no Git version floor or exact remediation.

- [ ] **Step 3: Update the manifest and health metadata**

In `manifest.lua`, replace the Mason tool and use the same exact prerequisite order from Curl through LuaRocks:

```lua
'pydocstyle',
'ruff',
'rubocop',
```

```lua
{ id = 'curl', executables = { 'curl' }, required = true },
{ id = 'delta', executables = { 'delta' }, required = false },
{
  id = 'git',
  executables = { 'git' },
  required = true,
  version = {
    command = { 'git', '--version' },
    pattern = 'git version%s+(%d+%.%d+%.%d+)',
    minimum = '2.31.0',
  },
},
{ id = 'gzip', executables = { 'gzip' }, required = true },
{ id = 'just', executables = { 'just' }, required = false },
{ id = 'lua_package_manager', executables = { 'luarocks' }, required = true },
```

In `health.lua`, add `git = 'Git'` to the version-label table and add:

```lua
-- PREREQUISITE_FIXES.Darwin
delta = 'brew install git-delta',
just = 'brew install just',

-- PREREQUISITE_FIXES.Linux
delta = 'Debian/Ubuntu: install the release .deb from https://github.com/dandavison/delta/releases; Fedora: sudo dnf install git-delta; Arch: sudo pacman -S git-delta; Cargo: cargo install git-delta',
just = 'Debian 13/Ubuntu 24.04+: sudo apt install just; Fedora: sudo dnf install just; Arch: sudo pacman -S just; Cargo: cargo install just',
```

Give `complete_probe()` a supported default Git version:

```lua
or id == 'git' and '2.50.1'
```

- [ ] **Step 4: Run focused tests and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/manifest_spec.lua \
  tests/headless/health_spec.lua
```

Expected: all selected tests PASS with `0 failed` and the Mason package count remains unchanged.

- [ ] **Step 5: Commit dependency ownership**

```sh
git add tests/headless/manifest_spec.lua tests/headless/health_spec.lua lua/nv_ide/toolchain/manifest.lua lua/nv_ide/health.lua
git commit -m "feat: declare integration dependencies"
```

### Task 4: Configure Delta for LazyGit and document Just

**Files:**
- Modify: `tests/headless/snacks_spec.lua`
- Modify: `tests/headless/plugin_ownership_spec.lua`
- Modify: `dotfiles/.config/lazygit/config.yml`
- Modify: `README.md`

- [ ] **Step 1: Write the failing tracked-configuration test**

Add to `snacks_spec.lua`:

```lua
h.it('uses Delta only inside the tracked LazyGit configuration', function()
  local lazygit = read 'dotfiles/.config/lazygit/config.yml'
  h.matches(lazygit, 'pagers:')
  h.matches(lazygit, 'pager: delta --dark --paging=never')

  local source = {}
  for _, path in ipairs(vim.fn.glob('lua/**/*.lua', false, true)) do
    source[#source + 1] = read(path)
  end
  for _, path in ipairs(vim.fn.glob('lua/*.lua', false, true)) do
    source[#source + 1] = read(path)
  end
  local rendered = table.concat(source, '\n')
  h.falsy(rendered:find('git config', 1, true), 'Neovim must not mutate global Git configuration')
end)
```

Add this characterization test to `tests/headless/plugin_ownership_spec.lua`:

```lua
h.it('keeps Just recipes reachable through Overseer builtins', function()
  local overseer = plugin(dofile 'lua/plugins/async-tasks.lua', 'stevearc/overseer.nvim')
  h.truthy(overseer, 'Overseer is missing')

  local run
  for _, key in ipairs(overseer.keys or {}) do
    if key[1] == '<leader>rr' then run = key; break end
  end
  h.truthy(run, 'OverseerRun mapping is missing')
  h.equal(run[2], '<cmd>OverseerRun<cr>')

  local previous = package.loaded.overseer
  local configured
  package.loaded.overseer = { setup = function(opts) configured = opts end }
  local ok, err = xpcall(overseer.config, debug.traceback)
  package.loaded.overseer = previous
  if not ok then error(err, 0) end

  h.deep_equal(configured.templates, { 'builtin', 'user' })
end)
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/snacks_spec.lua \
  tests/headless/plugin_ownership_spec.lua
```

Expected: FAIL because `pagers:` and the Delta command are absent.

- [ ] **Step 3: Add the pager and operator documentation**

In the opening `## Requirements` paragraph, change the Git prerequisite to `Git 2.31 or newer` so the README matches health and Diffview+.

Change the tracked LazyGit `git:` block to:

```yaml
git:
  log:
    showWholeGraph: true
  disableForcePushing: true
  pagers:
    - pager: delta --dark --paging=never
```

Insert the following section immediately before the existing `## Install` heading:

```markdown
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
```

- [ ] **Step 4: Run the focused test and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/snacks_spec.lua \
  tests/headless/plugin_ownership_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit the operator-facing integrations**

```sh
git add tests/headless/snacks_spec.lua tests/headless/plugin_ownership_spec.lua dotfiles/.config/lazygit/config.yml README.md
git commit -m "feat: configure Just and Delta workflows"
```

### Task 5: Resolve and verify plugin revisions

**Files:**
- Modify: `lazy-lock.json`

- [ ] **Step 1: Run the resolver; do not hand-edit plugin commits**

Run with network approval:

```sh
lock_output="$(mktemp /tmp/nv-ide-resolved-lock.XXXXXX)"
NV_IDE_SMOKE_ALLOW_INSTALL=1 \
NV_IDE_SMOKE_LOCK_OUTPUT="$lock_output" \
tests/headless/no-profile.sh resolve
cp "$lock_output" lazy-lock.json
```

Expected markers:

```text
LAZY SEED PASS
LAZY UPDATE PASS
LAZY STABLE PASS
FRESH STARTUP PASS
RESOLVED LOCKFILE /tmp/nv-ide-resolved-lock.
```

- [ ] **Step 2: Verify the requested plugin locks exist**

```sh
nvim --clean --headless -u NONE -i NONE \
  -l tests/headless/locked_plugin.lua lazy-lock.json mini.surround

nvim --clean --headless -u NONE -i NONE \
  -l tests/headless/locked_plugin.lua lazy-lock.json diffview-plus.nvim

git diff --check
```

Expected: each validator prints a non-empty branch and a 40-character commit; `git diff --check` is silent.

- [ ] **Step 3: Run the integration regression set**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/interaction_spec.lua \
  tests/headless/plugin_ownership_spec.lua \
  tests/headless/snacks_spec.lua \
  tests/headless/manifest_spec.lua \
  tests/headless/health_spec.lua \
  tests/headless/lint_format_spec.lua

tests/headless/no-profile.sh preflight
```

Expected: every selected test reports PASS, the summary reports `0 failed`, and preflight prints `SMOKE preflight PASS`.

- [ ] **Step 4: Run final repository acceptance**

```sh
nvim --clean --headless -u NONE -i NONE \
  -c "lua for _,f in ipairs(vim.fn.glob('**/*.lua', false, true)) do assert(loadfile(f), f) end" \
  -c 'qa!'

nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua

tests/headless/no-profile.sh preflight
git diff --check
```

Expected: Lua compilation exits zero, the complete suite reports `0 failed`, preflight prints `SMOKE preflight PASS`, the resolver has already printed `FRESH STARTUP PASS`, and `git diff --check` is silent.

- [ ] **Step 5: Commit the generated lockfile**

```sh
git add lazy-lock.json
git commit -m "chore: resolve integration plugin lockfile"
```

## Acceptance criteria

- `nvim-mini/mini.surround` is stable-tagged, loads on `VeryLazy`, owns `ys`, `ds`, and `cs`, and disables all unrequested helper mappings.
- Markdown no longer claims `ds` or `cs`; its `gs` and `gss` mappings remain.
- Diffview+ loads through the six declared commands; `<leader>gv`, `<leader>gh`, Gitsigns `<leader>gd`, and Unified `<leader>gU` are distinct.
- Ruff is present in the Mason inventory, Pylint is absent, the package count remains 91, and the editor-correctness plan's Ruff-only lint test passes.
- Git below 2.31 is unhealthy; missing Just and Delta produce optional warnings with platform-specific remediation.
- Overseer keeps builtin templates and `<leader>rr`; no recipe runs automatically.
- LazyGit uses `delta --dark --paging=never`; no Lua configuration invokes `git config`.
- `lazy-lock.json` contains validated `mini.surround` and `diffview-plus.nvim` revisions.
- The complete headless suite, isolated preflight, resolver fresh-start gate, Lua compilation, and `git diff --check` pass.
