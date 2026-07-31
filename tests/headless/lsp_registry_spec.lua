local h = require('tests.headless.harness')

local function load_registry()
  package.loaded['plugins.lsp.registry'] = nil
  local ok, registry = pcall(require, 'plugins.lsp.registry')
  h.truthy(ok, registry)
  return registry
end

local function lsp_opts(module)
  package.loaded[module] = nil
  for _, spec in ipairs(require(module)) do
    if spec[1] == 'neovim/nvim-lspconfig' then
      return spec.opts, spec
    end
  end
end

h.describe('LSP registry', function()
  h.it('composes every centrally owned server once', function()
    local registry = load_registry()
    local configured = {}
    local enabled = {}
    local hook_calls = {}

    registry.setup({
      capabilities = {
        workspace = { configuration = true },
      },
      defaults = {
        flags = { debounce_text_changes = 150 },
        settings = { telemetry = { enabled = false } },
      },
      servers = {
        gopls = {
          keys = { { '<leader>td', '<cmd>GoDebug<cr>' } },
          settings = { gopls = { gofumpt = true, staticcheck = true } },
        },
        clangd = {
          cmd = { 'clangd', '--background-index' },
          capabilities = { offsetEncoding = { 'utf-16' } },
        },
        vtsls = {
          settings = { typescript = { suggest = { completeFunctionCalls = true } } },
        },
        hls = {
          managed = false,
          owner = 'haskell-tools',
        },
        disabled = {
          enabled = false,
        },
      },
      setup = {
        ['*'] = function(server, config)
          hook_calls['*:' .. server] = (hook_calls['*:' .. server] or 0) + 1
          config.flags = vim.tbl_deep_extend('force', config.flags or {}, { allow_incremental_sync = true })
        end,
        gopls = function(server, config)
          hook_calls[server] = (hook_calls[server] or 0) + 1
          config.settings.gopls.completeUnimported = true
        end,
      },
    }, {
      protocol_capabilities = function()
        return { textDocument = { hover = { contentFormat = { 'markdown' } } } }
      end,
      blink_capabilities = function(capabilities)
        capabilities.textDocument.completion = { completionItem = { snippetSupport = true } }
        return capabilities
      end,
      config = function(server, config)
        configured[server] = configured[server] or {}
        configured[server][#configured[server] + 1] = vim.deepcopy(config)
      end,
      enable = function(server)
        enabled[server] = (enabled[server] or 0) + 1
      end,
    })

    h.equal(#configured.gopls, 1)
    h.equal(#configured.clangd, 1)
    h.equal(#configured.vtsls, 1)
    h.falsy(configured.hls, 'externally owned HLS must not be registered centrally')
    h.falsy(configured.disabled, 'disabled servers must not be registered')
    h.equal(enabled.gopls, 1)
    h.equal(enabled.clangd, 1)
    h.equal(enabled.vtsls, 1)
    h.falsy(enabled.hls)

    local gopls = configured.gopls[1]
    h.truthy(gopls.settings.gopls.gofumpt)
    h.truthy(gopls.settings.gopls.staticcheck)
    h.truthy(gopls.settings.gopls.completeUnimported)
    h.falsy(gopls.settings.telemetry.enabled)
    h.truthy(gopls.capabilities.workspace.configuration)
    h.truthy(gopls.capabilities.textDocument.completion.completionItem.snippetSupport)
    h.deep_equal(configured.clangd[1].capabilities.offsetEncoding, { 'utf-16' })
    h.truthy(configured.vtsls[1].settings.typescript.suggest.completeFunctionCalls)
    h.equal(hook_calls.gopls, 1)
    h.equal(hook_calls['*:gopls'], 1)
    h.equal(hook_calls['*:clangd'], 1)
    h.equal(hook_calls['*:vtsls'], 1)

    for _, config in pairs({ gopls, configured.clangd[1], configured.vtsls[1] }) do
      h.falsy(config.keys, 'key metadata must not reach vim.lsp.config')
      h.falsy(config.enabled, 'enable metadata must not reach vim.lsp.config')
      h.falsy(config.managed, 'ownership metadata must not reach vim.lsp.config')
      h.falsy(config.owner, 'ownership metadata must not reach vim.lsp.config')
    end
  end)

  h.it('keeps Angular roots specific to Angular workspaces', function()
    local opts = lsp_opts('plugins.lsp.lang.angular')
    h.truthy(opts and opts.servers and opts.servers.angularls)
    local markers = opts.servers.angularls.root_markers
    h.truthy(vim.tbl_contains(markers, 'angular.json'))
    h.truthy(vim.tbl_contains(markers, 'nx.json'))
    h.falsy(vim.tbl_contains(markers, 'package.json'))
  end)

  h.it('materializes YAML schemas before server registration', function()
    local schemas = { ['https://example.test/schema.json'] = 'example.yaml' }
    local previous = package.loaded.schemastore
    package.loaded.schemastore = {
      yaml = { schemas = function() return schemas end },
    }

    local opts = lsp_opts('plugins.lsp.lang.yaml')
    local target = { servers = {} }
    if type(opts) == 'function' then
      opts(nil, target)
    else
      target = opts
    end
    package.loaded.schemastore = previous

    local yamlls = target.servers and target.servers.yamlls
    h.truthy(yamlls)
    h.deep_equal(yamlls.settings.yaml.schemas, schemas)
    h.falsy(yamlls.on_new_config, 'native vim.lsp.config must receive materialized schemas')
  end)

  h.it('marks HLS as owned by haskell-tools', function()
    local opts = lsp_opts('plugins.lsp.lang.haskell')
    local hls = opts and opts.servers and opts.servers.hls
    h.truthy(hls)
    h.falsy(hls.managed)
    h.equal(hls.owner, 'haskell-tools')
  end)

  h.it('loads and configures clangd extensions from the clangd hook', function()
    local extension_config
    local previous = package.loaded.clangd_extensions
    package.loaded.clangd_extensions = {
      setup = function(config)
        extension_config = config
      end,
    }

    local opts = lsp_opts('plugins.lsp.lang.clangd')
    local server = vim.deepcopy(opts.servers.clangd)
    opts.setup.clangd('clangd', server)
    package.loaded.clangd_extensions = previous

    h.truthy(extension_config.ast)
    h.truthy(extension_config.memory_usage)
    h.truthy(extension_config.symbol_info)
    h.falsy(extension_config.server, 'clangd_extensions no longer owns the server configuration')

    package.loaded['plugins.lsp.lang.clangd'] = nil
    local specs = require('plugins.lsp.lang.clangd')
    local extension_spec
    for _, spec in ipairs(specs) do
      if spec[1] == 'p00f/clangd_extensions.nvim' then
        extension_spec = spec
      end
    end
    h.truthy(extension_spec)
    h.truthy(extension_spec.ft or extension_spec.event or extension_spec.cmd or extension_spec.keys)
  end)
end)
