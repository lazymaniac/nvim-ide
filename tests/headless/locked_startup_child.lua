local dir, marker = arg[1], arg[2]
assert(type(dir) == 'string' and dir ~= '', 'lock directory is required')
assert(type(marker) == 'string' and marker ~= '', 'marker path is required')

local instance = {
  lock = require('nv_ide.toolchain.lock').new { dir = dir },
  timeout_ms = 100,
  poll_ms = 10,
}

require('nv_ide.toolchain').with_startup_lock(function()
  assert(vim.g.nv_ide_toolchain_read_only_startup == true, 'verified smoke child was not made read-only')
  assert(vim.fn.writefile({ 'child-started' }, marker, 'b') == 0, 'failed to write child marker')
end, { instance = instance })
