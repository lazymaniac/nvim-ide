return {

  -- [[ CODE RUNNERS ]] ---------------------------------------------------------------

  -- Add which-key group for code runners
  {
    'folke/which-key.nvim',
    opts = {
      defaults = {
        ['<leader>r'] = { name = '+[run]' },
        ['<leader>j'] = { name = '+[jupyter]' },
      },
    },
  },

  -- [sniprun] - Run lines or part of code without running whole program
  -- see: `:h sniprun`
  {
    'michaelb/sniprun',
    event = 'VeryLazy',
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65
    build = 'sh install.sh',
    -- stylua: ignore
    keys = {
      { '<leader>rl', '<cmd>SnipRun<cr>', mode = { 'n' }, desc = 'Run line of code [rl]' },
      { '<leader>rs', '<cmd>SnipRun<cr>', mode = { 'v' }, desc = 'Run selected code [rs]' },
      { '<leader>rf', '<cmd>%SnipRun<cr>', mode = { 'n', 'v' }, desc = 'Run current file [rf]' },
    },
    config = function()
      require('sniprun').setup {
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
        --# to filter only successful runs (or errored-out runs respectively)
        display = {
          -- 'Classic', --# display results in the command-line  area
          -- 'VirtualTextOk', --# display ok results as virtual text (multiline is shortened)
          'VirtualText', --# display results as virtual text
          -- "TempFloatingWindow",      --# display results in a floating window
          -- "LongTempFloatingWindow",  --# same as above, but only long results. To use with VirtualText[Ok/Err]
          -- "Terminal",                --# display results in a vertical split
          -- "TerminalWithCode",        --# display results and code history in a vertical split
          'NvimNotify', --# display with the nvim-notify plugin
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
        live_mode_toggle = 'off', --# live mode toggle, see Usage - Running for more info
        --# miscellaneous compatibility/adjustement settings
        inline_messages = false, --# boolean toggle for a one-line way to display messages
        --# to workaround sniprun not being able to display anything
        borders = 'single', --# display borders around floating windows
        --# possible values are 'none', 'single', 'double', or 'shadow'
      }
    end,
  },

  -- [jupytext.nvim] - Automatically convert Jopyter notebooks to python files.
  -- see: `:h jupytext.nvim`
  {
    'GCBallesteros/jupytext.nvim',
    event = 'VeryLazy',
    config = true,
  },

  -- Use mini.hipatterns for Jupyter cells
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

  -- [molten-nvim] - REPL for jupyter notebook
  -- see: `:h molten-nvim`
  {
    'benlubas/molten-nvim',
    event = 'VeryLazy',
    dependencies = { '3rd/image.nvim' },
    build = ':UpdateRemotePlugins',
    init = function()
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_use_border_highlights = true
      -- I find auto open annoying, keep in mind setting this option will require setting
      -- a keybind for `:noautocmd MoltenEnterOutput` to open the output again
      vim.g.molten_auto_open_output = false
      -- optional, I like wrapping. works for virt text and the output window
      vim.g.molten_wrap_output = true
      -- Output as virtual text. Allows outputs to always be shown, works with images, but can
      -- be buggy with longer images
      vim.g.molten_virt_text_output = true
      -- this will make it so the output shows up below the \`\`\` cell delimiter
      vim.g.molten_virt_lines_off_by_1 = true
      -- add a few new things
      -- don't change the mappings (unless it's related to your bug)
      vim.keymap.set('n', '<localleader>e', ':MoltenEvaluateOperator<CR>', { desc = 'evaluate operator', silent = true })
      vim.keymap.set('n', '<localleader>os', ':noautocmd MoltenEnterOutput<CR>', { desc = 'open output window', silent = true })
      vim.keymap.set('n', '<localleader>rr', ':MoltenReevaluateCell<CR>', { desc = 're-eval cell', silent = true })
      vim.keymap.set('v', '<localleader>r', ':<C-u>MoltenEvaluateVisual<CR>gv', { desc = 'execute visual selection', silent = true })
      vim.keymap.set('n', '<localleader>oh', ':MoltenHideOutput<CR>', { desc = 'close output window', silent = true })
      vim.keymap.set('n', '<localleader>md', ':MoltenDelete<CR>', { desc = 'delete Molten cell', silent = true })

      -- if you work with html outputs:
      vim.keymap.set('n', '<localleader>mx', ':MoltenOpenInBrowser<CR>', { desc = 'open output in browser', silent = true })
    end,
  },

  {
    'quarto-dev/quarto-nvim',
    dependencies = {
      {
        'jmbuhr/otter.nvim',
        dependencies = {
          { 'neovim/nvim-lspconfig' },
        },
        opts = {
          buffers = {
            -- if set to true, the filetype of the otterbuffers will be set.
            -- otherwise only the autocommand of lspconfig that attaches
            -- the language server will be executed without setting the filetype
            set_filetype = true,
          },
        },
      },
    },
    opts = {
      lspFeatures = {
        languages = { 'r', 'python', 'julia', 'bash', 'lua', 'html', 'dot' },
      },
    },
  },
}
