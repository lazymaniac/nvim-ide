local ok, wf = pcall(require, "vim.lsp._watchfiles")
if ok then
  -- disable lsp watcher. Too slow on linux
  wf._watchfunc = function()
    return function() end
  end
end

if vim.g.neovide then
  vim.o.guifont = "FiraCode Nerd Font Mono:h11"
  vim.g.neovide_confirm_quit = true
  vim.g.neovide_remember_window_size = true
end

require("config.lazy")
require("config.init").setup({})

