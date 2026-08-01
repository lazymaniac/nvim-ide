local function check(value, message)
  if not value then
    error('lazy resolution smoke: ' .. message, 0)
  end
  return value
end

local function read_json(path)
  local file = check(io.open(path, 'rb'), 'cannot read ' .. path)
  local value = file:read '*a'
  file:close()
  return vim.json.decode(value)
end

local function write_json(path, value)
  local wrote = vim.fn.writefile({ vim.json.encode(value) }, path, 'b')
  check(wrote == 0, 'cannot write ' .. path)
end

local function plugin_errors()
  local config = require 'lazy.core.config'
  local plugin = require 'lazy.core.plugin'
  local errors = {}
  for name, spec in pairs(config.plugins) do
    if plugin.has_errors(spec) then
      errors[#errors + 1] = name
    end
  end
  table.sort(errors)
  return errors
end

local function check_errors(action)
  local errors = plugin_errors()
  check(#errors == 0, ('%s failed for: %s'):format(action, table.concat(errors, ', ')))
end

local function assert_locked_checkout(lockfile)
  local config = require 'lazy.core.config'
  for name, entry in pairs(lockfile) do
    if name == 'lazy.nvim' then
      local result = vim.system({ 'git', '-C', check(vim.env.LAZY, 'LAZY path is missing'), 'rev-parse', 'HEAD' }, { text = true }):wait()
      check(result.code == 0 and vim.trim(result.stdout or '') == entry.commit, 'lazy.nvim is not at its locked commit')
    else
      local spec = check(config.plugins[name], 'locked plugin is absent from the resolved spec: ' .. name)
      -- Lazy's restore pipeline deliberately refuses to touch a checkout that
      -- it considers dirty. Re-establish the tracked worktree in this isolated
      -- smoke XDG tree before proving the locked seed and attempting an update.
      local restored = vim.system({ 'git', '-C', spec.dir, 'reset', '--hard', entry.commit }, { text = true }):wait()
      check(restored.code == 0, ('cannot restore locked plugin %s: %s'):format(name, vim.trim(restored.stderr or '')))
      local result = vim.system({ 'git', '-C', spec.dir, 'rev-parse', 'HEAD' }, { text = true }):wait()
      check(result.code == 0, ('cannot inspect locked plugin %s: %s'):format(name, vim.trim(result.stderr or '')))
      check(vim.trim(result.stdout or '') == entry.commit, name .. ' is not at its locked commit')
      local tracked = vim.system({ 'git', '-C', spec.dir, 'ls-files', '-d', '-m' }, { text = true }):wait()
      check(tracked.code == 0, ('cannot inspect tracked files for %s: %s'):format(name, vim.trim(tracked.stderr or '')))
      check(vim.trim(tracked.stdout or '') == '', name .. ' has modified or deleted tracked files after restore')
    end
  end
end

local function git(lazy_path, arguments, timeout_ms, description)
  local command = { 'git', '-C', lazy_path }
  vim.list_extend(command, arguments)
  local spawned, process = pcall(vim.system, command, { text = true, timeout = timeout_ms })
  check(spawned, ('%s could not start: %s'):format(description, tostring(process)))
  local waited, result = pcall(process.wait, process)
  check(waited, ('%s did not complete: %s'):format(description, tostring(result)))
  check(result.code == 0, ('%s failed: %s'):format(description, vim.trim(result.stderr or result.stdout or ('exit code ' .. tostring(result.code)))))
  return vim.trim(result.stdout or '')
end

local function resolve_stable_lazy(resolved)
  local lazy_path = check(vim.env.LAZY, 'LAZY path is missing')
  local timeout_ms = tonumber(vim.env.NV_IDE_SMOKE_GIT_TIMEOUT_MS) or 60000
  check(timeout_ms > 0, 'Lazy git timeout must be positive')
  git(lazy_path, { 'fetch', '--force', '--tags', 'origin' }, timeout_ms, 'lazy.nvim stable-tag fetch')
  local tags = git(lazy_path, { 'tag', '--list', 'v[0-9]*', '--sort=-version:refname' }, timeout_ms, 'lazy.nvim tag listing')
  local stable_tag
  for tag in tags:gmatch '[^\r\n]+' do
    if tag:match '^v%d+%.%d+%.%d+$' then
      stable_tag = tag
      break
    end
  end
  check(stable_tag, 'lazy.nvim has no stable semantic-version tag')
  local stable_head = git(lazy_path, { 'rev-list', '-n', '1', stable_tag }, timeout_ms, 'lazy.nvim stable-tag resolution')
  check(stable_head:match '^[0-9a-fA-F]+$' and #stable_head == 40, 'lazy.nvim stable tag resolved to an invalid commit')
  git(lazy_path, { 'checkout', '--force', '--detach', stable_head }, timeout_ms, 'lazy.nvim stable checkout')
  local checked_out = git(lazy_path, { 'rev-parse', 'HEAD' }, timeout_ms, 'lazy.nvim checkout verification')
  check(checked_out == stable_head, 'resolved lazy.nvim commit does not equal the fetched stable tag head')
  resolved['lazy.nvim'] = { branch = 'main', commit = stable_head }
  return stable_tag, stable_head
end

local function publish(lockfile_path)
  local timeout_ms = tonumber(vim.env.NV_IDE_SMOKE_FRESH_TIMEOUT_MS) or 30000
  check(timeout_ms > 0, 'fresh-startup timeout must be positive')
  local smoke = require('nv_ide.toolchain.smoke').new {
    root = vim.fn.stdpath 'config',
    lockfile = lockfile_path,
    nvim = vim.env.NV_IDE_SMOKE_FRESH_NVIM or vim.v.progpath,
    timeout_ms = timeout_ms,
  }
  local gate = dofile(vim.fs.joinpath(vim.fn.stdpath 'config', 'tests', 'headless', 'resolution_gate.lua'))
  local publication = gate.publish {
    smoke = smoke,
    source = lockfile_path,
    destination = check(vim.env.NV_IDE_SMOKE_LOCK_OUTPUT, 'resolved lockfile output is missing'),
  }
  check(publication.ok, 'fresh startup failed: ' .. table.concat(publication.errors or {}, '; '))
  vim.api.nvim_out_write 'FRESH STARTUP PASS\n'
end

local action = check(arg[1], 'action is required')
local manager = require 'lazy.manage'
local lazy_config = require 'lazy.core.config'
lazy_config.options.headless.log = false
local lockfile_path = vim.fs.joinpath(vim.fn.stdpath 'config', 'lazy-lock.json')

if action == 'seed' then
  local locked = read_json(lockfile_path)
  manager.install { wait = true, show = false, lockfile = true }
  check_errors 'locked install'
  manager.restore { wait = true, show = false, lockfile = true }
  -- The checkout evidence below is authoritative. Lazy can retain a status
  -- task error for generated plugin files even when restore reached the exact
  -- locked revision.
  assert_locked_checkout(locked)
  -- Lazy manages plugin specs but not its external bootstrap checkout, so its
  -- lock writer omits lazy.nvim. Restore the fully verified tracked seed for
  -- the next process and for rollback evidence in the resolved artifact.
  write_json(lockfile_path, locked)
elseif action == 'update' then
  manager.update { wait = true, show = false, lockfile = false }
  check_errors 'latest update'
  local resolved = read_json(lockfile_path)
  check(next(resolved) ~= nil, 'latest update produced an empty lockfile')
  vim.api.nvim_out_write 'LAZY UPDATE PASS\n'
  local stable_tag, stable_head = resolve_stable_lazy(resolved)
  write_json(lockfile_path, resolved)
  check(read_json(lockfile_path)['lazy.nvim'].commit == stable_head, 'resolved lockfile did not record lazy.nvim stable head')
  vim.api.nvim_out_write(('LAZY STABLE PASS %s %s\n'):format(stable_tag, stable_head))
  publish(lockfile_path)
elseif action == 'publish' then
  local resolved = read_json(lockfile_path)
  check(next(resolved) ~= nil, 'plugin update produced an empty lockfile')
  local stable_tag, stable_head = resolve_stable_lazy(resolved)
  write_json(lockfile_path, resolved)
  check(read_json(lockfile_path)['lazy.nvim'].commit == stable_head, 'resolved lockfile did not record lazy.nvim stable head')
  vim.api.nvim_out_write(('LAZY STABLE PASS %s %s\n'):format(stable_tag, stable_head))
  publish(lockfile_path)
else
  error('lazy resolution smoke: invalid action ' .. action, 0)
end

if action == 'seed' then
  vim.api.nvim_out_write 'LAZY SEED PASS\n'
end
