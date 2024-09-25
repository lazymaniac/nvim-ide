local Util = require 'util'

local popup = {
  position = { col = '100%', row = 2 },
  size = function()
    return {
      width = 50,
      height = vim.o.lines - 4,
    }
  end,
}

return {

  -- [[ EXPLORERS ]] ---------------------------------------------------------------
  -- [neo-tree.nvim] - Explorer for files, buffer, git changes, symbols, remote
  -- see: `:h neo-tree.txt`
  -- link: https://github.com/nvim-neo-tree/neo-tree.nvim
  {
    'nvim-neo-tree/neo-tree.nvim',
    event = 'VeryLazy',
    branch = 'main',
    cmd = 'Neotree',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      '3rd/image.nvim',
    },
    keys = {
      {
        '<leader>e',
        function()
          local reveal_file = vim.fn.expand '%:p'
          if reveal_file == '' then
            reveal_file = vim.fn.getcwd()
          else
            local f = io.open(reveal_file, 'r')
            if f then
              f.close(f)
            else
              reveal_file = vim.fn.getcwd()
            end
          end
          require('neo-tree.command').execute {
            action = 'focus', -- OPTIONAL, this is the default value
            source = 'filesystem', -- OPTIONAL, this is the default value
            position = 'float', -- OPTIONAL, this is the default value
            reveal_file = reveal_file, -- path to file or folder to reveal
            reveal_force_cwd = true, -- change cwd without asking if needed
            dir = Util.root(),
          }
        end,
        desc = 'File Explorer [e]',
      },
      {
        '<leader>E',
        function()
          local reveal_file = vim.fn.expand '%:p'
          if reveal_file == '' then
            reveal_file = vim.fn.getcwd()
          else
            local f = io.open(reveal_file, 'r')
            if f then
              f.close(f)
            else
              reveal_file = vim.fn.getcwd()
            end
          end
          require('neo-tree.command').execute {
            action = 'focus',
            source = 'filesystem',
            position = 'right',
            reveal_file = reveal_file,
            reveal_force_cwd = true,
            dir = Util.root(),
          }
        end,
        desc = 'File Explorer (docked) [E]',
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
          enabled = true,
        },
      },
      -- A list of functions, each representing a global custom command
      -- that will be available in all sources (if not overridden in `opts[source_name].commands`)
      -- see `:h neo-tree-custom-commands-global`
      commands = {},
      sources = {
        'filesystem',
      },
      source_selector = {
        winbar = false,
        statusline = false,
        sources = {
          { source = 'filesystem', display_name = ' Files ' },
          { source = 'remote', display_name = ' Network ' },
        },
      },
      window = {
        position = 'right',
        width = 40,
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
          popup = popup,
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
      remote = {
        window = {
          popup = popup,
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

  -- [nvim-lsp-file-operations] - File operations supported by LSP
  -- see: `:h nvim-lsp-file-operations`
  -- link: https://github.com/antosha417/nvim-lsp-file-operations
  {
    'antosha417/nvim-lsp-file-operations',
    branch = 'master',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neo-tree/neo-tree.nvim',
    },
    config = function()
      require('lsp-file-operations').setup {
        -- used to see debug logs in file `vim.fn.stdpath("cache") .. lsp-file-operations.log`
        debug = false,
        -- select which file operations to enable
        operations = {
          willRenameFiles = true,
          didRenameFiles = true,
          willCreateFiles = true,
          didCreateFiles = true,
          willDeleteFiles = true,
          didDeleteFiles = true,
        },
        -- how long to wait (in milliseconds) for file rename information before cancelling
        timeout_ms = 10000,
      }
    end,
  },
}
