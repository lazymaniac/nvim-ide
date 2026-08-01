local h = require('tests.headless.harness')

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then return spec end
  end
  error('plugin spec not found: ' .. name)
end

local function dependency(spec, name)
  for _, candidate in ipairs(spec.dependencies or {}) do
    if type(candidate) == 'table' and candidate[1] == name then return candidate end
    if candidate == name then return candidate end
  end
end

h.describe('DAP ownership and lazy loading', function()
  h.it('loads the debug chain from commands and keys instead of LspAttach', function()
    local specs = dofile 'lua/plugins/dap.lua'
    local dap = plugin(specs, 'mfussenegger/nvim-dap')
    h.falsy(dap.event == 'LspAttach', 'ordinary LSP attachment must not load DAP')
    h.truthy(dap.cmd and #dap.cmd > 0, 'DAP commands must trigger the plugin')
    h.truthy(dap.keys and #dap.keys > 0, 'DAP keys must trigger the plugin')

    local persistent = plugin(specs, 'Weissle/persistent-breakpoints.nvim')
    h.falsy(persistent.lazy == false, 'persistent breakpoints must not load eagerly')
    h.truthy(persistent.keys and #persistent.keys > 0)

    local exceptions = plugin(specs, 'lucaSartore/nvim-dap-exception-breakpoints')
    h.falsy(exceptions.event == 'LspAttach')
    h.truthy(exceptions.keys and #exceptions.keys > 0)
  end)

  h.it('leaves Mason DAP installation to the toolchain owner', function()
    local dap = plugin(dofile('lua/plugins/dap.lua'), 'mfussenegger/nvim-dap')
    local mason = dependency(dap, 'jay-babu/mason-nvim-dap.nvim')
    h.truthy(type(mason) == 'table', 'mason-nvim-dap must be a real dependency spec')
    h.falsy(mason.event == 'LspAttach')
    h.falsy(mason.opts.automatic_installation)
    h.deep_equal(mason.opts.ensure_installed or {}, {})
  end)

  h.it('lets Mason DAP own only the otherwise-unowned Bash adapter', function()
    local dap = plugin(dofile('lua/plugins/dap.lua'), 'mfussenegger/nvim-dap')
    local mason = dependency(dap, 'jay-babu/mason-nvim-dap.nvim')
    local handlers = mason.opts.handlers
    h.truthy(type(handlers[1]) == 'function', 'Mason DAP needs an explicit default skip handler')

    local configured = {}
    local previous = package.loaded['mason-nvim-dap']
    package.loaded['mason-nvim-dap'] = {
      default_setup = function(config)
        configured[#configured + 1] = config.name
      end,
    }
    local ok, err = xpcall(function()
      for _, name in ipairs { 'codelldb', 'python', 'delve', 'js', 'kotlin', 'javadbg', 'javatest', 'haskell', 'bash' } do
        (handlers[name] or handlers[1]) { name = name }
      end
    end, debug.traceback)
    package.loaded['mason-nvim-dap'] = previous
    if not ok then error(err, 0) end

    h.deep_equal(configured, { 'bash' })
  end)

  h.it('gives Python and Ruby adapters their own filetype plugin specs', function()
    local python = plugin(dofile('lua/plugins/lsp/lang/python.lua'), 'mfussenegger/nvim-dap-python')
    h.truthy(python.config)
    h.truthy(python.keys and #python.keys == 2)
    h.truthy(vim.tbl_contains(python.ft or {}, 'python'))
    h.truthy(dependency(python, 'mfussenegger/nvim-dap'))

    local configured_python
    local previous_dap_python = package.loaded['dap-python']
    local previous_resolver = package.loaded['util.dap']
    package.loaded['dap-python'] = {
      setup = function(path) configured_python = path end,
    }
    package.loaded['util.dap'] = {
      resolve_python = function() return '/selected/bin/python' end,
    }
    local ok, err = xpcall(python.config, debug.traceback)
    package.loaded['dap-python'] = previous_dap_python
    package.loaded['util.dap'] = previous_resolver
    if not ok then error(err, 0) end
    h.equal(configured_python, '/selected/bin/python')

    local ruby = plugin(dofile('lua/plugins/lsp/lang/ruby.lua'), 'suketa/nvim-dap-ruby')
    h.truthy(ruby.config)
    h.truthy(vim.tbl_contains(ruby.ft or {}, 'ruby'))
    h.truthy(dependency(ruby, 'mfussenegger/nvim-dap'))
  end)

  h.it('keeps DAP-Go outside non-Go debug triggers', function()
    local main = plugin(dofile('lua/plugins/dap.lua'), 'mfussenegger/nvim-dap')
    h.falsy(dependency(main, 'leoluz/nvim-dap-go'), 'the main DAP trigger must not load DAP-Go')

    local go = plugin(dofile('lua/plugins/lsp/lang/go.lua'), 'leoluz/nvim-dap-go')
    h.truthy(dependency(go, 'mfussenegger/nvim-dap'))
    h.equal(#(go.keys or {}), 1)
    h.equal(go.keys[1][1], '<leader>td')
    h.equal(go.keys[1].ft, 'go')
  end)

  h.it('resolves an absolute executable Python in deterministic priority order', function()
    package.loaded['util.dap'] = nil
    local resolver = require 'util.dap'
    local selected = '/selected/bin/python'
    local virtual = '/virtual/bin/python'
    local project = '/workspace/.venv/bin/python'
    local system = '/usr/local/bin/python3'

    local function resolve(executable, selected_value, env)
      return resolver.resolve_python {
        selected = function() return selected_value end,
        env = env or { VIRTUAL_ENV = '/virtual' },
        cwd = function() return '/workspace' end,
        executable = function(path) return executable[path] == true end,
        exepath = function(command)
          return command == 'python3' and system or '/usr/bin/python'
        end,
      }
    end

    h.equal(resolve({ [selected] = true, [virtual] = true, [project] = true, [system] = true }, selected), selected)
    h.equal(resolve({ [virtual] = true, [project] = true, [system] = true }, nil), virtual)
    h.equal(resolve({ [virtual] = true, [project] = true, [system] = true }, selected), virtual)
    h.equal(resolve({ [project] = true, [system] = true }, nil, {}), project)
    h.equal(resolve({ [system] = true }, nil, {}), system)
    h.raises('No executable Python interpreter', function()
      resolve({}, nil, {})
    end)
  end)

  h.it('roots default Python resolution at the active buffer project', function()
    h.with_temp_dir(function(tmp)
      local source = vim.fs.joinpath(tmp, 'src', 'example.py')
      local python = vim.fs.joinpath(tmp, '.venv', 'bin', 'python')
      vim.fn.mkdir(vim.fs.dirname(source), 'p')
      vim.fn.mkdir(vim.fs.dirname(python), 'p')
      vim.fn.writefile({ '[project]' }, vim.fs.joinpath(tmp, 'pyproject.toml'))
      vim.fn.writefile({ 'print("ok")' }, source)
      vim.fn.writefile({}, python)
      local canonical_python = assert(vim.uv.fs_realpath(python))
      local previous_buffer = vim.api.nvim_get_current_buf()
      local previous_resolver = package.loaded['util.dap']
      local bufnr = vim.fn.bufadd(source)
      vim.fn.bufload(bufnr)
      vim.api.nvim_set_current_buf(bufnr)

      package.loaded['util.dap'] = nil
      local ok, result = xpcall(function()
        return require('util.dap').resolve_python {
          selected = function() return nil end,
          env = {},
          executable = function(path) return path == canonical_python end,
          exepath = function() return '' end,
        }
      end, debug.traceback)

      vim.api.nvim_set_current_buf(previous_buffer)
      vim.api.nvim_buf_delete(bufnr, { force = true })
      package.loaded['util.dap'] = previous_resolver
      if not ok then error(result, 0) end
      h.equal(result, canonical_python)
    end)
  end)

  h.it('consumes each language adapter setup hook exactly once', function()
    local main = plugin(dofile('lua/plugins/dap.lua'), 'mfussenegger/nvim-dap')
    local kotlin_fragment = plugin(dofile('lua/plugins/lsp/lang/kotlin.lua'), 'mfussenegger/nvim-dap')
    local calls = 0
    local opts = {
      setup = {
        kotlin_debug_adapter = function()
          calls = calls + 1
        end,
      },
    }
    h.truthy(kotlin_fragment.opts.setup.kotlin_debug_adapter)

    local previous_dap = package.loaded.dap
    local previous_view = package.loaded['dap-view']
    local previous_config = package.loaded.config
    package.loaded.dap = {
      configurations = {},
      listeners = {
        before = {
          attach = {},
          launch = {},
          event_terminated = {},
          event_exited = {},
        },
      },
    }
    package.loaded['dap-view'] = { open = function() end, close = function() end }
    package.loaded.config = { icons = { dap = {} } }

    local ok, err = xpcall(function()
      main.config(nil, opts)
    end, debug.traceback)
    package.loaded.dap = previous_dap
    package.loaded['dap-view'] = previous_view
    package.loaded.config = previous_config
    if not ok then error(err, 0) end

    h.equal(calls, 1)
  end)

  h.it('configures the explicitly owned Kotlin adapter and launch configurations', function()
    local kotlin = plugin(dofile('lua/plugins/lsp/lang/kotlin.lua'), 'mfussenegger/nvim-dap')
    local previous = package.loaded.dap
    local dap = { adapters = {}, configurations = {} }
    package.loaded.dap = dap
    local ok, err = xpcall(kotlin.opts.setup.kotlin_debug_adapter, debug.traceback)
    package.loaded.dap = previous
    if not ok then error(err, 0) end

    h.equal(dap.adapters.kotlin.type, 'executable')
    h.equal(dap.adapters.kotlin.command, 'kotlin-debug-adapter')
    h.truthy(#dap.configurations.kotlin == 2)
  end)

  h.it('renders DAP status without triggering its loader', function()
    local previous_loaded = package.loaded.dap
    local previous_preload = package.preload.dap
    local loads, status_calls = 0, 0
    package.loaded.dap = nil
    package.preload.dap = function()
      loads = loads + 1
      return { status = function() return 'unexpected' end }
    end

    local ok, err = xpcall(function()
      local render = dofile('lua/chadrc.lua').ui.statusline.modules.dap
      local rendered = render()
      h.equal(loads, 0, 'statusline rendering loaded nvim-dap')
      h.equal(rendered, nil)

      package.loaded.dap = {
        status = function()
          status_calls = status_calls + 1
          return 'running'
        end,
      }
      h.equal(render(), '   running ')
      h.equal(status_calls, 1)
    end, debug.traceback)

    package.loaded.dap = previous_loaded
    package.preload.dap = previous_preload
    if not ok then error(err, 0) end
  end)

  h.it('resolves Neotest Python and Jest from the test project', function()
    local neotest = plugin(dofile('lua/plugins/tests.lua'), 'nvim-neotest/neotest')
    local opts = neotest.opts()
    local previous_dap = package.loaded['util.dap']
    local previous_project = package.loaded['nv_ide.project']
    local python_root
    package.loaded['util.dap'] = {
      resolve_python = function(options)
        python_root = options.cwd
        return '/repo/.venv/bin/python'
      end,
    }
    package.loaded['nv_ide.project'] = {
      javascript = function(path)
        if path == '/repo/packages/web/src/example.test.ts' then
          return {
            root = '/repo/packages/web',
            configs = { jest = '/repo/packages/web/jest.config.ts' },
            executables = { jest = '/repo/packages/web/node_modules/.bin/jest' },
          }
        end
        h.equal(path, '/repo/web/src/fallback.test.js')
        return { root = '/repo/web', configs = {}, executables = {} }
      end,
    }

    local ok, err = xpcall(function()
      local python = opts.adapters['neotest-python']
      h.equal(python.python('/repo'), '/repo/.venv/bin/python')
      h.equal(python_root, '/repo')
      local jest = opts.adapters['neotest-jest']
      local path = '/repo/packages/web/src/example.test.ts'
      h.equal(jest.jestCommand(path), '/repo/packages/web/node_modules/.bin/jest')
      h.equal(jest.jestConfigFile(path), '/repo/packages/web/jest.config.ts')
      h.equal(jest.cwd(path), '/repo/packages/web')

      local fallback = '/repo/web/src/fallback.test.js'
      h.equal(jest.jestCommand(fallback), 'jest')
      h.equal(jest.jestConfigFile(fallback), '')
      h.equal(jest.cwd(fallback), '/repo/web')
    end, debug.traceback)

    package.loaded['util.dap'] = previous_dap
    package.loaded['nv_ide.project'] = previous_project
    if not ok then error(err, 0) end
  end)

  h.it('resolves Kotlin project and attach inputs when a session launches', function()
    local kotlin = plugin(dofile('lua/plugins/lsp/lang/kotlin.lua'), 'mfussenegger/nvim-dap')
    local previous_dap = package.loaded.dap
    local previous_project = package.loaded['nv_ide.project']
    local previous_input = vim.fn.input
    local dap = { adapters = {}, configurations = {} }
    local root_calls, input_calls = {}, {}
    package.loaded.dap = dap
    package.loaded['nv_ide.project'] = {
      root = function(target, markers)
        root_calls[#root_calls + 1] = { target = target, markers = markers }
        return '/repo/service'
      end,
    }
    vim.fn.input = function(prompt, default)
      input_calls[#input_calls + 1] = { prompt = prompt, default = default }
      return default
    end

    local ok, err = xpcall(function()
      kotlin.opts.setup.kotlin_debug_adapter()
      local launch, attach = unpack(dap.configurations.kotlin)
      h.equal(type(launch.projectRoot), 'function')
      h.equal(type(attach.projectRoot), 'function')
      h.equal(launch.projectRoot(), '/repo/service')
      h.equal(attach.projectRoot(), '/repo/service')
      h.equal(attach.hostName(), 'localhost')
      h.equal(attach.port(), 5005)
      h.equal(#root_calls, 2)
      for _, call in ipairs(root_calls) do
        h.equal(call.target, 0)
        h.truthy(vim.tbl_contains(call.markers, 'settings.gradle.kts'))
        h.truthy(vim.tbl_contains(call.markers, 'gradlew'))
        h.truthy(vim.tbl_contains(call.markers, 'mvnw'))
      end
      h.deep_equal(input_calls, {
        { prompt = 'Kotlin debug host: ', default = 'localhost' },
        { prompt = 'Kotlin debug port: ', default = '5005' },
      })

      vim.fn.input = function(prompt)
        return prompt:find('host', 1, true) and 'debug.example' or '6006'
      end
      h.equal(attach.hostName(), 'debug.example')
      h.equal(attach.port(), 6006)
    end, debug.traceback)

    package.loaded.dap = previous_dap
    package.loaded['nv_ide.project'] = previous_project
    vim.fn.input = previous_input
    if not ok then error(err, 0) end
  end)

  h.it('aggregates JavaScript debug configs once from the active project', function()
    local previous_dap = package.loaded.dap
    local previous_vscode = package.loaded['dap.ext.vscode']
    local previous_utils = package.loaded['dap.utils']
    local previous_project = package.loaded['nv_ide.project']
    local previous_util = package.loaded.util
    local queried = {}
    local vscode = {
      type_to_filetypes = {},
      getconfigs = function(path)
        queried[#queried + 1] = path
        if path == '/unrelated/.vscode/launch.json' then
          return { { type = 'pwa-node', request = 'launch', name = 'Unrelated' } }
        end
        h.equal(path, '/repo/web/.vscode/launch.json')
        return {
          { type = 'pwa-node', request = 'launch', name = 'Workspace launch' },
          { type = 'python', request = 'launch', name = 'Wrong adapter' },
        }
      end,
    }
    local dap = { adapters = {}, configurations = {}, providers = { configs = {} } }
    dap.providers.configs['dap.global'] = function(bufnr)
      return dap.configurations[vim.bo[bufnr].filetype] or {}
    end
    dap.providers.configs['dap.launch.json'] = function()
      return vscode.getconfigs '/unrelated/.vscode/launch.json'
    end
    package.loaded.dap = dap
    package.loaded['dap.ext.vscode'] = vscode
    package.loaded['dap.utils'] = { pick_process = function() return 17 end }
    package.loaded['nv_ide.project'] = {
      javascript = function()
        return {
          root = '/repo/web',
          launch_json = '/repo/web/.vscode/launch.json',
          package_manager = 'pnpm',
          executables = { jest = '/repo/web/node_modules/.bin/jest' },
          configs = {
            jest = '/repo/web/jest.config.ts',
            mocha = '/repo/web/.mocharc.json',
            karma = '/repo/web/karma.conf.ts',
            jasmine = '/repo/web/spec/support/jasmine.json',
          },
        }
      end,
    }
    package.loaded.util = {
      get_pkg_path = function(package, path)
        h.equal(package, 'js-debug-adapter')
        h.equal(path, 'js-debug/src/dapDebugServer.js')
        return '/mason/js-debug/src/dapDebugServer.js'
      end,
      lsp = {
        action = setmetatable({}, { __index = function() return function() end end }),
        execute = function() end,
        get_clients = function() return {} end,
        on_attach = function() end,
      },
    }

    local jsbuf = vim.api.nvim_create_buf(false, true)
    local luabuf = vim.api.nvim_create_buf(false, true)
    vim.bo[jsbuf].filetype = 'typescript'
    vim.bo[luabuf].filetype = 'lua'
    local ok, err = xpcall(function()
      local typescript = plugin(dofile('lua/plugins/lsp/lang/typescript.lua'), 'mfussenegger/nvim-dap')
      typescript.opts()
      for _, filetype in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue' } do
        h.equal(#dap.configurations[filetype], 2)
      end

      local aggregated = {}
      for _, provider in pairs(dap.providers.configs) do
        vim.list_extend(aggregated, provider(jsbuf))
      end
      local by_name = {}
      for _, config in ipairs(aggregated) do
        by_name[config.name] = (by_name[config.name] or 0) + 1
      end
      h.equal(by_name['Workspace launch'], 1)
      h.falsy(by_name['Wrong adapter'])
      h.falsy(by_name.Unrelated)
      h.equal(by_name['Jest Current File'], 1)
      h.equal(by_name['Mocha Current File'], 1)
      h.equal(by_name['Karma All Tests'], 1)
      h.equal(by_name['Jasmine Current File'], 1)
      h.deep_equal(queried, { '/repo/web/.vscode/launch.json' })

      local frameworks = dap.providers.configs.nv_ide_javascript(jsbuf)
      local framework_by_name = {}
      for _, config in ipairs(frameworks) do framework_by_name[config.name] = config end
      h.equal(framework_by_name['Jest Current File'].program, '/repo/web/node_modules/.bin/jest')
      h.equal(framework_by_name['Mocha Current File'].runtimeExecutable, 'pnpm')
      h.deep_equal(framework_by_name['Mocha Current File'].runtimeArgs, { 'exec', 'mocha' })

      h.deep_equal(dap.providers.configs['dap.launch.json'](luabuf), {
        { type = 'pwa-node', request = 'launch', name = 'Unrelated' },
      })
    end, debug.traceback)

    vim.api.nvim_buf_delete(jsbuf, { force = true })
    vim.api.nvim_buf_delete(luabuf, { force = true })
    package.loaded.dap = previous_dap
    package.loaded['dap.ext.vscode'] = previous_vscode
    package.loaded['dap.utils'] = previous_utils
    package.loaded['nv_ide.project'] = previous_project
    package.loaded.util = previous_util
    if not ok then error(err, 0) end
  end)
end)
