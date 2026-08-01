local h = require 'tests.headless.harness'

local function stage(missing, options)
  options = options or {}
  return {
    missing = vim.deepcopy(missing or {}),
    installs = 0,
    discover = function(self) return vim.deepcopy(self.missing) end,
    install = function(self)
      self.installs = self.installs + 1
      if options.fail then error(options.fail) end
      self.missing = {}
      return { ok = true }
    end,
  }
end

local function state(initial)
  return {
    value = initial,
    writes = {},
    read = function(self) return self.value and vim.deepcopy(self.value) or nil end,
    write = function(self, value)
      self.value = vim.deepcopy(value)
      self.writes[#self.writes + 1] = vim.deepcopy(value)
      return true
    end,
    should_run = function(_, current, options)
      if options.repair or options.force then return true end
      if next(options.missing or {}) ~= nil then return true end
      return not current or current.status ~= 'success' or current.schema_version ~= options.schema_version
        or current.fingerprint ~= options.fingerprint
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
      if options.busy then return nil, 'locked by pid 42' end
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
      fingerprint = function() return 'manifest-fingerprint' end,
    },
    state = options.state or state(),
    lock = options.lock or lock(),
    mason = options.mason or stage {},
    treesitter = options.treesitter or stage {},
    now = options.now or function() return 123 end,
    defer = options.defer or function(callback) callback() end,
    notify = function(message, level)
      notifications[#notifications + 1] = { message = message, level = level }
    end,
  }
  return instance, notifications
end

h.describe('toolchain orchestration', function()
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

    mason.install = function(self) self.installs = self.installs + 1; self.missing = {}; return { ok = true } end
    treesitter.install = function(self) self.installs = self.installs + 1; self.missing = {}; return { ok = true } end
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

  h.it('registers install and repair commands with bang/headless waiting semantics', function()
    package.loaded['nv_ide.toolchain.orchestrator'] = nil
    local orchestrator = require 'nv_ide.toolchain.orchestrator'
    local commands = {}
    local invocations = {}
    orchestrator.register({
      run = function(_, options) invocations[#invocations + 1] = options end,
    }, {
      create_user_command = function(name, callback, options)
        commands[name] = { callback = callback, options = options }
      end,
      headless = function() return false end,
    })

    h.truthy(commands.ToolchainInstall.options.bang)
    h.truthy(commands.ToolchainRepair.options.bang)
    commands.ToolchainInstall.callback { bang = true }
    commands.ToolchainRepair.callback { bang = false }
    h.truthy(invocations[1].wait)
    h.truthy(invocations[2].repair)
    h.falsy(invocations[2].wait)
  end)

  h.it('never invokes an operating-system package manager', function()
    local source = table.concat(vim.fn.readfile('lua/nv_ide/toolchain/orchestrator.lua'), '\n'):lower()
    for _, forbidden in ipairs { 'sudo ', 'brew install', 'apt install', 'dnf install', 'pacman -s' } do
      h.falsy(source:find(forbidden, 1, true), 'unexpected system package mutation: ' .. forbidden)
    end
  end)
end)
