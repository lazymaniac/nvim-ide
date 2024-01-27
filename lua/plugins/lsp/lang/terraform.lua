local Util = require 'util'

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'hcl', 'terraform' },
  desc = 'terraform/hcl commentstring configuration',
  command = 'setlocal commentstring=#\\ %s',
})

return {

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, {
          'terraform',
          'hcl',
        })
      end
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        terraformls = {},
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        terraform = { 'terraform_validate' },
        tf = { 'terraform_validate' },
      },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        terraform = { 'terraform_fmt' },
        tf = { 'terraform_fmt' },
        ['terraform-vars'] = { 'terraform_fmt' },
      },
    },
  },

  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      {
        'ANGkeith/telescope-terraform-doc.nvim',
        config = function()
          Util.on_load('telescope.nvim', function()
            require('telescope').load_extension 'terraform_doc'
          end)
        end,
      },
      {
        'cappyzawa/telescope-terraform.nvim',
        config = function()
          Util.on_load('telescope.nvim', function()
            require('telescope').load_extension 'terraform'
          end)
        end,
      },
    },
  },
}
