local M = {}

local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and table.concat(lines, '\n') or nil
end

local function nonempty(value)
  return type(value) == 'string' and value ~= '' and value or nil
end

local function runtime_name(contents)
  local major = contents and contents:match('JAVA_VERSION%s*=%s*["\']?(%d+)')
  return major and ('JavaSE-' .. major) or nil
end

function M.discover(options)
  options = options or {}
  local env = options.env or vim.env
  local exepath = options.exepath or vim.fn.exepath
  local stdpath = options.stdpath or vim.fn.stdpath
  local realpath = options.realpath or function(path) return vim.uv.fs_realpath(path) or path end
  local read = options.read_file or read_file
  local glob = options.glob or function(path) return vim.fn.glob(path, false, true) end

  local java_home = nonempty(env.JAVA_HOME)
  if not java_home then
    local executable = nonempty(exepath('java'))
    if executable then java_home = vim.fs.dirname(vim.fs.dirname(realpath(executable))) end
  end
  if java_home then java_home = vim.fs.normalize(java_home) end

  local homes = {}
  local seen = {}
  local function add(home)
    if not nonempty(home) then return end
    home = vim.fs.normalize(home)
    if not seen[home] then
      seen[home] = true
      homes[#homes + 1] = home
    end
  end

  add(java_home)
  local asdf_data = nonempty(env.ASDF_DATA_DIR)
  if not asdf_data and nonempty(env.HOME) then asdf_data = vim.fs.joinpath(env.HOME, '.asdf') end
  if asdf_data then
    for _, home in ipairs(glob(vim.fs.joinpath(asdf_data, 'installs', 'java', '*'))) do
      add(home)
    end
  end

  local runtimes = {}
  for _, home in ipairs(homes) do
    local name = runtime_name(read(vim.fs.joinpath(home, 'release')))
    if name then
      runtimes[#runtimes + 1] = {
        name = name,
        path = home,
        default = home == java_home or nil,
      }
    end
  end
  table.sort(runtimes, function(left, right)
    if left.default ~= right.default then return left.default == true end
    return left.name < right.name
  end)

  local mason = nonempty(env.MASON) or vim.fs.joinpath(stdpath('data'), 'mason')
  return {
    java_home = java_home,
    jdtls = nonempty(exepath('jdtls')) or 'jdtls',
    lombok = vim.fs.joinpath(mason, 'share', 'jdtls', 'lombok.jar'),
    formatter = vim.fs.joinpath(stdpath('config'), 'java-formatter.xml'),
    runtimes = runtimes,
  }
end

return M
