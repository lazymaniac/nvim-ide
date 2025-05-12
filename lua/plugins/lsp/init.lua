local Util = require 'util'

local function ensure_installed(packages)
  for _, package in ipairs(packages) do
    if not require('mason-registry').is_installed(package) then
      vim.cmd('MasonInstall ' .. package)
    end
  end
end

local packages = {
  'stylua', -- lua
  'hadolint', -- docker
  'djlint', -- angular, go
  'ansible-lint', -- ansible
  'cmakelint', -- cmake
  'cmakelang',
  'codelldb', -- rust, c
  'shellcheck', -- bash
  'shellharden',
  'beautysh',
  'bash-debug-adapter',
  'goimports', -- go
  'gofumpt',
  'staticcheck',
  'trivy',
  'delve',
  'haskell-debug-adapter', -- haskell
  'hlint',
  'prettierd', -- html
  'htmlhint',
  'stylelint',
  'eslint_d',
  'java-debug-adapter', -- java
  'checkstyle',
  'java-test',
  'vscode-java-decompiler',
  'jq', -- json
  'jsonlint',
  'prettierd',
  'ktlint', -- kotlin
  'kotlin-debug-adapter',
  'markdown-toc', -- markdown
  'markdownlint',
  'write-good',
  'black', -- python
  'pydocstyle',
  'pylint',
  'docformatter',
  'debugpy',
  'erb-formatter', -- ruby
  'erb-lint',
  'rubocop',
  'sqlfmt', -- sql
  'sqlfluff',
  'sqruff',
  'tfsec', -- terraform
  'trivy',
  'chrome-debug-adapter', -- typescript
  'firefox-debug-adapter',
  'js-debug-adapter',
  'node-debug2-adapter',
  'eslint_d',
  'yamllint', -- yaml
  'prettierd',
  'sonarlint-language-server',
  'clj-kondo',
  'golangci-lint',
  'kube-linter',
  'detekt',
  'luacheck',
  'selene',
  'actionlint',
  'xmlformatter',
}

return {
  --
  -- [mason.nvim] - LSP, formatter, dap, test tools installer
  -- see: `:h mason.nvim`
  -- link: https://github.com/mason-org/mason.nvim
  {
    'mason-org/mason.nvim',
    branch = 'main',
    event = 'VeryLazy',
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
      ensure_installed(packages)
    end,
  },

  {
    'mason-org/mason-lspconfig.nvim',
    branch = 'main',
    opts = {
      ensure_installed = {
        'lua_ls',
        'clangd',
        'angularls',
        'ansiblels',
        'bashls',
        'clojure_lsp',
        'cmake',
        'cucumber_language_server',
        'dockerls',
        'docker_compose_language_service',
        'elixirls',
        'gopls',
        'gradle_ls',
        'groovyls',
        'hls',
        'yamlls',
        'helm_ls',
        'html',
        'emmet_ls',
        'cssls',
        'jdtls',
        'jsonls',
        'julials',
        'kotlin_language_server',
        'marksman',
        'puppet',
        'pyright',
        'ruby_lsp',
        'rubocop',
        'rust_analyzer',
        'taplo',
        'sqls',
        'svelte',
        'terraformls',
        'vtsls',
        'ts_ls',
        'volar',
      },
      automatic_enable = {
        exclude = { 'rust_analyzer', 'jdtls' },
      },
    },
  },

  -- [nvim-lspconfig] - LSP integration config.
  -- see: `:h nvim-lspconfig`
  -- link: https://github.com/neovim/nvim-lspconfig
  {
    'neovim/nvim-lspconfig',
    event = 'VeryLazy',
    config = function(_, opts)
      -- setup keymaps
      Util.lsp.on_attach(function(client, buffer)
        require('plugins.lsp.keymaps').on_attach(client, buffer)
      end)
      local register_capability = vim.lsp.handlers['client/registerCapability']
      vim.lsp.handlers['client/registerCapability'] = function(err, res, ctx)
        local ret = register_capability(err, res, ctx)
        local client_id = ctx.client_id
        local client = vim.lsp.get_client_by_id(client_id)
        local buffer = vim.api.nvim_get_current_buf()
        require('plugins.lsp.keymaps').on_attach(client, buffer)
        return ret
      end
      -- diagnostics
      for name, icon in pairs(require('config').icons.diagnostics) do
        name = 'DiagnosticSign' .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = '' })
      end
      Util.toggle.inlay_hints()

      vim.lsp.config('lua_ls', {
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
              path = {
                'lua/?.lua',
                'lua/?/init.lua',
              },
            },
            -- Make the server aware of Neovim runtime files
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
        settings = {
          Lua = {},
        },
      })

      vim.lsp.config('angularls', {
        filetypes = {
          'html',
          'typescript',
          'typescriptreact',
          'typescript.tsx',
          'javascript',
          'javascriptreact',
          'javascript.jsx',
        },
        root_markers = { 'angular.json', 'package.json', 'nx.json' },
      })
    end,
  },
}
