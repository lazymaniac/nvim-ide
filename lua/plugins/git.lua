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
        map({ 'n', 'v' }, '<leader>ghs', ':Gitsigns stage_hunk<CR>', 'Stage Hunk')
        map({ 'n', 'v' }, '<leader>ghr', ':Gitsigns reset_hunk<CR>', 'Reset Hunk')
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

  -- [tardis.nvim] - Compare previos versions of file with current
  -- see: `:h tardis`
  {
    'fredeeb/tardis.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = true,
    keys = {
      {
        '<leader>gt',
        '<cmd>Tardis<cr>',
        mode = { 'n', 'v' },
        desc = 'Compare with previous versions',
      },
    },
  },
}
