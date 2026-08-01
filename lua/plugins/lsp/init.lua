local Util = require 'util'

return {
  --
  -- [mason.nvim] - LSP, formatter, dap, test tools installer
  -- see: `:h mason.nvim`
  -- link: https://github.com/mason-org/mason.nvim
  {
    'mason-org/mason.nvim',
    branch = 'main',
    cmd = 'Mason',
    build = ':MasonUpdate',
    opts = {
      registries = {
        'github:mason-org/mason-registry',
      },
      providers = {
        'mason.providers.registry-api',
        'mason.providers.client',
      },
      ui = {
        check_outdated_packages_on_open = true,
        border = nil,
        backdrop = 60,
        width = 0.8,
        height = 0.9,
        icons = {
          package_installed = '✓',
          package_pending = '➜',
          package_uninstalled = '✗',
        },
      },
    },
    config = function(_, opts)
      require('mason').setup(opts)
    end,
  },

  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    branch = 'main',
    lazy = false,
    dependencies = { 'mason-org/mason.nvim' },
    opts = function()
      return require('nv_ide.toolchain.mason').options()
    end,
    config = function(_, opts)
      require('nv_ide.toolchain.mason').setup(opts)
    end,
  },

  {
    'mason-org/mason-lspconfig.nvim',
    branch = 'main',
    event = 'BufReadPre',
    opts = {
      automatic_enable = false,
    },
  },

  -- [nvim-lspconfig] - LSP integration config.
  -- see: `:h nvim-lspconfig`
  -- link: https://github.com/neovim/nvim-lspconfig
  {
    'neovim/nvim-lspconfig',
    event = 'BufReadPre',
    opts = {
      servers = {
        lua_ls = {
          on_init = function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then
                return
              end
            end
            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
              runtime = {
                version = 'LuaJIT',
                path = { 'lua/?.lua', 'lua/?/init.lua' },
              },
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                  '${3rd}/luv/library',
                  '${3rd}/busted/library',
                },
              },
            })
          end,
          settings = { Lua = {} },
        },
        clangd = {},
        angularls = {},
        ansiblels = {},
        bashls = {},
        clojure_lsp = {},
        cmake = {},
        cucumber_language_server = {},
        dockerls = {},
        docker_compose_language_service = {},
        gopls = {},
        gradle_ls = { enabled = false },
        groovyls = { enabled = false },
        hls = {},
        yamlls = {},
        helm_ls = {},
        html = {},
        emmet_ls = {},
        cssls = {},
        jdtls = { managed = false, owner = 'nvim-jdtls' },
        jsonls = {},
        kotlin_language_server = {},
        marksman = {},
        puppet = {},
        pyright = {},
        ruby_lsp = {},
        rubocop = {},
        rust_analyzer = { managed = false, owner = 'rustaceanvim' },
        taplo = {},
        sqls = {},
        svelte = {},
        terraformls = {},
        vtsls = {},
      },
      setup = {},
    },
    config = function(_, opts)
      require('plugins.lsp.keymaps').setup()
      require('plugins.lsp.registry').setup(opts)
      Util.toggle.inlay_hints()
    end,
  },
}
