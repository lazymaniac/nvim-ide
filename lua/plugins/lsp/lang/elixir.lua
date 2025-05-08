return {

  {
    'mason-org/mason.nvim',
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

  -- [elixir-tools] - Improves experience with Elixir in neovim.
  -- see: `:h elixir-tools`
  -- link: https://github.com/elixir-tools/elixir-tools.nvim
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
          on_attach = function(_, bufnr)
            local wk = require 'which-key'
            wk.add {
              { '<leader>cm', ':ElixirFromPipe<cr>', desc = 'From Pipe [cm]', mode = 'n', buffer = bufnr },
              { '<leader>cO', ':ElixirToPipe<cr>', desc = 'To Pipe [co]', mode = 'n', buffer = bufnr },
              { '<leader>ce', ':ElixirExpandMacro<cr>', desc = 'Expand Macro [ce]', mode = 'n', buffer = bufnr },
            }
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
