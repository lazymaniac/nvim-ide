local M = {}

function M.early(options)
  return require('nv_ide.toolchain.environment').setup(options)
end

function M.manifest()
  return require 'nv_ide.toolchain.manifest'
end

return M
