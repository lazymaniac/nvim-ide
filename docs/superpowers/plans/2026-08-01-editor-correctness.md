# Editor Correctness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair formatting, lint trust, interaction ownership, file/terminal defaults, cache execution, and lazy-loading defects while introducing one shared project-context API.

**Architecture:** Pure or dependency-injected helpers own project context and formatting policy. Plugin configuration remains declarative, while automatic work is restricted to trusted save events. Startup and interaction fixes use explicit ownership boundaries and regression tests.

**Tech Stack:** Neovim 0.12 Lua, Conform, nvim-lint, Snacks, Base46, nvim-dap, custom dependency-free headless harness.

## File map

- `lua/nv_ide/project.lua`: shared roots, containment, executable selection, JavaScript context, and trust.
- `lua/util/format.lua`: the only core-to-Conform format policy adapter.
- `lua/plugins/lint_and_format.lua`: deterministic formatter and trusted save-only linter routing.
- `lua/config/keymaps.lua` and `lua/plugins/treesitter.lua`: terminal and motion ownership.
- `lua/plugins/snacks.lua`: bounded file sources plus ordinary-shell and Zellij mappings.
- `lua/nv_ide/cache.lua` and `init.lua`: allowlisted Base46 cache execution.
- `lua/chadrc.lua`: statusline rendering without eagerly loading DAP.
- `tests/headless/*_spec.lua`: focused regression coverage for each behavior above.

---

### Task 1: Add the shared project-context contract

**Files:**
- Create: `lua/nv_ide/project.lua`
- Create: `tests/headless/project_spec.lua`
- Modify: `lua/util/dap.lua`
- Test: `tests/headless/dap_spec.lua`

- [ ] **Step 1: Write failing project behavior tests**

Create `tests/headless/project_spec.lua`:

```lua
local h = require 'tests.headless.harness'

local function load_project()
  package.loaded['nv_ide.project'] = nil
  return require 'nv_ide.project'
end

h.describe('shared project context', function()
  h.it('finds the nearest project root from a path or buffer', function()
    h.with_temp_dir(function(tmp)
      local repo = vim.fs.joinpath(tmp, 'repo')
      local package = vim.fs.joinpath(repo, 'packages', 'web')
      local source = vim.fs.joinpath(package, 'src', 'example.ts')
      vim.fn.mkdir(vim.fs.joinpath(repo, '.git'), 'p')
      vim.fn.mkdir(vim.fs.dirname(source), 'p')
      vim.fn.writefile({ '{}' }, vim.fs.joinpath(package, 'package.json'))
      vim.fn.writefile({ 'export {}' }, source)

      local project = load_project()
      h.equal(project.root(source, { 'package.json', '.git' }), vim.fs.normalize(package))
      local bufnr = vim.fn.bufadd(source)
      h.equal(project.root(bufnr, { 'package.json', '.git' }), vim.fs.normalize(package))
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  h.it('uses path components for containment', function()
    local project = load_project()
    h.truthy(project.contains('/work/app', '/work/app/src/main.lua'))
    h.truthy(project.contains('/work/app', '/work/app'))
    h.falsy(project.contains('/work/app', '/work/application/main.lua'))
  end)

  h.it('resolves activated, project-local, then ambient executables', function()
    local project = load_project()
    local existing = {
      ['/active/bin/python'] = true,
      ['/repo/.venv/bin/python'] = true,
      ['/usr/bin/python3'] = true,
    }
    local deps = {
      executable = function(path) return existing[path] == true end,
      exepath = function(command) return command == 'python3' and '/usr/bin/python3' or '' end,
    }
    local candidates = {
      activated = { '/active/bin/python' },
      project = { '.venv/bin/python' },
      ambient = { 'python3' },
    }

    h.equal(project.executable('/repo', candidates, deps), '/active/bin/python')
    existing['/active/bin/python'] = nil
    h.equal(project.executable('/repo', candidates, deps), '/repo/.venv/bin/python')
    existing['/repo/.venv/bin/python'] = nil
    h.equal(project.executable('/repo', candidates, deps), '/usr/bin/python3')
  end)

  h.it('discovers JavaScript package and Jest context', function()
    h.with_temp_dir(function(tmp)
      local source = vim.fs.joinpath(tmp, 'src', 'example.test.ts')
      vim.fn.mkdir(vim.fs.joinpath(tmp, 'src'), 'p')
      vim.fn.mkdir(vim.fs.joinpath(tmp, 'node_modules', '.bin'), 'p')
      vim.fn.mkdir(vim.fs.joinpath(tmp, 'spec', 'support'), 'p')
      vim.fn.writefile({ '{}' }, vim.fs.joinpath(tmp, 'package.json'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'pnpm-lock.yaml'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'jest.config.ts'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, '.mocharc.json'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'karma.conf.ts'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'spec', 'support', 'jasmine.json'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'node_modules', '.bin', 'jest'))
      vim.fn.writefile({}, source)

      local context = load_project().javascript(source, {
        executable = function(path)
          return path == vim.fs.joinpath(tmp, 'node_modules', '.bin', 'jest')
        end,
      })
      h.equal(context.root, vim.fs.normalize(tmp))
      h.equal(context.package_manager, 'pnpm')
      h.deep_equal(context.configs, {
        jasmine = vim.fs.joinpath(tmp, 'spec', 'support', 'jasmine.json'),
        jest = vim.fs.joinpath(tmp, 'jest.config.ts'),
        karma = vim.fs.joinpath(tmp, 'karma.conf.ts'),
        mocha = vim.fs.joinpath(tmp, '.mocharc.json'),
      })
      h.equal(context.executables.jest, vim.fs.joinpath(tmp, 'node_modules', '.bin', 'jest'))
    end)
  end)

  h.it('inherits hoisted JavaScript tooling within a monorepo boundary', function()
    h.with_temp_dir(function(tmp)
      local package_root = vim.fs.joinpath(tmp, 'packages', 'web')
      local source = vim.fs.joinpath(package_root, 'src', 'example.test.ts')
      local jest = vim.fs.joinpath(tmp, 'node_modules', '.bin', 'jest')
      local launch = vim.fs.joinpath(tmp, '.vscode', 'launch.json')
      vim.fn.mkdir(vim.fs.joinpath(tmp, '.git'), 'p')
      vim.fn.mkdir(vim.fs.dirname(source), 'p')
      vim.fn.mkdir(vim.fs.dirname(jest), 'p')
      vim.fn.mkdir(vim.fs.dirname(launch), 'p')
      vim.fn.writefile({ '{}' }, vim.fs.joinpath(package_root, 'package.json'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'pnpm-lock.yaml'))
      vim.fn.writefile({}, jest)
      vim.fn.writefile({ '{ "configurations": [] }' }, launch)
      vim.fn.writefile({ 'export {}' }, source)

      local context = load_project().javascript(source, {
        executable = function(path) return path == jest end,
      })
      h.equal(context.root, vim.fs.normalize(package_root))
      h.equal(context.workspace_root, vim.fs.normalize(tmp))
      h.equal(context.package_manager, 'pnpm')
      h.equal(context.executables.jest, jest)
      h.equal(context.launch_json, launch)
    end)
  end)

  h.it('caches only positive directory trust decisions', function()
    local project = load_project()
    local calls, cache = 0, {}
    local deps = {
      cache = cache,
      secure_read = function()
        calls = calls + 1
        return calls >= 2 and true or nil
      end,
    }

    h.falsy(project.trusted('/repo', deps))
    h.truthy(project.trusted('/repo', deps))
    h.truthy(project.trusted('/repo', deps))
    h.equal(calls, 2)
  end)
end)
```

- [ ] **Step 2: Run the project spec and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/project_spec.lua
```

Expected: FAIL with `module 'nv_ide.project' not found`.

- [ ] **Step 3: Implement the project-context API**

Create `lua/nv_ide/project.lua` with this public shape and dependency-injected behavior:

```lua
local M = {}

M.markers = {
  'package.json', 'pyproject.toml', 'setup.cfg', 'tox.ini',
  'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts',
  'pom.xml', '.git',
}

local trust_cache = {}
local js_configs = {
  jest = { 'jest.config.ts', 'jest.config.js', 'jest.config.mjs', 'jest.config.cjs' },
  mocha = { '.mocharc.js', '.mocharc.cjs', '.mocharc.mjs', '.mocharc.json' },
  karma = { 'karma.conf.js', 'karma.conf.cjs', 'karma.conf.ts' },
  jasmine = { 'spec/support/jasmine.json', 'spec/support/jasmine.mjs' },
}
local js_bins = { 'jest', 'mocha', 'karma', 'jasmine' }

local function path_from_target(target)
  if type(target) == 'number' then return vim.api.nvim_buf_get_name(target) end
  return target
end

local function existing(path, stat)
  return path and stat(path) ~= nil
end

function M.root(target, markers, deps)
  deps = deps or {}
  local stat = deps.stat or vim.uv.fs_stat
  local find_root = deps.find_root or vim.fs.root
  local path = vim.fs.normalize(assert(path_from_target(target), 'project target is required'))
  local start = stat(path) and stat(path).type == 'directory' and path or vim.fs.dirname(path)
  local root = find_root(start, markers or M.markers)
  return root and vim.fs.normalize(root) or nil
end

function M.contains(root, path)
  root, path = vim.fs.normalize(root), vim.fs.normalize(path)
  local relative = vim.fs.relpath(root, path)
  return relative ~= nil and relative ~= '..' and not vim.startswith(relative, '../')
end

function M.executable(root, candidates, deps)
  deps = deps or {}
  local executable = deps.executable or function(path) return vim.fn.executable(path) == 1 end
  local exepath = deps.exepath or vim.fn.exepath
  for _, path in ipairs(candidates.activated or {}) do
    if path and path ~= '' and executable(path) then return vim.fs.normalize(path) end
  end
  for _, relative in ipairs(candidates.project or {}) do
    local path = vim.fs.joinpath(root, relative)
    if executable(path) then return vim.fs.normalize(path) end
  end
  for _, command in ipairs(candidates.ambient or {}) do
    local path = exepath(command)
    if path and path ~= '' and executable(path) then return vim.fs.normalize(path) end
  end
end

function M.javascript(target, deps)
  deps = deps or {}
  local stat = deps.stat or vim.uv.fs_stat
  local executable = deps.executable or function(path) return vim.fn.executable(path) == 1 end
  local root = M.root(target, { 'package.json' }, deps)
  if not root then return { configs = {}, executables = {} } end
  local workspace_root = M.root(target, { '.git' }, deps) or root
  local roots, cursor = {}, root
  while cursor and M.contains(workspace_root, cursor) do
    roots[#roots + 1] = cursor
    if cursor == workspace_root then break end
    local parent = vim.fs.dirname(cursor)
    if parent == cursor then break end
    cursor = parent
  end

  local function first(names)
    for _, directory in ipairs(roots) do
      for _, name in ipairs(names) do
        local path = vim.fs.joinpath(directory, name)
        if existing(path, stat) then return path end
      end
    end
  end
  local managers = {
    { 'pnpm-lock.yaml', 'pnpm' }, { 'yarn.lock', 'yarn' },
    { 'bun.lockb', 'bun' }, { 'bun.lock', 'bun' }, { 'package-lock.json', 'npm' },
  }
  local manager
  for _, directory in ipairs(roots) do
    for _, item in ipairs(managers) do
      if existing(vim.fs.joinpath(directory, item[1]), stat) then manager = item[2]; break end
    end
    if manager then break end
  end
  local executables = {}
  for _, name in ipairs(js_bins) do
    for _, directory in ipairs(roots) do
      local path = vim.fs.joinpath(directory, 'node_modules', '.bin', name)
      if executable(path) then executables[name] = path; break end
    end
  end
  local configs = {}
  for name, candidates in pairs(js_configs) do
    configs[name] = first(candidates)
  end
  return {
    root = root,
    workspace_root = workspace_root,
    package_manager = manager,
    package_json = vim.fs.joinpath(root, 'package.json'),
    launch_json = first { '.vscode/launch.json' },
    configs = configs,
    executables = executables,
  }
end

function M.trusted(root, deps)
  deps = deps or {}
  local cache = deps.cache or trust_cache
  root = vim.fs.normalize(root)
  if cache[root] == true then return true end
  local secure_read = deps.secure_read or vim.secure.read
  local ok, trusted = pcall(secure_read, root)
  if ok and trusted == true then cache[root] = true; return true end
  return false
end

return M
```

- [ ] **Step 4: Reuse the executable policy in Python DAP**

Extend `resolves an absolute executable Python in deterministic priority order` in `tests/headless/dap_spec.lua` with the selector-nil virtualenv regression:

```lua
h.equal(resolve({ [virtual] = true, [project] = true, [system] = true }, nil), virtual)
```

Add a second test proving default resolution starts at the active buffer project:

```lua
h.it('roots default Python resolution at the active buffer project', function()
  h.with_temp_dir(function(tmp)
    local source = vim.fs.joinpath(tmp, 'src', 'example.py')
    local python = vim.fs.joinpath(tmp, '.venv', 'bin', 'python')
    vim.fn.mkdir(vim.fs.dirname(source), 'p')
    vim.fn.mkdir(vim.fs.dirname(python), 'p')
    vim.fn.writefile({ '[project]' }, vim.fs.joinpath(tmp, 'pyproject.toml'))
    vim.fn.writefile({ 'print("ok")' }, source)
    vim.fn.writefile({}, python)
    local previous_buffer = vim.api.nvim_get_current_buf()
    local previous_resolver = package.loaded['util.dap']
    local bufnr = vim.fn.bufadd(source)
    vim.fn.bufload(bufnr)
    vim.api.nvim_set_current_buf(bufnr)

    package.loaded['util.dap'] = nil
    local ok, result = xpcall(function()
      return require('util.dap').resolve_python {
        selected = function() return nil end,
        env = {},
        executable = function(path) return path == python end,
        exepath = function() return '' end,
      }
    end, debug.traceback)

    vim.api.nvim_set_current_buf(previous_buffer)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    package.loaded['util.dap'] = previous_resolver
    if not ok then error(result, 0) end
    h.equal(result, vim.fs.normalize(python))
  end)
end)
```

In `lua/util/dap.lua`, replace the current `cwd` initialization and candidate iteration with:

```lua
local project = require 'nv_ide.project'
local target = opts.target == nil and 0 or opts.target
local cwd = type(opts.cwd) == 'function' and opts.cwd() or opts.cwd
cwd = cwd or project.root(target, { 'pyproject.toml', 'setup.cfg', 'tox.ini', '.git' })
if not cwd then
  local path = type(target) == 'number' and vim.api.nvim_buf_get_name(target) or target
  cwd = path and path ~= '' and vim.fs.dirname(vim.fs.normalize(path)) or vim.fn.getcwd()
end
local activated = {}
local selected_path = selected()
if selected_path then activated[#activated + 1] = selected_path end
if env.VIRTUAL_ENV then
  activated[#activated + 1] = vim.fs.joinpath(env.VIRTUAL_ENV, 'bin', 'python')
end
local path = project.executable(cwd, {
  activated = activated,
  project = { '.venv/bin/python', 'venv/bin/python' },
  ambient = { 'python3', 'python' },
}, {
  executable = executable,
  exepath = exepath,
})
if path then return path end
error('No executable Python interpreter was found for nvim-dap-python', 0)
```

Remove the now-unused local `absolute()` helper.

- [ ] **Step 5: Run project and DAP specs and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/project_spec.lua \
  tests/headless/dap_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 6: Commit the foundational contract**

```sh
git add lua/nv_ide/project.lua lua/util/dap.lua tests/headless/project_spec.lua tests/headless/dap_spec.lua
git commit -m "feat(project): add shared project context"
```

### Task 2: Restore the Conform format adapter and toggles

**Files:**
- Create: `lua/util/format.lua`
- Modify: `tests/headless/lint_format_spec.lua`
- Modify: `lua/plugins/lint_and_format.lua`

- [ ] **Step 1: Write the missing-adapter regression test**

Add this test to `tests/headless/lint_format_spec.lua`:

```lua
h.it('adapts Conform to global and buffer-local format policy', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local previous_conform = package.loaded.conform
  local previous_format = package.loaded['util.format']
  local previous_global = vim.g.autoformat
  local previous_buffer = vim.b[bufnr].autoformat
  package.loaded.conform = {
    formatexpr = function() return 'conform-formatexpr' end,
  }
  package.loaded['util.format'] = nil

  local ok, err = xpcall(function()
    local format = require 'util.format'
    vim.g.autoformat = false
    vim.b[bufnr].autoformat = nil
    h.falsy(format.enabled(bufnr))
    h.falsy(format.format_on_save(bufnr))
    h.equal(format.formatexpr(), 'conform-formatexpr')

    format.toggle()
    h.truthy(vim.g.autoformat)
    h.deep_equal(format.format_on_save(bufnr), { lsp_format = 'fallback' })

    format.toggle(true)
    h.equal(vim.b[bufnr].autoformat, false)
    vim.b[bufnr].autoformat = nil
    h.truthy(format.enabled(bufnr))
  end, debug.traceback)

  package.loaded.conform = previous_conform
  package.loaded['util.format'] = previous_format
  vim.g.autoformat = previous_global
  vim.b[bufnr].autoformat = previous_buffer
  if not ok then error(err, 0) end
end)
```

Extend the existing Conform setup test with:

```lua
h.equal(type(calls.setup.format_on_save), 'function')
local previous_autoformat = vim.g.autoformat
vim.g.autoformat = false
h.falsy(calls.setup.format_on_save(0), 'format-on-save must remain disabled by default')
vim.g.autoformat = previous_autoformat
```

- [ ] **Step 2: Run the format spec and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/lint_format_spec.lua
```

Expected: FAIL with `module 'util.format' not found`.

- [ ] **Step 3: Implement the sole format adapter**

Create `lua/util/format.lua`:

```lua
local M = {}

function M.formatexpr()
  return require('conform').formatexpr()
end

function M.enabled(bufnr)
  bufnr = bufnr or 0
  local value = vim.b[bufnr].autoformat
  if value ~= nil then return value == true end
  return vim.g.autoformat == true
end

function M.toggle(buffer_local)
  if buffer_local then
    local bufnr = vim.api.nvim_get_current_buf()
    vim.b[bufnr].autoformat = not M.enabled(bufnr)
    return
  end
  vim.g.autoformat = not (vim.g.autoformat == true)
  vim.b.autoformat = nil
end

function M.format_on_save(bufnr)
  if M.enabled(bufnr) then return { lsp_format = 'fallback' } end
end

return M
```

Set Conform's setup field to:

```lua
format_on_save = require('util').format.format_on_save,
```

Keep `vim.g.autoformat = false`, the current `formatexpr`, and existing toggle mappings.

- [ ] **Step 4: Run the format spec and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/lint_format_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit the repair**

```sh
git add lua/util/format.lua lua/plugins/lint_and_format.lua tests/headless/lint_format_spec.lua
git commit -m "fix(format): restore autoformat policy"
```

### Task 3: Complete deterministic formatter routing

**Files:**
- Modify: `tests/headless/lint_format_spec.lua`
- Modify: `lua/plugins/lint_and_format.lua`

- [ ] **Step 1: Add failing formatter-matrix assertions**

After Conform setup is captured, assert:

```lua
local ft = calls.setup.formatters_by_ft
h.truthy(ft.sh, 'sh formatter alias is missing')
h.deep_equal({ ft.sh[1], ft.sh[2] }, { 'beautysh', 'shellharden' })
h.truthy(ft.sh.stop_after_first)
h.truthy(ft.bash.stop_after_first)
h.deep_equal(ft.javascriptreact, { 'prettierd' })
h.deep_equal(ft.typescriptreact, { 'prettierd' })
h.deep_equal(ft.svelte, { 'prettierd' })
h.deep_equal(ft.jsonc, { 'prettierd' })
h.deep_equal(ft.eruby, { 'erb_format' })
h.deep_equal(ft.cmake, { 'cmake_format' })
h.deep_equal(ft.xml, { 'xmlformatter' })
for _, filetype in ipairs { 'angular', 'json', 'sql' } do
  h.truthy(ft[filetype].stop_after_first)
end
h.deep_equal(ft.python, { 'black', 'docformatter' })
h.falsy(ft.python.stop_after_first)
h.equal(calls.setup.formatters.prettierd.env.PRETTIERD_LOCAL_PRETTIER_ONLY, '1')
```

- [ ] **Step 2: Run the format spec and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/lint_format_spec.lua
```

Expected: FAIL with `sh formatter alias is missing`.

- [ ] **Step 3: Apply the explicit formatter matrix**

Use these exact entries:

```lua
bash = { 'beautysh', 'shellharden', stop_after_first = true },
sh = { 'beautysh', 'shellharden', stop_after_first = true },
angular = { 'djlint', 'prettierd', stop_after_first = true },
json = { 'jq', 'prettierd', stop_after_first = true },
sql = { 'sqlfmt', 'sqruff', stop_after_first = true },
javascriptreact = { 'prettierd' },
typescriptreact = { 'prettierd' },
svelte = { 'prettierd' },
jsonc = { 'prettierd' },
eruby = { 'erb_format' },
cmake = { 'cmake_format' },
xml = { 'xmlformatter' },
python = { 'black', 'docformatter' },
```

Configure the project-local Prettier requirement:

```lua
formatters = {
  prettierd = { env = { PRETTIERD_LOCAL_PRETTIER_ONLY = '1' } },
},
```

Do not add a Docker formatter or put `stop_after_first` on Python/Go deliberate chains.

- [ ] **Step 4: Run the format spec and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/lint_format_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit formatter routing**

```sh
git add tests/headless/lint_format_spec.lua lua/plugins/lint_and_format.lua
git commit -m "fix(format): complete formatter routing"
```

### Task 4: Trust-gate deterministic save-only linting

**Files:**
- Modify: `tests/headless/lint_format_spec.lua`
- Modify: `lua/plugins/lint_and_format.lua`

- [ ] **Step 1: Replace the lint fixture and write the failing routing test**

Delete the now-unused `contains()` helper and replace `configure_lint()` with:

```lua
local function configure_lint()
  local calls = {}
  local trusted = false
  local registration = {}
  local lint = {
    linters = { eslint_d = { env = {} } },
    linters_by_ft = {},
    try_lint = function(names, opts)
      calls[#calls + 1] = { names = vim.deepcopy(names), opts = vim.deepcopy(opts) }
    end,
  }
  local project = {
    root = function(path)
      h.truthy(vim.startswith(path, '/repo/'))
      return '/repo'
    end,
    trusted = function(root)
      h.equal(root, '/repo')
      return trusted
    end,
    contains = function(root, path)
      local relative = vim.fs.relpath(root, path)
      return relative ~= nil and relative ~= '..' and not vim.startswith(relative, '../')
    end,
  }
  local previous_lint = package.loaded.lint
  local previous_project = package.loaded['nv_ide.project']
  local previous_augroup = vim.api.nvim_create_augroup
  local previous_autocmd = vim.api.nvim_create_autocmd
  package.loaded.lint = lint
  package.loaded['nv_ide.project'] = project
  vim.api.nvim_create_augroup = function(name, opts)
    h.equal(name, 'nvide_lint')
    h.deep_equal(opts, { clear = true })
    return 71
  end
  vim.api.nvim_create_autocmd = function(events, opts)
    registration = { events = events, opts = opts }
    return 72
  end

  local spec = plugin(dofile('lua/plugins/lint_and_format.lua'), 'mfussenegger/nvim-lint')
  local ok, err = xpcall(spec.config, debug.traceback)

  package.loaded.lint = previous_lint
  package.loaded['nv_ide.project'] = previous_project
  vim.api.nvim_create_augroup = previous_augroup
  vim.api.nvim_create_autocmd = previous_autocmd
  if not ok then error(err, 0) end

  local function save(path, filetype)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, path)
    vim.bo[bufnr].filetype = filetype
    local saved, failure = xpcall(function()
      registration.opts.callback { buf = bufnr }
    end, debug.traceback)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    if not saved then error(failure, 0) end
  end

  return lint, calls, registration, save, function(value) trusted = value end
end
```

Update the kube-linter test to call `configure_lint()` without an executable table. Replace `registers Python linters only while their executables are available` with:

```lua
h.it('runs deterministic lint only after a trusted project save', function()
  local lint, calls, registration, save, set_trusted = configure_lint()
  h.equal(registration.events, 'BufWritePost')
  h.equal(registration.opts.group, 71)

  save('/repo/app.py', 'python')
  h.equal(#calls, 0, 'automatic lint must skip untrusted projects')

  set_trusted(true)
  save('/repo/app.py', 'python')
  save('/repo/config.yml', 'yaml')
  save('/repo/.github/workflows/ci.yml', 'yaml')
  h.deep_equal(calls, {
    { names = { 'ruff' }, opts = { cwd = '/repo' } },
    { names = { 'yamllint' }, opts = { cwd = '/repo' } },
    { names = { 'yamllint', 'actionlint' }, opts = { cwd = '/repo' } },
  })
  h.deep_equal(lint.linters_by_ft.python, { 'ruff' })
  h.deep_equal(lint.linters_by_ft.javascript, { 'eslint_d' })
  h.deep_equal(lint.linters_by_ft.javascriptreact, { 'eslint_d' })
  h.falsy(vim.inspect(lint.linters_by_ft):find('trivy', 1, true))
  h.equal(lint.linters.eslint_d.env.ESLINT_D_MISS, 'fail')
end)
```

- [ ] **Step 2: Run the lint spec and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/lint_format_spec.lua
```

Expected first failure: automatic lint registers `BufEnter`; after that assertion is corrected, the trust-skip assertion must still fail before production code changes.

- [ ] **Step 3: Implement save-only routing**

Replace ambient Python discovery and the broad autocmd with:

```lua
lint.linters_by_ft = {
  angular = { 'djlint' }, ansible = { 'ansible_lint' }, clojure = { 'clj-kondo' },
  cmake = { 'cmakelint' }, go = { 'golangcilint' }, haskell = { 'hlint' },
  helm = { 'kube_linter' }, html = { 'htmlhint' }, kotlin = { 'ktlint', 'detekt' },
  javascript = { 'eslint_d' }, javascriptreact = { 'eslint_d' },
  markdown = { 'markdownlint' }, python = { 'ruff' }, ruby = { 'erb_lint', 'rubocop' },
  typescript = { 'eslint_d' }, typescriptreact = { 'eslint_d' }, yaml = { 'yamllint' },
}
lint.linters.eslint_d.env = vim.tbl_extend('force', lint.linters.eslint_d.env or {}, {
  ESLINT_D_MISS = 'fail',
})

local project = require 'nv_ide.project'
local group = vim.api.nvim_create_augroup('nvide_lint', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  callback = function(event)
    local path = vim.api.nvim_buf_get_name(event.buf)
    local root = project.root(path)
    if not root or not project.trusted(root) then return end
    local names = vim.deepcopy(lint.linters_by_ft[vim.bo[event.buf].filetype] or {})
    if vim.bo[event.buf].filetype == 'yaml'
      and project.contains(vim.fs.joinpath(root, '.github', 'workflows'), path)
    then
      names[#names + 1] = 'actionlint'
    end
    if #names > 0 then
      vim.api.nvim_buf_call(event.buf, function()
        lint.try_lint(names, { cwd = root })
      end)
    end
  end,
})
```

Remove all automatic Trivy/tfsec entries and the `available()` helper. Keep explicit security tools installed for manual tasks.

- [ ] **Step 4: Run the lint spec and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/lint_format_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit lint ownership**

```sh
git add tests/headless/lint_format_spec.lua lua/plugins/lint_and_format.lua
git commit -m "fix(lint): trust project save routing"
```

### Task 5: Separate motion ownership and terminal autocmds

**Files:**
- Modify: `tests/headless/interaction_spec.lua`
- Modify: `lua/config/keymaps.lua`
- Modify: `lua/plugins/treesitter.lua`

- [ ] **Step 1: Write failing combined-ownership tests**

Add this test to `tests/headless/interaction_spec.lua`:

```lua
h.it('separates diagnostic, conditional, and terminal ownership', function()
  local previous_util = package.loaded.util
  local previous_augroup = vim.api.nvim_create_augroup
  local previous_autocmd = vim.api.nvim_create_autocmd
  local previous_keymap = vim.keymap.set
  local previous_cmd = vim.cmd
  local previous_global = _G.set_terminal_keymaps
  local core, mapped, commands = {}, {}, {}
  local registration

  package.loaded.util = {
    safe_keymap_set = function(_, lhs) core[lhs] = true end,
    format = { toggle = function() end },
  }
  vim.api.nvim_create_augroup = function(name, opts)
    h.equal(name, 'nvide_terminal')
    h.deep_equal(opts, { clear = true })
    return 81
  end
  vim.api.nvim_create_autocmd = function(event, opts)
    registration = { event = event, opts = opts }
    return 82
  end
  vim.keymap.set = function(mode, lhs, rhs, opts)
    mapped[#mapped + 1] = { mode = mode, lhs = lhs, rhs = rhs, opts = opts }
  end
  vim.cmd = function(command) commands[#commands + 1] = command end

  local ok, err = xpcall(function()
    dofile 'lua/config/keymaps.lua'
    if registration then registration.opts.callback { buf = 37 } end
  end, debug.traceback)

  package.loaded.util = previous_util
  vim.api.nvim_create_augroup = previous_augroup
  vim.api.nvim_create_autocmd = previous_autocmd
  vim.keymap.set = previous_keymap
  vim.cmd = previous_cmd
  _G.set_terminal_keymaps = previous_global
  if not ok then error(err, 0) end

  local treesitter = plugin(
    dofile('lua/plugins/treesitter.lua'),
    'nvim-treesitter/nvim-treesitter-textobjects'
  )
  local owners = {}
  for lhs in pairs(core) do owners[lhs] = { 'core' } end
  for _, key in ipairs(treesitter.keys or {}) do
    owners[key[1]] = owners[key[1]] or {}
    owners[key[1]][#owners[key[1]] + 1] = 'treesitter'
  end
  h.deep_equal(owners['[d'], { 'core' }, 'conditional motions must not own [d')
  h.deep_equal(owners[']d'], { 'core' }, 'conditional motions must not own ]d')
  h.deep_equal(owners['[C'], { 'treesitter' })
  h.deep_equal(owners[']C'], { 'treesitter' })

  h.truthy(registration, 'terminal mappings must use nvim_create_autocmd')
  h.equal(registration.event, 'TermOpen')
  h.equal(registration.opts.group, 81)
  h.equal(registration.opts.pattern, 'term://*')
  h.equal(#mapped, 6)
  for _, item in ipairs(mapped) do
    h.equal(item.mode, 't')
    h.equal(item.opts.buffer, 37)
  end
  for _, command in ipairs(commands) do
    h.falsy(command:find('autocmd!', 1, true), 'terminal setup must not clear another TermOpen handler')
  end
end)
```

- [ ] **Step 2: Run interaction tests and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/interaction_spec.lua
```

Expected: FAIL because Tree-sitter owns lowercase diagnostic keys and terminal setup uses a global function plus `autocmd!`.

- [ ] **Step 3: Move conditionals and isolate terminal setup**

Rename Tree-sitter conditional motions to `[C` and `]C`. Replace the terminal block with:

```lua
local terminal_group = vim.api.nvim_create_augroup('nvide_terminal', { clear = true })
vim.api.nvim_create_autocmd('TermOpen', {
  group = terminal_group,
  pattern = 'term://*',
  callback = function(event)
    local opts = { buffer = event.buf }
    vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
    vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
    vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
    vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
    vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
    vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
  end,
})
```

- [ ] **Step 4: Run interaction tests and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/interaction_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit interaction ownership**

```sh
git add tests/headless/interaction_spec.lua lua/config/keymaps.lua lua/plugins/treesitter.lua
git commit -m "fix(keys): isolate motions and terminals"
```

### Task 6: Bound file search and restore the ordinary shell

**Files:**
- Modify: `tests/headless/snacks_spec.lua`
- Modify: `lua/plugins/snacks.lua`

- [ ] **Step 1: Write failing picker and terminal tests**

Add these tests to `tests/headless/snacks_spec.lua`:

`snacks_spec.lua` owns both assertions because the safe picker sources and both terminal entry-point mappings are declared by the Snacks plugin; `interaction_spec.lua` remains responsible for core `keymaps.lua` and its buffer-local `TermOpen` behavior.

```lua
h.it('bounds default file sources and makes all-files search explicit', function()
  local snacks = plugin(dofile 'lua/plugins/snacks.lua', 'folke/snacks.nvim')
  local sources = snacks.opts.picker.sources
  h.falsy(sources.files.ignored)
  h.falsy(sources.files.follow)
  h.falsy(sources.explorer.ignored)
  h.falsy(sources.explorer.follow)

  local all_files = mapping(snacks, '<leader>sF')
  h.equal(#all_files, 1)
  h.matches(all_files[1].desc, 'All Files')
  local previous_snacks = _G.Snacks
  local all_files_options
  _G.Snacks = {
    picker = {
      files = function(opts) all_files_options = opts end,
    },
  }
  local ok, err = xpcall(all_files[1][2], debug.traceback)
  _G.Snacks = previous_snacks
  if not ok then error(err, 0) end
  h.deep_equal(all_files_options, { hidden = true, ignored = true, follow = false })
end)

h.it('keeps the ordinary shell and Zellij on separate mappings', function()
  local previous_external = package.loaded['util.external']
  local previous_snacks = _G.Snacks
  local ordinary_calls, zellij_calls = 0, 0
  package.loaded['util.external'] = {
    terminal = function(action)
      return function()
        if action.id == 'zellij' then zellij_calls = zellij_calls + 1 end
      end
    end,
  }
  _G.Snacks = {
    terminal = function() ordinary_calls = ordinary_calls + 1 end,
  }

  local ok, err = xpcall(function()
    local snacks = plugin(dofile 'lua/plugins/snacks.lua', 'folke/snacks.nvim')
    local shell = mapping(snacks, '<c-/>')
    local zellij = mapping(snacks, '<leader>lz')
    h.equal(#shell, 1)
    h.equal(#zellij, 1)
    shell[1][2]()
    zellij[1][2]()
  end, debug.traceback)

  package.loaded['util.external'] = previous_external
  _G.Snacks = previous_snacks
  if not ok then error(err, 0) end
  h.equal(ordinary_calls, 1)
  h.equal(zellij_calls, 1)
end)
```

- [ ] **Step 2: Run Snacks tests and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/snacks_spec.lua
```

Expected: FAIL because ignored files/symlinks are enabled and `<c-/>` owns Zellij.

- [ ] **Step 3: Apply safe picker and terminal mappings**

Inside the existing `sources.explorer` table, replace `ignored = true` with these two adjacent fields and leave every other explorer field unchanged:

```lua
ignored = false,
follow = false,
```

Replace the existing single-line `sources.files` value with:

```lua
files = { layout = bottom(), show_empty = true, hidden = true, ignored = false, follow = false },
```

Add or change mappings:

```lua
{
  '<leader>sF',
  function() Snacks.picker.files { hidden = true, ignored = true, follow = false } end,
  desc = 'Find All Files [sF]',
},
{
  '<c-/>',
  function() Snacks.terminal() end,
  desc = 'Toggle Terminal (c-/)',
  mode = { 'n', 't' },
},
{ '<leader>lz', terminal('zellij'), desc = 'Zellij Terminal [lz]' },
```

- [ ] **Step 4: Run Snacks tests and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/snacks_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit safe defaults**

```sh
git add tests/headless/snacks_spec.lua lua/plugins/snacks.lua
git commit -m "fix(snacks): bound files and shell"
```

### Task 7: Constrain Base46 cache execution

**Files:**
- Create: `tests/headless/cache_spec.lua`
- Create: `lua/nv_ide/cache.lua`
- Modify: `init.lua`

- [ ] **Step 1: Write failing allowlist and failure tests**

Create `tests/headless/cache_spec.lua`:

```lua
local h = require 'tests.headless.harness'

local function load_cache()
  package.loaded['nv_ide.cache'] = nil
  return require 'nv_ide.cache'
end

local integrations = { 'dap', 'treesitter', 'whichkey' }

local function write_allowed(cache, dir)
  local names = cache.allowed(integrations)
  for _, name in ipairs(names) do
    vim.fn.writefile({ 'return true' }, vim.fs.joinpath(dir, name))
  end
  return names
end

h.describe('Base46 cache loading', function()
  h.it('executes only sorted allowlisted regular files', function()
    h.with_temp_dir(function(tmp)
      local cache = load_cache()
      local names = write_allowed(cache, tmp)
      vim.fn.writefile({ 'return false' }, vim.fs.joinpath(tmp, 'stale-arbitrary-entry'))
      local executed = {}

      cache.load {
        dir = tmp,
        integrations = integrations,
        execute = function(path) executed[#executed + 1] = path end,
      }

      local canonical = assert(vim.uv.fs_realpath(tmp))
      local expected = vim.tbl_map(function(name)
        return vim.fs.joinpath(canonical, name)
      end, names)
      h.deep_equal(executed, expected)
      h.falsy(vim.tbl_contains(vim.tbl_map(vim.fs.basename, executed), 'stale-arbitrary-entry'))
    end)
  end)

  h.it('rejects a named directory with actionable regeneration guidance', function()
    h.with_temp_dir(function(tmp)
      local cache = load_cache()
      write_allowed(cache, tmp)
      local dap = vim.fs.joinpath(tmp, 'dap')
      h.equal(vim.fn.delete(dap), 0)
      h.equal(vim.fn.mkdir(dap), 1)

      local ok, err = pcall(cache.load, {
        dir = tmp,
        integrations = integrations,
        execute = function() error 'must not execute an invalid cache' end,
      })
      h.falsy(ok)
      h.matches(err, 'dap')
      h.matches(err, 'require("base46").compile()')
    end)
  end)

  h.it('stops at an execution failure and names the corrupt entry', function()
    h.with_temp_dir(function(tmp)
      local cache = load_cache()
      write_allowed(cache, tmp)
      local executed = {}
      local ok, err = pcall(cache.load, {
        dir = tmp,
        integrations = { 'dap' },
        execute = function(path)
          local name = vim.fs.basename(path)
          if name == 'dap' then error 'corrupt bytecode' end
          executed[#executed + 1] = name
        end,
      })

      h.falsy(ok)
      h.matches(err, 'dap')
      h.matches(err, 'corrupt bytecode')
      h.matches(err, 'require("base46").compile()')
      h.falsy(vim.tbl_contains(executed, 'defaults'), 'loading must stop after the failing entry')
    end)
  end)
end)
```

- [ ] **Step 2: Run the cache spec and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/cache_spec.lua
```

Expected: FAIL with `module 'nv_ide.cache' not found`.

- [ ] **Step 3: Implement deterministic cache loading**

Create a module whose core allowlist is:

```lua
local core = {
  'blankline', 'blink', 'cmp', 'colors', 'defaults', 'devicons', 'git', 'lsp',
  'mason', 'notify', 'nvcheatsheet', 'nvimtree', 'statusline', 'syntax', 'tbline',
  'telescope', 'term', 'treesitter', 'whichkey',
}
```

`allowed(integrations)` must merge, deduplicate, validate names with `^[%w_-]+$`, and sort. Start `load(opts)` with this canonical directory boundary:

```lua
local requested_dir = vim.fs.normalize(assert(opts.dir, 'Base46 cache directory is required'))
local realpath = opts.realpath or vim.uv.fs_realpath
local lstat = opts.fs_lstat or vim.uv.fs_lstat
local dir = realpath(requested_dir)
if not dir then
  error('Base46 cache directory is missing; regenerate with :lua require("base46").compile()', 0)
end
```

For every sorted allowlisted name, join it to `requested_dir`, require `lstat(lexical_path).type == 'file'`, resolve the canonical path, and require `vim.fs.dirname(path) == dir`. Wrap `opts.execute or dofile` with `pcall`; on the first invalid path or execution error, stop and raise a message containing the entry name, the underlying error when present, and `regenerate with :lua require("base46").compile()`.

Replace `init.lua`'s `readdir` loop with:

```lua
require('nv_ide.cache').load {
  dir = vim.g.base46_cache,
  integrations = require('nvconfig').base46.integrations,
}
```

- [ ] **Step 4: Run the cache spec and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/cache_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit constrained startup loading**

```sh
git add tests/headless/cache_spec.lua lua/nv_ide/cache.lua init.lua
git commit -m "fix(startup): constrain Base46 cache"
```

### Task 8: Preserve DAP lazy loading in the statusline

**Files:**
- Modify: `tests/headless/dap_spec.lua`
- Modify: `lua/chadrc.lua`

- [ ] **Step 1: Write the failing lazy-load test**

Add this test to `tests/headless/dap_spec.lua`:

```lua
h.it('renders DAP status without triggering its loader', function()
  local previous_loaded = package.loaded.dap
  local previous_preload = package.preload.dap
  local loads, status_calls = 0, 0
  package.loaded.dap = nil
  package.preload.dap = function()
    loads = loads + 1
    return { status = function() return 'unexpected' end }
  end

  local ok, err = xpcall(function()
    local render = dofile('lua/chadrc.lua').ui.statusline.modules.dap
    local rendered = render()
    h.equal(loads, 0, 'statusline rendering loaded nvim-dap')
    h.equal(rendered, nil)

    package.loaded.dap = {
      status = function()
        status_calls = status_calls + 1
        return 'running'
      end,
    }
    h.equal(render(), '   running ')
    h.equal(status_calls, 1)
  end, debug.traceback)

  package.loaded.dap = previous_loaded
  package.preload.dap = previous_preload
  if not ok then error(err, 0) end
end)
```

- [ ] **Step 2: Run DAP tests and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/dap_spec.lua
```

Expected: FAIL with `statusline rendering loaded nvim-dap`.

- [ ] **Step 3: Consult only an already-loaded adapter**

Use:

```lua
dap = function()
  local dap = package.loaded.dap
  if not dap then return end
  local status = dap.status()
  if status ~= '' then return '   ' .. status .. ' ' end
end,
```

- [ ] **Step 4: Run DAP tests and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/dap_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit lazy-loading repair**

```sh
git add tests/headless/dap_spec.lua lua/chadrc.lua
git commit -m "fix(statusline): preserve DAP laziness"
```

### Task 9: Run repository-level editor verification

**Files:**
- Verify only

- [ ] **Step 1: Compile every tracked Lua source**

```sh
nvim --clean --headless -u NONE -i NONE \
  -c "lua for _,f in ipairs(vim.fn.glob('**/*.lua', false, true)) do assert(loadfile(f), f) end" \
  -c 'qa!'
```

Expected: exit zero with no Lua compilation error.

- [ ] **Step 2: Run the complete dependency-free headless suite**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua
```

Expected: the final summary reports `0 failed`.

- [ ] **Step 3: Run isolated preflight and whitespace checks**

```sh
tests/headless/no-profile.sh preflight
git diff --check
```

Expected: preflight prints `SMOKE preflight PASS` and `git diff --check` is silent. The networked fresh-startup and resolved-lock publication gate remains owned by Task 5 of `2026-08-01-requested-ide-integrations.md`, after all three plans are implemented.

## Acceptance criteria

- Project roots, containment, JavaScript context, executable selection, and positive-only trust caching are centralized and covered by headless tests.
- Python DAP defaults to the active buffer project; selector, virtualenv, project environment, and ambient Python resolution preserve deterministic priority.
- Format mappings and `formatexpr` use the shared adapter; format-on-save remains disabled until a global or buffer-local toggle enables it.
- Formatter aliases exist, alternative formatters stop after the first available choice, and deliberate formatter chains remain sequential.
- Automatic lint runs once per trusted saved buffer, from that project root; Python uses Ruff only, workflow YAML adds Actionlint, ESLint daemon misses fail, and security scanners never run per buffer.
- Diagnostic and conditional motions have one owner each; terminal mappings are buffer-local and no `autocmd!` can clear another plugin's handler.
- Default file search respects ignore files and does not follow symlinks; ignored files require the explicit “All Files” mapping.
- The ordinary shell and Zellij use distinct mappings.
- Base46 executes only canonical allowlisted regular files, stops on the first failure, and reports regeneration guidance.
- Statusline rendering never loads DAP and calls an already-loaded adapter's status function once.
