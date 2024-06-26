return {
  {
    'folke/which-key.nvim',
    optional = true,
    opts = {
      defaults = {
        ['<localLeader>l'] = { name = '+vimtex' },
      },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'bibtex', 'latex' })
      end
      if type(opts.highlight.disable) == 'table' then
        vim.list_extend(opts.highlight.disable, { 'latex' })
      else
        opts.highlight.disable = { 'latex' }
      end
    end,
  },

  -- [vimtex] - Syntax plugin for Latex
  -- see: `:h vimtex`
  -- link: https://github.com/lervag/vimtex
  {
    'lervag/vimtex',
    branch = 'master',
    lazy = false, -- lazy-loading will disable inverse search
    config = function()
      vim.g.vimtex_mappings_disable = { ['n'] = { 'K' } } -- disable `K` as it conflicts with LSP hover
      vim.g.vimtex_quickfix_method = vim.fn.executable 'pplatex' == 1 and 'pplatex' or 'latexlog'
    end,
  },

  {
    'neovim/nvim-lspconfig',
    optional = true,
    opts = {
      servers = {
        texlab = {
          keys = {
            { '<Leader>K', '<plug>(vimtex-doc-package)', desc = 'Vimtex Docs', silent = true },
          },
        },
      },
    },
  },
}
