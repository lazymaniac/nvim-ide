return {

  -- [conform.nvim] - Code formatting.
  -- see: `:h conform`
  -- link: https://github.com/stevearc/conform.nvim
  'stevearc/conform.nvim',
  branch = 'master',
  event = 'VeryLazy',
  dependencies = { 'williamboman/mason.nvim' },
  cmd = 'ConformInfo',
    -- stylua: ignore
    keys = {
      { '<leader>cF', function() require('conform').format { formatters = { 'injected' } } end, mode = { 'n', 'v' }, desc = 'Format Injected Langs [cF]' },
    },
  opts = function()
    local opts = {
      format = {
        timeout_ms = 3000,
        async = false, -- not recommended to change
        quiet = false, -- not recommended to change
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        sh = { 'shfmt' },
      },
      -- The options you set here will be merged with the builtin formatters.
      -- You can also define any custom formatters here.
      formatters = {
        injected = { options = { ignore_errors = true } },
      },
    }
    return opts
  end,
  config = function()
  end,
}
