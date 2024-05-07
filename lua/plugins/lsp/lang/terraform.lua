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
      vim.list_extend(opts.ensure_installed, { 'tfsec', 'trivy', 'terraform_validate' })
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
    'stevearc/conform.nvim',
    optional = true,
    opts = {
      formatters_by_ft = {
        terraform = { 'terraform_fmt' },
        tf = { 'terraform_fmt' },
        ['terraform-vars'] = { 'terraform_fmt' },
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    optional = true,
    opts = {
      linters_by_ft = {
        terraform = { 'terraform_validate' },
        tf = { 'terraform_validate' },
      },
    },
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

  {
    'ANGkeith/telescope-terraform-doc.nvim',
    branch = 'main',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'terraform_doc'
    end,
  },

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
