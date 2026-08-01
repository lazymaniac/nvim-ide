local builders = require 'overseer.template.user.builders'

local discovery_timeout_ms = 10000

local function find_gradle_wrapper(search_dir)
  return vim.fs.find('gradlew', { path = search_dir, upward = true, type = 'file' })[1]
end

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
  find_gradle_wrapper = find_gradle_wrapper,
  dirname = vim.fs.dirname,
  executable = function(command)
    return vim.fn.executable(command)
  end,
  notify = function(message)
    vim.notify(message, vim.log.levels.INFO, { title = 'Overseer' })
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
