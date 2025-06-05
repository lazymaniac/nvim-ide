local Util = require 'util'
local map = Util.safe_keymap_set

return {

  -- [[ GIT ]] ---------------------------------------------------------------

  -- [gitsigns.nvim] - git signs highlights text that has changed since the list
  -- git commit, and also lets you interactively stage & unstage
  -- hunks in a commit.
  -- see: `:h gitsigns`
  -- link: https://github.com/lewis6991/gitsigns.nvim
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufReadPre',
    config = function()
      require('gitsigns').setup {
        signs = {
          add = { text = '┃' },
          change = { text = '┃' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },
        signs_staged = {
          add = { text = '┃' },
          change = { text = '┃' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },
        signs_staged_enable = true,
        signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
        numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir = {
          follow_files = true,
        },
        auto_attach = true,
        attach_to_untracked = true,
        current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
          delay = 1000,
          ignore_whitespace = false,
          virt_text_priority = 100,
          use_focus = true,
        },
        current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil, -- Use default
        max_file_length = 40000, -- Disable if file is longer than this (in lines)
        preview_config = {
          -- Options passed to nvim_open_win
          style = 'minimal',
          relative = 'cursor',
          row = 0,
          col = 1,
        },
        on_attach = function(bufnr)
          local gitsigns = require 'gitsigns'

          -- Navigation
          map('n', ']h', function()
            if vim.wo.diff then
              vim.cmd.normal { ']h', bang = true }
            else
              gitsigns.nav_hunk 'next'
            end
          end, { desc = 'Next hunk ]h]' })
          map('n', '[h', function()
            if vim.wo.diff then
              vim.cmd.normal { '[h', bang = true }
            else
              gitsigns.nav_hunk 'prev'
            end
          end, { desc = 'Prev hunk [h' })
          -- Actions
          map('n', '<leader>gs', gitsigns.stage_hunk, { desc = 'Stage hunk [gs]' })
          map('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'Reset hunk [gr]' })
          map('v', '<leader>gs', function()
            gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
          end, { desc = 'Stage hunk [gs]' })
          map('v', '<leader>gr', function()
            gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
          end, { desc = 'Reset hunk [gr]' })
          map('n', '<leader>gS', gitsigns.stage_buffer, { desc = 'Stage buffer [gS]' })
          map('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'Reset buffer [gR]' })
          map('n', '<leader>gp', gitsigns.preview_hunk, { desc = 'Preview hunk [gp]' })
          map('n', '<leader>gi', gitsigns.preview_hunk_inline, { desc = 'Preview hunk inline [gi]' })
          map('n', '<leader>gb', gitsigns.blame, { desc = 'Blame [gb]' })
          map('n', '<leader>gd', gitsigns.diffthis, { desc = 'Diff this [gd]' })
          map('n', '<leader>gD', function()
            gitsigns.diffthis '~'
          end, { desc = 'Diff this against HEAD [gD]' })
          map('n', '<leader>gQ', function()
            gitsigns.setqflist 'all'
          end, { desc = 'Set qflist with all hunks [gQ]' })
          map('n', '<leader>gq', gitsigns.setqflist, { desc = 'Set qflist with current hunk [gq]' })
          -- Toggles
          map('n', '<leader>gtb', gitsigns.toggle_current_line_blame, { desc = 'Toggle current line blame [gtb]' })
          map('n', '<leader>gtw', gitsigns.toggle_word_diff, { desc = 'Toggle word diff [gtw]' })
          -- Text object
          map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = 'Select hunk [ih]' })
        end,
      }
    end,
  },

  {
    'sindrets/diffview.nvim',
    event = 'VeryLazy',
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', mode = { 'n', 'v' }, desc = 'Open Diff View [gd]' },
      { '<leader>gq', '<cmd>DiffviewClose<cr>', mode = { 'n', 'v' }, desc = 'Close Diff View [gq]' },
      { '<leader>gf', '<cmd>DiffviewFileHistory<cr>', mode = { 'n', 'v' }, desc = 'Diff View File History [gf]' },
    },
    config = function()
      local actions = require 'diffview.actions'

      require('diffview').setup {
        diff_binaries = false, -- Show diffs for binaries
        enhanced_diff_hl = false, -- See |diffview-config-enhanced_diff_hl|
        git_cmd = { 'git' }, -- The git executable followed by default args.
        hg_cmd = { 'hg' }, -- The hg executable followed by default args.
        use_icons = true, -- Requires nvim-web-devicons
        show_help_hints = true, -- Show hints for how to open the help panel
        watch_index = true, -- Update views and index buffers when the git index changes.
        icons = { -- Only applies when use_icons is true.
          folder_closed = '',
          folder_open = '',
        },
        signs = {
          fold_closed = '',
          fold_open = '',
          done = '✓',
        },
        view = {
          -- Configure the layout and behavior of different types of views.
          -- Available layouts:
          --  'diff1_plain'
          --    |'diff2_horizontal'
          --    |'diff2_vertical'
          --    |'diff3_horizontal'
          --    |'diff3_vertical'
          --    |'diff3_mixed'
          --    |'diff4_mixed'
          -- For more info, see |diffview-config-view.x.layout|.
          default = {
            -- Config for changed files, and staged files in diff views.
            layout = 'diff2_horizontal',
            disable_diagnostics = false, -- Temporarily disable diagnostics for diff buffers while in the view.
            winbar_info = false, -- See |diffview-config-view.x.winbar_info|
          },
          merge_tool = {
            -- Config for conflicted files in diff views during a merge or rebase.
            layout = 'diff3_horizontal',
            disable_diagnostics = true, -- Temporarily disable diagnostics for diff buffers while in the view.
            winbar_info = true, -- See |diffview-config-view.x.winbar_info|
          },
          file_history = {
            -- Config for changed files in file history views.
            layout = 'diff2_horizontal',
            disable_diagnostics = false, -- Temporarily disable diagnostics for diff buffers while in the view.
            winbar_info = false, -- See |diffview-config-view.x.winbar_info|
          },
        },
        file_panel = {
          listing_style = 'tree', -- One of 'list' or 'tree'
          tree_options = { -- Only applies when listing_style is 'tree'
            flatten_dirs = true, -- Flatten dirs that only contain one single dir
            folder_statuses = 'only_folded', -- One of 'never', 'only_folded' or 'always'.
          },
          win_config = { -- See |diffview-config-win_config|
            position = 'left',
            width = 35,
            win_opts = {},
          },
        },
        file_history_panel = {
          log_options = { -- See |diffview-config-log_options|
            git = {
              single_file = {
                diff_merges = 'combined',
              },
              multi_file = {
                diff_merges = 'first-parent',
              },
            },
            hg = {
              single_file = {},
              multi_file = {},
            },
          },
          win_config = { -- See |diffview-config-win_config|
            position = 'bottom',
            height = 16,
            win_opts = {},
          },
        },
        commit_log_panel = {
          win_config = {}, -- See |diffview-config-win_config|
        },
        default_args = { -- Default args prepended to the arg-list for the listed commands
          DiffviewOpen = {},
          DiffviewFileHistory = {},
        },
        hooks = {}, -- See |diffview-config-hooks|
      }
    end,
  },
}
