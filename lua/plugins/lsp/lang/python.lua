return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'black', 'ruff', 'pydocstyle', 'pylama', 'pylint' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'ninja', 'python', 'rst', 'toml' })
      end
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        python = { 'black' },
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        python = { 'ruff', 'pydocstyle', 'pylama', 'pylint' },
      },
    },
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                diagnosticSeverityOverrides = {
                  reportUnusedExpression = 'none',
                },
              },
            },
          },
        },
        ruff_lsp = {
          keys = {
            {
              '<leader>cz',
              function()
                vim.lsp.buf.code_action {
                  apply = true,
                  context = {
                    only = { 'source.organizeImports' },
                    diagnostics = {},
                  },
                }
              end,
              desc = 'Organize Imports [co]',
            },
          },
        },
      },
      setup = {
        ruff_lsp = function()
          require('util').lsp.on_attach(function(client, _)
            if client.name == 'ruff_lsp' then
              -- Disable hover in favor of Pyright
              client.server_capabilities.hoverProvider = false
            end
          end)
        end,
      },
    },
  },

  {
    'nvim-neotest/neotest',
    dependencies = { 'nvim-neotest/neotest-python' },
  },

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'mfussenegger/nvim-dap-python',
      -- stylua: ignore
      keys = {
        { "<leader>dM", function() require('dap-python').test_method() end, desc = "Debug Method [dM]", ft = "python" },
        { "<leader>dS", function() require('dap-python').test_class() end, desc = "Debug Class [dS]", ft = "python" },
      },
      config = function()
        local path = require('mason-registry').get_package('debugpy'):get_install_path()
        require('dap-python').setup(path .. '/venv/bin/python')
      end,
    },
  },

  {
    'linux-cultist/venv-selector.nvim',
    cmd = 'VenvSelect',
    keys = { { '<leader>cv', '<cmd>:VenvSelect<cr>', desc = 'Select VirtualEnv [cv]' } },
    opts = function(_, opts)
      if require('util').has 'nvim-dap-python' then
        opts.dap_enabled = true
      end
      return vim.tbl_deep_extend('force', opts, {
        name = {
          'venv',
          '.venv',
          'env',
          '.env',
        },
      })
    end,
  },
}
