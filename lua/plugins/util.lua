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

  -- [persisted.nvim] - Automatic session management
  -- see: `:h persisted.nvim`
  {
    'olimorris/persisted.nvim',
    dependencies = {},
    -- stylua: ignore
    keys = {
      { '<leader>qt', "<CMD>SessionToggle<CR>", desc = 'Toggle Sessions [qt]' },
      { '<leader>qS', "<CMD>SessionStop<CR>", desc = 'Stop Recording [qS]' },
      { '<leader>qs', "<CMD>SessionSave<CR>", desc = 'Save Session [qs]' },
      { '<leader>qc', "<CMD>SessionLoad<CR>", desc = 'Load Session for CWD [qc]' },
      { '<leader>ql', "<CMD>SessionLoadLast<CR>", desc = 'Load Last Session [ql]' },
      { '<leader>qf', "<CMD>SessionLoadFromFile<CR>", desc = 'Load From File [qf]' },
      { '<leader>qd', "<CMD>SessionDelete<CR>", desc = 'Delete Current Session [qd]' },
      { '<leader>qL', "<CMD>Telescope persisted<CR>", desc = 'List Sessions [qL]' },
    },
    config = function()
      require('persisted').setup {
        save_dir = vim.fn.expand(vim.fn.stdpath 'data' .. '/sessions/'), -- directory where session files are saved
        silent = false, -- silent nvim message when sourcing session file
        use_git_branch = true, -- create session files based on the branch of a git enabled repository
        default_branch = 'main', -- the branch to load if a session file is not found for the current branch
        autosave = true, -- automatically save session files when exiting Neovim
        should_autosave = nil, -- function to determine if a session should be autosaved
        autoload = true, -- automatically load the session for the cwd on Neovim startup
        on_autoload_no_session = function()
          vim.notify 'No existing session to load.'
        end,
        follow_cwd = true, -- change session file name to match current working directory if it changes
        allowed_dirs = nil, -- table of dirs that the plugin will auto-save and auto-load from
        ignored_dirs = nil, -- table of dirs that are ignored when auto-saving and auto-loading
        ignored_branches = nil, -- table of branch patterns that are ignored for auto-saving and auto-loading
        telescope = {
          reset_prompt = true, -- Reset the Telescope prompt after an action?
          mappings = { -- table of mappings for the Telescope extension
            change_branch = '<c-b>',
            copy_session = '<c-c>',
            delete_session = '<c-d>',
          },
        },
      }
      require('telescope').load_extension 'persisted'
    end,
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

  -- [[ CHEATSHEET ]] ---------------------------------------------------------------
  -- [cheatsheet.nvim] - Cheats for editor, vim plugins, nerd-fonts, etc.
  -- see: `:h cheatsheet.nvim`
  {
    'sudormrfbin/cheatsheet.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/popup.nvim', 'nvim-lua/plenary.nvim' },
    keys = {
      {
        '<leader>?',
        '<cmd>Cheatsheet<cr>',
        mode = { 'n' },
        desc = 'Cheatsheet [?]',
      },
    },
    config = function()
      local ctactions = require 'cheatsheet.telescope.actions'
      require('cheatsheet').setup {
        bundled_cheetsheets = {
          enabled = { 'default', 'lua', 'markdown', 'regex', 'netrw', 'unicode' },
          disabled = { 'nerd-fonts' },
        },
        bundled_plugin_cheatsheets = {
          enabled = {
            'auto-session',
            'octo.nvim',
            'telescope.nvim',
          },
          disabled = { 'gitsigns' },
        },
        include_only_installed_plugins = true,
        telescope_mappings = {
          ['<CR>'] = ctactions.select_or_fill_commandline,
          ['<A-CR>'] = ctactions.select_or_execute,
          ['<C-Y>'] = ctactions.copy_cheat_value,
          ['<C-E>'] = ctactions.edit_user_cheatsheet,
        },
      }
    end,
  },

  -- [[ TOYS ]] ---------------------------------------------------------------

  -- [wttr.nvim] - Show current weather in lualine or forecast in popup
  -- see: `:h wttr.nvim`
  {
    'lazymaniac/wttr.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim', 'MunifTanjim/nui.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>lw', function() require('wttr').get_forecast() end, desc = 'Weather Forecast [Uw]', },
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
  {
    '0x5a4/oogway.nvim',
    event = 'VeryLazy',
    cmd = { 'Oogway' },
  },
}
