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

local function default_installed()
  return require('nvim-treesitter.config').get_installed 'parsers'
end

local function default_install(missing)
  return require('nvim-treesitter').install(missing)
end

function TreeSitter:discover()
  local installed = {}
  for _, parser in ipairs(self.installed()) do installed[parser] = true end
  local missing = {}
  for _, parser in ipairs(self.parsers) do
    if not installed[parser] then missing[#missing + 1] = parser end
  end
  return missing
end

function TreeSitter:install(options)
  options = options or {}
  local missing = self:discover()
  if #missing == 0 then return { ok = true, pending = false, missing = {} } end

  local ok, task_or_error = pcall(self.install_parsers, missing)
  if not ok then return { ok = false, error = tostring(task_or_error), missing = missing } end
  if not options.wait then return { ok = true, pending = true, missing = missing } end

  local waited, wait_error = pcall(task_or_error.wait, task_or_error, self.timeout_ms)
  if not waited then
    return { ok = false, error = tostring(wait_error), missing = self:discover() }
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
  return setmetatable({
    parsers = sorted_unique(options.parsers or manifest.treesitter.parsers),
    installed = options.installed or default_installed,
    install_parsers = options.install or default_install,
    timeout_ms = options.timeout_ms or 300000,
  }, TreeSitter)
end

return M
