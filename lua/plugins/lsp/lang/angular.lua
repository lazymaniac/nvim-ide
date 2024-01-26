return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        angularls = {},
      },
    },
  },

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'djlint' })
    end,
  },

  {
    'nvimtools/none-ls.nvim',
    opts = function(_, opts)
      local nls = require 'null-ls'
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.diagnostics.djlint,
      })
    end,
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        angular = { 'djlint' },
      },
    },
  },

  {
    'joeveiga/ng.nvim',
    keys = {
      {
        '<leader>ct',
        '<cmd>lua require("ng").goto_template_for_component()<cr>',
        mode = { 'n' },
        desc = 'Goto Template (Angular)',
      },
      {
        '<leader>cc',
        '<cmd>lua require("ng").goto_component_with_template_file()<cr>',
        mode = { 'n', 'v' },
        desc = 'Goto Component (Angular)',
      },
      {
        '<leader>cb',
        '<cmd>lua require("ng").get_template_tcb()<cr>',
        mode = { 'n', 'v' },
        desc = 'Goto Type Check Block (Angular)',
      },
    },
  },
  
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      'johnpapa/vscode-angular-snippets',
      config = function()
        require('luasnip.loaders.from_vscode').lazy_load()
      end,
    },
  },
}
