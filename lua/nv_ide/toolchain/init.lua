local M = {}

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

return M
