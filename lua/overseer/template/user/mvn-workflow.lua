local builders = require 'overseer.template.user.builders'

local goals_file_path = '/.mvn_goals'
local profiles_file_path = '/.mvn_profiles'
local sdk_man_candidates_java = '~/.sdkman/candidates/java/'

local function find_project_dir(search_dir)
  local pom_file = vim.fs.find('pom.xml', { path = search_dir, upward = true, type = 'file' })[1]
  return pom_file and vim.fs.dirname(pom_file) or nil
end

local function find_dirs_with_pom_xml(project_dir)
  local pom_files = vim.fn.globpath(project_dir, '**/pom.xml', false, true)
  local directories = {}
  for _, file_path in ipairs(pom_files) do
    local directory = vim.fn.fnamemodify(file_path, ':h')
    if not directory:find('/src', 1, true) and not directory:find('/target', 1, true) then
      directories[directory] = true
    end
  end

  local result = vim.tbl_keys(directories)
  table.sort(result)
  return result
end

local function find_sdk_java_candidates()
  local release_files = vim.fn.globpath(sdk_man_candidates_java, '**/release', false, true)
  local directories = {}
  for _, file_path in ipairs(release_files) do
    directories[vim.fn.fnamemodify(file_path, ':h')] = true
  end

  local result = vim.tbl_keys(directories)
  table.sort(result)
  return result
end

local function split_string_by_comma(content)
  local result = {}
  for _, line in ipairs(content) do
    for value in line:gmatch '([^,]+)' do
      result[#result + 1] = value
    end
  end
  return result
end

local function read_values_file(directory, file_name)
  local file_path = directory .. file_name
  if vim.fn.filereadable(file_path) == 1 then
    return split_string_by_comma(vim.fn.readfile(file_path))
  end
  return {}
end

return builders.maven_provider {
  find_project_dir = find_project_dir,
  executable = function(command)
    return vim.fn.executable(command)
  end,
  notify = function(message)
    vim.notify(message, vim.log.levels.INFO, { title = 'Overseer' })
  end,
  find_pom_dirs = find_dirs_with_pom_xml,
  find_java_sdks = find_sdk_java_candidates,
  basename = vim.fs.basename,
  joinpath = vim.fs.joinpath,
  read_goals = function(directory)
    return read_values_file(directory, goals_file_path)
  end,
  read_profiles = function(directory)
    return read_values_file(directory, profiles_file_path)
  end,
}
