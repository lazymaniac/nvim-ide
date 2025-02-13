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
        ruff = {
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
            if client.name == 'ruff' then
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
    dependencies = {
      { 'nvim-neotest/neotest-python' },
      { 'thenbe/neotest-playwright', dependencies = 'nvim-telescope/telescope.nvim' },
    },
    opts = {
      adapters = {
        ['neotest-python'] = {
          runner = 'pytest',
          python = '.venv/bin/python',
        },
        ['neotest-playwright'] = {
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
          },
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
    branch = 'regexp',
    cmd = 'VenvSelect',
    ft = "python",
    keys = { { '<leader>cv', '<cmd>:VenvSelect<cr>', desc = 'Select VirtualEnv [cv]' } },
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    },
  },

}
