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
  {
    'samodostal/image.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'm00qek/baleia.nvim',
    },
    opts = {
      render = {
        min_padding = 5,
        show_label = true,
        show_image_dimensions = true,
        use_dither = true,
        foreground_color = false,
        background_color = false,
      },
      events = {
        update_on_nvim_resize = true,
      },
    },
    config = function(_, opts)
      require('image').setup(opts)
    end,
  },
  {
    'adelarsq/image_preview.nvim',
    event = 'VeryLazy',
    config = function()
      require('image_preview').setup()
    end,
  },
}
