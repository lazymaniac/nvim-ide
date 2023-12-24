-- [[ Install `lazy.nvim` plugin manager ]]
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require('lazy').setup {
  spec = {
    -- Import plugins
    { import = 'plugins' },
  },
  defaults = {
    -- Disable lazy loading of plugins
    lazy = false,
    -- Aways use the latest stable git commit for plugins that support semver
    version = '*',
  },
  install = { colorscheme = { 'tokyonight', 'habamax' } },
  checker = { enable = true }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "netrwPlugin",
        -- "tarPlugin",
        -- "toHtml",
        -- "tutor",
        -- "zipPlugin",
      },
    },
  },
}
