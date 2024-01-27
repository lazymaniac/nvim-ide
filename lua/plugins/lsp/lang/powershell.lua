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
              ['<leader>ct'] = { '<cmd>lua require("powershell").toggle_term()<cr>', 'Toogle Term (PowerShell)' },
              ['<leader>ce'] = { '<cmd>lua require("powershell").eval()<cr>', 'Eval (PowerShell)' },
            }, { mode = { 'n', 'v' }, buffer = bufnr })
          end,
        },
      },
    },
  },

  {
    'TheLeoP/powershell.nvim',
    config = function()
      require('powershell').setup {
        bundle_path = vim.fn.stdpath 'data' .. '/mason/packages/powershell-editor-services',
      }
    end,
  },
}
