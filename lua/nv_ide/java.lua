local M = {}

local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and table.concat(lines, '\n') or nil
end

local function nonempty(value)
  return type(value) == 'string' and value ~= '' and value or nil
end

local function runtime_name(contents)
  local version = contents and contents:match('JAVA_VERSION%s*=%s*["\']?([%d%.]+)')
  local legacy = version and version:match('^1%.(%d+)')
  if legacy then return 'JavaSE-1.' .. legacy end
  local major = version and version:match('^(%d+)')
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
  local is_executable = options.is_executable or function(path) return vim.fn.executable(path) == 1 end
  local os_name = options.os or vim.uv.os_uname().sysname
  local probe_timeout_ms = options.probe_timeout_ms or 2000
  local system = options.system or vim.system
  local command_executable = options.command_executable or function(path) return vim.fn.executable(path) == 1 end
  local errors = {}

  local function probe(argv, label)
    if not command_executable(argv[1]) then return nil end
    local spawned, process = pcall(system, argv, { text = true })
    if not spawned then
      errors[#errors + 1] = ('%s failed to start: %s'):format(label, tostring(process))
      return nil
    end
    local waited, result = pcall(function() return process:wait(probe_timeout_ms) end)
    if not waited then
      errors[#errors + 1] = ('%s failed while waiting: %s'):format(label, tostring(result))
      return nil
    end
    if result.code == 124 then
      errors[#errors + 1] = ('%s timed out after %d ms'):format(label, probe_timeout_ms)
      return nil
    end
    if result.code ~= 0 then
      local stderr = vim.trim(result.stderr or '')
      errors[#errors + 1] = ('%s exited %d%s'):format(label, result.code, stderr ~= '' and ': ' .. stderr or '')
      return nil
    end
    return nonempty(vim.trim(result.stdout or ''))
  end

  local macos_java_home = options.macos_java_home or function()
    return probe({ '/usr/libexec/java_home' }, 'macOS java_home')
  end
  local asdf_java_home = options.asdf_java_home or function()
    local asdf = nonempty(exepath('asdf'))
    return asdf and probe({ asdf, 'where', 'java' }, 'asdf where java') or nil
  end

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
    errors = errors,
  }
end

function M.workspace_id(root, deps)
  if not root then return nil end
  deps = deps or {}
  local realpath = deps.realpath or vim.uv.fs_realpath
  local abspath = deps.abspath or vim.fs.abspath
  local absolute = abspath(root)
  local normalized = vim.fs.normalize(realpath(absolute) or absolute)
  local name = vim.fs.basename(normalized):gsub('[^%w_.-]', '_')
  return ('%s-%s'):format(name, vim.fn.sha256(normalized):sub(1, 12))
end

function M.bundle_patterns(mason)
  return {
    vim.fs.joinpath(mason, 'share', 'java-debug-adapter', 'com.microsoft.java.debug.plugin-*.jar'),
    vim.fs.joinpath(mason, 'share', 'vscode-java-decompiler', 'bundles', '*.jar'),
    vim.fs.joinpath(mason, 'share', 'java-test', '*.jar'),
  }
end

return M
