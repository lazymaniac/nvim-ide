return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        'elixir-ls',
      })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        'elixir',
        'heex',
        'eex',
      })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        elixirls = {},
      },
    },
  },

  {
    'elixir-tools/elixir-tools.nvim',
    branch = 'main',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local elixir = require 'elixir'
      local elixirls = require 'elixir.elixirls'
      elixir.setup {
        nextls = { enable = true },
        credo = {},
        elixirls = {
          enable = true,
          settings = elixirls.settings {
            dialyzerEnabled = false,
            enableTestLenses = false,
          },
          on_attach = function(client, bufnr)
            local wk = require 'which-key'
            wk.register({
              ['<leader>cm'] = { ':ElixirFromPipe<cr>', 'From Pipe [cm]' },
              ['<leader>cO'] = { ':ElixirToPipe<cr>', 'To Pipe [co]' },
              ['<leader>ce'] = { ':ElixirExpandMacro<cr>', 'Expand Macro [ce]' },
            }, { mode = 'n', buffer = bufnr })
          end,
        },
      }
    end,
  },

  {
    'nvim-neotest/neotest',
    dependencies = { 'jfpedroza/neotest-elixir' },
    opts = {
      adapters = {
        ['neotest-elixir'] = {},
      },
    },
  },
}
