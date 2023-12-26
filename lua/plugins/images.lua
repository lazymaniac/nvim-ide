return {
  {
    'edluffy/hologram.nvim',
    opts = {
      auto_display = false,
    },
    config = function(_, opts)
      require('hologram').setup(opts)
    end,
  },
}
