# Java JShell Current-Class Runner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Java-buffer command that saves and incrementally builds the current class, launches it through the matching project-aware JShell, and leaves the terminal interactive.

**Architecture:** Extend `nv_ide.java` with a callback-safe runner that captures one buffer and JDTLS client for the full asynchronous pipeline. JDTLS supplies main-class, runtime, classpath, and module-path data; a list-form Neovim terminal job launches JShell without shell interpolation. The Java LSP attachment installs one new buffer-local key while preserving the existing interactive shell key.

**Tech Stack:** Neovim 0.12 Lua, native LSP client requests, nvim-jdtls command contracts, `jobstart(..., { term = true })`, which-key, repository headless Lua harness.

## File map

- `lua/nv_ide/java.lua`: owns buffer validation, save/build orchestration, JDTLS resolution, JShell argv construction, terminal launch, and per-buffer re-entry state.
- `lua/plugins/lsp/lang/java.lua`: installs the Java-only `<leader>cJ` mapping with the captured buffer and client.
- `tests/headless/java_spec.lua`: exercises the asynchronous pipeline and keymap through injected dependencies without spawning JDTLS or JShell.
- `docs/superpowers/specs/2026-08-02-java-jshell-current-class-design.md`: records the approved behavior and resolver/module-path clarification.

---

### Task 1: Build the captured-buffer success pipeline

**Files:**
- Create: `tests/headless/java_spec.lua`
- Modify: `lua/nv_ide/java.lua:1-142`

- [ ] **Step 1: Add the fake JDTLS fixture and successful-run test**

Create `tests/headless/java_spec.lua` with this fixture and first test:

```lua
local h = require 'tests.headless.harness'

local function load_java()
  package.loaded['nv_ide.java'] = nil
  return require 'nv_ide.java'
end

local function fixture(overrides)
  local state = {
    events = {},
    launches = {},
    notifications = {},
    requests = {},
  }
  local client = {
    id = 7,
    name = 'jdtls',
    config = { root_dir = '/repo' },
    server_capabilities = {
      executeCommandProvider = {
        commands = {
          'vscode.java.resolveMainClass',
          'vscode.java.resolveClasspath',
          'vscode.java.resolveJavaExecutable',
        },
      },
    },
  }
  state.client = client
  local readable = {
    ['/repo/out'] = { type = 'directory' },
    ['/repo/lib/runtime.jar'] = { type = 'file' },
    ['/repo/modules'] = { type = 'directory' },
  }
  local deps = {
    buf_is_valid = function(bufnr) return bufnr == 17 end,
    buf_name = function(bufnr)
      h.equal(bufnr, 17)
      return '/repo/src/demo/Current.java'
    end,
    buf_uri = function(bufnr)
      h.equal(bufnr, 17)
      return 'file:///repo/src/demo/Current.java'
    end,
    buf_options = function(bufnr)
      h.equal(bufnr, 17)
      return { buftype = '', filetype = 'java', modifiable = true, readonly = false }
    end,
    save = function(bufnr)
      h.equal(bufnr, 17)
      state.events[#state.events + 1] = 'save'
    end,
    resolve_classname = function(bufnr)
      h.equal(bufnr, 17)
      state.events[#state.events + 1] = 'class'
      return 'demo.Current'
    end,
    get_client = function(client_id, bufnr)
      h.equal(client_id, 7)
      h.equal(bufnr, 17)
      return client
    end,
    request = function(request_client, method, params, callback, bufnr)
      h.equal(request_client, client)
      h.equal(bufnr, 17)
      state.events[#state.events + 1] = method
      state.requests[#state.requests + 1] = {
        method = method,
        params = vim.deepcopy(params),
        callback = callback,
        bufnr = bufnr,
      }
      return true, #state.requests
    end,
    fs_stat = function(path) return readable[path] end,
    is_executable = function(path) return path == '/jdk/bin/jshell' end,
    exepath = function() return '' end,
    path_separator = ':',
    open_terminal = function(argv, input, cwd)
      state.launches[#state.launches + 1] = {
        argv = vim.deepcopy(argv),
        input = input,
        cwd = cwd,
      }
      return true
    end,
    notify = function(message, level)
      state.notifications[#state.notifications + 1] = { message = message, level = level }
    end,
  }
  for key, value in pairs(overrides or {}) do deps[key] = value end
  return state, deps
end

local function respond(state, index, err, result)
  local request = assert(state.requests[index], 'request ' .. index .. ' is missing')
  request.callback(err, result)
end

h.describe('Java current-class JShell runner', function()
  h.it('saves, builds, resolves, and invokes the captured current class', function()
    local java = load_java()
    local state, deps = fixture()

    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
    h.deep_equal(state.events, { 'save', 'class', 'java/buildWorkspace' })
    h.equal(state.requests[1].params, false)

    respond(state, 1, nil, 1)
    h.deep_equal(state.requests[2].params, {
      command = 'vscode.java.resolveMainClass',
    })

    respond(state, 2, nil, {
      { mainClass = 'other.Current', projectName = 'other' },
      { mainClass = 'demo.module/demo.Current', projectName = 'demo' },
    })
    h.deep_equal(state.requests[3].params, {
      command = 'vscode.java.resolveClasspath',
      arguments = { 'demo.module/demo.Current', 'demo' },
    })

    respond(state, 3, nil, {
      { '/repo/modules', '/repo/missing-module' },
      { '/repo/out', '/repo/lib/runtime.jar', '/repo/missing.jar' },
    })
    h.deep_equal(state.requests[4].params, {
      command = 'vscode.java.resolveJavaExecutable',
      arguments = { 'demo.module/demo.Current', 'demo' },
    })

    respond(state, 4, nil, '/jdk/bin/java')
    h.deep_equal(state.launches, {
      {
        argv = {
          '/jdk/bin/jshell',
          '--class-path', '/repo/out:/repo/lib/runtime.jar',
          '--module-path', '/repo/modules',
          '--add-modules', 'ALL-MODULE-PATH',
        },
        input = 'demo.Current.main(new String[0]);\n',
        cwd = '/repo',
      },
    })
    h.equal(#state.notifications, 0)
  end)
end)
```

- [ ] **Step 2: Run the focused test and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/java_spec.lua
```

Expected: FAIL because `nv_ide.java.run_current_class` does not exist.

- [ ] **Step 3: Add the minimal successful orchestration**

In `lua/nv_ide/java.lua`, immediately after `local M = {}`, add the module state and shared helpers:

```lua
local active_jshell_runs = {}
local BUILD_SUCCEEDED = 1

local function class_portion(main_class)
  return type(main_class) == 'string' and (main_class:match('/(.+)$') or main_class) or nil
end

local function existing_paths(paths, fs_stat)
  local result = {}
  for _, path in ipairs(type(paths) == 'table' and paths or {}) do
    local stat = fs_stat(path)
    if stat and (stat.type == 'file' or stat.type == 'directory') then
      result[#result + 1] = path
    end
  end
  return result
end

local function supports_command(client, command)
  local provider = client.server_capabilities and client.server_capabilities.executeCommandProvider
  return type(provider) == 'table' and vim.tbl_contains(provider.commands or {}, command)
end

local function default_client(client_id, bufnr)
  if client_id then
    local client = vim.lsp.get_client_by_id(client_id)
    if client and client.name == 'jdtls' and client.attached_buffers[bufnr] then return client end
    return nil
  end
  local clients = require('jdtls.util').get_clients { name = 'jdtls', bufnr = bufnr }
  return #clients == 1 and clients[1] or nil
end

local function default_dependencies()
  return {
    buf_is_valid = vim.api.nvim_buf_is_valid,
    buf_name = vim.api.nvim_buf_get_name,
    buf_uri = vim.uri_from_bufnr,
    buf_options = function(bufnr)
      return {
        buftype = vim.bo[bufnr].buftype,
        filetype = vim.bo[bufnr].filetype,
        modifiable = vim.bo[bufnr].modifiable,
        readonly = vim.bo[bufnr].readonly,
      }
    end,
    save = function(bufnr)
      vim.api.nvim_buf_call(bufnr, function() vim.cmd.update() end)
    end,
    resolve_classname = function(bufnr)
      return vim.api.nvim_buf_call(bufnr, require('jdtls.util').resolve_classname)
    end,
    get_client = default_client,
    request = function(client, method, params, callback, bufnr)
      return client:request(method, params, callback, bufnr)
    end,
    fs_stat = vim.uv.fs_stat,
    is_executable = function(path) return vim.fn.executable(path) == 1 end,
    exepath = vim.fn.exepath,
    path_separator = vim.fn.has('win32') == 1 and ';' or ':',
    notify = vim.notify,
  }
end
```

Then add this public function immediately before `M.bundle_patterns`:

```lua
function M.run_current_class(options)
  options = options or {}
  local bufnr = options.bufnr or vim.api.nvim_get_current_buf()
  local deps = vim.tbl_extend('force', default_dependencies(), options.deps or {})

  if active_jshell_runs[bufnr] then
    deps.notify('Java JShell: a run is already in progress for this buffer', vim.log.levels.WARN)
    return false
  end

  if not deps.buf_is_valid(bufnr) then
    deps.notify('Java JShell: current buffer is invalid', vim.log.levels.ERROR)
    return false
  end
  local buffer_options = deps.buf_options(bufnr)
  local path = deps.buf_name(bufnr)
  if buffer_options.filetype ~= 'java'
    or buffer_options.buftype ~= ''
    or path == ''
    or not path:lower():match('%.java$')
  then
    deps.notify('Java JShell: current buffer is not a named Java source file', vim.log.levels.ERROR)
    return false
  end
  if buffer_options.readonly or not buffer_options.modifiable then
    deps.notify('Java JShell: current Java buffer is not writable', vim.log.levels.ERROR)
    return false
  end

  local client = deps.get_client(options.client_id, bufnr)
  if not client then
    deps.notify('Java JShell: no JDTLS client is attached to this buffer', vim.log.levels.ERROR)
    return false
  end

  active_jshell_runs[bufnr] = true
  local finished = false
  local function finish(message, level)
    if finished then return false end
    finished = true
    active_jshell_runs[bufnr] = nil
    if message then deps.notify('Java JShell: ' .. message, level or vim.log.levels.ERROR) end
    return not message
  end
  local function request(method, params, callback, label)
    local ok, accepted = pcall(deps.request, client, method, params, callback, bufnr)
    if not ok then return finish(label .. ' failed: ' .. tostring(accepted)) end
    if accepted ~= true then return finish(label .. ' request was rejected by JDTLS') end
    return true
  end

  local saved, save_error = pcall(deps.save, bufnr)
  if not saved then return finish('could not save the current file: ' .. tostring(save_error)) end
  local resolved, class_name = pcall(deps.resolve_classname, bufnr)
  if not resolved or type(class_name) ~= 'string' or class_name == '' then
    return finish('could not resolve the current class name')
  end

  local function launch(main, paths, java_exec)
    local module_paths = existing_paths(paths[1], deps.fs_stat)
    local class_paths = existing_paths(paths[2], deps.fs_stat)
    local suffix = java_exec:lower():match('%.exe$') and '.exe' or ''
    local sibling = vim.fs.joinpath(vim.fs.dirname(java_exec), 'jshell' .. suffix)
    local jshell = deps.is_executable(sibling) and sibling or deps.exepath('jshell')
    if type(jshell) ~= 'string' or jshell == '' then return finish('could not find JShell') end

    local argv = { jshell }
    if #class_paths > 0 then
      vim.list_extend(argv, { '--class-path', table.concat(class_paths, deps.path_separator) })
    end
    if #module_paths > 0 then
      vim.list_extend(argv, {
        '--module-path', table.concat(module_paths, deps.path_separator),
        '--add-modules', 'ALL-MODULE-PATH',
      })
    end
    local cwd = client.config and client.config.root_dir or nil
    local called, ok, terminal_error = pcall(
      deps.open_terminal,
      argv,
      class_name .. '.main(new String[0]);\n',
      cwd
    )
    if not called then return finish('terminal launch failed: ' .. tostring(ok)) end
    if not ok then return finish(terminal_error or 'could not start JShell') end
    return finish()
  end

  local function resolve_java(main, paths)
    local params = {
      command = 'vscode.java.resolveJavaExecutable',
      arguments = { main.mainClass, main.projectName or '' },
    }
    return request('workspace/executeCommand', params, function(err, java_exec)
      if err then return finish('Java executable resolution failed: ' .. (err.message or vim.inspect(err))) end
      if type(java_exec) ~= 'string' or java_exec == '' then
        return finish('JDTLS returned no Java executable')
      end
      launch(main, paths, java_exec)
    end, 'Java executable resolution')
  end

  local function resolve_paths(main)
    local params = {
      command = 'vscode.java.resolveClasspath',
      arguments = { main.mainClass, main.projectName or '' },
    }
    return request('workspace/executeCommand', params, function(err, paths)
      if err then return finish('classpath resolution failed: ' .. (err.message or vim.inspect(err))) end
      if type(paths) ~= 'table' or type(paths[1]) ~= 'table' or type(paths[2]) ~= 'table' then
        return finish('JDTLS returned an invalid classpath response')
      end
      resolve_java(main, paths)
    end, 'classpath resolution')
  end

  local function resolve_main()
    return request('workspace/executeCommand', {
      command = 'vscode.java.resolveMainClass',
    }, function(err, main_classes)
      if err then return finish('main-class resolution failed: ' .. (err.message or vim.inspect(err))) end
      local match
      for _, main in ipairs(type(main_classes) == 'table' and main_classes or {}) do
        if class_portion(main.mainClass) == class_name then
          match = main
          break
        end
      end
      if not match then return finish('the current class has no recognized main(String[]) method') end
      resolve_paths(match)
    end, 'main-class resolution')
  end

  local started = request('java/buildWorkspace', false, function(err, status)
    if err then return finish('incremental build failed: ' .. (err.message or vim.inspect(err))) end
    if status ~= BUILD_SUCCEEDED then
      return finish(('incremental build returned status %s; use <leader>cc for diagnostics'):format(tostring(status)))
    end
    resolve_main()
  end, 'incremental build')
  return started == true
end
```

Task 2 replaces the injected-only terminal assumption and adds the legacy Java-runtime fallback before this function becomes user-facing.

- [ ] **Step 4: Run the focused test and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/java_spec.lua
```

Expected: `1 passed, 0 failed`.

- [ ] **Step 5: Commit the captured-buffer pipeline**

```sh
git add lua/nv_ide/java.lua tests/headless/java_spec.lua
git commit -m "feat(java): build current-class JShell runner"
```

### Task 2: Harden failures, fallback resolution, and terminal startup

**Files:**
- Modify: `tests/headless/java_spec.lua`
- Modify: `lua/nv_ide/java.lua`

- [ ] **Step 1: Add failure, fallback, platform, and terminal tests**

Inside the existing `h.describe`, add tests with these exact outcome assertions:

```lua
h.it('rejects invalid buffers before saving or building', function()
  local cases = {
    { label = 'invalid', overrides = { buf_is_valid = function() return false end }, message = 'buffer is invalid' },
    { label = 'unnamed', overrides = { buf_name = function() return '' end }, message = 'named Java source file' },
    {
      label = 'non-Java',
      overrides = { buf_options = function() return { buftype = '', filetype = 'lua', modifiable = true, readonly = false } end },
      message = 'named Java source file',
    },
    {
      label = 'readonly',
      overrides = { buf_options = function() return { buftype = '', filetype = 'java', modifiable = true, readonly = true } end },
      message = 'not writable',
    },
    { label = 'no JDTLS', overrides = { get_client = function() return nil end }, message = 'no JDTLS client' },
  }
  for _, case in ipairs(cases) do
    local java = load_java()
    local state, deps = fixture(case.overrides)
    h.falsy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps }, case.label)
    h.equal(#state.requests, 0, case.label)
    h.equal(#state.launches, 0, case.label)
    h.matches(state.notifications[#state.notifications].message, case.message, case.label)
  end
end)

h.it('clears the guard after save, request, and build failures', function()
  local cases = {
    {
      label = 'save',
      overrides = { save = function() error 'disk full' end },
      settle = function() end,
      message = 'could not save',
    },
    {
      label = 'request rejected',
      overrides = { request = function() return false end },
      settle = function() end,
      message = 'request was rejected',
    },
    {
      label = 'build error',
      settle = function(state) respond(state, 1, { message = 'server stopped' }) end,
      message = 'server stopped',
    },
    {
      label = 'build failed',
      settle = function(state) respond(state, 1, nil, 2) end,
      message = '<leader>cc',
    },
  }
  for _, case in ipairs(cases) do
    local java = load_java()
    local state, deps = fixture(case.overrides)
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    case.settle(state)
    h.matches(state.notifications[#state.notifications].message, case.message, case.label)
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    h.falsy(state.notifications[#state.notifications].message:find('already in progress', 1, true), case.label)
  end
end)

h.it('blocks only overlapping asynchronous runs', function()
  local java = load_java()
  local state, deps = fixture()
  h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
  h.falsy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
  h.equal(#state.requests, 1)
  h.matches(state.notifications[1].message, 'already in progress')
  respond(state, 1, nil, 3)
  h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
  h.equal(#state.requests, 2)
end)

h.it('stops when main, paths, runtime, JShell, or terminal resolution fails', function()
  local function begin(overrides)
    local java = load_java()
    local state, deps = fixture(overrides)
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    return java, state, deps
  end

  local _, no_main = begin()
  respond(no_main, 2, nil, { { mainClass = 'demo.Other', projectName = 'demo' } })
  h.matches(no_main.notifications[1].message, 'no recognized main(String[])')

  local _, bad_paths = begin()
  respond(bad_paths, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
  respond(bad_paths, 3, nil, {})
  h.matches(bad_paths.notifications[1].message, 'invalid classpath response')

  local _, no_java = begin()
  respond(no_java, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
  respond(no_java, 3, nil, { {}, { '/repo/out' } })
  respond(no_java, 4, nil, nil)
  h.matches(no_java.notifications[1].message, 'no Java executable')

  local _, no_jshell = begin {
    is_executable = function() return false end,
    exepath = function() return '' end,
  }
  respond(no_jshell, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
  respond(no_jshell, 3, nil, { {}, { '/repo/out' } })
  respond(no_jshell, 4, nil, '/jdk/bin/java')
  h.matches(no_jshell.notifications[1].message, 'could not find JShell')

  local _, terminal = begin {
    open_terminal = function() return false, 'terminal job returned -1' end,
  }
  respond(terminal, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
  respond(terminal, 3, nil, { {}, { '/repo/out' } })
  respond(terminal, 4, nil, '/jdk/bin/java')
  h.matches(terminal.notifications[1].message, 'terminal job returned -1')
end)

h.it('uses Windows separators and jshell.exe beside java.exe', function()
  local java = load_java()
  local state, deps = fixture {
    path_separator = ';',
    is_executable = function(path) return path == 'C:/jdk/bin/jshell.exe' end,
  }
  java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
  respond(state, 1, nil, 1)
  respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
  respond(state, 3, nil, { {}, { '/repo/out', '/repo/lib/runtime.jar' } })
  respond(state, 4, nil, 'C:/jdk/bin/java.exe')
  h.equal(state.launches[1].argv[1], 'C:/jdk/bin/jshell.exe')
  h.equal(state.launches[1].argv[3], '/repo/out;/repo/lib/runtime.jar')
end)

h.it('falls back to the configured JDTLS runtime', function()
  local java = load_java()
  local state, deps = fixture()
  state.client.server_capabilities.executeCommandProvider.commands = {
    'vscode.java.resolveMainClass',
    'vscode.java.resolveClasspath',
  }
  java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
  respond(state, 1, nil, 1)
  respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
  respond(state, 3, nil, { {}, { '/repo/out' } })
  h.deep_equal(state.requests[4].params, {
    command = 'java.project.getSettings',
    arguments = {
      'file:///repo/src/demo/Current.java',
      { 'org.eclipse.jdt.ls.core.vm.location' },
    },
  })
  respond(state, 4, nil, {
    ['org.eclipse.jdt.ls.core.vm.location'] = '/jdk',
  })
  h.equal(state.launches[1].argv[1], '/jdk/bin/jshell')
end)

h.it('starts a bottom terminal with list argv and queues the main call', function()
  local java = load_java()
  local calls = {}
  local state, deps = fixture {
    open_terminal = false,
    cmd = function(command) calls[#calls + 1] = { 'cmd', command } end,
    current_buf = function() return 31 end,
    set_bufhidden = function(bufnr)
      calls[#calls + 1] = { 'bufhidden', bufnr, 'wipe' }
    end,
    jobstart = function(argv, opts)
      calls[#calls + 1] = { 'jobstart', vim.deepcopy(argv), vim.deepcopy(opts) }
      return 23
    end,
    chan_send = function(job, input) calls[#calls + 1] = { 'send', job, input } end,
    startinsert = function() calls[#calls + 1] = { 'startinsert' } end,
  }
  java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
  respond(state, 1, nil, 1)
  respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
  respond(state, 3, nil, { {}, { '/repo/out' } })
  respond(state, 4, nil, '/jdk/bin/java')
  h.deep_equal(calls, {
    { 'cmd', 'botright 12new' },
    { 'bufhidden', 31, 'wipe' },
    { 'jobstart', { '/jdk/bin/jshell', '--class-path', '/repo/out' }, { term = true, cwd = '/repo' } },
    { 'send', 23, 'demo.Current.main(new String[0]);\n' },
    { 'startinsert' },
  })
end)

h.it('cleans up terminal start and channel-send failures', function()
  local cases = {
    {
      label = 'start',
      overrides = { jobstart = function() return -1 end },
      expected = { { 'delete', 31 } },
      message = 'failed to start',
    },
    {
      label = 'send',
      overrides = {
        jobstart = function() return 23 end,
        chan_send = function() error 'closed channel' end,
      },
      expected = { { 'stop', 23 }, { 'delete', 31 } },
      message = 'closed channel',
    },
  }
  for _, case in ipairs(cases) do
    local java = load_java()
    local cleanup = {}
    local overrides = vim.tbl_extend('force', {
      open_terminal = false,
      cmd = function() end,
      current_buf = function() return 31 end,
      set_bufhidden = function() end,
      startinsert = function() end,
      jobstop = function(job) cleanup[#cleanup + 1] = { 'stop', job } end,
      buf_delete = function(bufnr) cleanup[#cleanup + 1] = { 'delete', bufnr } end,
    }, case.overrides)
    local state, deps = fixture(overrides)
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(state, 3, nil, { {}, { '/repo/out' } })
    respond(state, 4, nil, '/jdk/bin/java')
    h.deep_equal(cleanup, case.expected, case.label)
    h.matches(state.notifications[1].message, case.message, case.label)
    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps }, case.label)
  end
end)
```

- [ ] **Step 2: Run the focused test and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/java_spec.lua
```

Expected: at least the terminal-default and Java-setting fallback expectations fail until the defaults are completed.

- [ ] **Step 3: Add callback-total Java fallback and the default terminal job**

Extend `default_dependencies()` with these functions:

```lua
cmd = vim.cmd,
current_buf = vim.api.nvim_get_current_buf,
set_bufhidden = function(bufnr) vim.bo[bufnr].bufhidden = 'wipe' end,
buf_delete = function(bufnr) vim.api.nvim_buf_delete(bufnr, { force = true }) end,
jobstart = vim.fn.jobstart,
jobstop = vim.fn.jobstop,
chan_send = vim.api.nvim_chan_send,
startinsert = function() vim.cmd.startinsert() end,
```

Immediately after dependencies are merged in `run_current_class`, set the default terminal launcher when no test or caller supplies one:

```lua
deps.open_terminal = deps.open_terminal or function(argv, input, cwd)
  local opened, open_error = pcall(deps.cmd, 'botright 12new')
  if not opened then return false, 'could not open terminal split: ' .. tostring(open_error) end
  local terminal_buf = deps.current_buf()
  local hidden, hidden_error = pcall(deps.set_bufhidden, terminal_buf)
  if not hidden then
    pcall(deps.buf_delete, terminal_buf)
    return false, 'could not prepare terminal buffer: ' .. tostring(hidden_error)
  end
  local started, job = pcall(deps.jobstart, argv, { term = true, cwd = cwd })
  if not started or type(job) ~= 'number' or job <= 0 then
    pcall(deps.buf_delete, terminal_buf)
    return false, 'terminal job failed to start: ' .. tostring(started and job or job)
  end
  local sent, send_error = pcall(deps.chan_send, job, input)
  if not sent then
    pcall(deps.jobstop, job)
    pcall(deps.buf_delete, terminal_buf)
    return false, 'could not send main invocation: ' .. tostring(send_error)
  end
  pcall(deps.startinsert)
  return true
end
```

Replace `resolve_java` with a callback-total direct resolver plus the same compatibility setting used by nvim-jdtls:

```lua
local function resolve_java(main, paths)
  local project = main.projectName or ''
  if supports_command(client, 'vscode.java.resolveJavaExecutable') then
    local params = {
      command = 'vscode.java.resolveJavaExecutable',
      arguments = { main.mainClass, project },
    }
    return request('workspace/executeCommand', params, function(err, java_exec)
      if err then return finish('Java executable resolution failed: ' .. (err.message or vim.inspect(err))) end
      if type(java_exec) ~= 'string' or java_exec == '' then
        return finish('JDTLS returned no Java executable')
      end
      launch(main, paths, java_exec)
    end, 'Java executable resolution')
  end

  local setting = 'org.eclipse.jdt.ls.core.vm.location'
  local params = {
    command = 'java.project.getSettings',
    arguments = { deps.buf_uri(bufnr), { setting } },
  }
  return request('workspace/executeCommand', params, function(err, settings)
    if err then return finish('Java runtime setting failed: ' .. (err.message or vim.inspect(err))) end
    local java_home = type(settings) == 'table' and settings[setting] or nil
    if type(java_home) ~= 'string' or java_home == '' then
      return finish('JDTLS returned no Java runtime setting')
    end
    local suffix = vim.fn.has('win32') == 1 and '.exe' or ''
    launch(main, paths, vim.fs.joinpath(java_home, 'bin', 'java' .. suffix))
  end, 'Java runtime setting')
end
```

- [ ] **Step 4: Run focused and neighboring Java tests and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua \
  tests/headless/java_spec.lua \
  tests/headless/deprecated_api_spec.lua \
  tests/headless/privacy_loading_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit the hardened runner**

```sh
git add lua/nv_ide/java.lua tests/headless/java_spec.lua
git commit -m "fix(java): harden current-class JShell run"
```

### Task 3: Install the Java-only keybinding

**Files:**
- Modify: `tests/headless/java_spec.lua`
- Modify: `lua/plugins/lsp/lang/java.lua:395-421`

- [ ] **Step 1: Add a mapping ownership regression**

Append this source-level ownership test. The runner behavior is already exercised through callable functions; this test locks the integration points without starting the entire JDTLS plugin lifecycle:

```lua
h.it('preserves interactive JShell and maps current-class JShell separately', function()
  local source = table.concat(vim.fn.readfile('lua/plugins/lsp/lang/java.lua'), '\n')
  h.matches(source, [[{ '<leader>cj', require('jdtls').jshell]])
  h.matches(source, [[{ '<leader>cJ', function()]])
  h.matches(source, [[require('nv_ide.java').run_current_class { bufnr = args.buf, client_id = client.id }]])
  h.matches(source, [[desc = 'Run Current Class in JShell [cJ]']])
  h.matches(source, [[mode = 'n', buffer = args.buf]])
end)
```

- [ ] **Step 2: Run the focused test and verify RED**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/java_spec.lua
```

Expected: FAIL because `<leader>cJ` is absent from the Java LSP attachment.

- [ ] **Step 3: Add `<leader>cJ` beside the existing interactive mapping**

In the first Java `wk.add` table, keep `<leader>cj` unchanged and insert:

```lua
{
  '<leader>cJ',
  function()
    require('nv_ide.java').run_current_class { bufnr = args.buf, client_id = client.id }
  end,
  desc = 'Run Current Class in JShell [cJ]',
  mode = 'n',
  buffer = args.buf,
},
```

The capital mapping is intentionally Java-buffer-local. Rust's buffer-local `<leader>cJ` remains unrelated and cannot overlap in one filetype.

- [ ] **Step 4: Run the focused test and verify GREEN**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua tests/headless/java_spec.lua
```

Expected: all selected tests PASS with `0 failed`.

- [ ] **Step 5: Commit the mapping**

```sh
git add lua/plugins/lsp/lang/java.lua tests/headless/java_spec.lua
git commit -m "feat(java): map current class to JShell"
```

### Task 4: Verify the complete configuration and update the open branch

**Files:**
- Verify: `lua/nv_ide/java.lua`
- Verify: `lua/plugins/lsp/lang/java.lua`
- Verify: `tests/headless/java_spec.lua`
- Verify: `docs/superpowers/specs/2026-08-02-java-jshell-current-class-design.md`
- Verify: `docs/superpowers/plans/2026-08-02-java-jshell-current-class.md`

- [ ] **Step 1: Compile every tracked Lua file**

```sh
git ls-files '*.lua' | xargs -n1 luac -p
```

Expected: exit 0 with no output.

- [ ] **Step 2: Run the complete headless suite**

```sh
nvim --clean --headless -u tests/minimal_init.lua -i NONE \
  -l tests/headless/run.lua
```

Expected: final output reports `0 failed`.

- [ ] **Step 3: Run isolated preflight**

```sh
tests/headless/no-profile.sh preflight
```

Expected: the command exits 0 and reports a passing isolated preflight.

- [ ] **Step 4: Check patch hygiene and branch state**

```sh
git diff --check
git status --short --branch
```

Expected: no whitespace errors and a clean feature worktree.

- [ ] **Step 5: Push the existing feature branch**

```sh
git push origin codex/prod-ide-fixes
```

Expected: `origin/codex/prod-ide-fixes` advances and the existing pull request includes the JShell runner commits.
