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

  -- auto pairs
  {
    'echasnovski/mini.pairs',
    event = 'VeryLazy',
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
    'hedyhli/outline.nvim',
    config = function()
      require('outline').setup {
        outline_window = {
          position = 'right',
          split_command = nil,
          width = 20,
          relative_width = true,
          auto_close = false,
          auto_jump = true,
          jump_highlight_duration = 300,
          center_on_jump = true,
          show_numbers = false,
          show_relative_numbers = false,
          wrap = false,
          -- true/false/'focus_in_outline'/'focus_in_code'.
          show_cursorline = true,
          hide_cursor = true,
          focus_on_open = true,
          winhl = '',
        },
        outline_items = {
          show_symbol_details = true,
          show_symbol_lineno = true,
          highlight_hovered_item = true,
          auto_set_cursor = true,
          auto_update_events = {
            follow = { 'CursorMoved' },
            items = { 'InsertLeave', 'WinEnter', 'BufEnter', 'BufWinEnter', 'TabEnter', 'BufWritePost' },
          },
        },
        guides = {
          enabled = true,
          markers = {
            bottom = '└',
            middle = '├',
            vertical = '│',
          },
        },
        symbol_folding = {
          autofold_depth = 1,
          auto_unfold = {
            hovered = true,
            only = true,
          },
          markers = { '', '' },
        },
        preview_window = {
          auto_preview = false,
          open_hover_on_preview = false,
          width = 50, -- Percentage or integer of columns
          min_width = 50, -- Minimum number of columns
          relative_width = true,
          height = 50, -- Percentage or integer of lines
          min_height = 10, -- Minimum number of lines
          relative_height = true,
          border = 'single',
          winhl = 'NormalFloat:',
          winblend = 0,
          live = false,
        },
        keymaps = {
          show_help = '?',
          close = { '<Esc>', 'q' },
          goto_location = '<Cr>',
          peek_location = 'o',
          goto_and_close = '<S-Cr>',
          restore_location = '<C-g>',
          hover_symbol = '<C-space>',
          toggle_preview = 'K',
          rename_symbol = 'r',
          code_actions = 'a',
          fold = 'h',
          unfold = 'l',
          fold_toggle = '<Tab>',
          fold_toggle_all = '<S-Tab>',
          fold_all = 'W',
          unfold_all = 'E',
          fold_reset = 'R',
          down_and_jump = '<C-j>',
          up_and_jump = '<C-k>',
        },
        providers = {
          priority = { 'lsp', 'coc', 'markdown', 'norg', 'man' },
          lsp = {
            blacklist_clients = {},
          },
          markdown = {
            filetypes = { 'markdown' },
          },
        },
      }
    end,
    keys = {
      {
        '<leader>o',
        '<cmd>Outline<cr>',
        mode = 'n',
        desc = 'Document Symbols',
      },
    },
  },

  {
    'hat0uma/csvview.nvim',
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
          ---@type "highlight" | "border"
          display_mode = 'border',
        },
      }
    end,
  },

  {
    'Chaitanyabsprip/fastaction.nvim',
    opts = {
      dismiss_keys = { 'j', 'k', '<c-c>', 'q' },
      override_function = function(_) end,
      keys = 'qwertyuiopasdfghlzxcvbnm',
      popup = {
        border = 'rounded',
        hide_cursor = true,
        highlight = {
          divider = 'FloatBorder',
          key = 'MoreMsg',
          title = 'Title',
          window = 'NormalFloat',
        },
        title = 'Select code action:',
      },
      priority = {},
      register_ui_select = true,
    },
  },

  -- [boole.nvim] - Allows to flip opposite values, or quickly increase or decrease numbers.
  -- see: `:h boole.nvim`
  -- link: https://github.com/nat-418/boole.nvim
  {
    'nat-418/boole.nvim',
    branch = 'main',
    event = 'VeryLazy',
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
    branch = 'main',
    event = 'VeryLazy',
    config = function()
      require('hlargs').setup()
    end,
  },

  -- [auto-indent.nvim] - Auto move cursor to match indentation
  -- see: `:h auto-indent.nvim`
  -- link: https://github.com/VidocqH/auto-indent.nvim
  {
    'vidocqh/auto-indent.nvim',
    branch = 'main',
    event = 'VeryLazy',
    opts = {},
  },

  -- [rainbow_delimiters.nvim] - Rainbow colored delimiters
  -- see: `:h rainbow-delimiters`
  -- link: https://github.com/HiPhish/rainbow-delimiters.nvim
  {
    'HiPhish/rainbow-delimiters.nvim',
    branch = 'master',
    event = 'VeryLazy',
    config = function()
      local rainbow_delimiters = require 'rainbow-delimiters'
      require('rainbow-delimiters.setup').setup {
        strategy = {
          [''] = rainbow_delimiters.strategy['global'],
          vim = rainbow_delimiters.strategy['local'],
        },
        query = {
          [''] = 'rainbow-delimiters',
          lua = 'rainbow-blocks',
        },
      }
    end,
  },

  -- [leetcode.nvim] - LeetCode integration.
  -- see: `:h leetcode.nvim`
  -- link: https://github.com/kawre/leetcode.nvim
  -- help: To authenticate login to https://www.leetcode.com and get cookie using developer tools.
  {
    'kawre/leetcode.nvim',
    branch = 'master',
    build = ':TSUpdate html',
    cmd = 'Leet',
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-treesitter/nvim-treesitter',
      'rcarriga/nvim-notify',
    },
    opts = {
      arg = 'leetcode.nvim',
      lang = 'java',
      cn = { -- leetcode.cn
        enabled = false,
        translator = true,
        translate_problems = true,
      },
      storage = {
        home = vim.fn.stdpath 'data' .. '/leetcode',
        cache = vim.fn.stdpath 'cache' .. '/leetcode',
      },
      plugins = {
        non_standalone = false,
      },
      logging = true,
      injector = {},
      cache = {
        update_interval = 60 * 60 * 24 * 7,
      },
      console = {
        open_on_runcode = true,
        dir = 'row',
        size = {
          width = '90%',
          height = '75%',
        },
        result = {
          size = '60%',
        },
        testcase = {
          virt_text = true,
          size = '40%',
        },
      },
      description = {
        position = 'left',
        width = '40%',
        show_stats = true,
      },
      hooks = {
        ['enter'] = {},
        ['question_enter'] = {},
        ['leave'] = {},
      },
      keys = {
        toggle = { 'q' },
        confirm = { '<CR>' },
        reset_testcases = 'r',
        use_testcase = 'U',
        focus_testcases = 'H',
        focus_result = 'L',
      },
      theme = {},
      image_support = false,
    },
  },

  {
    'caliguIa/zendiagram.nvim',
    opts = {
      header = 'Diagnostics', -- Float window title
      source = true, -- Whether to display diagnostic source
      relative = 'win', -- "line"|"win" - What the float window's position is relative to
      anchor = 'NE', -- "NE"|"SE"|"SW"|"NW" - When 'relative' is set to "win" this sets the position of the floating window
    },
    config = function(_, opts)
      require('zendiagram').setup(opts)
      vim.diagnostic.open_float = Zendiagram.open

      vim.keymap.set({ 'n', 'x' }, ']d', function()
        vim.diagnostic.jump { count = 1 }
        vim.schedule(function()
          require('zendiagram').open()
          -- or: vim.cmd.Zendiagram('open')
          -- or: Zendiagram.open()
          -- or: vim.diagnostic.open_float() if you have overridden the default function
        end)
      end, { desc = 'Jump to next diagnostic' })

      vim.keymap.set({ 'n', 'x' }, '[d', function()
        vim.diagnostic.jump { count = -1 }
        vim.schedule(function()
          require('zendiagram').open()
          -- or: vim.cmd.Zendiagram('open')
          -- or: Zendiagram.open()
          -- or: vim.diagnostic.open_float() if you have overridden the default function
        end)
      end, { desc = 'Jump to prev diagnostic' })
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
