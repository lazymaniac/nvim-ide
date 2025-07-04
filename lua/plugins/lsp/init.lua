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
  'js-debug-adapter', -- typrescript, javascript
  'eslint_d',
  'yamllint', -- yaml
  'prettierd',
  'sonarlint-language-server',
  'clj-kondo',
  'golangci-lint',
  'kube-linter',
  'detekt',
  'luacheck',
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
    event = 'BufReadPre',
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
      },
      automatic_enable = {
        exclude = { 'rust_analyzer', 'jdtls', 'groovyls', 'gradle_ls' },
      },
    },
  },

  -- [nvim-lspconfig] - LSP integration config.
  -- see: `:h nvim-lspconfig`
  -- link: https://github.com/neovim/nvim-lspconfig
  {
    'neovim/nvim-lspconfig',
    event = 'BufReadPre',
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
        on_attach = function(_, bufnr)
          local wk = require 'which-key'
          wk.add {
            { '<leader>ct', '<cmd>lua require("ng").goto_template_for_component()<cr>', desc = 'Goto Template [ct]', mode = 'n', buffer = bufnr },
            { '<leader>cc', '<cmd>lua require("ng").goto_component_with_template_file()<cr>', desc = 'Goto Component [cc]', mode = 'n', buffer = bufnr },
            { '<leader>cb', '<cmd>lua require("ng").get_template_tcb()<cr>', desc = 'Goto Type Check Block [cb]', mode = 'n', buffer = bufnr },
          }
        end,
      })

      vim.lsp.config('yamlls', {
        -- Have to add this for yamlls to understand that we support line folding
        capabilities = {
          textDocument = {
            foldingRange = {
              dynamicRegistration = false,
              lineFoldingOnly = true,
            },
          },
        },
        -- lazy-load schemastore when needed
        on_new_config = function(new_config)
          new_config.settings.yaml.schemas = vim.tbl_deep_extend('force', new_config.settings.yaml.schemas or {}, require('schemastore').yaml.schemas())
        end,
        settings = {
          redhat = { telemetry = { enabled = false } },
          yaml = {
            keyOrdering = false,
            format = {
              enable = true,
            },
            validate = true,
            schemaStore = {
              -- Must disable built-in schemaStore support to use
              -- schemas from SchemaStore.nvim plugin
              enable = false,
              -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
              url = '',
            },
          },
        },
      })

      vim.lsp.config('vtsls', {
        -- explicitly add default filetypes, so that we can extend
        -- them in related extras
        filetypes = {
          'javascript',
          'javascriptreact',
          'javascript.jsx',
          'typescript',
          'typescriptreact',
          'typescript.tsx',
        },
        settings = {
          complete_function_calls = true,
          vtsls = {
            enableMoveToFileCodeAction = true,
            autoUseWorkspaceTsdk = true,
            experimental = {
              maxInlayHintLength = 30,
              completion = {
                enableServerSideFuzzyMatch = true,
              },
            },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = 'always' },
            suggest = {
              completeFunctionCalls = true,
            },
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = 'literals' },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
        },
        keys = {
          {
            'gD',
            function()
              local params = vim.lsp.util.make_position_params()
              require('util').lsp.execute {
                command = 'typescript.goToSourceDefinition',
                arguments = { params.textDocument.uri, params.position },
                open = true,
              }
            end,
            desc = 'Goto Source Definition',
          },
          {
            'gR',
            function()
              require('util').lsp.execute {
                command = 'typescript.findAllFileReferences',
                arguments = { vim.uri_from_bufnr(0) },
                open = true,
              }
            end,
            desc = 'File References',
          },
          {
            '<leader>co',
            require('util').lsp.action['source.organizeImports'],
            desc = 'Organize Imports',
          },
          {
            '<leader>cM',
            require('util').lsp.action['source.addMissingImports.ts'],
            desc = 'Add missing imports',
          },
          {
            '<leader>cu',
            require('util').lsp.action['source.removeUnused.ts'],
            desc = 'Remove unused imports',
          },
          {
            '<leader>cD',
            require('util').lsp.action['source.fixAll.ts'],
            desc = 'Fix all diagnostics',
          },
          {
            '<leader>cV',
            function()
              require('util').lsp.execute { command = 'typescript.selectTypeScriptVersion' }
            end,
            desc = 'Select TS workspace version',
          },
        },
      })
    end,
  },
}
