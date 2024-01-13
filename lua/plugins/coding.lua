return {

  -- [[ CODING HELPER ]] ---------------------------------------------------------------

  -- [boole.nvim] - Allows to increment numbers and flip common text to oposite value like true -> false
  {
    'nat-418/boole.nvim',
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

  -- Preview code actions before applying
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

  -- VSCode like preview of code.
  {
    'dnlhc/glance.nvim',
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

  -- Auto move cursor to match indentation
  {
    'vidocqh/auto-indent.nvim',
    event = 'VeryLazy',
    opts = {},
  },

  -- Highlight method arguments
  {
    'm-demare/hlargs.nvim',
    event = 'VeryLazy',
    config = function()
      require('hlargs').setup()
    end,
  },

  -- Regex explainer
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

  -- Surround text
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

  -- Additional actions for treesitter nodes
  {
    'ckolkey/ts-node-action',
    dependencies = { 'nvim-treesitter' },
    opts = {},
    -- stylua: ignore
    keys = {
      { '<leader>cn', function() require('ts-node-action').node_action() end, desc = 'Trigger Node Action' },
    },
  },
}
