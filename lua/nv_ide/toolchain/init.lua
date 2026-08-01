local M = {}

local function pack(...)
  return { n = select('#', ...), ... }
end

function M.early(options)
  local environment = require('nv_ide.toolchain.environment').setup(options)
  require('nv_ide.toolchain.orchestrator').setup()
  return environment
end

function M.manifest()
  return require 'nv_ide.toolchain.manifest'
end

function M.install(options)
  return require('nv_ide.toolchain.orchestrator').setup():run(options or {})
end

function M.update(options)
  return require('nv_ide.toolchain.orchestrator').setup():update(options or {})
end

function M.with_startup_lock(operation, options)
  options = options or {}
  local instance = options.instance or require('nv_ide.toolchain.orchestrator').setup()
  local env = options.env or vim.env
  local read_only_child = env.NV_IDE_TOOLCHAIN_READONLY_CHILD == '1'
  local token
  if read_only_child then
    local parent_pid = tonumber(env.NV_IDE_TOOLCHAIN_PARENT_LOCK_PID)
    local parent_token = env.NV_IDE_TOOLCHAIN_PARENT_LOCK_TOKEN
    local valid_pid = parent_pid and parent_pid > 0 and parent_pid == math.floor(parent_pid)
    local valid_token = type(parent_token) == 'string' and parent_token:match '^[0-9a-f]+$' and #parent_token == 64
    if not valid_pid or not valid_token or type(instance.lock.held_by) ~= 'function' or not instance.lock:held_by(parent_pid, parent_token) then
      error 'refusing unverified read-only toolchain child'
    end
  else
    local lock_error
    token, lock_error = instance.lock:acquire_wait {
      timeout_ms = instance.startup_lock_timeout_ms,
      poll_ms = instance.poll_ms,
    }
    if not token then
      error('failed to acquire cold-start toolchain lock: ' .. tostring(lock_error))
    end
  end

  local previous_read_only = vim.g.nv_ide_toolchain_read_only_startup
  if read_only_child then
    vim.g.nv_ide_toolchain_read_only_startup = true
  end
  local result = pack(xpcall(operation, debug.traceback))
  vim.g.nv_ide_toolchain_read_only_startup = previous_read_only
  local released, release_result = true, true
  if token then
    released, release_result = pcall(instance.lock.release, instance.lock, token)
  end
  if not result[1] then
    error(result[2], 0)
  end
  if not released or release_result ~= true then
    error('failed to release cold-start toolchain lock: ' .. tostring(release_result))
  end
  return unpack(result, 2, result.n)
end

return M
