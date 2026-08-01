local h = require 'tests.headless.harness'

local function adapter_with(options)
  package.loaded['nv_ide.toolchain.treesitter'] = nil
  return require('nv_ide.toolchain.treesitter').new(options)
end

h.describe('Tree-sitter installation adapter', function()
  h.it('requests only missing deduplicated parsers without blocking startup', function()
    local requested
    local waited = false
    local awaiting
    local completed
    local installed = { 'vim', 'query' }
    local adapter = adapter_with {
      parsers = { 'lua', 'vim', 'lua', 'query' },
      installed = function()
        return installed
      end,
      install = function(missing)
        requested = vim.deepcopy(missing)
        return {
          wait = function()
            waited = true
          end,
          await = function(_, callback)
            awaiting = callback
          end,
        }
      end,
    }

    h.deep_equal(adapter:discover(), { 'lua' })
    h.truthy(adapter:install({
      wait = false,
      on_complete = function(result)
        completed = result
      end,
    }).pending)
    h.deep_equal(requested, { 'lua' })
    h.falsy(waited, 'interactive startup must stay asynchronous')
    h.equal(completed, nil)

    installed[#installed + 1] = 'lua'
    awaiting(nil, true)
    h.truthy(completed.ok)
    h.deep_equal(completed.missing, {})
  end)

  h.it('waits with a timeout and verifies availability for bang or headless runs', function()
    local installed = { 'vim' }
    local waited_with
    local adapter = adapter_with {
      parsers = { 'lua', 'vim' },
      timeout_ms = 3210,
      installed = function()
        return installed
      end,
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

    local result = adapter:install { wait = true, timeout_ms = 1200 }
    h.equal(waited_with, 1200)
    h.truthy(result.ok)
    h.deep_equal(result.missing, {})
  end)

  h.it('reports timeout or post-install verification failures', function()
    local adapter = adapter_with {
      parsers = { 'lua' },
      installed = function()
        return {}
      end,
      install = function()
        return {
          wait = function()
            error 'timeout'
          end,
        }
      end,
    }
    local result = adapter:install { wait = true }
    h.falsy(result.ok)
    h.matches(result.error, 'timeout')
    h.deep_equal(result.missing, { 'lua' })
  end)

  h.it('requires parser-info revision evidence in default discovery', function()
    h.with_temp_dir(function(dir)
      vim.fn.writefile({ 'lua-revision' }, vim.fs.joinpath(dir, 'lua.revision'))
      local adapter = adapter_with {
        parsers = { 'lua', 'vim' },
        parser_registry = {
          lua = { install_info = { revision = 'lua-revision' } },
          vim = { install_info = { revision = 'vim-revision' } },
        },
        config = {
          get_installed = function(kind)
            h.equal(kind, 'parsers')
            return { 'lua', 'vim' }
          end,
          get_install_dir = function(kind)
            h.equal(kind, 'parser-info')
            return dir
          end,
        },
      }

      h.deep_equal(adapter:discover(), { 'vim' })
    end)
  end)

  h.it('forces repair when a parser binary exists without revision evidence', function()
    h.with_temp_dir(function(dir)
      local previous = package.loaded['nvim-treesitter']
      local requested
      package.loaded['nvim-treesitter'] = {
        install = function(missing, options)
          requested = { missing = vim.deepcopy(missing), options = vim.deepcopy(options) }
          return {
            wait = function()
              vim.fn.writefile({ 'repaired-revision' }, vim.fs.joinpath(dir, 'lua.revision'))
              return true
            end,
          }
        end,
      }

      local ok, result = xpcall(function()
        local adapter = adapter_with {
          parsers = { 'lua' },
          parser_registry = {
            lua = { install_info = { revision = 'repaired-revision' } },
          },
          config = {
            get_installed = function()
              return { 'lua' }
            end,
            get_install_dir = function()
              return dir
            end,
          },
        }
        h.deep_equal(adapter:discover(), { 'lua' })
        return adapter:install { wait = true }
      end, debug.traceback)
      package.loaded['nvim-treesitter'] = previous
      if not ok then
        error(result, 0)
      end

      h.deep_equal(requested.missing, { 'lua' })
      h.truthy(requested.options.force)
      h.truthy(result.ok)
      h.deep_equal(result.missing, {})
    end)
  end)

  h.it('persists dap_repl local-source evidence and invalidates it when the provider changes', function()
    h.with_temp_dir(function(dir)
      local parser_info = vim.fs.joinpath(dir, 'parser-info')
      local provider = vim.fs.joinpath(dir, 'nvim-dap-repl-highlights')
      vim.fn.mkdir(vim.fs.joinpath(provider, 'src'), 'p')
      vim.fn.mkdir(parser_info, 'p')
      vim.fn.writefile({ 'initial bundled parser source' }, vim.fs.joinpath(provider, 'src', 'parser.c'), 'b')
      vim.fn.writefile({}, vim.fs.joinpath(parser_info, 'dap_repl.revision'), 'b')

      local registry = {
        dap_repl = {
          install_info = { path = provider },
        },
      }
      local adapter = adapter_with {
        parsers = { 'dap_repl' },
        parser_registry = registry,
        config = {
          get_installed = function(kind)
            h.equal(kind, 'parsers')
            return { 'dap_repl' }
          end,
          get_install_dir = function(kind)
            h.equal(kind, 'parser-info')
            return parser_info
          end,
        },
        install = function(missing)
          h.deep_equal(missing, { 'dap_repl' })
          return {
            wait = function()
              return true
            end,
          }
        end,
      }

      h.deep_equal(adapter:discover(), { 'dap_repl' })
      local result = adapter:install { wait = true }
      h.truthy(result.ok)
      h.deep_equal(adapter:discover(), {})

      local receipt_path = vim.fs.joinpath(parser_info, 'dap_repl.nv-ide-receipt')
      local receipt = table.concat(vim.fn.readfile(receipt_path, 'b'), '\n')
      h.truthy(receipt:match '^nv%-ide%-ts%-v1:source%-sha256:[0-9a-f]+$')
      h.equal(table.concat(vim.fn.readfile(vim.fs.joinpath(parser_info, 'dap_repl.revision'), 'b'), '\n'), '')

      vim.fn.writefile({ 'changed bundled parser source' }, vim.fs.joinpath(provider, 'src', 'parser.c'), 'b')
      h.deep_equal(adapter:discover(), { 'dap_repl' }, 'a provider source change must force parser recompilation')
    end)
  end)

  h.it('removes full-list installation from the Tree-sitter plugin config', function()
    local source = table.concat(vim.fn.readfile 'lua/plugins/treesitter.lua', '\n')
    h.falsy(source:find("require('nvim-treesitter').install(opts.ensure_installed)", 1, true))
  end)
end)
