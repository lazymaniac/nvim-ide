return {

  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = false },
      indent = { enabled = true },
      input = { enabled = true },
      lazygit = {
        configure = true,
        -- extra configuration for lazygit that will be merged with the default
        -- snacks does NOT have a full yaml parser, so if you need `"test"` to appear with the quotes
        -- you need to double quote it: `"\"test\""`
        config = {
          os = { editPreset = 'nvim-remote' },
          gui = {
            -- set to an empty string "" to disable icons
            nerdFontsVersion = '3',
          },
        },
        theme_path = vim.fs.normalize(vim.fn.stdpath 'cache' .. '/lazygit-theme.yml'),
        -- Theme for lazygit
        theme = {
          [241] = { fg = 'Special' },
          activeBorderColor = { fg = 'MatchParen', bold = true },
          cherryPickedCommitBgColor = { fg = 'Identifier' },
          cherryPickedCommitFgColor = { fg = 'Function' },
          defaultFgColor = { fg = 'Normal' },
          inactiveBorderColor = { fg = 'FloatBorder' },
          optionsTextColor = { fg = 'Function' },
          searchingActiveBorderColor = { fg = 'MatchParen', bold = true },
          selectedLineBgColor = { bg = 'Visual' }, -- set to `default` to have no background colour
          unstagedChangesColor = { fg = 'DiagnosticError' },
        },
        win = {
          style = 'lazygit',
        },
      },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      quickfile = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      styles = {
        notification = {
          -- wo = { wrap = true } -- Wrap notifications
        },
      },
    },
    keys = {
      {
        '<leader>z',
        function()
          Snacks.zen()
        end,
        desc = 'Toggle Zen Mode',
      },
      {
        '<leader>Z',
        function()
          Snacks.zen.zoom()
        end,
        desc = 'Toggle Zoom',
      },
      {
        '<leader>.',
        function()
          Snacks.scratch()
        end,
        desc = 'Toggle Scratch Buffer',
      },
      {
        '<leader>S',
        function()
          Snacks.scratch.select()
        end,
        desc = 'Select Scratch Buffer',
      },
      {
        '<leader>n',
        function()
          Snacks.notifier.show_history()
        end,
        desc = 'Notification History',
      },
      {
        '<leader>bd',
        function()
          Snacks.bufdelete()
        end,
        desc = 'Delete Buffer',
      },
      {
        '<leader>cR',
        function()
          Snacks.rename.rename_file()
        end,
        desc = 'Rename File',
      },
      {
        '<leader>gB',
        function()
          Snacks.gitbrowse()
        end,
        desc = 'Git Browse',
      },
      {
        '<leader>gb',
        function()
          Snacks.git.blame_line()
        end,
        desc = 'Git Blame Line',
      },
      {
        '<leader>gf',
        function()
          Snacks.lazygit.log_file()
        end,
        desc = 'Lazygit Current File History',
      },
      {
        '<leader>gg',
        function()
          Snacks.lazygit()
        end,
        desc = 'Lazygit',
      },
      {
        '<leader>gl',
        function()
          Snacks.lazygit.log()
        end,
        desc = 'Lazygit Log (cwd)',
      },
      {
        '<leader>un',
        function()
          Snacks.notifier.hide()
        end,
        desc = 'Dismiss All Notifications',
      },
      {
        ']]',
        function()
          Snacks.words.jump(vim.v.count1)
        end,
        desc = 'Next Reference',
        mode = { 'n', 't' },
      },
      {
        '[[',
        function()
          Snacks.words.jump(-vim.v.count1)
        end,
        desc = 'Prev Reference',
        mode = { 'n', 't' },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Create some toggle mappings
          Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
          Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
          Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
          Snacks.toggle.diagnostics():map '<leader>ud'
          Snacks.toggle.line_number():map '<leader>ul'
          Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>uc'
          Snacks.toggle.treesitter():map '<leader>uT'
          Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>ub'
          Snacks.toggle.inlay_hints():map '<leader>uh'
          Snacks.toggle.indent():map '<leader>ug'
          Snacks.toggle.dim():map '<leader>uD'
        end,
      })
    end,
  },

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

  -- [showkeys] - Keys screencaster
  -- see: `:h showkeys`
  -- link: https://github.com/NvChad/showkeys
  {
    'nvchad/showkeys',
    cmd = 'ShowkeysToggle',
    keys = {
      {
        '<leader>lK',
        '<cmd>ShowkeysToggle<cr>',
        mode = { 'n' },
        desc = 'Keys Screencast',
      },
    },
  },

  -- [precognition.nvim] - Show hint with available movements.
  -- see: `:h precognition.nvim`
  -- link: https://github.com/tris203/precognition.nvim
  {
    'tris203/precognition.nvim',
    branch = 'main',
    event = 'VeryLazy',
    keys = {
      { '<leader>lh', '<cmd>lua require("precognition").toggle()<cr>', mode = { 'n', 'v' }, desc = 'Show movement hints [lh]' },
    },
    opts = {
      startVisible = true,
      showBlankVirtLine = true,
      highlightColor = { link = 'Comment' },
      hints = {
        Caret = { text = '^', prio = 2 },
        Dollar = { text = '$', prio = 1 },
        MatchingPair = { text = '%', prio = 5 },
        Zero = { text = '0', prio = 1 },
        w = { text = 'w', prio = 10 },
        b = { text = 'b', prio = 9 },
        e = { text = 'e', prio = 8 },
        W = { text = 'W', prio = 7 },
        B = { text = 'B', prio = 6 },
        E = { text = 'E', prio = 5 },
      },
      gutterHints = {
        G = { text = 'G', prio = 10 },
        gg = { text = 'gg', prio = 9 },
        PrevParagraph = { text = '{', prio = 8 },
        NextParagraph = { text = '}', prio = 8 },
      },
      disabled_fts = {
        'startify',
      },
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

  -- [http-codes.nvim] - Preview http codes
  -- see: `:h http-codes`
  -- link: https://github.com/barrett-ruth/http-codes.nvim?tab=readme-ov-file
  {
    'barrett-ruth/http-codes.nvim',
    config = true,
    -- or 'nvim-telescope/telescope.nvim'
    dependencies = 'ibhagwan/fzf-lua',
    keys = {
      { '<leader>lH', '<cmd>HTTPCodes<cr>', desc = 'HTTP Codes [lH]' },
    },
  },
}
