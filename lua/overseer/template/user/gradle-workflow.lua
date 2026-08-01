local builders = require 'overseer.template.user.builders'

local discovery_timeout_ms = 10000

local function defer(timeout_ms, callback)
  local timer = vim.defer_fn(callback, timeout_ms)
  return function()
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
end

return builders.gradle_provider({
  executable = function(command)
    return vim.fn.executable(command)
  end,
  notify = function(message)
    local notify = require 'notify'
    notify(message)
  end,
  jobstart = function(argv, options)
    return vim.fn.jobstart(argv, options)
  end,
  jobstop = function(job_id)
    vim.fn.jobstop(job_id)
  end,
  defer = defer,
}, {
  timeout_ms = discovery_timeout_ms,
})
