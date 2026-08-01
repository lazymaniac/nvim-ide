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
  local token, lock_error = instance.lock:acquire_wait {
    timeout_ms = instance.timeout_ms,
    poll_ms = instance.poll_ms,
  }
  if not token then
    error('failed to acquire cold-start toolchain lock: ' .. tostring(lock_error))
  end

  local result = pack(xpcall(operation, debug.traceback))
  local released, release_result = pcall(instance.lock.release, instance.lock, token)
  if not result[1] then
    error(result[2], 0)
  end
  if not released or release_result ~= true then
    error('failed to release cold-start toolchain lock: ' .. tostring(release_result))
  end
  return unpack(result, 2, result.n)
end

return M
