return {

  -- [[ IMAGES ]] ---------------------------------------------------------------
  -- [hologram.nvim] - Image support in MD files. Requires Kitty
  -- see: `:h hologram.nvim`
  {
    'edluffy/hologram.nvim',
    opts = {
      auto_display = false,
    },
    config = function(_, opts)
      require('hologram').setup(opts)
    end,
  },

  -- [image.nvim] - Image loader. Integrate into neo-tree, jupyter notebooks etc. Requires Kitty
  -- see: `:h image.nvim`
  {
    '3rd/image.nvim',
    event = 'VeryLazy',
    opts = {
      backend = 'kitty',
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { 'markdown', 'vimwiki' }, -- markdown extensions (ie. quarto) can go here
        },
        neorg = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { 'norg' },
        },
      },
      max_width = nil,
      max_height = nil,
      max_width_window_percentage = nil,
      max_height_window_percentage = 50,
      kitty_method = 'normal',
    },
  },
}
