local builders = require 'overseer.template.user.builders'

local probe_timeout_ms = 2000

local function command_succeeds(argv)
  if vim.fn.executable(argv[1]) ~= 1 then
    return false
  end

  local started, process = pcall(vim.system, argv, { text = true, timeout = probe_timeout_ms })
  if not started then
    return false
  end
  local completed, result = pcall(function()
    return process:wait()
  end)
  return completed and result.code == 0
end

return builders.docker_provider {
  command_succeeds = command_succeeds,
}
