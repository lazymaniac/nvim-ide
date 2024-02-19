return {

  -- [[ IMAGES ]] ---------------------------------------------------------------
  -- [hologram.nvim] - Image support in MD files. Requires Kitty
  -- see: `:h hologram.nvim`
  {
    'edluffy/hologram.nvim',
    enabled = true,
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
    enabled = true,
    opts = {
      backend = 'kitty',
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { 'markdown', 'vimwiki', 'quatro' }, -- markdown extensions (ie. quarto) can go here
        },
        neorg = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { 'norg' },
        },
      },
      max_width = 120,
      max_height = 12,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
      editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
      tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
      hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp' }, -- render image files as images when opened
    },
  },
}
