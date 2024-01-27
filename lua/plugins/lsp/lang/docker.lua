return {

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'dockerfile' })
      end
    end,
  },

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'hadolint' })
    end,
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        dockerfile = { 'hadolint' },
      },
    },
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        dockerls = {},
        docker_compose_language_service = {},
      },
    },
  },

  {
    'telescope.nvim',
    dependencies = {
      {
        'lpoto/telescope-docker.nvim',
        opts = {},
        config = function(_, opts)
          require('telescope').load_extension 'docker'
        end,
        keys = {
          { '<leader>fd', '<Cmd>Telescope docker<CR>', desc = 'Docker' },
        },
      },
    },
  },
}
