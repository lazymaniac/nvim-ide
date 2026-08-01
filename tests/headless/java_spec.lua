local h = require 'tests.headless.harness'

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then return spec end
  end
  error('plugin spec not found: ' .. name)
end

local function load_java()
  package.loaded['nv_ide.java'] = nil
  return require 'nv_ide.java'
end

local function fixture(overrides)
  local state = {
    cancelled_requests = {},
    events = {},
    launches = {},
    lifecycles = {},
    notifications = {},
    requests = {},
    timeouts = {},
  }
  local client = {
    id = 7,
    name = 'jdtls',
    config = { root_dir = '/repo' },
    server_capabilities = {
      executeCommandProvider = {
        commands = {
          'vscode.java.resolveMainClass',
          'vscode.java.resolveClasspath',
          'vscode.java.resolveJavaExecutable',
        },
      },
    },
  }
  state.client = client
  local usable = {
    ['/repo/out'] = true,
    ['/repo/lib/runtime.jar'] = true,
    ['/repo/modules'] = true,
  }
  local deps = {
    buf_is_valid = function(bufnr) return bufnr == 17 end,
    buf_name = function(bufnr)
      h.equal(bufnr, 17)
      return '/repo/src/demo/Current.java'
    end,
    buf_uri = function(bufnr)
      h.equal(bufnr, 17)
      return 'file:///repo/src/demo/Current.java'
    end,
    buf_options = function(bufnr)
      h.equal(bufnr, 17)
      return { buftype = '', filetype = 'java', modifiable = true, readonly = false }
    end,
    save = function(bufnr)
      h.equal(bufnr, 17)
      state.events[#state.events + 1] = 'save'
    end,
    resolve_classname = function(bufnr)
      h.equal(bufnr, 17)
      state.events[#state.events + 1] = 'class'
      return 'demo.Current'
    end,
    standard_main_invocation = function(bufnr, class_name)
      h.equal(bufnr, 17)
      h.equal(class_name, 'demo.Current')
      return 'demo.Current.main(new String[0]);\n'
    end,
    get_client = function(client_id, bufnr)
      h.equal(client_id, 7)
      h.equal(bufnr, 17)
      return client
    end,
    request = function(request_client, method, params, callback, bufnr)
      h.equal(request_client, client)
      h.equal(bufnr, 17)
      state.events[#state.events + 1] = method
      state.requests[#state.requests + 1] = {
        method = method,
        params = vim.deepcopy(params),
        callback = callback,
        bufnr = bufnr,
      }
      return true, #state.requests
    end,
    cancel_request = function(request_client, request_id)
      h.equal(request_client, client)
      state.cancelled_requests[#state.cancelled_requests + 1] = request_id
    end,
    start_timeout = function(timeout_ms, callback)
      local timeout = { timeout_ms = timeout_ms, callback = callback, cancelled = false }
      state.timeouts[#state.timeouts + 1] = timeout
      return function() timeout.cancelled = true end
    end,
    watch_lifecycle = function(bufnr, client_id, callback)
      h.equal(bufnr, 17)
      h.equal(client_id, 7)
      local lifecycle = { callback = callback, cancelled = false }
      state.lifecycles[#state.lifecycles + 1] = lifecycle
      return function() lifecycle.cancelled = true end
    end,
    path_usable = function(path) return usable[path] == true end,
    is_executable = function(path) return path == '/jdk/bin/jshell' end,
    exepath = function() return '' end,
    path_separator = ':',
    open_terminal = function(argv, input, cwd)
      state.launches[#state.launches + 1] = {
        argv = vim.deepcopy(argv),
        input = input,
        cwd = cwd,
      }
      return true
    end,
    notify = function(message, level)
      state.notifications[#state.notifications + 1] = { message = message, level = level }
    end,
  }
  for key, value in pairs(overrides or {}) do deps[key] = value end
  return state, deps
end

local function respond(state, index, err, result)
  local request = assert(state.requests[index], 'request ' .. index .. ' is missing')
  request.callback(err, result)
end

local function syntax_node(kind, text, children, fields, is_named)
  local node = {
    _children = children or {},
    _fields = fields or {},
    _kind = kind,
    _named = is_named ~= false,
    _text = text,
  }
  function node:type() return self._kind end
  function node:named() return self._named end
  function node:field(name) return self._fields[name] or {} end
  function node:iter_children()
    local index = 0
    return function()
      index = index + 1
      return self._children[index]
    end
  end
  function node:named_child_count()
    local count = 0
    for _, child in ipairs(self._children) do
      if child:named() then count = count + 1 end
    end
    return count
  end
  function node:named_child(index)
    for _, child in ipairs(self._children) do
      if child:named() then
        if index == 0 then return child end
        index = index - 1
      end
    end
  end
  return node
end

local function syntax_tree_for(parameter, options)
  options = options or {}
  local public = syntax_node('public', 'public', {}, {}, false)
  local static = syntax_node('static', 'static', {}, {}, false)
  local modifier_children = {}
  if options.method_public ~= false then modifier_children[#modifier_children + 1] = public end
  if options.is_static ~= false then modifier_children[#modifier_children + 1] = static end
  local modifiers = syntax_node('modifiers', 'method modifiers', modifier_children)
  local return_type = syntax_node('void_type', 'void')
  local method_name = syntax_node('identifier', 'main')
  local open = syntax_node('(', '(', {}, {}, false)
  local close = syntax_node(')', ')', {}, {}, false)
  local parameter_children = { open }
  if parameter then parameter_children[#parameter_children + 1] = parameter end
  parameter_children[#parameter_children + 1] = close
  local parameters = syntax_node('formal_parameters', parameter and '(...)' or '()', parameter_children)
  local method = syntax_node(
    'method_declaration',
    'public static void main(...) {}',
    { modifiers, return_type, method_name, parameters },
    { name = { method_name }, parameters = { parameters }, type = { return_type } }
  )
  local body = syntax_node('class_body', '{...}', { method })
  local class_name = syntax_node('identifier', 'Current')
  local type_children = {}
  if options.type_public ~= false then
    local type_public = syntax_node('public', 'public', {}, {}, false)
    type_children[#type_children + 1] = syntax_node('modifiers', 'public', { type_public })
  end
  type_children[#type_children + 1] = class_name
  type_children[#type_children + 1] = body
  local declaration = syntax_node(
    options.declaration_kind or 'class_declaration',
    'class Current {...}',
    type_children,
    { body = { body }, name = { class_name } }
  )
  return syntax_node('program', 'class Current {...}', { declaration })
end

local function with_syntax_tree(root, callback)
  local previous_parser = vim.treesitter.get_parser
  local previous_node_text = vim.treesitter.get_node_text
  vim.treesitter.get_parser = function()
    return {
      parse = function()
        return { { root = function() return root end } }
      end,
    }
  end
  vim.treesitter.get_node_text = function(node) return node._text end

  local ok, err = xpcall(callback, debug.traceback)
  vim.treesitter.get_parser = previous_parser
  vim.treesitter.get_node_text = previous_node_text
  if not ok then error(err, 0) end
end

h.describe('Java current-class JShell runner', function()
  h.it('saves, builds, resolves, and invokes the captured current class', function()
    local java = load_java()
    local state, deps = fixture()

    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
    h.deep_equal(state.events, { 'save', 'class', 'java/buildWorkspace' })
    h.equal(state.requests[1].params, false)

    respond(state, 1, nil, 1)
    h.deep_equal(state.requests[2].params, {
      command = 'vscode.java.resolveMainClass',
    })

    respond(state, 2, nil, {
      { mainClass = 'other.Current', projectName = 'other' },
      { mainClass = 'demo.module/demo.Current', projectName = 'demo' },
    })
    h.deep_equal(state.requests[3].params, {
      command = 'vscode.java.resolveClasspath',
      arguments = { 'demo.module/demo.Current', 'demo' },
    })

    respond(state, 3, nil, {
      { '/repo/modules', '/repo/missing-module' },
      { '/repo/out', '/repo/lib/runtime.jar', '/repo/missing.jar' },
    })
    h.deep_equal(state.requests[4].params, {
      command = 'vscode.java.resolveJavaExecutable',
      arguments = { 'demo.module/demo.Current', 'demo' },
    })

    respond(state, 4, nil, '/jdk/bin/java')
    h.deep_equal(state.launches, {
      {
        argv = {
          '/jdk/bin/jshell',
          '--class-path', '/repo/out:/repo/lib/runtime.jar',
          '--module-path', '/repo/modules',
          '--add-modules', 'ALL-MODULE-PATH',
        },
        input = 'demo.Current.main(new String[0]);\n',
        cwd = '/repo',
      },
    })
    h.equal(#state.notifications, 0)
    h.truthy(state.timeouts[1].cancelled)
  end)

  h.it('rejects invalid buffers before saving or building', function()
    local cases = {
      { label = 'invalid', overrides = { buf_is_valid = function() return false end }, message = 'buffer is invalid' },
      { label = 'unnamed', overrides = { buf_name = function() return '' end }, message = 'named Java source file' },
      {
        label = 'non-Java',
        overrides = { buf_options = function() return { buftype = '', filetype = 'lua', modifiable = true, readonly = false } end },
        message = 'named Java source file',
      },
      {
        label = 'readonly',
        overrides = { buf_options = function() return { buftype = '', filetype = 'java', modifiable = true, readonly = true } end },
        message = 'not writable',
      },
      { label = 'no JDTLS', overrides = { get_client = function() return nil end }, message = 'no JDTLS client' },
    }
    for _, case in ipairs(cases) do
      local java = load_java()
      local state, deps = fixture(case.overrides)
      h.falsy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps }, case.label)
      h.equal(#state.requests, 0, case.label)
      h.equal(#state.launches, 0, case.label)
      h.matches(state.notifications[#state.notifications].message, case.message, case.label)
    end
  end)

  h.it('clears the guard after save, request, and build failures', function()
    local cases = {
      {
        label = 'save',
        overrides = { save = function() error 'disk full' end },
        settle = function() end,
        message = 'could not save',
      },
      {
        label = 'request rejected',
        overrides = { request = function() return false end },
        settle = function() end,
        message = 'request was rejected',
      },
      {
        label = 'build error',
        settle = function(state) respond(state, 1, { message = 'server stopped' }) end,
        message = 'server stopped',
      },
      {
        label = 'build failed',
        settle = function(state) respond(state, 1, nil, 2) end,
        message = '<leader>cc',
      },
    }
    for _, case in ipairs(cases) do
      local java = load_java()
      local state, deps = fixture(case.overrides)
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      case.settle(state)
      h.matches(state.notifications[#state.notifications].message, case.message, case.label)
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      h.falsy(state.notifications[#state.notifications].message:find('already in progress', 1, true), case.label)
    end
  end)

  h.it('blocks only overlapping asynchronous runs', function()
    local java = load_java()
    local state, deps = fixture()
    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
    h.falsy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
    h.equal(#state.requests, 1)
    h.matches(state.notifications[1].message, 'already in progress')
    respond(state, 1, nil, 3)
    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
    h.equal(#state.requests, 2)
  end)

  h.it('times out a stalled request, cancels it, and ignores its late response', function()
    local java = load_java()
    local state, deps = fixture()

    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
    h.equal(state.timeouts[1].timeout_ms, 120000)
    h.falsy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })

    state.timeouts[1].callback()
    h.deep_equal(state.cancelled_requests, { 1 })
    h.matches(state.notifications[2].message, 'timed out')
    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
    h.equal(#state.requests, 2)

    respond(state, 1, nil, 1)
    h.equal(#state.requests, 2)
  end)

  h.it('releases the guard when JDTLS detaches and ignores its late response', function()
    local java = load_java()
    local state, deps = fixture()

    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
    state.lifecycles[1].callback('JDTLS detached before the run completed')
    h.deep_equal(state.cancelled_requests, { 1 })
    h.matches(state.notifications[1].message, 'JDTLS detached')
    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
    h.equal(#state.requests, 2)

    respond(state, 1, nil, 1)
    h.equal(#state.requests, 2)
  end)

  h.it('stops when main, paths, runtime, JShell, or terminal resolution fails', function()
    local function begin(overrides)
      local java = load_java()
      local state, deps = fixture(overrides)
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      respond(state, 1, nil, 1)
      return java, state, deps
    end

    local _, no_main = begin()
    respond(no_main, 2, nil, { { mainClass = 'demo.Other', projectName = 'demo' } })
    h.matches(no_main.notifications[1].message, 'no recognized main(String[])')

    local _, bad_paths = begin()
    respond(bad_paths, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(bad_paths, 3, nil, {})
    h.matches(bad_paths.notifications[1].message, 'invalid classpath response')

    local _, no_java = begin()
    respond(no_java, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(no_java, 3, nil, { {}, { '/repo/out' } })
    respond(no_java, 4, nil, nil)
    h.matches(no_java.notifications[1].message, 'no Java executable')

    local _, no_jshell = begin {
      is_executable = function() return false end,
      exepath = function() return '' end,
    }
    respond(no_jshell, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(no_jshell, 3, nil, { {}, { '/repo/out' } })
    respond(no_jshell, 4, nil, '/jdk/bin/java')
    h.matches(no_jshell.notifications[1].message, 'could not find JShell')

    local _, terminal = begin {
      open_terminal = function() return false, 'terminal job returned -1' end,
    }
    respond(terminal, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(terminal, 3, nil, { {}, { '/repo/out' } })
    respond(terminal, 4, nil, '/jdk/bin/java')
    h.matches(terminal.notifications[1].message, 'terminal job returned -1')
  end)

  h.it('rejects a classpath response with no usable runtime paths', function()
    local java = load_java()
    local state, deps = fixture()
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(state, 3, nil, { { '/repo/missing-module' }, { '/repo/missing.jar' } })
    respond(state, 4, nil, '/jdk/bin/java')

    h.equal(#state.launches, 0)
    h.matches(state.notifications[1].message, 'no usable runtime paths')
  end)

  h.it('rejects ambiguous matching main classes instead of choosing a project arbitrarily', function()
    local java = load_java()
    local state, deps = fixture()
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    respond(state, 2, nil, {
      { mainClass = 'demo.Current', projectName = 'service-a' },
      { mainClass = 'demo.module/demo.Current', projectName = 'service-b' },
    })

    h.equal(#state.requests, 2)
    h.equal(#state.launches, 0)
    h.matches(state.notifications[1].message, 'multiple projects contain demo.Current')
  end)

  h.it('rejects a recognized main signature that JShell cannot invoke directly', function()
    local java = load_java()
    local checks = 0
    local state, deps = fixture {
      standard_main_invocation = function(bufnr, class_name)
        h.equal(bufnr, 17)
        h.equal(class_name, 'demo.Current')
        checks = checks + 1
        return nil, 'only public static void main(String[]) or main(String...) is supported'
      end,
    }

    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })

    h.equal(checks, 1)
    h.equal(#state.requests, 2)
    h.equal(#state.launches, 0)
    h.matches(state.notifications[1].message, 'only public static void main')
  end)

  h.it('validates the Java main parameter type from syntax, not the variable name', function()
    local java = load_java()
    local wrong_type = syntax_node('integral_type', 'int')
    local misleading_name = syntax_node('variable_declarator', 'String')
    local ellipsis = syntax_node('...', '...', {}, {}, false)
    local parameter = syntax_node('spread_parameter', 'int... String', {
      wrong_type,
      ellipsis,
      misleading_name,
    })
    local root = syntax_tree_for(parameter)
    with_syntax_tree(root, function()
      local state, deps = fixture()
      deps.standard_main_invocation = nil
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      respond(state, 1, nil, 1)
      respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })

      h.equal(#state.requests, 2)
      h.matches(state.notifications[1].message, 'only public static void main')
    end)
  end)

  h.it('accepts a conventional String-array main signature from syntax', function()
    local java = load_java()
    local string_type = syntax_node('type_identifier', 'String')
    local dimensions = syntax_node('dimensions', '[]')
    local array_type = syntax_node('array_type', 'String[]', { string_type, dimensions })
    local parameter_name = syntax_node('identifier', 'args')
    local parameter = syntax_node(
      'formal_parameter',
      'String[] args',
      { array_type, parameter_name },
      { name = { parameter_name }, type = { array_type } }
    )

    with_syntax_tree(syntax_tree_for(parameter), function()
      local state, deps = fixture()
      deps.standard_main_invocation = nil
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      respond(state, 1, nil, 1)
      respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })

      h.equal(#state.requests, 3)
      h.equal(#state.notifications, 0)
    end)
  end)

  h.it('accepts Java array dimensions written after the main parameter name', function()
    local java = load_java()
    local string_type = syntax_node('type_identifier', 'String')
    local parameter_name = syntax_node('identifier', 'args')
    local dimensions = syntax_node('dimensions', '[]')
    local parameter = syntax_node(
      'formal_parameter',
      'String args[]',
      { string_type, parameter_name, dimensions },
      { name = { parameter_name }, type = { string_type } }
    )

    with_syntax_tree(syntax_tree_for(parameter), function()
      local state, deps = fixture()
      deps.standard_main_invocation = nil
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      respond(state, 1, nil, 1)
      respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })

      h.equal(#state.requests, 3)
      h.equal(#state.notifications, 0)
    end)
  end)

  h.it('rejects Java flexible no-argument and instance main declarations', function()
    local string_type = syntax_node('type_identifier', 'String')
    local dimensions = syntax_node('dimensions', '[]')
    local array_type = syntax_node('array_type', 'String[]', { string_type, dimensions })
    local parameter_name = syntax_node('identifier', 'args')
    local parameter = syntax_node(
      'formal_parameter',
      'String[] args',
      { array_type, parameter_name },
      { name = { parameter_name }, type = { array_type } }
    )
    local cases = {
      { label = 'no arguments', root = syntax_tree_for(nil) },
      { label = 'instance', root = syntax_tree_for(parameter, { is_static = false }) },
    }

    for _, case in ipairs(cases) do
      local java = load_java()
      with_syntax_tree(case.root, function()
        local state, deps = fixture()
        deps.standard_main_invocation = nil
        java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
        respond(state, 1, nil, 1)
        respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })

        h.equal(#state.requests, 2, case.label)
        h.matches(state.notifications[1].message, 'only public static void main', case.label)
      end)
    end
  end)

  h.it('accepts a final String varargs main parameter', function()
    local java = load_java()
    local final = syntax_node('final', 'final', {}, {}, false)
    local modifiers = syntax_node('modifiers', 'final', { final })
    local string_type = syntax_node('scoped_type_identifier', 'java.lang.String')
    local ellipsis = syntax_node('...', '...', {}, {}, false)
    local parameter_name = syntax_node('variable_declarator', 'args')
    local parameter = syntax_node('spread_parameter', 'final java.lang.String... args', {
      modifiers,
      string_type,
      ellipsis,
      parameter_name,
    })

    with_syntax_tree(syntax_tree_for(parameter), function()
      local state, deps = fixture()
      deps.standard_main_invocation = nil
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      respond(state, 1, nil, 1)
      respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })

      h.equal(#state.requests, 3)
      h.equal(#state.notifications, 0)
    end)
  end)

  h.it('accepts an implicitly public static main on a public interface', function()
    local java = load_java()
    local string_type = syntax_node('type_identifier', 'String')
    local dimensions = syntax_node('dimensions', '[]')
    local array_type = syntax_node('array_type', 'String[]', { string_type, dimensions })
    local parameter_name = syntax_node('identifier', 'args')
    local parameter = syntax_node(
      'formal_parameter',
      'String[] args',
      { array_type, parameter_name },
      { name = { parameter_name }, type = { array_type } }
    )
    local root = syntax_tree_for(parameter, {
      declaration_kind = 'interface_declaration',
      method_public = false,
    })

    with_syntax_tree(root, function()
      local state, deps = fixture()
      deps.standard_main_invocation = nil
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      respond(state, 1, nil, 1)
      respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })

      h.equal(#state.requests, 3)
      h.equal(#state.notifications, 0)
    end)
  end)

  h.it('rejects a package-private top-level class that JShell cannot access', function()
    local java = load_java()
    local string_type = syntax_node('type_identifier', 'String')
    local dimensions = syntax_node('dimensions', '[]')
    local array_type = syntax_node('array_type', 'String[]', { string_type, dimensions })
    local parameter_name = syntax_node('identifier', 'args')
    local parameter = syntax_node(
      'formal_parameter',
      'String[] args',
      { array_type, parameter_name },
      { name = { parameter_name }, type = { array_type } }
    )

    with_syntax_tree(syntax_tree_for(parameter, { type_public = false }), function()
      local state, deps = fixture()
      deps.standard_main_invocation = nil
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      respond(state, 1, nil, 1)
      respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })

      h.equal(#state.requests, 2)
      h.matches(state.notifications[1].message, 'top-level type must be public')
    end)
  end)

  h.it('rejects a two-dimensional String main parameter split across declarators', function()
    local java = load_java()
    local string_type = syntax_node('type_identifier', 'String')
    local type_dimensions = syntax_node('dimensions', '[]')
    local array_type = syntax_node('array_type', 'String[]', { string_type, type_dimensions })
    local parameter_name = syntax_node('identifier', 'args')
    local declarator_dimensions = syntax_node('dimensions', '[]')
    local parameter = syntax_node(
      'formal_parameter',
      'String[] args[]',
      { array_type, parameter_name, declarator_dimensions },
      { name = { parameter_name }, type = { array_type } }
    )

    with_syntax_tree(syntax_tree_for(parameter), function()
      local state, deps = fixture()
      deps.standard_main_invocation = nil
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      respond(state, 1, nil, 1)
      respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })

      h.equal(#state.requests, 2)
      h.matches(state.notifications[1].message, 'only public static void main')
    end)
  end)

  h.it('contains asynchronous callback failures and releases the run guard', function()
    local java = load_java()
    local state, deps = fixture {
      path_usable = function() error 'permission probe exploded' end,
    }
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(state, 3, nil, { {}, { '/repo/out' } })

    local callback_ok, callback_error = pcall(respond, state, 4, nil, '/jdk/bin/java')
    h.truthy(callback_ok, callback_error)
    h.matches(state.notifications[1].message, 'callback failed')
    h.matches(state.notifications[1].message, 'permission probe exploded')
    h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps })
  end)

  h.it('excludes runtime paths that are present but unreadable', function()
    local java = load_java()
    local state, deps = fixture()
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(state, 3, nil, { {}, { '/repo/out', '/repo/lib/unreadable.jar' } })
    respond(state, 4, nil, '/jdk/bin/java')

    h.deep_equal(state.launches[1].argv, {
      '/jdk/bin/jshell', '--class-path', '/repo/out',
    })
  end)

  h.it('uses Windows separators and jshell.exe beside java.exe', function()
    local java = load_java()
    local state, deps = fixture {
      path_separator = ';',
      is_executable = function(path) return path == 'C:/jdk/bin/jshell.exe' end,
    }
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(state, 3, nil, { {}, { '/repo/out', '/repo/lib/runtime.jar' } })
    respond(state, 4, nil, 'C:/jdk/bin/java.exe')
    h.equal(state.launches[1].argv[1], 'C:/jdk/bin/jshell.exe')
    h.equal(state.launches[1].argv[3], '/repo/out;/repo/lib/runtime.jar')
  end)

  h.it('falls back to the configured JDTLS runtime', function()
    local java = load_java()
    local state, deps = fixture()
    state.client.server_capabilities.executeCommandProvider.commands = {
      'vscode.java.resolveMainClass',
      'vscode.java.resolveClasspath',
    }
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(state, 3, nil, { {}, { '/repo/out' } })
    h.deep_equal(state.requests[4].params, {
      command = 'java.project.getSettings',
      arguments = {
        'file:///repo/src/demo/Current.java',
        { 'org.eclipse.jdt.ls.core.vm.location' },
      },
    })
    respond(state, 4, nil, {
      ['org.eclipse.jdt.ls.core.vm.location'] = '/jdk',
    })
    h.equal(state.launches[1].argv[1], '/jdk/bin/jshell')
  end)

  h.it('captures the buffer URI before asynchronous runtime fallback', function()
    local java = load_java()
    local deleted, uri_calls = false, 0
    local state, deps = fixture {
      buf_uri = function()
        uri_calls = uri_calls + 1
        if deleted then error 'buffer was deleted' end
        return 'file:///repo/src/demo/Current.java'
      end,
    }
    state.client.server_capabilities.executeCommandProvider.commands = {
      'vscode.java.resolveMainClass',
      'vscode.java.resolveClasspath',
    }

    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    h.equal(uri_calls, 1)
    deleted = true
    respond(state, 1, nil, 1)
    respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(state, 3, nil, { {}, { '/repo/out' } })
    respond(state, 4, nil, {
      ['org.eclipse.jdt.ls.core.vm.location'] = '/jdk',
    })

    h.equal(uri_calls, 1)
    h.equal(state.launches[1].argv[1], '/jdk/bin/jshell')
  end)

  h.it('starts a bottom terminal with list argv and queues the main call', function()
    local java = load_java()
    local calls = {}
    local state, deps = fixture {
      open_terminal = false,
      cmd = function(command) calls[#calls + 1] = { 'cmd', command } end,
      current_buf = function() return 31 end,
      set_bufhidden = function(bufnr)
        calls[#calls + 1] = { 'bufhidden', bufnr, 'wipe' }
      end,
      jobstart = function(argv, opts)
        calls[#calls + 1] = { 'jobstart', vim.deepcopy(argv), vim.deepcopy(opts) }
        return 23
      end,
      chan_send = function(job, input) calls[#calls + 1] = { 'send', job, input } end,
      startinsert = function() calls[#calls + 1] = { 'startinsert' } end,
    }
    java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
    respond(state, 1, nil, 1)
    respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
    respond(state, 3, nil, { {}, { '/repo/out' } })
    respond(state, 4, nil, '/jdk/bin/java')
    h.deep_equal(calls, {
      { 'cmd', 'botright 12new' },
      { 'bufhidden', 31, 'wipe' },
      { 'jobstart', { '/jdk/bin/jshell', '--class-path', '/repo/out' }, { term = true, cwd = '/repo' } },
      { 'send', 23, 'demo.Current.main(new String[0]);\n' },
      { 'startinsert' },
    })
  end)

  h.it('cleans up terminal start and channel-send failures', function()
    local cases = {
      {
        label = 'start',
        overrides = { jobstart = function() return -1 end },
        expected = { { 'delete', 31 } },
        message = 'failed to start',
      },
      {
        label = 'send',
        overrides = {
          jobstart = function() return 23 end,
          chan_send = function() error 'closed channel' end,
        },
        expected = { { 'stop', 23 }, { 'delete', 31 } },
        message = 'closed channel',
      },
    }
    for _, case in ipairs(cases) do
      local java = load_java()
      local cleanup = {}
      local overrides = vim.tbl_extend('force', {
        open_terminal = false,
        cmd = function() end,
        current_buf = function() return 31 end,
        set_bufhidden = function() end,
        startinsert = function() end,
        jobstop = function(job) cleanup[#cleanup + 1] = { 'stop', job } end,
        buf_delete = function(bufnr) cleanup[#cleanup + 1] = { 'delete', bufnr } end,
      }, case.overrides)
      local state, deps = fixture(overrides)
      java.run_current_class { bufnr = 17, client_id = 7, deps = deps }
      respond(state, 1, nil, 1)
      respond(state, 2, nil, { { mainClass = 'demo.Current', projectName = 'demo' } })
      respond(state, 3, nil, { {}, { '/repo/out' } })
      respond(state, 4, nil, '/jdk/bin/java')
      h.deep_equal(cleanup, case.expected, case.label)
      h.matches(state.notifications[1].message, case.message, case.label)
      h.truthy(java.run_current_class { bufnr = 17, client_id = 7, deps = deps }, case.label)
    end
  end)

  h.it('preserves interactive JShell and maps the current class separately', function()
    local previous = {
      blink = package.loaded['blink.cmp'],
      dap = package.loaded['jdtls.dap'],
      java = package.loaded['nv_ide.java'],
      jdtls = package.loaded.jdtls,
      tests = package.loaded['jdtls.tests'],
      util = package.loaded.util,
      which_key = package.loaded['which-key'],
      create_autocmd = vim.api.nvim_create_autocmd,
      get_client = vim.lsp.get_client_by_id,
      glob = vim.fn.glob,
    }
    local autocmds, mappings, runs = {}, {}, {}
    local function noop() end
    local interactive_jshell = function() end
    local fake_jdtls = setmetatable({
      extendedClientCapabilities = {},
      jshell = interactive_jshell,
    }, { __index = function() return noop end })
    package.loaded.jdtls = fake_jdtls
    package.loaded['jdtls.tests'] = setmetatable({}, { __index = function() return noop end })
    package.loaded['jdtls.dap'] = setmetatable({}, { __index = function() return noop end })
    package.loaded['blink.cmp'] = { get_lsp_capabilities = function() return {} end }
    package.loaded.util = { mason_root = function() return '/mason' end }
    package.loaded['nv_ide.java'] = {
      bundle_patterns = function() return {} end,
      run_current_class = function(options) runs[#runs + 1] = options end,
    }
    package.loaded['which-key'] = {
      add = function(entries)
        for _, entry in ipairs(entries) do mappings[#mappings + 1] = entry end
      end,
    }
    vim.fn.glob = function() return '' end
    vim.api.nvim_create_autocmd = function(event, options)
      autocmds[event] = options.callback
      return 1
    end
    vim.lsp.get_client_by_id = function(client_id)
      h.equal(client_id, 7)
      return { id = client_id, name = 'jdtls' }
    end

    local ok, err = xpcall(function()
      local java = plugin(dofile('lua/plugins/lsp/lang/java.lua'), 'mfussenegger/nvim-jdtls')
      java.config(nil, {
        full_cmd = function() return { 'jdtls' } end,
        root_dir = function() return '/repo' end,
        settings = {},
        dap = {},
      })
      autocmds.LspAttach { buf = 41, data = { client_id = 7 } }

      local interactive, current
      for _, mapping in ipairs(mappings) do
        if mapping[1] == '<leader>cj' then interactive = mapping end
        if mapping[1] == '<leader>cJ' then current = mapping end
      end
      h.truthy(interactive)
      h.equal(interactive[2], interactive_jshell)
      h.truthy(current)
      h.equal(current.mode, 'n')
      h.equal(current.buffer, 41)
      h.equal(current.desc, 'Run Current Class in JShell [cJ]')
      current[2]()
      h.deep_equal(runs, { { bufnr = 41, client_id = 7 } })
    end, debug.traceback)

    package.loaded['blink.cmp'] = previous.blink
    package.loaded['jdtls.dap'] = previous.dap
    package.loaded['nv_ide.java'] = previous.java
    package.loaded.jdtls = previous.jdtls
    package.loaded['jdtls.tests'] = previous.tests
    package.loaded.util = previous.util
    package.loaded['which-key'] = previous.which_key
    vim.api.nvim_create_autocmd = previous.create_autocmd
    vim.lsp.get_client_by_id = previous.get_client
    vim.fn.glob = previous.glob
    if not ok then error(err, 0) end
  end)
end)
