local M = {}

local active_jshell_runs = {}
local BUILD_SUCCEEDED = 1

local function class_portion(main_class)
  return type(main_class) == 'string' and (main_class:match('/(.+)$') or main_class) or nil
end

local function existing_paths(paths, fs_stat)
  local result = {}
  for _, path in ipairs(type(paths) == 'table' and paths or {}) do
    local stat = fs_stat(path)
    if stat and (stat.type == 'file' or stat.type == 'directory') then
      result[#result + 1] = path
    end
  end
  return result
end

local function supports_command(client, command)
  local provider = client.server_capabilities and client.server_capabilities.executeCommandProvider
  return type(provider) == 'table' and vim.tbl_contains(provider.commands or {}, command)
end

local function default_client(client_id, bufnr)
  if client_id then
    local client = vim.lsp.get_client_by_id(client_id)
    if client
      and client.name == 'jdtls'
      and client.attached_buffers
      and client.attached_buffers[bufnr]
    then
      return client
    end
    return nil
  end
  local clients = require('jdtls.util').get_clients { name = 'jdtls', bufnr = bufnr }
  return #clients == 1 and clients[1] or nil
end

local function default_dependencies()
  return {
    buf_is_valid = vim.api.nvim_buf_is_valid,
    buf_name = vim.api.nvim_buf_get_name,
    buf_uri = vim.uri_from_bufnr,
    buf_options = function(bufnr)
      return {
        buftype = vim.bo[bufnr].buftype,
        filetype = vim.bo[bufnr].filetype,
        modifiable = vim.bo[bufnr].modifiable,
        readonly = vim.bo[bufnr].readonly,
      }
    end,
    save = function(bufnr)
      vim.api.nvim_buf_call(bufnr, function() vim.cmd.update() end)
    end,
    resolve_classname = function(bufnr)
      return vim.api.nvim_buf_call(bufnr, require('jdtls.util').resolve_classname)
    end,
    get_client = default_client,
    request = function(client, method, params, callback, bufnr)
      return client:request(method, params, callback, bufnr)
    end,
    fs_stat = vim.uv.fs_stat,
    is_executable = function(path) return vim.fn.executable(path) == 1 end,
    exepath = vim.fn.exepath,
    path_separator = vim.fn.has('win32') == 1 and ';' or ':',
    notify = vim.notify,
    cmd = vim.cmd,
    current_buf = vim.api.nvim_get_current_buf,
    set_bufhidden = function(bufnr) vim.bo[bufnr].bufhidden = 'wipe' end,
    buf_delete = function(bufnr) vim.api.nvim_buf_delete(bufnr, { force = true }) end,
    jobstart = vim.fn.jobstart,
    jobstop = vim.fn.jobstop,
    chan_send = vim.api.nvim_chan_send,
    startinsert = function() vim.cmd.startinsert() end,
  }
end

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

function M.run_current_class(options)
  options = options or {}
  local bufnr = options.bufnr or vim.api.nvim_get_current_buf()
  local deps = vim.tbl_extend('force', default_dependencies(), options.deps or {})
  deps.open_terminal = deps.open_terminal or function(argv, input, cwd)
    local opened, open_error = pcall(deps.cmd, 'botright 12new')
    if not opened then return false, 'could not open terminal split: ' .. tostring(open_error) end
    local terminal_buf = deps.current_buf()
    local hidden, hidden_error = pcall(deps.set_bufhidden, terminal_buf)
    if not hidden then
      pcall(deps.buf_delete, terminal_buf)
      return false, 'could not prepare terminal buffer: ' .. tostring(hidden_error)
    end
    local started, job = pcall(deps.jobstart, argv, { term = true, cwd = cwd })
    if not started or type(job) ~= 'number' or job <= 0 then
      pcall(deps.buf_delete, terminal_buf)
      return false, 'terminal job failed to start: ' .. tostring(job)
    end
    local sent, send_error = pcall(deps.chan_send, job, input)
    if not sent then
      pcall(deps.jobstop, job)
      pcall(deps.buf_delete, terminal_buf)
      return false, 'could not send main invocation: ' .. tostring(send_error)
    end
    pcall(deps.startinsert)
    return true
  end

  if active_jshell_runs[bufnr] then
    deps.notify('Java JShell: a run is already in progress for this buffer', vim.log.levels.WARN)
    return false
  end

  if not deps.buf_is_valid(bufnr) then
    deps.notify('Java JShell: current buffer is invalid', vim.log.levels.ERROR)
    return false
  end
  local buffer_options = deps.buf_options(bufnr)
  local path = deps.buf_name(bufnr)
  if buffer_options.filetype ~= 'java'
    or buffer_options.buftype ~= ''
    or path == ''
    or not path:lower():match('%.java$')
  then
    deps.notify('Java JShell: current buffer is not a named Java source file', vim.log.levels.ERROR)
    return false
  end
  if buffer_options.readonly or not buffer_options.modifiable then
    deps.notify('Java JShell: current Java buffer is not writable', vim.log.levels.ERROR)
    return false
  end

  local client = deps.get_client(options.client_id, bufnr)
  if not client then
    deps.notify('Java JShell: no JDTLS client is attached to this buffer', vim.log.levels.ERROR)
    return false
  end

  active_jshell_runs[bufnr] = true
  local finished = false
  local function finish(message, level)
    if finished then return false end
    finished = true
    active_jshell_runs[bufnr] = nil
    if message then deps.notify('Java JShell: ' .. message, level or vim.log.levels.ERROR) end
    return not message
  end
  local function request(method, params, callback, label)
    local ok, accepted = pcall(deps.request, client, method, params, callback, bufnr)
    if not ok then return finish(label .. ' failed: ' .. tostring(accepted)) end
    if accepted ~= true then return finish(label .. ' request was rejected by JDTLS') end
    return true
  end

  local saved, save_error = pcall(deps.save, bufnr)
  if not saved then return finish('could not save the current file: ' .. tostring(save_error)) end
  local resolved, class_name = pcall(deps.resolve_classname, bufnr)
  if not resolved or type(class_name) ~= 'string' or class_name == '' then
    return finish('could not resolve the current class name')
  end

  local function launch(paths, java_exec)
    local module_paths = existing_paths(paths[1], deps.fs_stat)
    local class_paths = existing_paths(paths[2], deps.fs_stat)
    local suffix = java_exec:lower():match('%.exe$') and '.exe' or ''
    local sibling = vim.fs.joinpath(vim.fs.dirname(java_exec), 'jshell' .. suffix)
    local jshell = deps.is_executable(sibling) and sibling or deps.exepath('jshell')
    if type(jshell) ~= 'string' or jshell == '' then return finish('could not find JShell') end

    local argv = { jshell }
    if #class_paths > 0 then
      vim.list_extend(argv, { '--class-path', table.concat(class_paths, deps.path_separator) })
    end
    if #module_paths > 0 then
      vim.list_extend(argv, {
        '--module-path', table.concat(module_paths, deps.path_separator),
        '--add-modules', 'ALL-MODULE-PATH',
      })
    end
    local cwd = client.config and client.config.root_dir or nil
    local called, ok, terminal_error = pcall(
      deps.open_terminal,
      argv,
      class_name .. '.main(new String[0]);\n',
      cwd
    )
    if not called then return finish('terminal launch failed: ' .. tostring(ok)) end
    if not ok then return finish(terminal_error or 'could not start JShell') end
    return finish()
  end

  local function resolve_java(main, paths)
    local project = main.projectName or ''
    if supports_command(client, 'vscode.java.resolveJavaExecutable') then
      local params = {
        command = 'vscode.java.resolveJavaExecutable',
        arguments = { main.mainClass, project },
      }
      return request('workspace/executeCommand', params, function(err, java_exec)
        if err then return finish('Java executable resolution failed: ' .. (err.message or vim.inspect(err))) end
        if type(java_exec) ~= 'string' or java_exec == '' then
          return finish('JDTLS returned no Java executable')
        end
        launch(paths, java_exec)
      end, 'Java executable resolution')
    end

    local setting = 'org.eclipse.jdt.ls.core.vm.location'
    local params = {
      command = 'java.project.getSettings',
      arguments = { deps.buf_uri(bufnr), { setting } },
    }
    return request('workspace/executeCommand', params, function(err, settings)
      if err then return finish('Java runtime setting failed: ' .. (err.message or vim.inspect(err))) end
      local java_home = type(settings) == 'table' and settings[setting] or nil
      if type(java_home) ~= 'string' or java_home == '' then
        return finish('JDTLS returned no Java runtime setting')
      end
      local suffix = vim.fn.has('win32') == 1 and '.exe' or ''
      launch(paths, vim.fs.joinpath(java_home, 'bin', 'java' .. suffix))
    end, 'Java runtime setting')
  end

  local function resolve_paths(main)
    local params = {
      command = 'vscode.java.resolveClasspath',
      arguments = { main.mainClass, main.projectName or '' },
    }
    return request('workspace/executeCommand', params, function(err, paths)
      if err then return finish('classpath resolution failed: ' .. (err.message or vim.inspect(err))) end
      if type(paths) ~= 'table' or type(paths[1]) ~= 'table' or type(paths[2]) ~= 'table' then
        return finish('JDTLS returned an invalid classpath response')
      end
      resolve_java(main, paths)
    end, 'classpath resolution')
  end

  local function resolve_main()
    return request('workspace/executeCommand', {
      command = 'vscode.java.resolveMainClass',
    }, function(err, main_classes)
      if err then return finish('main-class resolution failed: ' .. (err.message or vim.inspect(err))) end
      local match
      for _, main in ipairs(type(main_classes) == 'table' and main_classes or {}) do
        if class_portion(main.mainClass) == class_name then
          match = main
          break
        end
      end
      if not match then return finish('the current class has no recognized main(String[]) method') end
      resolve_paths(match)
    end, 'main-class resolution')
  end

  local started = request('java/buildWorkspace', false, function(err, status)
    if err then return finish('incremental build failed: ' .. (err.message or vim.inspect(err))) end
    if status ~= BUILD_SUCCEEDED then
      return finish(('incremental build returned status %s; use <leader>cc for diagnostics'):format(tostring(status)))
    end
    resolve_main()
  end, 'incremental build')
  return started == true
end

function M.bundle_patterns(mason)
  return {
    vim.fs.joinpath(mason, 'share', 'java-debug-adapter', 'com.microsoft.java.debug.plugin-*.jar'),
    vim.fs.joinpath(mason, 'share', 'vscode-java-decompiler', 'bundles', '*.jar'),
    vim.fs.joinpath(mason, 'share', 'java-test', '*.jar'),
  }
end

return M
