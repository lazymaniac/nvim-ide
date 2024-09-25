local ok, wf = pcall(require, 'vim.lsp._watchfiles')
if ok then
  -- enable lsp watcher. Too slow on linux
  wf._watchfunc = function()
    return function() end
  end
end

if vim.g.neovide then
  vim.o.guifont = 'VictorMono Nerd Font:h10'
  vim.g.neovide_remember_window_size = true
  vim.api.nvim_set_keymap('n', '<F11>', ':let g:neovide_fullscreen = !g:neovide_fullscreen<CR>', {})
  vim.g.neovide_floating_blur_amount_x = 3.0
  vim.g.neovide_floating_blur_amount_y = 3.0
  vim.g.neovide_scroll_animation_far_lines = 1
end

---@diagnostic disable-next-line: different-requires
require 'config.lazy'
require('config').setup {}
