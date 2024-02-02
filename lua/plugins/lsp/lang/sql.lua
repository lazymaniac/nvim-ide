local sql_ft = { 'sql', 'mysql', 'plsql' }

return {
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'sqlfmt', 'sqlfluff' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    optional = true,
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'sql' })
      end
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        sql = { 'sqlfmt' },
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        sql = { 'sqlfluff' },
      },
    },
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        sqlls = {},
      },
    },
  },

  {
    'tpope/vim-dadbod',
    cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
    dependencies = {
      'kristijanhusak/vim-dadbod-ui',
      { 'kristijanhusak/vim-dadbod-completion', ft = sql_ft },
      { 'jsborjesson/vim-uppercase-sql', ft = sql_ft },
    },
    init = function()
      vim.g.db_ui_save_location = vim.fn.stdpath 'data' .. '/db_ui'
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_execute_on_save = false
      vim.g.db_ui_use_nvim_notify = true

      vim.api.nvim_create_autocmd('FileType', {
        pattern = sql_ft,
        callback = function()
          ---@diagnostic disable-next-line: missing-fields
          require('cmp').setup.buffer { sources = { { name = 'vim-dadbod-completion' } } }
        end,
      })
    end,
    -- stylua: ignore
    keys = {
      { '<leader>cD', '<cmd>DBUIToggle<CR>', desc = 'Database UI [cD]' },
    },
  },
}
