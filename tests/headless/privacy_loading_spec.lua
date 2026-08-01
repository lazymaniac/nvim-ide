local h = require('tests.headless.harness')

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then return spec end
  end
  error('plugin spec not found: ' .. name)
end

local function dependency(spec, name)
  for _, candidate in ipairs(spec.dependencies or {}) do
    if type(candidate) == 'table' and candidate[1] == name then return candidate end
    if candidate == name then return candidate end
  end
  error('dependency spec not found: ' .. name)
end

h.describe('AI privacy boundary', function()
  h.it('uses quiet, code-private defaults and disables unchecked project loading', function()
    local spec = plugin(dofile('lua/plugins/ai.lua'), 'olimorris/codecompanion.nvim')

    h.equal(spec.opts.opts.log_level, 'ERROR')
    h.falsy(spec.opts.opts.send_code)
    h.falsy(spec.opts.opts.per_project_config.enabled)
    h.truthy(spec.opts.adapters.http.ollama, 'the local Ollama adapter must remain available by default')
    h.falsy(spec.opts.adapters.http.anthropic, 'remote HTTP adapters must not be enabled globally')
  end)

  h.it('ignores an untrusted project override without evaluating it', function()
    local resolver = require('nv_ide.codecompanion')
    local evaluated = false
    local base = { opts = { send_code = false }, marker = 'base' }
    local resolved = resolver.resolve(base, {
      cwd = '/workspace/project',
      secure_read = function(path)
        h.equal(path, '/workspace/project/.codecompanion.lua')
        return nil
      end,
      evaluate = function()
        evaluated = true
        return { marker = 'project' }
      end,
    })

    h.equal(resolved.marker, 'base')
    h.falsy(evaluated, 'untrusted project configuration must never execute')
  end)

  h.it('merges a project override only after Neovim returns trusted contents', function()
    local resolver = require('nv_ide.codecompanion')
    local trusted_source = 'return { adapters = { http = { anthropic = {} } } }'
    local resolved = resolver.resolve({
      adapters = { http = { ollama = {} } },
      opts = { send_code = false },
    }, {
      cwd = '/workspace/project',
      secure_read = function() return trusted_source end,
    })

    h.truthy(resolved.adapters.http.ollama)
    h.truthy(resolved.adapters.http.anthropic)
    h.falsy(resolved.opts.send_code)
  end)

  h.it('rejects malformed trusted project configuration', function()
    local resolver = require('nv_ide.codecompanion')

    h.raises('must return a table', function()
      resolver.resolve({}, {
        cwd = '/workspace/project',
        secure_read = function() return 'return "not a table"' end,
      })
    end)
    h.raises('failed to compile trusted CodeCompanion config', function()
      resolver.resolve({}, {
        cwd = '/workspace/project',
        secure_read = function() return 'return {' end,
      })
    end)
  end)
end)

h.describe('language loading boundaries', function()
  h.it('loads LuaSnip sources only from the LuaSnip config phase', function()
    local blink = plugin(dofile('lua/plugins/autocompletion.lua'), 'saghen/blink.cmp')
    local luasnip = dependency(blink, 'L3MON4D3/LuaSnip')
    h.falsy(luasnip.init, 'LuaSnip loaders must not run during plugin initialization')
    h.truthy(type(luasnip.config) == 'function')

    local calls = {}
    local previous = package.loaded['luasnip.loaders.from_vscode']
    package.loaded['luasnip.loaders.from_vscode'] = {
      lazy_load = function(options) calls[#calls + 1] = options or {} end,
    }
    local ok, err = xpcall(luasnip.config, debug.traceback)
    package.loaded['luasnip.loaders.from_vscode'] = previous
    if not ok then error(err, 0) end

    h.equal(#calls, 2)
    h.equal(calls[2].paths[1], vim.fn.stdpath('config') .. '/snippets')
  end)

  h.it('binds heavyweight language integrations to their filetypes', function()
    local flutter = plugin(dofile('lua/plugins/lsp/lang/flutter.lua'), 'nvim-flutter/flutter-tools.nvim')
    h.truthy(vim.tbl_contains(flutter.ft or {}, 'dart'))
    h.falsy(flutter.lazy == false)

    local sexp = plugin(dofile('lua/plugins/lsp/lang/clojure.lua'), 'PaterJason/nvim-treesitter-sexp')
    h.truthy(vim.tbl_contains(sexp.ft or {}, 'clojure'))
    h.truthy(vim.tbl_contains(sexp.ft or {}, 'fennel'))
  end)

  h.it('enables Rust inlay hints only for the attached buffer', function()
    local rust = plugin(dofile('lua/plugins/lsp/lang/rust.lua'), 'mrcjkb/rustaceanvim')
    local previous_which_key = package.loaded['which-key']
    local previous_enable = vim.lsp.inlay_hint.enable
    local previous_config = vim.g.rustaceanvim
    local calls = {}
    package.loaded['which-key'] = { add = function() end }
    vim.lsp.inlay_hint.enable = function(enabled, opts)
      calls[#calls + 1] = { enabled, opts }
    end

    local ok, err = xpcall(function()
      rust.config()
      vim.g.rustaceanvim.server.on_attach({}, 42)
    end, debug.traceback)

    package.loaded['which-key'] = previous_which_key
    vim.lsp.inlay_hint.enable = previous_enable
    vim.g.rustaceanvim = previous_config
    if not ok then error(err, 0) end
    h.deep_equal(calls, { { true, { bufnr = 42 } } })
  end)

  h.it('discovers Java only at its filetype-triggered options boundary', function()
    local previous_java = package.loaded['nv_ide.java']
    local previous_setup = package.loaded['jdtls.setup']
    local previous_notify = vim.notify
    local discoveries, notifications = 0, {}
    package.loaded['nv_ide.java'] = {
      discover = function()
        discoveries = discoveries + 1
        return {
          jdtls = '/tools/jdtls',
          lombok = '/mason/share/jdtls/lombok.jar',
          formatter = '/config/java-formatter.xml',
          runtimes = {},
          errors = { 'asdf where java timed out after 25 ms' },
        }
      end,
    }
    package.loaded['jdtls.setup'] = { find_root = function() return '/repo' end }
    vim.notify = function(message, level)
      notifications[#notifications + 1] = { message = message, level = level }
    end

    local ok, err = xpcall(function()
      local java = plugin(dofile('lua/plugins/lsp/lang/java.lua'), 'mfussenegger/nvim-jdtls')
      h.equal(discoveries, 0)
      h.equal(#notifications, 0)
      local opts = java.opts()
      h.equal(discoveries, 1)
      h.equal(opts.cmd[1], '/tools/jdtls')
      h.equal(opts.paths.lombok, '/mason/share/jdtls/lombok.jar')
      h.equal(#notifications, 1)
      h.matches(notifications[1].message, 'asdf where java timed out after 25 ms')
      h.equal(notifications[1].level, vim.log.levels.WARN)
    end, debug.traceback)

    package.loaded['nv_ide.java'] = previous_java
    package.loaded['jdtls.setup'] = previous_setup
    vim.notify = previous_notify
    if not ok then error(err, 0) end
  end)
end)
