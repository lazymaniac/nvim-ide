local ok, wf = pcall(require, 'vim.lsp._watchfiles')
if ok then
  -- enable lsp watcher. Too slow on linux
  wf._watchfunc = function()
    return function() end
  end
end

if vim.g.neovide then
  -- text
  vim.o.guifont = 'VictorMono Nerd Font:h13'
  vim.g.neovide_text_gamma = 0.8
  vim.g.neovide_text_contrast = 0.9

  -- window padding
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_right = 0
  vim.g.neovide_padding_left = 0
  -- Helper function for transparency formatting
  local alpha = function()
    return string.format("%x", math.floor(255 * (vim.g.transparency or 0.8)))
  end
  -- g:neovide_opacity should be 0 if you want to unify transparency of content and title bar.
  vim.g.neovide_opacity = 0.0
  vim.g.transparency = 0.8

  -- window blur and background color
  vim.g.neovide_window_blurred = true
  vim.g.neovide_background_color = "#0f1117" .. alpha()

  -- floating indow blur
  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0

  -- floating window shadow
  vim.g.neovide_floating_shadow = true
  vim.g.neovide_floating_z_height = 10
  vim.g.neovide_light_angle_degrees = 45
  vim.g.neovide_light_radius = 5

  vim.g.neovide_floating_corner_radius = 0.4

  -- transparency
  vim.g.neovide_opacity = 0.6
  vim.g.neovide_normal_opacity = 0.6

  vim.g.neovide_theme = 'dark'

  -- border
  vim.g.neovide_show_border = false

  -- remember window size
  vim.g.neovide_remember_window_size = true
  vim.api.nvim_set_keymap('n', '<F11>', ':let g:neovide_fullscreen = !g:neovide_fullscreen<CR>', {})
  vim.g.neovide_floating_blur_amount_x = 3.0
  vim.g.neovide_floating_blur_amount_y = 3.0
  vim.g.neovide_scroll_animation_far_lines = 1
end

vim.g.base46_cache = vim.fn.stdpath 'data' .. '/base46_cache/'
---@diagnostic disable-next-line: different-requires
require 'config.lazy'
require('config').setup {}

for _, v in ipairs(vim.fn.readdir(vim.g.base46_cache)) do
  dofile(vim.g.base46_cache .. v)
end
