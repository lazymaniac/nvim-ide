local Orchestrator = {}
Orchestrator.__index = Orchestrator

local function is_empty(value)
  return next(value or {}) == nil
end

local function default_notify(message, level)
  vim.schedule(function()
    vim.notify(message, level, { title = 'nv_ide toolchain' })
  end)
end

local function default_headless()
  return #vim.api.nvim_list_uis() == 0
end

function Orchestrator:_release(token)
  self.running = false
  local ok, released = pcall(self.lock.release, self.lock, token)
  return ok and released == true
end

function Orchestrator:_record(status, missing, errors)
  local value = {
    schema_version = self.manifest.schema_version,
    fingerprint = self.manifest.fingerprint(),
    status = status,
    missing = missing or {},
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

function Orchestrator:_discover()
  local missing, errors = {}, {}
  for _, name in ipairs(self.stage_names) do
    local stage = self.stages[name]
    local ok, discovered = pcall(stage.discover, stage)
    if ok then
      if not is_empty(discovered) then missing[name] = discovered end
    else
      errors[#errors + 1] = ('%s discovery: %s'):format(name, tostring(discovered))
    end
  end
  return missing, errors
end

function Orchestrator:_finish(cycle, status, missing, errors)
  if cycle.finished then return end
  cycle.finished = true

  local recorded, record_error = pcall(self._record, self, status, missing, errors)
  self:_release(cycle.token)
  if not recorded then
    status = 'failed'
    errors = vim.list_extend(errors or {}, { 'state persistence: ' .. tostring(record_error) })
  end
  if status == 'failed' then
    self.notify(('Toolchain repair failed:\n%s'):format(table.concat(errors or {}, '\n')), vim.log.levels.ERROR)
  end
end

function Orchestrator:_verify(cycle)
  local missing, errors = self:_discover()
  if not is_empty(missing) then
    for _, name in ipairs(self.stage_names) do
      if missing[name] then
        errors[#errors + 1] = ('%s still missing: %s'):format(name, table.concat(missing[name], ', '))
      end
    end
  end
  if #errors > 0 then
    self:_finish(cycle, 'failed', missing, errors)
    return { status = 'failed', missing = missing, errors = errors }
  end
  self:_finish(cycle, 'success', {}, {})
  return { status = 'success', missing = {} }
end

function Orchestrator:_monitor(cycle)
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
  self.defer(function() self:_monitor(cycle) end, self.poll_ms)
end

function Orchestrator:run(options)
  options = options or {}
  if self.running then return { status = 'busy', error = 'toolchain operation already running' } end

  local acquired, token, lock_error = pcall(self.lock.acquire, self.lock)
  if not acquired then return { status = 'busy', error = tostring(token) } end
  if not token then return { status = 'busy', error = tostring(lock_error) } end
  self.running = true

  local cycle = {
    token = token,
    deadline = self.clock_ms() + self.timeout_ms,
    finished = false,
  }
  local missing, discovery_errors = self:_discover()
  if #discovery_errors > 0 then
    self:_finish(cycle, 'failed', missing, discovery_errors)
    return { status = 'failed', errors = discovery_errors, missing = missing }
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
    self:_release(token)
    return { status = 'debounced', missing = {} }
  end
  if is_empty(missing) then
    self:_finish(cycle, 'success', {}, {})
    return { status = 'success', missing = {} }
  end

  local install_errors = {}
  for _, name in ipairs(self.stage_names) do
    if missing[name] then
      local stage = self.stages[name]
      local ok, result = pcall(stage.install, stage, {
        wait = options.wait == true,
        startup = options.startup == true,
      })
      if not ok then
        install_errors[#install_errors + 1] = ('%s install: %s'):format(name, tostring(result))
      elseif type(result) == 'table' and result.ok == false then
        install_errors[#install_errors + 1] = ('%s install: %s'):format(name, result.error or 'failed')
      end
    end
  end
  if #install_errors > 0 then
    local remaining = self:_discover()
    self:_finish(cycle, 'failed', remaining, install_errors)
    return { status = 'failed', errors = install_errors, missing = remaining }
  end

  if options.wait then return self:_verify(cycle) end
  self.defer(function() self:_monitor(cycle) end, self.poll_ms)
  return { status = 'started', missing = missing }
end

local M = {}
local configured

function M.new(options)
  options = options or {}
  local manifest = options.manifest or require 'nv_ide.toolchain.manifest'
  return setmetatable({
    manifest = manifest,
    state = options.state or require('nv_ide.toolchain.state').new(),
    lock = options.lock or require('nv_ide.toolchain.lock').new(),
    stages = {
      mason = options.mason or require('nv_ide.toolchain.mason').new { manifest = manifest },
      treesitter = options.treesitter or require('nv_ide.toolchain.treesitter').new { manifest = manifest },
    },
    stage_names = { 'mason', 'treesitter' },
    now = options.now or os.time,
    clock_ms = options.clock_ms or vim.uv.now,
    defer = options.defer or vim.defer_fn,
    notify = options.notify or default_notify,
    debounce_seconds = options.debounce_seconds or 21600,
    timeout_ms = options.timeout_ms or 300000,
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
  end, { bang = true, desc = 'Install missing nv_ide tools and parsers' })
  create('ToolchainRepair', function(args)
    instance:run { repair = true, wait = args.bang or headless() }
  end, { bang = true, desc = 'Retry failed or missing nv_ide tools and parsers' })
end

function M.setup(options)
  if configured then return configured end
  options = options or {}
  local instance = options.instance or M.new(options)
  M.register(instance, options)

  local group = vim.api.nvim_create_augroup('nv_ide.toolchain', { clear = true })
  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    once = true,
    callback = function()
      local ok, result = pcall(instance.run, instance, { startup = true, wait = default_headless() })
      if not ok then instance.notify('Toolchain startup failed: ' .. tostring(result), vim.log.levels.ERROR) end
    end,
  })
  configured = instance
  return instance
end

return M
