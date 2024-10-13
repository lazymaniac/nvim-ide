vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  callback = function()
    vim.cmd [[Trouble qflist open]]
  end,
})

return {

  -- [[ KEYMAPS ]] ---------------------------------------------------------------

  -- [which-key.nvim] - Autocompletion for keymaps
  -- see: `:h which-key`
  -- link: https://github.com/folke/which-key.nvim
  {
    'folke/which-key.nvim',
    branch = 'main',
    event = 'VeryLazy',
    opts = {
      ---@type false | "classic" | "modern" | "helix"
      preset = 'modern',
      -- Delay before showing the popup. Can be a number or a function that returns a number.
      ---@type number | fun(ctx: { keys: string, mode: string, plugin?: string }):number
      delay = 200,
      ---@param mapping wk.Mapping
      filter = function(mapping)
        -- example to exclude mappings without a description
        -- return mapping.desc and mapping.desc ~= ""
        return true
      end,
      --- You can add any mappings here, or use `require('which-key').add()` later
      ---@type wk.Spec
      spec = {},
      -- show a warning when issues were detected with your mappings
      notify = false,
      -- Enable/disable WhichKey for certain mapping modes
      triggers = {
        { '<auto>', mode = 'nxsot' },
      },
      plugins = {
        marks = true, -- shows a list of your marks on ' and `
        registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
        -- the presets plugin, adds help for a bunch of default keybindings in Neovim
        -- No actual key bindings are created
        spelling = {
          enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
          suggestions = 20, -- how many suggestions should be shown in the list?
        },
        presets = {
          operators = true, -- adds help for operators like d, y, ...
          motions = true, -- adds help for motions
          text_objects = true, -- help for text objects triggered after entering an operator
          windows = true, -- default bindings on <c-w>
          nav = true, -- misc bindings to work with windows
          z = true, -- bindings for folds, spelling and others prefixed with z
          g = true, -- bindings for prefixed with g
        },
      },
      ---@type wk.Win.opts
      win = {
        -- don't allow the popup to overlap with the cursor
        no_overlap = true,
        -- width = 1,
        -- height = { min = 4, max = 25 },
        -- col = 0,
        -- row = math.huge,
        -- border = "none",
        padding = { 1, 2 }, -- extra window padding [top/bottom, right/left]
        title = true,
        title_pos = 'center',
        zindex = 1000,
        -- Additional vim.wo and vim.bo options
        bo = {},
        wo = {
          -- winblend = 10, -- value between 0-100 0 for fully opaque and 100 for fully transparent
        },
      },
      layout = {
        width = { min = 20 }, -- min and max width of the columns
        spacing = 3, -- spacing between columns
        align = 'left', -- align columns left, center or right
      },
      keys = {
        scroll_down = '<c-d>', -- binding to scroll down inside the popup
        scroll_up = '<c-u>', -- binding to scroll up inside the popup
      },
      ---@type (string|wk.Sorter)[]
      --- Mappings are sorted using configured sorters and natural sort of the keys
      --- Available sorters:
      --- * local: buffer-local mappings first
      --- * order: order of the items (Used by plugins like marks / registers)
      --- * group: groups last
      --- * alphanum: alpha-numerical first
      --- * mod: special modifier keys last
      --- * manual: the order the mappings were added
      --- * case: lower-case first
      sort = { 'local', 'order', 'group', 'alphanum', 'mod' },
      ---@type number|fun(node: wk.Node):boolean?
      expand = 0, -- expand groups when <= n mappings
      -- expand = function(node)
      --   return not node.desc -- expand all nodes without a description
      -- end,
      ---@type table<string, ({[1]:string, [2]:string}|fun(str:string):string)[]>
      replace = {
        key = {
          function(key)
            return require('which-key.view').format(key)
          end,
          -- { "<Space>", "SPC" },
        },
        desc = {
          { '<Plug>%((.*)%)', '%1' },
          { '^%+', '' },
          { '<[cC]md>', '' },
          { '<[cC][rR]>', '' },
          { '<[sS]ilent>', '' },
          { '^lua%s+', '' },
          { '^call%s+', '' },
          { '^:%s*', '' },
        },
      },
      show_help = true, -- show a help message in the command line for using WhichKey
      show_keys = true, -- show the currently pressed key and its label as a message in the command line
      debug = false, -- enable wk.log in the current directory
    },
    config = function(_, opts)
      local wk = require 'which-key'
      wk.setup(opts)
      local defaults = {
        { ']', group = '+[next]' },
        { '[', group = '+[prev]' },
        { '<leader><tab>', group = '+[tabs]' },
        { '<leader>b', group = '+[buffer]' },
        { '<leader>c', group = '+[code]' },
        { '<leader>d', group = '+[debug]' },
        { '<leader>f', group = '+[file/find]' },
        { '<leader>g', group = '+[git]' },
        { '<leader>q', group = '+[quit/session]' },
        { '<leader>s', group = '+[search]' },
        { '<leader>a', group = '+[terminal]' },
        { '<leader>u', group = '+[ui]' },
        { '<leader>w', group = '+[windows]' },
        { '<leader>x', group = '+[diagnostics/quickfix]' },
        { '<leader>l', group = '+[utils]' },
      }
      wk.add(defaults)
    end,
  },

  -- [[ TEXT HIGHLIGHT ]] ---------------------------------------------------------------

  -- [vim-illuminate] - Automatically highlights other instances of the word under your cursor.
  -- see: `:h vim-illuminate`
  -- link: https://github.com/RRethy/vim-illuminate
  {
    'RRethy/vim-illuminate',
    branch = 'master',
    event = 'VeryLazy',
    keys = {
      { ']]', desc = 'Next Reference <]]>' },
      { '[[', desc = 'Prev Reference <[[>' },
    },
    config = function(_, opts)
      require('illuminate').configure {
        delay = 200,
        large_file_cutoff = 2000,
        large_file_overrides = {
          providers = { 'lsp' },
        },
      }
      local function map(key, dir, buffer)
        vim.keymap.set('n', key, function()
          require('illuminate')['goto_' .. dir .. '_reference'](false)
        end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. ' Reference', buffer = buffer })
      end
      map(']]', 'next')
      map('[[', 'prev')
      -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map(']]', 'next', buffer)
          map('[[', 'prev', buffer)
        end,
      })
    end,
  },

  -- [[ BUFFER UTILS ]] ---------------------------------------------------------------

  -- [windows.nvim] - Plugin for maximizing windows
  -- see: `:h windows.nvim`
  -- link: https://github.com/anuvyklack/windows.nvim
  {
    'anuvyklack/windows.nvim',
    branch = 'main',
    dependencies = {
      { 'anuvyklack/middleclass', branch = 'master' },
      { 'anuvyklack/animation.nvim', branch = 'main' },
    },
    -- stylua: ignore
    keys = {
      { '<leader>wm', '<cmd>WindowsMaximize<cr>',        mode = { 'n', 'v' }, desc = 'Maximize Window [wm]', },
      { '<leader>we', '<cmd>WindowsEqualize<cr>',        mode = { 'n', 'v' }, desc = 'Equalize Window [we]', },
      { '<leader>wt', '<cmd>WindowsToggleAutowidth<cr>', mode = { 'n', 'v' }, desc = 'Toggle Autowidth [wt]', },
    },
    config = function()
      vim.o.winwidth = 10
      vim.o.winminwidth = 10
      vim.o.equalalways = false
      require('windows').setup()
    end,
  },

  -- [better_escape.nvim] - Escpe from insert mode with jj or jk
  -- see: `:h better_escape.nvim`
  -- link: https://github.com/max397574/better-escape.nvim
  {
    'max397574/better-escape.nvim',
    config = function()
      require('better_escape').setup {
        timeout = vim.o.timeoutlen,
        default_mappings = true,
        mappings = {
          i = {
            j = {
              -- These can all also be functions
              k = '<Esc>',
              j = '<Esc>',
            },
          },
          c = {
            j = {
              k = '<Esc>',
              j = '<Esc>',
            },
          },
          t = {
            j = {
              k = '<Esc>',
              j = '<Esc>',
            },
          },
          v = {
            j = {
              k = '<Esc>',
            },
          },
          s = {
            j = {
              k = '<Esc>',
            },
          },
        },
      }
    end,
  },

  -- [neominimap.nvim] - Code minimap
  -- see: `:h neominimap.nvim`
  -- link: https://github.com/Isrothy/neominimap.nvim
  {
    'Isrothy/neominimap.nvim',
    version = 'v3.*.*',
    enabled = true,
    lazy = false,
    keys = {
      -- Global Minimap Controls
      { '<leader>wM', '<cmd>Neominimap toggle<cr>', desc = 'Toggle global minimap' },
      -- Window-Specific Minimap Controls
      { '<leader>wW', '<cmd>Neominimap winToggle<cr>', desc = 'Toggle minimap for current window' },
      -- Buffer-Specific Minimap Controls
      { '<leader>wb', '<cmd>Neominimap bufToggle<cr>', desc = 'Toggle minimap for current buffer' },
    },
    init = function()
      vim.opt.wrap = false
      vim.opt.sidescrolloff = 36 -- Set a large value
      vim.g.neominimap = {
        auto_enable = true,
        exclude_filetypes = {
          'help', 'dashboard', 'markdown', 'norg'
        },
        exclude_buftypes = {
          'nofile',
          'nowrite',
          'quickfix',
          'terminal',
          'prompt',
        },
        x_multiplier = 4,
        y_multiplier = 1,
        --- Either `split` or `float`
        layout = 'float',
        split = {
          minimap_width = 8,
          fix_width = false,
          direction = 'right',
          close_if_last_window = false,
        },
        float = {
          minimap_width = 10,
          --- If set to nil, there is no maximum height restriction
          max_minimap_height = nil,
          margin = {
            right = 0,
            top = 0,
            bottom = 0,
          },
          z_index = 1,
          --- Accepts all usual border style options (e.g., "single", "double")
          window_border = 'rounded',
        },
        delay = 200,
        -- Sync the cursor position with the minimap
        sync_cursor = true,
        click = {
          enabled = false,
          auto_switch_focus = true,
        },
        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.WARN,
          mode = 'line',
          priority = {
            ERROR = 100,
            WARN = 90,
            INFO = 80,
            HINT = 70,
          },
          icon = {
            ERROR = '󰅚 ',
            WARN = '󰀪 ',
            INFO = '󰌶 ',
            HINT = ' ',
          },
        },
        git = {
          enabled = true,
          mode = 'sign',
          priority = 6,
          icon = {
            add = '+ ',
            change = '~ ',
            delete = '- ',
          },
        },
        search = {
          enabled = false,
          mode = 'line',
          priority = 20,
          icon = '󰱽 ',
        },
        treesitter = {
          enabled = true,
          priority = 200,
        },
        mark = {
          enabled = false,
          mode = 'icon',
          priority = 10,
          key = 'm',
          show_builtins = false,
        },
        fold = {
          -- Considering fold when rendering minimap
          enabled = true,
        },
      }
    end,
  },

  -- [bigfile.nvim] - Disable editor functions like lsp, treesitter when big file is loaded
  -- see: `:h bigfile.nvim`
  -- link: https://github.com/LunarVim/bigfile.nvim
  {
    'LunarVim/bigfile.nvim',
    branch = 'main',
    init = function()
      require('bigfile').setup {
        filesize = 2, -- size of the file in MiB, the plugin round file sizes to the closest MiB
        pattern = { '*' }, -- autocmd pattern
        features = { -- features to disable
          'indent_blankline',
          'illuminate',
          'lsp',
          'treesitter',
          'syntax',
          'matchparen',
          'vimopts',
          'filetype',
        },
      }
    end,
  },

  -- [vim-repeat] - Support `.` repeat in plugins.
  -- see: `:h vim-repeat`
  -- link: https://github.com/tpope/vim-repeat
  { 'tpope/vim-repeat', branch = 'master' },

  -- [gx.nvim] - Open link in browser
  -- see: `:h gx.nvim`
  -- link: https://github.com/chrishrb/gx.nvim
  {
    'chrishrb/gx.nvim',
    branch = 'main',
    event = { 'BufEnter' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      handler_options = {
        search_engine = 'google',
      },
    },
  },

  -- [modes.nvim] - Highlights current line accordingly to mode
  -- see: `:h modes.nvim`
  -- link: https://github.com/mvllow/modes.nvim
  {
    'mvllow/modes.nvim',
    branch = 'main',
    config = function()
      require('modes').setup {
        colors = {
          copy = '#f5c359',
          delete = '#c75c6a',
          insert = '#78ccc5',
          visual = '#9745be',
        },
        -- Set opacity for cursorline and number background
        line_opacity = 0.30,
        -- Enable cursor highlights
        set_cursor = true,
        -- Enable cursorline initially, and disable cursorline for inactive windows
        -- or ignored filetypes
        set_cursorline = true,
        -- Enable line number highlights to match cursorline
        set_number = true,
        -- Disable modes highlights in specified filetypes
        -- Please PR commonly ignored filetypes
        ignore_filetypes = { 'NvimTree', 'TelescopePrompt' },
      }
    end,
  },

  -- [snipe.nvim] - Efficient buffer navigation
  -- see: `:h snipe.nvim`
  -- link: https://github.com/leath-dub/snipe.nvim
  {
    'leath-dub/snipe.nvim',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>,',
        function()
          require('snipe').open_buffer_menu()
        end,
        desc = 'Open Snipe buffer menu',
      },
    },
    opts = {
      ui = {
        max_width = -1, -- -1 means dynamic width
        -- Can be any of "topleft", "bottomleft", "topright", "bottomright", "center", "cursor" (sets under the current cursor pos)
        position = 'cursor',
      },
      hints = {
        -- Characters to use for hints (NOTE: make sure they don't collide with the navigation keymaps)
        dictionary = 'sadflewcmpghio',
      },
      navigate = {
        -- When the list is too long it is split into pages
        -- `[next|prev]_page` options allow you to navigate
        -- this list
        next_page = 'J',
        prev_page = 'K',
        -- You can also just use normal navigation to go to the item you want
        -- this option just sets the keybind for selecting the item under the
        -- cursor
        under_cursor = '<cr>',
        -- In case you changed your mind, provide a keybind that lets you
        -- cancel the snipe and close the window.
        cancel_snipe = '<esc>',
      },
      -- Define the way buffers are sorted by default
      -- Can be any of "default" (sort buffers by their number) or "last" (sort buffers by last accessed)
      sort = 'last',
    },
  },

  -- [nvim-hlslens] - Highlights matched search, jump between matched instances.
  -- see: `:h nvim-hlslens`
  -- link: https://github.com/kevinhwang91/nvim-hlslens
  {
    'kevinhwang91/nvim-hlslens',
    branch = 'main',
    event = 'VeryLazy',
    config = function()
      require('hlslens').setup {}
    end,
  },
}
