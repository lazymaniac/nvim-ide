return {

  -- [haskell-tools] - Extension for Haskell LSP.
  -- see: `:h haskell-tools`
  -- link: https://github.com/mrcjkb/haskell-tools.nvim
  {
    'mrcjkb/haskell-tools.nvim',
    branch = 'master',
    ft = { 'haskell', 'lhaskell', 'cabal', 'cabalproject' },
    config = function() end,
  },

  {
    'nvim-neotest/neotest',
    optional = true,
    dependencies = {
      { 'mrcjkb/neotest-haskell', branch = 'master' },
    },
    opts = {
      adapters = {
        ['neotest-haskell'] = {},
      },
    },
  },

  -- [haskell-snippets] - Haskell specific snippets.
  -- see: `:h haskell-snippets`
  -- link: https://github.com/mrcjkb/haskell-snippets.nvim
  {
    'mrcjkb/haskell-snippets.nvim',
    branch = 'master',
    dependencies = { 'L3MON4D3/LuaSnip' },
    ft = { 'haskell', 'lhaskell', 'cabal', 'cabalproject' },
    config = function()
      local haskell_snippets = require('haskell-snippets').all
      require('luasnip').add_snippets('haskell', haskell_snippets, { key = 'haskell' })
    end,
  },
}
