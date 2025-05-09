return {
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
        ruby = { 'robocop' },
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
