local Util = require 'util'

return {

  -- [[ UI ENHANCEMENTS ]] ---------------------------------------------------------------
  --
  -- -- [ui] - UI enhancements like buffer line, status line, term support, lsp signature etc.
  -- see: `:h nvui`
  -- link: https://github.com/NvChad/ui
  {
    'nvchad/ui',
    config = function()
      require 'nvchad'
    end,
  },

  -- [nvim-notify] - Better 'vim.notify()'
  -- see: `:h nvim-notify`
  -- link: https://github.com/rcarriga/nvim-notify
  {
    'rcarriga/nvim-notify',
    branch = 'master',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<leader>un', function() require('notify').dismiss { silent = true, pending = true } end, desc = 'Dismiss all Notifications [un]', },
    },
    opts = {
      timeout = 3000, -- Time to show Notification in ms, set to false ti disable timeout.
      fps = 60, -- Frames per second for animnation stages, higher value means smoother animations but more CPU usage.
      level = 2, -- Minimum log level to display. See vim.log.levels.
      minimum_width = 35, -- Minimum width for notification window.
      render = 'wrapped-compact', -- 'default' | 'minimal' | 'simple' | 'wrapped-compact'. Function to render a notification buffer or a build-in renderer name
      stages = 'fade', -- 'slide' | 'fade' | 'static' | 'fade_in_slide_out' Animation stages.
      top_down = true, -- Whether or not to position the notification at the top or not
      icons = { -- Icons for each log level (upper case names)
        DEBUG = '',
        ERROR = '',
        INFO = '',
        TRACE = '✎',
        WARN = '',
      },
      -- Max number of lines for message.
      max_height = function()
        return math.floor(vim.o.lines * 0.80)
      end,
      -- Max number of columns for message.
      max_width = function()
        return math.floor(vim.o.columns * 0.80)
      end,
      -- Function called when a new window is opened, use for changing win settings/config
      on_open = function(win)
        vim.api.nvim_win_set_config(win, { zindex = 100 })
      end,
      -- on_close = Function -- Function called when window is closed.
    },
    config = function(_, opts)
      require('notify').setup(opts)
    end,
    init = function()
      -- when noice is not enabled, install notify on VeryLazy
      if not Util.has 'noice.nvim' then
        Util.on_very_lazy(function()
          vim.notify = require 'notify'
        end)
      end
    end,
  },

  -- [dressing.nvim] - Better vim.ui for input boxes, selects etc.
  -- see: `:h dressing.nvim`
  -- link: https://github.com/stevearc/dressing.nvim
  {
    'stevearc/dressing.nvim',
    branch = 'master',
    event = 'VeryLazy',
    opts = {
      input = {
        enabled = true, -- Set to false to disable the vim.ui.input implementation
        default_prompt = 'Input:', -- Default prompt string
        title_pos = 'right', -- Can be 'left', 'right', or 'center'
        insert_only = true, -- When true, <Esc> will close the modal
        start_in_insert = true, -- When true, input will start in insert mode.
        border = 'rounded', -- These are passed to nvim_open_win
        relative = 'cursor', -- 'editor' and 'win' will default to being centered
        prefer_width = 40, -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        width = nil,
        -- min_width and max_width can be a list of mixed types.
        max_width = { 140, 0.9 },
        min_width = { 20, 0.2 },
        buf_options = {},
        win_options = {
          wrap = true, -- Disable line wrapping
          list = true, -- Indicator for when text exceeds window
          listchars = 'precedes:…,extends:…',
          sidescrolloff = 4, -- Increase this for more context when text scrolls off the window
        },
        -- Set to `false` to disable
        mappings = {
          n = {
            ['<Esc>'] = 'Close',
            ['<CR>'] = 'Confirm',
          },
          i = {
            ['<C-c>'] = 'Close',
            ['<CR>'] = 'Confirm',
            ['<Up>'] = 'HistoryPrev',
            ['<Down>'] = 'HistoryNext',
          },
        },
        override = function(conf)
          -- This is the config that will be passed to nvim_open_win.
          -- Change values here to customize the layout
          return conf
        end,
        get_config = nil, -- see :help dressing_get_config
      },
      select = {
        enabled = true, -- Set to false to disable the vim.ui.select implementation
        backend = { 'telescope', 'fzf_lua', 'fzf' }, -- Priority list of preferred vim.select implementations
        trim_prompt = true, -- Trim trailing `:` from prompt
        -- Options for telescope selector
        -- These are passed into the telescope picker directly. Can be used like:
        -- telescope = require('telescope.themes').get_ivy({...})
        telescope = nil,
        -- Options for nui Menu
        nui = {
          position = '50%',
          size = nil,
          relative = 'editor',
          border = {
            style = 'rounded',
          },
          buf_options = {
            swapfile = false,
            filetype = 'DressingSelect',
          },
          win_options = {
            winblend = 0,
          },
          max_width = 80,
          max_height = 40,
          min_width = 40,
          min_height = 10,
        },
        -- Options for built-in selector
        builtin = {
          show_numbers = true, -- Display numbers for options and set up keymaps
          border = 'rounded', -- These are passed to nvim_open_win
          relative = 'editor', -- 'editor' and 'win' will default to being centered
          buf_options = {},
          win_options = {
            cursorline = true,
            cursorlineopt = 'both',
          },
          -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
          -- the min_ and max_ options can be a list of mixed types.
          -- max_width = {140, 0.8} means "the lesser of 140 columns or 80% of total"
          width = nil,
          max_width = { 140, 0.8 },
          min_width = { 40, 0.2 },
          height = nil,
          max_height = 0.9,
          min_height = { 10, 0.2 },
          mappings = { -- Set to `false` to disable
            ['<Esc>'] = 'Close',
            ['<C-c>'] = 'Close',
            ['<CR>'] = 'Confirm',
          },
          override = function(conf)
            -- This is the config that will be passed to nvim_open_win.
            -- Change values here to customize the layout
            return conf
          end,
        },
        format_item_override = {}, -- Used to override format_item. See :help dressing-format
        -- see :help dressing_get_config
        get_config = nil,
      },
    },
    init = function()
      local lazy = require 'lazy'
      vim.ui.select = function(...)
        lazy.load { plugins = { 'dressing.nvim' } }
        return vim.ui.select(...)
      end
      vim.ui.input = function(...)
        lazy.load { plugins = { 'dressing.nvim' } }
        return vim.ui.input(...)
      end
    end,
  },

  -- [noice.nvim] - Highly experimental plugin that completely replaces the UI for messages, cmdline and the popupmenu.
  -- see: `:h noice`
  -- link: https://github.com/folke/noice.nvim
  {
    'folke/noice.nvim',
    branch = 'main',
    priority = 1000,
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim', 'hrsh7th/nvim-cmp', 'rcarriga/nvim-notify' },
    -- stylua: ignore
    keys = {
      { '<C-S-Enter>', function() require('noice').redirect(vim.fn.getcmdline()) end,                 mode = 'c',                        desc = 'Redirect Cmdline <C-S-Enter>', },
      { '<leader>snl', function() require('noice').cmd 'last' end,                                    desc = 'Noice Last Message [snl]', },
      { '<leader>snh', function() require('noice').cmd 'history' end,                                 desc = 'Noice History [snh]', },
      { '<leader>sna', function() require('noice').cmd 'all' end,                                     desc = 'Noice All [sna]', },
      { '<leader>snd', function() require('noice').cmd 'dismiss' end,                                 desc = 'Dismiss All [snd]', },
      { '<c-f>',       function() if not require('noice.lsp').scroll(4) then return '<c-f>' end end,  silent = true,                     expr = true,                           desc = 'Scroll forward <c-f>',  mode = { 'i', 'n', 's' }, },
      { '<c-b>',       function() if not require('noice.lsp').scroll(-4) then return '<c-b>' end end, silent = true,                     expr = true,                           desc = 'Scroll backward <c-b>', mode = { 'i', 'n', 's' }, },
    },
    config = function()
      local wk = require 'which-key'
      if require('util').has 'noice.nvim' then
        local defaults = {
          { '<leader>sn', group = '+[noice]' },
        }
        wk.add(defaults)
      end
      require('noice').setup {
        cmdline = {
          enabled = true, -- enables the Noice cmdline UI
          view = 'cmdline_popup', -- view for rendering the cmdline. Change to `cmdline` to get a classic cmdline at the bottom
          opts = {}, -- global options for the cmdline. See section on views
          format = {
            -- conceal: (default=true) This will hide the text in the cmdline that matches the pattern.
            -- view: (default is cmdline view)
            -- opts: any options passed to the view
            -- icon_hl_group: optional hl_group for the icon
            -- title: set to anything or empty string to hide
            cmdline = { pattern = '^:', icon = '', lang = 'vim' },
            search_down = { kind = 'search', pattern = '^/', icon = ' ', lang = 'regex' },
            search_up = { kind = 'search', pattern = '^%?', icon = ' ', lang = 'regex' },
            filter = { pattern = '^:%s*!', icon = '$', lang = 'bash' },
            lua = { pattern = { '^:%s*lua%s+', '^:%s*lua%s*=%s*', '^:%s*=%s*' }, icon = '', lang = 'lua' },
            help = { pattern = '^:%s*he?l?p?%s+', icon = '' },
            input = {}, -- Used by input()
            -- lua = false, -- to disable a format, set to `false`
          },
        },
        messages = {
          -- NOTE: If you enable messages, then the cmdline is enabled automatically.
          -- This is a current Neovim limitation.
          enabled = true, -- enables the Noice messages UI
          view = 'notify', -- default view for messages
          view_error = 'notify', -- view for errors
          view_warn = 'notify', -- view for warnings
          view_history = 'messages', -- view for :messages
          view_search = 'virtualtext', -- view for search count messages. Set to `false` to disable
        },
        popupmenu = {
          enabled = true, -- enables the Noice popupmenu UI
          backend = 'nui', -- backend to use to show regular cmdline completions
          -- Icons for completion item kinds (see defaults at noice.config.icons.kinds)
          kind_icons = {}, -- set to `false` to disable icons
        },
        -- default options for require('noice').redirect
        -- see the section on Command Redirection
        redirect = {
          view = 'popup',
          filter = { event = 'msg_show' },
        },
        -- You can add any custom commands below that will be available with `:Noice command`
        commands = {
          history = {
            -- options for the message history that you get with `:Noice`
            view = 'split',
            opts = { enter = true, format = 'details' },
            filter = {
              any = {
                { event = 'notify' },
                { error = true },
                { warning = true },
                { event = 'msg_show', kind = { '' } },
                { event = 'lsp', kind = 'message' },
              },
            },
          },
          -- :Noice last
          last = {
            view = 'popup',
            opts = { enter = true, format = 'details' },
            filter = {
              any = {
                { event = 'notify' },
                { error = true },
                { warning = true },
                { event = 'msg_show', kind = { '' } },
                { event = 'lsp', kind = 'message' },
              },
            },
            filter_opts = { count = 1 },
          },
          -- :Noice errors
          errors = {
            -- options for the message history that you get with `:Noice`
            view = 'popup',
            opts = { enter = true, format = 'details' },
            filter = { error = true },
            filter_opts = { reverse = true },
          },
        },
        notify = {
          -- Noice can be used as `vim.notify` so you can route any notification like other messages
          -- Notification messages have their level and other properties set.
          -- event is always "notify" and kind can be any log level as a string
          -- The default routes will forward notifications to nvim-notify
          -- Benefit of using Noice for this is the routing and consistent history view
          enabled = true,
          view = 'notify',
        },
        lsp = {
          progress = {
            enabled = false,
            -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
            -- See the section on formatting for more details on how to customize.
            format = 'lsp_progress',
            format_done = 'lsp_progress_done',
            throttle = 1000 / 30, -- frequency to update lsp progress message
            view = 'mini',
          },
          override = {
            -- override the default lsp markdown formatter with Noice
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            -- override the lsp markdown formatter with Noice
            ['vim.lsp.util.stylize_markdown'] = true,
            -- override cmp documentation with Noice (needs the other options to work)
            ['cmp.entry.get_documentation'] = true,
          },
          hover = {
            enabled = true,
            silent = false, -- set to true to not show a message if hover is not available
            view = nil, -- when nil, use defaults from documentation
            opts = {}, -- merged with defaults from documentation
          },
          signature = {
            enabled = false,
            auto_open = {
              enabled = true,
              trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
              luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
              throttle = 50, -- Debounce lsp signature help request by 50ms
            },
            view = nil, -- when nil, use defaults from documentation
            opts = {}, -- merged with defaults from documentation
          },
          message = {
            -- Messages shown by lsp servers
            enabled = true,
            view = 'notify',
            opts = {},
          },
          -- defaults for hover and signature help
          documentation = {
            view = 'hover',
            opts = {
              lang = 'markdown',
              replace = true,
              render = 'plain',
              format = { '{message}' },
              win_options = { concealcursor = 'n', conceallevel = 3 },
            },
          },
        },
        markdown = {
          hover = {
            ['|(%S-)|'] = vim.cmd.help, -- vim help links
            ['%[.-%]%((%S-)%)'] = require('noice.util').open, -- markdown links
          },
          highlights = {
            ['|%S-|'] = '@text.reference',
            ['@%S+'] = '@parameter',
            ['^%s*(Parameters:)'] = '@text.title',
            ['^%s*(Return:)'] = '@text.title',
            ['^%s*(See also:)'] = '@text.title',
            ['{%S-}'] = '@parameter',
          },
        },
        health = {
          checker = true, -- Disable if you don't want health checks to run
        },
        smart_move = {
          -- noice tries to move out of the way of existing floating windows.
          enabled = true, -- you can disable this behaviour here
          -- add any filetypes here, that shouldn't trigger smart move.
          excluded_filetypes = { 'cmp_menu', 'cmp_docs', 'notify' },
        },
        presets = {
          -- you can enable a preset by setting it to true, or a table that will override the preset config
          -- you can also add custom presets that you can enable/disable with enabled=true
          bottom_search = false, -- use a classic bottom cmdline for search
          command_palette = true, -- position the cmdline and popupmenu together
          long_message_to_split = true, -- long messages will be sent to a split
          inc_rename = true, -- enables an input dialog for inc-rename.nvim
          lsp_doc_border = true, -- add a border to hover docs and signature help
        },
        throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
        views = {}, ---@see section on views
        status = {}, --- @see section on statusline components
        format = {}, --- @see section on formatting
        routes = {
          {
            filter = {
              event = 'msg_show',
              any = {
                { find = '%d+L, %d+B' },
                { find = '; after #%d+' },
                { find = '; before #%d+' },
              },
            },
            view = 'mini',
          },
        },
      }
    end,
  },

  {
    'echasnovski/mini.icons',
    opts = {},
    lazy = true,
    init = function()
      package.preload['nvim-web-devicons'] = function()
        require('mini.icons').mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,
  },
  -- [nui.nvim] - UI components like popups.
  -- see: `:h nui`
  -- link: https://github.com/MunifTanjim/nui.nvim
  { 'MunifTanjim/nui.nvim', branch = 'main' },

  -- [dashboard-nvim] - Welcome dashboard like in other IDE
  -- see: `:h dashboard-nvim`
  -- link: https://github.com/nvimdev/dashboard-nvim
  {
    'nvimdev/dashboard-nvim',
    branch = 'master',
    event = 'VimEnter',
    -- stylua: ignore
    keys = {
      { '<leader>D', '<cmd>Dashboard<cr>', desc = 'Dashboard [D]' },
    },
    opts = function()
      local oogway = require 'oogway'
      local opts = {
        theme = 'hyper',
        hide = {
          -- this is taken care of by lualine
          -- enabling this messes up the actual laststatus setting after loading a file
          statusline = false,
        },
        config = {
          week_header = {
            enable = false,
          },
          header = vim.fn.split(oogway.what_is_your_wisdom() .. '\n\n\n\n\n\n\n', '\n'),
          shortcut = {
            { icon = '󱎸 ', desc = 'Find Text', action = 'Telescope live_grep', key = 's' },
            { icon = ' ', desc = 'Config Files', action = [[lua require("util").telescope.config_files()()]], key = 'c' },
            { icon = ' ', desc = 'Leetcode', action = 'Leet', key = 'L' },
            { icon = ' ', desc = 'Lazy', action = 'Lazy update', key = 'l' },
            { icon = '󱊓 ', desc = 'Mason', action = 'Mason', key = 'm' },
            { icon = ' ', desc = 'Theme', action = 'Telescope themes', key = 't' },
            { icon = ' ', desc = 'Check Health', action = 'checkhealth', key = 'h' },
          },
          packages = { enabled = true },
          footer = function()
            local stats = require('lazy').stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return { '⚡ Neovim loaded ' .. stats.loaded .. '/' .. stats.count .. ' plugins in ' .. ms .. 'ms' }
          end,
        },
      }
      -- close Lazy and re-open when the dashboard is ready
      if vim.o.filetype == 'lazy' then
        vim.cmd.close()
        vim.api.nvim_create_autocmd('User', {
          pattern = 'DashboardLoaded',
          callback = function()
            require('lazy').show()
          end,
        })
      end
      return opts
    end,
  },

  -- [floating-help.nvim] - Vim help shown in floating popup
  -- see: 'h: floating-help'
  -- link: https://github.com/Tyler-Barham/floating-help.nvim
  {
    'Tyler-Barham/floating-help.nvim',
    branch = 'main',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<F1>', '<cmd>FloatingHelpToggle<cr>', mode = { 'n' }, desc = 'Toggle Floating Help <F1>' },
      { '<F5>', function() require("floating-help").open('t=help', vim.fn.expand("<cword>")) end, mode = { 'n' }, desc = 'Search cword in Help <F5>' },
      { '<F6>', function() require("floating-help").open('t=man', vim.fn.expand("<cword>")) end, mode = { 'n' }, desc = 'Search cwrod in Man <F6>' },
    },
    config = function()
      require('floating-help').setup {
        -- Defaults
        width = 82, -- Whole numbers are columns/rows
        height = 0.99, -- Decimals are a percentage of the editor
        position = 'E', -- NW,N,NW,W,C,E,SW,S,SE (C==center)
        borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
      }
      -- Only replace cmds, not search; only replace the first instance
      local function cmd_abbrev(abbrev, expansion)
        local cmd = 'cabbr ' .. abbrev .. ' <c-r>=(getcmdpos() == 1 && getcmdtype() == ":" ? "' .. expansion .. '" : "' .. abbrev .. '")<CR>'
        vim.cmd(cmd)
      end
      -- Redirect `:h` to `:FloatingHelp`
      cmd_abbrev('h', 'FloatingHelp')
      cmd_abbrev('help', 'FloatingHelp')
      cmd_abbrev('helpc', 'FloatingHelpClose')
      cmd_abbrev('helpclose', 'FloatingHelpClose')
    end,
  },

  -- [numb.nvim] - Show preview of location when jumping to line with `:{number}`
  -- see: `:h numb`
  -- link: https://github.com/nacro90/numb.nvim
  {
    'nacro90/numb.nvim',
    branch = 'master',
    event = 'VeryLazy',
    opts = {
      show_numbers = true, -- Enable 'number' for the window while peeking
      show_cursorline = true, -- Enable 'cursorline' for the window while peeking
      hide_relativenumbers = true, -- Enable turning off 'relativenumber' for the window while peeking
      number_only = false, -- Peek only when the command is only a number instead of when it starts with a number
      centered_peeking = true, -- Peeked line will be centered relative to window
    },
    config = function(_, opts)
      require('numb').setup(opts)
    end,
  },

  -- [nvim-window-picker] - Allows to decide where to split a window from neo-tree
  -- see: `:h window-picker`
  -- link: https://github.com/s1n7ax/nvim-window-picker
  {
    's1n7ax/nvim-window-picker',
    branch = 'main',
    name = 'window-picker',
    event = 'VeryLazy',
    opts = {
      -- type of hints you want to get
      -- following types are supported
      -- 'statusline-winbar' | 'floating-big-letter'
      -- 'statusline-winbar' draw on 'statusline' if possible, if not 'winbar' will be
      -- 'floating-big-letter' draw big letter on a floating window
      -- used
      hint = 'floating-big-letter',
      -- when you go to window selection mode, status bar will show one of
      -- following letters on them so you can use that letter to select the window
      selection_chars = 'FJDKSLA;CMRUEIWOQP',
      -- This section contains picker specific configurations
      picker_config = {
        statusline_winbar_picker = {
          -- You can change the display string in status bar.
          -- It supports '%' printf style. Such as `return char .. ': %f'` to display
          -- buffer file path. See :h 'stl' for details.
          selection_display = function(char)
            return '%=' .. char .. '%='
          end,
          -- whether you want to use winbar instead of the statusline
          -- "always" means to always use winbar,
          -- "never" means to never use winbar
          -- "smart" means to use winbar if cmdheight=0 and statusline if cmdheight > 0
          use_winbar = 'never', -- "always" | "never" | "smart"
        },
        floating_big_letter = {
          -- window picker plugin provides bunch of big letter fonts
          -- fonts will be lazy loaded as they are being requested
          -- additionally, user can pass in a table of fonts in to font
          -- property to use instead
          font = 'ansi-shadow', -- ansi-shadow |
        },
      },
      -- whether to show 'Pick window:' prompt
      show_prompt = true,
      -- prompt message to show to get the user input
      prompt_message = 'Pick window: ',
      -- if you want to manually filter out the windows, pass in a function that
      -- takes two parameters. You should return window ids that should be
      -- included in the selection
      -- EX:-
      -- function(window_ids, filters)
      --    -- folder the window_ids
      --    -- return only the ones you want to include
      --    return {1000, 1001}
      -- end
      filter_func = nil,
      -- following filters are only applied when you are using the default filter
      -- defined by this plugin. If you pass in a function to "filter_func"
      -- property, you are on your own
      filter_rules = {
        -- when there is only one window available to pick from, use that window
        -- without prompting the user to select
        autoselect_one = true,
        -- whether you want to include the window you are currently on to window
        -- selection or not
        include_current_win = false,
        -- filter using buffer options
        bo = {
          -- if the file type is one of following, the window will be ignored
          filetype = { 'NvimTree', 'neo-tree', 'notify' },
          -- if the file type is one of following, the window will be ignored
          buftype = { 'terminal' },
        },
        -- filter using window options
        wo = {},
        -- if the file path contains one of following names, the window
        -- will be ignored
        file_path_contains = {},
        -- if the file name contains one of following names, the window will be
        -- ignored
        file_name_contains = {},
      },
    },
    config = function(_, opts)
      require('window-picker').setup(opts)
    end,
  },

  -- [zen-mode.nvim] - Creates distraction free view for smooth coding
  -- see: `:h zen-mode`
  -- link: https://github.com/folke/zen-mode.nvim
  {
    'folke/zen-mode.nvim',
    branch = 'main',
    event = 'VeryLazy',
    keys = {
      { '<leader>Z', '<cmd>ZenMode<cr>', mode = { 'n' }, desc = 'Zen Mode [Z]' },
    },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      window = {
        backdrop = 0.95, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
        -- height and width can be:
        -- * an absolute number of cells when > 1
        -- * a percentage of the width / height of the editor when <= 1
        -- * a function that returns the width or the height
        width = 120, -- width of the Zen window
        height = 1, -- height of the Zen window
        -- by default, no options are changed for the Zen window
        -- uncomment any of the options below, or add other vim.wo options you want to apply
        options = {
          -- signcolumn = "no", -- disable signcolumn
          -- number = false, -- disable number column
          -- relativenumber = false, -- disable relative numbers
          -- cursorline = false, -- disable cursorline
          -- cursorcolumn = false, -- disable cursor column
          -- foldcolumn = "0", -- disable fold column
          -- list = false, -- disable whitespace characters
        },
      },
      plugins = {
        -- disable some global vim options (vim.o...)
        -- comment the lines to not apply the options
        options = {
          enabled = true,
          ruler = false, -- disables the ruler text in the cmd line area
          showcmd = false, -- disables the command in the last line of the screen
          -- you may turn on/off statusline in zen mode by setting 'laststatus'
          -- statusline will be shown only if 'laststatus' == 3
          laststatus = 0, -- turn off the statusline in zen mode
        },
        twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
        gitsigns = { enabled = true }, -- disables git signs
        tmux = { enabled = false }, -- disables the tmux statusline
        -- this will change the font size on kitty when in zen mode
        -- to make this work, you need to set the following kitty options:
        -- - allow_remote_control socket-only
        -- - listen_on unix:/tmp/kitty
        kitty = {
          enabled = false,
          font = '+4', -- font size increment
        },
        -- this will change the font size on alacritty when in zen mode
        -- requires  Alacritty Version 0.10.0 or higher
        -- uses `alacritty msg` subcommand to change font size
        alacritty = {
          enabled = false,
          font = '14', -- font size
        },
        -- this will change the font size on wezterm when in zen mode
        -- See also the Plugins/Wezterm section in this projects README
        wezterm = {
          enabled = false,
          -- can be either an absolute font size or the number of incremental steps
          font = '+4', -- (10% increase per step)
        },
      },
    },
  },

  -- [mini.animate] - Nice animations for UI
  -- see: `:h mini.animate`
  -- link: https://github.com/echasnovski/mini.animate
  {
    'echasnovski/mini.animate',
    branch = 'main',
    event = 'VeryLazy',
    opts = function()
      -- don't use animate when scrolling with the mouse
      local mouse_scrolled = false
      for _, scroll in ipairs { 'Up', 'Down' } do
        local key = '<ScrollWheel' .. scroll .. '>'
        vim.keymap.set({ '', 'i' }, key, function()
          mouse_scrolled = true
          return key
        end, { expr = true })
      end
      local animate = require 'mini.animate'
      return {
        resize = {
          timing = animate.gen_timing.linear { duration = 100, unit = 'total' },
        },
        scroll = {
          timing = animate.gen_timing.linear { duration = 150, unit = 'total' },
          subscroll = animate.gen_subscroll.equal {
            predicate = function(total_scroll)
              if mouse_scrolled then
                mouse_scrolled = false
                return false
              end
              return total_scroll > 1
            end,
          },
        },
      }
    end,
  },

  -- [helpview.nvim] - Format and colorize help files
  -- see: `:h helpview.nvim`
  -- link: https://github.com/OXY2DEV/helpview.nvim
  {
    'OXY2DEV/helpview.nvim',
    lazy = false,
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
  },

  -- [markview.nvim] - Markdown previever
  -- see: `:h markview.nvim`
  -- link: https://github.com/OXY2DEV/markview.nvim
  {
    'OXY2DEV/markview.nvim',
    lazy = false, -- Recommended
    ft = { 'markdown', 'norg' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
  },
}
