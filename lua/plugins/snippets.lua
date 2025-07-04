return {

  -- [[ CODE SNIPPETS ]] ---------------------------------------------------------------

  -- [luasnip] - Snippets engine. Loads snippets from various sources like vscode
  -- see: `h: luasnip`
  -- link: https://github.com/L3MON4D3/LuaSnip
  {
    'L3MON4D3/LuaSnip',
    branch = 'master',
    build = 'make install_jsregexp',
    event = 'InsertEnter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'johnpapa/vscode-angular-snippets',
      {
        'rafamadriz/friendly-snippets',
        config = function()
          require('luasnip.loaders.from_vscode').lazy_load { paths = './snippets' }
        end,
      },
    },
    init = function()
      require('luasnip.loaders.from_vscode').lazy_load {
        paths = { vim.fn.stdpath 'config' .. '/snippets' },
      }
    end,
  },

  -- [nvim-scissors] - Allows to create and edit snippets stored in json file
  -- see: `:h nvim-scissors`
  -- link: https://github.com/chrisgrieser/nvim-scissors
  {
    'chrisgrieser/nvim-scissors',
    branch = 'main',
    keys = {
      {
        '<leader>cS',
        function()
          require('scissors').addNewSnippet()
        end,
        mode = { 'n', 'v' },
        desc = 'Add New Snippet [cS]',
      },
      {
        '<leader>cE',
        function()
          require('scissors').editSnippet()
        end,
        desc = 'Edit Snippet [cE]',
      },
    },
    opts = {
      snippetDir = vim.fn.stdpath 'config' .. '/snippets',
      editSnippetPopup = {
        height = 0.4, -- relative to the window, between 0-1
        width = 0.6,
        border = 'rounded', -- `vim.o.winborder` on nvim 0.11, otherwise "rounded"
        keymaps = {
          cancel = 'q',
          saveChanges = '<CR>', -- alternatively, can also use `:w`
          goBackToSearch = '<BS>',
          deleteSnippet = '<C-BS>',
          duplicateSnippet = '<C-d>',
          openInFile = '<C-o>',
          insertNextPlaceholder = '<C-p>', -- insert & normal mode
          showHelp = '?',
        },
      },

      snippetSelection = {
        picker = 'vim.ui.select', ---@type "auto"|"telescope"|"snacks"|"vim.ui.select"
        -- `snacks` picker configurable via snacks config,
        -- see https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
      },
      backdrop = {
        enabled = true,
        blend = 50, -- between 0-100
      },
      icons = {
        scissors = '󰩫',
      },
      -- `none` writes as a minified json file using `vim.encode.json`.
      -- `yq`/`jq` ensure formatted & sorted json files, which is relevant when
      -- you version control your snippets.
      jsonFormatter = 'jq', -- "yq"|"jq"|"none"
    },
  },
}
