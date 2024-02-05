local path = require 'plenary.path'

local cwd = vim.fn.getcwd()
local goals_file_path = cwd .. '/.mvn_goals'
local profiles_file_path = cwd .. '/.mvn_profiles'
local maven_data = {}

local function is_pom_xml_present()
  return path:new(vim.fn.getcwd() .. '/pom.xml'):exists()
end

local function splitStringByComma(content)
  local t = {}
  for _, line in ipairs(content) do
    for str in string.gmatch(line, '([^,]+)') do
      table.insert(t, str)
    end
  end
  return t
end

local goals_file = path:new(goals_file_path)

if goals_file:exists() then
  local goals_content = vim.fn.readfile(goals_file_path)
  local goals = splitStringByComma(goals_content)
  maven_data.goals = goals
end

local profiles_file = path:new(profiles_file_path)

if profiles_file:exists() then
  local profiles_content = vim.fn.readfile(profiles_file_path)
  local profiles = splitStringByComma(profiles_content)
  maven_data.profiles = profiles
end

return {
  name = 'Maven Workflow',
  params = {
    clean = {
      type = 'boolean',
      name = 'Apply clean goal?',
      desc = 'Will apply clean goal before other goals',
      default = 'true',
    },
    goals = {
      type = 'list',
      name = 'Select additional goals',
      subtype = {
        type = 'enum',
        choices = maven_data.goals,
      },
      optional = true,
      delimiter = ' ',
    },
    profiles = {
      type = 'list',
      name = 'Add optional profile(s)',
      subtype = {
        type = 'enum',
        choices = maven_data.profiles,
      },
      optional = true,
      delimiter = ' ',
    },
  },
  builder = function(params)
    local args = {}

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

    return {
      cmd = { 'mvn' },
      args = args,
    }
  end,
  condition = {
    callback = is_pom_xml_present,
  },
}
