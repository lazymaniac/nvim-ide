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
map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Prev buffer <S-h>' })
map('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next buffer <S-l>' })
map('n', '[b', '<cmd>bprevious<cr>', { desc = 'Prev buffer <[b>' })
map('n', ']b', '<cmd>bnext<cr>', { desc = 'Next buffer <]b>' })
map('n', '<leader>bb', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer [bb]' })
map('n', '<leader>`', '<cmd>e #<cr>', { desc = 'Switch to Other Buffer [`]' })

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

-- formatting
map({ 'n', 'v' }, '<leader>cf', function()
  Util.format { force = true }
end, { desc = 'Format [cf]' })

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
map('n', '<leader>ub', function() Util.toggle('background', false, { 'light', 'dark' }) end, { desc = 'Toggle Background [ub]' })
-- stylua: ignore
map('n', '<leader>uf', function() Util.format.toggle() end, { desc = 'Toggle auto format (global) [uf]' })
-- stylua: ignore
map('n', '<leader>uF', function() Util.format.toggle(true) end, { desc = 'Toggle auto format (buffer) [uF]' })
-- stylua: ignore
map('n', '<leader>us', function() Util.toggle 'spell' end, { desc = 'Toggle Spelling [us]' })
-- stylua: ignore
map('n', '<leader>uw', function() Util.toggle 'wrap' end, { desc = 'Toggle Word Wrap [uw]' })
-- stylua: ignore
map('n', '<leader>uL', function() Util.toggle 'relativenumber' end, { desc = 'Toggle Relative Line Numbers [uL]' })
-- stylua: ignore
map('n', '<leader>ul', function() Util.toggle.number() end, { desc = 'Toggle Line Numbers [ul]' })
-- stylua: ignore
map('n', '<leader>ud', function() Util.toggle.diagnostics() end, { desc = 'Toggle Diagnostics [ud]' })
local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
-- stylua: ignore
map('n', '<leader>uc', function() Util.toggle('conceallevel', false, { 0, conceallevel }) end, { desc = 'Toggle Conceal [uc]' })
if vim.lsp.buf.inlay_hint or vim.lsp.inlay_hint then
-- stylua: ignore
  map('n', '<leader>uh', function() Util.toggle.inlay_hints() end, { desc = 'Toggle Inlay Hints [uh]' })
end
-- stylua: ignore
map('n', '<leader>uT', function() if vim.b.ts_highlight then vim.treesitter.stop() else vim.treesitter.start() end end, { desc = 'Toggle Treesitter Highlight [uT]' })

-- quit
map('n', '<leader>qq', '<cmd>qa<cr>', { desc = 'Quit all [qq]' })

-- highlights under cursor
map('n', '<leader>ui', vim.show_pos, { desc = 'Inspect Pos [ui]' })

-- windows
map('n', '<leader>ww', '<C-W>p', { desc = 'Other Window [ww]', remap = true })
map('n', '<leader>wd', '<C-W>c', { desc = 'Window Delete [wd]', remap = true })
map('n', '<leader>w-', '<C-W>s', { desc = 'Window Split Below [w-]', remap = true })
map('n', '<leader>w|', '<C-W>v', { desc = 'Window Split Right [w|]', remap = true })
map('n', '<leader>-', '<C-W>s', { desc = 'Window Split Below [-]', remap = true })
map('n', '<leader>|', '<C-W>v', { desc = 'Window Split Right [|]', remap = true })

-- tabs
map('n', '<leader><tab>l', '<cmd>tablast<cr>', { desc = 'Last Tab [<tab>l]' })
map('n', '<leader><tab>f', '<cmd>tabfirst<cr>', { desc = 'First Tab [<tab>f]' })
map('n', '<leader><tab><tab>', '<cmd>tabnew<cr>', { desc = 'New Tab [<tab><tab>]' })
map('n', '<leader><tab>]', '<cmd>tabnext<cr>', { desc = 'Next Tab [<tab>]]' })
map('n', '<leader><tab>d', '<cmd>tabclose<cr>', { desc = 'Delete Tab [<tab>d]' })
map('n', '<leader><tab>[', '<cmd>tabprevious<cr>', { desc = 'Previous Tab [<tab>[]' })
