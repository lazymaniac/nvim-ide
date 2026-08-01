local Mason = {}
Mason.__index = Mason

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

local function default_installed(name)
  local ok, installed = pcall(require('mason-registry').is_installed, name)
  return ok and installed == true
end

local function default_installer()
  return require 'mason-tool-installer'
end

function Mason:discover()
  local missing = {}
  for _, package in ipairs(self.packages) do
    if not self.is_installed(package) then missing[#missing + 1] = package end
  end
  return missing
end

function Mason:install(options)
  options = options or {}
  local installer = self.installer or default_installer()
  if options.startup and not options.wait then
    installer.run_on_start()
    return { ok = true, pending = true }
  end
  installer.check_install(false, options.wait == true)
  return { ok = true, pending = not options.wait }
end

local M = {}

function M.options(manifest)
  manifest = manifest or require 'nv_ide.toolchain.manifest'
  return {
    ensure_installed = vim.deepcopy(manifest.mason.packages),
    auto_update = false,
    run_on_start = true,
    start_delay = 250,
    debounce_hours = nil,
    integrations = {
      ['mason-lspconfig'] = false,
      ['mason-null-ls'] = false,
      ['mason-nvim-dap'] = false,
    },
  }
end

function M.setup(options)
  require('mason-tool-installer').setup(options)
  pcall(vim.api.nvim_del_augroup_by_name, 'mti_start')
end

function M.new(options)
  options = options or {}
  local manifest = options.manifest or require 'nv_ide.toolchain.manifest'
  return setmetatable({
    packages = sorted_unique(options.packages or manifest.mason.packages),
    is_installed = options.is_installed or default_installed,
    installer = options.installer,
  }, Mason)
end

return M
