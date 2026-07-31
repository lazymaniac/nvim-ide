return {

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        angularls = {
          filetypes = {
            'html',
            'typescript',
            'typescriptreact',
            'typescript.tsx',
            'javascript',
            'javascriptreact',
            'javascript.jsx',
          },
          root_markers = { 'angular.json', 'nx.json' },
          on_attach = function(_, bufnr)
            local wk = require 'which-key'
            wk.add {
              { '<leader>ct', '<cmd>lua require("ng").goto_template_for_component()<cr>', desc = 'Goto Template [ct]', mode = 'n', buffer = bufnr },
              { '<leader>cc', '<cmd>lua require("ng").goto_component_with_template_file()<cr>', desc = 'Goto Component [cc]', mode = 'n', buffer = bufnr },
              { '<leader>cb', '<cmd>lua require("ng").get_template_tcb()<cr>', desc = 'Goto Type Check Block [cb]', mode = 'n', buffer = bufnr },
            }
          end,
        },
      },
    },
  },

  -- [ng.nvim] - Adds extra command to native lsp.
  -- see: `:h ng,nvim`
  -- link: https://github.com/joeveiga/ng.nvim
  {
    'joeveiga/ng.nvim',
    ft = { 'typescript', 'typescriptreact', 'typescript.tsx', 'javascript', 'javascriptreact', 'javascript.jsx' },
    branch = 'main',
  },
}
