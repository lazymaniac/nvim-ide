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

  -- [git-dev.nvim] - Use GitDevOpen <repo url> to open remote repo in neovim.
  -- see: `:h git-dev.nvim`
  -- link: https://github.com/moyiz/git-dev.nvim
  {
    'moyiz/git-dev.nvim',
    branch = 'master',
    event = 'VeryLazy',
    opts = {
      -- Whether to delete an opened repository when nvim exits.
      -- If `true`, it will create an auto command for opened repositories
      -- to delete the local directory when nvim exists.
      ephemeral = true,
      -- Set buffers of opened repositories to be read-only and unmodifiable.
      read_only = false,
      -- Whether / how to CD into opened repository.
      -- Options: global|tab|window|none
      cd_type = 'global',
      -- Location of cloned repositories. Should be dedicated for this purpose.
      repositories_dir = vim.fn.stdpath 'cache' .. '/git-dev',
      -- Extend the builtin URL parsers.
      -- Should map domains to parse functions. See |parser.lua|.
      extra_domain_to_parser = nil,
      git = {
        -- Name / path of `git` command.
        command = 'git',
        -- Default organization if none is specified.
        -- If given repository name does not contain '/' and `default_org` is
        -- not `nil` nor empty, it will be prepended to the given name.
        default_org = nil,
        -- Base URI to use when given repository name is scheme-less.
        base_uri_format = 'https://github.com/%s.git',
        -- Arguments for `git clone`.
        -- Triggered when repository does not exist locally.
        -- It will clone submodules too, disable it if it is too slow.
        clone_args = '--jobs=2 --single-branch --recurse-submodules ' .. '--shallow-submodules',
        -- Arguments for `git fetch`.
        -- Triggered when repository is already exists locally to refresh the local
        -- copy.
        fetch_args = '--jobs=2 --no-all --update-shallow -f --prune --no-tags',
        -- Arguments for `git checkout`.
        -- Triggered when a branch, tag or commit is given.
        checkout_args = '-f --recurse-submodules',
      },
    },
  },
}
