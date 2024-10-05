vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  callback = function()
    vim.cmd [[Trouble qflist open]]
  end,
})

local float_win = function(title)
  ---@type trouble.Window.opts
  return {
    type = 'float',
    title = title,
    relative = 'editor', -- "editor" | "win" | "cursor" cursor is only valid for float
    position = { 0.1, 0.5 },
    size = { width = 0.8, height = 0.2 },
    focusable = true,
    border = 'rounded',
  }
end

-- Window options for the preview window. Can be a split, floating window,
-- or `main` to show the preview in the main editor window.
---@type trouble.Window.opts
local float_preview = {
  type = 'float',
  position = { 0.4, 0.0 },
  size = { width = 0.8, height = 0.6 },
  relative = 'cursor',
  border = 'rounded',
}

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

  -- [mini.bufremove] - Batter buffer remove
  -- see: `:h mini.bufremove`
  -- link: https://github.com/echasnovski/mini.bufremove
  {
    'echasnovski/mini.bufremove',
    branch = 'main',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      {
        '<leader>bd',
        function()
          local bd = require('mini.bufremove').delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(('Save changes to %q?'):format(vim.fn.bufname()), '&Yes\n&No\n&Cancel')
            if choice == 1 then -- Yes
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then -- No
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
        desc = 'Delete Buffer [bd]',
      },
      { '<leader>bD', function() require('mini.bufremove').delete(0, true) end, desc = 'Delete Buffer (Force) [bD]' },
    },
  },

  -- [[ DIAGNOSTICS ]] ---------------------------------------------------------------

  -- [trouble.nvim] - Better diagnostics, loclist, quickfix etc.
  -- see: `:h trouble.nvim`
  -- link: https://github.com/folke/trouble.nvim
  {
    'folke/trouble.nvim',
    branch = 'main',
    event = 'VeryLazy',
    cmd = { 'Trouble' },
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics_prev toggle<cr>', desc = 'Diagnostics [xx]' },
      { '<leader>xX', '<cmd>Trouble diagnostics_prev toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics [xX]' },
      { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List [xL]' },
      { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List [xQ]' },
      { '<leader>o', '<cmd>Trouble lsp_document_symbols_prev toggle win.position=right win.size=0.3<cr>', desc = 'Toggle symbols [xs]' },
      { '<leader>xl', '<cmd>Trouble lsp_prev toggle<cr>', desc = 'Toggle LSP [xl]' },
      {
        '[q',
        function()
          if require('trouble').is_open() then
            require('trouble').prev { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = 'Previous trouble/quickfix item <[q>',
      },
      {
        ']q',
        function()
          if require('trouble').is_open() then
            require('trouble').next { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = 'Next trouble/quickfix item <]q>',
      },
    },
    opts = {
      auto_close = true, -- auto close when there are no items
      auto_open = false, -- auto open when there are items
      auto_preview = true, -- automatically open preview when on an item
      auto_refresh = true, -- auto refresh when open
      auto_jump = false, -- auto jump to the item when there's only one
      focus = false, -- Focus the window when opened
      restore = true, -- restores the last location in the list when opening
      follow = true, -- Follow the current item
      indent_guides = true, -- show indent guides
      max_items = 200, -- limit number of items that can be displayed per section
      multiline = true, -- render multi-line messages
      pinned = false, -- When pinned, the opened trouble window will be bound to the current buffer
      warn_no_results = true, -- show a warning when there are no results
      open_no_results = false, -- open the trouble window when there are no results
      ---@type trouble.Window.opts
      win = {}, -- window options for the results window. Can be a split or a floating window.
      -- Window options for the preview window. Can be a split, floating window,
      -- or `main` to show the preview in the main editor window.
      ---@type trouble.Window.opts
      preview = {
        type = 'main',
        -- when a buffer is not yet loaded, the preview window will be created
        -- in a scratch buffer with only syntax highlighting enabled.
        -- Set to false, if you want the preview to always be a real loaded buffer.
        scratch = true,
      },
      -- Throttle/Debounce settings. Should usually not be changed.
      ---@type table<string, number|{ms:number, debounce?:boolean}>
      throttle = {
        refresh = 20, -- fetches new data when needed
        update = 10, -- updates the window
        render = 10, -- renders the window
        follow = 100, -- follows the current item
        preview = { ms = 100, debounce = true }, -- shows the preview for the current item
      },
      -- Key mappings can be set to the name of a builtin action,
      -- or you can define your own custom action.
      ---@type table<string, trouble.Action.spec|false>
      keys = {
        ['?'] = 'help',
        r = 'refresh',
        R = 'toggle_refresh',
        q = 'close',
        o = 'jump_close',
        ['<esc>'] = 'cancel',
        ['<cr>'] = 'jump',
        ['<2-leftmouse>'] = 'jump',
        ['<c-s>'] = 'jump_split',
        ['<c-v>'] = 'jump_vsplit',
        -- go down to next item (accepts count)
        -- j = "next",
        ['}'] = 'next',
        [']]'] = 'next',
        -- go up to prev item (accepts count)
        -- k = "prev",
        ['{'] = 'prev',
        ['[['] = 'prev',
        dd = 'delete',
        d = { action = 'delete', mode = 'v' },
        i = 'inspect',
        p = 'preview',
        P = 'toggle_preview',
        zo = 'fold_open',
        zO = 'fold_open_recursive',
        zc = 'fold_close',
        zC = 'fold_close_recursive',
        za = 'fold_toggle',
        zA = 'fold_toggle_recursive',
        zm = 'fold_more',
        zM = 'fold_close_all',
        zr = 'fold_reduce',
        zR = 'fold_open_all',
        zx = 'fold_update',
        zX = 'fold_update_all',
        zn = 'fold_disable',
        zN = 'fold_enable',
        zi = 'fold_toggle_enable',
        gb = { -- example of a custom action that toggles the active view filter
          action = function(view)
            view:filter({ buf = 0 }, { toggle = true })
          end,
          desc = 'Toggle Current Buffer Filter',
        },
        s = { -- example of a custom action that toggles the severity
          action = function(view)
            local f = view:get_filter 'severity'
            local severity = ((f and f.filter.severity or 0) + 1) % 5
            view:filter({ severity = severity }, {
              id = 'severity',
              template = '{hl:Title}Filter:{hl} {severity}',
              del = severity == 0,
            })
          end,
          desc = 'Toggle Severity Filter',
        },
      },
      ---@type table<string, trouble.Mode>
      modes = {
        preview_float = {
          mode = 'diagnostics',
          preview = {
            type = 'float',
            relative = 'editor',
            border = 'rounded',
            title = 'Preview',
            title_pos = 'center',
            position = { 0, -2 },
            size = { width = 0.4, height = 0.4 },
            zindex = 200,
          },
        },
        diagnostics_prev = {
          focus = true,
          mode = 'diagnostics',
          win = float_win 'Diagnostics', -- window options for the results window. Can be a split or a floating window.
          preview = float_preview,
        },
        references_prev = {
          mode = 'lsp_references',
          focus = true,
          win = float_win 'References', -- window options for the results window. Can be a split or a floating window.
          preview = float_preview,
        },
        definition_prev = {
          mode = 'lsp_definitions',
          focus = true,
          win = float_win 'Definitions',
          preview = float_preview,
        },
        declaration_prev = {
          mode = 'lsp_declarations',
          focus = true,
          win = float_win 'Declaration',
          preview = float_preview,
        },
        type_definition_prev = {
          mode = 'lsp_type_definitions',
          focus = true,
          win = float_win 'Type Definition',
          preview = float_preview,
        },
        implementations_prev = {
          mode = 'lsp_implementations',
          focus = true,
          win = float_win 'Implementations',
          preview = float_preview,
        },
        command_prev = {
          mode = 'lsp_command',
          focus = true,
          win = float_win 'LSP Command',
          preview = float_preview,
        },
        incoming_calls_prev = {
          mode = 'lsp_incoming_calls',
          focus = true,
          win = float_win 'Incoming Calls',
          preview = float_preview,
        },
        outgoing_calls_prev = {
          mode = 'lsp_outgoing_calls',
          focus = true,
          win = float_win 'Outgoing calls',
          preview = float_preview,
        },
        lsp_document_symbols_prev = {
          mode = 'lsp_document_symbols',
          focus = true,
        },
        lsp_prev = {
          mode = 'lsp',
          focus = true,
          win = float_win 'LSP References / Declarations / ...',
          preview = float_preview,
        },
        -- sources define their own modes, which you can use directly,
        -- or override like in the example below
        lsp_references = {
          -- some modes are configurable, see the source code for more details
          params = {
            include_declaration = true,
          },
        },
        -- The LSP base mode for:
        -- * lsp_definitions, lsp_references, lsp_implementations
        -- * lsp_type_definitions, lsp_declarations, lsp_command
        lsp_base = {
          params = {
            -- don't include the current location in the results
            include_current = false,
          },
        },
        -- more advanced example that extends the lsp_document_symbols
        symbols = {
          desc = 'document symbols',
          mode = 'lsp_document_symbols',
          focus = false,
          win = { position = 'right' },
          filter = {
            -- remove Package since luals uses it for control flow structures
            ['not'] = { ft = 'lua', kind = 'Package' },
            any = {
              -- all symbol kinds for help / markdown files
              ft = { 'help', 'markdown' },
              -- default set of symbol kinds
              kind = {
                'Class',
                'Constructor',
                'Enum',
                'Field',
                'Function',
                'Interface',
                'Method',
                'Module',
                'Namespace',
                'Package',
                'Property',
                'Struct',
                'Trait',
              },
            },
          },
        },
      },
    },
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
        x_multiplier = 8,
        y_multiplier = 1,
        layout = 'float',
        split = {
          minimap_width = 10,
          fix_width = false,
          direction = 'right',
          close_if_last_window = false,
        },
        float = {
          minimap_width = 10,
          max_minimap_height = nil,
          margin = {
            right = 0,
            top = 0,
            bottom = 0,
          },
          z_index = 1,
          window_border = 'single',
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
