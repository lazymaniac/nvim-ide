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

  {
    url = "https://codeberg.org/andyg/leap.nvim",
    config = function()
      -- require('leap').set_default_mappings()
      -- Exclude whitespace and the middle of alphabetic words from preview:
      --   foobar[baaz] = quux
      --   ^----^^^--^^-^-^--^
      require('leap').opts.preview_filter = function(ch0, ch1, ch2)
        return not (ch1:match '%s' or ch0:match '%a' and ch1:match '%a' and ch2:match '%a')
      end
      require('leap').opts.equivalence_classes = { ' \t\r\n', '([{', ')]}', '\'"`' }
      require('leap.user').set_repeat_keys('<enter>', '<backspace>')
    end,
  },
}
