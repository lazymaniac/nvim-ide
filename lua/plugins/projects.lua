return {
  -- [[ PROJECT MANAGEMENT ]] ---------------------------------------------------------------

  -- [projections.nvim] - Plugin to manage project in defined directory (workspace)
  -- see: `:h projections.nvim`
  -- link: https://github.com/GnikDroy/projections.nvim
  {
    'gnikdroy/projections.nvim',
    branch = 'main',
    -- stylua: ignore
    keys = {
      { '<leader>fw', '<cmd>Telescope projections<cr>', mode = { 'n' }, desc = 'Switch Workspace [fw]', },
    },
    config = function()
      require('projections').setup {
        workspaces = {                        -- Default workspaces to search for
          { '~/workspace/', { '.git' } },     -- Documents/dev is a workspace. patterns = { ".git" }
        },
        patterns = { '.git', '.svn', '.hg' }, -- Default patterns to use if none were specified. These are NOT regexps.
        -- store_hooks = { pre = nil, post = nil },   -- pre and post hooks for store_session, callable | nil
        -- restore_hooks = { pre = nil, post = nil }, -- pre and post hooks for restore_session, callable | nil
        -- workspaces_file = "path/to/file",          -- Path to workspaces json file
        -- sessions_directory = "path/to/dir",        -- Directory where sessions are stored
      }
      -- Bind <leader>fp to Telescope projections
      require('telescope').load_extension 'projections'
      vim.keymap.set('n', '<leader>fp', function()
        vim.cmd 'Telescope projections'
      end)
      -- Autostore session on VimExit
      local Session = require 'projections.session'
      vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
        callback = function()
          Session.store(vim.loop.cwd())
        end,
      })
      -- Switch to project if vim was started in a project dir
      local switcher = require 'projections.switcher'
      vim.api.nvim_create_autocmd({ 'VimEnter' }, {
        callback = function()
          if vim.fn.argc() == 0 then
            switcher.switch(vim.loop.cwd())
          end
        end,
      })
    end,
  },
}
