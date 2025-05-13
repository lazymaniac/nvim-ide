return {

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
        pattern = { '*.component.html', '*.container.html' },
        callback = function()
          vim.treesitter.start(nil, 'angular')
        end,
      })
    end,
  },

  -- [ng.nvim] - Adds extra command to native lsp.
  -- see: `:h ng,nvim`
  -- link: https://github.com/joeveiga/ng.nvim
  {
    'joeveiga/ng.nvim',
    event = 'VeryLazy',
    branch = 'main',
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
