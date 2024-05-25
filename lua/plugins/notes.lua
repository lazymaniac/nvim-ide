return {

  -- [[ NOTE TAKING ]] ---------------------------------------------------------------

  -- [luarocks.nvim] - Install lua dependencies from nvim.
  -- see: `:h luarocks.nvim`
  -- link: https://github.com/vhyrro/luarocks.nvim
  {
    'vhyrro/luarocks.nvim',
    branch = 'main',
    priority = 1000, -- We'd like this plugin to load first out of the rest
    config = true,   -- This automatically runs `require("luarocks-nvim").setup()`
    opts = {
      rocks = { 'lua-curl', 'nvim-nio', 'mimetypes', 'xml2lua' },
    },
  },

  -- [neorg] - Note taking, calendar, presentations, journal
  -- see: `:h neorg`
  -- link: https://github.com/nvim-neorg/neorg
  {
    'nvim-neorg/neorg',
    branch = 'main',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-neorg/neorg-telescope', 'luarocks.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>nn',  '<cmd>Neorg index<cr>',                            mode = { 'n', 'v' }, desc = 'Notes index [nn]' },
      { '<leader>nc',  '<cmd>Neorg journal custom<cr>',                   mode = { 'n', 'v' }, desc = 'Journal custom day [nc]' },
      { '<leader>nt',  '<cmd>Neorg journal today<cr>',                    mode = { 'n', 'v' }, desc = 'Journal today [nt]' },
      { '<leader>no',  '<cmd>Neorg journal tomorrow<cr>',                 mode = { 'n', 'v' }, desc = 'Journal tomorrow [no]' },
      { '<leader>ny',  '<cmd>Neorg journal yesterday<cr>',                mode = { 'n', 'v' }, desc = 'Journal yesterday [ny]' },
      { '<leader>ns',  '<cmd>Neorg sync-parsers<cr>',                     mode = { 'n', 'v' }, desc = 'Neorg sync-parsers [ns]' },
      { '<leader>nfl', '<cmd>Telescope neorg insert_link<cr>',            mode = { 'n', 'v' }, desc = 'Insert Link [nfl]' },
      { '<leader>nfL', '<cmd>Telescope neorg find_linkable<cr>',          mode = { 'n', 'v' }, desc = 'Find Linkable [nfL]', },
      { '<leader>nfa', '<cmd>Telescope neorg find_aof_tasks<cr>',         mode = { 'n', 'v' }, desc = 'Find AOF Tasks [nfa]', },
      { '<leader>nfr', '<cmd>Telescope neorg find_aof_project_tasks<cr>', mode = { 'n', 'v' }, desc = 'Find AOF Project Tasks [nfr]', },
      { '<leader>nfn', '<cmd>Telescope neorg find_neorg_files<cr>',       mode = { 'n', 'v' }, desc = 'Find Neorg Files [nfn]', },
      { '<leader>nfh', '<cmd>Telescope neorg search_headings<cr>',        mode = { 'n', 'v' }, desc = 'Search Headings [nfh]', },
      { '<leader>nff', '<cmd>Telescope neorg insert_file_link<cr>',       mode = { 'n', 'v' }, desc = 'Insert File Link [nff]', },
      { '<leader>nfw', '<cmd>Telescope neorg switch_workspace<cr>',       mode = { 'n', 'v' }, desc = 'Switch Workspace [nfw]', },
      { '<leader>nfc', '<cmd>Telescope neorg find_context_tasks<cr>',     mode = { 'n', 'v' }, desc = 'Find Context Tasks [nfc]', },
      { '<leader>nft', '<cmd>Telescope neorg find_project_tasks<cr>',     mode = { 'n', 'v' }, desc = 'Find Project Tasks [nft]', },
    },
    config = function()
      require('neorg').setup {
        load = {
          ['core.defaults'] = {},  -- Loads default behaviour
          ['core.concealer'] = {}, -- Adds pretty icons to your documents
          ['core.dirman'] = {      -- Manages Neorg workspaces
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
          -- ['core.ui.calendar'] = {},
        },
      }
    end,
  },

  -- [org-checkbox.nvim] - Convert list into checkboxes and viceversa
  -- see: `:h org-checkbox.nvim`
  -- link: https://github.com/massix/org-checkbox.nvim
  {
    'massix/org-checkbox.nvim',
    config = function()
      require('orgcheckbox').setup { lhs = '<leader>oT' }
    end,
    ft = { 'org' },
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
