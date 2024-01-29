return {

  -- [[ CODING HELPER ]] ---------------------------------------------------------------

  -- [boole.nvim] - Allows to increment numbers and flip common text to oposite value like true -> false
  {
    'nat-418/boole.nvim',
    event = 'VeryLazy',
    opts = {
      mappings = {
        increment = '<C-a>',
        decrement = '<C-x>',
      },
      -- User defined loops
      additions = {},
      allow_caps_additions = {
        { 'enable', 'disable' },
        -- enable → disable
        -- Enable → Disable
        -- ENABLE → DISABLE
      },
    },
    config = function(_, opts)
      require('boole').setup(opts)
    end,
  },

  -- [actions-preview.nvim] - Preview code actions before applying
  -- see: `:h actions-preview.nvim`
  {
    'aznhe21/actions-preview.nvim',
    event = 'VeryLazy',
    config = function()
      require('actions-preview').setup {
        -- options for vim.diff(): https://neovim.io/doc/user/lua.html#vim.diff()
        diff = {
          ctxlen = 4,
        },
        -- priority list of preferred backend
        backend = {
          'nui',
        },
        -- options for nui.nvim components
        nui = {
          -- component direction. "col" or "row"
          dir = 'row',
          -- options for nui Layout component: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/layout
          layout = {
            position = '50%',
            size = {
              width = '80%',
              height = '70%',
            },
            min_width = 40,
            min_height = 10,
            relative = 'editor',
          },
          -- options for preview area: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup
          preview = {
            size = '60%',
            border = {
              style = 'rounded',
              padding = { 0, 1 },
            },
          },
          -- options for selection area: https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/menu
          select = {
            size = '40%',
            border = {
              style = 'rounded',
              padding = { 0, 1 },
            },
          },
        },
      }
    end,
    -- stylua: ignore
    keys = {
      { '<leader>cq', function() require('actions-preview').code_actions() end, desc = 'Code Action - Preview' },
    },
  },

  -- [glance.nvim] - Preview code like in VSCode
  -- see: `:h glance.nvim`
  {
    'dnlhc/glance.nvim',
    event = 'VeryLazy',
    config = function()
      require('glance').setup()
    end,
    -- stylua: ignore
    keys = {
      { 'gpd', '<cmd>Glance definitions<CR>', desc = 'Preview Definition' },
      { 'gpt', '<cmd>Glance type_definitions<CR>', desc = 'Preview Type Definition' },
      { 'gpi', '<cmd>Glance implementations<CR>', desc = 'Preview Implementation' },
      { 'gpr', '<cmd>Glance references<CR>', desc = 'Preview References' },
    },
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
    config = function()
      require('hypersonic').setup {
        ---@type 'none'|'single'|'double'|'rounded'|'solid'|'shadow'|table
        border = 'rounded',
        ---@type number 0-100
        winblend = 0,
        ---@type boolean
        add_padding = true,
        ---@type string
        hl_group = 'Keyword',
        ---@type string
        wrapping = '"',
        ---@type boolean
        enable_cmdline = true,
      }
    end,
    -- stylua: ignore
    keys = {
      { '<leader>cR', '<cmd>Hypersonic<cr>', desc = 'Regex explain' },
    },
  },

  -- [nvim-surround] - Superior text surroundings. Add, remove, replace.
  -- see: `:h nvim-surround`
  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
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
      { '<leader>cn', function() require('ts-node-action').node_action() end, desc = 'Trigger Node Action' },
    },
  },

  -- [nvim-hlslens] - Helps better glance at matched information, jump between matched instances.
  -- see: `:h nvim-hlslens`
  {
    'kevinhwang91/nvim-hlslens',
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
      -- require('hlslens').setup() is not required
      require('scrollbar.handlers.search').setup {
        -- hlslens config overrides
      }
    end,
  },

  -- [mini.indentscope] - Active indent guide and indent text objects. When browsing
  -- code, this highlights the current level of indentation, and animates the highlighting.
  -- see: `:h mini.indentscope`
  {
    'echasnovski/mini.indentscope',
    version = false, -- wait till new 0.7.0 release to put it back on semver
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

  -- [nvim-lightbulb] - Show lightbulb where code action is available
  -- see: `:h lightbulb`
  {
    'kosayoda/nvim-lightbulb',
    event = 'VeryLazy',
    config = function()
      require('nvim-lightbulb').setup {
        autocmd = { enabled = true },
      }
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

  -- [dropbar.nvim] - Interactive breadcrumbs bar
  -- see: `:h dropbar.nvim`
  -- TODO: Tweak config
  {
    'Bekaboo/dropbar.nvim',
    enabled = not vim.g.neovide,
    -- optional, but required for fuzzy finder support
    dependencies = { 'nvim-telescope/telescope-fzf-native.nvim' },
  },
  -- [nvim-devdocs] - Dev docs
  -- see: `:h nvim-devdocs`
  -- TODO: Tweak config
  {
    'luckasRanarison/nvim-devdocs',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim', 'nvim-treesitter/nvim-treesitter' },
    opts = {},
  },
}
