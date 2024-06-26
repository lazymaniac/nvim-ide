return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'djlint' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'angular' })
      end
    end,
  },

  -- [ng.nvim] - Adds extra command to native lsp.
  -- see: `:h ng,nvim`
  -- link: https://github.com/joeveiga/ng.nvim
  {
    'joeveiga/ng.nvim',
    event = 'VeryLazy',
    branch = 'main',
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        angularls = {
          on_attach = function(client, bufnr)
            local wk = require 'which-key'
            wk.register({
              ['<leader>ct'] = { '<cmd>lua require("ng").goto_template_for_component()<cr>', 'Goto Template [ct]' },
              ['<leader>cc'] = { '<cmd>lua require("ng").goto_component_with_template_file()<cr>', 'Goto Component [cc]' },
              ['<leader>cb'] = { '<cmd>lua require("ng").get_template_tcb()<cr>', 'Goto Type Check Block [cb]' },
            }, { mode = 'n', buffer = bufnr })
          end,
        },
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
