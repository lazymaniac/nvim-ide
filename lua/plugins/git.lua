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

  -- [unified.nvim] - Single file diff viewer
  -- see: `:h unified.nvim`
  -- link: https://github.com/axkirillov/unified.nvim
  {
    'axkirillov/unified.nvim',
    keys = {
      { '<leader>gd', '<cmd>Unified<cr>', mode = { 'n' }, desc = 'Diff current file [gd]' },
    },
    opts = {
      signs = {
        add = '│',
        delete = '│',
        change = '│',
      },
      highlights = {
        add = 'DiffAdd',
        delete = 'DiffDelete',
        change = 'DiffChange',
      },
      line_symbols = {
        add = '+',
        delete = '-',
        change = '~',
      },
      auto_refresh = true, -- Whether to automatically refresh diff when buffer changes
    },
  },
}
