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
