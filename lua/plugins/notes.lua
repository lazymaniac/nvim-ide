return {

  -- [[ NOTE TAKING ]] ---------------------------------------------------------------
  -- [neorg] - Note taking, calendar, presentations, journal
  -- see: `:h neorg`
  {
    'nvim-neorg/neorg',
    event = 'VeryLazy',
    build = ':Neorg sync-parsers',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
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
          ['core.completion'] = {
            config = {
              engine = 'nvim-cmp',
              name = '[Neorg]',
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
          ['core.ui.calendar'] = {},
        },
      }
    end,
    -- stylua: ignore
    keys = {
      { '<leader>nn', '<cmd>Neorg index<cr>', mode = { 'n', 'v' }, desc = 'Notes index', },
      { '<leader>nc', '<cmd>Neorg journal custom<cr>', mode = { 'n', 'v' }, desc = 'Jornal custom day', },
      { '<leader>nt', '<cmd>Neorg jornal today<cr>', mode = { 'n', 'v' }, desc = 'Journal today', },
      { '<leader>no', '<cmd>Neorg jornal tomorrow<cr>', mode = { 'n', 'v' }, desc = 'Journal tomorrow', },
      { '<leader>ny', '<cmd>Neorg jornal yesterday<cr>', mode = { 'n', 'v' }, desc = 'Journal yesterday', },
      { '<leader>ns', '<cmd>Neorg sync-parsers<cr>', mode = { 'n', 'v' }, desc = 'Neorg sync-parsers', },
    },
  },

  -- Add which-key group for notes
  {
    'folke/which-key.nvim',
    optional = true,
    opts = {
      defaults = {
        ['<leader>n'] = { name = '+[notes]' },
      },
    },
  },
}
