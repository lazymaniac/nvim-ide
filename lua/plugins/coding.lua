return {

  -- [[ CODING HELPERS ]] ---------------------------------------------------------------

  {
    dir = '~/workspace/voyager.nvim/',
    enabled = false,
    keys = {
      { '<leader>V', '<cmd>VoyagerOpen<cr>', mode = { 'n' }, desc = 'Open Voyager' },
    },
    dependencies = {
      'grapp-dev/nui-components.nvim',
      dependencies = {
        'MunifTanjim/nui.nvim',
      },
    },
  },

  {
    'Chaitanyabsprip/fastaction.nvim',
    event = 'LspAttach',
    opts = {
      dismiss_keys = { 'j', 'k', '<c-c>', 'q' },
      keys = 'asdfghlzxcvbnm',
      popup = {
        border = 'rounded',
        hide_cursor = true,
        title = 'Select one of:',
      },
      priority = {},
    },
  },

  -- auto pairs
  {
    'echasnovski/mini.pairs',
    event = 'InsertEnter',
    opts = {
      -- In which modes mappings from this `config` should be created
      modes = { insert = true, command = true, terminal = false },
      -- Global mappings. Each right hand side should be a pair information, a
      -- table with at least these fields (see more in |MiniPairs.map|):
      -- - <action> - one of 'open', 'close', 'closeopen'.
      -- - <pair> - two character string for pair to be used.
      -- By default pair is not inserted after `\`, quotes are not recognized by
      -- <CR>, `'` does not insert pair after a letter.
      -- Only parts of tables can be tweaked (others will use these defaults).
      mappings = {
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
        ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
        ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },

        [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
        [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
        ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },

        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
        ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
      },
    },
  },

  {
    'hat0uma/csvview.nvim',
    ft = { 'csv', 'tsv' },
    config = function()
      require('csvview').setup {
        parser = {
          async_chunksize = 50,
          delimiter = {
            default = ',',
            ft = {
              tsv = '\t',
            },
          },
          quote_char = '"',
          comments = {
            -- "#",
            -- "--",
            -- "//",
          },
        },
        view = {
          min_column_width = 5,
          spacing = 2,
          display_mode = 'border',
        },
      }
    end,
  },

  -- [boole.nvim] - Allows to flip opposite values, or quickly increase or decrease numbers.
  -- see: `:h boole.nvim`
  -- link: https://github.com/nat-418/boole.nvim
  {
    'nat-418/boole.nvim',
    event = 'BufReadPost',
    branch = 'main',
    config = function()
      require('boole').setup {
        mappings = {
          increment = '<C-a>',
          decrement = '<C-x>',
        },
        additions = {},
        allow_caps_additions = {
          { 'enable', 'disable' },
        },
      }
    end,
  },

  -- [hlargs.nvim] - Highlight function arguments
  -- see: `:h hlargs.nvim`
  -- link: https://github.com/m-demare/hlargs.nvim
  {
    'm-demare/hlargs.nvim',
    event = 'LspAttach',
    branch = 'main',
    opts = {},
  },

  -- [guess-indent.nvim] - Automatically detect and set indentation
  -- link: https://github.com/NMAC427/guess-indent.nvim
  {
    'nmac427/guess-indent.nvim',
    event = 'BufReadPre',
    config = function()
      require('guess-indent').setup {
        auto_cmd = true, -- Set to false to disable automatic execution
        override_editorconfig = false, -- Set to true to override settings set by .editorconfig
        filetype_exclude = { -- A list of filetypes for which the auto command gets disabled
          'netrw',
          'tutor',
        },
        buftype_exclude = { -- A list of buffer types for which the auto command gets disabled
          'help',
          'nofile',
          'terminal',
          'prompt',
        },
        on_tab_options = { -- A table of vim options when tabs are detected
          ['expandtab'] = false,
        },
        on_space_options = { -- A table of vim options when spaces are detected
          ['expandtab'] = true,
          ['tabstop'] = 'detected', -- If the option value is 'detected', The value is set to the automatically detected indent size.
          ['softtabstop'] = 'detected',
          ['shiftwidth'] = 'detected',
        },
      }
    end,
  },

  -- [rainbow_delimiters.nvim] - Rainbow colored delimiters
  -- see: `:h rainbow-delimiters`
  -- link: https://github.com/HiPhish/rainbow-delimiters.nvim
  {
    'HiPhish/rainbow-delimiters.nvim',
    branch = 'master',
    event = 'BufReadPost',
    config = function()
      require('rainbow-delimiters.setup').setup {}
    end,
  },

  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'LspAttach', -- Or `LspAttach`
    priority = 1000, -- needs to be loaded in first
    config = function()
      require('tiny-inline-diagnostic').setup()
      vim.diagnostic.config { virtual_text = false } -- Only if needed in your configuration, if you already have native LSP diagnostics
    end,
  },

  {
    'OXY2DEV/patterns.nvim',
    keys = {
      {
        '<leader>lx',
        '<cmd>Patterns<cr>',
        mode = { 'n', 'v' },
        desc = 'Regex explain',
      },
    },
  },
}
