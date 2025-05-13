return {

  -- [[ GIT ]] ---------------------------------------------------------------

  -- [gitsigns.nvim] - git signs highlights text that has changed since the list
  -- git commit, and also lets you interactively stage & unstage
  -- hunks in a commit.
  -- see: `:h gitsigns`
  -- link: https://github.com/lewis6991/gitsigns.nvim
  {
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    config = function(_, opts)
      local wk = require 'which-key'
      local defaults = {
        { '<leader>gu', group = '+[buffer]' },
        { '<leader>gut', group = '+[toggle]' },
      }
      wk.add(defaults)
      require('gitsigns').setup(opts)
    end,
    opts = {
      signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
      numhl = true, -- Toggle with `:Gitsigns toggle_numhl`
      linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
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
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end
        -- Navigation
        map({ 'n', 'v' }, ']h', function()
          if vim.wo.diff then
            return ']h'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, 'Jump to next hunk <]h>')
        map({ 'n', 'v' }, '[h', function()
          if vim.wo.diff then
            return '[h'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, 'Jump to prev hunk <[h>')
        -- Actions
        map({ 'n', 'v' }, '<leader>gus', ':Gitsigns stage_hunk<CR>', 'Stage Hunk [gus]')
        map({ 'n', 'v' }, '<leader>gur', ':Gitsigns reset_hunk<CR>', 'Reset Hunk [gur]')
        map('n', '<leader>guS', gs.stage_buffer, 'Stage Buffer [guS]')
        map('n', '<leader>guu', gs.undo_stage_hunk, 'Undo Stage Hunk [guu]')
        map('n', '<leader>guR', gs.reset_buffer, 'Reset Buffer [guR]')
        map('n', '<leader>gup', gs.preview_hunk_inline, 'Preview Hunk [gup]')
        map('n', '<leader>gub', function()
          gs.blame_line { full = true }
        end, 'Blame Line [gub]')
        map('n', '<leader>gud', gs.diffthis, 'Diff This [gud]')
        map('n', '<leader>guD', function()
          gs.diffthis '~'
        end, 'Diff This ~ [guD]')
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'GitSigns Select Hunk <ih>')
        -- Toggles
        map('n', '<leader>gutb', gs.toggle_current_line_blame, 'Toggle line blame [gutb]')
        map('n', '<leader>gutd', gs.toggle_deleted, 'Toggle git show deleted [gutd]')
        map('n', '<leader>guts', gs.toggle_signs, 'Toggle signs [guts]')
      end,
    },
  },
}
