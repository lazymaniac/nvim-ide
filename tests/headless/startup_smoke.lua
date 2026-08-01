local function check(value, message)
  if not value then
    error('startup smoke: ' .. message, 0)
  end
  return value
end

local function is_empty(value)
  return type(value) == 'table' and next(value) == nil
end

local function verify()
  check(vim.env.NVIM_TOOLCHAIN_AUTORUN == '1', 'NVIM_TOOLCHAIN_AUTORUN must be enabled')

  local manifest = require 'nv_ide.toolchain.manifest'
  check(manifest.profiles == nil, 'the toolchain must not expose profiles')

  local state = check(require('nv_ide.toolchain.state').new():read(), 'persisted toolchain state is missing')
  local fingerprint = manifest.fingerprint()
  check(state.schema_version == manifest.schema_version, 'persisted schema version is stale')
  check(state.fingerprint == fingerprint, 'persisted manifest fingerprint is stale')
  check(state.status == 'success', 'startup repair did not persist success')
  check(type(state.last_success) == 'number', 'startup repair has no completion timestamp')
  check(is_empty(state.missing), 'startup repair persisted missing dependencies')

  local update = check(state.plugin_update, 'first-run plugin update state is missing')
  check(update.status == 'success', 'first-run plugin update did not persist success')
  check(update.fingerprint == fingerprint, 'first-run plugin update fingerprint is stale')
  check(type(update.last_success) == 'number', 'first-run plugin update has no completion timestamp')
  check(type(update.observed) == 'table', 'first-run plugin update has no observed state')
  check(type(update.observed.before) == 'table', 'first-run plugin update has no before evidence')
  check(type(update.observed.after) == 'table', 'first-run plugin update has no after evidence')
  check(type(update.manager) == 'table', 'first-run plugin update has no lazy.nvim manager evidence')
  check(
    type(update.manager.before) == 'string' and #update.manager.before == 40,
    'first-run plugin update has no prior lazy.nvim revision'
  )
  check(
    type(update.manager.commit) == 'string' and #update.manager.commit == 40,
    'first-run plugin update has no selected lazy.nvim revision'
  )
  check(type(update.manager.tag) == 'string' and update.manager.tag:match '^v%d+%.%d+%.%d+$', 'first-run lazy.nvim tag is invalid')

  vim.api.nvim_out_write 'STARTUP AUTORUN PASS\n'
end

local function finish()
  local ok, failure = xpcall(verify, debug.traceback)
  if ok then
    vim.cmd 'qa!'
  else
    vim.api.nvim_err_writeln(failure)
    vim.cmd 'cquit 1'
  end
end

if vim.v.vim_did_enter == 1 then
  vim.schedule(finish)
else
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    desc = 'Assert persisted first-run toolchain completion',
    callback = function()
      -- The toolchain's VimEnter handler was registered during init.lua and runs
      -- first. Scheduling here observes its blocking headless repair and update.
      vim.schedule(finish)
    end,
  })
end
