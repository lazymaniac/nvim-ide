local TreeSitter = {}
TreeSitter.__index = TreeSitter

local function sorted_unique(values)
  local seen, result = {}, {}
  for _, value in ipairs(values or {}) do
    if not seen[value] then
      seen[value] = true
      result[#result + 1] = value
    end
  end
  table.sort(result)
  return result
end

local function default_installed(provided_config, parser_registry)
  local config = provided_config or require 'nvim-treesitter.config'
  return require('nv_ide.toolchain.treesitter_receipt').complete(config, parser_registry)
end

local function default_record(parsers, provided_config, parser_registry)
  local receipt = require 'nv_ide.toolchain.treesitter_receipt'
  for _, parser in ipairs(parsers) do
    local recorded, record_error = receipt.persist(parser, {
      config = provided_config,
      parser_registry = parser_registry,
    })
    if not recorded then
      return nil, record_error
    end
  end
  return true
end

local function default_install(missing)
  -- Discovery also treats an installed parser without revision evidence as
  -- incomplete. Force is required for nvim-treesitter to rebuild that parser
  -- instead of skipping it merely because its binary is present.
  return require('nvim-treesitter').install(missing, { force = true })
end

local function includes(values, expected)
  for _, value in ipairs(values or {}) do
    if value == expected then
      return true
    end
  end
  return false
end

local function default_prepare(parsers, provided_registry)
  if not includes(parsers, 'dap_repl') then
    return
  end
  local registry = provided_registry or require 'nvim-treesitter.parsers'
  if registry.dap_repl then
    return
  end

  -- nvim-dap-repl-highlights registers its main-branch local parser from a
  -- User TSUpdate callback. First-run discovery precedes any TSUpdate, so
  -- explicitly replay that registration event before inspecting providers.
  pcall(vim.api.nvim_exec_autocmds, 'User', { pattern = 'TSUpdate', modeline = false })
  if registry.dap_repl then
    return
  end

  -- A freshly installed provider may not have run its plugin config yet.
  local loaded, provider = pcall(require, 'nvim-dap-repl-highlights')
  if loaded and type(provider.setup) == 'function' then
    pcall(provider.setup)
    pcall(vim.api.nvim_exec_autocmds, 'User', { pattern = 'TSUpdate', modeline = false })
  end
end

function TreeSitter:discover()
  self.prepare()
  local installed = {}
  for _, parser in ipairs(self.installed()) do
    installed[parser] = true
  end
  local missing = {}
  for _, parser in ipairs(self.parsers) do
    if not installed[parser] then
      missing[#missing + 1] = parser
    end
  end
  return missing
end

function TreeSitter:_record(parsers)
  local called, recorded, record_error = pcall(self.record, parsers)
  if not called then
    return nil, tostring(recorded)
  end
  if recorded ~= true then
    return nil, tostring(record_error or 'parser receipt persistence failed')
  end
  return true
end

function TreeSitter:install(options)
  options = options or {}
  local missing = self:discover()
  if #missing == 0 then
    return { ok = true, pending = false, missing = {} }
  end

  local ok, task_or_error = pcall(self.install_parsers, missing)
  if not ok then
    return { ok = false, error = tostring(task_or_error), missing = missing }
  end
  if not options.wait then
    if options.on_complete then
      local awaited, await_error = pcall(task_or_error.await, task_or_error, function(error, result)
        local record_error
        if error == nil and result ~= false then
          local recorded
          recorded, record_error = self:_record(missing)
          if not recorded then
            result = false
          end
        end
        local remaining = self:discover()
        options.on_complete {
          ok = error == nil and result ~= false and #remaining == 0,
          error = error and tostring(error) or record_error or (result == false and 'parser installation failed' or nil),
          missing = remaining,
        }
      end)
      if not awaited then
        return { ok = false, error = tostring(await_error), missing = missing }
      end
    end
    return { ok = true, pending = true, missing = missing }
  end

  local timeout_ms = math.min(options.timeout_ms or self.timeout_ms, self.timeout_ms)
  local waited, wait_result = pcall(task_or_error.wait, task_or_error, timeout_ms)
  if not waited then
    return { ok = false, error = tostring(wait_result), missing = self:discover() }
  end
  if wait_result == false then
    return { ok = false, error = 'parser installation failed', missing = self:discover() }
  end
  local recorded, record_error = self:_record(missing)
  if not recorded then
    return { ok = false, error = record_error, missing = self:discover() }
  end
  local remaining = self:discover()
  return {
    ok = #remaining == 0,
    error = #remaining > 0 and 'parser verification failed' or nil,
    missing = remaining,
  }
end

local M = {}

function M.new(options)
  options = options or {}
  local manifest = options.manifest or require 'nv_ide.toolchain.manifest'
  local parsers = sorted_unique(options.parsers or manifest.treesitter.parsers)
  local using_default_discovery = options.installed == nil
  local installed = options.installed or function()
    return default_installed(options.config, options.parser_registry)
  end
  local record = options.record or function(parsers)
    if not using_default_discovery then
      return true
    end
    return default_record(parsers, options.config, options.parser_registry)
  end
  return setmetatable({
    parsers = parsers,
    prepare = options.prepare or function()
      default_prepare(parsers, options.parser_registry)
    end,
    installed = installed,
    install_parsers = options.install or default_install,
    record = record,
    timeout_ms = options.timeout_ms or 300000,
  }, TreeSitter)
end

return M
