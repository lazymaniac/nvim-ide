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

local function composed_opts(modules)
  local result = {}
  for _, module in ipairs(modules) do
    local opts = lsp_opts(module)
    if type(opts) == 'function' then
      opts(nil, result)
    else
      result = vim.tbl_deep_extend('force', result, vim.deepcopy(opts or {}))
    end
  end
  return result
end

local NIL = {}

local function with_restored_modules(modules, body)
  local previous = {}
  for _, module in ipairs(modules) do
    previous[module] = package.loaded[module] == nil and NIL or package.loaded[module]
  end
  local ok, result = xpcall(body, debug.traceback)
  for _, module in ipairs(modules) do
    package.loaded[module] = previous[module] == NIL and nil or previous[module]
  end
  if not ok then error(result, 0) end
  return result
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
        claimed = {},
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
        claimed = function()
          hook_calls.claimed = (hook_calls.claimed or 0) + 1
          return true
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
    h.falsy(configured.claimed, 'a setup hook returning true owns registration')
    h.equal(enabled.gopls, 1)
    h.equal(enabled.clangd, 1)
    h.equal(enabled.vtsls, 1)
    h.falsy(enabled.hls)
    h.falsy(enabled.claimed)
    h.equal(hook_calls.claimed, 1)

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

  h.it('registers effective options composed from the real language modules', function()
    local configured = {}
    local enabled = {}
    local extension_calls = 0
    local modules = {
      'util',
      'clangd_extensions',
      'plugins.lsp',
      'plugins.lsp.lang.go',
      'plugins.lsp.lang.clangd',
      'plugins.lsp.lang.typescript',
      'plugins.lsp.lang.haskell',
    }
    with_restored_modules(modules, function()
      package.loaded.util = {
        lsp = {
          action = setmetatable({}, { __index = function() return function() end end }),
          execute = function() end,
          get_clients = function() return {} end,
          on_attach = function() end,
        },
        get_pkg_path = function() return '/tmp/mason-package' end,
        toggle = { inlay_hints = function() end },
      }
      package.loaded.clangd_extensions = {
        setup = function()
          extension_calls = extension_calls + 1
        end,
      }
      local opts = composed_opts {
        'plugins.lsp',
        'plugins.lsp.lang.go',
        'plugins.lsp.lang.clangd',
        'plugins.lsp.lang.typescript',
        'plugins.lsp.lang.haskell',
      }

      load_registry().setup(opts, {
        protocol_capabilities = function() return {} end,
        blink_capabilities = function(capabilities) return capabilities end,
        config = function(server, config)
          h.falsy(configured[server], server .. ' configured more than once')
          configured[server] = vim.deepcopy(config)
        end,
        enable = function(server)
          enabled[server] = (enabled[server] or 0) + 1
        end,
      })
    end)

    h.truthy(configured.gopls.settings.gopls.gofumpt)
    h.truthy(configured.gopls.settings.gopls.codelenses.run_govulncheck)
    h.truthy(configured.gopls.settings.gopls.analyses.nilness)
    h.truthy(vim.tbl_contains(configured.clangd.cmd, '--background-index'))
    h.truthy(vim.tbl_contains(configured.clangd.cmd, '--clang-tidy'))
    h.truthy(configured.clangd.init_options.usePlaceholders)
    h.truthy(configured.vtsls.settings.vtsls.autoUseWorkspaceTsdk)
    h.truthy(configured.vtsls.settings.vtsls.experimental.completion.enableServerSideFuzzyMatch)
    h.truthy(configured.vtsls.settings.typescript.suggest.completeFunctionCalls)
    h.truthy(configured.vtsls.settings.javascript.suggest.completeFunctionCalls)
    h.equal(enabled.gopls, 1)
    h.equal(enabled.clangd, 1)
    h.equal(enabled.vtsls, 1)
    h.equal(extension_calls, 1)

    for _, external in ipairs { 'hls', 'jdtls', 'rust_analyzer' } do
      h.falsy(configured[external], external .. ' must remain externally owned')
      h.falsy(enabled[external], external .. ' must never be centrally enabled')
    end
  end)

  h.it('invokes vtsls request methods with the client as self', function()
    local attached
    local modules = { 'util', 'plugins.lsp.lang.typescript' }
    with_restored_modules(modules, function()
      package.loaded.util = {
        lsp = {
          action = setmetatable({}, { __index = function() return function() end end }),
          execute = function() end,
          on_attach = function(callback) attached = callback end,
        },
        get_pkg_path = function() return '/tmp/mason-package' end,
      }
      local opts = lsp_opts('plugins.lsp.lang.typescript')
      opts.setup.vtsls('vtsls', vim.deepcopy(opts.servers.vtsls))

      local client = { commands = {} }
      local calls = {}
      client.request = function(self, method, params, callback)
        h.equal(self, client)
        calls[#calls + 1] = { method, params.command }
        if callback then callback(nil, { body = { files = { '/tmp/target.ts' } } }) end
      end
      attached(client, 1)

      local previous_select = vim.ui.select
      local ok, err = xpcall(function()
        vim.ui.select = function(_, _, callback) callback('/tmp/target.ts') end
        client.commands['_typescript.moveToFileRefactoring']({
          command = 'typescript.moveToFile',
          arguments = {
            'move',
            vim.uri_from_fname('/tmp/source.ts'),
            { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 1 } },
          },
        })
      end, debug.traceback)
      vim.ui.select = previous_select
      if not ok then error(err, 0) end

      h.deep_equal(calls, {
        { 'workspace/executeCommand', 'typescript.tsserverRequest' },
        { 'workspace/executeCommand', 'typescript.moveToFile' },
      })
    end)
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

  h.it('declares clangd roots through the native Neovim 0.12 contract', function()
    local opts = lsp_opts('plugins.lsp.lang.clangd')
    local clangd = opts.servers.clangd
    h.falsy(clangd.root_dir, 'a legacy return-value root callback prevents native LSP startup')
    h.deep_equal(clangd.root_markers, {
      {
        'Makefile',
        'configure.ac',
        'configure.in',
        'config.h.in',
        'meson.build',
        'meson_options.txt',
        'build.ninja',
      },
      { 'compile_commands.json', 'compile_flags.txt' },
    })
  end)
end)
