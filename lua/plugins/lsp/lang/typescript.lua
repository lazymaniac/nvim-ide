return {

  -- add typescript to treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'typescript', 'tsx' })
      end
    end,
  },

  -- correctly setup lspconfig
  {
    'neovim/nvim-lspconfig',
    opts = {
      -- make sure mason installs the server
      servers = {
        ts_ls = {},
      },
    },
  },

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      {
        'williamboman/mason.nvim',
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { 'js-debug-adapter', 'jq' })
        end,
      },
    },
    opts = function()
      local dap = require 'dap'
      if not dap.adapters['pwa-node'] then
        require('dap').adapters['pwa-node'] = {
          type = 'server',
          host = 'localhost',
          port = '${port}',
          executable = {
            command = 'node',
            args = {
              require('mason-registry').get_package('js-debug-adapter'):get_install_path() .. '/js-debug/src/dapDebugServer.js',
              '${port}',
            },
          },
        }
      end
      for _, language in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
        if not dap.configurations[language] then
          dap.configurations[language] = {
            {
              type = 'pwa-node',
              request = 'launch',
              name = 'Launch file',
              program = '${file}',
              cwd = '${workspaceFolder}',
            },
            {
              type = 'pwa-node',
              request = 'attach',
              name = 'Attach',
              processId = require('dap.utils').pick_process,
              cwd = '${workspaceFolder}',
            },
          }
        end
      end
    end,
  },
}
