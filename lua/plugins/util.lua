return {

  -- [[ PERFORMANCE ]] --------------------------------------------------------------
  -- [vim-startuptime] - Measure startup time. Displayed on dashboard
  {
    'dstein64/vim-startuptime',
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
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {
      dir = vim.fn.expand(vim.fn.stdpath 'state' .. '/sessions/'), -- directory where session files are saved
      options = vim.opt.sessionoptions:get(),
      save_empty = false, -- don't save if there are no open file buffers
    },
    -- stylua: ignore
    keys = {
      { '<leader>qs', function() require('persistence').load() end, desc = 'Restore Session', },
      { '<leader>ql', function() require('persistence').load { last = true } end, desc = 'Restore Last Session', },
      { '<leader>qd', function() require('persistence').stop() end, desc = "Don't Save Current Session", },
    },
  },

  -- [[ UTIL LIB ]] ---------------------------------------------------------------
  -- [plenary.nvim] - Utility lib used by other plugins
  -- see: `:h help-tag`
  { 'nvim-lua/plenary.nvim' },

  -- [[ LEARNING VIM MOTIONS ]] ---------------------------------------------------------------
  -- [hardtime.nvim] - Plugin that helps learn vim motions and keybindings by providing hints
  -- see: `:h hardtime`
  {
    'm4xshen/hardtime.nvim',
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
    opts = {
      max_time = 1000,
      max_count = 3,
      disable_mouse = false,
      hint = true,
      notification = true,
      allow_different_key = false,
      enabled = true,
    },
    -- stylua: ignore
    keys = {
      { '<leader>uH', '<cmd>Hardtime toggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle Hardtime', },
    },
  },

  -- [[ CHEATSHEET ]] ---------------------------------------------------------------
  -- [cheatsheet.nvim] - Cheats for editor, vim plugins, nerd-fonts, etc.
  -- see: `:h cheatsHeet.nvim`
  {
    'sudormrfbin/cheatsheet.nvim',
    event = 'VeryLazy',
    dependencies = {
      { 'nvim-telescope/telescope.nvim' },
      { 'nvim-lua/popup.nvim' },
      { 'nvim-lua/plenary.nvim' },
    },
    config = function()
      require('cheatsheet').setup {
        -- Whether to show bundled cheatsheets
        -- For generic cheatsheets like default, unicode, nerd-fonts, etc
        -- bundled_cheatsheets = {
        --     enabled = {},
        --     disabled = {},
        -- },
        bundled_cheatsheets = {
          disabled = { 'nerd-fonts' },
        },
        -- For plugin specific cheatsheets
        -- bundled_plugin_cheatsheets = {
        --     enabled = {},
        --     disabled = {},
        -- }
        bundled_plugin_cheatsheets = true,
        -- For bundled plugin cheatsheets, do not show a sheet if you
        -- don't have the plugin installed (searches runtimepath for
        -- same directory name)
        include_only_installed_plugins = true,
        -- Key mappings bound inside the telescope window
        telescope_mappings = {
          ['<CR>'] = require('cheatsheet.telescope.actions').select_or_fill_commandline,
          ['<A-CR>'] = require('cheatsheet.telescope.actions').select_or_execute,
          ['<C-Y>'] = require('cheatsheet.telescope.actions').copy_cheat_value,
          ['<C-E>'] = require('cheatsheet.telescope.actions').edit_user_cheatsheet,
        },
      }
    end,
  },

  -- [[ TOYS ]] ---------------------------------------------------------------
  -- [Tip.nvim] - Show useful tip on nvim startup
  {
    'TobinPalmer/Tip.nvim',
    event = 'VimEnter',
    init = function()
      -- Default config
      require('tip').setup {
        seconds = 6,
        title = 'Tip!',
        url = 'https://vtip.43z.one',
      }
    end,
  },

  -- [wttr.nvim] - Show current weather in lualine or forecast in popup
  -- see: `:h wttr.nvim`
  {
    'lazymaniac/wttr.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
    },
    opts = {
      location = '',
      format = 1,
      custom_format = '%C+%c+T:%t+%w+UV:%u+Hum:%h',
      lang = 'en',
    },
    -- stylua: ignore
    keys = {
      { '<leader>W', function() require('wttr').get_forecast() end, desc = 'Weather Forecast', },
    },
  },

  -- [oogway.nvim] - Provides list of Oogway sentences and ascii prictures
  -- see: `:h oogway`
  {
    '0x5a4/oogway.nvim',
    event = 'VeryLazy',
    cmd = { 'Oogway' },
  },
}
