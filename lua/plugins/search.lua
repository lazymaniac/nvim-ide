return {

  -- [[ SEARCHING AND REPLACING ]] ---------------------------------------------------------------

  -- [grug-far.nvim] - Search and replace across multiple files with a fuzzy finder interface.
  -- see: `:h grug-far.nvim`
  -- link: https://github.com/MagicDuck/grug-far.nvim
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

-- [smart-motion.nvim] - Home row keys for smart motions
-- see: `:h smart-motion.nvim`
-- link: https://github.com/FluxxField/smart-motion.nvim
  {
    'FluxxField/smart-motion.nvim',
    branch = 'master',
    event = 'BufReadPost',
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
}
