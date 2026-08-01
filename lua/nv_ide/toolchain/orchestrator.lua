local Orchestrator = {}
Orchestrator.__index = Orchestrator

local DEFAULT_TIMEOUT_MS = 1800000

local function is_empty(value)
  return next(value or {}) == nil
end

local function positive_integer(value)
  if type(value) == 'string' and not value:match '^%d+$' then
    return nil
  end
  if type(value) ~= 'string' and type(value) ~= 'number' then
    return nil
  end
  local parsed = tonumber(value)
  if not parsed or parsed <= 0 or parsed == math.huge or parsed ~= math.floor(parsed) then
    return nil
  end
  return parsed
end

local function timeout_ms(options)
  local injected = positive_integer(options.timeout_ms)
  if injected then
    return injected
  end
  local env = options.env or vim.env
  return positive_integer(env.NV_IDE_TOOLCHAIN_TIMEOUT_MS) or DEFAULT_TIMEOUT_MS
end

local function default_notify(message, level)
  vim.schedule(function()
    vim.notify(message, level, { title = 'nv_ide toolchain' })
  end)
end

local function default_headless()
  return #vim.api.nvim_list_uis() == 0
end

local function copy_errors(errors)
  return type(errors) == 'table' and vim.deepcopy(errors) or {}
end

local function append_error(result, message)
  result.status = 'failed'
  result.errors = result.errors or {}
  result.errors[#result.errors + 1] = tostring(message)
end

function Orchestrator:_release(token)
  self.running = false
  local ok, released = pcall(self.lock.release, self.lock, token)
  return ok and released == true
end

function Orchestrator:_record(status, missing, errors)
  local previous = self.state:read()
  local value = {
    schema_version = self.manifest.schema_version,
    fingerprint = self.manifest.fingerprint(),
    status = status,
    missing = missing or {},
    plugin_update = previous and vim.deepcopy(previous.plugin_update) or nil,
  }
  if status == 'success' then
    value.last_success = self.now()
  else
    value.last_failure = self.now()
    value.errors = errors or {}
  end
  self.state:write(value)
  return value
end

function Orchestrator:_notify_failure(result, prefix)
  if result.status ~= 'failed' then
    return
  end
  pcall(self.notify, ('%s:\n%s'):format(prefix, table.concat(result.errors or {}, '\n')), vim.log.levels.ERROR)
end

function Orchestrator:_call_complete(callback, result)
  if not callback then
    return true
  end
  local ok, callback_error = pcall(callback, result)
  if not ok then
    append_error(result, 'completion callback: ' .. tostring(callback_error))
  end
  return ok
end

function Orchestrator:_call_settled(cycle, result)
  if cycle.settled then
    return true
  end
  cycle.settled = true
  return self:_call_complete(cycle.on_settled, result)
end

function Orchestrator:_discover()
  local missing, errors = {}, {}
  for _, name in ipairs(self.stage_names) do
    local stage = self.stages[name]
    local ok, discovered = pcall(stage.discover, stage)
    if ok then
      if not is_empty(discovered) then
        missing[name] = discovered
      end
    else
      errors[#errors + 1] = ('%s discovery: %s'):format(name, tostring(discovered))
    end
  end
  return missing, errors
end

function Orchestrator:_installations_complete(cycle)
  for _, installation in ipairs(cycle.installations or {}) do
    if not installation.completed then
      return false
    end
  end
  return true
end

function Orchestrator:_installation_errors(cycle)
  local errors = {}
  for _, installation in ipairs(cycle.installations or {}) do
    vim.list_extend(errors, installation.errors or {})
  end
  return errors
end

function Orchestrator:_finish(cycle, status, missing, errors)
  if cycle.finished then
    return cycle.result
  end
  if cycle.reported then
    if not self:_installations_complete(cycle) then
      return cycle.result
    end
    cycle.finished = true
    local released = self:_release(cycle.token)
    if not released then
      append_error(cycle.result, 'lock release failed')
      pcall(self._record, self, 'failed', cycle.result.missing, cycle.result.errors)
    else
      self:_call_settled(cycle, cycle.result)
    end
    return cycle.result
  end

  if not self:_installations_complete(cycle) then
    cycle.reported = true
    local result = {
      status = 'failed',
      missing = vim.deepcopy(missing or {}),
      errors = copy_errors(errors),
    }
    local recorded, record_error = pcall(self._record, self, result.status, result.missing, result.errors)
    if not recorded then
      append_error(result, 'state persistence: ' .. tostring(record_error))
    end
    self:_call_complete(cycle.on_complete, result)
    self:_notify_failure(result, 'Toolchain repair failed')
    cycle.result = result
    return result
  end

  cycle.finished = true
  local result = {
    status = status,
    missing = vim.deepcopy(missing or {}),
    errors = copy_errors(errors),
  }
  local recorded, record_error = pcall(self._record, self, result.status, result.missing, result.errors)
  if not recorded then
    append_error(result, 'state persistence: ' .. tostring(record_error))
  end
  local released = self:_release(cycle.token)
  if not released then
    append_error(result, 'lock release failed')
    if recorded then
      pcall(self._record, self, 'failed', result.missing, result.errors)
    end
  end
  -- Completion may start another cycle, so no state writes are allowed after this callback.
  self:_call_complete(cycle.on_complete, result)
  if released then
    self:_call_settled(cycle, result)
  end
  self:_notify_failure(result, 'Toolchain repair failed')
  cycle.result = result
  return result
end

function Orchestrator:_finish_unrecorded(cycle, result)
  if cycle.finished then
    return cycle.result
  end
  cycle.finished = true
  result = vim.deepcopy(result)
  result.errors = copy_errors(result.errors)
  local released = self:_release(cycle.token)
  if not released then
    append_error(result, 'lock release failed')
  end
  self:_call_complete(cycle.on_complete, result)
  if released then
    self:_call_settled(cycle, result)
  end
  self:_notify_failure(result, 'Toolchain operation failed')
  cycle.result = result
  return result
end

function Orchestrator:_wait_verify(cycle)
  local missing, errors = {}, {}
  local remaining_ms = math.max(0, cycle.deadline - self.clock_ms())
  if remaining_ms == 0 then
    missing, errors = self:_discover()
    vim.list_extend(errors, self:_installation_errors(cycle))
    if self:_installations_complete(cycle) and #errors == 0 and is_empty(missing) then
      return self:_finish(cycle, 'success', {}, {})
    end
    errors[#errors + 1] = ('verification timed out after %d ms'):format(self.timeout_ms)
    return self:_finish(cycle, 'failed', missing, errors)
  end

  local completed = self.wait(remaining_ms, function()
    if not self:_installations_complete(cycle) then
      return false
    end
    errors = self:_installation_errors(cycle)
    if #errors > 0 then
      return true
    end
    missing, errors = self:_discover()
    return #errors > 0 or is_empty(missing)
  end, self.poll_ms)
  if not completed then
    local discovery_errors
    missing, discovery_errors = self:_discover()
    errors = self:_installation_errors(cycle)
    vim.list_extend(errors, discovery_errors)
    errors[#errors + 1] = ('verification timed out after %d ms'):format(self.timeout_ms)
    return self:_finish(cycle, 'failed', missing, errors)
  end
  if #errors > 0 then
    return self:_finish(cycle, 'failed', missing, errors)
  end
  return self:_finish(cycle, 'success', {}, {})
end

function Orchestrator:_monitor_locked(cycle)
  if cycle.reported then
    return self:_finish(cycle, cycle.result.status, cycle.result.missing, cycle.result.errors)
  end
  if not self:_installations_complete(cycle) then
    if self.clock_ms() >= cycle.deadline then
      local missing, errors = self:_discover()
      errors[#errors + 1] = ('verification timed out after %d ms'):format(self.timeout_ms)
      self:_finish(cycle, 'failed', missing, errors)
      return
    end
    self.defer(function()
      self:_monitor(cycle)
    end, self.poll_ms)
    return
  end

  local installation_errors = self:_installation_errors(cycle)
  if #installation_errors > 0 then
    self:_finish(cycle, 'failed', {}, installation_errors)
    return
  end

  local missing, errors = self:_discover()
  if #errors > 0 then
    self:_finish(cycle, 'failed', missing, errors)
    return
  end
  if is_empty(missing) then
    self:_finish(cycle, 'success', {}, {})
    return
  end
  if self.clock_ms() >= cycle.deadline then
    errors[#errors + 1] = ('verification timed out after %d ms'):format(self.timeout_ms)
    self:_finish(cycle, 'failed', missing, errors)
    return
  end
  self.defer(function()
    self:_monitor(cycle)
  end, self.poll_ms)
end

function Orchestrator:_monitor(cycle)
  if cycle.finished then
    return cycle.result
  end
  local ok, result = xpcall(function()
    return self:_monitor_locked(cycle)
  end, debug.traceback)
  if not ok then
    return self:_finish(cycle, 'failed', {}, { 'deferred verification: ' .. tostring(result) })
  end
  return result
end

function Orchestrator:_run_locked(cycle, options)
  local missing, discovery_errors = self:_discover()
  if #discovery_errors > 0 then
    return self:_finish(cycle, 'failed', missing, discovery_errors)
  end

  local current = self.state:read()
  local should_run = self.state:should_run(current, {
    schema_version = self.manifest.schema_version,
    fingerprint = self.manifest.fingerprint(),
    debounce_seconds = self.debounce_seconds,
    missing = missing,
    repair = options.repair,
    force = options.force,
  })
  if not should_run then
    return self:_finish_unrecorded(cycle, { status = 'debounced', missing = {} })
  end
  if is_empty(missing) then
    return self:_finish(cycle, 'success', {}, {})
  end

  local install_errors = {}
  for _, name in ipairs(self.stage_names) do
    if missing[name] then
      local remaining_ms = math.max(0, cycle.deadline - self.clock_ms())
      if remaining_ms == 0 then
        install_errors[#install_errors + 1] = ('operation timed out after %d ms'):format(self.timeout_ms)
        break
      end
      local stage = self.stages[name]
      local installation = {
        stage = name,
        completed = false,
        errors = {},
      }
      cycle.installations[#cycle.installations + 1] = installation
      local function on_complete(result)
        if installation.completed or cycle.finished then
          return
        end
        installation.completed = true
        local errors = type(result) == 'table' and result.errors or nil
        if type(errors) == 'table' and #errors > 0 then
          for _, message in ipairs(errors) do
            installation.errors[#installation.errors + 1] = ('%s install: %s'):format(name, tostring(message))
          end
        elseif type(result) == 'table' and result.ok == false then
          installation.errors[#installation.errors + 1] = ('%s install: %s'):format(name, result.error or 'failed')
        end
        if cycle.reported and self:_installations_complete(cycle) then
          self:_monitor(cycle)
        end
      end
      local ok, result = pcall(stage.install, stage, {
        wait = options.wait == true,
        startup = options.startup == true,
        show = options.show,
        timeout_ms = remaining_ms,
        on_complete = on_complete,
      })
      if not ok then
        on_complete { ok = false, error = tostring(result) }
      elseif type(result) == 'table' and result.ok == false then
        on_complete(result)
      elseif type(result) ~= 'table' or result.pending ~= true then
        on_complete(result)
      end
      vim.list_extend(install_errors, installation.errors)
    end
  end
  if #install_errors > 0 then
    local remaining, rediscovery_errors = self:_discover()
    vim.list_extend(install_errors, rediscovery_errors)
    return self:_finish(cycle, 'failed', remaining, install_errors)
  end

  if options.wait then
    return self:_wait_verify(cycle)
  end
  self.defer(function()
    self:_monitor(cycle)
  end, self.poll_ms)
  return { status = 'started', missing = missing }
end

function Orchestrator:run(options)
  options = options or {}
  if self.running then
    local result = { status = 'busy', error = 'toolchain operation already running' }
    self:_call_complete(options.on_complete, result)
    return result
  end

  local acquired, token, lock_error = pcall(self.lock.acquire, self.lock)
  if not acquired then
    local result = { status = 'busy', error = tostring(token) }
    self:_call_complete(options.on_complete, result)
    return result
  end
  if not token then
    local result = { status = 'busy', error = tostring(lock_error) }
    self:_call_complete(options.on_complete, result)
    return result
  end
  self.running = true

  local cycle = {
    token = token,
    deadline = self.clock_ms() + self.timeout_ms,
    finished = false,
    on_complete = options.on_complete,
    on_settled = options.on_settled,
    installations = {},
  }
  local ok, result = xpcall(function()
    return self:_run_locked(cycle, options)
  end, debug.traceback)
  if not ok then
    return self:_finish(cycle, 'failed', {}, { 'orchestration: ' .. tostring(result) })
  end
  return result
end

function Orchestrator:needs_plugin_update()
  local current = self.state:read()
  local update = current and current.plugin_update
  return type(update) ~= 'table' or update.status ~= 'success' or update.fingerprint ~= self.manifest.fingerprint()
end

function Orchestrator:_record_update(result)
  local value = self.state:read() or {}
  value.schema_version = self.manifest.schema_version
  value.fingerprint = self.manifest.fingerprint()
  value.plugin_update = {
    status = result.status,
    fingerprint = self.manifest.fingerprint(),
    snapshot = result.snapshot,
    rolled_back = result.rolled_back == true,
    manager = vim.deepcopy(result.manager),
    observed = vim.deepcopy(result.observed or {}),
    rollback = vim.deepcopy(result.rollback or {}),
  }
  if result.status == 'success' then
    value.plugin_update.last_success = self.now()
  else
    value.plugin_update.last_failure = self.now()
    value.plugin_update.errors = vim.deepcopy(result.errors or {})
  end
  self.state:write(value)
  return value
end

function Orchestrator:update(options)
  options = options or {}
  if self.running then
    return { status = 'busy', error = 'toolchain operation already running' }
  end

  local acquired, token, lock_error = pcall(self.lock.acquire, self.lock)
  if not acquired then
    return { status = 'busy', error = tostring(token) }
  end
  if not token then
    return { status = 'busy', error = tostring(lock_error) }
  end
  self.running = true

  local final
  local settled = false
  local reported = false
  local function normalize(result)
    result = vim.deepcopy(result or { status = 'failed', errors = { 'plugin updater returned no result' } })
    result.errors = copy_errors(result.errors)
    return result
  end

  local function report(result)
    if reported then
      return final
    end
    reported = true
    result = normalize(result)
    local recorded, record_error = pcall(self._record_update, self, result)
    if not recorded then
      append_error(result, 'state persistence: ' .. tostring(record_error))
    end
    self:_call_complete(options.on_complete, result)
    self:_notify_failure(result, 'Toolchain update failed')
    final = result
    return result
  end

  local function finish(result)
    if settled then
      return final
    end
    settled = true
    if reported then
      if not self:_release(token) then
        append_error(final, 'lock release failed')
        pcall(self._record_update, self, final)
      end
      return final
    end

    result = normalize(result)
    local recorded, record_error = pcall(self._record_update, self, result)
    if not recorded then
      append_error(result, 'state persistence: ' .. tostring(record_error))
    end
    if not self:_release(token) then
      append_error(result, 'lock release failed')
      if recorded then
        pcall(self._record_update, self, result)
      end
    end
    -- Completion may start another cycle, so no state writes are allowed after this callback.
    self:_call_complete(options.on_complete, result)
    self:_notify_failure(result, 'Toolchain update failed')
    final = result
    return result
  end

  local ok, started = pcall(self.plugins.update, self.plugins, {
    wait = options.wait == true,
    fresh = options.fresh == true,
    show = options.show,
    timeout_ms = self.timeout_ms,
    lock_owner = { pid = self.lock.pid, token = token },
    on_complete = finish,
  })
  if not ok then
    finish { status = 'failed', errors = { tostring(started) }, rolled_back = false }
  elseif type(started) == 'table' and started.status ~= 'started' and not settled then
    finish(started)
  end

  if options.wait then
    if not settled then
      report { status = 'failed', errors = { 'blocking toolchain update did not complete' } }
    end
    return final
  end
  if not settled then
    local scheduled, schedule_error = pcall(self.defer, function()
      if not settled then
        report {
          status = 'failed',
          errors = { ('plugin update timed out after %d ms'):format(self.timeout_ms) },
        }
      end
    end, self.timeout_ms)
    if not scheduled then
      return report { status = 'failed', errors = { 'update watchdog: ' .. tostring(schedule_error) } }
    end
  end
  return final or started or { status = 'started' }
end

local M = {}
local configured

function M.new(options)
  options = options or {}
  local manifest = options.manifest or require 'nv_ide.toolchain.manifest'
  local operation_timeout_ms = timeout_ms(options)
  local treesitter = options.treesitter or require('nv_ide.toolchain.treesitter').new { manifest = manifest, timeout_ms = operation_timeout_ms }
  local smoke = options.smoke or require('nv_ide.toolchain.smoke').new()
  local plugins = options.plugins
    or require('nv_ide.toolchain.plugins').new {
      manifest = manifest,
      smoke = smoke,
      timeout_ms = operation_timeout_ms,
    }
  local stages = {}
  local stage_names = {}
  if type(plugins.discover) == 'function' and type(plugins.install) == 'function' then
    stages.plugins = plugins
    stage_names[#stage_names + 1] = 'plugins'
  end
  stages.mason = options.mason or require('nv_ide.toolchain.mason').new { manifest = manifest }
  stage_names[#stage_names + 1] = 'mason'
  stages.treesitter = treesitter
  stage_names[#stage_names + 1] = 'treesitter'
  return setmetatable({
    manifest = manifest,
    state = options.state or require('nv_ide.toolchain.state').new(),
    lock = options.lock or require('nv_ide.toolchain.lock').new(),
    stages = stages,
    plugins = plugins,
    stage_names = stage_names,
    now = options.now or os.time,
    clock_ms = options.clock_ms or vim.uv.now,
    defer = options.defer or vim.defer_fn,
    wait = options.wait or vim.wait,
    notify = options.notify or default_notify,
    debounce_seconds = options.debounce_seconds or 21600,
    timeout_ms = operation_timeout_ms,
    poll_ms = options.poll_ms or 250,
    running = false,
  }, Orchestrator)
end

function M.register(instance, options)
  options = options or {}
  local create = options.create_user_command or vim.api.nvim_create_user_command
  local headless = options.headless or default_headless
  create('ToolchainInstall', function(args)
    instance:run { wait = args.bang or headless() }
  end, { bang = true, desc = 'Install missing nv_ide plugins, tools, and parsers' })
  create('ToolchainRepair', function(args)
    instance:run { repair = true, wait = args.bang or headless() }
  end, { bang = true, desc = 'Retry failed or missing nv_ide tools and parsers' })
  create('ToolchainUpdate', function(args)
    instance:update { wait = args.bang or headless() }
  end, { bang = true, desc = 'Update plugins and parsers with rollback validation' })
end

function M.setup(options)
  if configured then
    return configured
  end
  options = options or {}
  local instance = options.instance or M.new(options)
  M.register(instance, options)
  configured = instance
  if options.autorun == false or vim.env.NVIM_TOOLCHAIN_AUTORUN == '0' then
    return configured
  end

  local group = vim.api.nvim_create_augroup('nv_ide.toolchain', { clear = true })
  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    once = true,
    callback = function()
      local headless = default_headless()
      local ok, result = pcall(instance.run, instance, {
        startup = true,
        wait = headless,
        on_settled = function()
          if instance:needs_plugin_update() then
            instance:update { wait = headless, fresh = true, first_run = true }
          end
        end,
      })
      if not ok then
        instance.notify('Toolchain startup failed: ' .. tostring(result), vim.log.levels.ERROR)
      end
    end,
  })
  return instance
end

return M
