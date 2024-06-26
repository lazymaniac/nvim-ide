return {

  -- [omnisharp-extended-lsp] - Extends native LSP for omnisharp
  -- see: `:h omnisharp-extended-lsp`
  -- link: https://github.com/Hoffs/omnisharp-extended-lsp.nvim
  { 'Hoffs/omnisharp-extended-lsp.nvim', lazy = true },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'c_sharp' })
      end
    end,
  },

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'netcoredbg', 'csharpier' })
      end
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        omnisharp = {
          handlers = {
            ['textDocument/definition'] = function(...)
              return require('omnisharp_extended').handler(...)
            end,
          },
          keys = {
            {
              'gd',
              function()
                require('omnisharp_extended').telescope_lsp_definitions()
              end,
              desc = 'Goto Definition',
            },
          },
          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
          enable_import_completion = true,
        },
      },
    },
  },

  {
    'mfussenegger/nvim-dap',
    optional = true,
    opts = function()
      local dap = require 'dap'
      if not dap.adapters['netcoredbg'] then
        require('dap').adapters['netcoredbg'] = {
          type = 'executable',
          command = vim.fn.exepath 'netcoredbg',
          args = { '--interpreter=vscode' },
        }
      end
      for _, lang in ipairs { 'cs', 'fsharp', 'vb' } do
        if not dap.configurations[lang] then
          dap.configurations[lang] = {
            {
              type = 'netcoredbg',
              name = 'Launch file',
              request = 'launch',
              ---@diagnostic disable-next-line: redundant-parameter
              program = function()
                return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/', 'file')
              end,
              cwd = '${workspaceFolder}',
            },
          }
        end
      end
    end,
  },
}
