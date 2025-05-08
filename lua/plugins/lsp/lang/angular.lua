return {

  {
    'mason-org/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'djlint' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'angular', 'scss' })
      end
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
        pattern = { '*.component.html', '*.container.html' },
        callback = function()
          vim.treesitter.start(nil, 'angular')
        end,
      })
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
            wk.add {
              { '<leader>ct', '<cmd>lua require("ng").goto_template_for_component()<cr>', desc = 'Goto Template [ct]', mode = 'n', buffer = bufnr },
              { '<leader>cc', '<cmd>lua require("ng").goto_component_with_template_file()<cr>', desc = 'Goto Component [cc]', mode = 'n', buffer = bufnr },
              { '<leader>cb', '<cmd>lua require("ng").get_template_tcb()<cr>', desc = 'Goto Type Check Block [cb]', mode = 'n', buffer = bufnr },
            }
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
