return {

  {
    'towolf/vim-helm',
    branch = 'master',
    ft = 'helm',
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        yamlls = {},
        helm_ls = {},
      },
    },
  },

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        'helm-ls',
      })
    end,
  },
}
