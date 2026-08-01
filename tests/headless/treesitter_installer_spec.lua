local h = require 'tests.headless.harness'

local function adapter_with(options)
  package.loaded['nv_ide.toolchain.treesitter'] = nil
  return require('nv_ide.toolchain.treesitter').new(options)
end

h.describe('Tree-sitter installation adapter', function()
  h.it('requests only missing deduplicated parsers without blocking startup', function()
    local requested
    local waited = false
    local adapter = adapter_with {
      parsers = { 'lua', 'vim', 'lua', 'query' },
      installed = function() return { 'vim', 'query' } end,
      install = function(missing)
        requested = vim.deepcopy(missing)
        return { wait = function() waited = true end }
      end,
    }

    h.deep_equal(adapter:discover(), { 'lua' })
    h.truthy(adapter:install { wait = false }.pending)
    h.deep_equal(requested, { 'lua' })
    h.falsy(waited, 'interactive startup must stay asynchronous')
  end)

  h.it('waits with a timeout and verifies availability for bang or headless runs', function()
    local installed = { 'vim' }
    local waited_with
    local adapter = adapter_with {
      parsers = { 'lua', 'vim' },
      timeout_ms = 3210,
      installed = function() return installed end,
      install = function(missing)
        return {
          wait = function(_, timeout)
            waited_with = timeout
            installed = vim.list_extend(installed, missing)
            return true
          end,
        }
      end,
    }

    local result = adapter:install { wait = true }
    h.equal(waited_with, 3210)
    h.truthy(result.ok)
    h.deep_equal(result.missing, {})
  end)

  h.it('reports timeout or post-install verification failures', function()
    local adapter = adapter_with {
      parsers = { 'lua' },
      installed = function() return {} end,
      install = function()
        return { wait = function() error 'timeout' end }
      end,
    }
    local result = adapter:install { wait = true }
    h.falsy(result.ok)
    h.matches(result.error, 'timeout')
    h.deep_equal(result.missing, { 'lua' })
  end)

  h.it('removes full-list installation from the Tree-sitter plugin config', function()
    local source = table.concat(vim.fn.readfile('lua/plugins/treesitter.lua'), '\n')
    h.falsy(source:find("require('nvim-treesitter').install(opts.ensure_installed)", 1, true))
  end)
end)
