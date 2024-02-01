return {

  -- [[ NOTE TAKING ]] ---------------------------------------------------------------
  -- [neorg] - Note taking, calendar, presentations, journal
  -- see: `:h neorg`
  {
    'nvim-neorg/neorg',
    event = 'VeryLazy',
    build = ':Neorg sync-parsers',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-neorg/neorg-telescope' },
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
      { '<leader>nn', '<cmd>Neorg index<cr>', mode = { 'n', 'v' }, desc = 'Notes index' },
      { '<leader>nc', '<cmd>Neorg journal custom<cr>', mode = { 'n', 'v' }, desc = 'Journal custom day' },
      { '<leader>nt', '<cmd>Neorg journal today<cr>', mode = { 'n', 'v' }, desc = 'Journal today' },
      { '<leader>no', '<cmd>Neorg journal tomorrow<cr>', mode = { 'n', 'v' }, desc = 'Journal tomorrow' },
      { '<leader>ny', '<cmd>Neorg journal yesterday<cr>', mode = { 'n', 'v' }, desc = 'Journal yesterday' },
      { '<leader>ns', '<cmd>Neorg sync-parsers<cr>', mode = { 'n', 'v' }, desc = 'Neorg sync-parsers' },
      { '<leader>nfl', '<cmd>Telescope neorg insert_link<cr>', mode = { 'n', 'v' }, desc = 'Insert Link' },
      { '<leader>nfl', '<cmd>Telescope neorg find_linkable<cr>', mode = { 'n', 'v' }, desc = 'Find Linkable', },
      { '<leader>nfa', '<cmd>Telescope neorg find_aof_tasks<cr>', mode = { 'n', 'v' }, desc = 'Find AOF Tasks', },
      { '<leader>nfr', '<cmd>Telescope neorg find_aof_project_tasks<cr>', mode = { 'n', 'v' }, desc = 'Find AOF Project Tasks', },
      { '<leader>nfn', '<cmd>Telescope neorg find_neorg_files<cr>', mode = { 'n', 'v' }, desc = 'Find Neorg Files', },
      { '<leader>nfh', '<cmd>Telescope neorg search_headings<cr>', mode = { 'n', 'v' }, desc = 'Search Headings', },
      { '<leader>nff', '<cmd>Telescope neorg insert_file_link<cr>', mode = { 'n', 'v' }, desc = 'Insert File Link', },
      { '<leader>nfw', '<cmd>Telescope neorg switch_workspace<cr>', mode = { 'n', 'v' }, desc = 'Switch Workspace', },
      { '<leader>nfc', '<cmd>Telescope neorg find_context_tasks<cr>', mode = { 'n', 'v' }, desc = 'Find Context Tasks', },
      { '<leader>nft', '<cmd>Telescope neorg find_project_tasks<cr>', mode = { 'n', 'v' }, desc = 'Find Project Tasks', },

    },
  },

  -- Add which-key group for notes
  {
    'folke/which-key.nvim',
    optional = true,
    opts = {
      defaults = {
        ['<leader>n'] = { name = '+[notes]' },
        ['<leader>nf'] = { name = '+[find/insert]' },
      },
    },
  },
}
