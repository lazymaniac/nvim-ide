return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        angularls = {},
      },
    },
  },
  {
    'joeveiga/ng.nvim',
    keys = {
      {
        '<leader>ct',
        '<cmd>lua require("ng").goto_template_for_component()<cr>',
        mode = { 'n' },
        desc = 'Goto Template (Angular)',
      },
      {
        '<leader>cc',
        '<cmd>lua require("ng").goto_component_with_template_file()<cr>',
        mode = { 'n', 'v' },
        desc = 'Goto Component (Angular)',
      },
      {
        '<leader>cb',
        '<cmd>lua require("ng").get_template_tcb()<cr>',
        mode = { 'n', 'v' },
        desc = 'Goto Type Check Block (Angular)',
      },
    },
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = {
      'johnpapa/vscode-angular-snippets',
      config = function()
        require('luasnip.loaders.from_vscode').lazy_load()
      end,
    },
  },
}
