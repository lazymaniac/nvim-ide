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
map('n', '<leader>bd', '<cmd>lua require("nvchad.tabufline").close_buffer()<cr>', { desc = 'Close buffer [bd]' })
map('n', '<leader>bo', '<cmd>lua require("nvchad.tabufline").closeAllBufs(false)<cr>', { desc = 'Close other buffers [bo]' })
map('n', '<leader>bc', '<cmd>lua require("nvchad.tabufline").closeAllBufs(true)<cr>', { desc = 'Close all buffers [bc]' })
map('n', '<leader>bl', '<cmd>lua require("nvchad.tabufline").closeBufs_at_direction("left") <cr>', { desc = 'Close all buffers to the left [bl]' })
map('n', '<leader>br', '<cmd>lua require("nvchad.tabufline").closeBufs_at_direction("right") <cr>', { desc = 'Close all buffers to the right [bl]' })
map('n', '<leader>bL', '<cmd>lua require("nvchad.tabufline").move_buf(-1)<cr>', { desc = 'Move buffer to the left [bL]' })
map('n', '<leader>bR', '<cmd>lua require("nvchad.tabufline").move_buf(1)<cr>', { desc = 'Move buffer to the right [bR]' })

for i = 1, 9, 1 do
  map('n', string.format('<A-%s>', i), function()
    vim.api.nvim_set_current_buf(vim.t.bufs[i])
  end, { desc = string.format('Open buffer %s', i) })
end

-- Terminals
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
map({ 'n', 't' }, '<A-n>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "node", cmd = "node"}<cr>', { desc = 'Node [an]' })
map({ 'n', 't' }, '<A-u>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "ncdu", cmd = "ncdu"}<cr>', { desc = 'ncdu [au]' })
map({ 'n', 't' }, '<A-b>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "btop", cmd = "btop --utf-force"}<cr>', { desc = 'btop [ab]' })
map({ 'n', 't' }, '<A-p>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "python", cmd = "python"}<cr>', { desc = 'Python [ap]' })
map({ 'n', 't' }, '<A-d>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "lazydocker", cmd = "lazydocker"}<cr>', { desc = 'Lazydocker [ad]' })
map({ 'n', 't' }, '<A-s>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "lazysql", cmd = "lazysql"}<cr>', { desc = 'Lazysql [as]' })
map({ 'n', 't' }, '<A-g>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "lazygit", cmd = "lazygit"}<cr>', { desc = 'Lazygit [ag]' })
map({ 'n', 't' }, '<A-f>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "fl1", cmd = "onefetch"}<cr>', { desc = 'Floating Terminal [af]' })
map({ 'n', 't' }, '<A-\\>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "fl1", cmd = "onefetch"}<cr>', { desc = 'Floating Terminal [af]' })
map({ 'n', 't' }, '<A-v>', '<cmd>lua require("nvchad.term").toggle {pos = "vsp", id = "spv1", cmd = "onefetch"}<cr>', { desc = 'Vertical Split Terminal [av]' })
map({ 'n', 't' }, '<A-h>', '<cmd>lua require("nvchad.term").toggle {pos = "sp", id = "fl1", cmd = "onefetch"}<cr>', { desc = 'Horizontal Split Terminal [ah]' })
map({ 'n', 't' }, '<A-1>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "fl1", cmd = "onefetch"}<cr>', { desc = 'Terminal 1 [a1]' })
map({ 'n', 't' }, '<A-2>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "fl2", cmd = "onefetch"}<cr>', { desc = 'Terminal 2 [a1]' })
map({ 'n', 't' }, '<A-3>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "fl3", cmd = "onefetch"}<cr>', { desc = 'Terminal 3 [a1]' })
map({ 'n', 't' }, '<A-4>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "fl4", cmd = "onefetch"}<cr>', { desc = 'Terminal 4 [a1]' })
map({ 'n', 't' }, '<A-5>', '<cmd>lua require("nvchad.term").toggle {pos = "float", id = "fl5", cmd = "onefetch"}<cr>', { desc = 'Terminal 5 [a1]' })
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
map('n', '<leader>uc', function() Util.toggle('conceallevel', false, { 0, conceallevel }) end,
  { desc = 'Toggle Conceal [uc]' })
if vim.lsp.buf.inlay_hint or vim.lsp.inlay_hint then
  -- stylua: ignore
  map('n', '<leader>uh', function() Util.toggle.inlay_hints() end, { desc = 'Toggle Inlay Hints [uh]' })
end
-- stylua: ignore
map('n', '<leader>uT', function() if vim.b.ts_highlight then vim.treesitter.stop() else vim.treesitter.start() end end,
  { desc = 'Toggle Treesitter Highlight [uT]' })

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
