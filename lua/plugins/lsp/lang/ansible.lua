return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'yaml' })
      end
    end,
  },

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'ansible-lint' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        ansiblels = {},
      },
    },
  },

  {
    'mfussenegger/nvim-ansible',
    branch = 'main',
    keys = {
      {
        '<leader>cR',
        function()
          require('ansible').run()
        end,
        silent = true,
      },
    },
  },
}
