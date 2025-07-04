return {

  -- [volt] - Reactive ui for neovim
  -- see: `:h volt`
  -- link: https://github.com/NvChad/volt
  { 'nvchad/volt' },

  -- [minty] - Reacive color picker
  -- see: `:h minty`
  -- link: https://github.com/NvChad/minty
  {
    'nvchad/minty',
    keys = {
      {
        '<leader>lCs',
        '<cmd>Shades<cr>',
        mode = { 'n' },
        desc = 'Pick Color Shades',
      },
      {
        '<leader>lCc',
        '<cmd>Huefy<cr>',
        mode = { 'n' },
        desc = 'Pick Color',
      },
    },
    cmd = { 'Shades', 'Huefy' },
    opts = {
      huefy = {
        border = false,
      },
    },
  },
}
