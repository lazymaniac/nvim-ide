local h = require 'tests.headless.harness'

local function find_plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then return spec end
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
    if not ok then error(specs, 0) end
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

  h.it('discovers missing packages and delegates both startup and blocking installs', function()
    package.loaded['nv_ide.toolchain.mason'] = nil
    local calls = {}
    local adapter = require('nv_ide.toolchain.mason').new {
      packages = { 'stylua', 'lua-language-server', 'stylua' },
      is_installed = function(name) return name == 'stylua' end,
      installer = {
        run_on_start = function() calls[#calls + 1] = { 'startup' } end,
        check_install = function(update, sync) calls[#calls + 1] = { 'install', update, sync } end,
      },
    }

    h.deep_equal(adapter:discover(), { 'lua-language-server' })
    adapter:install { startup = true, wait = false }
    adapter:install { startup = false, wait = true }
    h.deep_equal(calls, {
      { 'startup' },
      { 'install', false, true },
    })
  end)

  h.it('removes every competing package installer', function()
    local lsp = table.concat(vim.fn.readfile('lua/plugins/lsp/init.lua'), '\n')
    local dap = table.concat(vim.fn.readfile('lua/plugins/dap.lua'), '\n')
    h.falsy(lsp:find("vim.cmd('MasonInstall", 1, true))
    h.falsy(lsp:find("require('mason-registry')", 1, true))
    h.falsy(lsp:find('ensure_installed = {', 1, true))
    h.falsy(dap:find('automatic_installation = true', 1, true))
  end)
end)
