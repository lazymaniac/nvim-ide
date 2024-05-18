return {

  -- [[ CODE SNIPPETS ]] ---------------------------------------------------------------

  -- [friendly-snippets] - Set of useful snippets in vscode format
  -- see: `:h friendly-snippets`
  -- link: https://github.com/rafamadriz/friendly-snippets
  {
    'rafamadriz/friendly-snippets',
    branch = 'main',
    event = 'VeryLazy',
    dependencies = { 'L3MON4D3/LuaSnip' },
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load { paths = './snippets' }
    end,
  },

  -- [luasnip] - Snippets engine. Loads snippets from various sources like vscode
  -- see: `h: luasnip`
  -- link: https://github.com/L3MON4D3/LuaSnip
  {
    'L3MON4D3/LuaSnip',
    branch = 'master',
    event = 'VimEnter',
    build = (not jit.os:find 'Windows') and "echo 'NOTE: jsregexp is optional, so not a big deal if it fails to build'; make install_jsregexp" or nil,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    init = function()
      local ls = require 'luasnip'
      ls.setup {
        -- Required to automatically include base snippets, like "c" snippets for "cpp"
        load_ft_func = require('luasnip_snippets.common.snip_utils').load_ft_func,
        ft_func = require('luasnip_snippets.common.snip_utils').ft_func,
        -- To enable auto expansin
        enable_autosnippets = true,
        -- Uncomment to enable visual snippets triggered using <c-x>
        -- store_selection_keys = '<c-x>',
        history = true,
        delete_check_events = 'TextChanged',
      }
      -- LuaSnip key bindings
      vim.keymap.set({ 'i', 's' }, '<C-E>', function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true })
    end,
  },

  -- [luasnip_snippets] - Library of snippets ported from vim-snippets
  -- see: `luasnip_snippets`
  -- link: https://github.com/mireq/luasnip-snippets
  {
    'mireq/luasnip-snippets',
    branch = 'main',
    event = 'VeryLazy',
    dependencies = { 'L3MON4D3/LuaSnip' },
    init = function()
      -- Mandatory setup function
      require('luasnip_snippets.common.snip_utils').setup()
    end,
  },

  -- [nvim-scissors] - Allows to create and edit snippets stored in json file
  -- see: `:h nvim-scissors`
  -- link: https://github.com/chrisgrieser/nvim-scissors
  {
    'chrisgrieser/nvim-scissors',
    branch = 'main',
    dependencies = 'nvim-telescope/telescope.nvim',
    -- stylua: ignore
    keys = {
      { '<leader>fs', function() require('scissors').addNewSnippet() end, mode = { 'n', 'v' }, desc = 'Add New Snippet [fs]' },
      { '<leader>fS', function() require('scissors').editSnippet() end, desc = 'Edit Snippet [fS]' },
    },
    opts = {
      snippetDir = vim.fn.stdpath 'config' .. '/snippets',
      editSnippetPopup = {
        height = 0.4, -- relative to the window, number between 0 and 1
        width = 0.6,
        border = 'rounded',
        keymaps = {
          cancel = 'q',
          saveChanges = '<CR>',
          goBackToSearch = '<BS>',
          delete = '<C-BS>',
          openInFile = '<C-o>',
          insertNextToken = '<C-t>', -- works in insert & normal mode
        },
      },
      -- `none` writes as a minified json file using `vim.encode.json`.
      -- `yq`/`jq` ensure formatted & sorted json files, which is relevant when
      -- you version control your snippets.
      jsonFormatter = 'jq', -- "yq"|"jq"|"none"
    },
  },
}
