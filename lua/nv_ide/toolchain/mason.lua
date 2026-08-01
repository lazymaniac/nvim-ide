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

local function package_status(name, provided_registry)
  local loaded, registry = pcall(function()
    return provided_registry or require 'mason-registry'
  end)
  if not loaded then
    return { complete = false, error = tostring(registry) }
  end

  local found, package = pcall(registry.get_package, name)
  if not found or not package then
    return { complete = false, error = tostring(package) }
  end
  local checked, installing = pcall(package.is_installing, package)
  if not checked or installing then
    return { complete = false, installing = installing == true, package = package }
  end
  local installed_ok, installed = pcall(package.is_installed, package)
  if not installed_ok or not installed then
    return { complete = false, package = package }
  end
  local receipt_ok, receipt = pcall(function()
    return package:get_receipt():or_else(nil)
  end)
  local receipt_complete = receipt_ok and type(receipt) == 'table' and type(receipt.metrics) == 'table' and tonumber(receipt.metrics.completion_time) ~= nil
  if not receipt_complete then
    return { complete = false, package = package }
  end
  local versioned, version = pcall(package.get_installed_version, package)
  return {
    complete = versioned and type(version) == 'string' and version ~= '',
    package = package,
  }
end

local function quarantine(package, name)
  local checked, installing = pcall(package.is_installing, package)
  if not checked then
    return nil, ('failed to verify Mason install activity for %s: %s'):format(name, tostring(installing))
  end
  if installing then
    return nil
  end

  local resolved, path = pcall(package.get_install_path, package)
  if not resolved then
    return nil, tostring(path)
  end
  if not path or not vim.uv.fs_stat(path) then
    return nil
  end
  path = vim.fs.normalize(path)
  if vim.fs.basename(path) ~= name then
    return nil, ('refusing to quarantine unexpected Mason path for %s: %s'):format(name, path)
  end

  local target = path .. ('.nv-ide-invalid-%d-%d'):format(vim.uv.os_getpid(), vim.uv.hrtime())
  local renamed, rename_error = vim.uv.fs_rename(path, target)
  if not renamed then
    return nil, ('failed to quarantine incomplete Mason package %s: %s'):format(name, tostring(rename_error))
  end
  return target
end

local function default_installer()
  return require 'mason-tool-installer'
end

function Mason:discover()
  local missing = {}
  for _, package in ipairs(self.packages) do
    if not self.is_installed(package) then
      missing[#missing + 1] = package
    end
  end
  return missing
end

function Mason:_prepare(missing)
  if not self.inspect_package then
    return {}, nil
  end
  local quarantined = {}
  for _, name in ipairs(missing) do
    local status = self.inspect_package(name)
    if status.package and not status.installing and not status.complete then
      local path, quarantine_error = quarantine(status.package, name)
      if quarantine_error then
        return quarantined, quarantine_error
      end
      if path then
        quarantined[#quarantined + 1] = path
      end
    end
  end
  return quarantined, nil
end

function Mason:install(options)
  options = options or {}
  local missing = self:discover()
  if #missing == 0 then
    return { ok = true, pending = false, missing = {} }
  end
  local quarantined, prepare_error = self:_prepare(missing)
  if prepare_error then
    return { ok = false, error = prepare_error, missing = missing, quarantined = quarantined }
  end

  local completed = false
  local autocmd
  local function complete(result)
    if completed then
      return
    end
    completed = true
    if autocmd then
      pcall(self.delete_autocmd, autocmd)
    end
    result.quarantined = vim.deepcopy(quarantined)
    if options.on_complete then
      options.on_complete(result)
    end
  end
  if options.on_complete then
    autocmd = self.create_autocmd('User', {
      pattern = 'MasonToolsUpdateCompleted',
      once = true,
      callback = function(event)
        local discovered, remaining = pcall(self.discover, self)
        if not discovered then
          complete {
            ok = false,
            error = 'Mason post-install verification failed: ' .. tostring(remaining),
            missing = vim.deepcopy(missing),
            data = event.data,
          }
        elseif #remaining > 0 then
          complete {
            ok = false,
            error = 'Mason installation completed without valid receipts for: ' .. table.concat(remaining, ', '),
            missing = remaining,
            data = event.data,
          }
        else
          complete { ok = true, missing = {}, data = event.data }
        end
      end,
    })
  end

  local loaded, installer = pcall(function()
    return self.installer or default_installer()
  end)
  if not loaded then
    complete { ok = false, error = tostring(installer) }
    return { ok = false, error = tostring(installer), missing = missing, quarantined = quarantined }
  end
  local started, install_error
  if options.startup and not options.wait then
    started, install_error = pcall(installer.run_on_start)
  else
    started, install_error = pcall(installer.check_install, false, false)
  end
  if not started then
    complete { ok = false, error = tostring(install_error) }
    return { ok = false, error = tostring(install_error), missing = missing, quarantined = quarantined }
  end
  return { ok = true, pending = true, missing = missing, quarantined = quarantined }
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
  local inspect_package
  if not options.is_installed then
    inspect_package = function(name)
      return package_status(name, options.registry)
    end
  end
  local is_installed = options.is_installed or function(name)
    return inspect_package(name).complete
  end
  return setmetatable({
    packages = sorted_unique(options.packages or manifest.mason.packages),
    is_installed = is_installed,
    inspect_package = inspect_package,
    installer = options.installer,
    create_autocmd = options.create_autocmd or vim.api.nvim_create_autocmd,
    delete_autocmd = options.delete_autocmd or vim.api.nvim_del_autocmd,
  }, Mason)
end

return M
