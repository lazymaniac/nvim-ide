return {
  --
  -- ############### GITLAB PLUGIN ###############
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
    keys = {
      {
        'glr',
        function()
          require('gitlab').review()
        end,
        mode = { 'n' },
        desc = 'Gitlab review',
      },
      {
        'gls',
        function()
          require('gitlab').summary()
        end,
        mode = { 'n' },
        desc = 'Gitlab summary',
      },
      {
        'glA',
        function()
          require('gitlab').approve()
        end,
        mode = { 'n' },
        desc = 'Gitlab approve',
      },
      {
        'glR',
        function()
          require('gitlab').revoke()
        end,
        mode = { 'n' },
        desc = 'Gitlab revoke',
      },
      {
        'glc',
        function()
          require('gitlab').create_comment()
        end,
        mode = { 'n' },
        desc = 'Gitlab create comment',
      },
      {
        'glc',
        function()
          require('gitlab').create_multiline_comment()
        end,
        mode = { 'v' },
        desc = 'Gitlab create multiline comment',
      },
      {
        'glC',
        function()
          require('gitlab').create_comment_suggestion()
        end,
        mode = { 'v' },
        desc = 'Gitlab create comment suggestion',
      },
      {
        'glm',
        function()
          require('gitlab').move_to_discussion_tree_from_diagnostic()
        end,
        mode = { 'n' },
        desc = 'Gitlab move to discussion tree from diagnostics',
      },
      {
        'gln',
        function()
          require('gitlab').create_note()
        end,
        mode = { 'n' },
        desc = 'Gitlab create note',
      },
      {
        'gld',
        function()
          require('gitlab').toggle_discussions()
        end,
        mode = { 'n' },
        desc = 'Gitlab toggle discussion',
      },
      {
        'glaa',
        function()
          require('gitlab').add_assignee()
        end,
        mode = { 'n' },
        desc = 'Gitlab add assignee',
      },
      {
        'glad',
        function()
          require('gitlab').delete_assignee()
        end,
        mode = { 'n' },
        desc = 'Gitlab delete assignee',
      },
      {
        'glara',
        function()
          require('gitlab').add_reviewer()
        end,
        mode = { 'n' },
        desc = 'Gitlab add reviewer',
      },
      {
        'glard',
        function()
          require('gitlab').delete_reviewer()
        end,
        mode = { 'n' },
        desc = 'Gitlab delete reviewer',
      },
      {
        'glp',
        function()
          require('gitlab').pipeline()
        end,
        mode = { 'n' },
        desc = 'Gitlab pipeline',
      },
      {
        'glo',
        function()
          require('gitlab').open_in_browser()
        end,
        mode = { 'n' },
        desc = 'Gitlab open in browser',
      },
      {
        'glB',
        function()
          local gitlab = require 'gitlab'
          require('gitlab.server').restart(function()
            vim.cmd.tabclose()
            gitlab.review() -- Reopen the reviewer after server restarts
          end)
        end,
        mode = { 'n' },
        desc = 'Gitlab refresh review',
      },
      {
        'glP',
        function()
          require('gitlab').print_settings()
        end,
        mode = { 'n' },
        desc = 'Gitlab troubleshoot settings',
      },
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
}
