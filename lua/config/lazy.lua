-- [[ Install `lazy.nvim` plugin manager ]]
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  vim.fn.system { 'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath }
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require('lazy').setup {
  spec = {
    -- Import plugins
    { import = 'plugins' },
    { import = 'plugins.lsp.lang' },
  },
  defaults = {
    -- Disable lazy loading of plugins
    lazy = false,
    -- Always use the latest stable git commit for plugins that support semver
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
        "netrwPlugin",
        "tarPlugin",
        -- "toHtml",
        "tutor",
        -- "zipPlugin",
      },
    },
  },
  ui = {
    border = 'rounded',
  },
}

-- [[TERMINAL]] global functions
function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  -- vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
  vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

vim.cmd 'autocmd! TermOpen term://* lua set_terminal_keymaps()'

local Terminal = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new { cmd = 'lazygit', hidden = true }

function _LAZYGIT_TOGGLE()
  lazygit:toggle()
end

local node = Terminal:new { cmd = 'node', hidden = true }

function _NODE_TOGGLE()
  node:toggle()
end

local ncdu = Terminal:new { cmd = 'ncdu', hidden = true }

function _NCDU_TOGGLE()
  ncdu:toggle()
end

local btop = Terminal:new { cmd = 'btop --utf-force', hidden = true }

function _BTOP_TOGGLE()
  btop:toggle()
end

local python = Terminal:new { cmd = 'python', hidden = true }

function _PYTHON_TOGGLE()
  python:toggle()
end

local lazydocker = Terminal:new { cmd = 'lazydocker', hidden = true }

function _LAZYDOCKER_TOGGLE()
  lazydocker:toggle()
end

local lazysql = Terminal:new { cmd = 'lazysql', hidden = true }

function _LAZYSQL_TOGGLE()
  lazysql:toggle()
end
