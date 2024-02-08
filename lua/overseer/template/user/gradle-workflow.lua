local path = require 'plenary.path'

local function is_gradle_in_cwd()
  local is_gradle = path:new(vim.fn.getcwd() .. '/gradlew'):exists()
  if is_gradle then
    require 'notify' 'Found Gradle. Creating task'
  end
  return is_gradle
end

-- Function to run a shell command in the background
local function run_command_in_background(cmd, callback)
  local output = {}
  local job_id
  local on_stdout = function(_, data)
    if data then
      for _, line in ipairs(data) do
        if line ~= '' then -- Ignore empty strings (last data event)
          table.insert(output, line)
        end
      end
    end
  end
  local on_exit = function(_, code)
    if code == 0 then
      callback(table.concat(output, '\n'))
    else
      print('Command failed with exit code', code)
    end
  end
  -- Start the job
  job_id = vim.fn.jobstart(cmd, {
    on_stdout = on_stdout,
    on_exit = on_exit,
    stdout_buffered = true,
  })
  if job_id == 0 then
    print 'Failed to run gradle command: Not executable'
  elseif job_id == -1 then
    print 'Failed to run gradle command: Invalid arguments'
  end
end

local provider = {
  condition = {
    callback = is_gradle_in_cwd,
  },
  generator = function(opts, cb)
    run_command_in_background('./gradlew tasks', function(tasks_output)
      local ret = {}
      local gradle_tasks = {}

      for task in tasks_output:gmatch '(%w+)%s%-' do
        if task and not gradle_tasks[task] then
          gradle_tasks[task] = true
        end
      end

      gradle_tasks = vim.tbl_keys(gradle_tasks)
      table.sort(gradle_tasks)

      table.insert(ret, {
        name = 'Gradle',
        params = {
          tasks = {
            type = 'list',
            desc = 'Selec task(s)',
            subtype = {
              type = 'enum',
              choices = gradle_tasks,
            },
            delimiter = ' ',
            order = 1,
          },
          extra_params = {
            type = 'string',
            desc = 'Add extra parameter(s)',
            optional = true,
            order = 2,
          },
        },
        builder = function(params)
          local args = {}

          if params.tasks then
            for _, task in ipairs(params.tasks) do
              table.insert(args, task)
            end
          end

          return {
            cmd = './gradlew',
            args = args,
          }
        end,
        priority = 40,
      })
      cb(ret)
    end)
  end,
}

return provider
