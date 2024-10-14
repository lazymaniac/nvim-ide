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
        { '<leader>gb', group = '+[buffer]' },
        { '<leader>gbt', group = '+[toggle]' },
      }
      wk.add(defaults)
      require('gitsigns').setup(opts)
    end,
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
      current_line_blame_formatter_opts = {
        relative_time = true,
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
        map({ 'n', 'v' }, '<leader>gbs', ':Gitsigns stage_hunk<CR>', 'Stage Hunk [gbs]')
        map({ 'n', 'v' }, '<leader>gbr', ':Gitsigns reset_hunk<CR>', 'Reset Hunk [gbr]')
        map('n', '<leader>gbS', gs.stage_buffer, 'Stage Buffer [gbS]')
        map('n', '<leader>gbu', gs.undo_stage_hunk, 'Undo Stage Hunk [gbu]')
        map('n', '<leader>gbR', gs.reset_buffer, 'Reset Buffer [gbR]')
        map('n', '<leader>gbp', gs.preview_hunk_inline, 'Preview Hunk [gbp]')
        map('n', '<leader>gbb', function()
          gs.blame_line { full = true }
        end, 'Blame Line [gbb]')
        map('n', '<leader>gbd', gs.diffthis, 'Diff This [gbd]')
        map('n', '<leader>gbD', function()
          gs.diffthis '~'
        end, 'Diff This ~ [gbD]')
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'GitSigns Select Hunk <ih>')
        -- Toggles
        map('n', '<leader>gbtb', gs.toggle_current_line_blame, 'Toggle line blame [gbtb]')
        map('n', '<leader>gbtd', gs.toggle_deleted, 'Toggle git show deleted [gbtd]')
        map('n', '<leader>gbts', gs.toggle_signs, 'Toggle signs [gbts]')
      end,
    },
  },

  -- [diffview.nvim] - View files diff in neovim.
  -- see: `:h diffview.nvim`
  -- link: https://github.com/sindrets/diffview.nvim
  {
    'sindrets/diffview.nvim',
    branch = 'main',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>',        mode = { 'n', 'v' }, desc = 'Open Diff View [gd]' },
      { '<leader>gq', '<cmd>DiffviewClose<cr>',       mode = { 'n', 'v' }, desc = 'Close Diff View [gq]' },
      { '<leader>gf', '<cmd>DiffviewFileHistory<cr>', mode = { 'n', 'v' }, desc = 'Diff View File History [gf]' },
    },
    config = function()
      require('diffview').setup {
        diff_binaries = false, -- Show diffs for binaries
        enhanced_diff_hl = false, -- See ':h diffview-config-enhanced_diff_hl'
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
          -- For more info, see ':h diffview-config-view.x.layout'.
          default = {
            -- Config for changed files, and staged files in diff views.
            layout = 'diff2_horizontal',
            winbar_info = false, -- See ':h diffview-config-view.x.winbar_info'
          },
          merge_tool = {
            -- Config for conflicted files in diff views during a merge or rebase.
            layout = 'diff3_horizontal',
            disable_diagnostics = true, -- Temporarily disable diagnostics for conflict buffers while in the view.
            winbar_info = true, -- See ':h diffview-config-view.x.winbar_info'
          },
          file_history = {
            -- Config for changed files in file history views.
            layout = 'diff2_horizontal',
            winbar_info = false, -- See ':h diffview-config-view.x.winbar_info'
          },
        },
        file_panel = {
          listing_style = 'tree', -- One of 'list' or 'tree'
          tree_options = { -- Only applies when listing_style is 'tree'
            flatten_dirs = true, -- Flatten dirs that only contain one single dir
            folder_statuses = 'only_folded', -- One of 'never', 'only_folded' or 'always'.
          },
          win_config = { -- See ':h diffview-config-win_config'
            position = 'left',
            width = 35,
            win_opts = {},
          },
        },
        file_history_panel = {
          log_options = { -- See ':h diffview-config-log_options'
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
          win_config = { -- See ':h diffview-config-win_config'
            position = 'bottom',
            height = 16,
            win_opts = {},
          },
        },
        commit_log_panel = {
          win_config = { -- See ':h diffview-config-win_config'
            win_opts = {},
          },
        },
        default_args = { -- Default args prepended to the arg-list for the listed commands
          DiffviewOpen = {},
          DiffviewFileHistory = {},
        },
        hooks = {}, -- See ':h diffview-config-hooks'
        keymaps = {
          disable_defaults = false, -- Disable the default keymaps
        },
      }
    end,
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
