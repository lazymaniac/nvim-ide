return {

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        powershell_es = {
          bundle_path = vim.fn.stdpath 'data' .. '/mason/packages/powershell-editor-services',
          on_attach = function(client, bufnr)
            local wk = require 'which-key'
            wk.add {
              { '<leader>ct', '<cmd>lua require("powershell").toggle_term()<cr>', desc = 'Toggle Term (PowerShell) [ct]', mode = { 'n', 'v' }, buffer = bufnr },
              { '<leader>ce', '<cmd>lua require("powershell").eval()<cr>', desc = 'Eval (PowerShell) [ce]', mode = { 'n', 'v' }, buffer = bufnr },
            }
          end,
        },
      },
    },
  },

  -- [powershell.nvim] - Powershell LSP support.
  -- see: `:h powershell.nvim`
  -- link: https://github.com/TheLeoP/powershell.nvim
  {
    'TheLeoP/powershell.nvim',
    branch = 'main',
    config = function()
      require('powershell').setup {
        bundle_path = vim.fn.stdpath 'data' .. '/mason/packages/powershell-editor-services',
      }
    end,
  },
}
