return {

  -- [[ NOTE TAKING ]] ---------------------------------------------------------------

  -- [luarocks.nvim] - Install lua dependencies from nvim.
  -- see: `:h luarocks.nvim`
  -- link: https://github.com/vhyrro/luarocks.nvim
  {
    'vhyrro/luarocks.nvim',
    branch = 'main',
    priority = 1000, -- We'd like this plugin to load first out of the rest
    config = true, -- This automatically runs `require("luarocks-nvim").setup()`
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-neotest/nvim-nio',
      'nvim-neorg/lua-utils.nvim',
      'nvim-lua/plenary.nvim',
      'pysan3/pathlib.nvim',
    },
    opts = {
    },
  },

  -- [neorg] - Note taking, calendar, presentations, journal
  -- see: `:h neorg`
  -- link: https://github.com/nvim-neorg/neorg
  {
    'nvim-neorg/neorg',
    branch = 'main',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim', 'luarocks.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>nn',  '<cmd>Neorg index<cr>',                            mode = { 'n', 'v' }, desc = 'Notes index [nn]' },
      { '<leader>nc',  '<cmd>Neorg journal custom<cr>',                   mode = { 'n', 'v' }, desc = 'Journal custom day [nc]' },
      { '<leader>nt',  '<cmd>Neorg journal today<cr>',                    mode = { 'n', 'v' }, desc = 'Journal today [nt]' },
      { '<leader>no',  '<cmd>Neorg journal tomorrow<cr>',                 mode = { 'n', 'v' }, desc = 'Journal tomorrow [no]' },
      { '<leader>ny',  '<cmd>Neorg journal yesterday<cr>',                mode = { 'n', 'v' }, desc = 'Journal yesterday [ny]' },
      { '<leader>ns',  '<cmd>Neorg sync-parsers<cr>',                     mode = { 'n', 'v' }, desc = 'Neorg sync-parsers [ns]' },
    },
    config = function()
      local wk = require 'which-key'
      local defaults = {
        { '<leader>n', group = '+[notes]' },
        { '<leader>nf', group = '+[find/insert]' },
      }
      wk.add(defaults)
      require('neorg').setup {
        load = {
          ['core.defaults'] = {}, -- Loads default behaviour
          ['core.concealer'] = {}, -- Adds pretty icons to your documents
          ['core.dirman'] = { -- Manages Neorg workspaces
            config = {
              default_workspace = 'notes',
              workspaces = {
                notes = '~/neorg/notes',
              },
            },
          },
          ['core.export'] = {
            config = {
              export_dir = '~/neorg/export/',
            },
          },
          ['core.export.markdown'] = {
            config = {
              extension = 'md',
              extensions = 'all',
            },
          },
          ['core.presenter'] = {
            config = {
              zen_mode = 'zen-mode',
            },
          },
          ['core.summary'] = {},
        },
      }
    end,
  },
}
