local h = require 'tests.headless.harness'

local function find_plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then
      return spec
    end
  end
  return nil
end

local function resolve_opts(spec)
  return type(spec.opts) == 'function' and spec.opts() or spec.opts
end

h.describe('single-owner Mason installation', function()
  h.it('gives the complete raw inventory only to mason-tool-installer', function()
    local saved_util = package.loaded.util
    package.loaded.util = {
      toggle = { inlay_hints = function() end },
    }
    package.loaded['plugins.lsp'] = nil
    local ok, specs = pcall(require, 'plugins.lsp')
    package.loaded.util = saved_util
    if not ok then
      error(specs, 0)
    end
    local manifest = require 'nv_ide.toolchain.manifest'
    local installer = assert(find_plugin(specs, 'WhoIsSethDaniel/mason-tool-installer.nvim'))
    local opts = resolve_opts(installer)

    h.deep_equal(opts.ensure_installed, manifest.mason.packages)
    h.truthy(opts.run_on_start)
    h.truthy(opts.start_delay > 0 and opts.start_delay <= 1000, 'startup delay must stay short')
    h.equal(opts.debounce_hours, nil, 'the project state owns debounce')
    h.falsy(opts.auto_update)
    h.deep_equal(opts.integrations, {
      ['mason-lspconfig'] = false,
      ['mason-null-ls'] = false,
      ['mason-nvim-dap'] = false,
    })

    local mason_lsp = assert(find_plugin(specs, 'mason-org/mason-lspconfig.nvim'))
    h.equal(resolve_opts(mason_lsp).ensure_installed, nil)
    h.falsy(resolve_opts(mason_lsp).automatic_enable)
  end)

  h.it('discovers missing packages and always delegates asynchronous installs', function()
    package.loaded['nv_ide.toolchain.mason'] = nil
    local calls = {}
    local adapter = require('nv_ide.toolchain.mason').new {
      packages = { 'stylua', 'lua-language-server', 'stylua' },
      is_installed = function(name)
        return name == 'stylua'
      end,
      installer = {
        run_on_start = function()
          calls[#calls + 1] = { 'startup' }
        end,
        check_install = function(update, sync)
          calls[#calls + 1] = { 'install', update, sync }
        end,
      },
    }

    h.deep_equal(adapter:discover(), { 'lua-language-server' })
    adapter:install { startup = true, wait = false }
    adapter:install { startup = false, wait = true }
    h.deep_equal(calls, {
      { 'startup' },
      { 'install', false, false },
    })
  end)

  h.it('treats partial receipts and active installs as missing', function()
    package.loaded['nv_ide.toolchain.mason'] = nil
    local function optional(value)
      return {
        or_else = function(_, fallback)
          return value == nil and fallback or value
        end,
      }
    end
    local complete_receipt = optional { metrics = { completion_time = 123 } }
    local packages = {
      installing = {
        is_installing = function()
          return true
        end,
        is_installed = function()
          return true
        end,
        get_receipt = function()
          return complete_receipt
        end,
        get_installed_version = function()
          return '2.0.0'
        end,
      },
      partial = {
        is_installing = function()
          return false
        end,
        is_installed = function()
          return true
        end,
        get_receipt = function()
          return optional { metrics = {} }
        end,
        get_installed_version = function()
          return '2.0.0'
        end,
      },
      valid = {
        is_installing = function()
          return false
        end,
        is_installed = function()
          return true
        end,
        get_receipt = function()
          return complete_receipt
        end,
        get_installed_version = function()
          return '1.0.0'
        end,
      },
    }
    local adapter = require('nv_ide.toolchain.mason').new {
      packages = { 'valid', 'unknown', 'partial', 'installing' },
      registry = {
        get_package = function(name)
          if not packages[name] then
            error 'unknown package'
          end
          return packages[name]
        end,
      },
    }

    h.deep_equal(adapter:discover(), { 'installing', 'partial', 'unknown' })
  end)

  h.it('quarantines a non-installing incomplete package before MTI and surfaces its completion event', function()
    h.with_temp_dir(function(dir)
      package.loaded['nv_ide.toolchain.mason'] = nil
      local package_path = vim.fs.joinpath(dir, 'packages', 'stylua')
      vim.fn.mkdir(package_path, 'p')
      local event
      local completed
      local calls = {}
      local receipt_complete = false
      local package = {
        is_installing = function()
          return false
        end,
        is_installed = function()
          return true
        end,
        get_receipt = function()
          return {
            or_else = function()
              return { metrics = receipt_complete and { completion_time = 123 } or {} }
            end,
          }
        end,
        get_installed_version = function()
          return '2.1.0'
        end,
        get_install_path = function()
          return package_path
        end,
      }
      local adapter = require('nv_ide.toolchain.mason').new {
        packages = { 'stylua' },
        registry = {
          get_package = function(name)
            h.equal(name, 'stylua')
            return package
          end,
        },
        installer = {
          check_install = function(update, sync)
            h.falsy(update)
            h.falsy(sync)
            calls[#calls + 1] = 'install'
          end,
        },
        create_autocmd = function(kind, options)
          h.equal(kind, 'User')
          h.equal(options.pattern, 'MasonToolsUpdateCompleted')
          event = options.callback
          calls[#calls + 1] = 'listen'
          return 17
        end,
        delete_autocmd = function() end,
      }

      local result = adapter:install {
        wait = true,
        on_complete = function(value)
          completed = value
        end,
      }

      h.truthy(result.pending)
      h.deep_equal(calls, { 'listen', 'install' })
      h.falsy(vim.uv.fs_stat(package_path), 'the incomplete directory must no longer block MTI')
      local quarantined = vim.fn.glob(package_path .. '.nv-ide-invalid-*', false, true)
      h.equal(#quarantined, 1)
      h.equal(completed, nil, 'completion must wait for the MTI event')

      receipt_complete = true
      event { data = { 'stylua' } }
      h.truthy(completed.ok)
      h.deep_equal(completed.quarantined, quarantined)
    end)
  end)

  h.it('fails immediately when the MTI completion event leaves a package incomplete', function()
    package.loaded['nv_ide.toolchain.mason'] = nil
    local event
    local completed
    local adapter = require('nv_ide.toolchain.mason').new {
      packages = { 'stylua' },
      is_installed = function()
        return false
      end,
      installer = {
        check_install = function() end,
      },
      create_autocmd = function(_, options)
        event = options.callback
        return 18
      end,
      delete_autocmd = function() end,
    }

    local result = adapter:install {
      wait = true,
      on_complete = function(value)
        completed = value
      end,
    }
    h.truthy(result.pending)

    event { data = { 'stylua' } }

    h.falsy(completed.ok)
    h.deep_equal(completed.missing, { 'stylua' })
    h.matches(completed.error, 'stylua')
  end)

  h.it('does not quarantine a package that begins installing during repair preparation', function()
    h.with_temp_dir(function(dir)
      package.loaded['nv_ide.toolchain.mason'] = nil
      local package_path = vim.fs.joinpath(dir, 'packages', 'stylua')
      vim.fn.mkdir(package_path, 'p')
      local installing_checks = 0
      local package = {
        is_installing = function()
          installing_checks = installing_checks + 1
          return installing_checks >= 3
        end,
        is_installed = function()
          return true
        end,
        get_receipt = function()
          return {
            or_else = function()
              return { metrics = {} }
            end,
          }
        end,
        get_installed_version = function()
          return '2.1.0'
        end,
        get_install_path = function()
          return package_path
        end,
      }
      local adapter = require('nv_ide.toolchain.mason').new {
        packages = { 'stylua' },
        registry = {
          get_package = function()
            return package
          end,
        },
        installer = { check_install = function() end },
      }

      local result = adapter:install { wait = true }

      h.truthy(result.pending)
      h.truthy(vim.uv.fs_stat(package_path), 'active installation directory must remain in place')
      h.deep_equal(vim.fn.glob(package_path .. '.nv-ide-invalid-*', false, true), {})
    end)
  end)

  h.it('removes every competing package installer', function()
    local lsp = table.concat(vim.fn.readfile 'lua/plugins/lsp/init.lua', '\n')
    local dap = table.concat(vim.fn.readfile 'lua/plugins/dap.lua', '\n')
    h.falsy(lsp:find("vim.cmd('MasonInstall", 1, true))
    h.falsy(lsp:find("require('mason-registry')", 1, true))
    h.falsy(lsp:find('ensure_installed = {', 1, true))
    h.falsy(dap:find('automatic_installation = true', 1, true))
  end)
end)
