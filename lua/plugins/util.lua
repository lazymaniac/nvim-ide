return {

  -- [[ PERFORMANCE ]] --------------------------------------------------------------
  -- [vim-startuptime] - Measure startup time. Displayed on dashboard
  -- link: https://github.com/dstein64/vim-startuptime
  {
    'dstein64/vim-startuptime',
    branch = 'master',
    event = 'VeryLazy',
    cmd = 'StartupTime',
    config = function()
      vim.g.startuptime_tries = 10
    end,
  },

  -- [[ SESSION MANAGEMENT ]] ---------------------------------------------------------------

  -- [persistence.nvim] - Session management. This saves your session in the background,
  -- keeping track of open buffers, window arrangement, and more.
  -- You can restore sessions when returning through the dashboard.
  -- see: `:h persistence`
  -- link: https://github.com/folke/persistence.nvim
  {
    'folke/persistence.nvim',
    branch = 'main',
    event = 'BufReadPre',
    -- stylua: ignore
    keys = {
      { '<leader>qs', function() require('persistence').load() end,               desc = 'Restore Session [qs]', },
      { '<leader>ql', function() require('persistence').load { last = true } end, desc = 'Restore Last Session [ql]', },
      { '<leader>qd', function() require('persistence').stop() end,               desc = "Don't Save Current Session [qd]", },
    },
    opts = {
      dir = vim.fn.expand(vim.fn.stdpath 'state' .. '/sessions/'), -- directory where session files are saved
      options = vim.opt.sessionoptions:get(),
      save_empty = false,                                          -- don't save if there are no open file buffers
    },
  },

  -- [[ UTIL LIB ]] ---------------------------------------------------------------

  -- [plenary.nvim] - Utility lib used by other plugins
  -- see: `:h help-tag`
  -- link: https://github.com/nvim-lua/plenary.nvim
  { 'nvim-lua/plenary.nvim', branch = 'master' },

  -- [[ LEARNING VIM MOTIONS ]] ---------------------------------------------------------------

  -- [hardtime.nvim] - Plugin that helps learn vim motions and keybindings by providing hints
  -- see: `:h hardtime`
  -- link: https://github.com/m4xshen/hardtime.nvim
  {
    'm4xshen/hardtime.nvim',
    branch = 'main',
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>uH', '<cmd>Hardtime toggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle Hardtime [uH]', },
    },
    opts = {
      max_time = 1000,
      max_count = 3,
      disable_mouse = false,
      hint = true,
      notification = true,
      allow_different_key = false,
      enabled = false,
    },
  },

  -- [screenkey.nvim] - Show currently pressed keys in popup
  -- see: `:h screenkey.nvim`
  -- link: https://github.com/NStefan002/screenkey.nvim
  {
    'NStefan002/screenkey.nvim',
    keys = {
      { '<leader>lk', '<cmd>Screenkey<cr>', mode = { 'n', 'v' }, desc = 'Show pressed keys' },
    },
    cmd = 'Screenkey',
    version = '*',
    config = true,
  },

  -- [precognition.nvim] - Show hint with available movements.
  -- see: `:h precognition.nvim`
  -- link: https://github.com/tris203/precognition.nvim
  {
    'tris203/precognition.nvim',
    branch = 'main',
    keys = {
      { '<leader>lh', '<cmd>lua require("precognition").toggle()<cr>', mode = { 'n', 'v' }, desc = 'Show movement hints' },
    },
    config = {
      -- startVisible = true,
      -- showBlankVirtLine = true,
      -- highlightColor = "Comment",
      -- hints = {
      --      Caret = { text = "^", prio = 2 },
      --      Dollar = { text = "$", prio = 1 },
      --      MatchingPair = { text = "%", prio = 5 },
      --      Zero = { text = "0", prio = 1 },
      --      w = { text = "w", prio = 10 },
      --      b = { text = "b", prio = 9 },
      --      e = { text = "e", prio = 8 },
      --      W = { text = "W", prio = 7 },
      --      B = { text = "B", prio = 6 },
      --      E = { text = "E", prio = 5 },
      -- },
      -- gutterHints = {
      --     -- prio is not currently used for gutter hints
      --     G = { text = "G", prio = 1 },
      --     gg = { text = "gg", prio = 1 },
      --     PrevParagraph = { text = "{", prio = 1 },
      --     NextParagraph = { text = "}", prio = 1 },
      -- },
    },
  },
  -- [[ TOYS ]] ---------------------------------------------------------------

  -- [wttr.nvim] - Show current weather in lualine or forecast in popup
  -- see: `:h wttr.nvim`
  -- link: https://github.com/lazymaniac/wttr.nvim
  {
    'lazymaniac/wttr.nvim',
    branch = 'main',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim', 'MunifTanjim/nui.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>lw', function() require('wttr').get_forecast() end, desc = 'Weather Forecast [lw]', },
    },
    opts = {
      location = '',
      format = 1,
      custom_format = '%C+%c+T:%t+%w+UV:%u+Hum:%h',
      lang = 'en',
    },
  },

  -- [oogway.nvim] - Provides list of Oogway sentences and ascii prictures
  -- see: `:h oogway`
  -- link: https://github.com/0x5a4/oogway.nvim
  {
    '0x5a4/oogway.nvim',
    branch = 'main',
    event = 'VeryLazy',
    cmd = { 'Oogway' },
  },
}
