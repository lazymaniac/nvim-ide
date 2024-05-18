return {

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        powershell_es = {
          bundle_path = vim.fn.stdpath 'data' .. '/mason/packages/powershell-editor-services',
          on_attach = function(client, bufnr)
            local wk = require 'which-key'
            wk.register({
              ['<leader>ct'] = { '<cmd>lua require("powershell").toggle_term()<cr>', 'Toggle Term (PowerShell) [ct]' },
              ['<leader>ce'] = { '<cmd>lua require("powershell").eval()<cr>', 'Eval (PowerShell) [ce]' },
            }, { mode = { 'n', 'v' }, buffer = bufnr })
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
