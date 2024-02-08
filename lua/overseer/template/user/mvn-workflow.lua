local path = require 'plenary.path'

local goals_file_path = '/.mvn_goals'
local profiles_file_path = '/.mvn_profiles'
local sdk_man_candidates_java = '~/.sdkman/candidates/java/'

local notification_displayed = false

local function is_pom_xml_in_cwd()
  local is_maven = path:new(vim.fn.getcwd() .. '/pom.xml'):exists()
  if is_maven and not notification_displayed then
    require 'notify' 'Found Maven. Setting up tasks'
    notification_displayed = true
  end
  return is_maven
end

local function find_dirs_with_pom_xml()
  local pomFiles = vim.fn.globpath(vim.fn.getcwd(), '**/pom.xml', false, true)

  local directories = {}
  for _, filePath in ipairs(pomFiles) do
    -- Extract the directory part of each file path
    local dir = vim.fn.fnamemodify(filePath, ':h')

    -- Exclude /src and /target
    if not string.find(dir, '/src') and not string.find(dir, '/target') then
      directories[dir] = true
    end
  end

  local dirList = vim.tbl_keys(directories)
  table.sort(dirList)
  return dirList
end

local function find_sdk_java_candidates()
  local java_candidates = vim.fn.globpath(sdk_man_candidates_java, '**/release', false, true)

  local directories = {}
  for _, filePath in ipairs(java_candidates) do
    -- Extract the directory part of each file path
    local dir = vim.fn.fnamemodify(filePath, ':h')
    directories[dir] = true
  end

  local dirList = vim.tbl_keys(directories)
  table.sort(dirList)
  return dirList
end

local function split_string_by_comma(content)
  local split = {}
  for _, line in ipairs(content) do
    for str in string.gmatch(line, '([^,]+)') do
      table.insert(split, str)
    end
  end
  return split
end

local function read_golas_file(cwd)
  local goals_file = path:new(cwd .. goals_file_path)
  if goals_file:exists() then
    local goals_content = vim.fn.readfile(cwd .. goals_file_path)
    local goals = split_string_by_comma(goals_content)
    return goals
  end
  return {}
end

local function read_profiles_file(cwd)
  local profiles_file = path:new(cwd .. profiles_file_path)
  if profiles_file:exists() then
    local profiles_content = vim.fn.readfile(cwd .. profiles_file_path)
    local profiles = split_string_by_comma(profiles_content)
    return profiles
  end
  return {}
end

local function get_last_directory_in_path(dir)
  local path_with_trailing_slash = dir:gsub('([^/])$', '%1/')
  local last_directory = path_with_trailing_slash:match '.*/([^/]*)/$'
  return last_directory
end

local provider = {
  condition = {
    callback = is_pom_xml_in_cwd,
  },
  generator = function(opts, cb)
    local ret = {}
    local tasks = {}
    local pom_dirs = find_dirs_with_pom_xml()
    local java_sdks = find_sdk_java_candidates()

    for _, dir in ipairs(pom_dirs) do
      local task = {}
      task.name = get_last_directory_in_path(dir)
      task.dir = string.sub(dir, string.len(vim.fn.getcwd()) + 1)
      task.goals = read_golas_file(dir)
      task.profiles = read_profiles_file(dir)
      task.sdks = java_sdks
      table.insert(tasks, task)
    end

    for i, task in ipairs(tasks) do
      table.insert(ret, {
        name = 'Maven: ' .. task.name,
        params = {
          clean = {
            type = 'boolean',
            desc = 'Will apply clean goal before other goals',
            default = 'true',
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
          local args = {}

          table.insert(args, '-f')
          table.insert(args, '.' .. task.dir .. '/pom.xml')

          if params.clean then
            table.insert(args, 'clean')
          end

          if params.goals then
            for _, goal in ipairs(params.goals) do
              table.insert(args, goal)
            end
          end

          if params.profiles then
            for _, profile in ipairs(params.profiles) do
              table.insert(args, '-P ' .. profile)
            end
          end

          local cmd = {}
          if not params.sdks then
            table.insert(cmd, 'mvn')
          else
            table.insert(cmd, 'JAVA_HOME=' .. params.sdks)
            table.insert(cmd, 'mvn')
          end

          return {
            cmd = cmd,
            args = args,
          }
        end,
        priority = i,
      })
    end

    cb(ret)
  end,
}

return provider
