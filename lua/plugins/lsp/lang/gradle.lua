return {

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'groovy', 'kotlin' })
      end
    end,
  },

  {
    'neovim/nvim-lspconfig',
    ---@class PluginLspOpts
    opts = {
      servers = {
        gradle_ls = {},
        groovyls = {},
      },
    },
  },
}
