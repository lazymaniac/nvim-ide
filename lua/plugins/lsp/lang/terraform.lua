vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'hcl', 'terraform' },
  desc = 'terraform/hcl commentstring configuration',
  command = 'setlocal commentstring=#\\ %s',
})

return {
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
