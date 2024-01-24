return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { 'html', 'css' })
    end,
  },

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { 'prettierd' })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      -- make sure mason installs the server
      servers = {
        -- html
        html = {
          filetypes = { 'html', 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },
        },
        -- Emmet
        emmet_ls = {
          init_options = {
            html = {
              options = {
                -- For possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
                ['bem.enabled'] = true,
              },
            },
          },
        },
        -- CSS
        cssls = {},
      },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        html = { 'prettierd' },
      },
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      defaults = {
        ['<leader>U'] = { name = '+[utils]' },
        ['<leader>UC'] = { name = '+[color]' },
      },
    },
  },

  {
    'uga-rosa/ccc.nvim',
    opts = {},
    cmd = { 'CccPick', 'CccConvert', 'CccHighlighterEnable', 'CccHighlighterDisable', 'CccHighlighterToggle' },
    keys = {
      { '<leader>UCp', '<cmd>CccPick<cr>', desc = 'Pick' },
      { '<leader>UCc', '<cmd>CccConvert<cr>', desc = 'Convert' },
      { '<leader>UCh', '<cmd>CccHighlighterToggle<cr>', desc = 'Toggle Highlighter' },
    },
  },
}
