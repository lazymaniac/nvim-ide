local ok, wf = pcall(require, 'vim.lsp._watchfiles')
if ok then
  -- enable lsp watcher. Too slow on linux
  wf._watchfunc = function()
    return function() end
  end
end

if vim.g.neovide then
  vim.o.guifont = 'VictorMono Nerd Font:h10'
  vim.g.neovide_refresh_rate = 165
  vim.g.neovide_remember_window_size = true
  vim.api.nvim_set_keymap('n', '<F11>', ':let g:neovide_fullscreen = !g:neovide_fullscreen<CR>', {})
  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0
  vim.g.neovide_scroll_animation_length = 0.0
  vim.g.neovide_scroll_animation_far_lines = 1
  vim.g.neovide_unlink_border_highlights = true
  vim.g.neovide_cursor_vfx_mode = 'railgun'
end

---@diagnostic disable-next-line: different-requires
require 'config.lazy'
require('config').setup {}

-- [[TERMINAL]] global functions
-- TODO: Find better place for this config
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
