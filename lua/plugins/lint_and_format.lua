return {

  -- [mason-bridge.nvim] - Automatically add and configure linter and formatter installed by Mason.
  -- see: `:h mason-bridge.nvim`
  -- link: https://github.com/frostplexx/mason-bridge.nvim
  {
    'frostplexx/mason-bridge.nvim',
    branch = 'main',
    dependencies = {
      'williamboman/mason.nvim',
    },
  },

  -- [[ LINTING ]] ---------------------------------------------------------------

  -- [nvim-lint] - Code linting in real-time
  -- see: `:h nvim-lint`
  -- link: https://github.com/mfussenegger/nvim-lint
  {
    'mfussenegger/nvim-lint',
    branch = 'master',
    event = 'VeryLazy',
    dependencies = {
      'frostplexx/mason-bridge.nvim',
    },
    opts = {
      -- Event to trigger linters
      linters_by_ft = {
        fish = { 'fish' },
        -- Use the "*" filetype to run linters on all filetypes.
        -- ['*'] = { 'typos' },
        -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
        -- ['_'] = { 'fallback linter' },
      },
    },
    config = function()
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
        callback = function()
          require('lint').try_lint()
        end,
      })
    end,
  },

  -- [[ FORMATTING ]] ---------------------------------------------------------------

  -- [conform.nvim] - Code formatting.
  -- see: `:h conform`
  -- link: https://github.com/stevearc/conform.nvim
  {
    'stevearc/conform.nvim',
    branch = 'master',
    event = 'VeryLazy',
    dependencies = { 'williamboman/mason.nvim', 'frostplexx/mason-bridge.nvim' },
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
    config = function() end,
  },
}
