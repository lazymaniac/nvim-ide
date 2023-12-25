local Util = require 'util'

return {

  -- file explorer
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    cmd = 'Neotree',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      '3rd/image.nvim',
    },
    keys = {
      {
        '<leader>fe',
        function()
          require('neo-tree.command').execute { action = 'focus', position = 'left', dir = Util.root() }
        end,
        desc = 'Explorer NeoTree (root dir)',
      },
      {
        '<leader>fE',
        function()
          require('neo-tree.command').execute { action = 'focus', position = 'left', dir = vim.loop.cwd() }
        end,
        desc = 'Explorer NeoTree (cwd)',
      },
      {
        '<leader>e',
        function()
          require('neo-tree.command').execute { action = 'focus', position = 'float', dir = Util.root() }
        end,
        desc = 'Explorer NeoTree (root dir)',
      },
      {
        '<leader>E',
        function()
          require('neo-tree.command').execute { action = 'focus', position = 'float', dir = vim.loop.cwd() }
        end,
        desc = 'Explorer NeoTree (cwd)',
      },
      {
        '<leader>ge',
        function()
          require('neo-tree.command').execute { source = 'git_status', action = 'focus', position = 'float' }
        end,
        desc = 'Git explorer',
      },
      {
        '<leader>be',
        function()
          require('neo-tree.command').execute { source = 'buffers', action = 'focus', position = 'float' }
        end,
        desc = 'Buffer explorer',
      },
    },
    deactivate = function()
      vim.cmd [[Neotree close]]
    end,
    init = function()
      if vim.fn.argc(-1) == 1 then
        local stat = vim.loop.fs_stat(vim.fn.argv(0))
        if stat and stat.type == 'directory' then
          require 'neo-tree'
        end
      end
    end,
    opts = {
      close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
      popup_border_style = 'rounded',
      enable_git_status = true,
      enable_diagnostics = true,
      enable_normal_mode_for_inputs = false, -- Enable normal mode for input dialogs.
      open_files_do_not_replace_types = { 'terminal', 'Trouble', 'trouble', 'qf', 'Outline' },
      sort_case_insensitive = false, -- used when sorting files and directories in the tree
      sort_function = nil, -- use a custom function for sorting files and directories in the tree
      -- sort_function = function (a,b)
      --       if a.type == b.type then
      --           return a.path > b.path
      --       else
      --           return a.type > b.type
      --       end
      --   end , -- this sorts files and directories descendantly
      default_component_configs = {
        container = {
          enable_character_fade = true,
        },
        indent = {
          indent_size = 2,
          padding = 1, -- extra padding on left hand side
          -- indent guides
          with_markers = true,
          indent_marker = '│',
          last_indent_marker = '└',
          highlight = 'NeoTreeIndentMarker',
          -- expander config, needed for nesting files
          with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
          expander_collapsed = '',
          expander_expanded = '',
          expander_highlight = 'NeoTreeExpander',
        },
        icon = {
          folder_closed = '',
          folder_open = '',
          folder_empty = '󰜌',
          -- The next two settings are only a fallback, if you use nvim-web-devicons and configure default icons there
          -- then these will never be used.
          default = '*',
          highlight = 'NeoTreeFileIcon',
        },
        modified = {
          symbol = '[+]',
          highlight = 'NeoTreeModified',
        },
        name = {
          trailing_slash = true,
          use_git_status_colors = true,
          highlight = 'NeoTreeFileName',
        },
        git_status = {
          symbols = {
            -- Change type
            added = '✚', -- or "✚", but this is redundant info if you use git_status_colors on the name
            modified = '', -- or "", but this is redundant info if you use git_status_colors on the name
            deleted = '✖', -- this can only be used in the git_status source
            renamed = '󰁕', -- this can only be used in the git_status source
            -- Status type
            untracked = '',
            ignored = '',
            unstaged = '󰄱',
            staged = '',
            conflict = '',
          },
        },
        -- If you don't want to use these columns, you can set `enabled = false` for each of them individually
        file_size = {
          enabled = true,
          required_width = 80, -- min width of window required to show this column
        },
        type = {
          enabled = true,
          required_width = 132, -- min width of window required to show this column
        },
        last_modified = {
          enabled = true,
          required_width = 88, -- min width of window required to show this column
        },
        created = {
          enabled = true,
          required_width = 110, -- min width of window required to show this column
        },
        symlink_target = {
          enabled = false,
        },
      },
      -- A list of functions, each representing a global custom command
      -- that will be available in all sources (if not overridden in `opts[source_name].commands`)
      -- see `:h neo-tree-custom-commands-global`
      commands = {},
      sources = {
        'filesystem',
        'buffers',
        'git_status',
        'document_symbols',
        'netman.ui.neo-tree',
      },
      source_selector = {
        winbar = true,
        statusline = false,
        sources = {
          {
            source = 'filesystem',
            display_name = ' Files ',
          },
          {
            source = 'buffers',
            display_name = ' Buffers ',
          },
          {
            source = 'git_status',
            display_name = ' Git ',
          },
          {
            source = 'document_symbols',
            display_name = ' Symbols ',
          },
          {
            source = 'remote',
            display_name = ' Network ',
          },
        },
      },
      window = {
        position = 'left',
        width = 50,
        mapping_options = {
          noremap = true,
          nowait = true,
        },
        mappings = {
          ['<space>'] = {
            'toggle_node',
            nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
          },
          ['<2-LeftMouse>'] = 'open',
          ['<cr>'] = 'open',
          ['<esc>'] = 'cancel', -- close preview or floating neo-tree window
          ['P'] = { 'toggle_preview', config = { use_float = true, use_image_nvim = true } },
          -- Read `# Preview Mode` for more information
          ['l'] = 'focus_preview',
          -- ["S"] = "open_split",
          -- ["s"] = "open_vsplit",
          ['S'] = 'split_with_window_picker',
          ['s'] = 'vsplit_with_window_picker',
          -- ["t"] = "open_tabnew",
          -- ["<cr>"] = "open_drop",
          ['t'] = 'open_tab_drop',
          ['w'] = 'open_with_window_picker',
          --["P"] = "toggle_preview", -- enter preview mode, which shows the current node without focusing
          ['C'] = 'close_node',
          -- ['C'] = 'close_all_subnodes',
          ['z'] = 'close_all_nodes',
          ['Z'] = 'expand_all_nodes',
          ['a'] = {
            'add',
            -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
            -- some commands may take optional config options, see `:h neo-tree-mappings` for details
            config = {
              show_path = 'none', -- "none", "relative", "absolute"
            },
          },
          ['A'] = 'add_directory', -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
          ['d'] = 'delete',
          ['r'] = 'rename',
          ['y'] = 'copy_to_clipboard',
          ['x'] = 'cut_to_clipboard',
          ['p'] = 'paste_from_clipboard',
          ['c'] = 'copy', -- takes text input for destination, also accepts the optional config.show_path option like "add":
          -- ["c"] = {
          --  "copy",
          --  config = {
          --    show_path = "none" -- "none", "relative", "absolute"
          --  }
          --}
          ['m'] = 'move', -- takes text input for destination, also accepts the optional config.show_path option like "add".
          ['q'] = 'close_window',
          ['R'] = 'refresh',
          ['?'] = 'show_help',
          ['<'] = 'prev_source',
          ['>'] = 'next_source',
          ['i'] = 'show_file_details',
        },
      },
      nesting_rules = {},
      filesystem = {
        bind_to_cwd = true,
        filtered_items = {
          visible = true, -- when true, they will just be displayed differently than normal items
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_hidden = false, -- only works on Windows for hidden files/directories
          hide_by_name = {
            --"node_modules"
          },
          hide_by_pattern = { -- uses glob style patterns
            --"*.meta",
            --"*/src/*/tsconfig.json",
          },
          always_show = { -- remains visible even if other settings would normally hide it
            --".gitignored",
          },
          never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
            --".DS_Store",
            --"thumbs.db"
          },
          never_show_by_pattern = { -- uses glob style patterns
            --".null-ls_*",
          },
        },
        follow_current_file = {
          enabled = true, -- This will find and focus the file in the active buffer every time
          --               -- the current file is changed while the tree is open.
          leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
        },
        group_empty_dirs = true, -- when true, empty folders will be grouped together
        hijack_netrw_behavior = 'open_default', -- netrw disabled, opening a directory opens neo-tree
        -- in whatever position is specified in window.position
        -- "open_current",  -- netrw disabled, opening a directory opens within the
        -- window like netrw would, regardless of window.position
        -- "disabled",    -- netrw left alone, neo-tree does not handle opening dirs
        use_libuv_file_watcher = true, -- This will use the OS level file watchers to detect changes
        -- instead of relying on nvim autocmd events.
        window = {
          popup = {
            position = { col = '100%', row = 2 },
            size = function()
              return {
                width = 60,
                height = vim.o.lines - 6,
              }
            end,
          },
          mappings = {
            ['<space>'] = 'none',
            ['<bs>'] = 'navigate_up',
            ['.'] = 'set_root',
            ['H'] = 'toggle_hidden',
            ['/'] = 'fuzzy_finder',
            ['D'] = 'fuzzy_finder_directory',
            ['#'] = 'fuzzy_sorter', -- fuzzy sorting using the fzy algorithm
            -- ["D"] = "fuzzy_sorter_directory",
            ['f'] = 'filter_on_submit',
            ['<c-x>'] = 'clear_filter',
            ['[g'] = 'prev_git_modified',
            [']g'] = 'next_git_modified',
            ['o'] = { 'show_help', nowait = false, config = { title = 'Order by', prefix_key = 'o' } },
            ['oc'] = { 'order_by_created', nowait = false },
            ['od'] = { 'order_by_diagnostics', nowait = false },
            ['og'] = { 'order_by_git_status', nowait = false },
            ['om'] = { 'order_by_modified', nowait = false },
            ['on'] = { 'order_by_name', nowait = false },
            ['os'] = { 'order_by_size', nowait = false },
            ['ot'] = { 'order_by_type', nowait = false },
          },
          fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
            ['<down>'] = 'move_cursor_down',
            ['<C-n>'] = 'move_cursor_down',
            ['<up>'] = 'move_cursor_up',
            ['<C-p>'] = 'move_cursor_up',
          },
        },

        commands = {}, -- Add a custom command or override a global one using the same function name
      },
      buffers = {
        follow_current_file = {
          enabled = true, -- This will find and focus the file in the active buffer every time
          --              -- the current file is changed while the tree is open.
          leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
        },
        group_empty_dirs = true, -- when true, empty folders will be grouped together
        show_unloaded = true,
        window = {
          popup = {
            position = { col = '100%', row = 2 },
            size = function()
              return {
                width = 60,
                height = vim.o.lines - 6,
              }
            end,
          },
          mappings = {
            ['bd'] = 'buffer_delete',
            ['<bs>'] = 'navigate_up',
            ['.'] = 'set_root',
            ['o'] = { 'show_help', nowait = false, config = { title = 'Order by', prefix_key = 'o' } },
            ['oc'] = { 'order_by_created', nowait = false },
            ['od'] = { 'order_by_diagnostics', nowait = false },
            ['om'] = { 'order_by_modified', nowait = false },
            ['on'] = { 'order_by_name', nowait = false },
            ['os'] = { 'order_by_size', nowait = false },
            ['ot'] = { 'order_by_type', nowait = false },
          },
        },
      },
      git_status = {
        window = {
          popup = {
            position = { col = '100%', row = 2 },
            size = function()
              return {
                width = 60,
                height = vim.o.lines - 6,
              }
            end,
          },
          position = 'float',
          mappings = {
            ['A'] = 'git_add_all',
            ['gu'] = 'git_unstage_file',
            ['ga'] = 'git_add_file',
            ['gr'] = 'git_revert_file',
            ['gc'] = 'git_commit',
            ['gp'] = 'git_push',
            ['gg'] = 'git_commit_and_push',
            ['o'] = { 'show_help', nowait = false, config = { title = 'Order by', prefix_key = 'o' } },
            ['oc'] = { 'order_by_created', nowait = false },
            ['od'] = { 'order_by_diagnostics', nowait = false },
            ['om'] = { 'order_by_modified', nowait = false },
            ['on'] = { 'order_by_name', nowait = false },
            ['os'] = { 'order_by_size', nowait = false },
            ['ot'] = { 'order_by_type', nowait = false },
          },
        },
      },
      document_symbols = {
        window = {
          popup = {
            position = { col = '100%', row = 2 },
            size = function()
              return {
                width = 60,
                height = vim.o.lines - 6,
              }
            end,
          },
          mappings = {
            ['<CR>'] = 'open',
            ['x'] = 'none',
            ['m'] = 'none',
            ['A'] = 'none',
            ['y'] = 'none',
            ['i'] = 'none',
            ['d'] = 'none',
            ['c'] = 'none',
            ['a'] = 'none',
            ['p'] = 'none',
          },
        },
      },
      remote = {
        window = {
          popup = {
            position = { col = '100%', row = 2 },
            size = function()
              return {
                width = 60,
                height = vim.o.lines - 6,
              }
            end,
          },
        },
      },
    },
    config = function(_, opts)
      local function on_move(data)
        Util.lsp.on_rename(data.source, data.destination)
      end

      local events = require 'neo-tree.events'
      opts.event_handlers = opts.event_handlers or {}
      vim.list_extend(opts.event_handlers, {
        { event = events.FILE_MOVED, handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
      })
      require('neo-tree').setup(opts)
      vim.api.nvim_create_autocmd('TermClose', {
        pattern = '*lazygit',
        callback = function()
          if package.loaded['neo-tree.sources.git_status'] then
            require('neo-tree.sources.git_status').refresh()
          end
        end,
      })
    end,
  },

  -- search/replace in multiple files
  {
    'nvim-pack/nvim-spectre',
    build = false,
    cmd = 'Spectre',
    opts = { open_cmd = 'noswapfile vnew' },
    -- stylua: ignore
    keys = {
      { "<leader>sr", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
    },
  },

  -- Fuzzy finder.
  -- The default key bindings to find files will use Telescope's
  -- `find_files` or `git_files` depending on whether the
  -- directory is a git repo.
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    version = false, -- telescope did only one release, so use HEAD for now
    dependencies = {
      {
        'rcarriga/nvim-notify',
        config = function()
          Util.on_load('telescope.nvim', function()
            require('telescope').load_extension 'notify'
          end)
        end,
      },
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        enabled = vim.fn.executable 'make' == 1,
        config = function()
          Util.on_load('telescope.nvim', function()
            require('telescope').load_extension 'fzf'
          end)
        end,
      },
    },
    keys = {
      {
        '<leader>,',
        '<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>',
        desc = 'Switch Buffer',
      },
      { '<leader>/', Util.telescope 'live_grep', desc = 'Grep (root dir)' },
      { '<leader>:', '<cmd>Telescope command_history<cr>', desc = 'Command History' },
      { '<leader><space>', Util.telescope 'files', desc = 'Find Files (root dir)' },
      -- find
      { '<leader>fb', '<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>', desc = 'Buffers' },
      { '<leader>fc', Util.telescope.config_files(), desc = 'Find Config File' },
      { '<leader>ff', Util.telescope 'files', desc = 'Find Files (root dir)' },
      { '<leader>fF', Util.telescope('files', { cwd = false }), desc = 'Find Files (cwd)' },
      { '<leader>fr', '<cmd>Telescope oldfiles<cr>', desc = 'Recent' },
      { '<leader>fR', Util.telescope('oldfiles', { cwd = vim.loop.cwd() }), desc = 'Recent (cwd)' },
      -- git
      { '<leader>gc', '<cmd>Telescope git_commits<CR>', desc = 'commits' },
      { '<leader>gs', '<cmd>Telescope git_status<CR>', desc = 'status' },
      -- search
      { '<leader>s"', '<cmd>Telescope registers<cr>', desc = 'Registers' },
      { '<leader>sa', '<cmd>Telescope autocommands<cr>', desc = 'Auto Commands' },
      { '<leader>sb', '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = 'Buffer' },
      { '<leader>sc', '<cmd>Telescope command_history<cr>', desc = 'Command History' },
      { '<leader>sC', '<cmd>Telescope commands<cr>', desc = 'Commands' },
      { '<leader>sd', '<cmd>Telescope diagnostics bufnr=0<cr>', desc = 'Document diagnostics' },
      { '<leader>sD', '<cmd>Telescope diagnostics<cr>', desc = 'Workspace diagnostics' },
      { '<leader>sg', Util.telescope 'live_grep', desc = 'Grep (root dir)' },
      { '<leader>sG', Util.telescope('live_grep', { cwd = false }), desc = 'Grep (cwd)' },
      { '<leader>sh', '<cmd>Telescope help_tags<cr>', desc = 'Help Pages' },
      { '<leader>sH', '<cmd>Telescope highlights<cr>', desc = 'Search Highlight Groups' },
      { '<leader>sk', '<cmd>Telescope keymaps<cr>', desc = 'Key Maps' },
      { '<leader>sM', '<cmd>Telescope man_pages<cr>', desc = 'Man Pages' },
      { '<leader>sm', '<cmd>Telescope marks<cr>', desc = 'Jump to Mark' },
      { '<leader>so', '<cmd>Telescope vim_options<cr>', desc = 'Options' },
      { '<leader>sR', '<cmd>Telescope resume<cr>', desc = 'Resume' },
      { '<leader>sw', Util.telescope('grep_string', { word_match = '-w' }), desc = 'Word (root dir)' },
      { '<leader>sW', Util.telescope('grep_string', { cwd = false, word_match = '-w' }), desc = 'Word (cwd)' },
      { '<leader>sw', Util.telescope 'grep_string', mode = 'v', desc = 'Selection (root dir)' },
      { '<leader>sW', Util.telescope('grep_string', { cwd = false }), mode = 'v', desc = 'Selection (cwd)' },
      { '<leader>uC', Util.telescope('colorscheme', { enable_preview = true }), desc = 'Colorscheme with preview' },
      {
        '<leader>ss',
        function()
          require('telescope.builtin').lsp_document_symbols {
            symbols = require('config').get_kind_filter(),
          }
        end,
        desc = 'Goto Symbol',
      },
      {
        '<leader>sS',
        function()
          require('telescope.builtin').lsp_dynamic_workspace_symbols {
            symbols = require('config').get_kind_filter(),
          }
        end,
        desc = 'Goto Symbol (Workspace)',
      },
      {
        '<leader>sN',
        function()
          require('telescope').extensions.notify.notify()
        end,
        desc = 'Notifications',
      },
      {
        '<leader>fp',
        function()
          require('telescope.builtin').find_files { cwd = require('lazy.core.config').options.root }
        end,
        desc = 'Find Plugin File',
      },
    },
    opts = function()
      local actions = require 'telescope.actions'

      local open_with_trouble = function(...)
        return require('trouble.providers.telescope').open_with_trouble(...)
      end
      local open_selected_with_trouble = function(...)
        return require('trouble.providers.telescope').open_selected_with_trouble(...)
      end
      local find_files_no_ignore = function()
        local action_state = require 'telescope.actions.state'
        local line = action_state.get_current_line()
        Util.telescope('find_files', { no_ignore = true, default_text = line })()
      end
      local find_files_with_hidden = function()
        local action_state = require 'telescope.actions.state'
        local line = action_state.get_current_line()
        Util.telescope('find_files', { hidden = true, default_text = line })()
      end

      return {
        defaults = {
          layout_strategy = 'horizontal',
          layout_config = { prompt_position = 'top' },
          sorting_strategy = 'ascending',
          winblend = 0,
          prompt_prefix = ' ',
          selection_caret = ' ',
          -- open files in the first window that is an actual file.
          -- use the current window if no other window is available.
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == '' then
                return win
              end
            end
            return 0
          end,
          mappings = {
            i = {
              ['<c-t>'] = open_with_trouble,
              ['<a-t>'] = open_selected_with_trouble,
              ['<a-i>'] = find_files_no_ignore,
              ['<a-h>'] = find_files_with_hidden,
              ['<C-Down>'] = actions.cycle_history_next,
              ['<C-Up>'] = actions.cycle_history_prev,
              ['<C-f>'] = actions.preview_scrolling_down,
              ['<C-b>'] = actions.preview_scrolling_up,
            },
            n = {
              ['q'] = actions.close,
            },
          },
        },
      }
    end,
  },

  -- Flash enhances the built-in search functionality by showing labels
  -- at the end of each match, letting you quickly jump to a specific
  -- location.
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    vscode = true,
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
      { "S",     mode = { "n", "o", "x" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
      { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
      { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
    },
  },

  -- Flash Telescope config
  {
    'nvim-telescope/telescope.nvim',
    optional = true,
    opts = function(_, opts)
      if not Util.has 'flash.nvim' then
        return
      end
      local function flash(prompt_bufnr)
        require('flash').jump {
          pattern = '^',
          label = { after = { 0, 0 } },
          search = {
            mode = 'search',
            exclude = {
              function(win)
                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'TelescopeResults'
              end,
            },
          },
          action = function(match)
            local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
            picker:set_selection(match.pos[1] - 1)
          end,
        }
      end
      opts.defaults = vim.tbl_deep_extend('force', opts.defaults or {}, {
        mappings = { n = { s = flash }, i = { ['<c-s>'] = flash } },
      })
    end,
  },

  -- which-key helps you remember key bindings by showing a popup
  -- with the active keybindings of the command you started typing.
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      plugins = {
        spelling = {
          enabled = true, -- Enabling this will show WhichKey when pressing z= to select spelling suggestion
          suggestions = 20, -- How many suggestions should be shown in the list?
        },
        marks = true, -- Show a list of marks on ' and `
        registers = true, -- Shows registers on " in NORMAL or <C-r> in INSERT mode
      },

      -- The presets plugin, adds help for bunch of default keybindings in Neovim
      -- No actual keybindings are created
      presets = {
        oprators = true, -- Adds help for operators like d, y, ... and registers them for motion / text completion
        motions = true, -- Adds help for motions
        text_objects = true, -- Adds help for text objects triggered after entering an operator
        windows = true, -- Help for windows. Default bindings on <C-w>
        nav = true, -- Misc bindings to work with windows
        z = true, -- Bindings for folds, spelling and other prefixed with z
        g = true, -- Bindings for prefixed with g
      },

      -- Add operators that will trigger motion and text objects completion.
      -- To enable all native operators, set the preset / operators plugin
      -- above
      operators = { gc = 'Comments' },

      key_labels = {
        -- Override the label used to display some keys. It doesn't effect
        -- WK in any other way
        -- For example:
        -- ["<space>"] = "SPC",
        -- ["<CR>"] = "RET",
        -- ["<TAB>"] = "TAB",
      },
      icons = {
        breadcrumb = '»', -- symbol used in the command line area that shows your active key combo
        separator = '➜', -- symbol used between a key and it's label
        group = '+', -- symbol prepended to a group
      },
      popup_mappings = {
        scroll_down = '<c-d>', -- binding to scroll down inside the popup
        scroll_up = '<c-u>', -- binding to scroll up inside the popup
      },
      window = {
        border = 'rounded', -- none, single, double, shadow, rounded
        position = 'bottom', -- bottom, top
        margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
        padding = { 1, 1, 1, 1 }, -- extra window padding [top, right, bottom, left]
        winblend = 0,
      },
      layout = {
        height = { min = 4, max = 25 }, -- min and max height of the columns
        width = { min = 20, max = 50 }, -- min and max width of the columns
        spacing = 3, -- spacing between columns
        align = 'left', -- align columns left, center or right
      },
      ignore_missing = false,
      hidden = { '<silent>', '<cmd>', '<Cmd>', '<CR>', 'call', 'lua', '^:', '^ ' }, -- hide mapping boilerplate
      show_help = true, -- show help message on the command line when the popup is visible
      triggers = 'auto', -- automatically setup triggers
      -- triggers = {"<leader>"} -- or specify a list manually
      triggers_blacklist = {
        -- list of mode / prefixes that should never be hooked by WhichKey
        -- this is mostly relevant for key maps that start with a native binding
        -- most people should not need to change this
        i = { 'j', 'k' },
        v = { 'j', 'k' },
      },
      defaults = {
        mode = { 'n', 'v' },
        ['g'] = { name = '+goto' },
        ['gs'] = { name = '+surround' },
        [']'] = { name = '+next' },
        ['['] = { name = '+prev' },
        ['<leader><tab>'] = { name = '+tabs' },
        ['<leader>b'] = { name = '+buffer' },
        ['<leader>c'] = { name = '+code' },
        ['<leader>f'] = { name = '+file/find' },
        ['<leader>g'] = { name = '+git' },
        ['<leader>gh'] = { name = '+hunks' },
        ['<leader>q'] = { name = '+quit/session' },
        ['<leader>s'] = { name = '+search' },
        ['<leader>u'] = { name = '+ui' },
        ['<leader>w'] = { name = '+windows' },
        ['<leader>x'] = { name = '+diagnostics/quickfix' },
      },
    },
    config = function(_, opts)
      local wk = require 'which-key'
      wk.setup(opts)
      wk.register(opts.defaults)
    end,
  },

  -- git signs highlights text that has changed since the list
  -- git commit, and also lets you interactively stage & unstage
  -- hunks in a commit.
  {
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    opts = {
      signs = {
        add = { hl = 'GitSignsAdd', text = ' ', numhl = 'GitSignsAddNr', linehl = 'GitSignsAddLn' },
        change = { hl = 'GitSignsChange', text = ' ', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
        delete = { hl = 'GitSignsDelete', text = ' ', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
        topdelete = { hl = 'GitSignsDelete', text = '󱅁 ', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
        changedelete = { hl = 'GitSignsChange', text = '󰍷 ', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
        untracked = { text = '▎' },
      },
      signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
      numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
      },
      current_line_blame_formatter_opts = {
        relative_time = false,
      },
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil, -- Use default
      max_file_length = 40000,
      preview_config = {
        -- Options passed to nvim_open_win
        border = 'single',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1,
      },
      yadm = {
        enable = false,
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- stylua: ignore start
        -- Navigation
        map({"n", "v"}, "]h", function ()
          if vim.wo.diff then
            return ']h'
          end
          vim.schedule(function ()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, {expr = true, desc = "Jump to next hunk"})

        map({"n", "v"}, "[h", function ()
          if vim.wo.diff then
            return "[h"
          end
          vim.schedule(function ()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Jump to prev hunk"})

        -- Actions
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")

        -- Toggles
        map('n', '<leader>ghtb', gs.toggle_current_line_blame, "Toggle line blame")
        map("n", '<leader>ghtd', gs.toggle_deleted, "Toggle git show deleted")
      end,
    },
  },

  -- Git related plugins
  {
    'tpope/vim-fugitive',
  },
  {
    'tpope/vim-rhubarb',
  },

  -- Detect tabstop and shiftwidth automatically
  {
    'tpope/vim-sleuth',
  },

  -- Automatically highlights other instances of the word under your cursor.
  -- This works with LSP, Treesitter, and regexp matching to find the other
  -- instances.
  {
    'RRethy/vim-illuminate',
    event = 'VeryLazy',
    opts = {
      delay = 200,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { 'lsp' },
      },
    },
    config = function(_, opts)
      require('illuminate').configure(opts)

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
    keys = {
      { ']]', desc = 'Next Reference' },
      { '[[', desc = 'Prev Reference' },
    },
  },

  -- buffer remove
  {
    'echasnovski/mini.bufremove',

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
        desc = 'Delete Buffer',
      },
      -- stylua: ignore
      { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete Buffer (Force)" },
    },
  },

  -- better diagnostics list and others
  {
    'folke/trouble.nvim',
    cmd = { 'TroubleToggle', 'Trouble' },
    opts = { use_diagnostic_signs = true },
    keys = {
      { '<leader>xx', '<cmd>TroubleToggle document_diagnostics<cr>', desc = 'Document Diagnostics (Trouble)' },
      { '<leader>xX', '<cmd>TroubleToggle workspace_diagnostics<cr>', desc = 'Workspace Diagnostics (Trouble)' },
      { '<leader>xL', '<cmd>TroubleToggle loclist<cr>', desc = 'Location List (Trouble)' },
      { '<leader>xQ', '<cmd>TroubleToggle quickfix<cr>', desc = 'Quickfix List (Trouble)' },
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
        desc = 'Previous trouble/quickfix item',
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
        desc = 'Next trouble/quickfix item',
      },
    },
  },

  -- Diagnostics text objects
  --
  -- keymapping | function | purpose
  -- ig | require('textobj-diagnostic').next_diag_inclusive() | finds the diagnostic under or after the cursor (including any diagnostic the cursor is sitting on)
  -- ]g | require('textobj-diagnostic').next_diag() | finds the diagnostic after the cursor (excluding any diagnostic the cursor is sitting on)
  -- [g | require('textobj-diagnostic').prev_diag() | finds the diagnostic before the cursor (excluding any diagnostic the cursor is sitting on)
  -- No mapping by default | require('textobj-diagnostic').nearest_diag() | find the diagnostic nearest to the cursor, under, before, or after, taking into account both vertical and horizontal distance
  {
    'andrewferrier/textobj-diagnostic.nvim',
    config = function()
      require('textobj-diagnostic').setup()
    end,
  },

  -- Finds and lists all of the TODO, HACK, BUG, etc comment
  -- in your project and loads them into a browsable list.
  {
    'folke/todo-comments.nvim',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = 'VeryLazy',
    config = true,
    -- stylua: ignore
    keys = {
      { "]t",         function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      { "[t",         function() require("todo-comments").jump_prev() end, desc = "Previous todo comment" },
      { "<leader>xt", "<cmd>TodoTrouble<cr>",                              desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>",      desc = "Todo/Fix/Fixme (Trouble)" },
      { "<leader>st", "<cmd>TodoTelescope<cr>",                            desc = "Todo" },
      { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>",    desc = "Todo/Fix/Fixme" },
    },
  },

  -- Show next key clue
  {
    'echasnovski/mini.clue',
    version = false,
  },

  -- Show symbols outline for current buffer
  {
    'hedyhli/outline.nvim',
    keys = {
      {
        '<leader>o',
        '<cmd>Outline<cr>',
        mode = { 'n' },
        desc = 'Toggle outline',
      },
    },
    config = function()
      require('outline').setup {
        outline_window = {
          -- Where to open the split window: right/left
          position = 'right',
          -- The default split commands used are 'topleft vs' and 'botright vs'
          -- depending on `position`. You can change this by providing your own
          -- `split_command`.
          -- `position` will not be considered if `split_command` is non-nil.
          -- This should be a valid vim command used for opening the split for the
          -- outline window. Eg, 'rightbelow vsplit'.
          split_command = nil,

          -- Percentage or integer of columns
          width = 20,
          -- Whether width is relative to the total width of nvim
          -- When relative_width = true, this means take 25% of the total
          -- screen width for outline window.
          relative_width = true,

          -- Auto close the outline window if goto_location is triggered and not for
          -- peek_location
          auto_close = false,
          -- Automatically scroll to the location in code when navigating outline window.
          auto_jump = false,
          -- boolean or integer for milliseconds duration to apply a temporary highlight
          -- when jumping. false to disable.
          jump_highlight_duration = 300,
          -- Whether to center the cursor line vertically in the screen when
          -- jumping/focusing. Executes zz.
          center_on_jump = true,

          -- Vim options for the outline window
          show_numbers = false,
          show_relative_numbers = false,
          wrap = false,

          -- true/false/'focus_in_outline'/'focus_in_code'.
          -- The last two means only show cursorline when the focus is in outline/code.
          -- 'focus_in_outline' can be used if the outline_items.auto_set_cursor
          -- operations are too distracting due to visual contrast caused by cursorline.
          show_cursorline = true,
          -- Enable this only if you enabled cursorline so your cursor color can
          -- blend with the cursorline, in effect, as if your cursor is hidden
          -- in the outline window.
          -- This makes your line of cursor have the same color as if the cursor
          -- wasn't focused on the outline window.
          -- This feature is experimental.
          hide_cursor = false,

          -- Whether to auto-focus on the outline window when it is opened.
          -- Set to false to *always* retain focus on your previous buffer when opening
          -- outline.
          -- If you enable this you can still use bangs in :Outline! or :OutlineOpen! to
          -- retain focus on your code. If this is false, retaining focus will be
          -- enforced for :Outline/:OutlineOpen and you will not be able to have the
          -- other behaviour.
          focus_on_open = true,
          -- Winhighlight option for outline window.
          -- See :help 'winhl'
          -- To change background color to "CustomHl" for example, use "Normal:CustomHl".
          winhl = '',
        },

        outline_items = {
          -- Show extra details with the symbols (lsp dependent) as virtual next
          show_symbol_details = true,
          -- Show corresponding line numbers of each symbol on the left column as
          -- virtual text, for quick navigation when not focused on outline.
          -- Why? See this comment:
          -- https://github.com/simrat39/symbols-outline.nvim/issues/212#issuecomment-1793503563
          show_symbol_lineno = true,
          -- Whether to highlight the currently hovered symbol and all direct parents
          highlight_hovered_item = true,
          -- Whether to automatically set cursor location in outline to match
          -- location in code when focus is in code. If disabled you can use
          -- `:OutlineFollow[!]` from any window or `<C-g>` from outline window to
          -- trigger this manually.
          auto_set_cursor = true,
          -- Autocmd events to automatically trigger these operations.
          auto_update_events = {
            -- Includes both setting of cursor and highlighting of hovered item.
            -- The above two options are respected.
            -- This can be triggered manually through `follow_cursor` lua API,
            -- :OutlineFollow command, or <C-g>.
            follow = { 'CursorMoved' },
            -- Re-request symbols from the provider.
            -- This can be triggered manually through `refresh_outline` lua API, or
            -- :OutlineRefresh command.
            items = { 'InsertLeave', 'WinEnter', 'BufEnter', 'BufWinEnter', 'TabEnter', 'BufWritePost' },
          },
        },

        -- Options for outline guides which help show tree hierarchy of symbols
        guides = {
          enabled = true,
          markers = {
            -- It is recommended for bottom and middle markers to use the same number
            -- of characters to align all child nodes vertically.
            bottom = '└',
            middle = '├',
            vertical = '│',
          },
        },

        symbol_folding = {
          -- Depth past which nodes will be folded by default. Set to false to unfold all on open.
          autofold_depth = 1,
          -- When to auto unfold nodes
          auto_unfold = {
            -- Auto unfold currently hovered symbol
            hovered = true,
            -- Auto fold when the root level only has this many nodes.
            -- Set true for 1 node, false for 0.
            only = true,
          },
          markers = { '', '' },
        },

        preview_window = {
          -- Automatically open preview of code location when navigating outline window
          auto_preview = true,
          -- Automatically open hover_symbol when opening preview (see keymaps for
          -- hover_symbol).
          -- If you disable this you can still open hover_symbol using your keymap
          -- below.
          open_hover_on_preview = false,
          width = 50, -- Percentage or integer of columns
          min_width = 50, -- This is the number of columns
          -- Whether width is relative to the total width of nvim.
          -- When relative_width = true, this means take 50% of the total
          -- screen width for preview window, ensure the result width is at least 50
          -- characters wide.
          relative_width = true,
          -- Border option for floating preview window.
          -- Options include: single/double/rounded/solid/shadow or an array of border
          -- characters.
          -- See :help nvim_open_win() and search for "border" option.
          border = 'single',
          -- winhl options for the preview window, see ':h winhl'
          winhl = 'NormalFloat:',
          -- Pseudo-transparency of the preview window, see ':h winblend'
          winblend = 0,
          -- Experimental feature that let's you edit the source content live
          -- in the preview window. Like VS Code's "peek editor".
          live = false,
        },

        -- These keymaps can be a string or a table for multiple keys.
        -- Set to `{}` to disable. (Using 'nil' will fallback to default keys)
        keymaps = {
          show_help = '?',
          close = { '<Esc>', 'q' },
          -- Jump to symbol under cursor.
          -- It can auto close the outline window when triggered, see
          -- 'auto_close' option above.
          goto_location = '<Cr>',
          -- Jump to symbol under cursor but keep focus on outline window.
          peek_location = 'o',
          -- Visit location in code and close outline immediately
          goto_and_close = '<S-Cr>',
          -- Change cursor position of outline window to match current location in code.
          -- 'Opposite' of goto/peek_location.
          restore_location = '<C-g>',
          -- Open LSP/provider-dependent symbol hover information
          hover_symbol = '<C-space>',
          -- Preview location code of the symbol under cursor
          toggle_preview = 'K',
          rename_symbol = 'r',
          code_actions = 'a',
          -- These fold actions are collapsing tree nodes, not code folding
          fold = 'h',
          unfold = 'l',
          fold_toggle = '<Tab>',
          -- Toggle folds for all nodes.
          -- If at least one node is folded, this action will fold all nodes.
          -- If all nodes are folded, this action will unfold all nodes.
          fold_toggle_all = '<S-Tab>',
          fold_all = 'W',
          unfold_all = 'E',
          fold_reset = 'R',
          -- Move down/up by one line and peek_location immediately.
          -- You can also use outline_window.auto_jump=true to do this for any
          -- j/k/<down>/<up>.
          down_and_jump = '<C-j>',
          up_and_jump = '<C-k>',
        },

        providers = {
          priority = { 'lsp', 'coc', 'markdown', 'norg' },
          lsp = {
            -- Lsp client names to ignore
            blacklist_clients = {},
          },
        },

        symbols = {
          -- Filter by kinds (string) for symbols in the outline.
          -- Possible kinds are the Keys in the icons table below.
          -- A filter list is a string[] with an optional exclude (boolean) field.
          -- The symbols.filter option takes either a filter list or ft:filterList
          -- key-value pairs.
          -- Put  exclude=true  in the string list to filter by excluding the list of
          -- kinds instead.
          -- Include all except String and Constant:
          --   filter = { 'String', 'Constant', exclude = true }
          -- Only include Package, Module, and Function:
          --   filter = { 'Package', 'Module', 'Function' }
          -- See more examples below.
          filter = nil,

          -- You can use a custom function that returns the icon for each symbol kind.
          -- This function takes a kind (string) as parameter and should return an
          -- icon as string.
          icon_fetcher = nil,
          -- 3rd party source for fetching icons. Fallback if icon_fetcher returned
          -- empty string. Currently supported values: 'lspkind'
          icon_source = nil,
          -- The next fallback if both icon_fetcher and icon_source has failed, is
          -- the custom mapping of icons specified below. The icons table is also
          -- needed for specifying hl group.
          icons = {
            File = { icon = '󰈔', hl = 'Identifier' },
            Module = { icon = '󰆧', hl = 'Include' },
            Namespace = { icon = '󰅪', hl = 'Include' },
            Package = { icon = '󰏗', hl = 'Include' },
            Class = { icon = '𝓒', hl = 'Type' },
            Method = { icon = 'ƒ', hl = 'Function' },
            Property = { icon = '', hl = 'Identifier' },
            Field = { icon = '󰆨', hl = 'Identifier' },
            Constructor = { icon = '', hl = 'Special' },
            Enum = { icon = 'ℰ', hl = 'Type' },
            Interface = { icon = '󰜰', hl = 'Type' },
            Function = { icon = '', hl = 'Function' },
            Variable = { icon = '', hl = 'Constant' },
            Constant = { icon = '', hl = 'Constant' },
            String = { icon = '𝓐', hl = 'String' },
            Number = { icon = '#', hl = 'Number' },
            Boolean = { icon = '⊨', hl = 'Boolean' },
            Array = { icon = '󰅪', hl = 'Constant' },
            Object = { icon = '⦿', hl = 'Type' },
            Key = { icon = '🔐', hl = 'Type' },
            Null = { icon = 'NULL', hl = 'Type' },
            EnumMember = { icon = '', hl = 'Identifier' },
            Struct = { icon = '𝓢', hl = 'Structure' },
            Event = { icon = '🗲', hl = 'Type' },
            Operator = { icon = '+', hl = 'Identifier' },
            TypeParameter = { icon = '𝙏', hl = 'Identifier' },
            Component = { icon = '󰅴', hl = 'Function' },
            Fragment = { icon = '󰅴', hl = 'Constant' },
            TypeAlias = { icon = ' ', hl = 'Type' },
            Parameter = { icon = ' ', hl = 'Identifier' },
            StaticMethod = { icon = ' ', hl = 'Function' },
            Macro = { icon = ' ', hl = 'Function' },
          },
        },
      }
    end,
  },
}
