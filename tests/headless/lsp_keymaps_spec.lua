local h = require('tests.headless.harness')

local function load_keymaps()
  package.loaded['plugins.lsp.keymaps'] = nil
  return require('plugins.lsp.keymaps')
end

h.describe('LSP keymaps', function()
  h.it('returns an immutable copy of the base mappings', function()
    local keymaps = load_keymaps()
    local first = keymaps.get()
    first[1][1] = '<broken>'
    local second = keymaps.get()
    h.equal(second[1][1], 'K')
  end)

  h.it('does not leak one clients mappings into another buffer', function()
    local keymaps = load_keymaps()
    local server_opts = {
      alpha = { keys = { { 'ga', '<cmd>Alpha<cr>' } } },
      beta = { keys = { { 'gb', '<cmd>Beta<cr>' } } },
    }
    local function resolve_for(client)
      return keymaps.resolve(client == 'alpha' and 11 or 22, {
        clients = { { name = client } },
        server_opts = server_opts,
        resolve = function(spec) return spec end,
      })
    end

    local alpha = resolve_for('alpha')
    local beta = resolve_for('beta')
    local function has_lhs(maps, lhs)
      for _, map in ipairs(maps) do
        if map[1] == lhs then return true end
      end
      return false
    end

    h.truthy(has_lhs(alpha, 'ga'))
    h.falsy(has_lhs(alpha, 'gb'))
    h.truthy(has_lhs(beta, 'gb'))
    h.falsy(has_lhs(beta, 'ga'))
  end)

  h.it('checks dynamic method support for the attached buffer', function()
    local keymaps = load_keymaps()
    local seen
    local supported = keymaps.has(37, 'signatureHelp', {
      clients = {
        {
          supports_method = function(_, method, buffer)
            seen = { method = method, buffer = buffer }
            return true
          end,
        },
      },
    })

    h.truthy(supported)
    h.equal(seen.method, 'textDocument/signatureHelp')
    h.equal(seen.buffer, 37)
  end)

  h.it('passes an integer buffer through the legacy client-list fallback', function()
    local previous_util = package.loaded.util
    local previous_module = package.loaded['util.lsp']
    local previous_get_clients = vim.lsp.get_clients
    local previous_active_clients = vim.lsp.get_active_clients
    local seen
    package.loaded.util = {}
    package.loaded['util.lsp'] = nil
    vim.lsp.get_clients = nil
    vim.lsp.get_active_clients = function()
      return {
        {
          supports_method = function(_, method, buffer)
            seen = { method, buffer }
            return true
          end,
        },
      }
    end

    local clients = require('util.lsp').get_clients { bufnr = 41, method = 'textDocument/hover' }

    vim.lsp.get_clients = previous_get_clients
    vim.lsp.get_active_clients = previous_active_clients
    package.loaded['util.lsp'] = previous_module
    package.loaded.util = previous_util
    h.equal(#clients, 1)
    h.deep_equal(seen, { 'textDocument/hover', 41 })
  end)

  h.it('reapplies mappings to every buffer after dynamic registration', function()
    local keymaps = load_keymaps()
    local callbacks = {}
    local handlers = {
      ['client/registerCapability'] = function()
        callbacks.original = (callbacks.original or 0) + 1
        return 'registered'
      end,
    }
    local applied = {}
    local client = { attached_buffers = { [7] = 'lua', [13] = 'lua' } }

    keymaps.setup({
      handlers = handlers,
      register_on_attach = function(callback)
        callbacks.attach = callback
      end,
      get_client_by_id = function(id)
        h.equal(id, 99)
        return client
      end,
      apply = function(_, buffer)
        applied[#applied + 1] = buffer
      end,
    })

    callbacks.attach(client, 5)
    h.deep_equal(applied, { 5 })
    local result = handlers['client/registerCapability'](nil, {}, { client_id = 99 })
    table.sort(applied)
    h.equal(result, 'registered')
    h.equal(callbacks.original, 1)
    h.deep_equal(applied, { 5, 7, 13 })
  end)

  h.it('honors client-name filters registered through util.lsp.on_attach', function()
    local previous_util = package.loaded.util
    local previous_autocmd = vim.api.nvim_create_autocmd
    local previous_get_client = vim.lsp.get_client_by_id
    package.loaded.util = {}
    package.loaded['util.lsp'] = nil

    local callback
    vim.api.nvim_create_autocmd = function(_, opts)
      callback = opts.callback
      return 1
    end
    vim.lsp.get_client_by_id = function(id)
      return { id = id, name = id == 1 and 'vtsls' or 'gopls' }
    end

    local calls = {}
    require('util.lsp').on_attach(function(client, buffer)
      calls[#calls + 1] = { client.name, buffer }
    end, 'vtsls')
    callback({ buf = 8, data = { client_id = 2 } })
    callback({ buf = 9, data = { client_id = 1 } })

    vim.api.nvim_create_autocmd = previous_autocmd
    vim.lsp.get_client_by_id = previous_get_client
    package.loaded['util.lsp'] = nil
    package.loaded.util = previous_util

    h.deep_equal(calls, { { 'vtsls', 9 } })
  end)

  h.it('passes the vtsls position encoding to position params', function()
    local previous_util = package.loaded.util
    local previous_make_position_params = vim.lsp.util.make_position_params
    local seen
    local executed
    package.loaded.util = {
      lsp = {
        action = setmetatable({}, { __index = function() return function() end end }),
        execute = function(command) executed = command end,
        get_clients = function()
          return { { name = 'vtsls', offset_encoding = 'utf-8' } }
        end,
        on_attach = function() end,
      },
      get_pkg_path = function() return '/tmp/js-debug' end,
    }
    vim.lsp.util.make_position_params = function(win, encoding)
      seen = { win, encoding }
      return { textDocument = { uri = 'file:///tmp/test.ts' }, position = { line = 0, character = 0 } }
    end

    package.loaded['plugins.lsp.lang.typescript'] = nil
    local opts = lsp_opts and lsp_opts('plugins.lsp.lang.typescript')
    if not opts then
      for _, spec in ipairs(require('plugins.lsp.lang.typescript')) do
        if spec[1] == 'neovim/nvim-lspconfig' then opts = spec.opts end
      end
    end
    local mapping
    for _, key in ipairs(opts.servers.vtsls.keys) do
      if key[1] == 'gD' then mapping = key end
    end
    mapping[2]()

    vim.lsp.util.make_position_params = previous_make_position_params
    package.loaded.util = previous_util
    package.loaded['plugins.lsp.lang.typescript'] = nil

    h.deep_equal(seen, { 0, 'utf-8' })
    h.equal(executed.command, 'typescript.goToSourceDefinition')
  end)
end)
