return {

  -- KOTLIN
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'kotlin' })
      end
    end,
  },

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        'ktlint',
        'kotlin-debug-adapter',
        'detekt',
      })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        kotlin = { 'ktlint' },
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        kotlin = { 'ktlint', 'detekt' },
      },
    },
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        kotlin_language_server = {},
      },
    },
  },

  {
    'mfussenegger/nvim-dap',
    opts = {
      setup = {
        kotlin_debug_adapter = function()
          local dap = require 'dap'

          -- Configuration
          dap.configurations.kotlin = {
            {
              type = 'kotlin',
              name = 'launch - kotlin',
              request = 'launch',
              projectRoot = vim.fn.getcwd() .. '/app',
              mainClass = function()
                return vim.fn.input('Path to main class > ', '', 'file')
                -- return vim.fn.input("Path to main class > ", "myapp.sample.app.AppKt", "file")
              end,
            },
            {
              type = 'kotlin',
              name = 'attach - kotlin',
              request = 'attach',
              projectRoot = vim.fn.getcwd() .. '/app',
              hostName = 'localhost',
              port = 5005,
              timeout = 1000,
            },
          }
        end,
      },
    },
  },
}
