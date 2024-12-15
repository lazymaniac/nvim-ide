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

  -- [bufferline.nvim] - This is what powers fancy-looking tabs, which include filetype icons and close buttons.
  -- see: `:h bufferline`
  -- link: https://github.com/akinsho/bufferline.nvim
  {
    'akinsho/bufferline.nvim',
    branch = 'main',
    event = 'VeryLazy',
    keys = {
      { '<leader>bp', '<Cmd>BufferLineTogglePin<CR>', desc = 'Toggle pin [bp]' },
      { '<leader>bP', '<Cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Delete non-pinned buffers [bP]' },
      { '<leader>bo', '<Cmd>BufferLineCloseOthers<CR>', desc = 'Delete other buffers [bo]' },
      { '<leader>br', '<Cmd>BufferLineCloseRight<CR>', desc = 'Delete buffers to the right [br]' },
      { '<leader>bl', '<Cmd>BufferLineCloseLeft<CR>', desc = 'Delete buffers to the left [bl]' },
      { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer <S-h>' },
      { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer <S-l>' },
      { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer <[b>' },
      { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer <]b>' },
    },
    opts = {
      options = {
        mode = 'buffers', -- Set to "tabs" to only show tabpages instead
        -- style_preset = require('bufferline').style_preset.minimal, -- or style_preset.minimal
        themable = true, --Allows highlight groups to be overridden i.e. sets highlights as default
        numbers = 'ordinal', -- "none" | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
        close_command = function(n)
          require('mini.bufremove').delete(n, false)
        end, -- can be a string | function, see "Mouse actions"
        right_mouse_command = function(n)
          require('mini.bufremove').delete(n, false)
        end, -- can be a string | function, see "Mouse actions"
        left_mouse_command = 'buffer %d', -- can be a string | function, see "Mouse actions"
        middle_mouse_command = nil, -- can be a string | function, see "Mouse actions"
        indicator = { style = 'icon', icon = '▎' },
        buffer_close_icon = ' ',
        modified_icon = '●',
        close_icon = ' ',
        left_trunc_marker = ' ',
        right_trunc_marker = ' ',
        max_name_length = 30,
        max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
        truncate_names = true, -- Whether or not tab names should be truncated
        tab_size = 18,
        diagnostics = false, -- | "nvim_lsp" | "coc" | false
        diagnostics_update_in_insert = false,
        color_icons = true, -- Whether or not to add the filetype icon to highlights
        show_buffer_icons = true, -- Disable filetype icons for buffers
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        show_duplicate_prefix = true, -- Whether to show duplicate buffer prefix
        persist_buffer_sort = true, -- Whether or not custom sorted buffers should persist
        move_wraps_at_ends = true, -- whether or not the move command "wraps" at the first or last position
        -- can also be a table containing 2 custom separators
        -- [focused and unfocused]. eg: { '|', '|' }
        separator_style = { '|' }, -- 'slant' | 'slope' | 'thick' | 'thin' | { 'any', 'any' },
        enforce_regular_tabs = true,
        always_show_bufferline = false,
        hover = {
          enabled = true,
          delay = 200,
          reveal = { 'close' },
        },
        sort_by = nil, -- 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
        --   -- add custom logic
        -- return buffer_a.modified > buffer_b.modified
        -- end,
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
            ---@diagnostic disable-next-line: undefined-global
            pcall(nvim_bufferline)
          end)
        end,
      })
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
