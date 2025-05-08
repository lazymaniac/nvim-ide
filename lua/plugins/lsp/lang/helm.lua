return {

  -- [vim-helm] - Syntax for HELM templates.
  -- see: `:h vim-helm`
  -- link: https://github.com/towolf/vim-helm
  {
    'towolf/vim-helm',
    branch = 'master',
    ft = 'helm',
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = { ensure_installed = { 'helm' } },
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
    'mason-org/mason.nvim',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        'helm-ls',
      })
    end,
  },
}
