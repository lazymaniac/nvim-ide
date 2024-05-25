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
      { '<leader>cf', function() require('conform').format { } end, mode = { 'n', 'v' }, desc = 'Format [cf]' },
    },
    config = function()
      require('conform').setup {
        -- Map of filetype to formatters
        formatters_by_ft = {
          lua = { 'stylua' },
          -- Conform will run multiple formatters sequentially
          go = { 'goimports', 'gofmt' },
          -- Use a sub-list to run only the first available formatter
          javascript = { { 'prettierd', 'prettier' } },
          -- You can use a function here to determine the formatters dynamically
          python = function(bufnr)
            if require('conform').get_formatter_info('ruff_format', bufnr).available then
              return { 'ruff_format' }
            else
              return { 'isort', 'black' }
            end
          end,
          -- Use the "*" filetype to run formatters on all filetypes.
          ['*'] = { 'codespell' },
          -- Use the "_" filetype to run formatters on filetypes that don't
          -- have other formatters configured.
          ['_'] = { 'trim_whitespace' },
        },
        -- If this is set, Conform will run the formatter on save.
        -- It will pass the table to conform.format().
        -- This can also be a function that returns the table.
        format_on_save = {
          -- I recommend these options. See :help conform.format for details.
          lsp_fallback = true,
          timeout_ms = 500,
        },
        -- If this is set, Conform will run the formatter asynchronously after save.
        -- It will pass the table to conform.format().
        -- This can also be a function that returns the table.
        format_after_save = {
          lsp_fallback = true,
        },
        -- Conform will notify you when a formatter errors
        notify_on_error = true,
        -- Custom formatters and overrides for built-in formatters
        formatters = {},
      }
    end,
  },
}
