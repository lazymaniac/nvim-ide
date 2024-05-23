vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'hcl', 'terraform' },
  desc = 'terraform/hcl commentstring configuration',
  command = 'setlocal commentstring=#\\ %s',
})

return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'tfsec', 'trivy' })
    end,
  },

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
        terraform = { 'tfsec', 'trivy' },
        tf = { 'tfsec', 'trivy' },
      },
    },
  },

  -- [telescope-terraform-doc] - Telescope picker for Terraform docs.
  -- see: `:h telescope-terraform-doc`
  -- link: https://github.com/ANGkeith/telescope-terraform-doc.nvim
  {
    'ANGkeith/telescope-terraform-doc.nvim',
    branch = 'main',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'terraform_doc'
    end,
  },

  -- [telescope-terraform] - Privdes info about terraform workspace.
  -- see: `:h telescope-terraform`
  -- link: https://github.com/cappyzawa/telescope-terraform.nvim
  {
    'cappyzawa/telescope-terraform.nvim',
    branch = 'main',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'terraform'
    end,
  },
}
