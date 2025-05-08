return {

  {
    'mason-org/mason.nvim',
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

  -- [volt] - Reactive ui for neovim
  -- see: `:h volt`
  -- link: https://github.com/NvChad/volt
  { 'nvchad/volt', lazy = true },

  -- [minty] - Reacive color picker
  -- see: `:h minty`
  -- link: https://github.com/NvChad/minty
  {
    'nvchad/minty',
    keys = {
      {
        '<leader>lcs',
        '<cmd>Shades<cr>',
        mode = { 'n' },
        desc = 'Pick Color Shades',
      },
      {
        '<leader>lcc',
        '<cmd>Huefy<cr>',
        mode = { 'n' },
        desc = 'Pick Color',
      },
    },
    event = 'VeryLazy',
    cmd = { 'Shades', 'Huefy' },
    opts = {
      huefy = {
        border = false,
      },
    },
  },
}
