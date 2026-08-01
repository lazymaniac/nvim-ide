require('nv_ide.requirements').assert_supported()

if vim.g.neovide then
  -- text
  vim.o.guifont = 'Maple Mono NF:h13'
  vim.g.neovide_text_gamma = 0.8
  vim.g.neovide_text_contrast = 0.9

  -- window padding
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_right = 0
  vim.g.neovide_padding_left = 0

  -- floating window shadow
  vim.g.neovide_floating_shadow = true
  vim.g.neovide_floating_z_height = 10
  vim.g.neovide_light_angle_degrees = 45
  vim.g.neovide_light_radius = 5

  vim.g.neovide_floating_corner_radius = 0.4

  -- border
  vim.g.neovide_show_border = false

  -- remember window size
  vim.g.neovide_remember_window_size = true
  vim.api.nvim_set_keymap('n', '<F11>', ':let g:neovide_fullscreen = !g:neovide_fullscreen<CR>', {})
  vim.g.neovide_floating_blur_amount_x = 3.0
  vim.g.neovide_floating_blur_amount_y = 3.0
  vim.g.neovide_scroll_animation_far_lines = 1
  vim.g.neovide_input_macos_option_key_is_meta = 'only_left'
end

vim.g.base46_cache = vim.fn.stdpath 'data' .. '/base46_cache/'
local toolchain = require 'nv_ide.toolchain'
toolchain.early()
toolchain.with_startup_lock(function()
  ---@diagnostic disable-next-line: different-requires
  require 'config.lazy'
end)
require('config').setup {}

require('nv_ide.cache').load {
  dir = vim.g.base46_cache,
  integrations = require('nvconfig').base46.integrations,
}
