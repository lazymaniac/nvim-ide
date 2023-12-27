return {

  -- GRADLE
  {
    'neovim/nvim-lspconfig',
    ---@class PluginLspOpts
    opts = {
      servers = {
        gradle_ls = {},
      },
    },
  },
}
