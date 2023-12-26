return {

  -- GRADLE
  {
    'neovim/nvim-lspconfig',
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        gradle_ls = {},
      },
    },
  },
}
