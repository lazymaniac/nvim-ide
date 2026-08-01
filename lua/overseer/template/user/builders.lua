local M = {
  name = 'Internal Overseer command builders',
  generator = function()
    return {}
  end,
}

local gradle_command = './gradlew'

local function is_executable(result)
  return result == true or result == 1
end

local function append(target, values)
  for _, value in ipairs(values or {}) do
    assert(type(value) == 'string', 'argv values must be strings')
    target[#target + 1] = value
  end
end

local function finish_argument(arguments, current, started)
  if started then
    arguments[#arguments + 1] = table.concat(current)
  end
end

function M.split_argv(value)
  if value == nil or value == '' then
    return {}
  end
  if type(value) == 'table' then
    local arguments = {}
    append(arguments, value)
    return arguments
  end
  assert(type(value) == 'string', 'extra parameters must be a string or argv list')

  local arguments = {}
  local current = {}
  local started = false
  local quote
  local index = 1

  while index <= #value do
    local character = value:sub(index, index)
    if quote == "'" then
      if character == "'" then
        quote = nil
      else
        current[#current + 1] = character
      end
      started = true
    elseif quote == '"' then
      if character == '"' then
        quote = nil
      elseif character == '\\' then
        index = index + 1
        assert(index <= #value, 'unterminated escape in extra parameters')
        current[#current + 1] = value:sub(index, index)
      else
        current[#current + 1] = character
      end
      started = true
    elseif character == "'" or character == '"' then
      quote = character
      started = true
    elseif character == '\\' then
      index = index + 1
      assert(index <= #value, 'unterminated escape in extra parameters')
      current[#current + 1] = value:sub(index, index)
      started = true
    elseif character:match '%s' then
      finish_argument(arguments, current, started)
      current = {}
      started = false
    else
      current[#current + 1] = character
      started = true
    end
    index = index + 1
  end

  assert(not quote, 'unterminated quote in extra parameters')
  finish_argument(arguments, current, started)
  return arguments
end

function M.maven(params)
  assert(type(params) == 'table', 'Maven parameters must be a table')
  assert(type(params.pom_file) == 'string' and params.pom_file ~= '', 'Maven pom_file is required')

  local arguments = { '-f', params.pom_file }
  if params.clean == true then
    arguments[#arguments + 1] = 'clean'
  end
  if params.skip_test == true then
    arguments[#arguments + 1] = '-DskipTests'
  end
  append(arguments, params.goals)
  for _, profile in ipairs(params.profiles or {}) do
    assert(type(profile) == 'string', 'Maven profiles must be strings')
    arguments[#arguments + 1] = '-P'
    arguments[#arguments + 1] = profile
  end
  append(arguments, M.split_argv(params.extra_params))

  local environment = {}
  if type(params.sdks) == 'string' and params.sdks ~= '' then
    environment.JAVA_HOME = params.sdks
  end

  return {
    cmd = 'mvn',
    args = arguments,
    env = environment,
  }
end

function M.maven_provider(probes)
  assert(type(probes) == 'table', 'Maven provider probes must be a table')
  local notification_displayed = false

  return {
    generator = function(_, cb)
      if not probes.has_root_pom() then
        cb {}
        return
      end
      if not is_executable(probes.executable 'mvn') then
        cb 'Maven executable is unavailable'
        return
      end
      if not notification_displayed then
        probes.notify 'Found Maven. Setting up tasks'
        notification_displayed = true
      end

      local definitions = {}
      local java_sdks = probes.find_java_sdks()
      for priority, directory in ipairs(probes.find_pom_dirs()) do
        local task = {
          name = probes.basename(directory),
          pom_file = probes.joinpath(directory, 'pom.xml'),
          goals = probes.read_goals(directory),
          profiles = probes.read_profiles(directory),
          sdks = java_sdks,
        }
        definitions[#definitions + 1] = {
          name = 'Maven: ' .. task.name,
          params = {
            clean = {
              type = 'boolean',
              desc = 'Will apply clean goal before other goals',
              default = true,
              order = 1,
            },
            skip_test = {
              type = 'boolean',
              desc = 'Skip tests?',
              default = true,
              order = 2,
            },
            goals = {
              type = 'list',
              desc = 'Select additional goal(s)',
              subtype = {
                type = 'enum',
                choices = task.goals,
              },
              optional = true,
              delimiter = ' ',
              order = 3,
            },
            profiles = {
              type = 'list',
              desc = 'Add optional profile(s)',
              subtype = {
                type = 'enum',
                choices = task.profiles,
              },
              optional = true,
              delimiter = ' ',
              order = 4,
            },
            sdks = {
              desc = 'Build with Java version. Empty means current',
              type = 'enum',
              choices = task.sdks,
              optional = true,
              order = 5,
            },
            extra_params = {
              type = 'string',
              desc = 'Add extra parameter like -Denable.integration.test',
              optional = true,
              order = 6,
            },
          },
          builder = function(params)
            return M.maven {
              pom_file = task.pom_file,
              clean = params.clean,
              skip_test = params.skip_test,
              goals = params.goals,
              profiles = params.profiles,
              sdks = params.sdks,
              extra_params = params.extra_params,
            }
          end,
          priority = priority,
        }
      end
      cb(definitions)
    end,
  }
end

function M.resolve_docker_compose(command_succeeds)
  assert(type(command_succeeds) == 'function', 'Docker Compose probe is required')
  if command_succeeds { 'docker', 'compose', 'version' } then
    return { cmd = 'docker', args = { 'compose' } }
  end
  if command_succeeds { 'docker-compose', 'version' } then
    return { cmd = 'docker-compose', args = {} }
  end
  return nil, 'Docker Compose executable is unavailable'
end

function M.docker(params, compose_command)
  assert(type(params) == 'table', 'Docker Compose parameters must be a table')
  assert(type(compose_command) == 'table', 'resolved Docker Compose command is required')
  assert(type(compose_command.cmd) == 'string', 'Docker Compose command must be a string')

  local arguments = {}
  append(arguments, compose_command.args)
  if type(params.file) == 'string' and params.file ~= '' then
    arguments[#arguments + 1] = '-f'
    arguments[#arguments + 1] = params.file
  end
  if type(params.task) == 'string' and params.task ~= '' then
    arguments[#arguments + 1] = params.task
  end
  if params.detached == true and params.task == 'up' then
    arguments[#arguments + 1] = '-d'
  end
  append(arguments, M.split_argv(params.extra_params))

  return {
    cmd = compose_command.cmd,
    args = arguments,
    env = {},
  }
end

function M.docker_provider(probes)
  assert(type(probes) == 'table', 'Docker Compose provider probes must be a table')
  assert(type(probes.command_succeeds) == 'function', 'Docker Compose command probe is required')

  return {
    generator = function(_, cb)
      local compose_command, err = M.resolve_docker_compose(probes.command_succeeds)
      if not compose_command then
        cb(err)
        return
      end

      cb {
        {
          name = 'Docker Compose',
          params = {
            file = {
              type = 'string',
              desc = 'Name of docker-compose file. Empty means docker-compose.yml',
              optional = true,
              order = 1,
            },
            task = {
              type = 'enum',
              desc = 'Action',
              choices = {
                'build',
                'create',
                'down',
                'images',
                'kill',
                'logs',
                'pause',
                'ps',
                'pull',
                'restart',
                'rm',
                'start',
                'stop',
                'top',
                'unpause',
                'up',
              },
              order = 2,
            },
            detached = {
              type = 'boolean',
              desc = 'Run as detached?',
              default = true,
              order = 3,
            },
            extra_params = {
              type = 'string',
              desc = 'Add extra parameter(s)',
              optional = true,
              order = 4,
            },
          },
          builder = function(params)
            return M.docker(params, compose_command)
          end,
          priority = 40,
        },
      }
    end,
  }
end

function M.gradle(params)
  assert(type(params) == 'table', 'Gradle parameters must be a table')
  local arguments = {}
  append(arguments, params.tasks)
  append(arguments, M.split_argv(params.extra_params))
  return {
    cmd = gradle_command,
    args = arguments,
    env = {},
  }
end

function M.parse_gradle_tasks(output)
  local lines = output
  if type(output) == 'string' then
    lines = {}
    for line in output:gmatch '[^\r\n]+' do
      lines[#lines + 1] = line
    end
  end
  assert(type(lines) == 'table', 'Gradle task output must be a string or line list')

  local found = {}
  for _, line in ipairs(lines) do
    local task = line:match '^%s*([:%w_.%-]+)%s+%-%s+'
    if task then
      found[task] = true
    end
  end

  local tasks = {}
  for task in pairs(found) do
    tasks[#tasks + 1] = task
  end
  table.sort(tasks)
  return tasks
end

local function run_gradle_tasks(probes, timeout_ms, callback)
  local output = {}
  local errors = {}
  local completed = false
  local cancel_timeout
  local job_id

  local function finish(result, err)
    if completed then
      return
    end
    completed = true
    if cancel_timeout then
      pcall(cancel_timeout)
    end
    callback(result, err)
  end

  local options = {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data or {}) do
        if line ~= '' then
          output[#output + 1] = line
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data or {}) do
        if line ~= '' then
          errors[#errors + 1] = line
        end
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        finish(output)
        return
      end

      local message = ('Gradle task discovery failed with exit code %s'):format(tostring(code))
      if #errors > 0 then
        message = message .. ': ' .. table.concat(errors, '\n')
      end
      finish(nil, message)
    end,
  }

  local started, result = pcall(probes.jobstart, { gradle_command, 'tasks', '--console=plain' }, options)
  if not started then
    finish(nil, 'Gradle task discovery jobstart failed: ' .. tostring(result))
    return
  end
  job_id = result
  if job_id == 0 then
    finish(nil, 'Gradle task discovery failed: gradlew is not executable')
    return
  end
  if job_id == -1 then
    finish(nil, 'Gradle task discovery failed: invalid arguments')
    return
  end
  if type(job_id) ~= 'number' or job_id < 1 then
    finish(nil, 'Gradle task discovery failed to start')
    return
  end
  if completed then
    return
  end

  local scheduled, cancel_or_error = pcall(probes.defer, timeout_ms, function()
    if completed then
      return
    end
    pcall(probes.jobstop, job_id)
    finish(nil, ('Gradle task discovery timed out after %dms'):format(timeout_ms))
  end)
  if not scheduled then
    pcall(probes.jobstop, job_id)
    finish(nil, 'Gradle task discovery timeout setup failed: ' .. tostring(cancel_or_error))
    return
  end
  if type(cancel_or_error) == 'function' then
    cancel_timeout = cancel_or_error
  end
end

function M.gradle_provider(probes, options)
  assert(type(probes) == 'table', 'Gradle provider probes must be a table')
  assert(type(options) == 'table', 'Gradle provider options must be a table')
  assert(type(options.timeout_ms) == 'number' and options.timeout_ms > 0, 'Gradle timeout_ms must be positive')
  local notification_displayed = false

  return {
    generator = function(_, cb)
      if not is_executable(probes.executable(gradle_command)) then
        cb 'Gradle task discovery failed: gradlew is not executable'
        return
      end
      if not notification_displayed then
        probes.notify 'Found Gradle. Creating task'
        notification_displayed = true
      end

      run_gradle_tasks(probes, options.timeout_ms, function(tasks_output, err)
        if err then
          cb(err)
          return
        end

        cb {
          {
            name = 'Gradle',
            params = {
              tasks = {
                type = 'list',
                desc = 'Select task(s)',
                subtype = {
                  type = 'enum',
                  choices = M.parse_gradle_tasks(tasks_output),
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
            builder = M.gradle,
            priority = 40,
          },
        }
      end)
    end,
  }
end

return M
