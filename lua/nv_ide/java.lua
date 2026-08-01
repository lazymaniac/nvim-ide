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

local function default_macos_java_home()
  if vim.fn.executable('/usr/libexec/java_home') ~= 1 then return nil end
  local result = vim.system({ '/usr/libexec/java_home' }, { text = true }):wait()
  if result.code ~= 0 then return nil end
  return nonempty(vim.trim(result.stdout or ''))
end

local function default_asdf_java_home(exepath)
  local asdf = nonempty(exepath('asdf'))
  if not asdf then return nil end
  local result = vim.system({ asdf, 'where', 'java' }, { text = true }):wait()
  if result.code ~= 0 then return nil end
  return nonempty(vim.trim(result.stdout or ''))
end

function M.discover(options)
  options = options or {}
  local env = options.env or vim.env
  local exepath = options.exepath or vim.fn.exepath
  local stdpath = options.stdpath or vim.fn.stdpath
  local realpath = options.realpath or function(path) return vim.uv.fs_realpath(path) or path end
  local read = options.read_file or read_file
  local glob = options.glob or function(path) return vim.fn.glob(path, false, true) end
  local is_executable = options.is_executable or function(path) return vim.fn.executable(path) == 1 end
  local os_name = options.os or vim.uv.os_uname().sysname
  local macos_java_home = options.macos_java_home or default_macos_java_home
  local asdf_java_home = options.asdf_java_home or function() return default_asdf_java_home(exepath) end

  local homes = {}
  local seen = {}
  local validated = {}
  local java_home
  local function add(home, prefer)
    if not nonempty(home) then return end
    home = vim.fs.normalize(home)
    if not seen[home] then
      seen[home] = true
      homes[#homes + 1] = home
      local name = runtime_name(read(vim.fs.joinpath(home, 'release')))
      validated[home] = name and is_executable(vim.fs.joinpath(home, 'bin', 'java')) and name or false
    end
    if prefer and not java_home and validated[home] then java_home = home end
  end

  add(nonempty(env.JAVA_HOME), true)
  local executable = nonempty(exepath('java'))
  if executable then add(vim.fs.dirname(vim.fs.dirname(realpath(executable))), true) end
  if not java_home then add(asdf_java_home(), true) end
  if os_name == 'Darwin' and not java_home then add(macos_java_home(), true) end
  local asdf_data = nonempty(env.ASDF_DATA_DIR)
  if not asdf_data and nonempty(env.HOME) then asdf_data = vim.fs.joinpath(env.HOME, '.asdf') end
  if asdf_data then
    for _, home in ipairs(glob(vim.fs.joinpath(asdf_data, 'installs', 'java', '*'))) do
      add(home, false)
    end
  end

  local runtimes = {}
  for _, home in ipairs(homes) do
    local name = validated[home]
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
