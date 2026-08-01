local h = require 'tests.headless.harness'

local function stage(missing, options)
  options = options or {}
  return {
    missing = vim.deepcopy(missing or {}),
    installs = 0,
    discover = function(self)
      return vim.deepcopy(self.missing)
    end,
    install = function(self)
      self.installs = self.installs + 1
      if options.fail then
        error(options.fail)
      end
      self.missing = {}
      return { ok = true }
    end,
  }
end

local function state(initial)
  return {
    value = initial,
    writes = {},
    read = function(self)
      return self.value and vim.deepcopy(self.value) or nil
    end,
    write = function(self, value)
      self.value = vim.deepcopy(value)
      self.writes[#self.writes + 1] = vim.deepcopy(value)
      return true
    end,
    should_run = function(_, current, options)
      if options.repair or options.force then
        return true
      end
      if next(options.missing or {}) ~= nil then
        return true
      end
      return not current or current.status ~= 'success' or current.schema_version ~= options.schema_version or current.fingerprint ~= options.fingerprint
    end,
  }
end

local function lock(options)
  options = options or {}
  return {
    acquired = 0,
    released = {},
    acquire = function(self)
      self.acquired = self.acquired + 1
      if options.busy then
        return nil, 'locked by pid 42'
      end
      return 'lock-token-' .. self.acquired
    end,
    release = function(self, token)
      self.released[#self.released + 1] = token
      return true
    end,
  }
end

local function new(options)
  package.loaded['nv_ide.toolchain.orchestrator'] = nil
  local notifications = {}
  local instance = require('nv_ide.toolchain.orchestrator').new {
    manifest = {
      schema_version = 1,
      fingerprint = function()
        return 'manifest-fingerprint'
      end,
    },
    state = options.state or state(),
    lock = options.lock or lock(),
    mason = options.mason or stage {},
    treesitter = options.treesitter or stage {},
    now = options.now or function()
      return 123
    end,
    defer = options.defer or function(callback)
      callback()
    end,
    wait = options.wait,
    clock_ms = options.clock_ms,
    timeout_ms = options.timeout_ms,
    env = options.env or {},
    poll_ms = options.poll_ms,
    plugins = options.plugins or {
      update = function()
        return { status = 'success' }
      end,
    },
    notify = function(message, level)
      notifications[#notifications + 1] = { message = message, level = level }
    end,
  }
  return instance, notifications
end

h.describe('toolchain orchestration', function()
  h.it('allows a complete first run for up to thirty minutes by default', function()
    local instance = new {}

    h.equal(instance.timeout_ms, 1800000)
  end)

  h.it('uses a valid environment timeout unless an explicit timeout is injected', function()
    local from_environment = new {
      env = { NV_IDE_TOOLCHAIN_TIMEOUT_MS = '2400000' },
    }
    local injected = new {
      env = { NV_IDE_TOOLCHAIN_TIMEOUT_MS = '2400000' },
      timeout_ms = 750,
    }

    h.equal(from_environment.timeout_ms, 2400000)
    h.equal(injected.timeout_ms, 750)
  end)

  h.it('ignores invalid environment timeouts without leaking process environment', function()
    local before = vim.env.NV_IDE_TOOLCHAIN_TIMEOUT_MS
    for _, value in ipairs { '0', '-1', '1.5', 'not-a-number' } do
      local instance = new {
        env = { NV_IDE_TOOLCHAIN_TIMEOUT_MS = value },
      }
      h.equal(instance.timeout_ms, 1800000, 'invalid timeout must use the bounded default: ' .. value)
    end

    h.equal(vim.env.NV_IDE_TOOLCHAIN_TIMEOUT_MS, before)
  end)

  h.it('installs and verifies missing items at startup even after a prior success', function()
    local mason = stage { 'stylua' }
    local treesitter = stage { 'lua' }
    local saved = state {
      schema_version = 1,
      fingerprint = 'manifest-fingerprint',
      status = 'success',
      last_success = 120,
    }
    local instance = new { state = saved, mason = mason, treesitter = treesitter }

    local result = instance:run { startup = true, wait = true }
    h.equal(result.status, 'success')
    h.equal(mason.installs, 1)
    h.equal(treesitter.installs, 1)
    h.equal(saved.value.status, 'success')
    h.deep_equal(saved.value.missing, {})
  end)

  h.it('refuses concurrent invocation without running a stage', function()
    local mason = stage { 'stylua' }
    local process_lock = lock { busy = true }
    local instance = new { mason = mason, lock = process_lock }
    local result = instance:run { wait = true }
    h.equal(result.status, 'busy')
    h.matches(result.error, 'locked')
    h.equal(mason.installs, 0)
  end)

  h.it('persists stage failures, reports once, and retries the next invocation', function()
    local mason = stage({ 'stylua' }, { fail = 'mason exploded' })
    local treesitter = stage({ 'lua' }, { fail = 'parser exploded' })
    local saved = state()
    local instance, notifications = new { state = saved, mason = mason, treesitter = treesitter }

    local failed = instance:run { wait = true }
    h.equal(failed.status, 'failed')
    h.equal(saved.value.status, 'failed')
    h.equal(#saved.value.errors, 2)
    h.equal(#notifications, 1, 'one summary must cover every failed stage')

    mason.install = function(self)
      self.installs = self.installs + 1
      self.missing = {}
      return { ok = true }
    end
    treesitter.install = function(self)
      self.installs = self.installs + 1
      self.missing = {}
      return { ok = true }
    end
    local retried = instance:run { wait = true }
    h.equal(retried.status, 'success')
    h.equal(saved.value.status, 'success')
  end)

  h.it('completes an interactive startup through the deferred verifier', function()
    local saved = state()
    local deferred = 0
    local instance = new {
      state = saved,
      mason = stage { 'stylua' },
      defer = function(callback)
        deferred = deferred + 1
        callback()
      end,
    }
    local result = instance:run { startup = true, wait = false }
    h.equal(result.status, 'started')
    h.equal(deferred, 1)
    h.equal(saved.value.status, 'success')
  end)

  h.it('retains the lock until asynchronous installer completion even when discovery turns empty early', function()
    local completion
    local deferred = {}
    local process_lock = lock()
    local saved = state()
    local mason = stage { 'stylua' }
    mason.install = function(self, options)
      self.installs = self.installs + 1
      self.missing = {}
      completion = options.on_complete
      return { ok = true, pending = true }
    end
    local instance = new {
      mason = mason,
      lock = process_lock,
      state = saved,
      defer = function(callback)
        deferred[#deferred + 1] = callback
      end,
      clock_ms = function()
        return 100
      end,
    }

    local result = instance:run { startup = true, wait = false }
    h.equal(result.status, 'started')
    h.deep_equal(mason:discover(), {}, 'the promoted directory appears before the installer is complete')
    h.deep_equal(process_lock.released, {})
    h.equal(saved.value, nil)
    h.truthy(instance.running)

    deferred[1]()
    h.deep_equal(process_lock.released, {}, 'polling must not mistake early discovery for completion')
    h.equal(saved.value, nil)
    h.equal(#deferred, 2)

    completion { ok = true }
    deferred[2]()
    h.equal(saved.value.status, 'success')
    h.deep_equal(process_lock.released, { 'lock-token-1' })
    h.falsy(instance.running)
  end)

  h.it('contains deferred monitor failures and releases the lock', function()
    local pending
    local completion
    local process_lock = lock()
    local completed
    local mason = stage { 'stylua' }
    mason.install = function(self, options)
      self.installs = self.installs + 1
      completion = options.on_complete
      return { ok = true, pending = true }
    end
    local instance = new {
      lock = process_lock,
      mason = mason,
      defer = function(callback)
        pending = callback
      end,
      clock_ms = function()
        error 'clock exploded'
      end,
    }
    instance.clock_ms = function()
      return 100
    end
    local result = instance:run {
      wait = false,
      on_complete = function(value)
        completed = value
      end,
    }
    h.equal(result.status, 'started')
    instance.clock_ms = function()
      error 'clock exploded'
    end

    local ok = pcall(pending)

    h.truthy(ok)
    h.equal(completed.status, 'failed')
    h.matches(table.concat(completed.errors or {}, '\n'), 'clock exploded')
    h.deep_equal(process_lock.released, {}, 'the lock must cover the still-running installer')
    h.truthy(instance.running)

    completion { ok = false, error = 'late failure' }
    h.deep_equal(process_lock.released, { 'lock-token-1' })
    h.falsy(instance.running)
  end)

  h.it('bounds headless waiting in the central orchestrator while installers remain asynchronous', function()
    local mason = stage { 'stylua' }
    local completion
    mason.install = function(self, options)
      self.installs = self.installs + 1
      completion = options.on_complete
      return { ok = true, pending = true }
    end
    local process_lock = lock()
    local polls = 0
    local instance = new {
      mason = mason,
      lock = process_lock,
      timeout_ms = 50,
      poll_ms = 5,
      wait = function(timeout, predicate, interval)
        h.equal(timeout, 50)
        h.equal(interval, 5)
        for _ = 1, 3 do
          polls = polls + 1
          if polls == 3 then
            mason.missing = {}
            completion { ok = true }
          end
          if predicate() then
            return true
          end
        end
        return false
      end,
    }

    local result = instance:run { wait = true }
    h.equal(result.status, 'success')
    h.equal(mason.installs, 1)
    h.equal(polls, 3)
    h.deep_equal(process_lock.released, { 'lock-token-1' })
  end)

  h.it('uses one cycle-wide deadline after installer stage time has elapsed', function()
    local now = 1000
    local mason = stage { 'stylua' }
    mason.install = function(self, options)
      self.installs = self.installs + 1
      h.equal(options.timeout_ms, 50)
      now = now + 40
      self.missing = {}
      return { ok = true }
    end
    local instance = new {
      mason = mason,
      timeout_ms = 50,
      poll_ms = 5,
      clock_ms = function()
        return now
      end,
      wait = function(timeout, predicate, interval)
        h.equal(timeout, 10)
        h.equal(interval, 5)
        return predicate()
      end,
    }

    local result = instance:run { wait = true }

    h.equal(result.status, 'success')
  end)

  h.it('persists a bounded timeout but retains the lock until late asynchronous completion', function()
    local mason = stage { 'stylua' }
    local completion
    mason.install = function(self, options)
      self.installs = self.installs + 1
      completion = options.on_complete
      return { ok = true, pending = true }
    end
    local process_lock = lock()
    local saved = state()
    local instance, notifications = new {
      mason = mason,
      lock = process_lock,
      state = saved,
      timeout_ms = 25,
      poll_ms = 5,
      wait = function(timeout, predicate, interval)
        h.equal(timeout, 25)
        h.equal(interval, 5)
        predicate()
        return false
      end,
    }

    local result = instance:run { wait = true }
    h.equal(result.status, 'failed')
    h.matches(table.concat(result.errors, '\n'), 'timed out after 25 ms')
    h.equal(saved.value.status, 'failed')
    h.deep_equal(saved.value.missing, { mason = { 'stylua' } })
    h.deep_equal(process_lock.released, {}, 'timeout must not release a lock covering live work')
    h.truthy(instance.running)
    h.equal(instance:run({ wait = true }).status, 'busy')
    h.equal(#notifications, 1)

    mason.missing = {}
    completion { ok = true }
    h.deep_equal(process_lock.released, { 'lock-token-1' })
    h.falsy(instance.running)
  end)

  h.it('fails closed and releases the lock for every state failure after acquisition', function()
    local cases = {
      {
        name = 'read',
        saved = {
          read = function()
            error 'read exploded'
          end,
          write = function()
            return true
          end,
          should_run = function()
            return true
          end,
        },
      },
      {
        name = 'should-run',
        saved = {
          read = function()
            return nil
          end,
          write = function()
            return true
          end,
          should_run = function()
            error 'should-run exploded'
          end,
        },
      },
      {
        name = 'write',
        saved = {
          read = function()
            return nil
          end,
          write = function()
            error 'write exploded'
          end,
          should_run = function()
            return true
          end,
        },
      },
    }

    for _, case in ipairs(cases) do
      local process_lock = lock()
      local instance = new { state = case.saved, lock = process_lock }
      local ok, result = pcall(instance.run, instance, { wait = true })
      h.truthy(ok, case.name .. ' failure must not escape')
      h.equal(result.status, 'failed', case.name .. ' failure must fail closed')
      h.matches(table.concat(result.errors or {}, '\n'), 'exploded')
      h.deep_equal(process_lock.released, { 'lock-token-1' })
      h.falsy(instance.running)
    end
  end)

  h.it('contains completion callback failures and releases the lock', function()
    local process_lock = lock()
    local instance = new { lock = process_lock }

    local ok, result = pcall(instance.run, instance, {
      wait = true,
      on_complete = function()
        error 'completion exploded'
      end,
    })

    h.truthy(ok)
    h.equal(result.status, 'failed')
    h.matches(table.concat(result.errors or {}, '\n'), 'completion exploded')
    h.deep_equal(process_lock.released, { 'lock-token-1' })
    h.falsy(instance.running)
  end)

  h.it('installs missing configured plugins through the same bounded cycle', function()
    local plugin_stage = stage { 'missing-plugin.nvim' }
    plugin_stage.update = function()
      return { status = 'success' }
    end
    local instance = new { plugins = plugin_stage }

    local result = instance:run { wait = true }

    h.equal(result.status, 'success')
    h.equal(plugin_stage.installs, 1)
  end)

  h.it('registers install and repair commands with bang/headless waiting semantics', function()
    package.loaded['nv_ide.toolchain.orchestrator'] = nil
    local orchestrator = require 'nv_ide.toolchain.orchestrator'
    local commands = {}
    local invocations = {}
    orchestrator.register({
      run = function(_, options)
        invocations[#invocations + 1] = options
      end,
    }, {
      create_user_command = function(name, callback, options)
        commands[name] = { callback = callback, options = options }
      end,
      headless = function()
        return false
      end,
    })

    h.truthy(commands.ToolchainInstall.options.bang)
    h.truthy(commands.ToolchainRepair.options.bang)
    commands.ToolchainInstall.callback { bang = true }
    commands.ToolchainRepair.callback { bang = false }
    h.truthy(invocations[1].wait)
    h.truthy(invocations[2].repair)
    h.falsy(invocations[2].wait)
  end)

  h.it('runs the first-start plugin update after a failed repair releases its lock', function()
    package.loaded['nv_ide.toolchain.orchestrator'] = nil
    local orchestrator = require 'nv_ide.toolchain.orchestrator'
    pcall(vim.api.nvim_del_augroup_by_name, 'nv_ide.toolchain')
    local process_lock = lock()
    local saved = state()
    local updates = 0
    local instance
    local plugins = {
      update = function(_, options)
        updates = updates + 1
        h.deep_equal(process_lock.released, { 'lock-token-1' }, 'repair lock must be released before plugin update')
        h.equal(process_lock.acquired, 2, 'the update must own a new lock cycle')
        h.truthy(options.wait)
        h.truthy(options.fresh)
        return { status = 'success' }
      end,
    }
    instance = orchestrator.new {
      state = saved,
      lock = process_lock,
      mason = stage({ 'stylua' }, { fail = 'mason exploded' }),
      treesitter = stage {},
      plugins = plugins,
    }
    orchestrator.setup {
      instance = instance,
      create_user_command = function() end,
    }

    vim.api.nvim_exec_autocmds('VimEnter', {})

    h.equal(updates, 1)
    h.equal(saved.value.status, 'failed', 'plugin success must not erase the installer failure')
    h.matches(table.concat(saved.value.errors or {}, '\n'), 'mason exploded')
    h.equal(saved.value.plugin_update.status, 'success')
    h.deep_equal(process_lock.released, { 'lock-token-1', 'lock-token-2' })
  end)

  h.it('waits for late installer settlement before one first-start plugin update', function()
    package.loaded['nv_ide.toolchain.orchestrator'] = nil
    local orchestrator = require 'nv_ide.toolchain.orchestrator'
    pcall(vim.api.nvim_del_augroup_by_name, 'nv_ide.toolchain')
    local process_lock = lock()
    local saved = state()
    local completion
    local mason = stage { 'stylua' }
    mason.install = function(self, options)
      self.installs = self.installs + 1
      completion = options.on_complete
      return { ok = true, pending = true }
    end
    local updates = 0
    local plugins = {
      update = function()
        updates = updates + 1
        h.deep_equal(process_lock.released, { 'lock-token-1' }, 'late repair lock must be released before plugin update')
        return { status = 'success' }
      end,
    }
    local instance = orchestrator.new {
      state = saved,
      lock = process_lock,
      mason = mason,
      treesitter = stage {},
      plugins = plugins,
      timeout_ms = 25,
      poll_ms = 5,
      wait = function(_, predicate)
        predicate()
        return false
      end,
    }
    orchestrator.setup {
      instance = instance,
      create_user_command = function() end,
    }

    vim.api.nvim_exec_autocmds('VimEnter', {})

    h.equal(updates, 0, 'plugin update must not race a timed-out installer still holding the lock')
    h.equal(saved.value.status, 'failed')
    h.matches(table.concat(saved.value.errors or {}, '\n'), 'timed out after 25 ms')
    h.deep_equal(process_lock.released, {})

    mason.missing = {}
    completion { ok = false, error = 'late mason failure' }
    completion { ok = true }

    h.equal(updates, 1)
    h.equal(saved.value.status, 'failed', 'late plugin success must preserve repair diagnostics')
    h.equal(saved.value.plugin_update.status, 'success')
    h.deep_equal(process_lock.released, { 'lock-token-1', 'lock-token-2' })
  end)

  h.it('can disable only VimEnter autorun while retaining user commands', function()
    package.loaded['nv_ide.toolchain.orchestrator'] = nil
    local orchestrator = require 'nv_ide.toolchain.orchestrator'
    pcall(vim.api.nvim_del_augroup_by_name, 'nv_ide.toolchain')
    local commands = {}
    local instance = {
      run = function()
        error 'autorun must be disabled'
      end,
      update = function()
        return { status = 'success' }
      end,
      notify = function() end,
    }

    orchestrator.setup {
      instance = instance,
      autorun = false,
      create_user_command = function(name, callback, options)
        commands[name] = { callback = callback, options = options }
      end,
    }

    h.truthy(commands.ToolchainInstall)
    h.truthy(commands.ToolchainRepair)
    h.truthy(commands.ToolchainUpdate)
    h.falsy(pcall(vim.api.nvim_get_autocmds, { group = 'nv_ide.toolchain' }))
  end)

  h.it('honors the isolated-process autorun environment gate', function()
    package.loaded['nv_ide.toolchain.orchestrator'] = nil
    local orchestrator = require 'nv_ide.toolchain.orchestrator'
    pcall(vim.api.nvim_del_augroup_by_name, 'nv_ide.toolchain')
    local previous = vim.env.NVIM_TOOLCHAIN_AUTORUN
    vim.env.NVIM_TOOLCHAIN_AUTORUN = '0'

    local ok, err = xpcall(function()
      orchestrator.setup {
        instance = {
          run = function()
            error 'autorun must be disabled'
          end,
          update = function()
            return { status = 'success' }
          end,
          notify = function() end,
        },
        create_user_command = function() end,
      }
      h.falsy(pcall(vim.api.nvim_get_autocmds, { group = 'nv_ide.toolchain' }))
    end, debug.traceback)
    vim.env.NVIM_TOOLCHAIN_AUTORUN = previous
    if not ok then
      error(err, 0)
    end
  end)

  h.it('never invokes an operating-system package manager', function()
    local source = table.concat(vim.fn.readfile 'lua/nv_ide/toolchain/orchestrator.lua', '\n'):lower()
    for _, forbidden in ipairs { 'sudo ', 'brew install', 'apt install', 'dnf install', 'pacman -s' } do
      h.falsy(source:find(forbidden, 1, true), 'unexpected system package mutation: ' .. forbidden)
    end
  end)
end)
