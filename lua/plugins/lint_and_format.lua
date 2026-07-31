return {

  -- [[ LINTING ]] ---------------------------------------------------------------

  -- [nvim-lint] - Code linting in real-time
  -- see: `:h nvim-lint`
  -- link: https://github.com/mfussenegger/nvim-lint
  {
    'mfussenegger/nvim-lint',
    branch = 'master',
    event = 'BufReadPost',
    config = function()
      local lint = require 'lint'

      local function available(names)
        return vim.tbl_filter(function(name)
          return vim.fn.executable(name) == 1
        end, names)
      end

      lint.linters.kube_linter = {
        cmd = 'kube-linter',
        args = { 'lint', '--format', 'plain' },
        append_fname = true,
        stream = 'both',
        ignore_exitcode = true,
        parser = function(output)
          local diagnostics = {}
          for _, line in ipairs(vim.split(output, '\n', { plain = true, trimempty = true })) do
            local filename, message = line:match '^(.-):%s+(.+)$'
            if message and filename ~= 'Error' then
              diagnostics[#diagnostics + 1] = {
                lnum = 0,
                col = 0,
                severity = vim.diagnostic.severity.WARN,
                source = 'kube-linter',
                code = message:match '%(check:%s*([^,%)]+)',
                message = message,
              }
            end
          end
          return diagnostics
        end,
      }

      lint.linters_by_ft = {
        angular = { 'djlint' },
        ansible = { 'ansible_lint' },
        clojure = { 'clj-kondo' },
        cmake = { 'cmakelint' },
        go = { 'golangcilint' },
        haskell = { 'hlint' },
        helm = { 'kube_linter' },
        html = { 'htmlhint' },
        java = { 'trivy' },
        kotlin = { 'ktlint', 'detekt' },
        markdown = { 'markdownlint' },
        python = available { 'ruff', 'pylint', 'flake8', 'mypy' },
        ruby = { 'erb_lint', 'rubocop', 'trivy' },
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
          lint.linters_by_ft.python = available { 'ruff', 'pylint', 'flake8', 'mypy' }
          lint.try_lint()
        end,
      })
    end,
  },

  -- [sonarlint.nvim] - Sonarlint LSP
  -- see: `:h sonarlint.nvim`
  -- link: https://gitlab.com/schrieveslaach/sonarlint.nvim
  {
    'https://gitlab.com/schrieveslaach/sonarlint.nvim',
    ft = { 'java', 'javascript', 'typescript', 'c', 'go', 'kubernetes', 'css', 'docker', 'xml', 'html', 'python' },
    config = function()
      require('sonarlint').setup {
        server = {
          cmd = {
            'sonarlint-language-server',
            '-stdio',
            '-analyzers',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjava.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjs.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarxml.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonargo.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarhtml.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonariac.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjavasymbolicexecution.jar',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarpython.jar',
          },
        },
        filetypes = {
          'java',
          'javascript',
          'typescript',
          'c',
          'go',
          'kubernetes',
          'css',
          'docker',
          'xml',
          'html',
          'python',
        },
      }
    end,
  },

  -- [[ FORMATTING ]] ---------------------------------------------------------------

  -- [conform.nvim] - Code formatting.
  -- see: `:h conform`
  -- link: https://github.com/stevearc/conform.nvim
  {
    'stevearc/conform.nvim',
    branch = 'master',
    cmd = 'ConformInfo',
    -- stylua: ignore
    keys = {
      { '<leader>cf', function() require('conform').format { async = true, lsp_format = 'fallback' } end, mode = { 'n', 'v' }, desc = 'Format [cf]' },
      { '<leader>cF', function() require('conform').format { async = true, lsp_format = 'fallback', formatters = { 'injected' } } end, mode = { 'n', 'v' }, desc = 'Format Injected Langs [cF]' },
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
          angular = { 'djlint', 'prettierd' },
          ruby = { 'rubocop' },
          go = { 'goimports', 'gofumpt' },
          json = { 'jq', 'prettierd' },
          javascript = { 'prettierd' },
          less = { 'prettierd' },
          scss = { 'prettierd' },
          sql = { 'sqlfmt', 'sqruff' },
          typescript = { 'prettierd' },
          vue = { 'prettierd' },
          kotlin = { 'ktlint' },
          markdown = { 'prettierd', 'markdownlint', 'markdown-toc' },
          yaml = { 'prettierd' },
          rust = { 'rustfmt' },
          -- Conform will run multiple formatters sequentially
          -- go = { 'goimports', 'gofmt' },
          -- Use a sub-list to run only the first available formatter
          -- javascript = { { 'prettierd', 'prettier' } },
          -- You can use a function here to determine the formatters dynamically
          -- Use the "*" filetype to run formatters on all filetypes.
          ['*'] = { 'trim_whitespace' },
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
