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
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics [xx]' },
      { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics [xX]' },
      { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List [xL]' },
      { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List [xQ]' },
      { '<leader>xs', '<cmd>Trouble symbols toggle win.relative=win win.position=right<cr>' },
      { '<leader>xl', '<cmd>Trouble lsp toggle win.relative=win win.position=right<cr>' },
      {
        '[q',
        function()
          if require('trouble').is_open() then
            require('trouble').previous { skip_groups = true, jump = true }
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
      auto_close = false, -- auto close when there are no items
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
          mode = 'diagnostics',
          preview = {
            type = 'split',
            relative = 'win',
            position = 'right',
            size = 0.4,
          },
        },
        references_prev = {
          mode = 'lsp_references',
          focus = true,
          preview = {
            type = 'split',
            relative = 'win',
            position = 'right',
            size = 0.5,
          },
        },
        definition_prev = {
          mode = 'lsp_definitions',
          focus = true,
          preview = {
            type = 'split',
            relative = 'win',
            position = 'right',
            size = 0.5,
          },
        },
        declaration_prev = {
          mode = 'lsp_declarations',
          focus = true,
          preview = {
            type = 'split',
            relative = 'win',
            position = 'right',
            size = 0.5,
          },
        },
        type_definition_prev = {
          mode = 'lsp_type_definitions',
          focus = true,
          preview = {
            type = 'split',
            relative = 'win',
            position = 'right',
            size = 0.5,
          },
        },
        implementations_prev = {
          mode = 'lsp_implementations',
          focus = true,
          preview = {
            type = 'split',
            relative = 'win',
            position = 'right',
            size = 0.5,
          },
        },
        command_prev = {
          mode = 'lsp_command',
          focus = true,
          preview = {
            type = 'split',
            relative = 'win',
            position = 'right',
            size = 0.5,
          },
        },
        incoming_calls_prev = {
          mode = 'lsp_incoming_calls',
          focus = true,
          preview = {
            type = 'split',
            relative = 'win',
            position = 'right',
            size = 0.5,
          },
        },
        outgoing_calls_prev = {
          mode = 'lsp_outgoing_calls',
          focus = true,
          preview = {
            type = 'split',
            relative = 'win',
            position = 'right',
            size = 0.5,
          },
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

  -- [todo-comments.nvim] - Finds and lists all of the TODO, HACK, BUG, etc comment
  -- in your project and loads them into a browsable list.
  -- see: `:h todo-comments`
  -- link: https://github.com/folke/todo-comments.nvim
  {
    'folke/todo-comments.nvim',
    branch = 'main',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = 'VeryLazy',
    config = true,
    -- stylua: ignore
    keys = {
      { ']t',         function() require('todo-comments').jump_next() end, desc = 'Next todo comment <]t>' },
      { '[t',         function() require('todo-comments').jump_prev() end, desc = 'Previous [t]odo comment <[t>' },
      { '<leader>xt', '<cmd>TodoTrouble<cr>',                              desc = 'List Todo [xt]' },
      { '<leader>xT', '<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>',      desc = 'List Todo/Fix/Fixme [xT]' },
      { '<leader>st', '<cmd>TodoTelescope<cr>',                            desc = 'Search Todo [sT]' },
      { '<leader>sT', '<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>',    desc = 'Search Todo/Fix/Fixme [sT]' },
    },
  },

  -- [[ YANK/PASTE ]] ---------------------------------------------------------------

  -- [yanky.nvim] - Better yank/paste
  -- see: `h: yanky`
  -- link: https://github.com/gbprod/yanky.nvim
  {
    'gbprod/yanky.nvim',
    branch = 'main',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      ---@diagnostic disable-next-line: undefined-field
      { "<leader>p", function() require("telescope").extensions.yank_history.yank_history({}) end,  desc = "Search Yank History [p]" },
      { 'y',         '<Plug>(YankyYank)',                                                           mode = { 'n', 'x' },                                desc = 'Yank text <y>' },
      { 'p',         '<Plug>(YankyPutAfter)',                                                       mode = { 'n', 'x' },                                desc = 'Put yanked text after cursor <p>' },
      { 'P',         '<Plug>(YankyPutBefore)',                                                      mode = { 'n', 'x' },                                desc = 'Put yanked text before cursor <P>' },
      { 'gp',        '<Plug>(YankyGPutAfter)',                                                      mode = { 'n', 'x' },                                desc = 'Put yanked text after selection <gp>' },
      { 'gP',        '<Plug>(YankyGPutBefore)',                                                     mode = { 'n', 'x' },                                desc = 'Put yanked text before selection <gP>' },
      { '[y',        '<Plug>(YankyCycleForward)',                                                   desc = 'Cycle forward through yank history <[y>' },
      { ']y',        '<Plug>(YankyCycleBackward)',                                                  desc = 'Cycle backward through yank history <]y>' },
      { ']p',        '<Plug>(YankyPutIndentAfterLinewise)',                                         desc = 'Put indented after cursor (linewise) <]p>' },
      { '[p',        '<Plug>(YankyPutIndentBeforeLinewise)',                                        desc = 'Put indented before cursor (linewise) <[p>' },
      { ']P',        '<Plug>(YankyPutIndentAfterLinewise)',                                         desc = 'Put indented after cursor (linewise) <]P>' },
      { '[P',        '<Plug>(YankyPutIndentBeforeLinewise)',                                        desc = 'Put indented before cursor (linewise) <[P>' },
      { '>p',        '<Plug>(YankyPutIndentAfterShiftRight)',                                       desc = 'Put and indent right <>p>' },
      { '<p',        '<Plug>(YankyPutIndentAfterShiftLeft)',                                        desc = 'Put and indent left <<p>' },
      { '>P',        '<Plug>(YankyPutIndentBeforeShiftRight)',                                      desc = 'Put before and indent right <>P>' },
      { '<P',        '<Plug>(YankyPutIndentBeforeShiftLeft)',                                       desc = 'Put before and indent left <<P>' },
      { '=p',        '<Plug>(YankyPutAfterFilter)',                                                 desc = 'Put after applying a filter <=p>' },
      { '=P',        '<Plug>(YankyPutBeforeFilter)',                                                desc = 'Put before applying a filter <=P>' },
    },
    opts = {
      ring = {
        history_length = 100,
        storage = 'shada',
        storage_path = vim.fn.stdpath 'data' .. '/databases/yanky.db', -- Only for sqlite storage
        sync_with_numbered_registers = true,
        cancel_event = 'update',
        ignore_registers = { '_' },
        update_register_on_cycle = false,
      },
      picker = {
        select = {
          action = nil, -- nil to use default put action
        },
        telescope = {
          use_default_mappings = true, -- if default mappings should be used
          mappings = nil, -- nil to use default mappings or no mappings (see `use_default_mappings`)
        },
      },
      system_clipboard = {
        sync_with_ring = true,
      },
      highlight = {
        on_put = true,
        on_yank = true,
        timer = 200,
      },
      preserve_cursor_position = {
        enabled = true,
      },
      textobj = {
        enabled = true,
      },
    },
  },

  -- [[ BUFFER UTILS ]] ---------------------------------------------------------------

  -- [arrow.nvim] - Pin buffers for quick access
  -- see: `:h arrow.nvim`
  -- link: https://github.com/otavioschwanck/arrow.nvim
  {
    'otavioschwanck/arrow.nvim',
    branch = 'master',
    event = 'VeryLazy',
    opts = {
      show_icons = true,
      leader_key = '`', -- Recommended to be a single key
    },
  },

  -- [detour.nvim] - Open current buffer in popup
  -- see: `:h detour.nvim`
  -- link: https://github.com/carbon-steel/detour.nvim
  {
    'carbon-steel/detour.nvim',
    branch = 'main',
    event = 'VeryLazy',
  },

  -- [guess-indent.nvim] - Plugin to guess proper indentation level.
  -- see: `:h guess-indent.nvim`
  -- link: https://github.com/NMAC427/guess-indent.nvim
  {
    'nmac427/guess-indent.nvim',
    branch = 'main',
    config = function()
      require('guess-indent').setup {}
    end,
  },

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

  -- [nvim-scrollbar] - Scorllbar with git and lsp integration
  -- see: `:h nvim-scrollbar`
  -- link: https://github.com/petertriho/nvim-scrollbar
  {
    'petertriho/nvim-scrollbar',
    branch = 'main',
    config = function()
      require('scrollbar').setup {
        show = true,
        show_in_active_only = false,
        set_highlights = true,
        folds = 1000, -- handle folds, set to number to disable folds if no. of lines in buffer exceeds this
        max_lines = false, -- disables if no. of lines in buffer exceeds this
        hide_if_all_visible = false, -- Hides everything if all lines are visible
        throttle_ms = 100,
        handle = {
          text = ' ',
          blend = 30, -- Integer between 0 and 100. 0 for fully opaque and 100 to full transparent. Defaults to 30.
          color = nil,
          color_nr = nil, -- cterm
          highlight = 'CursorColumn',
          hide_if_all_visible = true, -- Hides handle if all lines are visible
        },
        excluded_buftypes = {
          'terminal',
        },
        excluded_filetypes = {
          'cmp_docs',
          'cmp_menu',
          'noice',
          'prompt',
          'TelescopePrompt',
        },
        autocmd = {
          render = {
            'BufWinEnter',
            'TabEnter',
            'TermEnter',
            'WinEnter',
            'CmdwinLeave',
            'TextChanged',
            'VimResized',
            'WinScrolled',
          },
          clear = {
            'BufWinLeave',
            'TabLeave',
            'TermLeave',
            'WinLeave',
          },
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true, -- Requires gitsigns
          handle = true,
          search = true, -- Requires hlslens
          ale = false, -- Requires ALE
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

  -- [wilder.nvim] - cmdline improving plugin
  -- see: `:h wilder.nvim`
  -- link: https://github.com/gelguy/wilder.nvim
  {
    'gelguy/wilder.nvim',
    branch = 'master',
    config = function()
      local wilder = require 'wilder'
      wilder.setup { modes = { ':', '/', '?' } }
      wilder.set_option('pipeline', {
        wilder.branch(
          wilder.cmdline_pipeline {
            -- sets the language to use, 'vim' and 'python' are supported
            language = 'python',
            -- 0 turns off fuzzy matching
            -- 1 turns on fuzzy matching
            -- 2 partial fuzzy matching (match does not have to begin with the same first letter)
            fuzzy = 1,
          },
          wilder.python_search_pipeline {
            -- can be set to wilder#python_fuzzy_delimiter_pattern() for stricter fuzzy matching
            pattern = wilder.python_fuzzy_pattern(),
            -- omit to get results in the order they appear in the buffer
            sorter = wilder.python_difflib_sorter(),
            -- can be set to 're2' for performance, requires pyre2 to be installed
            -- see :h wilder#python_search() for more details
            engine = 're',
          }
        ),
      })
      local gradient = {
        '#f4468f',
        '#fd4a85',
        '#ff507a',
        '#ff566f',
        '#ff5e63',
        '#ff6658',
        '#ff704e',
        '#ff7a45',
        '#ff843d',
        '#ff9036',
        '#f89b31',
        '#efa72f',
        '#e6b32e',
        '#dcbe30',
        '#d2c934',
        '#c8d43a',
        '#bfde43',
        '#b6e84e',
        '#aff05b',
      }
      for i, fg in ipairs(gradient) do
        gradient[i] = wilder.make_hl('WilderGradient' .. i, 'Pmenu', { { a = 1 }, { a = 1 }, { foreground = fg } })
      end
      wilder.set_option(
        'renderer',
        wilder.popupmenu_renderer {
          highlights = {
            gradient = gradient, -- must be set
            -- selected_gradient key can be set to apply gradient highlighting for the selected candidate.
          },
          highlighter = wilder.highlighter_with_gradient {
            wilder.basic_highlighter(), -- or wilder.lua_fzy_highlighter(),
          },
        }
      )
    end,
  },
}
