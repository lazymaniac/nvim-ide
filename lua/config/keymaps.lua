-- This file is automatically loaded by config.init
local Util = require 'util'

local map = Util.safe_keymap_set

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Insert mode movements
map('i', '<C-b>', '<ESC>^i', { desc = 'move beginning of line' })
map('i', '<C-e>', '<End>', { desc = 'move end of line' })
map('i', '<C-h>', '<Left>', { desc = 'move left' })
map('i', '<C-l>', '<Right>', { desc = 'move right' })
map('i', '<C-j>', '<Down>', { desc = 'move down' })
map('i', '<C-k>', '<Up>', { desc = 'move up' })

-- better up/down
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ 'n', 'x' }, '<Down>', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map({ 'n', 'x' }, '<Up>', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map('n', '<C-h>', '<C-w>h', { desc = 'Go to left window <C-w>h', remap = true })
map('n', '<C-j>', '<C-w>j', { desc = 'Go to lower window <C-w>j', remap = true })
map('n', '<C-k>', '<C-w>k', { desc = 'Go to upper window <C-w>k', remap = true })
map('n', '<C-l>', '<C-w>l', { desc = 'Go to right window <C-w>l', remap = true })

-- Resize window using <ctrl> arrow keys
map('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase window height <C-up>' })
map('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease window height <C-Down>' })
map('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width <C-Left>' })
map('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width <C-Right>' })

-- Move Lines
map('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move down <A-j>' })
map('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move up <A-k>' })
map('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move down <A-j>' })
map('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move up <A-k>' })
map('v', '<A-j>', ":m '>+1<cr>gv=gv", { desc = 'Move down <A-j>' })
map('v', '<A-k>', ":m '<-2<cr>gv=gv", { desc = 'Move up <A-k>' })

-- Buffers
map('n', '<S-h>', '<cmd>lua require("nvchad.tabufline").prev()<cr>', { desc = 'Prev buffer <S-h>' })
map('n', '<S-l>', '<cmd>lua require("nvchad.tabufline").next()<cr>', { desc = 'Next buffer <S-l>' })
map('n', '[b', '<cmd>lua require("nvchad.tabufline").prev()<cr>', { desc = 'Prev buffer <[b>' })
map('n', ']b', '<cmd>lua require("nvchad.tabufline").next()<cr>', { desc = 'Next buffer <]b>' })
map('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer [bb]' })
map('n', '<leader>`', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer [`]' })

-- Terminals
function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
  vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

vim.cmd 'autocmd! TermOpen term://* lua set_terminal_keymaps()'
map({ 'n', 't' }, '<A-b>', function () Snacks.terminal.toggle("btop --utf-force") end, { desc = 'btop [A-b]' })
map({ 'n', 't' }, '<A-c>', function () Snacks.terminal.toggle("nap") end, { desc = 'Nap [A-c]' })
map({ 'n', 't' }, '<A-l>', function () Snacks.terminal.toggle("cloudlens") end, { desc = 'Cloudlens [A-l]' })
map({ 'n', 't' }, '<A-u>', function () Snacks.terminal.toggle("dua i") end, { desc = 'ncdu [A-u]' })
map({ 'n', 't' }, '<A-d>', function () Snacks.terminal.toggle("lazydocker") end, { desc = 'Lazydocker [A-d]' })
map({ 'n', 't' }, '<A-D>', function () Snacks.terminal.toggle("podman-tui") end, { desc = 'Podman [A-D]' })
map({ 'n', 't' }, '<A-s>', function () Snacks.terminal.toggle("harlequin") end, { desc = 'Harlequin [A-s]' })
map({ 'n', 't' }, '<A-g>', function () Snacks.lazygit() end, { desc = 'Lazygit [A-g]' })
map({ 'n', 't' }, '<A-n>', function () Snacks.terminal.toggle("node") end, { desc = 'Node [A-n]' })
map({ 'n', 't' }, '<A-p>', function () Snacks.terminal.toggle("python3") end, { desc = 'Python [A-p]' })
map({ 'n', 't' }, '<A-v>', function () Snacks.terminal.toggle("jshell") end, { desc = 'JShell [A-v]' })
map({ 'n', 't' }, '<A-f>', function () Snacks.terminal.open("zellij options --theme kanagawa") end, { desc = 'New Terminal [A-f]' })
map({ 'n', 't' }, '<A-\\>', function () Snacks.terminal.toggle("zellij options --theme kanagawa") end, { desc = 'Toggle Terminal [A-\\]' })
map({ 'n', 't' }, '<A-t>', function () Snacks.terminal.toggle("termscp") end, { desc = 'TermSCP [A-t]' })
map({ 'n', 't' }, '<A-h>', function () Snacks.terminal.toggle("posting") end, { desc = 'Posting [A-h]' })
map({ 'n', 't' }, '<A-k>', function () Snacks.terminal.toggle("k9s") end, { desc = 'K9S [A-k]' })
map({ 'n', 't' }, '<A-e>', function () Snacks.terminal.toggle("euporie-notebook") end, { desc = 'Euporie [A-e]' })
--
-- Clear search with <esc>
map({ 'i', 'n' }, '<esc>', '<cmd>noh<cr><esc>', { desc = 'Escape and clear hlsearch <esc>' })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
map('n', '<leader>ur', '<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>', { desc = 'Redraw / clear hlsearch / diff update <C-L><CR>' })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next search result <n>' })
map('x', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result <n>' })
map('o', 'n', "'Nn'[v:searchforward]", { expr = true, desc = 'Next search result <n>' })
map('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev search result <N>' })
map('x', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result <N>' })
map('o', 'N', "'nN'[v:searchforward]", { expr = true, desc = 'Prev search result <N>' })

-- Add undo break-points
map('i', ',', ',<c-g>u')
map('i', '.', '.<c-g>u')
map('i', ';', ';<c-g>u')

-- Save file
map({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save file <C-s>' })

--Keywordprg
map('n', '<leader>K', '<cmd>norm! K<cr>', { desc = 'Keywordprg [K]' })

-- Better indenting
map('v', '<', '<gv^')
map('v', '>', '>gv^')

-- Lazy & Mason
map('n', '<leader>ll', '<cmd>Lazy<cr>', { desc = 'Lazy [ll]' })
map('n', '<leader>lm', '<cmd>Mason<cr>', { desc = 'Mason [lm]' })

-- new file
map('n', '<leader>fn', '<cmd>enew<cr>', { desc = 'New File [fn]' })

map('n', '<leader>xl', '<cmd>lopen<cr>', { desc = 'Location List [xl]' })
map('n', '<leader>xq', '<cmd>copen<cr>', { desc = 'Quickfix List [xq]' })

map('n', '[q', vim.cmd.cprev, { desc = 'Previous quickfix <[q>' })
map('n', ']q', vim.cmd.cnext, { desc = 'Next quickfix <]q>' })

-- diagnostic
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go { severity = severity }
  end
end
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Code Diagnostics [cd]' })
map('n', ']d', diagnostic_goto(true), { desc = 'Next Diagnostic <]d>' })
map('n', '[d', diagnostic_goto(false), { desc = 'Prev Diagnostic <[b>' })
map('n', ']e', diagnostic_goto(true, 'ERROR'), { desc = 'Next Error <]e>' })
map('n', '[e', diagnostic_goto(false, 'ERROR'), { desc = 'Prev Error <[e>' })
map('n', ']w', diagnostic_goto(true, 'WARN'), { desc = 'Next Warning <]w>' })
map('n', '[w', diagnostic_goto(false, 'WARN'), { desc = 'Prev Warning <[w>' })

-- toggle options
-- stylua: ignore
map('n', '<leader>ut', function() require("base46").toggle_theme() end,
  { desc = 'Toggle Theme [ut]' })
-- stylua: ignore
map('n', '<leader>uf', function() Util.format.toggle() end, { desc = 'Toggle auto format (global) [uf]' })
-- stylua: ignore
map('n', '<leader>uF', function() Util.format.toggle(true) end, { desc = 'Toggle auto format (buffer) [uF]' })

-- quit
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit all [qq]' })

-- highlights under cursor
map('n', '<leader>ui', vim.show_pos, { desc = 'Inspect Pos [ui]' })

-- windows
map('n', '<leader>ww', '<C-W>p', { desc = 'Other Window [ww]', remap = true })
map('n', '<leader>wd', function()
  vim.cmd 'close'
end, { desc = 'Window Delete [wd]', remap = true })
map('n', '<leader>w-', '<C-W>s', { desc = 'Window Split Below [w-]', remap = true })
map('n', '<leader>w|', '<C-W>v', { desc = 'Window Split Right [w|]', remap = true })
map('n', '<leader>-', '<C-W>s', { desc = 'Window Split Below [-]', remap = true })
map('n', '<leader>|', '<C-W>v', { desc = 'Window Split Right [|]', remap = true })

-- tabs
map('n', '<leader><tab>l', '<cmd>tablast<cr>', { desc = 'Last Tab [<tab>l]' })
map('n', '<leader><tab>f', '<cmd>tabfirst<cr>', { desc = 'First Tab [<tab>f]' })
map('n', '<leader><tab>n', '<cmd>tabnew<cr>', { desc = 'New Tab [<tab><tab>]' })
map('n', '<leader><tab><tab>', '<cmd>tabnext<cr>', { desc = 'Next Tab [<tab><tab>]' })
map('n', '<leader><tab>]', '<cmd>tabnext<cr>', { desc = 'Next Tab [<tab>]]' })
map('n', '<leader><tab>d', '<cmd>tabclose<cr>', { desc = 'Delete Tab [<tab>d]' })
map('n', '<leader><tab>[', '<cmd>tabprevious<cr>', { desc = 'Previous Tab [<tab>[]' })
