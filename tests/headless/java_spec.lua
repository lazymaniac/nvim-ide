local h = require 'tests.headless.harness'

local function load_java()
  package.loaded['nv_ide.java'] = nil
  return require 'nv_ide.java'
end

local function fixture(overrides)
  local state = {
    events = {},
    launches = {},
    notifications = {},
    requests = {},
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
  local readable = {
    ['/repo/out'] = { type = 'directory' },
    ['/repo/lib/runtime.jar'] = { type = 'file' },
    ['/repo/modules'] = { type = 'directory' },
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
    fs_stat = function(path) return readable[path] end,
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
end)
