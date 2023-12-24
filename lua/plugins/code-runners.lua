return {

  -- Run part of code
  {
    'michaelb/sniprun',
    branch = 'master',
    build = 'sh install.sh',
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65
    opts = {
      selected_interpreters = {}, --# use those instead of the default for the current filetype
      repl_enable = {}, --# enable REPL-like behavior for the given interpreters
      repl_disable = {}, --# disable REPL-like behavior for the given interpreters

      interpreter_options = { --# interpreter-specific options, see doc / :SnipInfo <name>

        --# use the interpreter name as key
        GFM_original = {
          use_on_filetypes = { 'markdown.pandoc' }, --# the 'use_on_filetypes' configuration key is
          --# available for every interpreter
        },
        Python3_original = {
          error_truncate = 'auto', --# Truncate runtime errors 'long', 'short' or 'auto'
          --# the hint is available for every interpreter
          --# but may not be always respected
        },
      },

      --# you can combo different display modes as desired and with the 'Ok' or 'Err' suffix
      --# to filter only sucessful runs (or errored-out runs respectively)
      display = {
        'Classic', --# display results in the command-line  area
        'VirtualTextOk', --# display ok results as virtual text (multiline is shortened)

        -- "VirtualText",             --# display results as virtual text
        -- "TempFloatingWindow",      --# display results in a floating window
        -- "LongTempFloatingWindow",  --# same as above, but only long results. To use with VirtualText[Ok/Err]
        -- "Terminal",                --# display results in a vertical split
        -- "TerminalWithCode",        --# display results and code history in a vertical split
        -- "NvimNotify",              --# display with the nvim-notify plugin
        -- "Api"                      --# return output to a programming interface
      },

      live_display = { 'VirtualTextOk' }, --# display mode used in live_mode

      display_options = {
        terminal_scrollback = vim.o.scrollback, --# change terminal display scrollback lines
        terminal_line_number = false, --# whether show line number in terminal window
        terminal_signcolumn = false, --# whether show signcolumn in terminal window
        terminal_persistence = true, --# always keep the terminal open (true) or close it at every occasion (false)
        terminal_position = 'vertical', --# or "horizontal", to open as horizontal split instead of vertical split
        terminal_width = 45, --# change the terminal display option width (if vertical)
        terminal_height = 20, --# change the terminal display option height (if horizontal)
        notification_timeout = 5, --# timeout for nvim_notify output
      },

      --# You can use the same keys to customize whether a sniprun producing
      --# no output should display nothing or '(no output)'
      show_no_output = {
        'Classic',
        'TempFloatingWindow', --# implies LongTempFloatingWindow, which has no effect on its own
      },

      --# customize highlight groups (setting this overrides colorscheme)
      snipruncolors = {
        SniprunVirtualTextOk = { bg = '#66eeff', fg = '#000000', ctermbg = 'Cyan', cterfg = 'Black' },
        SniprunFloatingWinOk = { fg = '#66eeff', ctermfg = 'Cyan' },
        SniprunVirtualTextErr = { bg = '#881515', fg = '#000000', ctermbg = 'DarkRed', cterfg = 'Black' },
        SniprunFloatingWinErr = { fg = '#881515', ctermfg = 'DarkRed' },
      },

      live_mode_toggle = 'off', --# live mode toggle, see Usage - Running for more info

      --# miscellaneous compatibility/adjustement settings
      inline_messages = false, --# boolean toggle for a one-line way to display messages
      --# to workaround sniprun not being able to display anything

      borders = 'single', --# display borders around floating windows
      --# possible values are 'none', 'single', 'double', or 'shadow'
    },
    config = function()
      require('sniprun').setup {
        -- your options
      }
    end,
    keys = {
      {
        '<leader>rR',
        '<cmd>SnipRun<cr>',
        mode = { 'n', 'v' },
        desc = 'SnipRun',
      },
    },
  },

  {
    'folke/which-key.nvim',
    opts = {
      defaults = {
        ['<leader>r'] = { name = '+run' },
      },
    },
  },

  -- JUPYTER NOTEBOOK
  -- For below plugins to run, first install jupytext with conda: conda install jupytext -c conda-forge
  {
    'GCBallesteros/NotebookNavigator.nvim',
    event = 'VeryLazy',
    dependencies = {
      'echasnovski/mini.comment',
      'hkupty/iron.nvim', -- repl provider
      -- "akinsho/toggleterm.nvim", -- alternative repl provider
      'anuvyklack/hydra.nvim',
    },
    opts = {
      -- Code cell marker. Cells start with the marker and end either at the beginning
      -- of the next cell or at the end of the file.
      -- By default, uses language-specific double percent comments like `# %%`.
      -- This can be overridden for each language with this setting.
      cell_markers = {
        -- python = "# %%",
      },
      -- If not `nil` the keymap defined in the string will activate the hydra head.
      -- If you don't want to use hydra you don't need to install it either.
      activate_hydra_keys = nil,
      -- If `true` a hint panel will be shown when the hydra head is active. If `false`
      -- you get a minimalistic hint on the command line.
      show_hydra_hint = true,
      -- Mappings while the hydra head is active.
      -- Any of the mappings can be set to "nil", the string! Not the value! to unamp it
      hydra_keys = {
        comment = 'c',
        run = 'X',
        run_and_move = 'x',
        move_up = 'k',
        move_down = 'j',
        add_cell_before = 'a',
        add_cell_after = 'b',
      },
      -- The repl plugin with which to interface
      -- Current options: "iron" for iron.nvim, "toggleterm" for toggleterm.nvim,
      -- or "auto" which checks which of the above are installed
      repl_provider = 'auto',
      -- Syntax based highlighting. If you don't want to install mini.hipattners or
      -- enjoy a more minimalistic look
      syntax_highlight = false,
      -- (Optional) for use with `mini.hipatterns` to highlight cell markers
      cell_highlight_group = 'Folded',
    },
    config = function()
      local nn = require 'notebook-navigator'
      nn.setup { activate_hydra_keys = '<leader>h' }
    end,
    keys = {
      {
        ']j',
        function()
          require('notebook-navigator').move_cell 'd'
        end,
        mode = { 'n', 'v' },
        desc = 'Move jupyter cell down',
      },
      {
        '[j',
        function()
          require('notebook-navigator').move_cell 'u'
        end,
        mode = { 'n', 'v' },
        desc = 'Move jupyter cell up',
      },
      {
        '<leader>rN',
        "<cmd>lua require('notebook-navigator').run_cell()<cr>",
        mode = { 'n', 'v' },
        desc = 'Run jupyter cell',
      },
      {
        '<leader>rn',
        "<cmd>lua require('notebook-navigator').run_and_move()<cr>",
        mode = { 'n', 'v' },
        desc = 'Run jupyter cell and move',
      },
      {
        '<leader>rA',
        "<cmd>lua require('notebook-navigator').run_all_cells()<cr>",
        mode = { 'n', 'v' },
        desc = 'Run all jupyter cells',
      },
      {
        '<leader>rB',
        "<cmd>lua require('notebook-navigator').run_cells_below()<cr>",
        mode = { 'n', 'v' },
        desc = 'Run jupyter cells below',
      },
      {
        '<leader>cC',
        "<cmd>lua require('notebook-navigator').comment_cell()<cr>",
        mode = { 'n', 'v' },
        desc = 'Comment jupyter cell',
      },
      {
        '<leader>cD',
        "<cmd>lua require('notebook-navigator').add_cell_below()<cr>",
        mode = { 'n', 'v' },
        desc = 'Add jupyter cell below',
      },
      {
        '<leader>cU',
        "<cmd>lua require('notebook-navigator').add_cell_above()<cr>",
        mode = { 'n', 'v' },
        desc = 'Add jupyter cell above',
      },
      {
        '<leader>cM',
        "<cmd>lua require('notebook-navigator').merge_cell()<cr>",
        mode = { 'n', 'v' },
        desc = 'Merge jupyter cell',
      },
    },
  },
  {
    'GCBallesteros/jupytext.nvim',
    config = true,
    -- Depending on your nvim distro or config you may need to make the loading not lazy
    lazy = false,
  },
  {
    'echasnovski/mini.hipatterns',
    event = 'VeryLazy',
    dependencies = { 'GCBallesteros/NotebookNavigator.nvim' },
    opts = function()
      local nn = require 'notebook-navigator'

      local opts = { highlighters = { cells = nn.minihipatterns_spec } }
      return opts
    end,
  },
}
