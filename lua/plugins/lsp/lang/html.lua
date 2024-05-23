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
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        html = {
          filetypes = { 'html', 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },
        },
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

  -- [ccc.nvim] - Color picker in Nvim
  -- see: `:h ccc.nvim`
  -- link: https://github.com/uga-rosa/ccc.nvim
  {
    'uga-rosa/ccc.nvim',
    branch = 'main',
    opts = {},
    cmd = { 'CccPick', 'CccConvert', 'CccHighlighterEnable', 'CccHighlighterDisable', 'CccHighlighterToggle' },
    keys = {
      { '<leader>lcp', '<cmd>CccPick<cr>',              desc = 'Pick [lcp]' },
      { '<leader>lcc', '<cmd>CccConvert<cr>',           desc = 'Convert [lcc]' },
      { '<leader>lch', '<cmd>CccHighlighterToggle<cr>', desc = 'Toggle Highlighter [lch]' },
    },
  },
}
