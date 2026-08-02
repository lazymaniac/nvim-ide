local function check(value, message)
  if not value then
    error('Voyager GitHub smoke: ' .. message, 0)
  end
  return value
end

local config_root = vim.fn.getcwd()
local lazy_path = check(vim.env.LAZY, 'LAZY checkout path is required')
check(vim.fn.isdirectory(lazy_path) == 1, 'LAZY checkout does not exist')
vim.opt.runtimepath:prepend(lazy_path)

local voyager
for _, spec in ipairs(dofile 'lua/plugins/coding.lua') do
  if spec[1] == 'lazymaniac/voyager.nvim' then
    voyager = spec
    break
  end
end
check(voyager, 'published Voyager spec not found')

local smoke_root = vim.fn.tempname()
check(vim.fn.mkdir(smoke_root, 'p') == 1, 'cannot create disposable plugin root')
local smoke_lock = vim.fs.joinpath(smoke_root, 'lazy-lock.json')
check(vim.uv.fs_copyfile(vim.fs.joinpath(config_root, 'lazy-lock.json'), smoke_lock), 'cannot copy lockfile')

-- The shared minimal init disables native plugin loading for isolated config tests.
-- lazy.nvim intentionally returns before setup while this option is disabled.
vim.opt.loadplugins = true
require('lazy').setup {
  spec = { voyager },
  defaults = { lazy = false, version = '*' },
  root = vim.fs.joinpath(smoke_root, 'plugins'),
  lockfile = smoke_lock,
  install = { missing = true },
  checker = { enabled = false },
  change_detection = { enabled = false },
  rocks = { enabled = false },
  headless = { process = false, log = false, task = false, colors = false },
}

local lazy_config = require 'lazy.core.config'
local lazy_plugin = require 'lazy.core.plugin'
local installed = check(lazy_config.plugins['voyager.nvim'], 'resolved plugin is missing')
check(installed._.installed, 'resolved plugin was not installed')
check(not lazy_plugin.has_errors(installed), 'resolved plugin has installation errors')

local head = vim.system({ 'git', '-C', installed.dir, 'rev-parse', 'HEAD' }, { text = true }):wait()
local remote = vim.system({ 'git', '-C', installed.dir, 'rev-parse', 'origin/main' }, { text = true }):wait()
check(head.code == 0 and remote.code == 0, 'cannot inspect the installed Git checkout')
check(vim.trim(head.stdout or '') == vim.trim(remote.stdout or ''), 'locked checkout is not published GitHub main')

for _, command in ipairs { 'VoyagerOpen', 'VoyagerFocus', 'VoyagerSave', 'VoyagerLoad', 'VoyagerClose' } do
  check(vim.fn.exists(':' .. command) == 2, command .. ' is missing')
end

vim.cmd.edit(vim.fs.joinpath(config_root, 'lua', 'plugins', 'coding.lua'))
local source_buf = vim.api.nvim_get_current_buf()
local original_reference = function() end
local original_source_definition = function() end
vim.keymap.set('n', 'gr', original_reference, { nowait = true })
vim.keymap.set('n', 'gD', original_source_definition, { buffer = source_buf, nowait = true })

vim.cmd.VoyagerOpen()
local wrapped_reference = vim.api.nvim_buf_call(source_buf, function()
  return vim.fn.maparg('gr', 'n', false, true)
end)
check(wrapped_reference.buffer == 1, 'gr was not wrapped buffer-locally')
check(wrapped_reference.nowait == 1, 'gr lost its nowait behavior')

local untouched_source_definition = vim.api.nvim_buf_call(source_buf, function()
  return vim.fn.maparg('gD', 'n', false, true)
end)
check(untouched_source_definition.callback == original_source_definition, 'gD was repurposed')

vim.cmd.VoyagerClose()
local restored_reference = vim.api.nvim_buf_call(source_buf, function()
  return vim.fn.maparg('gr', 'n', false, true)
end)
check(restored_reference.callback == original_reference, 'gr did not restore its prior owner')
check(restored_reference.nowait == 1, 'restored gr lost nowait')

vim.keymap.del('n', 'gr')
vim.api.nvim_buf_delete(source_buf, { force = true })
check(vim.fn.delete(smoke_root, 'rf') == 0, 'cannot remove disposable plugin root')
vim.api.nvim_out_write 'VOYAGER GITHUB SMOKE PASS\n'
