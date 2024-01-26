local ok, wf = pcall(require, 'vim.lsp._watchfiles')
if ok then
  -- enable lsp watcher. Too slow on linux
  wf._watchfunc = function()
    return function() end
  end
end

if vim.g.neovide then
  vim.o.guifont = 'CaskaydiaCove Nerd Font:h11'
  vim.g.neovide_remember_window_size = true
end

require 'config.lazy'
require('config').setup {}

-- [[TERMINAL]] global functions
-- TODO: Find better place for this config
function _G.set_terminal_keymaps()
  local opts = { noremap = true }
  -- vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', 'jk', [[<C-\><C-n>]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-h>', [[<C-\><C-n><C-W>h]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-l>', [[<C-\><C-n><C-W>l]], opts)
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
