return {

  -- [[ GIT ]] ---------------------------------------------------------------
  -- [gitsigns.nvim] - git signs highlights text that has changed since the list
  -- git commit, and also lets you interactively stage & unstage
  -- hunks in a commit.
  -- see: `:h gitsigns`
  {
    'lewis6991/gitsigns.nvim',
    event = 'VeryLazy',
    config = function(_, opts)
      require('gitsigns').setup(opts)
      require('scrollbar.handlers.gitsigns').setup()
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
      linehl = true, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff = true, -- Toggle with `:Gitsigns toggle_word_diff`
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
        end, 'Jump to next hunk')
        map({ 'n', 'v' }, '[h', function()
          if vim.wo.diff then
            return '[h'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, 'Jump to prev hunk')
        -- Actions
        map({ 'n', 'v' }, '<leader>gbs', ':Gitsigns stage_hunk<CR>', 'Stage Hunk')
        map({ 'n', 'v' }, '<leader>gbr', ':Gitsigns reset_hunk<CR>', 'Reset Hunk')
        map('n', '<leader>gbS', gs.stage_buffer, 'Stage Buffer')
        map('n', '<leader>gbu', gs.undo_stage_hunk, 'Undo Stage Hunk')
        map('n', '<leader>gbR', gs.reset_buffer, 'Reset Buffer')
        map('n', '<leader>gbp', gs.preview_hunk_inline, 'Preview Hunk')
        map('n', '<leader>gbb', function()
          gs.blame_line { full = true }
        end, 'Blame Line')
        map('n', '<leader>gbd', gs.diffthis, 'Diff This')
        map('n', '<leader>gbD', function()
          gs.diffthis '~'
        end, 'Diff This ~')
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', 'GitSigns Select Hunk')
        -- Toggles
        map('n', '<leader>gbtb', gs.toggle_current_line_blame, 'Toggle line blame')
        map('n', '<leader>gbtd', gs.toggle_deleted, 'Toggle git show deleted')
        map('n', '<leader>gbts', gs.toggle_signs, 'Toggle signs')
      end,
    },
  },

  -- Add gitsigns group to which-key
  {
    'folke/which-key.nvim',
    optional = true,
    opts = {
      defaults = {
        ['<leader>gb'] = { name = '+[buffer]' },
        ['<leader>gbt'] = { name = '+[toggle]' },
      },
    },
  },

  --
  -- [gitlab.nvim] Gitlab integration
  --
  -- ## Usage
  -- First, check out the branch that you want to review locally.
  --
  -- git checkout feature-branch
  -- Then open Neovim. To begin, try running the summary command or the review command.
  --
  -- ## Connecting to Gitlab
  -- This plugin requires an auth token to connect to Gitlab. The token can be set in the root directory
  -- of the project in a .gitlab.nvim environment file, or can be set via a shell environment variable
  -- called GITLAB_TOKEN instead. If both are present, the .gitlab.nvim file will take precedence.
  --
  -- Optionally provide a GITLAB_URL environment variable (or gitlab_url value in the .gitlab.nvim file)
  -- to connect to a self-hosted Gitlab instance. This is optional, use ONLY for self-hosted instances.
  -- Here's what they'd look like as environment variables:
  --
  -- export GITLAB_TOKEN="your_gitlab_token"
  -- export GITLAB_URL="https://my-personal-gitlab-instance.com/"
  --
  -- And as a .gitlab.nvim file:
  -- auth_token=your_gitlab_token
  -- gitlab_url=https://my-personal-gitlab-instance.com/
  --
  -- The plugin will look for the .gitlab.nvim file in the root of the current project by default.
  -- However, you may provide a custom path to the configuration file via the config_path option. This
  -- must be an absolute path to the directory that holds your .gitlab.nvim file.
  {
    'harrisoncramer/gitlab.nvim',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
      'sindrets/diffview.nvim',
      'stevearc/dressing.nvim', -- Recommended but not required. Better UI for pickers.
      'nvim-tree/nvim-web-devicons', -- Recommended but not required. Icons in discussion tree.
      enabled = true,
    },
    -- stylua: ignore
    keys = {
      { '<leader>glr', function() require('gitlab').review() end, mode = { 'n' }, desc = 'Gitlab review' },
      { '<leader>gls', function() require('gitlab').summary() end, mode = { 'n' }, desc = 'Gitlab summary' },
      { '<leader>glA', function() require('gitlab').approve() end, mode = { 'n' }, desc = 'Gitlab approve' },
      { '<leader>glR', function() require('gitlab').revoke() end, mode = { 'n' }, desc = 'Gitlab revoke' },
      { '<leader>glc', function() require('gitlab').create_comment() end, mode = { 'n' }, desc = 'Gitlab create comment' },
      { '<leader>glc', function() require('gitlab').create_multiline_comment() end, mode = { 'v' }, desc = 'Gitlab create multiline comment' },
      { '<leader>glC', function() require('gitlab').create_comment_suggestion() end, mode = { 'v' }, desc = 'Gitlab create comment suggestion' },
      { '<leader>glm', function() require('gitlab').move_to_discussion_tree_from_diagnostic() end, mode = { 'n' }, desc = 'Gitlab move to discussion tree from diagnostics' },
      { '<leader>gln', function() require('gitlab').create_note() end, mode = { 'n' }, desc = 'Gitlab create note' },
      { '<leader>gld', function() require('gitlab').toggle_discussions() end, mode = { 'n' }, desc = 'Gitlab toggle discussion' },
      { '<leader>glPaa', function() require('gitlab').add_assignee() end, mode = { 'n' }, desc = 'Gitlab add assignee' },
      { '<leader>glPad', function() require('gitlab').delete_assignee() end, mode = { 'n' }, desc = 'Gitlab delete assignee' },
      { '<leader>glPra', function() require('gitlab').add_reviewer() end, mode = { 'n' }, desc = 'Gitlab add reviewer' },
      { '<leader>glPrd', function() require('gitlab').delete_reviewer() end, mode = { 'n' }, desc = 'Gitlab delete reviewer' },
      { '<leader>glp', function() require('gitlab').pipeline() end, mode = { 'n' }, desc = 'Gitlab pipeline' },
      { '<leader>glo', function() require('gitlab').open_in_browser() end, mode = { 'n' }, desc = 'Gitlab open in browser' },
      { '<leader>glB',
        function()
          local gitlab = require 'gitlab'
          require('gitlab.server').restart(function()
            vim.cmd.tabclose()
            gitlab.review()
          end)
        end,
        mode = { 'n' },
        desc = 'Gitlab refresh review',
      },
      { '<leader>glt', function() require('gitlab').print_settings() end, mode = { 'n' }, desc = 'Gitlab troubleshoot settings', },
    },
    opts = {
      port = nil, -- The port of the Go server, which runs in the background, if omitted or `nil` the port will be chosen automatically
      log_path = vim.fn.stdpath 'cache' .. '/gitlab.nvim.log', -- Log path for the Go server
      config_path = nil, -- Custom path for `.gitlab.nvim` file, please read the "Connecting to Gitlab" section
      debug = { go_request = false, go_response = false }, -- Which values to log
      attachment_dir = nil, -- The local directory for files (see the "summary" section)
      help = '?', -- Opens a help popup for local keymaps when a relevant view is focused (popup, discussion panel, etc)
      popup = { -- The popup for comment creation, editing, and replying
        exit = '<Esc>',
        perform_action = '<leader>s', -- Once in normal mode, does action (like saving comment or editing description, etc)
        perform_linewise_action = '<leader>l', -- Once in normal mode, does the linewise action (see logs for this job, etc)
        width = '40%',
        height = '60%',
        border = 'rounded', -- One of "rounded", "single", "double", "solid"
        opacity = 1.0, -- From 0.0 (fully transparent) to 1.0 (fully opaque)
        comment = nil, -- Individual popup overrides, e.g. { width = "60%", height = "80%", border = "single", opacity = 0.85 },
        edit = nil,
        note = nil,
        pipeline = nil,
        reply = nil,
      },
      discussion_tree = { -- The discussion tree that holds all comments
        auto_open = true, -- Automatically open when the reviewer is opened
        switch_view = 'T', -- Toggles between the notes and discussions views
        default_view = 'discussions', -- Show "discussions" or "notes" by default
        blacklist = {}, -- List of usernames to remove from tree (bots, CI, etc)
        jump_to_file = 'o', -- Jump to comment location in file
        jump_to_reviewer = 'm', -- Jump to the location in the reviewer window
        edit_comment = 'e', -- Edit comment
        delete_comment = 'dd', -- Delete comment
        reply = 'r', -- Reply to comment
        toggle_node = 't', -- Opens or closes the discussion
        toggle_resolved = 'p', -- Toggles the resolved status of the whole discussion
        position = 'left', -- "top", "right", "bottom" or "left"
        size = '20%', -- Size of split
        relative = 'editor', -- Position of tree split relative to "editor" or "window"
        resolved = '✓', -- Symbol to show next to resolved discussions
        unresolved = '✖', -- Symbol to show next to unresolved discussions
        tree_type = 'simple', -- Type of discussion tree - "simple" means just list of discussions, "by_file_name" means file tree with discussions under file
        winbar = nil, -- Custom function to return winbar title, should return a string. Provided with WinbarTable (defined in annotations.lua)
        -- If using lualine, please add "gitlab" to disabled file types, otherwise you will not see the winbar.
      },
      info = { -- Show additional fields in the summary pane
        enabled = true,
        horizontal = false, -- Display metadata to the left of the summary rather than underneath
        fields = { -- The fields listed here will be displayed, in whatever order you choose
          'author',
          'created_at',
          'updated_at',
          'merge_status',
          'draft',
          'conflicts',
          'assignees',
          'reviewers',
          'branch',
          'pipeline',
        },
      },
      discussion_sign_and_diagnostic = {
        skip_resolved_discussion = false,
        skip_old_revision_discussion = true,
      },
      discussion_sign = {
        -- See :h sign_define for details about sign configuration.
        enabled = true,
        text = '💬',
        linehl = nil,
        texthl = nil,
        culhl = nil,
        numhl = nil,
        priority = 20, -- Priority of sign, the lower the number the higher the priority
        helper_signs = {
          -- For multiline comments the helper signs are used to indicate the whole context
          -- Priority of helper signs is lower than the main sign (-1).
          enabled = true,
          start = '↑',
          mid = '|',
          ['end'] = '↓',
        },
      },
      discussion_diagnostic = {
        -- If you want to customize diagnostics for discussions you can make special config
        -- for namespace `gitlab_discussion`. See :h vim.diagnostic.config
        enabled = true,
        severity = vim.diagnostic.severity.INFO,
        code = nil, -- see :h diagnostic-structure
        display_opts = {}, -- see opts in vim.diagnostic.set
      },
      pipeline = {
        created = '',
        pending = '',
        preparing = '',
        scheduled = '',
        running = 'ﰌ',
        canceled = 'ﰸ',
        skipped = 'ﰸ',
        success = '✓',
        failed = '',
      },
      colors = {
        discussion_tree = {
          username = 'Keyword',
          date = 'Comment',
          chevron = 'DiffviewNonText',
          directory = 'Directory',
          directory_icon = 'DiffviewFolderSign',
          file_name = 'Normal',
        },
      },
    },
    build = function()
      require('gitlab.server').build(true)
    end, -- Builds the Go binary
    config = function(_, opts)
      require('dressing').setup {
        input = {
          enabled = true,
        },
      }
      require('gitlab').setup(opts)
    end,
  },

  -- add which_key groups for gitlab
  {
    'folke/which-key.nvim',
    optional = true,
    opts = {
      defaults = {
        ['<leader>gl'] = { name = '+[gitlab]' },
        ['<leader>glP'] = { name = '+[people]' },
        ['<leader>glPa'] = { name = '+[assignee]' },
        ['<leader>glPr'] = { name = '+[reviewer]' },
      },
    },
  },

  -- Ensure GH tool is installed
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'gh' })
    end,
  },

  -- [octo.nvim] - GitHub integration
  -- see: `:h octo.nvim`
  {
    'pwntester/octo.nvim',
    cmd = 'Octo',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      use_local_fs = false, -- use local files on right side of reviews
      enable_builtin = true, -- shows a list of builtin actions when no action is provided
      default_remote = { 'upstream', 'origin' }, -- order to try remotes
      ssh_aliases = {}, -- SSH aliases. e.g. `ssh_aliases = {["github.com-work"] = "github.com"}`
      picker = 'telescope', -- or "fzf-lua"
      picker_config = {
        use_emojis = false, -- only used by "fzf-lua" picker for now
        mappings = { -- mappings for the pickers
          open_in_browser = { lhs = '<C-b>', desc = 'open issue in browser' },
          copy_url = { lhs = '<C-y>', desc = 'copy url to system clipboard' },
          checkout_pr = { lhs = '<C-o>', desc = 'checkout pull request' },
          merge_pr = { lhs = '<C-r>', desc = 'merge pull request' },
        },
      },
      comment_icon = '▎', -- comment marker
      outdated_icon = '󰅒 ', -- outdated indicator
      resolved_icon = ' ', -- resolved indicator
      reaction_viewer_hint_icon = ' ', -- marker for user reactions
      user_icon = ' ', -- user icon
      timeline_marker = ' ', -- timeline marker
      timeline_indent = '2', -- timeline indentation
      right_bubble_delimiter = '', -- bubble delimiter
      left_bubble_delimiter = '', -- bubble delimiter
      github_hostname = '', -- GitHub Enterprise host
      snippet_context_lines = 4, -- number or lines around commented lines
      gh_env = {}, -- extra environment variables to pass on to GitHub CLI, can be a table or function returning a table
      timeout = 5000, -- timeout for requests between the remote server
      ui = {
        use_signcolumn = true, -- show "modified" marks on the sign column
      },
      issues = {
        order_by = { -- criteria to sort results of `Octo issue list`
          field = 'CREATED_AT', -- either COMMENTS, CREATED_AT or UPDATED_AT (https://docs.github.com/en/graphql/reference/enums#issueorderfield)
          direction = 'DESC', -- either DESC or ASC (https://docs.github.com/en/graphql/reference/enums#orderdirection)
        },
      },
      pull_requests = {
        order_by = { -- criteria to sort the results of `Octo pr list`
          field = 'CREATED_AT', -- either COMMENTS, CREATED_AT or UPDATED_AT (https://docs.github.com/en/graphql/reference/enums#issueorderfield)
          direction = 'DESC', -- either DESC or ASC (https://docs.github.com/en/graphql/reference/enums#orderdirection)
        },
        always_select_remote_on_create = false, -- always give prompt to select base remote repo when creating PRs
      },
      file_panel = {
        size = 10, -- changed files panel rows
        use_icons = true, -- use web-devicons in file panel (if false, nvim-web-devicons does not need to be installed)
      },
      colors = { -- used for highlight groups (see Colors section below)
        white = '#ffffff',
        grey = '#2A354C',
        black = '#000000',
        red = '#fdb8c0',
        dark_red = '#da3633',
        green = '#acf2bd',
        dark_green = '#238636',
        yellow = '#d3c846',
        dark_yellow = '#735c0f',
        blue = '#58A6FF',
        dark_blue = '#0366d6',
        purple = '#6f42c1',
      },
      mappings = {
        issue = {
          close_issue = { lhs = '<space>ic', desc = 'close issue' },
          reopen_issue = { lhs = '<space>io', desc = 'reopen issue' },
          list_issues = { lhs = '<space>il', desc = 'list open issues on same repo' },
          reload = { lhs = '<C-r>', desc = 'reload issue' },
          open_in_browser = { lhs = '<C-b>', desc = 'open issue in browser' },
          copy_url = { lhs = '<C-y>', desc = 'copy url to system clipboard' },
          add_assignee = { lhs = '<space>aa', desc = 'add assignee' },
          remove_assignee = { lhs = '<space>ad', desc = 'remove assignee' },
          create_label = { lhs = '<space>lc', desc = 'create label' },
          add_label = { lhs = '<space>la', desc = 'add label' },
          remove_label = { lhs = '<space>ld', desc = 'remove label' },
          goto_issue = { lhs = '<space>gi', desc = 'navigate to a local repo issue' },
          add_comment = { lhs = '<space>ca', desc = 'add comment' },
          delete_comment = { lhs = '<space>cd', desc = 'delete comment' },
          next_comment = { lhs = ']c', desc = 'go to next comment' },
          prev_comment = { lhs = '[c', desc = 'go to previous comment' },
          react_hooray = { lhs = '<space>rp', desc = 'add/remove 🎉 reaction' },
          react_heart = { lhs = '<space>rh', desc = 'add/remove ❤️ reaction' },
          react_eyes = { lhs = '<space>re', desc = 'add/remove 👀 reaction' },
          react_thumbs_up = { lhs = '<space>r+', desc = 'add/remove 👍 reaction' },
          react_thumbs_down = { lhs = '<space>r-', desc = 'add/remove 👎 reaction' },
          react_rocket = { lhs = '<space>rr', desc = 'add/remove 🚀 reaction' },
          react_laugh = { lhs = '<space>rl', desc = 'add/remove 😄 reaction' },
          react_confused = { lhs = '<space>rc', desc = 'add/remove 😕 reaction' },
        },
        pull_request = {
          checkout_pr = { lhs = '<space>po', desc = 'checkout PR' },
          merge_pr = { lhs = '<space>pm', desc = 'merge commit PR' },
          squash_and_merge_pr = { lhs = '<space>psm', desc = 'squash and merge PR' },
          list_commits = { lhs = '<space>pc', desc = 'list PR commits' },
          list_changed_files = { lhs = '<space>pf', desc = 'list PR changed files' },
          show_pr_diff = { lhs = '<space>pd', desc = 'show PR diff' },
          add_reviewer = { lhs = '<space>va', desc = 'add reviewer' },
          remove_reviewer = { lhs = '<space>vd', desc = 'remove reviewer request' },
          close_issue = { lhs = '<space>ic', desc = 'close PR' },
          reopen_issue = { lhs = '<space>io', desc = 'reopen PR' },
          list_issues = { lhs = '<space>il', desc = 'list open issues on same repo' },
          reload = { lhs = '<C-r>', desc = 'reload PR' },
          open_in_browser = { lhs = '<C-b>', desc = 'open PR in browser' },
          copy_url = { lhs = '<C-y>', desc = 'copy url to system clipboard' },
          goto_file = { lhs = 'gf', desc = 'go to file' },
          add_assignee = { lhs = '<space>aa', desc = 'add assignee' },
          remove_assignee = { lhs = '<space>ad', desc = 'remove assignee' },
          create_label = { lhs = '<space>lc', desc = 'create label' },
          add_label = { lhs = '<space>la', desc = 'add label' },
          remove_label = { lhs = '<space>ld', desc = 'remove label' },
          goto_issue = { lhs = '<space>gi', desc = 'navigate to a local repo issue' },
          add_comment = { lhs = '<space>ca', desc = 'add comment' },
          delete_comment = { lhs = '<space>cd', desc = 'delete comment' },
          next_comment = { lhs = ']c', desc = 'go to next comment' },
          prev_comment = { lhs = '[c', desc = 'go to previous comment' },
          react_hooray = { lhs = '<space>rp', desc = 'add/remove 🎉 reaction' },
          react_heart = { lhs = '<space>rh', desc = 'add/remove ❤️ reaction' },
          react_eyes = { lhs = '<space>re', desc = 'add/remove 👀 reaction' },
          react_thumbs_up = { lhs = '<space>r+', desc = 'add/remove 👍 reaction' },
          react_thumbs_down = { lhs = '<space>r-', desc = 'add/remove 👎 reaction' },
          react_rocket = { lhs = '<space>rr', desc = 'add/remove 🚀 reaction' },
          react_laugh = { lhs = '<space>rl', desc = 'add/remove 😄 reaction' },
          react_confused = { lhs = '<space>rc', desc = 'add/remove 😕 reaction' },
        },
        review_thread = {
          goto_issue = { lhs = '<space>gi', desc = 'navigate to a local repo issue' },
          add_comment = { lhs = '<space>ca', desc = 'add comment' },
          add_suggestion = { lhs = '<space>sa', desc = 'add suggestion' },
          delete_comment = { lhs = '<space>cd', desc = 'delete comment' },
          next_comment = { lhs = ']c', desc = 'go to next comment' },
          prev_comment = { lhs = '[c', desc = 'go to previous comment' },
          select_next_entry = { lhs = ']q', desc = 'move to previous changed file' },
          select_prev_entry = { lhs = '[q', desc = 'move to next changed file' },
          select_first_entry = { lhs = '[Q', desc = 'move to first changed file' },
          select_last_entry = { lhs = ']Q', desc = 'move to last changed file' },
          close_review_tab = { lhs = '<C-c>', desc = 'close review tab' },
          react_hooray = { lhs = '<space>rp', desc = 'add/remove 🎉 reaction' },
          react_heart = { lhs = '<space>rh', desc = 'add/remove ❤️ reaction' },
          react_eyes = { lhs = '<space>re', desc = 'add/remove 👀 reaction' },
          react_thumbs_up = { lhs = '<space>r+', desc = 'add/remove 👍 reaction' },
          react_thumbs_down = { lhs = '<space>r-', desc = 'add/remove 👎 reaction' },
          react_rocket = { lhs = '<space>rr', desc = 'add/remove 🚀 reaction' },
          react_laugh = { lhs = '<space>rl', desc = 'add/remove 😄 reaction' },
          react_confused = { lhs = '<space>rc', desc = 'add/remove 😕 reaction' },
        },
        submit_win = {
          approve_review = { lhs = '<C-a>', desc = 'approve review' },
          comment_review = { lhs = '<C-m>', desc = 'comment review' },
          request_changes = { lhs = '<C-r>', desc = 'request changes review' },
          close_review_tab = { lhs = '<C-c>', desc = 'close review tab' },
        },
        review_diff = {
          add_review_comment = { lhs = '<space>ca', desc = 'add a new review comment' },
          add_review_suggestion = { lhs = '<space>sa', desc = 'add a new review suggestion' },
          focus_files = { lhs = '<leader>e', desc = 'move focus to changed file panel' },
          toggle_files = { lhs = '<leader>b', desc = 'hide/show changed files panel' },
          next_thread = { lhs = ']t', desc = 'move to next thread' },
          prev_thread = { lhs = '[t', desc = 'move to previous thread' },
          select_next_entry = { lhs = ']q', desc = 'move to previous changed file' },
          select_prev_entry = { lhs = '[q', desc = 'move to next changed file' },
          select_first_entry = { lhs = '[Q', desc = 'move to first changed file' },
          select_last_entry = { lhs = ']Q', desc = 'move to last changed file' },
          close_review_tab = { lhs = '<C-c>', desc = 'close review tab' },
          toggle_viewed = { lhs = '<leader><space>', desc = 'toggle viewer viewed state' },
          goto_file = { lhs = 'gf', desc = 'go to file' },
        },
        file_panel = {
          next_entry = { lhs = 'j', desc = 'move to next changed file' },
          prev_entry = { lhs = 'k', desc = 'move to previous changed file' },
          select_entry = { lhs = '<cr>', desc = 'show selected changed file diffs' },
          refresh_files = { lhs = 'R', desc = 'refresh changed files panel' },
          focus_files = { lhs = '<leader>e', desc = 'move focus to changed file panel' },
          toggle_files = { lhs = '<leader>b', desc = 'hide/show changed files panel' },
          select_next_entry = { lhs = ']q', desc = 'move to previous changed file' },
          select_prev_entry = { lhs = '[q', desc = 'move to next changed file' },
          select_first_entry = { lhs = '[Q', desc = 'move to first changed file' },
          select_last_entry = { lhs = ']Q', desc = 'move to last changed file' },
          close_review_tab = { lhs = '<C-c>', desc = 'close review tab' },
          toggle_viewed = { lhs = '<leader><space>', desc = 'toggle viewer viewed state' },
        },
      },
    },
    -- stylua: ignore
    keys = {
      { '<leader>gi', '<cmd>Octo<cr>', desc = 'Github' },
    },
  },

  -- [diffview.nvim] - Git diffview for nvim
  -- see: `:h diffview.nvim`
  {
    'sindrets/diffview.nvim',
    config = function()
      local actions = require 'diffview.actions'
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
          view = {
            -- The `view` bindings are active in the diff buffers, only when the current
            -- tabpage is a Diffview.
            { 'n', '<tab>', actions.select_next_entry, { desc = 'Open the diff for the next file' } },
            { 'n', '<s-tab>', actions.select_prev_entry, { desc = 'Open the diff for the previous file' } },
            { 'n', 'gf', actions.goto_file_edit, { desc = 'Open the file in the previous tabpage' } },
            { 'n', '<C-w><C-f>', actions.goto_file_split, { desc = 'Open the file in a new split' } },
            { 'n', '<C-w>gf', actions.goto_file_tab, { desc = 'Open the file in a new tabpage' } },
            { 'n', '<leader>e', actions.focus_files, { desc = 'Bring focus to the file panel' } },
            { 'n', '<leader>b', actions.toggle_files, { desc = 'Toggle the file panel.' } },
            { 'n', 'g<C-x>', actions.cycle_layout, { desc = 'Cycle through available layouts.' } },
            { 'n', '[x', actions.prev_conflict, { desc = 'In the merge-tool: jump to the previous conflict' } },
            { 'n', ']x', actions.next_conflict, { desc = 'In the merge-tool: jump to the next conflict' } },
            { 'n', '<leader>co', actions.conflict_choose 'ours', { desc = 'Choose the OURS version of a conflict' } },
            { 'n', '<leader>ct', actions.conflict_choose 'theirs', { desc = 'Choose the THEIRS version of a conflict' } },
            { 'n', '<leader>cb', actions.conflict_choose 'base', { desc = 'Choose the BASE version of a conflict' } },
            { 'n', '<leader>ca', actions.conflict_choose 'all', { desc = 'Choose all the versions of a conflict' } },
            { 'n', 'dx', actions.conflict_choose 'none', { desc = 'Delete the conflict region' } },
            { 'n', '<leader>cO', actions.conflict_choose_all 'ours', { desc = 'Choose the OURS version of a conflict for the whole file' } },
            { 'n', '<leader>cT', actions.conflict_choose_all 'theirs', { desc = 'Choose the THEIRS version of a conflict for the whole file' } },
            { 'n', '<leader>cB', actions.conflict_choose_all 'base', { desc = 'Choose the BASE version of a conflict for the whole file' } },
            { 'n', '<leader>cA', actions.conflict_choose_all 'all', { desc = 'Choose all the versions of a conflict for the whole file' } },
            { 'n', 'dX', actions.conflict_choose_all 'none', { desc = 'Delete the conflict region for the whole file' } },
          },
          diff1 = {
            -- Mappings in single window diff layouts
            { 'n', 'g?', actions.help { 'view', 'diff1' }, { desc = 'Open the help panel' } },
          },
          diff2 = {
            -- Mappings in 2-way diff layouts
            { 'n', 'g?', actions.help { 'view', 'diff2' }, { desc = 'Open the help panel' } },
          },
          diff3 = {
            -- Mappings in 3-way diff layouts
            { { 'n', 'x' }, '2do', actions.diffget 'ours', { desc = 'Obtain the diff hunk from the OURS version of the file' } },
            { { 'n', 'x' }, '3do', actions.diffget 'theirs', { desc = 'Obtain the diff hunk from the THEIRS version of the file' } },
            { 'n', 'g?', actions.help { 'view', 'diff3' }, { desc = 'Open the help panel' } },
          },
          diff4 = {
            -- Mappings in 4-way diff layouts
            { { 'n', 'x' }, '1do', actions.diffget 'base', { desc = 'Obtain the diff hunk from the BASE version of the file' } },
            { { 'n', 'x' }, '2do', actions.diffget 'ours', { desc = 'Obtain the diff hunk from the OURS version of the file' } },
            { { 'n', 'x' }, '3do', actions.diffget 'theirs', { desc = 'Obtain the diff hunk from the THEIRS version of the file' } },
            { 'n', 'g?', actions.help { 'view', 'diff4' }, { desc = 'Open the help panel' } },
          },
          file_panel = {
            { 'n', 'j', actions.next_entry, { desc = 'Bring the cursor to the next file entry' } },
            { 'n', '<down>', actions.next_entry, { desc = 'Bring the cursor to the next file entry' } },
            { 'n', 'k', actions.prev_entry, { desc = 'Bring the cursor to the previous file entry' } },
            { 'n', '<up>', actions.prev_entry, { desc = 'Bring the cursor to the previous file entry' } },
            { 'n', '<cr>', actions.select_entry, { desc = 'Open the diff for the selected entry' } },
            { 'n', 'o', actions.select_entry, { desc = 'Open the diff for the selected entry' } },
            { 'n', 'l', actions.select_entry, { desc = 'Open the diff for the selected entry' } },
            { 'n', '<2-LeftMouse>', actions.select_entry, { desc = 'Open the diff for the selected entry' } },
            { 'n', '-', actions.toggle_stage_entry, { desc = 'Stage / unstage the selected entry' } },
            { 'n', 's', actions.toggle_stage_entry, { desc = 'Stage / unstage the selected entry' } },
            { 'n', 'S', actions.stage_all, { desc = 'Stage all entries' } },
            { 'n', 'U', actions.unstage_all, { desc = 'Unstage all entries' } },
            { 'n', 'X', actions.restore_entry, { desc = 'Restore entry to the state on the left side' } },
            { 'n', 'L', actions.open_commit_log, { desc = 'Open the commit log panel' } },
            { 'n', 'zo', actions.open_fold, { desc = 'Expand fold' } },
            { 'n', 'h', actions.close_fold, { desc = 'Collapse fold' } },
            { 'n', 'zc', actions.close_fold, { desc = 'Collapse fold' } },
            { 'n', 'za', actions.toggle_fold, { desc = 'Toggle fold' } },
            { 'n', 'zR', actions.open_all_folds, { desc = 'Expand all folds' } },
            { 'n', 'zM', actions.close_all_folds, { desc = 'Collapse all folds' } },
            { 'n', '<c-b>', actions.scroll_view(-0.25), { desc = 'Scroll the view up' } },
            { 'n', '<c-f>', actions.scroll_view(0.25), { desc = 'Scroll the view down' } },
            { 'n', '<tab>', actions.select_next_entry, { desc = 'Open the diff for the next file' } },
            { 'n', '<s-tab>', actions.select_prev_entry, { desc = 'Open the diff for the previous file' } },
            { 'n', 'gf', actions.goto_file_edit, { desc = 'Open the file in the previous tabpage' } },
            { 'n', '<C-w><C-f>', actions.goto_file_split, { desc = 'Open the file in a new split' } },
            { 'n', '<C-w>gf', actions.goto_file_tab, { desc = 'Open the file in a new tabpage' } },
            { 'n', 'i', actions.listing_style, { desc = "Toggle between 'list' and 'tree' views" } },
            { 'n', 'f', actions.toggle_flatten_dirs, { desc = 'Flatten empty subdirectories in tree listing style' } },
            { 'n', 'R', actions.refresh_files, { desc = 'Update stats and entries in the file list' } },
            { 'n', '<leader>e', actions.focus_files, { desc = 'Bring focus to the file panel' } },
            { 'n', '<leader>b', actions.toggle_files, { desc = 'Toggle the file panel' } },
            { 'n', 'g<C-x>', actions.cycle_layout, { desc = 'Cycle available layouts' } },
            { 'n', '[x', actions.prev_conflict, { desc = 'Go to the previous conflict' } },
            { 'n', ']x', actions.next_conflict, { desc = 'Go to the next conflict' } },
            { 'n', 'g?', actions.help 'file_panel', { desc = 'Open the help panel' } },
            { 'n', '<leader>cO', actions.conflict_choose_all 'ours', { desc = 'Choose the OURS version of a conflict for the whole file' } },
            { 'n', '<leader>cT', actions.conflict_choose_all 'theirs', { desc = 'Choose the THEIRS version of a conflict for the whole file' } },
            { 'n', '<leader>cB', actions.conflict_choose_all 'base', { desc = 'Choose the BASE version of a conflict for the whole file' } },
            { 'n', '<leader>cA', actions.conflict_choose_all 'all', { desc = 'Choose all the versions of a conflict for the whole file' } },
            { 'n', 'dX', actions.conflict_choose_all 'none', { desc = 'Delete the conflict region for the whole file' } },
          },
          file_history_panel = {
            { 'n', 'g!', actions.options, { desc = 'Open the option panel' } },
            { 'n', '<C-A-d>', actions.open_in_diffview, { desc = 'Open the entry under the cursor in a diffview' } },
            { 'n', 'y', actions.copy_hash, { desc = 'Copy the commit hash of the entry under the cursor' } },
            { 'n', 'L', actions.open_commit_log, { desc = 'Show commit details' } },
            { 'n', 'zR', actions.open_all_folds, { desc = 'Expand all folds' } },
            { 'n', 'zM', actions.close_all_folds, { desc = 'Collapse all folds' } },
            { 'n', 'j', actions.next_entry, { desc = 'Bring the cursor to the next file entry' } },
            { 'n', '<down>', actions.next_entry, { desc = 'Bring the cursor to the next file entry' } },
            { 'n', 'k', actions.prev_entry, { desc = 'Bring the cursor to the previous file entry.' } },
            { 'n', '<up>', actions.prev_entry, { desc = 'Bring the cursor to the previous file entry.' } },
            { 'n', '<cr>', actions.select_entry, { desc = 'Open the diff for the selected entry.' } },
            { 'n', 'o', actions.select_entry, { desc = 'Open the diff for the selected entry.' } },
            { 'n', '<2-LeftMouse>', actions.select_entry, { desc = 'Open the diff for the selected entry.' } },
            { 'n', '<c-b>', actions.scroll_view(-0.25), { desc = 'Scroll the view up' } },
            { 'n', '<c-f>', actions.scroll_view(0.25), { desc = 'Scroll the view down' } },
            { 'n', '<tab>', actions.select_next_entry, { desc = 'Open the diff for the next file' } },
            { 'n', '<s-tab>', actions.select_prev_entry, { desc = 'Open the diff for the previous file' } },
            { 'n', 'gf', actions.goto_file_edit, { desc = 'Open the file in the previous tabpage' } },
            { 'n', '<C-w><C-f>', actions.goto_file_split, { desc = 'Open the file in a new split' } },
            { 'n', '<C-w>gf', actions.goto_file_tab, { desc = 'Open the file in a new tabpage' } },
            { 'n', '<leader>e', actions.focus_files, { desc = 'Bring focus to the file panel' } },
            { 'n', '<leader>b', actions.toggle_files, { desc = 'Toggle the file panel' } },
            { 'n', 'g<C-x>', actions.cycle_layout, { desc = 'Cycle available layouts' } },
            { 'n', 'g?', actions.help 'file_history_panel', { desc = 'Open the help panel' } },
          },
          option_panel = {
            { 'n', '<tab>', actions.select_entry, { desc = 'Change the current option' } },
            { 'n', 'q', actions.close, { desc = 'Close the panel' } },
            { 'n', 'g?', actions.help 'option_panel', { desc = 'Open the help panel' } },
          },
          help_panel = {
            { 'n', 'q', actions.close, { desc = 'Close help menu' } },
            { 'n', '<esc>', actions.close, { desc = 'Close help menu' } },
          },
        },
      }
    end,
    -- stylua: ignore
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', mode = { 'n', 'v' }, desc = 'Open Diff View' },
      { '<leader>gq', '<cmd>DiffviewClose<cr>', mode = { 'n', 'v' }, desc = 'Close Diff View' },
      { '<leader>gf', '<cmd>DiffviewFileHistory<cr>', mode = { 'n', 'v' }, desc = 'Diff View File History' },
    }
,
  },

  -- [neogit] - Git integration in nvim
  -- see: `:h neogit`
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration
      'nvim-telescope/telescope.nvim', -- optional
    },
    -- stylua: ignore
    keys = {
      { '<leader>gn', '<cmd>Neogit<cr>', mode = { 'n', 'v' }, desc = 'Open Neogit' },
    },
    config = function()
      local neogit = require 'neogit'
      neogit.setup {
        -- Hides the hints at the top of the status buffer
        disable_hint = false,
        -- Disables changing the buffer highlights based on where the cursor is.
        disable_context_highlighting = false,
        -- Disables signs for sections/items/hunks
        disable_signs = false,
        -- Changes what mode the Commit Editor starts in. `true` will leave nvim in normal mode, `false` will change nvim to
        -- insert mode, and `"auto"` will change nvim to insert mode IF the commit message is empty, otherwise leaving it in
        -- normal mode.
        disable_insert_on_commit = 'auto',
        -- When enabled, will watch the `.git/` directory for changes and refresh the status buffer in response to filesystem
        -- events.
        filewatcher = {
          interval = 1000,
          enabled = true,
        },
        -- "ascii"   is the graph the git CLI generates
        -- "unicode" is the graph like https://github.com/rbong/vim-flog
        graph_style = 'ascii',
        -- Used to generate URL's for branch popup action "pull request".
        git_services = {
          ['github.com'] = 'https://github.com/${owner}/${repository}/compare/${branch_name}?expand=1',
          ['bitbucket.org'] = 'https://bitbucket.org/${owner}/${repository}/pull-requests/new?source=${branch_name}&t=1',
          ['gitlab.com'] = 'https://gitlab.com/${owner}/${repository}/merge_requests/new?merge_request[source_branch]=${branch_name}',
        },
        -- Allows a different telescope sorter. Defaults to 'fuzzy_with_index_bias'. The example below will use the native fzf
        -- sorter instead. By default, this function returns `nil`.
        telescope_sorter = function()
          return require('telescope').extensions.fzf.native_fzf_sorter()
        end,
        -- Persist the values of switches/options within and across sessions
        remember_settings = true,
        -- Scope persisted settings on a per-project basis
        use_per_project_settings = true,
        -- Table of settings to never persist. Uses format "Filetype--cli-value"
        ignored_settings = {
          'NeogitPushPopup--force-with-lease',
          'NeogitPushPopup--force',
          'NeogitPullPopup--rebase',
          'NeogitCommitPopup--allow-empty',
          'NeogitRevertPopup--no-edit',
        },
        -- Configure highlight group features
        highlight = {
          italic = true,
          bold = true,
          underline = true,
        },
        -- Set to false if you want to be responsible for creating _ALL_ keymappings
        use_default_keymaps = true,
        -- Neogit refreshes its internal state after specific events, which can be expensive depending on the repository size.
        -- Disabling `auto_refresh` will make it so you have to manually refresh the status after you open it.
        auto_refresh = true,
        -- Value used for `--sort` option for `git branch` command
        -- By default, branches will be sorted by commit date descending
        -- Flag description: https://git-scm.com/docs/git-branch#Documentation/git-branch.txt---sortltkeygt
        -- Sorting keys: https://git-scm.com/docs/git-for-each-ref#_options
        sort_branches = '-committerdate',
        -- Change the default way of opening neogit
        kind = 'tab',
        -- Disable line numbers and relative line numbers
        disable_line_numbers = true,
        -- The time after which an output console is shown for slow running commands
        console_timeout = 2000,
        -- Automatically show console if a command takes more than console_timeout milliseconds
        auto_show_console = true,
        status = {
          recent_commit_count = 10,
        },
        commit_editor = {
          kind = 'auto',
        },
        commit_select_view = {
          kind = 'tab',
        },
        commit_view = {
          kind = 'vsplit',
          verify_commit = os.execute 'which gpg' == 0, -- Can be set to true or false, otherwise we try to find the binary
        },
        log_view = {
          kind = 'tab',
        },
        rebase_editor = {
          kind = 'auto',
        },
        reflog_view = {
          kind = 'tab',
        },
        merge_editor = {
          kind = 'auto',
        },
        tag_editor = {
          kind = 'auto',
        },
        preview_buffer = {
          kind = 'split',
        },
        popup = {
          kind = 'split',
        },
        signs = {
          -- { CLOSED, OPENED }
          hunk = { '', '' },
          item = { '>', 'v' },
          section = { '>', 'v' },
        },
        -- Each Integration is auto-detected through plugin presence, however, it can be disabled by setting to `false`
        integrations = {
          -- If enabled, use telescope for menu selection rather than vim.ui.select.
          -- Allows multi-select and some things that vim.ui.select doesn't.
          telescope = nil,
          -- Neogit only provides inline diffs. If you want a more traditional way to look at diffs, you can use `diffview`.
          -- The diffview integration enables the diff popup.
          --
          -- Requires you to have `sindrets/diffview.nvim` installed.
          diffview = nil,
          -- If enabled, uses fzf-lua for menu selection. If the telescope integration
          -- is also selected then telescope is used instead
          -- Requires you to have `ibhagwan/fzf-lua` installed.
          fzf_lua = nil,
        },
        sections = {
          -- Reverting/Cherry Picking
          sequencer = {
            folded = false,
            hidden = false,
          },
          untracked = {
            folded = false,
            hidden = false,
          },
          unstaged = {
            folded = false,
            hidden = false,
          },
          staged = {
            folded = false,
            hidden = false,
          },
          stashes = {
            folded = true,
            hidden = false,
          },
          unpulled_upstream = {
            folded = true,
            hidden = false,
          },
          unmerged_upstream = {
            folded = false,
            hidden = false,
          },
          unpulled_pushRemote = {
            folded = true,
            hidden = false,
          },
          unmerged_pushRemote = {
            folded = false,
            hidden = false,
          },
          recent = {
            folded = true,
            hidden = false,
          },
          rebase = {
            folded = true,
            hidden = false,
          },
        },
        mappings = {
          commit_editor = {
            ['q'] = 'Close',
            ['<c-c><c-c>'] = 'Submit',
            ['<c-c><c-k>'] = 'Abort',
          },
          rebase_editor = {
            ['p'] = 'Pick',
            ['r'] = 'Reword',
            ['e'] = 'Edit',
            ['s'] = 'Squash',
            ['f'] = 'Fixup',
            ['x'] = 'Execute',
            ['d'] = 'Drop',
            ['b'] = 'Break',
            ['q'] = 'Close',
            ['<cr>'] = 'OpenCommit',
            ['gk'] = 'MoveUp',
            ['gj'] = 'MoveDown',
            ['<c-c><c-c>'] = 'Submit',
            ['<c-c><c-k>'] = 'Abort',
          },
          finder = {
            ['<cr>'] = 'Select',
            ['<c-c>'] = 'Close',
            ['<esc>'] = 'Close',
            ['<c-n>'] = 'Next',
            ['<c-p>'] = 'Previous',
            ['<down>'] = 'Next',
            ['<up>'] = 'Previous',
            ['<tab>'] = 'MultiselectToggleNext',
            ['<s-tab>'] = 'MultiselectTogglePrevious',
            ['<c-j>'] = 'NOP',
          },
          -- Setting any of these to `false` will disable the mapping.
          popup = {
            ['?'] = 'HelpPopup',
            ['A'] = 'CherryPickPopup',
            ['D'] = 'DiffPopup',
            ['M'] = 'RemotePopup',
            ['P'] = 'PushPopup',
            ['X'] = 'ResetPopup',
            ['Z'] = 'StashPopup',
            ['b'] = 'BranchPopup',
            ['c'] = 'CommitPopup',
            ['f'] = 'FetchPopup',
            ['l'] = 'LogPopup',
            ['m'] = 'MergePopup',
            ['p'] = 'PullPopup',
            ['r'] = 'RebasePopup',
            ['v'] = 'RevertPopup',
          },
          status = {
            ['q'] = 'Close',
            ['I'] = 'InitRepo',
            ['1'] = 'Depth1',
            ['2'] = 'Depth2',
            ['3'] = 'Depth3',
            ['4'] = 'Depth4',
            ['<tab>'] = 'Toggle',
            ['x'] = 'Discard',
            ['s'] = 'Stage',
            ['S'] = 'StageUnstaged',
            ['<c-s>'] = 'StageAll',
            ['u'] = 'Unstage',
            ['U'] = 'UnstageStaged',
            ['$'] = 'CommandHistory',
            ['#'] = 'Console',
            ['Y'] = 'YankSelected',
            ['<c-r>'] = 'RefreshBuffer',
            ['<enter>'] = 'GoToFile',
            ['<c-v>'] = 'VSplitOpen',
            ['<c-x>'] = 'SplitOpen',
            ['<c-t>'] = 'TabOpen',
            ['{'] = 'GoToPreviousHunkHeader',
            ['}'] = 'GoToNextHunkHeader',
          },
        },
      }
    end,
  },
}
