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
        kotlin = { 'ktlint', 'detekt' },
        javascript = { 'eslint_d' },
        javascriptreact = { 'eslint_d' },
        markdown = { 'markdownlint' },
        python = { 'ruff' },
        ruby = { 'erb_lint', 'rubocop' },
        typescript = { 'eslint_d' },
        typescriptreact = { 'eslint_d' },
        yaml = { 'yamllint' },
        -- Use the "*" filetype to run linters on all filetypes.
        -- ['*'] = { 'typos' },
        -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
        -- ['_'] = { 'fallback linter' },
      }
      lint.linters.eslint_d.env = vim.tbl_extend('force', lint.linters.eslint_d.env or {}, {
        ESLINT_D_MISS = 'fail',
      })

      local project = require 'nv_ide.project'
      local group = vim.api.nvim_create_augroup('nvide_lint', { clear = true })
      vim.api.nvim_create_autocmd('BufWritePost', {
        group = group,
        callback = function(event)
          local path = vim.api.nvim_buf_get_name(event.buf)
          local root = project.root(path)
          if not root or not project.trusted(root) then return end
          local names = vim.deepcopy(lint.linters_by_ft[vim.bo[event.buf].filetype] or {})
          if vim.bo[event.buf].filetype == 'yaml'
            and project.contains(vim.fs.joinpath(root, '.github', 'workflows'), path)
          then
            names[#names + 1] = 'actionlint'
          end
          if #names > 0 then
            vim.api.nvim_buf_call(event.buf, function()
              lint.try_lint(names, { cwd = root })
            end)
          end
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
      local mason = require('util').mason_root()
      require('sonarlint').setup {
        server = {
          cmd = {
            'sonarlint-language-server',
            '-stdio',
            '-analyzers',
            vim.fs.joinpath(mason, 'share', 'sonarlint-analyzers', 'sonarjava.jar'),
            vim.fs.joinpath(mason, 'share', 'sonarlint-analyzers', 'sonarjs.jar'),
            vim.fs.joinpath(mason, 'share', 'sonarlint-analyzers', 'sonarxml.jar'),
            vim.fs.joinpath(mason, 'share', 'sonarlint-analyzers', 'sonargo.jar'),
            vim.fs.joinpath(mason, 'share', 'sonarlint-analyzers', 'sonarhtml.jar'),
            vim.fs.joinpath(mason, 'share', 'sonarlint-analyzers', 'sonariac.jar'),
            vim.fs.joinpath(mason, 'share', 'sonarlint-analyzers', 'sonarjavasymbolicexecution.jar'),
            vim.fs.joinpath(mason, 'share', 'sonarlint-analyzers', 'sonarpython.jar'),
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
          bash = { 'beautysh', 'shellharden', stop_after_first = true },
          sh = { 'beautysh', 'shellharden', stop_after_first = true },
          css = { 'prettierd' },
          flow = { 'prettierd' },
          graphql = { 'prettierd' },
          html = { 'prettierd' },
          python = { 'black', 'docformatter' },
          angular = { 'djlint', 'prettierd', stop_after_first = true },
          ruby = { 'rubocop' },
          go = { 'goimports', 'gofumpt' },
          json = { 'jq', 'prettierd', stop_after_first = true },
          jsonc = { 'prettierd' },
          javascript = { 'prettierd' },
          javascriptreact = { 'prettierd' },
          less = { 'prettierd' },
          scss = { 'prettierd' },
          sql = { 'sqlfmt', 'sqruff', stop_after_first = true },
          typescript = { 'prettierd' },
          typescriptreact = { 'prettierd' },
          vue = { 'prettierd' },
          svelte = { 'prettierd' },
          kotlin = { 'ktlint' },
          markdown = { 'prettierd', 'markdownlint', 'markdown-toc' },
          yaml = { 'prettierd' },
          rust = { 'rustfmt' },
          eruby = { 'erb_format' },
          cmake = { 'cmake_format' },
          xml = { 'xmlformatter' },
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
        format_on_save = require('util').format.format_on_save,
        format_after_save = nil,
        notify_on_error = true,
        formatters = {
          prettierd = { env = { PRETTIERD_LOCAL_PRETTIER_ONLY = '1' } },
        },
      }
    end,
  },
}
