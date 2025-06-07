return {

  -- [[ SEARCHING AND REPLACING ]] ---------------------------------------------------------------

  -- search/replace in multiple files
  {
    'MagicDuck/grug-far.nvim',
    opts = { headerMaxWidth = 80 },
    cmd = 'GrugFar',
    keys = {
      {
        '<leader>ss',
        function()
          local grug = require 'grug-far'
          local ext = vim.bo.buftype == '' and vim.fn.expand '%:e'
          grug.open {
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= '' and '*.' .. ext or nil,
            },
          }
        end,
        mode = { 'n', 'v' },
        desc = 'Search and Replace',
      },
    },
  },

  {
    'FluxxField/smart-motion.nvim',
    branch = 'master',
    opts = {
      keys = 'fjdksleirughtynm',
      presets = {
        words = false,
        lines = false,
        search = true,
        delete = false,
        yank = false,
        change = false,
      },
    },
  },

  -- [improved-search] - Enhance searching with n and N keys
  -- see: `:h improved-search`
  -- link: https://github.com/backdround/improved-search.nvim
  {
    'backdround/improved-search.nvim',
    branch = 'main',
    event = 'VeryLazy',
    config = function()
      local search = require 'improved-search'
      -- Search next / previous.
      vim.keymap.set({ 'n', 'x', 'o' }, 'n', search.stable_next)
      vim.keymap.set({ 'n', 'x', 'o' }, 'N', search.stable_previous)
      -- Search current word without moving.
      vim.keymap.set('n', '!', search.current_word)
      -- Search selected text in visual mode
      vim.keymap.set('x', '!', search.in_place) -- search selection without moving
      vim.keymap.set('x', '*', search.forward) -- search selection forward
      vim.keymap.set('x', '#', search.backward) -- search selection backward
      -- Search by motion in place
      vim.keymap.set('n', '|', search.in_place)
      -- You can also use search.forward / search.backward for motion selection.
    end,
  },
}
