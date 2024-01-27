return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'hadolint' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'dockerfile' })
      end
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
        keys = {
          { '<leader>fd', '<Cmd>Telescope docker<CR>', desc = 'Docker' },
        },
        config = function()
          ---@diagnostic disable-next-line: undefined-field
          require('telescope').load_extension 'docker'
        end,
      },
    },
  },
}
