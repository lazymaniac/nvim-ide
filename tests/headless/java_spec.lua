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
end)
