return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { 'prettierd', 'htmlhint', 'stylelint', 'eslint_d' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { 'html', 'css', 'scss', 'javascript', 'typescript' })
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        html = { 'prettierd' },
        javascript = { 'prettierd' },
        css = { 'prettierd' },
        less = { 'prettierd' },
        scss = { 'prettierd' },
        jsx = { 'prettierd' },
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        html = { 'htmlhint', 'stylelint' },
        javascript = { 'eslint_d' },
        css = { 'stylelint' },
        scss = { 'stylelint' },
        less = { 'stylelint' },
      },
    },
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
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      defaults = {
        ['<leader>l'] = { name = '+[utils]' },
        ['<leader>lc'] = { name = '+[color]' },
      },
    },
  },

  {
    'uga-rosa/ccc.nvim',
    branch = 'main',
    opts = {},
    cmd = { 'CccPick', 'CccConvert', 'CccHighlighterEnable', 'CccHighlighterDisable', 'CccHighlighterToggle' },
    keys = {
      { '<leader>lcp', '<cmd>CccPick<cr>', desc = 'Pick [lcp]' },
      { '<leader>lcc', '<cmd>CccConvert<cr>', desc = 'Convert [lcc]' },
      { '<leader>lch', '<cmd>CccHighlighterToggle<cr>', desc = 'Toggle Highlighter [lch]' },
    },
  },
}
