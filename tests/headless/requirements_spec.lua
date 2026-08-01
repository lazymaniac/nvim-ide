local h = require 'tests.headless.harness'

h.describe('early Neovim requirements', function()
  h.it('fails before Lazy bootstrap when Neovim is older than 0.12', function()
    package.loaded['nv_ide.requirements'] = nil
    local requirements = require 'nv_ide.requirements'
    h.raises('NV-IDE requires Neovim >= 0.12.0', function()
      requirements.assert_supported {
        has = function(feature)
          h.equal(feature, 'nvim-0.12')
          return 0
        end,
        version = function()
          return { major = 0, minor = 11, patch = 4 }
        end,
      }
    end)
  end)

  h.it('allows Neovim 0.12 and runs the guard before the toolchain or Lazy', function()
    local requirements = require 'nv_ide.requirements'
    requirements.assert_supported {
      has = function()
        return 1
      end,
      version = function()
        return { major = 0, minor = 12, patch = 0 }
      end,
    }

    local source = table.concat(vim.fn.readfile('init.lua'), '\n')
    local guard = assert(source:find("require('nv_ide.requirements').assert_supported()", 1, true))
    local toolchain = assert(source:find("require 'nv_ide.toolchain'", 1, true))
    h.truthy(guard < toolchain)
  end)
end)
