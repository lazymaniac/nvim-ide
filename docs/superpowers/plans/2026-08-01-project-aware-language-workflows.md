# Project-Aware Language Workflows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make tests, debug adapters, TypeScript actions, Rust hints, and Java runtime/workspace paths resolve safely from the active project and buffer.

**Architecture:** The shared `nv_ide.project` contract supplies roots, executables, and JavaScript context at invocation time. Language plugins retain generic fallbacks, add project-specific configurations only when discovered, and validate external responses before using them.

**Tech Stack:** Neovim native LSP, nvim-dap, Neotest, nvim-jdtls, rustaceanvim, Mason paths, headless Lua tests.

**Prerequisite:** Complete Task 1 of `2026-08-01-editor-correctness.md` so `nv_ide.project` and the shared Python executable policy exist.

## File map

- `lua/plugins/tests.lua`: invocation-time Python and Jest adapter options.
- `lua/plugins/lsp/lang/kotlin.lua`: launch-time Kotlin project roots and attach inputs.
- `lua/plugins/lsp/lang/typescript.lua`: project-scoped JavaScript launch/framework providers and validated move-file actions.
- `lua/plugins/lsp/lang/rust.lua`: buffer-local inlay hints.
- `lua/nv_ide/project.lua`: JavaScript framework configurations shared with DAP and Neotest.
- `lua/nv_ide/java.lua`: bounded discovery and collision-free workspace identity.
- `lua/plugins/lsp/lang/java.lua`: deferred Java options and portable bundle paths.
- `lua/util/init.lua` and `lua/plugins/lint_and_format.lua`: portable Mason root and Sonar paths.
- `tests/headless/*_spec.lua`: focused adapter, loading, path, and boundary regressions.

---

### Task 1: Resolve Neotest Python and Jest from each project

**Files:**
- Modify: `lua/plugins/tests.lua`
- Modify: `tests/headless/dap_spec.lua`

- [ ] **Step 1: Write the failing adapter-option test**

Add:

```lua
h.it('resolves Neotest Python and Jest from the test project', function()
  local neotest = plugin(dofile('lua/plugins/tests.lua'), 'nvim-neotest/neotest')
  local opts = neotest.opts()
  local previous_dap = package.loaded['util.dap']
  local previous_project = package.loaded['nv_ide.project']
  local python_root
  package.loaded['util.dap'] = {
    resolve_python = function(options)
      python_root = options.cwd
      return '/repo/.venv/bin/python'
    end,
  }
  package.loaded['nv_ide.project'] = {
    javascript = function(path)
      if path == '/repo/packages/web/src/example.test.ts' then
        return {
          root = '/repo/packages/web',
          configs = { jest = '/repo/packages/web/jest.config.ts' },
          executables = { jest = '/repo/packages/web/node_modules/.bin/jest' },
        }
      end
      h.equal(path, '/repo/web/src/fallback.test.js')
      return { root = '/repo/web', configs = {}, executables = {} }
    end,
  }

  local ok, err = xpcall(function()
    local python = opts.adapters['neotest-python']
    h.equal(python.python('/repo'), '/repo/.venv/bin/python')
    h.equal(python_root, '/repo')
    local jest = opts.adapters['neotest-jest']
    local path = '/repo/packages/web/src/example.test.ts'
    h.equal(jest.jestCommand(path), '/repo/packages/web/node_modules/.bin/jest')
    h.equal(jest.jestConfigFile(path), '/repo/packages/web/jest.config.ts')
    h.equal(jest.cwd(path), '/repo/packages/web')

    local fallback = '/repo/web/src/fallback.test.js'
    h.equal(jest.jestCommand(fallback), 'jest')
    h.equal(jest.jestConfigFile(fallback), '')
    h.equal(jest.cwd(fallback), '/repo/web')
  end, debug.traceback)

  package.loaded['util.dap'] = previous_dap
  package.loaded['nv_ide.project'] = previous_project
  if not ok then error(err, 0) end
end)
```

- [ ] **Step 2: Run DAP/adapter tests and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/dap_spec.lua
```

Expected: FAIL with `attempt to call field 'opts' (a nil value)`.

- [ ] **Step 3: Make options inspectable and project-aware**

Move the exact existing options table, from `local opts = {` through its matching closing brace after `watch`, byte-for-byte into a new `opts = function()` field that returns that table. Change `config = function()` to `config = function(_, opts)`; keep the which-key registration, Neotest namespace configuration, adapter materialization loop, and `require('neotest').setup(opts)` in that config function. Within the moved options table, replace the two adapter entries with:

```lua
['neotest-python'] = {
  dap = { justMyCode = false },
  args = { '--log-level', 'DEBUG' },
  runner = 'pytest',
  python = function(root)
    return require('util.dap').resolve_python { cwd = root }
  end,
  pytest_discover_instances = true,
},
['neotest-jest'] = {
  jestCommand = function(path)
    return require('nv_ide.project').javascript(path).executables.jest or 'jest'
  end,
  jestConfigFile = function(path)
    return require('nv_ide.project').javascript(path).configs.jest or ''
  end,
  cwd = function(path)
    return require('nv_ide.project').javascript(path).root
  end,
  env = { CI = true },
},
```

Do not alter any other adapter or Neotest option while moving the table.
The empty `jestConfigFile` result is intentional: Neotest-Jest omits `--config` when that path does not exist, allowing Jest to discover package configuration from the project `cwd` without testing a relative `jest.config.js` against Neovim's unrelated global CWD.

- [ ] **Step 4: Run DAP/adapter tests and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/dap_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit project-aware tests**

```sh
git add lua/plugins/tests.lua tests/headless/dap_spec.lua
git commit -m "fix(test): resolve adapters from active project"
```

### Task 2: Build Kotlin and JavaScript DAP configurations per project

**Files:**
- Modify: `lua/plugins/lsp/lang/kotlin.lua`
- Modify: `lua/plugins/lsp/lang/typescript.lua`
- Modify: `tests/headless/dap_spec.lua`

- [ ] **Step 1: Write the failing Kotlin invocation-time test**

Add this test to `tests/headless/dap_spec.lua`:

```lua
h.it('resolves Kotlin project and attach inputs when a session launches', function()
  local kotlin = plugin(dofile('lua/plugins/lsp/lang/kotlin.lua'), 'mfussenegger/nvim-dap')
  local previous_dap = package.loaded.dap
  local previous_project = package.loaded['nv_ide.project']
  local previous_input = vim.fn.input
  local dap = { adapters = {}, configurations = {} }
  local root_calls, input_calls = {}, {}
  package.loaded.dap = dap
  package.loaded['nv_ide.project'] = {
    root = function(target, markers)
      root_calls[#root_calls + 1] = { target = target, markers = markers }
      return '/repo/service'
    end,
  }
  vim.fn.input = function(prompt, default)
    input_calls[#input_calls + 1] = { prompt = prompt, default = default }
    return default
  end

  local ok, err = xpcall(function()
    kotlin.opts.setup.kotlin_debug_adapter()
    local launch, attach = unpack(dap.configurations.kotlin)
    h.equal(type(launch.projectRoot), 'function')
    h.equal(type(attach.projectRoot), 'function')
    h.equal(launch.projectRoot(), '/repo/service')
    h.equal(attach.projectRoot(), '/repo/service')
    h.equal(attach.hostName(), 'localhost')
    h.equal(attach.port(), 5005)
    h.equal(#root_calls, 2)
    for _, call in ipairs(root_calls) do
      h.equal(call.target, 0)
      h.truthy(vim.tbl_contains(call.markers, 'settings.gradle.kts'))
      h.truthy(vim.tbl_contains(call.markers, 'gradlew'))
      h.truthy(vim.tbl_contains(call.markers, 'mvnw'))
    end
    h.deep_equal(input_calls, {
      { prompt = 'Kotlin debug host: ', default = 'localhost' },
      { prompt = 'Kotlin debug port: ', default = '5005' },
    })

    vim.fn.input = function(prompt)
      return prompt:find('host', 1, true) and 'debug.example' or '6006'
    end
    h.equal(attach.hostName(), 'debug.example')
    h.equal(attach.port(), 6006)
  end, debug.traceback)

  package.loaded.dap = previous_dap
  package.loaded['nv_ide.project'] = previous_project
  vim.fn.input = previous_input
  if not ok then error(err, 0) end
end)
```

- [ ] **Step 2: Write the failing JavaScript provider test**

Add this test to `tests/headless/dap_spec.lua`:

```lua
h.it('aggregates JavaScript debug configs once from the active project', function()
  local previous_dap = package.loaded.dap
  local previous_vscode = package.loaded['dap.ext.vscode']
  local previous_utils = package.loaded['dap.utils']
  local previous_project = package.loaded['nv_ide.project']
  local previous_util = package.loaded.util
  local queried = {}
  local vscode = {
    type_to_filetypes = {},
    getconfigs = function(path)
      queried[#queried + 1] = path
      if path == '/unrelated/.vscode/launch.json' then
        return { { type = 'pwa-node', request = 'launch', name = 'Unrelated' } }
      end
      h.equal(path, '/repo/web/.vscode/launch.json')
      return {
        { type = 'pwa-node', request = 'launch', name = 'Workspace launch' },
        { type = 'python', request = 'launch', name = 'Wrong adapter' },
      }
    end,
  }
  local dap = { adapters = {}, configurations = {}, providers = { configs = {} } }
  dap.providers.configs['dap.global'] = function(bufnr)
    return dap.configurations[vim.bo[bufnr].filetype] or {}
  end
  dap.providers.configs['dap.launch.json'] = function()
    return vscode.getconfigs '/unrelated/.vscode/launch.json'
  end
  package.loaded.dap = dap
  package.loaded['dap.ext.vscode'] = vscode
  package.loaded['dap.utils'] = { pick_process = function() return 17 end }
  package.loaded['nv_ide.project'] = {
    javascript = function()
      return {
        root = '/repo/web',
        launch_json = '/repo/web/.vscode/launch.json',
        package_manager = 'pnpm',
        executables = { jest = '/repo/web/node_modules/.bin/jest' },
        configs = {
          jest = '/repo/web/jest.config.ts',
          mocha = '/repo/web/.mocharc.json',
          karma = '/repo/web/karma.conf.ts',
          jasmine = '/repo/web/spec/support/jasmine.json',
        },
      }
    end,
  }
  package.loaded.util = {
    get_pkg_path = function(package, path)
      h.equal(package, 'js-debug-adapter')
      h.equal(path, 'js-debug/src/dapDebugServer.js')
      return '/mason/js-debug/src/dapDebugServer.js'
    end,
    lsp = {
      action = setmetatable({}, { __index = function() return function() end end }),
      execute = function() end,
      get_clients = function() return {} end,
      on_attach = function() end,
    },
  }

  local jsbuf = vim.api.nvim_create_buf(false, true)
  local luabuf = vim.api.nvim_create_buf(false, true)
  vim.bo[jsbuf].filetype = 'typescript'
  vim.bo[luabuf].filetype = 'lua'
  local ok, err = xpcall(function()
    local typescript = plugin(dofile('lua/plugins/lsp/lang/typescript.lua'), 'mfussenegger/nvim-dap')
    typescript.opts()
    for _, filetype in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue' } do
      h.equal(#dap.configurations[filetype], 2)
    end

    local aggregated = {}
    for _, provider in pairs(dap.providers.configs) do
      vim.list_extend(aggregated, provider(jsbuf))
    end
    local by_name = {}
    for _, config in ipairs(aggregated) do
      by_name[config.name] = (by_name[config.name] or 0) + 1
    end
    h.equal(by_name['Workspace launch'], 1)
    h.falsy(by_name['Wrong adapter'])
    h.falsy(by_name.Unrelated)
    h.equal(by_name['Jest Current File'], 1)
    h.equal(by_name['Mocha Current File'], 1)
    h.equal(by_name['Karma All Tests'], 1)
    h.equal(by_name['Jasmine Current File'], 1)
    h.deep_equal(queried, { '/repo/web/.vscode/launch.json' })

    local frameworks = dap.providers.configs.nv_ide_javascript(jsbuf)
    local framework_by_name = {}
    for _, config in ipairs(frameworks) do framework_by_name[config.name] = config end
    h.equal(framework_by_name['Jest Current File'].program, '/repo/web/node_modules/.bin/jest')
    h.equal(framework_by_name['Mocha Current File'].runtimeExecutable, 'pnpm')
    h.deep_equal(framework_by_name['Mocha Current File'].runtimeArgs, { 'exec', 'mocha' })

    h.deep_equal(dap.providers.configs['dap.launch.json'](luabuf), {
      { type = 'pwa-node', request = 'launch', name = 'Unrelated' },
    })
  end, debug.traceback)

  vim.api.nvim_buf_delete(jsbuf, { force = true })
  vim.api.nvim_buf_delete(luabuf, { force = true })
  package.loaded.dap = previous_dap
  package.loaded['dap.ext.vscode'] = previous_vscode
  package.loaded['dap.utils'] = previous_utils
  package.loaded['nv_ide.project'] = previous_project
  package.loaded.util = previous_util
  if not ok then error(err, 0) end
end)
```

- [ ] **Step 3: Run DAP tests and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/dap_spec.lua
```

Expected: FAIL because Kotlin captures `<cwd>/app`, JavaScript registers ten project-assuming entries, and no project provider exists.

- [ ] **Step 4: Resolve Kotlin fields at launch time**

Use:

```lua
local markers = {
  'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts',
  'gradlew', 'mvnw', 'pom.xml', '.git',
}
local function project_root()
  return require('nv_ide.project').root(0, markers)
end
```

Set both `projectRoot = project_root`. Set attach inputs to:

```lua
hostName = function() return vim.fn.input('Kotlin debug host: ', 'localhost') end,
port = function() return tonumber(vim.fn.input('Kotlin debug port: ', '5005')) end,
```

- [ ] **Step 5: Replace unconditional JavaScript framework entries**

Keep these two static configurations for each JS filetype, assigning `vim.deepcopy(generic)` so filetypes do not share a mutable table:

```lua
local generic = {
  { type = 'pwa-node', request = 'launch', name = 'Launch file', program = '${file}', cwd = '${workspaceFolder}' },
  {
    type = 'pwa-node', request = 'attach', name = 'Attach to Node process',
    processId = require('dap.utils').pick_process, cwd = '${workspaceFolder}',
  },
}
```

Preserve the original launch provider for non-JavaScript buffers, but replace its JavaScript behavior with project-local and adapter-type-filtered loading:

```lua
local default_launch_provider = dap.providers.configs['dap.launch.json']
dap.providers.configs['dap.launch.json'] = function(bufnr)
  if not vim.tbl_contains(js_filetypes, vim.bo[bufnr].filetype) then
    return default_launch_provider and default_launch_provider(bufnr) or {}
  end
  local context = require('nv_ide.project').javascript(bufnr)
  if not context.launch_json then return {} end
  local ok, configs = pcall(require('dap.ext.vscode').getconfigs, context.launch_json)
  if not ok then
    vim.notify('JavaScript launch.json: ' .. tostring(configs), vim.log.levels.WARN)
    return {}
  end
  return vim.tbl_filter(function(config)
    return config.type == 'node' or config.type == 'pwa-node'
  end, configs or {})
end
```

Add framework-command and argument helpers:

```lua
local package_exec_args = {
  npm = { 'exec', '--' },
  pnpm = { 'exec' },
  yarn = { 'exec' },
  bun = { 'x' },
}

local function framework_command(context, name)
  local executable = context.executables[name]
  if executable then return { program = executable } end
  local prefix = context.package_manager and package_exec_args[context.package_manager]
  if not context.configs[name] or not prefix then return nil end
  local runtime_args = vim.deepcopy(prefix)
  runtime_args[#runtime_args + 1] = name
  return { runtimeExecutable = context.package_manager, runtimeArgs = runtime_args }
end

local function configured_args(context, name, args, flag)
  args = vim.deepcopy(args)
  local config = context.configs[name]
  if config and flag then
    args[#args + 1] = flag
    args[#args + 1] = config
  end
  return args
end

local function add_framework(configs, context, name, config)
  local command = framework_command(context, name)
  if command then
    configs[#configs + 1] = vim.tbl_deep_extend('force', config, command)
  end
end
```

Register a framework-only provider; workspace launch configurations remain owned solely by the overridden built-in provider:

```lua
dap.providers.configs.nv_ide_javascript = function(bufnr)
  if not vim.tbl_contains(js_filetypes, vim.bo[bufnr].filetype) then return {} end
  local context = require('nv_ide.project').javascript(bufnr)
  if not context.root then return {} end
  local configs = {}

  add_framework(configs, context, 'jest', {
      type = 'pwa-node', request = 'launch', name = 'Jest Current File',
      args = configured_args(context, 'jest', { '--runInBand', '${relativeFile}' }, '--config'),
      cwd = context.root, console = 'integratedTerminal', internalConsoleOptions = 'neverOpen',
  })
  add_framework(configs, context, 'mocha', {
      type = 'pwa-node', request = 'launch', name = 'Mocha Current File',
      args = configured_args(context, 'mocha', { '--timeout', '999999', '--colors', '${file}' }, '--config'),
      cwd = context.root, console = 'integratedTerminal', internalConsoleOptions = 'neverOpen',
  })
  local karma_args = { 'start' }
  if context.configs.karma then karma_args[#karma_args + 1] = context.configs.karma end
  vim.list_extend(karma_args, { '--browsers', 'ChromeHeadless' })
  add_framework(configs, context, 'karma', {
      type = 'pwa-node', request = 'launch', name = 'Karma All Tests',
      args = karma_args,
      cwd = context.root, console = 'integratedTerminal', internalConsoleOptions = 'neverOpen',
  })
  local jasmine_args = { '${file}' }
  if context.configs.jasmine then
    jasmine_args[#jasmine_args + 1] = '--config=' .. context.configs.jasmine
  end
  add_framework(configs, context, 'jasmine', {
      type = 'pwa-node', request = 'launch', name = 'Jasmine Current File',
      args = jasmine_args,
      cwd = context.root, console = 'integratedTerminal', internalConsoleOptions = 'neverOpen',
  })
  return configs
end
```

Remove duplicate npm-test and all unconditional Mocha/Jest/Karma/Jasmine entries. Keep the existing `node` to `pwa-node` adapter compatibility and `vscode.type_to_filetypes` registration.

- [ ] **Step 6: Run DAP tests and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/dap_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 7: Commit project-aware debug adapters**

```sh
git add lua/plugins/lsp/lang/kotlin.lua lua/plugins/lsp/lang/typescript.lua tests/headless/dap_spec.lua
git commit -m "fix(dap): build project-aware Kotlin and JS configs"
```

### Task 3: Validate TypeScript move-file responses and scope Rust inlays

**Files:**
- Modify: `lua/plugins/lsp/lang/typescript.lua`
- Modify: `lua/plugins/lsp/lang/rust.lua`
- Modify: `tests/headless/lsp_registry_spec.lua`
- Modify: `tests/headless/privacy_loading_spec.lua`

- [ ] **Step 1: Add failing TypeScript response cases**

Drive the registered command with missing arguments and these response pairs:

```lua
local responses = {
  { { message = 'request failed' }, nil },
  { nil, nil },
  { nil, {} },
  { nil, { body = {} } },
  { nil, { body = { files = 'invalid' } } },
  { nil, { body = { files = { false } } } },
}
```

In the existing `invokes vtsls request methods with the client as self` test, insert this block after `attached(client, 1)` and before the current happy-path request stub:

```lua
local responses = {
  { { message = 'request failed' }, nil },
  { nil, nil },
  { nil, {} },
  { nil, { body = {} } },
  { nil, { body = { files = 'invalid' } } },
  { nil, { body = { files = { false } } } },
}
local handler = client.commands['_typescript.moveToFileRefactoring']
local valid_command = {
  command = 'typescript.moveToFile',
  arguments = {
    'move',
    vim.uri_from_fname('/tmp/source.ts'),
    { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 1 } },
  },
}
local saved_select = vim.ui.select
local saved_notify = vim.notify
local notifications = {}
vim.notify = function(message, level)
  notifications[#notifications + 1] = { message = message, level = level }
end

local negative_ok, negative_err = xpcall(function()
  local requests = 0
  client.request = function() requests = requests + 1 end
  handler {}
  h.equal(requests, 0)
  h.equal(#notifications, 1)

  for _, response in ipairs(responses) do
    notifications = {}
    local selections = 0
    client.request = function(self, _, _, callback)
      h.equal(self, client)
      requests = requests + 1
      callback(response[1], response[2])
    end
    vim.ui.select = function() selections = selections + 1 end
    local invoked, invoke_error = pcall(handler, valid_command)
    h.truthy(invoked, tostring(invoke_error))
    h.equal(selections, 0)
    h.equal(#notifications, 1)
    h.truthy(vim.startswith(notifications[1].message, 'TypeScript move-to-file:'))
    h.equal(notifications[1].level, vim.log.levels.WARN)
  end

  notifications = {}
  requests = 0
  client.request = function(self, _, params, callback)
    h.equal(self, client)
    requests = requests + 1
    if params.command == 'typescript.tsserverRequest' then
      callback(nil, { body = { files = { '/tmp/target.ts' } } })
    else
      callback({ message = 'move failed' })
    end
  end
  vim.ui.select = function(_, _, callback) callback('/tmp/target.ts') end
  handler(valid_command)
  h.equal(requests, 2)
  h.equal(#notifications, 1)
  h.matches(notifications[1].message, 'move failed')
end, debug.traceback)

vim.ui.select = saved_select
vim.notify = saved_notify
if not negative_ok then error(negative_err, 0) end
```

Keep the existing happy-path assertions afterward so both successful LSP requests still prove that `client` is passed as `self`.

- [ ] **Step 2: Add the failing Rust buffer-local test**

Add this test to `tests/headless/privacy_loading_spec.lua`:

```lua
h.it('enables Rust inlay hints only for the attached buffer', function()
  local rust = plugin(dofile('lua/plugins/lsp/lang/rust.lua'), 'mrcjkb/rustaceanvim')
  local previous_which_key = package.loaded['which-key']
  local previous_enable = vim.lsp.inlay_hint.enable
  local previous_config = vim.g.rustaceanvim
  local calls = {}
  package.loaded['which-key'] = { add = function() end }
  vim.lsp.inlay_hint.enable = function(enabled, opts)
    calls[#calls + 1] = { enabled, opts }
  end

  local ok, err = xpcall(function()
    rust.config()
    vim.g.rustaceanvim.server.on_attach({}, 42)
  end, debug.traceback)

  package.loaded['which-key'] = previous_which_key
  vim.lsp.inlay_hint.enable = previous_enable
  vim.g.rustaceanvim = previous_config
  if not ok then error(err, 0) end
  h.deep_equal(calls, { { true, { bufnr = 42 } } })
end)
```

- [ ] **Step 3: Run focused LSP specs and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/lsp_registry_spec.lua \
  tests/headless/privacy_loading_spec.lua
```

Expected: TypeScript throws from `unpack`/`result.body`, and Rust passes no buffer options.

- [ ] **Step 4: Guard the TypeScript command boundary**

Replace the complete `_typescript.moveToFileRefactoring` handler with:

```lua
local function warn(message)
  vim.notify('TypeScript move-to-file: ' .. tostring(message), vim.log.levels.WARN)
end
client.commands['_typescript.moveToFileRefactoring'] = function(command)
  local args = type(command) == 'table' and command.arguments
  local action, uri, range = type(args) == 'table' and unpack(args) or nil
  local function valid_string(value) return type(value) == 'string' and value ~= '' end
  local function valid_position(position)
    return type(position) == 'table'
      and type(position.line) == 'number' and position.line >= 0
      and type(position.character) == 'number' and position.character >= 0
  end
  local valid_range = type(range) == 'table'
    and valid_position(range.start) and valid_position(range['end'])
  if type(command) ~= 'table' or not valid_string(command.command)
    or not valid_string(action) or not valid_string(uri) or not valid_range
  then
    warn 'invalid command arguments'
    return
  end
  local function move(newf)
    client:request('workspace/executeCommand', {
      command = command.command,
      arguments = { action, uri, range, newf },
    }, function(err)
      if err then warn(err.message or tostring(err)) end
    end)
  end
  local converted, fname = pcall(vim.uri_to_fname, uri)
  if not converted then warn('invalid document URI: ' .. tostring(fname)); return end
  client:request('workspace/executeCommand', {
    command = 'typescript.tsserverRequest',
    arguments = { 'getMoveToRefactoringFileSuggestions', {
      file = fname,
      startLine = range.start.line + 1, startOffset = range.start.character + 1,
      endLine = range['end'].line + 1, endOffset = range['end'].character + 1,
    } },
  }, function(err, result)
    if err then warn(err.message or tostring(err)); return end
    local files = result and result.body and result.body.files
    local valid_files = vim.islist(files) and #files > 0
    if valid_files then
      for _, file in ipairs(files) do
        if type(file) ~= 'string' or file == '' then valid_files = false; break end
      end
    end
    if not valid_files then warn 'server returned no destinations'; return end
    files = vim.deepcopy(files)
    table.insert(files, 1, 'Enter new path...')
    vim.ui.select(files, {
      prompt = 'Select move destination:',
      format_item = function(file) return vim.fn.fnamemodify(file, ':~:.') end,
    }, function(file)
      if file and file:find('^Enter new path') then
        vim.ui.input({
          prompt = 'Enter move destination:',
          default = vim.fn.fnamemodify(fname, ':h') .. '/',
          completion = 'file',
        }, function(newf)
          if type(newf) == 'string' and newf ~= '' then move(newf) end
        end)
      elseif file then
        move(file)
      end
    end)
  end)
end
```

- [ ] **Step 5: Scope Rust hints to the attached buffer**

Use:

```lua
vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
```

- [ ] **Step 6: Run focused LSP specs and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/lsp_registry_spec.lua \
  tests/headless/privacy_loading_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 7: Commit boundary validation**

```sh
git add lua/plugins/lsp/lang/typescript.lua lua/plugins/lsp/lang/rust.lua tests/headless/lsp_registry_spec.lua tests/headless/privacy_loading_spec.lua
git commit -m "fix(lsp): validate actions and scope Rust inlays"
```

### Task 4: Defer and bound Java runtime discovery

**Files:**
- Modify: `lua/nv_ide/java.lua`
- Modify: `lua/plugins/lsp/lang/java.lua`
- Modify: `tests/headless/deprecated_api_spec.lua`
- Modify: `tests/headless/privacy_loading_spec.lua`

- [ ] **Step 1: Write failing timeout and load-boundary tests**

Add this test to `tests/headless/deprecated_api_spec.lua`:

```lua
h.it('bounds both external Java home probes', function()
  local java = require 'nv_ide.java'
  local function timeout_case(os_name, exepaths, expected_argv, expected_error)
    local calls = {}
    local discovered = java.discover {
      env = {},
      os = os_name,
      exepath = function(command) return exepaths[command] or '' end,
      stdpath = function(kind) return '/xdg/' .. kind end,
      realpath = function(path) return path end,
      glob = function() return {} end,
      is_executable = function() return false end,
      read_file = function() return nil end,
      command_executable = function(path) return path == expected_argv[1] end,
      probe_timeout_ms = 25,
      system = function(argv, opts)
        h.deep_equal(opts, { text = true })
        return {
          wait = function(_, timeout)
            calls[#calls + 1] = { argv = vim.deepcopy(argv), timeout = timeout }
            return { code = 124, stdout = '', stderr = '' }
          end,
        }
      end,
    }
    h.deep_equal(calls, { { argv = expected_argv, timeout = 25 } })
    h.truthy(vim.tbl_contains(discovered.errors, expected_error))
  end

  timeout_case(
    'Linux',
    { asdf = '/tools/asdf' },
    { '/tools/asdf', 'where', 'java' },
    'asdf where java timed out after 25 ms'
  )
  timeout_case(
    'Darwin',
    {},
    { '/usr/libexec/java_home' },
    'macOS java_home timed out after 25 ms'
  )
end)

h.it('reports Java probe spawn, wait, and exit failures', function()
  local java = require 'nv_ide.java'
  local cases = {
    {
      expected = 'failed to start',
      system = function() error 'spawn denied' end,
    },
    {
      expected = 'failed while waiting',
      system = function()
        return { wait = function() error 'wait broke' end }
      end,
    },
    {
      expected = 'exited 7: broken probe',
      system = function()
        return { wait = function() return { code = 7, stderr = 'broken probe\n' } end }
      end,
    },
  }
  for _, case in ipairs(cases) do
    local discovered = java.discover {
      env = {},
      os = 'Linux',
      exepath = function(command) return command == 'asdf' and '/tools/asdf' or '' end,
      stdpath = function(kind) return '/xdg/' .. kind end,
      realpath = function(path) return path end,
      glob = function() return {} end,
      is_executable = function() return false end,
      read_file = function() return nil end,
      command_executable = function(path) return path == '/tools/asdf' end,
      system = case.system,
    }
    h.matches(table.concat(discovered.errors, '\n'), case.expected)
  end
end)
```

Add this test to `tests/headless/privacy_loading_spec.lua`:

```lua
h.it('discovers Java only at its filetype-triggered options boundary', function()
  local previous_java = package.loaded['nv_ide.java']
  local previous_setup = package.loaded['jdtls.setup']
  local previous_notify = vim.notify
  local discoveries, notifications = 0, {}
  package.loaded['nv_ide.java'] = {
    discover = function()
      discoveries = discoveries + 1
      return {
        jdtls = '/tools/jdtls',
        lombok = '/mason/share/jdtls/lombok.jar',
        formatter = '/config/java-formatter.xml',
        runtimes = {},
        errors = { 'asdf where java timed out after 25 ms' },
      }
    end,
  }
  package.loaded['jdtls.setup'] = { find_root = function() return '/repo' end }
  vim.notify = function(message, level)
    notifications[#notifications + 1] = { message = message, level = level }
  end

  local ok, err = xpcall(function()
    local java = plugin(dofile('lua/plugins/lsp/lang/java.lua'), 'mfussenegger/nvim-jdtls')
    h.equal(discoveries, 0)
    h.equal(#notifications, 0)
    local opts = java.opts()
    h.equal(discoveries, 1)
    h.equal(opts.cmd[1], '/tools/jdtls')
    h.equal(opts.paths.lombok, '/mason/share/jdtls/lombok.jar')
    h.equal(#notifications, 1)
    h.matches(notifications[1].message, 'asdf where java timed out after 25 ms')
    h.equal(notifications[1].level, vim.log.levels.WARN)
  end, debug.traceback)

  package.loaded['nv_ide.java'] = previous_java
  package.loaded['jdtls.setup'] = previous_setup
  vim.notify = previous_notify
  if not ok then error(err, 0) end
end)
```

- [ ] **Step 2: Run Java/loading specs and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/deprecated_api_spec.lua \
  tests/headless/privacy_loading_spec.lua
```

Expected: discovery runs during `dofile` and external probes do not receive bounded wait values.

- [ ] **Step 3: Add bounded external-probe dependencies**

Preserve the existing `options.macos_java_home` and `options.asdf_java_home` overrides for deterministic tests. Inside `java.discover`, add:

```lua
local probe_timeout_ms = options.probe_timeout_ms or 2000
local system = options.system or vim.system
local command_executable = options.command_executable
  or function(path) return vim.fn.executable(path) == 1 end
local errors = {}

local function probe(argv, label)
  if not command_executable(argv[1]) then return nil end
  local spawned, process = pcall(system, argv, { text = true })
  if not spawned then
    errors[#errors + 1] = ('%s failed to start: %s'):format(label, tostring(process))
    return nil
  end
  local waited, result = pcall(function() return process:wait(probe_timeout_ms) end)
  if not waited then
    errors[#errors + 1] = ('%s failed while waiting: %s'):format(label, tostring(result))
    return nil
  end
  if result.code == 124 then
    errors[#errors + 1] = ('%s timed out after %d ms'):format(label, probe_timeout_ms)
    return nil
  end
  if result.code ~= 0 then
    local stderr = vim.trim(result.stderr or '')
    errors[#errors + 1] = ('%s exited %d%s'):format(
      label,
      result.code,
      stderr ~= '' and ': ' .. stderr or ''
    )
    return nil
  end
  return nonempty(vim.trim(result.stdout or ''))
end
```

Use `probe({ '/usr/libexec/java_home' }, 'macOS java_home')` for the default macOS resolver and `probe({ asdf, 'where', 'java' }, 'asdf where java')` for the default asdf resolver. Include `errors = errors` in the returned discovery table.

- [ ] **Step 4: Move discovery into the Java options boundary**

Remove module-level `java_paths`. Change `local jdtls_settings = {` to `local function java_settings(paths) return {`, close that function after the settings table, and make these exact substitutions inside it:

- `java_paths.runtimes` to `paths.runtimes`;
- the Lombok VM argument's `java_paths.lombok` to `paths.lombok`;
- `java_paths.formatter` to `paths.formatter`.

Make the `nvim-jdtls` spec start its options function with:

```lua
opts = function()
  local paths = require('nv_ide.java').discover()
  for _, message in ipairs(paths.errors or {}) do
    vim.notify('Java discovery: ' .. message, vim.log.levels.WARN)
  end
  return {
    paths = paths,
    settings = java_settings(paths),
    root_dir = require('jdtls.setup').find_root,
    project_name = function(root_dir)
      return root_dir and vim.fs.basename(root_dir)
    end,
    jdtls_config_dir = function(project_name)
      return vim.fs.joinpath(vim.fn.stdpath('cache'), 'jdtls', project_name, 'config')
    end,
    jdtls_workspace_dir = function(project_name)
      return vim.fs.joinpath(vim.fn.stdpath('cache'), 'jdtls', project_name, 'workspace')
    end,
    cmd = { paths.jdtls },
    full_cmd = function(opts)
      local root_dir = opts.root_dir(root_markers)
      local project_name = opts.project_name(root_dir)
      local cmd = vim.deepcopy(opts.cmd)
      if project_name then
        vim.list_extend(cmd, {
          '--jvm-arg=-Xmx4g',
          '--jvm-arg=-javaagent:' .. opts.paths.lombok,
          '-configuration',
          opts.jdtls_config_dir(project_name),
          '-data',
          opts.jdtls_workspace_dir(project_name),
        })
      end
      return cmd
    end,
    dap = { hotcodereplace = 'auto', config_overrides = {} },
    test = true,
  }
end,
```

In `config(_, opts)`, replace `settings = jdtls_settings` with `settings = opts.settings`. The bundle paths remain unchanged only until Task 5 replaces them with the Mason helper. After this task, `java.lua` must contain no `java_paths` or `jdtls_settings` identifier, and no discovery or warning may run while the module is merely evaluated.

- [ ] **Step 5: Run Java/loading specs and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/deprecated_api_spec.lua \
  tests/headless/privacy_loading_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 6: Commit Java discovery repair**

```sh
git add lua/nv_ide/java.lua lua/plugins/lsp/lang/java.lua tests/headless/deprecated_api_spec.lua tests/headless/privacy_loading_spec.lua
git commit -m "fix(java): defer and bound runtime discovery"
```

### Task 5: Isolate JDTLS workspaces and remove ambient Mason paths

**Files:**
- Modify: `lua/nv_ide/java.lua`
- Modify: `lua/util/init.lua`
- Modify: `lua/plugins/lsp/lang/java.lua`
- Modify: `lua/plugins/lint_and_format.lua`
- Modify: `tests/headless/deprecated_api_spec.lua`
- Modify: `tests/headless/lint_format_spec.lua`

- [ ] **Step 1: Write failing identity and Mason fallback tests**

Add these tests to `tests/headless/deprecated_api_spec.lua`:

```lua
h.it('builds absolute collision-free JDTLS workspace identities', function()
  local java = require 'nv_ide.java'
  local deps = {
    abspath = function(path)
      return path == 'service' and '/work/acme/service' or path
    end,
    realpath = function() return nil end,
  }
  local expected = java.workspace_id('/work/acme/service', deps)
  h.equal(expected, java.workspace_id('/work/acme/team/../service', deps))
  h.equal(expected, java.workspace_id('service', deps))
  h.falsy(expected == java.workspace_id('/work/other/service', deps))
  h.truthy(expected:match '^service%-%x%x%x%x%x%x%x%x%x%x%x%x$')
end)

h.it('derives Java bundle patterns from one Mason root', function()
  local patterns = require('nv_ide.java').bundle_patterns '/xdg/data/nvim/mason'
  h.deep_equal(patterns, {
    '/xdg/data/nvim/mason/share/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar',
    '/xdg/data/nvim/mason/share/vscode-java-decompiler/bundles/*.jar',
    '/xdg/data/nvim/mason/share/java-test/*.jar',
  })
end)
```

Add this test to `tests/headless/lint_format_spec.lua`:

```lua
h.it('uses the portable Mason root for helpers and Sonar analyzers', function()
  local previous_lazy = package.loaded['lazy.core.util']
  local previous_util = package.loaded.util
  package.loaded['lazy.core.util'] = {}
  package.loaded.util = nil
  local ok, err = xpcall(function()
    local util = require 'util'
    h.equal(util.mason_root {
      env = {},
      stdpath = function() return '/xdg/data/nvim' end,
    }, '/xdg/data/nvim/mason')
    h.equal(util.mason_root {
      env = { MASON = '' },
      stdpath = function() return '/xdg/data/nvim' end,
    }, '/xdg/data/nvim/mason')
    h.equal(util.mason_root {
      env = { MASON = '/custom/mason' },
      stdpath = function() return '/unused' end,
    }, '/custom/mason')
  end, debug.traceback)
  package.loaded['lazy.core.util'] = previous_lazy
  package.loaded.util = previous_util
  if not ok then error(err, 0) end

  local previous_sonarlint = package.loaded.sonarlint
  local previous_util_module = package.loaded.util
  local configured
  package.loaded.util = { mason_root = function() return '/xdg/data/nvim/mason' end }
  package.loaded.sonarlint = { setup = function(opts) configured = opts end }
  local sonar = plugin(dofile('lua/plugins/lint_and_format.lua'), 'https://gitlab.com/schrieveslaach/sonarlint.nvim')
  local configured_ok, configured_err = xpcall(sonar.config, debug.traceback)
  package.loaded.sonarlint = previous_sonarlint
  package.loaded.util = previous_util_module
  if not configured_ok then error(configured_err, 0) end
  for _, path in ipairs(vim.list_slice(configured.server.cmd, 4)) do
    h.truthy(vim.startswith(path, '/xdg/data/nvim/mason/share/sonarlint-analyzers/'), path)
  end

  local source = table.concat(vim.fn.readfile('lua/plugins/lsp/lang/java.lua'), '\n')
    .. table.concat(vim.fn.readfile('lua/plugins/lint_and_format.lua'), '\n')
  h.falsy(source:find('$MASON', 1, true))
end)
```

- [ ] **Step 2: Run focused Java/format specs and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/deprecated_api_spec.lua \
  tests/headless/lint_format_spec.lua
```

Expected: same-named projects collide, `mason_root` is absent, and both sources contain `$MASON`.

- [ ] **Step 3: Add stable workspace and Mason helpers**

Add:

```lua
function M.workspace_id(root, deps)
  if not root then return nil end
  deps = deps or {}
  local realpath = deps.realpath or vim.uv.fs_realpath
  local abspath = deps.abspath or vim.fs.abspath
  local absolute = abspath(root)
  local normalized = vim.fs.normalize(realpath(absolute) or absolute)
  local name = vim.fs.basename(normalized):gsub('[^%w_.-]', '_')
  return ('%s-%s'):format(name, vim.fn.sha256(normalized):sub(1, 12))
end

function M.bundle_patterns(mason)
  return {
    vim.fs.joinpath(mason, 'share', 'java-debug-adapter', 'com.microsoft.java.debug.plugin-*.jar'),
    vim.fs.joinpath(mason, 'share', 'vscode-java-decompiler', 'bundles', '*.jar'),
    vim.fs.joinpath(mason, 'share', 'java-test', '*.jar'),
  }
end
```

In `util/init.lua`:

```lua
function M.mason_root(opts)
  opts = opts or {}
  local env = opts.env or vim.env
  local stdpath = opts.stdpath or vim.fn.stdpath
  local configured = type(env.MASON) == 'string' and env.MASON ~= '' and env.MASON or nil
  return vim.fs.normalize(configured or vim.fs.joinpath(stdpath('data'), 'mason'))
end
```

Make `get_pkg_path()` call `M.mason_root()` and construct its result with `vim.fs.joinpath`.

- [ ] **Step 4: Use the helpers at every affected path**

JDTLS `project_name(root_dir)` must call `require('nv_ide.java').workspace_id(root_dir)`. In Java config, derive `local mason = require('util').mason_root()` once and iterate `require('nv_ide.java').bundle_patterns(mason)` instead of the three `$MASON` globs. In Sonar config, derive the same helper once and use `vim.fs.joinpath(mason, 'share', 'sonarlint-analyzers', filename)` for each of the existing eight analyzer filenames. Remove every `vim.fn.expand` call whose argument starts with `$MASON/`.

- [ ] **Step 5: Run focused specs and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/deprecated_api_spec.lua \
  tests/headless/lint_format_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 6: Commit portable Java paths**

```sh
git add lua/nv_ide/java.lua lua/util/init.lua lua/plugins/lsp/lang/java.lua lua/plugins/lint_and_format.lua tests/headless/deprecated_api_spec.lua tests/headless/lint_format_spec.lua
git commit -m "fix(java): isolate workspaces and Mason paths"
```

### Task 6: Run the language-workflow regression set

**Files:**
- Verify only

- [ ] **Step 1: Run every affected headless spec**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/project_spec.lua \
  tests/headless/dap_spec.lua \
  tests/headless/lsp_registry_spec.lua \
  tests/headless/privacy_loading_spec.lua \
  tests/headless/deprecated_api_spec.lua \
  tests/headless/lint_format_spec.lua
```

Expected: all selected tests PASS and the summary reports `0 failed`.

- [ ] **Step 2: Compile all Lua and run the complete headless suite**

```sh
nvim --clean --headless -u NONE -i NONE \
  -c "lua for _,f in ipairs(vim.fn.glob('**/*.lua', false, true)) do assert(loadfile(f), f) end" \
  -c 'qa!'

nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua
```

Expected: compilation exits zero and the complete suite reports `0 failed`.

- [ ] **Step 3: Run isolated startup and whitespace checks**

```sh
tests/headless/no-profile.sh preflight
git diff --check
```

Expected: preflight prints `SMOKE preflight PASS` and `git diff --check` is silent. Networked fresh startup is intentionally deferred to Task 5 of `2026-08-01-requested-ide-integrations.md`, after every plugin declaration is present.

## Acceptance criteria

- Neotest resolves Python and Jest from the target project and falls back to normal Jest discovery when no explicit config exists.
- Kotlin roots and attach values are evaluated at session launch, never captured from editor CWD.
- JavaScript DAP has two generic fallbacks, one project-local launch provider, and only runnable project-local framework entries; launch configurations are neither duplicated nor read from unrelated CWD.
- TypeScript move-file commands validate all external fields, report suggestion and move failures, and never open UI for malformed responses.
- Rust inlay hints are scoped to the attached buffer.
- Java discovery performs no work at module evaluation, bounds both external probes, and reports failures only at the Java-triggered boundary.
- JDTLS workspace identities include an absolute-root hash, so equal basenames cannot collide.
- Missing or empty `MASON` uses the standard data path for JDTLS bundles, Java decompiler/test jars, and Sonar analyzers.
