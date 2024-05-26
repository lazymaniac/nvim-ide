return {

  -- [[ CODING HELPERS ]] ---------------------------------------------------------------

  {
    dir = '~/workspace/voyager.nvim/',
  },

  -- [lspsaga.nvim] - Improves LSP experience in neovim.
  -- see: `:h lspsaga.nvim`
  -- link: https://github.com/nvimdev/lspsaga.nvim
  {
    'nvimdev/lspsaga.nvim',
    branch = 'main',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      require('lspsaga').setup {
        code_action = {
          num_shortcut = false,
          show_server_name = true,
          extend_gitsigns = false,
          only_in_cursor = false,
          max_height = 0.2,
          keys = {
            quit = 'q',
            exec = '<CR>',
          },
        },
        lightbulb = {
          enable = true,
          sign = false,
          debounce = 0,
          sign_priority = 40,
          virtual_text = true,
          enable_in_insert = false,
        },
        scroll_preview = {
          scroll_down = '<C-f>',
          scroll_up = '<C-b>',
        },
        request_timeout = 2000,
        finder = {
          max_height = 0.6,
          left_width = 0.3,
          methods = {},
          default = 'ref+imp',
          layout = 'float',
          silent = false,
          filter = {},
          fname_sub = nil,
          sp_inexist = false,
          sp_global = false,
          ly_botright = false,
          keys = {
            shuttle = '[w',
            toggle_or_open = 'o',
            vsplit = 's',
            split = 'i',
            tabe = 't',
            tabnew = 'r',
            quit = 'q',
            close = '<C-c>k',
          },
        },
        symbol_in_winbar = {
          enable = false,
          separator = ' › ',
          hide_keyword = true,
          ignore_patterns = nil,
          show_file = false,
          folder_level = 1,
          color_mode = true,
          dely = 300,
        },
        callhierarchy = {
          layout = 'float',
          left_width = 0.2,
          keys = {
            edit = 'o',
            vsplit = 's',
            split = 'i',
            tabe = 't',
            close = '<C-c>k',
            quit = 'q',
            shuttle = '[w',
            toggle_or_req = 'u',
          },
        },
        implement = {
          enable = true,
          sign = true,
          lang = {},
          virtual_text = true,
          priority = 100,
        },
        beacon = {
          enable = true,
          frequency = 7,
        },
      }
    end,
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

  -- [auto-indent.nvim] - Auto move cursor to match indentation
  -- see: `:h auto-indent.nvim`
  -- link: https://github.com/VidocqH/auto-indent.nvim
  {
    'vidocqh/auto-indent.nvim',
    branch = 'main',
    event = 'VeryLazy',
    opts = {},
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

  -- [Hypersonic.nvim] - Regex writing and testing
  -- see: `:h Hypersonic.nvim`
  -- link: https://github.com/tomiis4/hypersonic.nvim
  {
    'tomiis4/Hypersonic.nvim',
    branch = 'main',
    event = 'CmdlineEnter',
    cmd = 'Hypersonic',
    -- stylua: ignore
    keys = {
      { '<leader>cE', '<cmd>Hypersonic<cr>', desc = 'Regex explain [cE]' },
    },
    config = function()
      require('hypersonic').setup {
        border = 'rounded',
        winblend = 0,
        add_padding = true,
        hl_group = 'Keyword',
        wrapping = '"',
        enable_cmdline = true,
      }
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
      -- Setup keymappings
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
          mappings['<leader>'][root_key]['a'][char][ichar] = { '<CMD>call feedkeys("ysa\\' .. char .. '\\' .. ichar .. '")<CR>', 'ysa' .. char .. ichar .. target }
        end
      end
      -- inner mappings
      mappings['<leader>'][root_key]['i'] = { name = '+[inner]' }
      for char, desc in pairs(all_targets) do
        mappings['<leader>'][root_key]['i'][char] = { name = desc }
        for ichar, target in pairs(all_targets) do
          mappings['<leader>'][root_key]['i'][char][ichar] = { '<CMD>call feedkeys("ysi\\' .. char .. '\\' .. ichar .. '")<CR>', 'ysi' .. char .. ichar .. target }
        end
      end
      -- change mappings
      mappings['<leader>'][root_key]['c'] = { name = '+[change]' }
      for char, desc in pairs(all_targets) do
        mappings['<leader>'][root_key]['c'][char] = { name = desc }
        for ichar, target in pairs(all_targets) do
          mappings['<leader>'][root_key]['c'][char][ichar] = { '<CMD>call feedkeys("cs\\' .. char .. '\\' .. ichar .. '")<CR>', 'cs' .. char .. ichar .. target }
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

  -- [nvim-hlslens] - Highlights matched search, jump between matched instances.
  -- see: `:h nvim-hlslens`
  -- link: https://github.com/kevinhwang91/nvim-hlslens
  {
    'kevinhwang91/nvim-hlslens',
    branch = 'main',
    event = 'VeryLazy',
    config = function()
      require('hlslens').setup {
        build_position_cb = function(plist, _, _, _)
          require('scrollbar.handlers.search').handler.show(plist.start_pos)
        end,
      }
      vim.cmd [[
        augroup scrollbar_search_hide
            autocmd!
            autocmd CmdlineLeave : lua require('scrollbar.handlers.search').handler.hide()
        augroup END
    ]]
    end,
  },

  -- [mini.indentscope] - Visual guide for indentations.
  -- see: `:h mini.indentscope`
  -- link: https://github.com/echasnovski/mini.indentscope
  {
    'echasnovski/mini.indentscope',
    branch = 'main',
    event = 'VeryLazy',
    opts = {
      draw = {
        -- Delay (in ms) between event and start of drawing scope indicator
        delay = 50,
        -- Animation rule for scope's first drawing. A function which, given
        -- next and total step numbers, returns wait time (in ms). See
        -- |MiniIndentscope.gen_animation| for builtin options. To disable
        -- animation, use `require('mini.indentscope').gen_animation.none()`.
        -- animation = --<function: implements constant 20ms between steps>,
        -- Symbol priority. Increase to display on top of more symbols.
        priority = 2,
      },
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Textobjects
        object_scope = 'ii',
        object_scope_with_border = 'ai',
        -- Motions (jump to respective border line; if not present - body line)
        goto_top = '[i',
        goto_bottom = ']i',
      },
      -- Options which control scope computation
      options = {
        -- Type of scope's border: which line(s) with smaller indent to
        -- categorize as border. Can be one of: 'both', 'top', 'bottom', 'none'.
        border = 'both',
        -- Whether to use cursor column when computing reference indent.
        -- Useful to see incremental scopes with horizontal cursor movements.
        indent_at_cursor = true,
        -- Whether to first check input line to be a border of adjacent scope.
        -- Use it if you want to place cursor on function header to get scope of
        -- its body.
        try_as_border = true,
      },
      symbol = '│', -- Which character to use for drawing scope indicator
    },
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'help',
          'alpha',
          'dashboard',
          'neo-tree',
          'Trouble',
          'trouble',
          'lazy',
          'mason',
          'notify',
          'toggleterm',
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
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
      'nvim-tree/nvim-web-devicons',
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
