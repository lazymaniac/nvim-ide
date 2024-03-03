return {

  -- [[ CODING HELPER ]] ---------------------------------------------------------------

  {
    'nvimdev/lspsaga.nvim',
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
  -- [boole.nvim] - Allows to increment numbers and flip common text to opposite value like true -> false
  {
    'nat-418/boole.nvim',
    event = 'VeryLazy',
    config = function()
      require('boole').setup {
        mappings = {
          increment = '<C-a>',
          decrement = '<C-x>',
        },
        -- User defined loops
        additions = {},
        allow_caps_additions = {
          { 'enable', 'disable' },
        },
      }
    end,
  },

  -- [auto-indent.nvim] - Auto move cursor to match indentation
  -- see: `:h auto-indent.nvim`
  {
    'vidocqh/auto-indent.nvim',
    event = 'VeryLazy',
    opts = {},
  },

  -- [hlargs.nvim] - Highlight function arguments
  -- see: `:h hlargs.nvim`
  {
    'm-demare/hlargs.nvim',
    event = 'VeryLazy',
    config = function()
      require('hlargs').setup()
    end,
  },

  -- [Hypersonic.nvim] - Regex explainer
  -- see: `:h Hypersonic.nvim`
  {
    'tomiis4/Hypersonic.nvim',
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
  {
    'kylechui/nvim-surround',
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
      -- FIX: below mapping is not working
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
      all_targets = vim.list_extend(all_targets, grammar_targets)
      all_targets = vim.list_extend(all_targets, abbreviated_targets)
      all_targets = vim.list_extend(all_targets, keywords_targets)
      local abbreviated_and_grammar_targets = {}
      abbreviated_and_grammar_targets = vim.list_extend(abbreviated_and_grammar_targets, grammar_targets)
      abbreviated_and_grammar_targets = vim.list_extend(abbreviated_and_grammar_targets, abbreviated_targets)
      local mappings = {
        ['<leader>'] = {
          ['S'] = { name = '+[surround]' },
        },
      }
      -- around mappings
      mappings['<leader>']['S']['a'] = { name = 'around' }
      for char, desc in pairs(all_targets) do
        mappings['<leader>']['S']['a'][char] = { name = desc }
        for ichar, target in pairs(abbreviated_and_grammar_targets) do
          mappings['<leader>']['S']['a'][char][ichar] = { "<CMD>call feedkeys('ysa" .. char .. ichar .. "')<CR>", 'ysa' .. char .. ichar .. target }
        end
      end
      -- inner mappings
      mappings['<leader>']['S']['i'] = { name = 'inner' }
      for char, desc in pairs(all_targets) do
        mappings['<leader>']['S']['i'][char] = { name = desc }
        for ichar, target in pairs(all_targets) do
          mappings['<leader>']['S']['i'][char][ichar] = { "<CMD>call feedkeys('ysi" .. char .. ichar .. "')<CR>", 'ysi' .. char .. ichar .. target }
        end
      end
      -- change mappings
      mappings['<leader>']['S']['c'] = { name = 'change' }
      for char, desc in pairs(all_targets) do
        mappings['<leader>']['S']['c'][char] = { name = desc }
        for ichar, target in pairs(all_targets) do
          -- FIXME: escape ''s
          mappings['<leader>']['S']['c'][char][ichar] = { "<CMD>call feedkeys('cs" .. char .. ichar .. "')<CR>", 'cs' .. char .. ichar .. target }
        end
      end
      -- delete mappings
      mappings['<leader>']['S']['d'] = { name = 'delete' }
      for char, target in pairs(all_targets) do
        mappings['<leader>']['S']['d'][char] = { "<CMD>call feedkeys('ds" .. char .. "')<CR>", 'ds' .. char .. target }
      end
      -- line mappings
      mappings['<leader>']['S']['s'] = { name = '[s] line' }
      for char, target in pairs(all_targets) do
        mappings['<leader>']['S']['s'][char] = { "<CMD>call feedkeys('yss" .. char .. "')<CR>", 'yss' .. char .. target }
      end
      require('which-key').register(mappings)
    end,
  },

  -- [ts-node-action] - Additional actions for treesitter nodes.
  -- see: `:h ts-node-action`
  {
    'ckolkey/ts-node-action',
    event = 'VeryLazy',
    dependencies = { 'nvim-treesitter' },
    opts = {},
    -- stylua: ignore
    keys = {
      { '<leader>cn', function() require('ts-node-action').node_action() end, desc = 'Trigger Node Action [cn]' },
    },
  },

  -- [nvim-hlslens] - Helps better glance at matched information, jump between matched instances.
  -- see: `:h nvim-hlslens`
  {
    'kevinhwang91/nvim-hlslens',
    event = 'VeryLazy',
    config = function()
      require('hlslens').setup {}
    end,
  },

  -- [mini.indentscope] - Active indent guide and indent text objects. When browsing
  -- code, this highlights the current level of indentation, and animates the highlighting.
  -- see: `:h mini.indentscope`
  {
    'echasnovski/mini.indentscope',
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
  {
    'HiPhish/rainbow-delimiters.nvim',
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

  -- [nvim-devdocs] - Dev docs
  -- see: `:h nvim-devdocs`
  {
    'luckasRanarison/nvim-devdocs',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim', 'nvim-treesitter/nvim-treesitter' },
    -- stylua: ignore
    keys = {
      { '<leader>ld', '<cmd>DevdocsOpenFloat<cr>', mode = { 'n' }, desc = 'Open DevDocs' },
    },
    config = function()
      require('nvim-devdocs').setup {
        dir_path = vim.fn.stdpath 'data' .. '/devdocs', -- installation directory
        filetypes = {
          -- extends the filetype to docs mappings used by the `DevdocsOpenCurrent` command, the version doesn't have to be specified
          -- scss = "sass",
          -- javascript = { "node", "javascript" }
        },
        float_win = { -- passed to nvim_open_win(), see :h api-floatwin
          relative = 'editor',
          height = 35,
          width = 160,
          border = 'rounded',
        },
        wrap = false, -- text wrap, only applies to floating window
        previewer_cmd = 'glow', -- for example: "glow"
        cmd_args = { '-s', 'dark', '-w', '150' }, -- example using glow: { "-s", "dark", "-w", "80" }
        cmd_ignore = {}, -- ignore cmd rendering for the listed docs
        picker_cmd = true, -- use cmd previewer in picker preview
        picker_cmd_args = { '-s', 'dark', '-w', '100' }, -- example using glow: { "-s", "dark", "-w", "50" }
        mappings = { -- keymaps for the doc buffer
          open_in_browser = '',
        },
        ensure_installed = {}, -- get automatically installed
      }
    end,
  },
}
