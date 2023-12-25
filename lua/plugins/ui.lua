local Util = require 'util'

return {
  -- Better `vim.notify()`
  -- see: `:h notify`
  {
    'rcarriga/nvim-notify',
    keys = {
      {
        '<leader>un',
        function()
          require('notify').dismiss { silent = true, pending = true }
        end,
        desc = 'Dismiss all Notifications',
      },
    },
    opts = {
      timeout = 2500, -- Time to show Notification in ms, set to false ti disable timeout.
      fps = 30, -- Frames per second for animnation stages, higher value means smoother animations but more CPU usage.
      level = 2, -- Minimum log level to display. See vim.log.levels.
      minimum_width = 50, -- Minimum width for notification window.
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
        return math.floor(vim.o.lines * 0.75)
      end,
      -- Max number of columns for message.
      max_width = function()
        return math.floor(vim.o.columns * 0.75)
      end,
      -- Function called when a new window is openend, use for changing win settings/config
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

  -- better vim.ui
  -- see `:h dressing`
  {
    'stevearc/dressing.nvim',
    opts = {
      input = {
        enabled = true, -- Set to false to disable the vim.ui.input implementation
        default_prompt = 'Input:', -- Default prompt string
        title_pos = 'center', -- Can be 'left', 'right', or 'center'
        insert_only = true, -- When true, <Esc> will close the modal
        start_in_insert = true, -- When true, input will start in insert mode.
        border = 'rounded', -- These are passed to nvim_open_win
        relative = 'cursor', -- 'editor' and 'win' will default to being centered
        prefer_width = 40, -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        width = nil,
        -- min_width and max_width can be a list of mixed types.
        -- min_width = {20, 0.2} means "the greater of 20 columns or 20% of total"
        max_width = { 140, 0.9 },
        min_width = { 20, 0.2 },
        buf_options = {},
        win_options = {
          wrap = false, -- Disable line wrapping
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
        backend = { 'telescope', 'fzf_lua', 'fzf', 'builtin', 'nui' }, -- Priority list of preferred vim.select implementations
        trim_prompt = true, -- Trim trailing `:` from prompt

        -- Options for telescope selector
        -- These are passed into the telescope picker directly. Can be used like:
        -- telescope = require('telescope.themes').get_ivy({...})
        telescope = nil,

        -- Options for fzf selector
        fzf = {
          window = {
            width = 0.5,
            height = 0.4,
          },
        },

        -- Options for fzf-lua
        fzf_lua = {
          -- winopts = {
          --   height = 0.5,
          --   width = 0.5,
          -- },
        },

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
        -- get_config = function(opts)
        --   if opts.kind == 'codeaction' then
        --     return {
        --       backend = 'nui',
        --       nui = {
        --         relative = 'cursor',
        --         max_width = 40,
        --       },
        --     }
        --   end
        -- end,
      },
    },
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require('lazy').load { plugins = { 'dressing.nvim' } }
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require('lazy').load { plugins = { 'dressing.nvim' } }
        return vim.ui.input(...)
      end
    end,
  },

  -- This is what powers fancy-looking tabs, which include filetype icons and close buttons.
  -- see: `:h bufferline`
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    keys = {
      { '<leader>bp', '<Cmd>BufferLineTogglePin<CR>', desc = 'Toggle pin' },
      { '<leader>bP', '<Cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Delete non-pinned buffers' },
      { '<leader>bo', '<Cmd>BufferLineCloseOthers<CR>', desc = 'Delete other buffers' },
      { '<leader>br', '<Cmd>BufferLineCloseRight<CR>', desc = 'Delete buffers to the right' },
      { '<leader>bl', '<Cmd>BufferLineCloseLeft<CR>', desc = 'Delete buffers to the left' },
      { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer' },
      { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer' },
      { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer' },
      { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer' },
    },
    opts = {
      options = {
        mode = 'buffers', -- Set to "tabs" to only show tabpages instead
        -- style_preset = require('bufferline').style_preset.minimal, -- or style_preset.minimal
        themable = true, --Allows highlight groups to be overriden i.e. sets highlights as default
        numbers = 'ordinal', -- "none" | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
        -- stylua: ignore
        close_command = function(n) require("mini.bufremove").delete(n, false) end, -- can be a string | function, see "Mouse actions"
        -- stylua: ignore
        right_mouse_command = function(n) require("mini.bufremove").delete(n, false) end, -- can be a string | function, see "Mouse actions"
        left_mouse_command = 'buffer %d', -- can be a string | function, see "Mouse actions"
        middle_mouse_command = nil, -- can be a string | function, see "Mouse actions"
        indicator = { style = 'icon', icon = '▎' },
        buffer_close_icon = '',
        modified_icon = '●',
        close_icon = '',
        left_trunc_marker = '',
        right_trunc_marker = '',
        --- name_formatter can be used to change the buffer's label in the bufferline.
        --- Please note some names can/will break the
        --- bufferline so use this at your discretion knowing that it has
        --- some limitations that will *NOT* be fixed.
        -- name_formatter = function(buf)  -- buf contains a "name", "path" and "bufnr"
        --   -- remove extension from markdown files for example
        --   if buf.name:match('%.md') then
        --     return vim.fn.fnamemodify(buf.name, ':t:r')
        --   end
        -- end,
        max_name_length = 30,
        max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
        truncate_names = true, -- Whether ot not tab names should be truncated
        tab_size = 18,
        diagnostics = false, -- | "nvim_lsp" | "coc" | false
        diagnostics_update_in_insert = false,
        -- NOTE: this will be called a lot so don't do any heavy processing here
        -- custom_filter = function(buf_number)
        --   -- filter out filetypes you don't want to see
        --   if vim.bo[buf_number].filetype ~= "<i-dont-want-to-see-this>" then
        --     return true
        --   end
        --   -- filter out by buffer name
        --   if vim.fn.bufname(buf_number) ~= "<buffer-name-I-dont-want>" then
        --     return true
        --   end
        --   -- filter out based on arbitrary rules
        --   -- e.g. filter out vim wiki buffer from tabline in your work repo
        --   if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
        --     return true
        --   end
        -- end,
        color_icons = true, -- Whether or not to add the filetype icon to highlights
        -- get_element_icon = function(element)
        --   -- element consists of {filetype: string, path: string, extension: string, directory: string}
        --   -- This can be used to change how bufferline fetches the icon
        --   -- for an element e.g. a buffer or a tab.
        --   -- e.g.
        --   local icon, hl = require('nvim-web-devicons').get_icon_by_filetype(element.filetype, { default = false })
        --   return icon, hl
        --   -- or
        --   local custom_map = {my_thing_ft: {icon = "my_thing_icon", hl}}
        --   return custom_map[element.filetype]
        -- end,
        show_buffer_icons = true, -- Disable filetype icons for buffers
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        show_duplicate_prefix = true, -- Whether to show duplicate buffer prefix
        persist_buffer_sort = true, -- Whether or not custom sorted buffers should persist
        move_wraps_at_ends = false, -- whether or not the move command "wraps" at the first or last position
        -- can also be a table containing 2 custom separators
        -- [focused and unfocused]. eg: { '|', '|' }
        separator_style = 'slant', -- 'slant' | 'slope' | 'thick' | 'thin' | { 'any', 'any' },
        enforce_regular_tabs = true,
        always_show_bufferline = false,
        hover = {
          enabled = true,
          delay = 200,
          reveal = { 'close' },
        },
        -- sort_by = 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
        --   -- add custom logic
        --   return buffer_a.modified > buffer_b.modified
        -- end
        diagnostics_indicator = function(_, _, diag)
          local icons = require('config').icons.diagnostics
          local ret = (diag.error and icons.Error .. diag.error .. ' ' or '') .. (diag.warning and icons.Warn .. diag.warning or '')
          return vim.trim(ret)
        end,
        offsets = {
          {
            filetype = 'neo-tree',
            text = 'Explorer',
            highlight = 'Directory',
            text_align = 'left',
          },
        },
      },
    },
    config = function(_, opts)
      require('bufferline').setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd('BufAdd', {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },

  -- [[lualine] statusline configuration
  -- see: `h: lualine`
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    -- init = function()
    --   vim.g.lualine_laststatus = vim.o.laststatus
    --   if vim.fn.argc(-1) > 0 then
    --     -- set an empty statusline till lualine loads
    --     vim.o.statusline = ' '
    --   else
    --     -- hide the statusline on the starter page
    --     vim.o.laststatus = 0
    --   end
    -- end,
    config = function(_, opts)
      require('lualine').setup(opts)
    end,
    opts = function()
      local icons = require('config').icons
      return {
        options = {
          icons_enabled = true,
          theme = 'everforest',
          -- section_separators = { left = '', right = '' },
          -- component_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = { statusline = { 'dashboard', 'alpha', 'starter' } },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = true,
          refresh = {
            statusline = 500,
            tabline = 500,
            winbar = 500,
          },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_c = {
            'hostname',
          },
          lualine_x = {
            -- stylua: ignore
            {
              function() return require("noice").api.status.command.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
              color = Util.ui.fg("Statement"),
            },
            -- stylua: ignore
            {
              function() return require("noice").api.status.mode.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
              color = Util.ui.fg("Constant"),
            },
            -- stylua: ignore
            {
              function() return "  " .. require("dap").status() end,
              cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
              color = Util.ui.fg("Debug"),
            },
            {
              require('lazy.status').updates,
              cond = require('lazy.status').has_updates,
              color = Util.ui.fg 'Special',
            },
            { 'searchcount' },
            { 'selectioncount' },
          },
          lualine_y = {
            { 'progress', separator = ' ', padding = { left = 1, right = 0 } },
            { 'location', padding = { left = 0, right = 1 } },
          },
          lualine_z = {
            'datetime',
          },
        },
        inactive_sections = {},
        tabline = {},
        winbar = {
          lualine_a = {
            Util.lualine.root_dir(),
          },
          lualine_b = {
            { Util.lualine.pretty_path() },
          },
          lualine_c = {
            {
              'diff',
              symbols = {
                added = icons.git.added,
                modified = icons.git.modified,
                removed = icons.git.removed,
              },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end,
            },
            {
              'diagnostics',
              symbols = {
                error = icons.diagnostics.Error,
                warn = icons.diagnostics.Warn,
                info = icons.diagnostics.Info,
                hint = icons.diagnostics.Hint,
              },
            },
          },
          lualine_x = {
            {
              'filetype',
              icon_only = false,
              colored = true,
              separator = '',
              padding = { left = 1, right = 1 },
              icon = {
                align = 'right',
              },
            },
            { 'encoding' },
            { 'fileformat' },
            { 'filesize' },
          },
          lualine_y = {},
          lualine_z = {},
        },
        inactive_winbar = {},
        extensions = { 'neo-tree', 'lazy' },
      }
    end,
  },

  -- indent guides for Neovim
  {
    'lukas-reineke/indent-blankline.nvim',
    event = 'VeryLazy',
    opts = {
      indent = {
        char = '│',
        tab_char = '│',
      },
      scope = { enabled = false },
      exclude = {
        filetypes = {
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
          'lazyterm',
        },
      },
    },
    main = 'ibl',
  },

  -- Active indent guide and indent text objects. When you're browsing
  -- code, this highlights the current level of indentation, and animates
  -- the highlighting.
  {
    'echasnovski/mini.indentscope',
    version = false, -- wait till new 0.7.0 release to put it back on semver
    event = 'VeryLazy',
    opts = {
      -- symbol = "▏",
      symbol = '│',
      options = { try_as_border = true },
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
          'lazyterm',
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },

  -- Displays a popup with possible key bindings of the command you started typing
  {
    'folke/which-key.nvim',
    opts = function(_, opts)
      if require('util').has 'noice.nvim' then
        opts.defaults['<leader>sn'] = { name = '+noice' }
      end
    end,
  },

  -- Highly experimental plugin that completely replaces the UI for messages, cmdline and the popupmenu.
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
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
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
      },
    },
    -- stylua: ignore
    keys = {
      { "<S-Enter>",   function() require("noice").redirect(vim.fn.getcmdline()) end,                 mode = "c",                 desc = "Redirect Cmdline" },
      { "<leader>snl", function() require("noice").cmd("last") end,                                   desc = "Noice Last Message" },
      { "<leader>snh", function() require("noice").cmd("history") end,                                desc = "Noice History" },
      { "<leader>sna", function() require("noice").cmd("all") end,                                    desc = "Noice All" },
      { "<leader>snd", function() require("noice").cmd("dismiss") end,                                desc = "Dismiss All" },
      { "<c-f>",       function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end,  silent = true,              expr = true,              desc = "Scroll forward",  mode = { "i", "n", "s" } },
      { "<c-b>",       function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true,              expr = true,              desc = "Scroll backward", mode = { "i", "n", "s" } },
    },
  },

  -- icons
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- ui components
  { 'MunifTanjim/nui.nvim', lazy = true },

  {
    'nvimdev/dashboard-nvim',
    event = 'VimEnter',
    dependencies = { { 'nvim-tree/nvim-web-devicons' } },
    opts = function()
      local logo = [[
           ██╗   ██╗██╗███╗   ███╗
           ██║   ██║██║████╗ ████║
           ██║   ██║██║██╔████╔██║
           ╚██╗ ██╔╝██║██║╚██╔╝██║
            ╚████╔╝ ██║██║ ╚═╝ ██║
             ╚═══╝  ╚═╝╚═╝     ╚═╝
      ]]

      logo = string.rep('\n', 8) .. logo .. '\n\n'

      local opts = {
        theme = 'hyper',
        hide = {
          -- this is taken care of by lualine
          -- enabling this messes up the actual laststatus setting after loading a file
          statusline = false,
        },
        config = {
          week_header = {
            enable = true,
          },
          header = vim.split(logo, '\n'),
          -- stylua: ignore
          shortcut = {
            {
              desc = '󰊳 Lazy Update',
              group = '@property',
              action = 'Lazy update',
              key = 'u'
            },
            {
              icon = ' ',
              icon_hl = '@variable',
              desc = 'Find Files',
              group = 'Label',
              action = 'Telescope find_files',
              key = 'f',
            },
            {
              desc = ' Apps',
              group = 'DiagnosticHint',
              action = 'Telescope app',
              key = 'a',
            },
            {
              desc = ' Theme',
              group = 'Number',
              action = 'Telescope colorscheme',
              key = 'd',
            },
          },
          center = {
            { action = 'Telescope find_files', desc = ' Find file', icon = ' ', key = 'f' },
            { action = 'ene | startinsert', desc = ' New file', icon = ' ', key = 'n' },
            { action = 'Telescope oldfiles', desc = ' Recent files', icon = ' ', key = 'r' },
            { action = 'Telescope live_grep', desc = ' Find text', icon = ' ', key = 'g' },
            { action = [[lua require("util").telescope.config_files()()]], desc = ' Config', icon = ' ', key = 'c' },
            { action = 'lua require("persistence").load()', desc = ' Restore Session', icon = ' ', key = 's' },
            { action = 'Lazy', desc = ' Lazy', icon = '󰒲 ', key = 'l' },
            { action = 'Mason', desc = ' Mason', icon = ' ', key = 'm' },
            { action = 'qa', desc = ' Quit', icon = ' ', key = 'q' },
          },
          footer = function()
            local stats = require('lazy').stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            return { '⚡ Neovim loaded ' .. stats.loaded .. '/' .. stats.count .. ' plugins in ' .. ms .. 'ms' }
          end,
        },
      }

      for _, button in ipairs(opts.config.center) do
        button.desc = button.desc .. string.rep(' ', 43 - #button.desc)
        button.key_format = '  %s'
      end

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

  -- Vim help shown in flaoting popup
  {
    'Tyler-Barham/floating-help.nvim',
    config = function()
      require('floating-help').setup {
        -- Defaults
        width = 90, -- Whole numbers are columns/rows
        height = 0.9, -- Decimals are a percentage of the editor
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
    event = { 'VeryLazy' },
    keys = {
      { '<F1>', '<cmd>FloatingHelpToggle<cr>', mode = { 'n' }, desc = 'Toggle Floating Help' },
    },
  },

  -- Show lightbulb where code action is available
  {
    'kosayoda/nvim-lightbulb',
    config = function()
      require('nvim-lightbulb').setup {
        autocmd = { enabled = true },
      }
    end,
  },

  -- Show preview when jumping to line with `:{number}`
  {
    'nacro90/numb.nvim',
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

  -- Rainbow colored delimiters
  {
    'HiPhish/rainbow-delimiters.nvim',
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
        priority = {
          [''] = 110,
          lua = 210,
        },
        highlight = {
          'RainbowDelimiterRed',
          'RainbowDelimiterYellow',
          'RainbowDelimiterBlue',
          'RainbowDelimiterOrange',
          'RainbowDelimiterGreen',
          'RainbowDelimiterViolet',
          'RainbowDelimiterCyan',
        },
      }
    end,
  },

  -- Scroll bar for nvim
  {
    'petertriho/nvim-scrollbar',
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
        marks = {
          Cursor = {
            text = '•',
            priority = 0,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'Normal',
          },
          Search = {
            text = { '-', '=' },
            priority = 1,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'Search',
          },
          Error = {
            text = { '-', '=' },
            priority = 2,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'DiagnosticVirtualTextError',
          },
          Warn = {
            text = { '-', '=' },
            priority = 3,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'DiagnosticVirtualTextWarn',
          },
          Info = {
            text = { '-', '=' },
            priority = 4,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'DiagnosticVirtualTextInfo',
          },
          Hint = {
            text = { '-', '=' },
            priority = 5,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'DiagnosticVirtualTextHint',
          },
          Misc = {
            text = { '-', '=' },
            priority = 6,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'Normal',
          },
          GitAdd = {
            text = '┆',
            priority = 7,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'GitSignsAdd',
          },
          GitChange = {
            text = '┆',
            priority = 7,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'GitSignsChange',
          },
          GitDelete = {
            text = '▁',
            priority = 7,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = 'GitSignsDelete',
          },
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
          gitsigns = false, -- Requires gitsigns
          handle = true,
          search = false, -- Requires hlslens
          ale = false, -- Requires ALE
        },
      }
    end,
  },

  -- helps better glance at matched information, jump between matched instances.
  {
    'kevinhwang91/nvim-hlslens',
    config = function()
      -- require('hlslens').setup() is not required
      require('scrollbar.handlers.search').setup {
        -- hlslens config overrides
      }
    end,
  },

  -- Allows to decide where to split a window
  {
    's1n7ax/nvim-window-picker',
    name = 'window-picker',
    event = 'VeryLazy',
    version = '2.*',
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
          selection_display = function(char, windowid)
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

      -- You can pass in the highlight name or a table of content to set as
      -- highlight
      highlights = {
        statusline = {
          focused = {
            fg = '#ededed',
            bg = '#e35e4f',
            bold = true,
          },
          unfocused = {
            fg = '#ededed',
            bg = '#44cc41',
            bold = true,
          },
        },
        winbar = {
          focused = {
            fg = '#ededed',
            bg = '#e35e4f',
            bold = true,
          },
          unfocused = {
            fg = '#ededed',
            bg = '#44cc41',
            bold = true,
          },
        },
      },
    },
    config = function(_, opts)
      require('window-picker').setup(opts)
    end,
  },

  -- Creates distraction free view for smooth coding
  {
    'folke/zen-mode.nvim',
    keys = {
      {
        '<leader>Z',
        '<cmd>ZenMode<cr>',
        mode = { 'n' },
        desc = 'Zen Mode',
      },
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
        gitsigns = { enabled = false }, -- disables git signs
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
        -- See alse also the Plugins/Wezterm section in this projects README
        wezterm = {
          enabled = false,
          -- can be either an absolute font size or the number of incremental steps
          font = '+4', -- (10% increase per step)
        },
      },
      -- callback where you can add custom code when the Zen window opens
      on_open = function(win) end,
      -- callback where you can add custom code when the Zen window closes
      on_close = function() end,
    },
  },
}
