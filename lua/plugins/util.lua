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
    opts = { options = vim.opt.sessionoptions:get() },
    -- stylua: ignore
    keys = {
      { "<leader>qs", function() require("persistence").load() end,                desc = "Restore Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end,                desc = "Don't Save Current Session" },
    },
  },

  -- library used by other plugins
  { 'nvim-lua/plenary.nvim', lazy = true },

  -- Plugin that helps learn vim motions and keybindings
  --
  -- hardtime.nvim is enabled by default. You can change its state with the following commands:
  --
  -- :Hardtime enable enable hardtime.nvim
  -- :Hardtime disable disable hardtime.nvim
  -- :Hardtime toggle toggle hardtime.nvim
  -- You can view the most frequently seen hints with :Hardtime report.

  -- Your log file is at ~/.cache/nvim/hardtime.nvim.log.
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
  {
    'sudormrfbin/cheatsheet.nvim',
    requires = {
      { 'nvim-telescope/telescope.nvim' },
      { 'nvim-lua/popup.nvim' },
      { 'nvim-lua/plenary.nvim' },
    },
  },
}
