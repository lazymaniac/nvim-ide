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
    'mhanberg/output-panel.nvim',
    version = '*',
    event = 'VeryLazy',
    config = function()
      require('output_panel').setup {
        max_buffer_size = 5000, -- default
      }
    end,
    cmd = { 'OutputPanel' },
    keys = {
      {
        '<leader>lo',
        vim.cmd.OutputPanel,
        mode = 'n',
        desc = 'Toggle the output panel',
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
          width = 25,
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
        '<leader>cs',
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

  -- [nvim-surround] - Superior text surroundings. Add, remove, replace.
  -- see: `:h nvim-surround`
  -- link: https://github.com/kylechui/nvim-surround
  {
    'kylechui/nvim-surround',
    branch = 'main',
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup {
        keymaps = {
          insert = '<C-g>s',
          insert_line = '<C-g>S',
          normal = 'ys',
          normal_cur = 'yss',
          normal_line = 'yS',
          normal_cur_line = 'ySS',
          visual = 'S',
          visual_line = 'gS',
          delete = 'ds',
          change = 'cs',
          change_line = 'cS',
        },
        aliases = {
          ['a'] = '>',
          ['b'] = ')',
          ['B'] = '}',
          ['r'] = ']',
          ['q'] = { '"', "'", '`' },
          ['s'] = { '}', ']', ')', '>', '"', "'", '`' },
        },
        highlight = {
          duration = 0,
        },
        move_cursor = 'begin',
        indent_lines = function(start, stop)
          local b = vim.bo
          -- Only re-indent the selection if a formatter is set up already
          if start < stop and (b.equalprg ~= '' or b.indentexpr ~= '' or b.cindent or b.smartindent or b.lisp) then
            vim.cmd(string.format('silent normal! %dG=%dG', start, stop))
          end
        end,
      }
      -- Setup keymappings. Code borrowed from surround-ui
      local root_key = 'S'
      local grammar_targets = {
        ['['] = '',
        [']'] = '',
        ['('] = '',
        [')'] = '',
        ['{'] = '',
        ['}'] = '',
        ['<'] = '',
        ['>'] = '',
        ['`'] = '',
        ["'"] = '',
        ['"'] = '',
      }
      local abbreviated_targets = {
        ['b'] = ' [bracket]',
      }
      local keywords_targets = {
        ['w'] = ' [word]',
        ['W'] = ' [WORD]',
        ['f'] = ' [function]',
        ['q'] = ' [quote]',
      }
      local all_targets = {}
      all_targets = vim.tbl_extend('error', all_targets, grammar_targets, abbreviated_targets, keywords_targets)
      local abbreviated_and_grammar_targets = {}
      abbreviated_and_grammar_targets = vim.tbl_extend('error', abbreviated_and_grammar_targets, grammar_targets, abbreviated_targets)
      local mappings = {
        ['<leader>'] = {
          [root_key] = { name = '+[surround]' },
        },
      }
      -- around mappings
      mappings['<leader>'][root_key]['a'] = { name = '+[around]' }
      for char, desc in pairs(all_targets) do
        mappings['<leader>'][root_key]['a'][char] = { name = desc }
        for ichar, target in pairs(abbreviated_and_grammar_targets) do
          mappings['<leader>'][root_key]['a'][char][ichar] =
            { '<CMD>call feedkeys("ysa\\' .. char .. '\\' .. ichar .. '")<CR>', 'ysa' .. char .. ichar .. target }
        end
      end
      -- inner mappings
      mappings['<leader>'][root_key]['i'] = { name = '+[inner]' }
      for char, desc in pairs(all_targets) do
        mappings['<leader>'][root_key]['i'][char] = { name = desc }
        for ichar, target in pairs(all_targets) do
          mappings['<leader>'][root_key]['i'][char][ichar] =
            { '<CMD>call feedkeys("ysi\\' .. char .. '\\' .. ichar .. '")<CR>', 'ysi' .. char .. ichar .. target }
        end
      end
      -- change mappings
      mappings['<leader>'][root_key]['c'] = { name = '+[change]' }
      for char, desc in pairs(all_targets) do
        mappings['<leader>'][root_key]['c'][char] = { name = desc }
        for ichar, target in pairs(all_targets) do
          mappings['<leader>'][root_key]['c'][char][ichar] =
            { '<CMD>call feedkeys("cs\\' .. char .. '\\' .. ichar .. '")<CR>', 'cs' .. char .. ichar .. target }
        end
      end
      -- delete mappings
      mappings['<leader>'][root_key]['d'] = { name = '+[delete]' }
      for char, target in pairs(all_targets) do
        mappings['<leader>'][root_key]['d'][char] = { '<CMD>call feedkeys("ds\\' .. char .. '")<CR>', 'ds' .. char .. target }
      end
      -- line mappings
      mappings['<leader>'][root_key]['s'] = { name = '+[line]' }
      for char, target in pairs(all_targets) do
        mappings['<leader>'][root_key]['s'][char] = { '<CMD>call feedkeys("yss\\' .. char .. '")<CR>', 'yss' .. char .. target }
      end
      require('which-key').register(mappings)
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
}
