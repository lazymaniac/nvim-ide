return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'black', 'pydocstyle', 'pylint', 'docformatter' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'ninja', 'python', 'rst', 'toml' })
      end
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = 'openFilesOnly',
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        ruff = {},
        ruff_lsp = {
          keys = {
            {
              '<leader>cz',
              function()
                vim.lsp.buf.code_action {
                  apply = true,
                  context = {
                    only = { 'source.organizeImports' },
                    diagnostics = {},
                  },
                }
              end,
              desc = 'Organize Imports [cz]',
            },
          },
        },
      },
      setup = {
        ruff_lsp = function()
          require('util').lsp.on_attach(function(client, _)
            if client.name == 'ruff_lsp' then
              -- Disable hover in favor of Pyright
              client.server_capabilities.hoverProvider = false
            end
          end)
        end,
      },
    },
  },

  {
    'nvim-neotest/neotest',
    dependencies = { 'nvim-neotest/neotest-python' },
    opts = {
      adapters = {
        ['neotest-python'] = {
          runner = 'pytest',
          python = '.venv/bin/python',
        },
      },
    },
  },

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'mfussenegger/nvim-dap-python',
      -- stylua: ignore
      keys = {
        { "<leader>dM", function() require('dap-python').test_method() end, desc = "Debug Method [dM]", ft = "python" },
        { "<leader>dS", function() require('dap-python').test_class() end, desc = "Debug Class [dS]", ft = "python" },
      },
      config = function()
        local path = require('mason-registry').get_package('debugpy'):get_install_path()
        require('dap-python').setup '.venv/bin/python'
      end,
    },
  },

  -- [venv-selector.nvim] - Python Virtual Env selector.
  -- see: `:h venv-selector.nvim`
  -- link: https://github.com/linux-cultist/venv-selector.nvim
  -- TODO: check new `regexp` branch
  {
    'linux-cultist/venv-selector.nvim',
    branch = 'main',
    cmd = 'VenvSelect',
    keys = { { '<leader>cv', '<cmd>:VenvSelect<cr>', desc = 'Select VirtualEnv [cv]' } },
    opts = function(_, opts)
      if require('util').has 'nvim-dap-python' then
        opts.dap_enabled = true
      end
      return vim.tbl_deep_extend('force', opts, {
        name = {
          'venv',
          '.venv',
          'env',
          '.env',
        },
      })
    end,
  },

  {
    'hrsh7th/nvim-cmp',
    branch = 'main',
    opts = function(_, opts)
      opts.auto_brackets = opts.auto_brackets or {}
      table.insert(opts.auto_brackets, 'python')
    end,
  },
}
