return {

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'angular' })
      end
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        angularls = {
          on_attach = function(client, bufnr)
            local wk = require 'which-key'
            wk.register({
              ['<leader>ct'] = { '<cmd>lua require("ng").goto_template_for_component()<cr>', 'Goto Template (Angular)' },
              ['<leader>cc'] = { '<cmd>lua require("ng").goto_component_with_template_file()<cr>', 'Goto Component (Angular)' },
              ['<leader>cb'] = { '<cmd>lua require("ng").get_template_tcb()<cr>', 'Goto Type Check Block (Angular)' },
            }, { mode = 'n', buffer = bufnr })
          end,
        },
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
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        angular = { 'djlint' },
      },
    },
  },

  {
    'joeveiga/ng.nvim',
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
