return {

  -- [[ LINTING ]] ---------------------------------------------------------------

  -- [nvim-lint] - Code linting in real-time
  -- see: `:h nvim-lint`
  -- link: https://github.com/mfussenegger/nvim-lint
  {
    'mfussenegger/nvim-lint',
    branch = 'master',
    event = 'VeryLazy',
    config = function()
      require('lint').linters_by_ft = {
        lua = { 'selene' },
        angular = { 'djlint' },
        ansible = { 'ansible-lint' },
        clojure = { 'clj-kondo' },
        cmake = { 'cmakelint' },
        elixir = { 'trivy' },
        go = { 'golangci-lint' },
        haskell = { 'hlint' },
        helm = { 'kube-linter' },
        html = { 'htmlhint' },
        java = { 'checkstyle', 'trivy' },
        kotlin = { 'ktlint', 'detekt' },
        markdown = { 'markdownlint', 'write-good' },
        python = { 'ruff', 'pylint', 'flake8', 'mypy' },
        ruby = { 'erb-lint', 'rubocop', 'trivy' },
        rust = { 'bacon' },
        terraform = { 'tfsec', 'trivy' },
        tf = { 'tfsec', 'trivy' },
        typescript = { 'eslint_d', 'trivy' },
        yaml = { 'yamllint', 'actionlint' },
        -- Use the "*" filetype to run linters on all filetypes.
        -- ['*'] = { 'typos' },
        -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
        -- ['_'] = { 'fallback linter' },
      }
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufEnter' }, {
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
    dependencies = { 'mason-org/mason.nvim', 'frostplexx/mason-bridge.nvim' },
    cmd = 'ConformInfo',
    -- stylua: ignore
    keys = {
      { '<leader>cf', function() require('conform').format { async = true, lsp_fallback = true } end, mode = { 'n', 'v' }, desc = 'Format [cf]' },
      { '<leader>cF', function() require('conform').format { async = true, lsp_fallback = true, formatters = { 'injected' } } end, mode = { 'n', 'v' }, desc = 'Format Injected Langs [cF]' },
    },
    config = function()
      require('conform').setup {
        -- Map of filetype to formatters
        formatters_by_ft = {
          lua = { 'stylua' },
          bash = { 'beautysh', 'shellharden' },
          css = { 'prettierd' },
          flow = { 'prettierd' },
          graphql = { 'prettierd' },
          html = { 'prettierd' },
          python = { 'black', 'docformatter' },
          cmake = { 'cmakelang' },
          angular = { 'djlint', 'prettierd' },
          ruby = { 'erb-formatter', 'rubocop' },
          go = { 'goimports', 'gofumpt' },
          json = { 'jq', 'prettierd' },
          javascript = { 'prettierd' },
          less = { 'prettierd' },
          scss = { 'prettierd' },
          sql = { 'sqlfmt', 'sqruff' },
          typescript = { 'prettierd' },
          vuejs = { 'prettierd' },
          kotlin = { 'ktlint' },
          markdown = { 'prettierd', 'markdownlint', 'markdown-toc' },
          yaml = { 'prettierd', 'actionlint' },
          -- Conform will run multiple formatters sequentially
          -- go = { 'goimports', 'gofmt' },
          -- Use a sub-list to run only the first available formatter
          -- javascript = { { 'prettierd', 'prettier' } },
          -- You can use a function here to determine the formatters dynamically
          -- Use the "*" filetype to run formatters on all filetypes.
          ['*'] = { 'codespell', 'trim_whitespace' },
          -- Use the "_" filetype to run formatters on filetypes that don't
          -- have other formatters configured.
        },
        format_on_save = nil,
        format_after_save = nil,
        notify_on_error = true,
        formatters = {},
      }
    end,
  },
}
