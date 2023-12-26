return {
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
    'williamboman/mason.nvim',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        'elixir-ls',
      })
    end,
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'jfpedroza/neotest-elixir',
    },
    opts = {
      adapters = {
        ['neotest-elixir'] = {},
      },
    },
  },
  {
    'nvimtools/none-ls.nvim',
    opts = function(_, opts)
      if vim.fn.executable 'credo' == 0 then
        return
      end
      local nls = require 'null-ls'
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.diagnostics.credo,
      })
    end,
  },
  {
    'mfussenegger/nvim-lint',
    opts = function(_, opts)
      if vim.fn.executable 'credo' == 0 then
        return
      end
      opts.linters_by_ft = {
        elixir = { 'credo' },
      }
    end,
  },
}
