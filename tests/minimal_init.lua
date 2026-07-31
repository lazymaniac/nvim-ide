local source = debug.getinfo(1, 'S').source:sub(2)
local tests_dir = vim.fs.dirname(vim.fs.normalize(source))
local root = vim.fs.dirname(tests_dir)

vim.opt.runtimepath:prepend(root)
package.path = table.concat({
  root .. '/?.lua',
  root .. '/?/init.lua',
  root .. '/lua/?.lua',
  root .. '/lua/?/init.lua',
  package.path,
}, ';')

vim.opt.shadafile = 'NONE'
vim.opt.swapfile = false
vim.opt.undofile = false
vim.g.mapleader = ' '

