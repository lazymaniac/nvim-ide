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
    'L3MON4D3/LuaSnip',
    dependencies = {
      'johnpapa/vscode-angular-snippets',
      config = function()
        require('luasnip.loaders.from_vscode').lazy_load()
      end,
    },
  },
}
