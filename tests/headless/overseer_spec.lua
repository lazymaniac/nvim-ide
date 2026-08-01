local h = require 'tests.headless.harness'

local builders_module = 'overseer.template.user.builders'
local docker_module = 'overseer.template.user.docker-compose'
local gradle_module = 'overseer.template.user.gradle-workflow'
local maven_module = 'overseer.template.user.mvn-workflow'

local function reload(module)
  package.loaded[module] = nil
  return require(module)
end

local function assert_command_shape(command)
  h.equal(type(command.cmd), 'string')
  h.equal(type(command.args), 'table')
  h.equal(type(command.env), 'table')
end

h.describe('Overseer workflow builders', function()
  h.it('splits quoted extra arguments without evaluating shell syntax', function()
    local builders = reload(builders_module)

    h.deep_equal(
      builders.split_argv [[-Dmessage="hello world" '; touch /tmp/not-run' plain\ value $(also-not-run)]],
      { '-Dmessage=hello world', '; touch /tmp/not-run', 'plain value', '$(also-not-run)' }
    )
    h.raises('unterminated quote', function()
      builders.split_argv [[-Dmessage="unfinished]]
    end)
  end)

  h.it('builds Maven argv and environment for every boolean branch', function()
    local builders = reload(builders_module)
    local cases = {
      {
        name = 'clean build with skipped tests, profiles, SDK, and hostile-looking values',
        params = {
          pom_file = '/workspace/project with spaces/pom.xml',
          clean = true,
          skip_test = true,
          goals = { 'verify' },
          profiles = { 'fast profile', 'release;touch /tmp/not-run' },
          sdks = '/Java Homes/temurin;still-literal',
          extra_params = [[-Dmessage="hello world" '$(touch /tmp/not-run)']],
        },
        expected = {
          cmd = 'mvn',
          args = {
            '-f',
            '/workspace/project with spaces/pom.xml',
            'clean',
            '-DskipTests',
            'verify',
            '-P',
            'fast profile',
            '-P',
            'release;touch /tmp/not-run',
            '-Dmessage=hello world',
            '$(touch /tmp/not-run)',
          },
          env = { JAVA_HOME = '/Java Homes/temurin;still-literal' },
        },
      },
      {
        name = 'minimal build runs tests and inherits Java',
        params = {
          pom_file = '/workspace/pom.xml',
          clean = false,
          skip_test = false,
          goals = { 'test' },
          profiles = {},
          sdks = '',
          extra_params = {},
        },
        expected = {
          cmd = 'mvn',
          args = { '-f', '/workspace/pom.xml', 'test' },
          env = {},
        },
      },
    }

    for _, case in ipairs(cases) do
      local command = builders.maven(case.params)
      assert_command_shape(command)
      h.deep_equal(command, case.expected, case.name)
    end
  end)

  h.it('checks modern Docker Compose before a checked legacy fallback', function()
    local builders = reload(builders_module)
    local probes = {}
    local modern = builders.resolve_docker_compose(function(argv)
      probes[#probes + 1] = argv
      return argv[1] == 'docker'
    end)

    h.deep_equal(modern, { cmd = 'docker', args = { 'compose' } })
    h.deep_equal(probes, { { 'docker', 'compose', 'version' } })

    probes = {}
    local legacy = builders.resolve_docker_compose(function(argv)
      probes[#probes + 1] = argv
      return argv[1] == 'docker-compose'
    end)

    h.deep_equal(legacy, { cmd = 'docker-compose', args = {} })
    h.deep_equal(probes, {
      { 'docker', 'compose', 'version' },
      { 'docker-compose', 'version' },
    })

    local missing, err = builders.resolve_docker_compose(function()
      return false
    end)
    h.equal(missing, nil)
    h.matches(err, 'Docker Compose executable')
  end)

  h.it('builds Docker argv for up and start without shell concatenation', function()
    local builders = reload(builders_module)
    local cases = {
      {
        name = 'modern detached up',
        command = { cmd = 'docker', args = { 'compose' } },
        params = {
          file = '/workspace/compose files/dev;safe.yml',
          task = 'up',
          detached = true,
          extra_params = [[--project-name "space project" '$(not-run)']],
        },
        expected = {
          cmd = 'docker',
          args = {
            'compose',
            '-f',
            '/workspace/compose files/dev;safe.yml',
            'up',
            '-d',
            '--project-name',
            'space project',
            '$(not-run)',
          },
          env = {},
        },
      },
      {
        name = 'legacy start is already detached',
        command = { cmd = 'docker-compose', args = {} },
        params = { file = '', task = 'start', detached = true, extra_params = {} },
        expected = { cmd = 'docker-compose', args = { 'start' }, env = {} },
      },
      {
        name = 'foreground up omits detached flag',
        command = { cmd = 'docker', args = { 'compose' } },
        params = { task = 'up', detached = false },
        expected = { cmd = 'docker', args = { 'compose', 'up' }, env = {} },
      },
    }

    for _, case in ipairs(cases) do
      local command = builders.docker(case.params, case.command)
      assert_command_shape(command)
      h.deep_equal(command, case.expected, case.name)
    end
  end)

  h.it('builds Gradle argv and parses qualified or hyphenated task names', function()
    local builders = reload(builders_module)
    local command = builders.gradle {
      tasks = { ':app:test-task', 'clean_test' },
      extra_params = [[--project-prop="space value" ';not-run']],
    }

    assert_command_shape(command)
    h.deep_equal(command, {
      cmd = './gradlew',
      args = { ':app:test-task', 'clean_test', '--project-prop=space value', ';not-run' },
      env = {},
    })
    h.deep_equal(
      builders.parse_gradle_tasks {
        'Build tasks',
        ':app:test-task - Runs application tests',
        'clean_test - Cleans generated tests',
        'publish-local - Publishes locally',
        ':app:test-task - Duplicate',
        'not a task heading',
      },
      { ':app:test-task', 'clean_test', 'publish-local' }
    )
  end)
end)

h.describe('Overseer workflow executable validation', function()
  h.it('validates Maven inside its generator instead of an ignored callback condition', function()
    local builders = reload(builders_module)
    local provider = builders.maven_provider {
      has_root_pom = function()
        return true
      end,
      executable = function()
        return 0
      end,
      notify = function() end,
    }
    local callbacks = 0
    local result

    h.equal(provider.condition, nil)
    provider.generator({}, function(value)
      callbacks = callbacks + 1
      result = value
    end)

    h.equal(callbacks, 1)
    h.equal(type(result), 'string')
    h.matches(result, 'Maven executable')
  end)

  h.it('validates Docker Compose once in its provider generator', function()
    local builders = reload(builders_module)
    local probe_calls = 0
    local provider = builders.docker_provider {
      command_succeeds = function(argv)
        probe_calls = probe_calls + 1
        return argv[1] == 'docker'
      end,
    }
    local callbacks = 0
    local result

    h.equal(provider.condition, nil)
    provider.generator({}, function(value)
      callbacks = callbacks + 1
      result = value
    end)
    h.equal(callbacks, 1)
    h.equal(type(result), 'table')
    h.equal(#result, 1)
    h.equal(probe_calls, 1)
    h.deep_equal(result[1].builder { task = 'up', detached = true }, {
      cmd = 'docker',
      args = { 'compose', 'up', '-d' },
      env = {},
    })
    h.equal(probe_calls, 1, 'task building must reuse the validated command')

    local missing = builders.docker_provider {
      command_succeeds = function()
        return false
      end,
    }
    missing.generator({}, function(value)
      callbacks = callbacks + 1
      result = value
    end)
    h.equal(callbacks, 2)
    h.equal(type(result), 'string')
    h.matches(result, 'Docker Compose executable')
  end)

  h.it('loads production workflows through provider factories without test-only APIs', function()
    for _, module in ipairs { maven_module, docker_module, gradle_module } do
      local provider = reload(module)
      h.equal(provider.condition, nil, module .. ' must validate inside its generator')
      h.equal(type(provider.generator), 'function', module .. ' must return a provider')
      h.equal(provider._create, nil, module .. ' must not expose a test-only factory')
    end
  end)
end)

h.describe('Overseer plugin timeout configuration', function()
  h.it('uses current bounded provider timeout and cache option names', function()
    local captured
    local previous_preload = package.preload.overseer
    local previous_loaded = package.loaded.overseer
    package.loaded.overseer = nil
    package.preload.overseer = function()
      return {
        setup = function(options)
          captured = options
        end,
      }
    end

    reload('plugins.async-tasks')[1].config()

    package.loaded.overseer = previous_loaded
    package.preload.overseer = previous_preload
    h.equal(captured.template_timeout_ms, 30000)
    h.equal(captured.template_cache_threshold_ms, 100)
    h.equal(captured.template_timeout, nil)
    h.equal(captured.template_cache_threshold, nil)
  end)
end)

h.describe('Gradle workflow discovery', function()
  package.preload['plenary.path'] = package.preload['plenary.path']
    or function()
      local Path = {}
      function Path:new(value)
        return setmetatable({ value = value }, { __index = self })
      end
      function Path:exists()
        return true
      end
      return Path
    end

  local function scenario(overrides)
    local state = {
      callbacks = 0,
      stopped = {},
      timeout_ms = nil,
      timeout_callback = nil,
      cancel_count = 0,
    }
    local probes = {
      cwd = function()
        return '/workspace'
      end,
      executable = function()
        return 1
      end,
      notify = function() end,
      jobstart = function(argv, options)
        state.argv = argv
        state.job_options = options
        return 41
      end,
      jobstop = function(job_id)
        state.stopped[#state.stopped + 1] = job_id
      end,
      defer = function(timeout_ms, callback)
        state.timeout_ms = timeout_ms
        state.timeout_callback = callback
        return function()
          state.cancel_count = state.cancel_count + 1
        end
      end,
    }
    for key, value in pairs(overrides or {}) do
      probes[key] = value
    end

    local builders = reload(builders_module)
    local provider = builders.gradle_provider(probes, { timeout_ms = 10000 })
    provider.generator({}, function(result)
      state.callbacks = state.callbacks + 1
      state.result = result
    end)
    return state
  end

  h.it('discovers tasks using argv and completes once on success', function()
    local state = scenario()

    h.deep_equal(state.argv, { './gradlew', 'tasks', '--console=plain' })
    h.truthy(
      state.timeout_ms > 0 and state.timeout_ms < 30000,
      'internal timeout must finish before Overseer\'s 30000ms provider timeout'
    )
    state.job_options.on_stdout(nil, {
      ':app:test-task - Runs application tests',
      'publish-local - Publishes locally',
      '',
    })
    state.job_options.on_exit(nil, 0)

    h.equal(state.callbacks, 1)
    h.equal(type(state.result), 'table')
    h.deep_equal(state.result[1].params.tasks.subtype.choices, { ':app:test-task', 'publish-local' })
    h.deep_equal(
      state.result[1].builder {
        tasks = { ':app:test-task' },
        extra_params = { '--info' },
      },
      {
        cmd = './gradlew',
        args = { ':app:test-task', '--info' },
        env = {},
      }
    )

    state.timeout_callback()
    state.job_options.on_exit(nil, 1)
    h.equal(state.callbacks, 1, 'late timeout/exit must not invoke the provider twice')
  end)

  h.it('completes once for every start and process failure branch', function()
    local start_cases = {
      {
        name = 'not executable',
        start = function()
          return 0
        end,
        error = 'not executable',
      },
      {
        name = 'invalid arguments',
        start = function()
          return -1
        end,
        error = 'invalid arguments',
      },
      {
        name = 'jobstart exception',
        start = function()
          error 'jobstart exploded'
        end,
        error = 'jobstart exploded',
      },
    }

    for _, case in ipairs(start_cases) do
      local state = scenario { jobstart = case.start }
      h.equal(state.callbacks, 1, case.name)
      h.equal(type(state.result), 'string', case.name)
      h.matches(state.result, case.error, case.name)
    end

    local state = scenario()
    state.job_options.on_exit(nil, 17)
    h.equal(state.callbacks, 1)
    h.equal(type(state.result), 'string')
    h.matches(state.result, 'exit code 17')
    state.job_options.on_exit(nil, 0)
    h.equal(state.callbacks, 1)
  end)

  h.it('stops a timed-out job and completes once', function()
    local state = scenario()

    state.timeout_callback()
    h.deep_equal(state.stopped, { 41 })
    h.equal(state.callbacks, 1)
    h.equal(type(state.result), 'string')
    h.matches(state.result, 'timed out')

    state.job_options.on_exit(nil, 143)
    state.timeout_callback()
    h.equal(state.callbacks, 1)
  end)
end)

h.describe('Overseer user template collection', function()
  h.it('is a valid empty provider instead of a deprecated module list', function()
    local collection = reload 'overseer.template.user'
    h.falsy(vim.islist(collection))
    h.equal(type(collection.generator), 'function')
    h.equal(collection.condition, nil)
  end)
end)
