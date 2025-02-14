local lsp = "ruby_lsp"
local formatter = "rubocop"
return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = { ensure_installed = { 'ruby' } },
  },
  {
    'neovim/nvim-lspconfig',
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        ruby_lsp = {
          enabled = true,
        },
        solargraph = {
          enabled = false,
        },
        rubocop = {
          -- If Solargraph and Rubocop are both enabled as an LSP,
          -- diagnostics will be duplicated because Solargraph
          -- already calls Rubocop if it is installed
          enabled = true,
        },
        standardrb = {
          enabled = false,
        },
      },
    },
  },
  {
    'williamboman/mason.nvim',
    opts = { ensure_installed = { 'erb-formatter', 'erb-lint', 'rubocop', 'ruby-lsp', 'solargraph', 'standardrb' } },
  },
  {
    'mfussenegger/nvim-dap',
    optional = true,
    dependencies = {
      'suketa/nvim-dap-ruby',
      config = function()
        require('dap-ruby').setup()
      end,
    },
  },
  {
    'stevearc/conform.nvim',
    optional = true,
    opts = {
      formatters_by_ft = {
        ruby = { formatter },
        eruby = { 'erb_format' },
      },
    },
  },
  {
    'nvim-neotest/neotest',
    optional = true,
    dependencies = {
      'olimorris/neotest-rspec',
    },
    opts = {
      adapters = {
        ['neotest-rspec'] = {
          -- NOTE: By default neotest-rspec uses the system wide rspec gem instead of the one through bundler
          -- rspec_cmd = function()
          --   return vim.tbl_flatten({
          --     "bundle",
          --     "exec",
          --     "rspec",
          --   })
          -- end,
        },
      },
    },
  },
}
