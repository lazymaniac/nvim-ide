local M = {}

local active_jshell_runs = {}
local BUILD_SUCCEEDED = 1

local function class_portion(main_class)
  return type(main_class) == 'string' and (main_class:match('/(.+)$') or main_class) or nil
end

local function existing_paths(paths, path_usable)
  local result = {}
  for _, path in ipairs(type(paths) == 'table' and paths or {}) do
    if path_usable(path) then result[#result + 1] = path end
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

local function node_field(node, name)
  local fields = node:field(name)
  return fields and fields[1] or nil
end

local function node_text(node, bufnr)
  return node and vim.treesitter.get_node_text(node, bufnr) or nil
end

local function has_modifier(method, modifier)
  for child in method:iter_children() do
    if child:type() == 'modifiers' then
      for item in child:iter_children() do
        if item:type() == modifier then return true end
      end
    end
  end
  return false
end

local function has_string_array_parameter(method, bufnr)
  local parameters = node_field(method, 'parameters')
  if not parameters or parameters:named_child_count() ~= 1 then return false end
  local parameter = parameters:named_child(0)
  if parameter:type() == 'formal_parameter' then
    local parameter_type = node_field(parameter, 'type')
    if not parameter_type then return false end
    local declarator_dimensions
    for child in parameter:iter_children() do
      if child:type() == 'dimensions' then
        declarator_dimensions = node_text(child, bufnr):gsub('%s+', '')
        break
      end
    end
    local type_text = node_text(parameter_type, bufnr):gsub('%s+', '')
    if parameter_type:type() == 'array_type' then
      return declarator_dimensions == nil
        and (type_text == 'String[]' or type_text == 'java.lang.String[]')
    end
    if type_text ~= 'String' and type_text ~= 'java.lang.String' then return false end
    return declarator_dimensions == '[]'
  end
  if parameter:type() == 'spread_parameter' then
    local parameter_type
    for index = 0, parameter:named_child_count() - 1 do
      local candidate = parameter:named_child(index)
      if candidate:type() ~= 'modifiers' and candidate:type() ~= 'variable_declarator' then
        parameter_type = candidate
        break
      end
    end
    if not parameter_type then return false end
    local text = node_text(parameter_type, bufnr):gsub('%s+', '')
    return text == 'String' or text == 'java.lang.String'
  end
  return false
end

local function is_standard_main(method, bufnr, declaration_kind)
  local public_method = has_modifier(method, 'public')
    or (declaration_kind == 'interface_declaration' and not has_modifier(method, 'private'))
  return node_text(node_field(method, 'name'), bufnr) == 'main'
    and node_text(node_field(method, 'type'), bufnr) == 'void'
    and public_method
    and has_modifier(method, 'static')
    and has_string_array_parameter(method, bufnr)
end

local function standard_main_invocation(bufnr, class_name)
  local parser, parser_error = vim.treesitter.get_parser(bufnr, 'java')
  if not parser then return nil, 'Java Tree-sitter parser is unavailable: ' .. tostring(parser_error) end
  local trees = parser:parse()
  local root = trees[1] and trees[1]:root() or nil
  if not root then return nil, 'Java Tree-sitter could not parse the current file' end

  local simple_name = class_name:match('([%w_$]+)$')
  local type_kinds = {
    class_declaration = true,
    enum_declaration = true,
    interface_declaration = true,
    record_declaration = true,
  }
  for index = 0, root:named_child_count() - 1 do
    local declaration = root:named_child(index)
    if type_kinds[declaration:type()] and node_text(node_field(declaration, 'name'), bufnr) == simple_name then
      if not has_modifier(declaration, 'public') then
        return nil, 'the current top-level type must be public for direct JShell access'
      end
      local body = node_field(declaration, 'body')
      if body then
        for body_index = 0, body:named_child_count() - 1 do
          local member = body:named_child(body_index)
          if member:type() == 'method_declaration' and is_standard_main(member, bufnr, declaration:type()) then
            return class_name .. '.main(new String[0]);\n'
          end
        end
      end
    end
  end
  return nil, 'only public static void main(String[]) or main(String...) is supported'
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
    standard_main_invocation = standard_main_invocation,
    get_client = default_client,
    request = function(client, method, params, callback, bufnr)
      return client:request(method, params, callback, bufnr)
    end,
    cancel_request = function(client, request_id) return client:cancel_request(request_id) end,
    start_timeout = function(timeout_ms, callback)
      local timer = vim.defer_fn(callback, timeout_ms)
      return function()
        if timer and not timer:is_closing() then
          timer:stop()
          timer:close()
        end
      end
    end,
    watch_lifecycle = function(bufnr, client_id, callback)
      local autocmd_id = vim.api.nvim_create_autocmd({ 'LspDetach', 'BufWipeout' }, {
        buffer = bufnr,
        callback = function(event)
          if event.event == 'LspDetach' then
            if not event.data or event.data.client_id ~= client_id then return end
            callback('JDTLS detached before the run completed')
          else
            callback('the source buffer closed before the run completed')
          end
        end,
      })
      return function()
        if autocmd_id then
          pcall(vim.api.nvim_del_autocmd, autocmd_id)
          autocmd_id = nil
        end
      end
    end,
    path_usable = function(path)
      local stat = vim.uv.fs_stat(path)
      if not stat or (stat.type ~= 'file' and stat.type ~= 'directory') then return false end
      return vim.uv.fs_access(path, stat.type == 'directory' and 'RX' or 'R') == true
    end,
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
  local pending_requests = {}
  local cancel_lifecycle = function() end
  local cancel_timeout = function() end
  local function finish(message, level)
    if finished then return false end
    finished = true
    active_jshell_runs[bufnr] = nil
    pcall(cancel_lifecycle)
    pcall(cancel_timeout)
    if message then deps.notify('Java JShell: ' .. message, level or vim.log.levels.ERROR) end
    return not message
  end
  local function cancel_pending_requests()
    for request_id in pairs(pending_requests) do
      pcall(deps.cancel_request, client, request_id)
    end
    pending_requests = {}
  end
  local function request(method, params, callback, label)
    if finished then return false end
    local request_id
    local responded = false
    local function guarded_callback(err, result)
      responded = true
      if request_id then pending_requests[request_id] = nil end
      if finished then return end
      local callback_ok, callback_error = pcall(callback, err, result)
      if not callback_ok then
        cancel_pending_requests()
        finish(label .. ' callback failed: ' .. tostring(callback_error))
      end
    end
    local ok, accepted
    ok, accepted, request_id = pcall(deps.request, client, method, params, guarded_callback, bufnr)
    if not ok then return finish(label .. ' failed: ' .. tostring(accepted)) end
    if accepted ~= true then return finish(label .. ' request was rejected by JDTLS') end
    if request_id and not responded then pending_requests[request_id] = true end
    return true
  end

  local lifecycle_started, lifecycle_cancel_or_error = pcall(
    deps.watch_lifecycle,
    bufnr,
    client.id,
    function(message)
      if finished then return end
      cancel_pending_requests()
      finish(message)
    end
  )
  if not lifecycle_started or type(lifecycle_cancel_or_error) ~= 'function' then
    return finish('could not watch the JDTLS lifecycle: ' .. tostring(lifecycle_cancel_or_error))
  end
  cancel_lifecycle = lifecycle_cancel_or_error
  if finished then return false end

  local timeout_ms = options.timeout_ms
  if type(timeout_ms) ~= 'number' or timeout_ms <= 0 then timeout_ms = 120000 end
  local timeout_started, cancel_or_error = pcall(deps.start_timeout, timeout_ms, function()
    if finished then return end
    cancel_pending_requests()
    finish(('timed out after %d ms while waiting for JDTLS'):format(timeout_ms))
  end)
  if not timeout_started or type(cancel_or_error) ~= 'function' then
    return finish('could not start the JDTLS timeout guard: ' .. tostring(cancel_or_error))
  end
  cancel_timeout = cancel_or_error
  if finished then return false end

  local saved, save_error = pcall(deps.save, bufnr)
  if not saved then return finish('could not save the current file: ' .. tostring(save_error)) end
  local resolved, class_name = pcall(deps.resolve_classname, bufnr)
  if not resolved or type(class_name) ~= 'string' or class_name == '' then
    return finish('could not resolve the current class name')
  end
  local invocation_resolved, main_input, invocation_error = pcall(
    deps.standard_main_invocation,
    bufnr,
    class_name
  )
  local main_validation_error
  if not invocation_resolved then
    main_validation_error = 'could not inspect the current main method: ' .. tostring(main_input)
  elseif type(main_input) ~= 'string' or main_input == '' then
    main_validation_error = invocation_error or 'could not build a supported main invocation'
  end
  local buffer_uri
  if not supports_command(client, 'vscode.java.resolveJavaExecutable') then
    local uri_resolved, uri = pcall(deps.buf_uri, bufnr)
    if not uri_resolved or type(uri) ~= 'string' or uri == '' then
      return finish('could not capture the current buffer URI')
    end
    buffer_uri = uri
  end

  local function launch(paths, java_exec)
    local module_paths = existing_paths(paths[1], deps.path_usable)
    local class_paths = existing_paths(paths[2], deps.path_usable)
    if #module_paths == 0 and #class_paths == 0 then
      return finish('JDTLS returned no usable runtime paths')
    end
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
      main_input,
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
      arguments = { buffer_uri, { setting } },
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
      local matches = {}
      for _, main in ipairs(type(main_classes) == 'table' and main_classes or {}) do
        if class_portion(main.mainClass) == class_name then
          matches[#matches + 1] = main
        end
      end
      if #matches == 0 then return finish('the current class has no recognized main(String[]) method') end
      if #matches > 1 then
        return finish(('multiple projects contain %s; use <leader>dM to select a main class'):format(class_name))
      end
      if main_validation_error then return finish(main_validation_error) end
      resolve_paths(matches[1])
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
