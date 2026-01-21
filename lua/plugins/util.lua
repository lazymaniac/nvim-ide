return {

  -- [[ SESSION MANAGEMENT ]] ---------------------------------------------------------------

  {
    'rmagatti/auto-session',
    lazy = false,
    -- stylua: ignore
    keys = {
      { '<leader>ql', '<cmd>Autosession search<cr>', mode = { 'n' }, desc = 'Load session [ql]', },
    },
    ---enables autocomplete for opts
    ---@module "auto-session"
    ---@type AutoSession.Config
    opts = {
      -- Saving / restoring
      enabled = true, -- Enables/disables auto creating, saving and restoring
      auto_save = true, -- Enables/disables auto saving session on exit
      auto_restore = false, -- Enables/disables auto restoring session on start
      auto_create = true, -- Enables/disables auto creating new session files. Can be a function that returns true if a new session file should be allowed
      auto_restore_last_session = false, -- On startup, loads the last saved session if session for cwd does not exist
      cwd_change_handling = true, -- Automatically save/restore sessions when changing directories
      single_session_mode = false, -- Enable single session mode to keep all work in one session regardless of cwd changes. When enabled, prevents creation of separate sessions for different directories and maintains one unified session. Does not work with cwd_change_handling

      -- Filtering
      suppressed_dirs = nil, -- Suppress session restore/create in certain directories
      allowed_dirs = nil, -- Allow session restore/create in certain directories
      bypass_save_filetypes = nil, -- List of filetypes to bypass auto save when the only buffer open is one of the file types listed, useful to ignore dashboards
      close_filetypes_on_save = { 'checkhealth' }, -- Buffers with matching filetypes will be closed before saving
      close_unsupported_windows = true, -- Close windows that aren't backed by normal file before autosaving a session
      preserve_buffer_on_restore = nil, -- Function that returns true if a buffer should be preserved when restoring a session

      -- Git / Session naming
      git_use_branch_name = false, -- Include git branch name in session name, can also be a function that takes an optional path and returns the name of the branch
      git_auto_restore_on_branch_change = false, -- Should we auto-restore the session when the git branch changes. Requires git_use_branch_name
      custom_session_tag = nil, -- Function that can return a string to be used as part of the session name

      -- Deleting
      auto_delete_empty_sessions = true, -- Enables/disables deleting the session if there are only unnamed/empty buffers when auto-saving
      purge_after_minutes = nil, -- Sessions older than purge_after_minutes will be deleted asynchronously on startup, e.g. set to 14400 to delete sessions that haven't been accessed for more than 10 days, defaults to off (no purging), requires >= nvim 0.10

      -- Saving extra data
      save_extra_data = nil, -- Function that returns extra data that should be saved with the session. Will be passed to restore_extra_data on restore
      restore_extra_data = nil, -- Function called when there's extra data saved for a session

      -- Argument handling
      args_allow_single_directory = true, -- Follow normal session save/load logic if launched with a single directory as the only argument
      args_allow_files_auto_save = false, -- Allow saving a session even when launched with a file argument (or multiple files/dirs). It does not load any existing session first. Can be true or a function that returns true when saving is allowed. See documentation for more detail

      -- Misc
      log_level = 'error', -- Sets the log level of the plugin (debug, info, warn, error).
      root_dir = vim.fn.stdpath 'data' .. '/sessions/', -- Root dir where sessions will be stored
      show_auto_restore_notif = false, -- Whether to show a notification when auto-restoring
      restore_error_handler = nil, -- Function called when there's an error restoring. By default, it ignores fold errors otherwise it displays the error and returns false to disable auto_save
      continue_restore_on_error = true, -- Keep loading the session even if there's an error
      lsp_stop_on_restore = false, -- Should language servers be stopped when restoring a session. Can also be a function that will be called if set. Not called on autorestore from startup
      lazy_support = true, -- Automatically detect if Lazy.nvim is being used and wait until Lazy is done to make sure session is restored correctly. Does nothing if Lazy isn't being used
      legacy_cmds = true, -- Define legacy commands: Session*, Autosession (lowercase s), currently true. Set to false to prevent defining them

      ---@type SessionLens
      session_lens = {
        picker = 'snacks', -- "telescope"|"snacks"|"fzf"|"select"|nil Pickers are detected automatically but you can also set one manually. Falls back to vim.ui.select
        load_on_setup = true, -- Only used for telescope, registers the telescope extension at startup so you can use :Telescope session-lens
        picker_opts = nil, -- Table passed to Telescope / Snacks / Fzf-Lua to configure the picker. See below for more information

        ---@type SessionLensMappings
        mappings = {
          -- Mode can be a string or a table, e.g. {"i", "n"} for both insert and normal mode
          delete_session = { 'i', '<C-d>' }, -- mode and key for deleting a session from the picker
          alternate_session = { 'i', '<C-s>' }, -- mode and key for swapping to alternate session from the picker
          copy_session = { 'i', '<C-y>' }, -- mode and key for copying a session from the picker
        },

        ---@type SessionControl
        session_control = {
          control_dir = vim.fn.stdpath 'data' .. '/auto_session/', -- Auto session control dir, for control files, like alternating between two sessions with session-lens
          control_filename = 'session_control.json', -- File name of the session control file
        },
      },
    },
  },

  -- [[ UTIL LIB ]] ---------------------------------------------------------------

  -- [plenary.nvim] - Utility lib used by other plugins
  -- see: `:h help-tag`
  -- link: https://github.com/nvim-lua/plenary.nvim
  { 'nvim-lua/plenary.nvim', branch = 'master', lazy = true },

  -- [[ LEARNING VIM MOTIONS ]] ---------------------------------------------------------------

  -- [hardtime.nvim] - Plugin that helps learn vim motions and keybindings by providing hints
  -- see: `:h hardtime`
  -- link: https://github.com/m4xshen/hardtime.nvim
  {
    'm4xshen/hardtime.nvim',
    branch = 'main',
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>uH', '<cmd>Hardtime toggle<cr>', mode = { 'n' }, desc = 'Toggle Hardtime [uH]', },
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

  {
    'shahshlok/vim-coach.nvim',
    dependencies = {
      'folke/snacks.nvim',
    },
    config = function()
      require('vim-coach').setup()
    end,
    keys = {
      { '<leader>h', '<cmd>VimCoach<cr>', desc = 'Vim Coach' },
    },
  },

  -- [[ TOYS ]] ---------------------------------------------------------------

  -- [wttr.nvim] - Show current weather in lualine or forecast in popup
  -- see: `:h wttr.nvim`
  -- link: https://github.com/lazymaniac/wttr.nvim
  {
    'lazymaniac/wttr.nvim',
    branch = 'main',
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

  -- [store.nvim] - Plugins browser.
  -- see: `:h store.nvim`
  -- link: https://github.com/alex-popov-tech/store.nvim
  {
    'alex-popov-tech/store.nvim',
    cmd = 'Store',
    keys = {
      { '<leader>lP', '<cmd>Store<cr>', desc = 'Open Plugin Store' },
    },
    config = function()
      require('store').setup {
        -- Window dimensions (percentages or absolute)
        width = 0.8,
        height = 0.8,

        -- Layout proportions (must sum to 1.0)
        proportions = {
          list = 0.3, -- 30% for repository list
          preview = 0.7, -- 70% for preview pane
        },

        -- Keybindings (arrays of keys for each action)
        keybindings = {
          help = { '?' }, -- Show help
          close = { 'q', '<esc>', '<c-c>' }, -- Close modal
          filter = { 'f' }, -- Open filter input
          refresh = { 'r' }, -- Refresh data
          open = { '<cr>', 'o' }, -- Open selected repository
          switch_focus = { '<tab>', '<s-tab>' }, -- Switch focus between panes
          sort = { 's' }, -- Sort repositories
        },

        -- Repository display options
        list_fields = { 'full_name', 'pushed_at', 'stars', 'forks', 'issues', 'tags' },
        full_name_limit = 35, -- Max characters for repository names

        -- GitHub API (optional)
        github_token = nil, -- GitHub token for increased rate limits

        -- Behavior
        preview_debounce = 100, -- ms delay for preview updates
        cache_duration = 24 * 60 * 60, -- 24 hours in seconds
        logging = 'off', -- Levels: off, error, warn, log, debug
      }
    end,
  },
}
