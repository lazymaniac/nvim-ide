return {

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
      { '<leader>qs', function() require('persistence').load() end, desc = 'Restore Session [qs]', },
      { '<leader>ql', function() require('persistence').load { last = true } end, desc = 'Restore Last Session [ql]', },
      { '<leader>qd', function() require('persistence').stop() end, desc = "Don't Save Current Session [qd]", },
    },
    opts = {
      dir = vim.fn.expand(vim.fn.stdpath 'state' .. '/sessions/'), -- directory where session files are saved
      options = vim.opt.sessionoptions:get(),
      save_empty = false, -- don't save if there are no open file buffers
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

  {
    'nvzone/typr',
    dependencies = 'nvzone/volt',
    opts = {},
    cmd = { 'Typr', 'TyprStats' },
  },
}
