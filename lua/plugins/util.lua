return {

  -- measure startuptime
  {
    'dstein64/vim-startuptime',
    cmd = 'StartupTime',
    config = function()
      vim.g.startuptime_tries = 10
    end,
  },

  -- Session management. This saves your session in the background,
  -- keeping track of open buffers, window arrangement, and more.
  -- You can restore sessions when returning through the dashboard.
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {
      dir = vim.fn.expand(vim.fn.stdpath 'state' .. '/sessions/'), -- directory where session files are saved
      options = vim.opt.sessionoptions:get(),
      pre_save = nil, -- a function to call before saving the session
      save_empty = false, -- don't save if there are no open file buffers
    },
    keys = {
      {
        '<leader>qs',
        function()
          require('persistence').load()
        end,
        desc = 'Restore Session',
      },
      {
        '<leader>ql',
        function()
          require('persistence').load { last = true }
        end,
        desc = 'Restore Last Session',
      },
      {
        '<leader>qd',
        function()
          require('persistence').stop()
        end,
        desc = "Don't Save Current Session",
      },
    },
  },

  -- library used by other plugins
  { 'nvim-lua/plenary.nvim' },

  -- Plugin that helps learn vim motions and keybindings
  --
  -- hardtime.nvim is enabled by default. You can change its state with the following commands:
  --
  -- :Hardtime enable enable hardtime.nvim
  -- :Hardtime disable disable hardtime.nvim
  -- :Hardtime toggle toggle hardtime.nvim
  -- View the most frequently seen hints with :Hardtime report.

  -- Log file is at ~/.cache/nvim/hardtime.nvim.log.
  {
    'm4xshen/hardtime.nvim',
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
    opts = {
      max_time = 1000,
      max_count = 2,
      disable_mouse = false,
      hint = true,
      notification = true,
      allow_different_key = false,
      enabled = true,
    },
    config = function(_, opts)
      require('hardtime').setup(opts)
    end,
    keys = {
      {
        '<leader>uH',
        '<cmd>Hardtime toggle<cr>',
        mode = { 'n', 'v' },
        desc = 'Toggle Hardtime',
      },
    },
  },

  -- Coding cheatsheet
  -- see: `h: cheatsheet`
  {
    'sudormrfbin/cheatsheet.nvim',
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
        bundled_cheatsheets = true,

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
  {
    'TobinPalmer/Tip.nvim',
    event = 'VimEnter',
    init = function()
      -- Default config
      require('tip').setup {
        seconds = 2,
        title = 'Tip!',
        url = 'https://vtip.43z.one',
      }
    end,
  },
  {
    'lazymaniac/wttr.nvim',
    event = 'VeryLazy',
    branch = 'main',
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
    keys = {
      {
        '<leader>W',
        function()
          require('wttr').get_forecast()
        end,
        desc = 'Weather Forecast',
      },
    },
  },
  {
    'adityastomar67/italicize',
    config = function()
      require('italicize').setup {
        transparency = false,
        italics = true,
      }
    end,
  },
}
