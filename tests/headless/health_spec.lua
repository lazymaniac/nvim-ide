local h = require 'tests.headless.harness'

local SENTINELS = {
  ANTHROPIC_API_KEY = 'anthropic-super-secret-sentinel',
  OPENAI_API_KEY = 'openai-super-secret-sentinel',
}

local function find(records, id)
  for _, record in ipairs(records or {}) do
    if record.id == id then
      return record
    end
  end
end

local function ids(records)
  local result = {}
  for _, record in ipairs(records or {}) do
    result[#result + 1] = record.id
  end
  table.sort(result)
  return result
end

local function complete_probe(options)
  options = options or {}
  local manifest = require 'nv_ide.toolchain.manifest'
  local calls = {
    executable = {},
    mason = {},
    parser = {},
    backend = {},
    credential = {},
    version = {},
    capability = {},
  }
  local unavailable = options.unavailable or {}
  local probe = {
    manifest = manifest,
    system = function()
      return { os = options.os or 'Linux', arch = options.arch or 'x86_64', nvim = options.nvim or '0.12.4' }
    end,
    executable = function(name)
      calls.executable[name] = (calls.executable[name] or 0) + 1
      return unavailable[name] ~= true
    end,
    version = function(id, constraint)
      calls.version[id] = (calls.version[id] or 0) + 1
      local versions = options.versions or {}
      local version = versions[id]
        or id == 'go' and '1.26.0'
        or id == 'javascript' and '24.15.0'
        or id == 'python' and '3.13.11'
        or id == 'java' and '21.0.8'
        or id == 'ruby' and '3.4.5'
      return {
        version = version,
        supported = not (options.unsupported_versions or {})[id],
      }
    end,
    capability = function(id, capability)
      local key = id .. ':' .. capability.id
      calls.capability[key] = (calls.capability[key] or 0) + 1
      local version = (options.versions or {})[key]
      local supported = capability.kind ~= 'command_version' or not (options.unsupported_versions or {})[key]
      return {
        available = unavailable[key] ~= true and supported,
        version = version,
        supported = supported,
      }
    end,
    mason_status = function(name)
      calls.mason[name] = (calls.mason[name] or 0) + 1
      if name == manifest.mason.packages[1] then
        return { status = 'failed' }
      elseif name == manifest.mason.packages[2] then
        return { status = 'installing' }
      end
      return { status = 'installed', version = '1.2.3' }
    end,
    parser_status = function(name)
      calls.parser[name] = (calls.parser[name] or 0) + 1
      if name == manifest.treesitter.parsers[1] then
        return { status = 'missing' }
      end
      return { status = 'installed', revision = 'parser-revision-' .. name }
    end,
    treesitter_cli_version = function()
      return options.treesitter_cli_version or '0.26.3'
    end,
    toolchain_state = function()
      return {
        plugin_update = {
          status = 'success',
          observed = {
            before = { mason_receipts = { stylua = '1.0.0' }, treesitter_parser_info = { lua = 'before-rev' } },
            after = { mason_receipts = { stylua = '1.1.0' }, treesitter_parser_info = { lua = 'after-rev' } },
          },
          rollback = {
            lazy = 'exact',
            mason = 'not-guaranteed',
            treesitter = 'not-guaranteed',
            limitation = 'Only Lazy rollback is exact; Mason and parser exact downgrades are not guaranteed',
          },
        },
      }
    end,
    watcher = function()
      return {
        supported = true,
        backend = 'fs_event',
        inotify = {
          max_user_watches = 524288,
          max_user_instances = 128,
          sufficient = true,
        },
      }
    end,
    clipboard = options.clipboard or function()
      return {
        session = 'ssh',
        provider = 'OSC 52',
        available = true,
        tmux = { active = true, passthrough = false, set_clipboard = 'off', ms = false },
        local_providers = { pbcopy = false, wl_copy = true, xclip = false, xsel = false },
      }
    end,
    backend_available = function(backend)
      calls.backend[backend.id] = (calls.backend[backend.id] or 0) + 1
      return backend.id == 'ollama' and unavailable[backend.executable] ~= true
    end,
    credential = function(name)
      calls.credential[name] = (calls.credential[name] or 0) + 1
      return SENTINELS[name]
    end,
  }
  return probe, calls
end

h.describe('nv_ide health collection', function()
  h.it('keeps every required bootstrap and picker prerequisite in the manifest', function()
    local manifest = require 'nv_ide.toolchain.manifest'
    local by_id = {}
    for _, record in ipairs(manifest.prerequisites) do
      by_id[record.id] = record
    end
    for _, id in ipairs {
      'archive',
      'bash',
      'c_compiler',
      'curl',
      'git',
      'gzip',
      'lua_package_manager',
      'ripgrep',
      'ruby_package_manager',
      'tree_sitter_cli',
    } do
      h.truthy(by_id[id], 'missing manifest prerequisite: ' .. id)
      h.truthy(by_id[id].required, id .. ' must be classified as required')
    end
    h.deep_equal(by_id.archive.executables, { 'tar', 'unzip' })
    h.deep_equal(by_id.bash.executables, { 'bash' })
    h.deep_equal(by_id.gzip.executables, { 'gzip' })
    h.deep_equal(by_id.lua_package_manager.executables, { 'luarocks' })
    h.deep_equal(by_id.ripgrep.executables, { 'rg' })
    h.deep_equal(by_id.ruby_package_manager.executables, { 'gem' })
    h.deep_equal(by_id.tree_sitter_cli.executables, { 'tree-sitter' })
  end)

  h.it('requires installer-compatible Go, Node, and Python runtimes plus Python venv support', function()
    local health = require 'nv_ide.health'
    local probe, calls = complete_probe {
      versions = { go = '1.25.9', javascript = '24.14.0', python = '3.14.0' },
      unsupported_versions = { go = true, javascript = true, python = true },
      unavailable = { ['python:venv'] = true },
    }
    local report = health.collect(probe)
    local go = find(report.runtimes, 'go')
    local javascript = find(report.runtimes, 'javascript')
    local python = find(report.runtimes, 'python')

    h.falsy(go.available)
    h.equal(go.version, '1.25.9')
    h.equal(go.minimum_version, '1.26.0')
    h.falsy(go.version_supported)
    h.falsy(javascript.available)
    h.equal(javascript.minimum_version, '24.15.0')
    h.falsy(python.available)
    h.equal(python.minimum_version, '3.10.0')
    h.equal(python.maximum_version_exclusive, '3.14.0')
    h.falsy(python.capabilities[1].available)
    h.equal(python.capabilities[1].id, 'venv')
    h.equal(calls.version.go, 1)
    h.equal(calls.version.javascript, 1)
    h.equal(calls.version.python, 1)
    h.equal(calls.capability['python:venv'], 1)

    h.truthy(health.version_supported('3.10.0', '3.10.0', '3.14.0'))
    h.truthy(health.version_supported('3.13.11', '3.10.0', '3.14.0'))
    h.falsy(health.version_supported('3.9.20', '3.10.0', '3.14.0'))
    h.falsy(health.version_supported('3.14.0', '3.10.0', '3.14.0'))
    h.falsy(health.version_supported('not-a-version', '3.10.0', '3.14.0'))
  end)

  h.it('probes Python venv by creating and cleaning a temporary environment', function()
    local health = require 'nv_ide.health'
    local commands, deleted = {}, {}
    local available = health.python_venv_capability('python3', {
      tempname = function()
        return '/tmp/nv-ide-health-python-venv'
      end,
      run = function(command, timeout_ms)
        commands[#commands + 1] = command
        h.equal(timeout_ms, 30000)
        return { code = 0 }
      end,
      delete = function(path)
        deleted[#deleted + 1] = path
        return 0
      end,
    })
    h.truthy(available)
    h.deep_equal(commands, { { 'python3', '-m', 'venv', '/tmp/nv-ide-health-python-venv' } })
    h.deep_equal(deleted, { '/tmp/nv-ide-health-python-venv' })
  end)

  h.it('requires Java and javac 21 plus Ruby 3 for current Mason packages', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe {
      versions = { java = '20.0.2', ['java:javac_version'] = '20.0.2', ruby = '2.7.8' },
      unsupported_versions = { java = true, ['java:javac_version'] = true, ruby = true },
    }
    local report = health.collect(probe)
    local java = find(report.runtimes, 'java')
    local ruby = find(report.runtimes, 'ruby')
    h.falsy(java.available)
    h.equal(java.minimum_version, '21.0.0')
    h.equal(java.version, '20.0.2')
    h.equal(java.capabilities[1].id, 'javac_version')
    h.equal(java.capabilities[1].version, '20.0.2')
    h.falsy(java.capabilities[1].supported)
    h.falsy(ruby.available)
    h.equal(ruby.minimum_version, '3.0.0')

    local messages, reporter = {}, {}
    for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
      reporter[level] = function(message)
        messages[#messages + 1] = tostring(message)
      end
    end
    health.check(probe, reporter)
    local output = table.concat(messages, '\n')
    h.matches(output, 'Java 20.0.2 requires >= 21.0.0')
    h.matches(output, 'javac 20.0.2 requires >= 21.0.0')
    h.matches(output, 'Ruby 2.7.8 requires >= 3.0.0')
  end)

  h.it('parses Java versions emitted exclusively on stderr', function()
    local health = require 'nv_ide.health'
    local status = health.command_version_status({
      command = { 'java', '-version' },
      pattern = 'version%s+"?(%d+%.%d+%.%d+)',
      minimum = '21.0.0',
    }, function(command, timeout_ms)
      h.deep_equal(command, { 'java', '-version' })
      h.equal(timeout_ms, 3000)
      return { code = 0, stdout = '', stderr = 'openjdk version "21.0.8" 2026-07-15' }
    end)
    h.deep_equal(status, { version = '21.0.8', supported = true })
  end)

  h.it('reports Neovim older than 0.12 as an unsupported required runtime', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe { nvim = '0.11.4' }
    local messages, reporter = {}, {}
    for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
      reporter[level] = function(message)
        messages[#messages + 1] = { level = level, message = tostring(message) }
      end
    end
    local report = health.check(probe, reporter)
    h.falsy(report.system.nvim_supported)
    local output = vim.inspect(messages)
    h.matches(output, 'NV-IDE requires Neovim >= 0.12.0')
    h.matches(output, 'https://neovim.io/doc/install/')
  end)

  h.it('requires Rosetta translation only for Mason hlint on Darwin arm64', function()
    local health = require 'nv_ide.health'
    local linux = health.collect((complete_probe { os = 'Linux', arch = 'x86_64', unavailable = { arch = true } }))
    local linux_rosetta = find(linux.prerequisites, 'mason_hlint_rosetta')
    h.falsy(linux_rosetta.applicable)
    h.truthy(linux_rosetta.available)
    h.falsy(linux_rosetta.required)

    local probe = complete_probe {
      os = 'Darwin',
      arch = 'arm64',
      unavailable = { ['mason_hlint_rosetta:x86_64_translation'] = true },
    }
    local report = health.collect(probe)
    local rosetta = find(report.prerequisites, 'mason_hlint_rosetta')
    h.truthy(rosetta.applicable)
    h.truthy(rosetta.required)
    h.falsy(rosetta.available)

    local messages, reporter = {}, {}
    for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
      reporter[level] = function(message)
        messages[#messages + 1] = tostring(message)
      end
    end
    health.check(probe, reporter)
    h.matches(table.concat(messages, '\n'), 'softwareupdate --install-rosetta --agree-to-license')
  end)

  h.it('classifies and probes the complete manifest inventory without retaining credential values', function()
    package.loaded['nv_ide.health'] = nil
    local health = require 'nv_ide.health'
    local probe, calls = complete_probe { unavailable = { unzip = true, mmdc = true } }
    local report = health.collect(probe)
    local manifest = probe.manifest

    h.deep_equal(report.system, { os = 'Linux', arch = 'x86_64', nvim = '0.12.4', nvim_supported = true })
    h.truthy(find(report.prerequisites, 'archive').required)
    h.falsy(find(report.prerequisites, 'archive').available)
    h.falsy(find(report.prerequisites, 'snacks_image_mermaid').required)
    h.falsy(find(report.prerequisites, 'snacks_image_mermaid').available)

    h.equal(#report.mason, #manifest.mason.packages)
    h.equal(#report.parsers, #manifest.treesitter.parsers)
    h.equal(#report.runtimes, #manifest.runtimes)
    h.equal(#report.external_actions, #manifest.external_actions)
    h.equal(#report.ai.cli, #manifest.ai.cli)
    h.equal(#report.ai.backends, #manifest.ai.backends)
    h.equal(#report.ai.credentials, #manifest.ai.credentials)
    h.truthy(report.mason[1].required)
    h.equal(report.mason[1].status, 'failed')
    h.equal(report.mason[2].status, 'installing')
    h.equal(report.mason[3].status, 'installed')
    h.equal(report.mason[3].version, '1.2.3')
    h.truthy(report.parsers[1].required)
    h.equal(report.parsers[1].status, 'missing')
    h.equal(report.parsers[2].status, 'installed')
    h.equal(report.parsers[2].revision, 'parser-revision-' .. report.parsers[2].id)
    h.equal(report.treesitter.cli.version, '0.26.3')
    h.equal(report.update.status, 'success')
    h.equal(report.update.observed.before.mason_receipts.stylua, '1.0.0')
    h.equal(report.update.observed.after.treesitter_parser_info.lua, 'after-rev')
    h.truthy(report.runtimes[1].required)
    h.falsy(report.external_actions[1].required)

    for _, record in ipairs(manifest.prerequisites) do
      for _, executable in ipairs(record.executables) do
        if record.platform then
          h.equal(calls.executable[executable], nil)
        else
          h.truthy(calls.executable[executable])
        end
      end
    end
    for _, record in ipairs(manifest.runtimes) do
      for _, executable in ipairs(record.executables) do
        h.truthy(calls.executable[executable])
      end
    end
    for _, action in ipairs(manifest.external_actions) do
      h.truthy(calls.executable[action.command[1]])
    end
    for _, name in ipairs(manifest.mason.packages) do
      h.equal(calls.mason[name], 1)
    end
    for _, name in ipairs(manifest.treesitter.parsers) do
      h.equal(calls.parser[name], 1)
    end
    for _, name in ipairs(manifest.ai.cli) do
      h.truthy(calls.executable[name])
    end
    for _, backend in ipairs(manifest.ai.backends) do
      h.equal(calls.backend[backend.id], 1)
    end
    for _, name in ipairs(manifest.ai.credentials) do
      h.equal(calls.credential[name], 1)
    end

    h.deep_equal(ids(report.ai.credentials), { 'ANTHROPIC_API_KEY', 'OPENAI_API_KEY' })
    for _, credential in ipairs(report.ai.credentials) do
      h.equal(type(credential.present), 'boolean')
      h.equal(credential.value, nil)
    end
    local rendered = vim.inspect(report)
    for _, sentinel in pairs(SENTINELS) do
      h.falsy(rendered:find(sentinel, 1, true), 'health collection leaked a credential')
    end
  end)

  h.it('reports watcher, inotify, SSH OSC 52, and tmux constraints', function()
    local health = require 'nv_ide.health'
    local report = health.collect((complete_probe()))
    h.truthy(report.watcher.supported)
    h.equal(report.watcher.backend, 'fs_event')
    h.truthy(report.watcher.inotify.sufficient)
    h.equal(report.clipboard.session, 'ssh')
    h.equal(report.clipboard.provider, 'OSC 52')
    h.truthy(report.clipboard.tmux.active)
    h.equal(report.clipboard.tmux.set_clipboard, 'off')
    h.falsy(report.clipboard.tmux.ms)
  end)

  h.it('reports a local platform clipboard provider independently of SSH state', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe {
      clipboard = function()
        return {
          session = 'local',
          provider = 'pbcopy',
          available = true,
          tmux = { active = false, passthrough = true, set_clipboard = 'on', ms = true },
          local_providers = { pbcopy = true, wl_copy = false, xclip = false, xsel = false },
        }
      end,
    }
    local report = health.collect(probe)
    h.equal(report.clipboard.session, 'local')
    h.equal(report.clipboard.provider, 'pbcopy')
    h.truthy(report.clipboard.available)
    h.falsy(report.clipboard.tmux.active)
  end)

  h.it('applies tmux clipboard capability policy only to OSC 52 sessions', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe {
      clipboard = function()
        return {
          session = 'local',
          provider = 'pbcopy',
          available = true,
          tmux = { active = true, set_clipboard = 'off', ms = false },
          local_providers = { pbcopy = true, wl_copy = false, xclip = false, xsel = false },
        }
      end,
    }
    local messages = {}
    local reporter = {}
    for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
      reporter[level] = function(message)
        messages[#messages + 1] = tostring(message)
      end
    end
    health.check(probe, reporter)
    local output = table.concat(messages, '\n')
    h.falsy(output:find('tmux set-clipboard is not on', 1, true))
    h.falsy(output:find('tmux lacks the Ms clipboard capability', 1, true))
  end)

  h.it('renders required failures, optional warnings, and only credential-presence booleans', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe { unavailable = { unzip = true, mmdc = true } }
    local messages = {}
    local reporter = {}
    for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
      reporter[level] = function(message)
        messages[#messages + 1] = { level = level, message = tostring(message) }
      end
    end

    local report = health.check(probe, reporter)
    local output = vim.inspect(messages)
    h.matches(output, 'archive')
    h.matches(output, 'snacks_image_mermaid')
    h.truthy(output:find('set -s set-clipboard on', 1, true))
    h.truthy(output:find("terminal-features ',*:clipboard'", 1, true))
    h.matches(output, ':ToolchainRepair!')
    h.matches(output, ':MasonLog')
    h.falsy(output:find(':MasonInstall', 1, true))
    h.falsy(output:find(':TSInstall', 1, true))
    h.matches(output, 'sudo apt install tar unzip')
    h.matches(output, '1.2.3')
    h.matches(output, 'parser-revision-bash')
    h.matches(output, 'Tree-sitter CLI 0.26.3')
    h.matches(output, 'Only Lazy rollback is exact')
    h.matches(output, 'stylua@1.0.0')
    h.matches(output, 'stylua@1.1.0')
    h.matches(output, 'lua@before-rev')
    h.matches(output, 'lua@after-rev')
    h.matches(output, 'ANTHROPIC_API_KEY: present')
    h.truthy(vim.tbl_contains(
      vim.tbl_map(function(item)
        return item.level
      end, messages),
      'error'
    ))
    h.truthy(vim.tbl_contains(
      vim.tbl_map(function(item)
        return item.level
      end, messages),
      'warn'
    ))
    for _, sentinel in pairs(SENTINELS) do
      h.falsy(output:find(sentinel, 1, true), 'health renderer leaked a credential')
      h.falsy(vim.inspect(report):find(sentinel, 1, true), 'health return leaked a credential')
    end
  end)

  h.it('requires a completed Mason receipt before classifying an install directory as healthy', function()
    local health = require 'nv_ide.health'
    local function optional(value)
      return {
        or_else = function(_, fallback)
          return value == nil and fallback or value
        end,
      }
    end
    local complete = {
      is_installing = function()
        return false
      end,
      is_installed = function()
        return true
      end,
      get_receipt = function()
        return optional { metrics = { completion_time = 123 } }
      end,
      get_installed_version = function()
        return '2.0.0'
      end,
      get_install_handle = function()
        return optional(nil)
      end,
    }
    h.deep_equal(health.mason_package_status(complete), { status = 'installed', version = '2.0.0' })

    local partial = vim.tbl_extend('force', complete, {
      get_receipt = function()
        return optional(nil)
      end,
    })
    h.deep_equal(health.mason_package_status(partial), { status = 'failed' })

    local installing = vim.tbl_extend('force', partial, {
      is_installing = function()
        return true
      end,
    })
    h.deep_equal(health.mason_package_status(installing), { status = 'installing' })
  end)

  h.it('rejects completed Mason receipts without a readable non-empty installed version', function()
    local health = require 'nv_ide.health'
    local package = {
      is_installing = function()
        return false
      end,
      is_installed = function()
        return true
      end,
      get_receipt = function()
        return {
          or_else = function()
            return { metrics = { completion_time = 123 } }
          end,
        }
      end,
    }

    for _, get_installed_version in ipairs {
      function()
        error 'unreadable installed version'
      end,
      function()
        return ''
      end,
      function()
        return nil
      end,
    } do
      package.get_installed_version = get_installed_version
      h.deep_equal(health.mason_package_status(package), { status = 'failed' })
    end
  end)

  h.it('requires Tree-sitter parser revision evidence before classifying a parser as healthy', function()
    local health = require 'nv_ide.health'
    h.deep_equal(health.parser_install_status(false), { status = 'missing' })
    h.deep_equal(health.parser_install_status(true), { status = 'failed' })
    h.deep_equal(health.parser_install_status(true, 'abc123'), {
      status = 'installed',
      revision = 'abc123',
    })
  end)

  h.it('uses the same dap_repl local-source receipt as installer discovery', function()
    h.with_temp_dir(function(dir)
      local parser_info = vim.fs.joinpath(dir, 'parser-info')
      local provider = vim.fs.joinpath(dir, 'nvim-dap-repl-highlights')
      vim.fn.mkdir(vim.fs.joinpath(provider, 'src'), 'p')
      vim.fn.mkdir(parser_info, 'p')
      vim.fn.writefile({ 'bundled dap repl parser' }, vim.fs.joinpath(provider, 'src', 'parser.c'), 'b')
      vim.fn.writefile({}, vim.fs.joinpath(parser_info, 'dap_repl.revision'), 'b')

      local config = {
        get_install_dir = function(kind)
          h.equal(kind, 'parser-info')
          return parser_info
        end,
      }
      local parser_registry = {
        dap_repl = { install_info = { path = provider } },
      }
      local adapter = require('nv_ide.toolchain.treesitter').new {
        parsers = { 'dap_repl' },
        parser_registry = parser_registry,
        config = vim.tbl_extend('force', config, {
          get_installed = function()
            return { 'dap_repl' }
          end,
        }),
        install = function()
          return { wait = function() return true end }
        end,
      }
      h.truthy(adapter:install({ wait = true }).ok)

      local health = require 'nv_ide.health'
      local installed = health.parser_provider_status('dap_repl', true, {
        config = config,
        parser_registry = parser_registry,
      })
      h.equal(installed.status, 'installed')
      h.truthy(installed.revision:match '^nv%-ide%-ts%-v1:source%-sha256:')

      vim.fn.writefile({ 'new bundled dap repl parser' }, vim.fs.joinpath(provider, 'src', 'parser.c'), 'b')
      h.deep_equal(health.parser_provider_status('dap_repl', true, {
        config = config,
        parser_registry = parser_registry,
      }), { status = 'failed' })
    end)
  end)

  h.it('rejects a Tree-sitter CLI older than the supported 0.26.1 minimum', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe { treesitter_cli_version = '0.25.9' }
    local messages = {}
    local reporter = {}
    for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
      reporter[level] = function(message)
        messages[#messages + 1] = { level = level, message = tostring(message) }
      end
    end
    local report = health.check(probe, reporter)
    h.falsy(report.treesitter.cli.supported)
    local output = vim.inspect(messages)
    h.matches(output, 'requires >= 0.26.1')
    h.matches(output, 'cargo install tree-sitter-cli --version 0.26.3 --locked')
  end)

  h.it('recognizes xsel as a valid local Linux X11 clipboard provider', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe {
      clipboard = function()
        return {
          session = 'local',
          provider = 'xsel',
          available = true,
          tmux = { active = false, set_clipboard = 'off', ms = false },
          local_providers = { pbcopy = false, wl_copy = false, xclip = false, xsel = true },
        }
      end,
    }
    local report = health.collect(probe)
    h.truthy(report.clipboard.available)
    h.equal(report.clipboard.provider, 'xsel')
    h.truthy(report.clipboard.local_providers.xsel)
  end)

  h.it('treats the full runtime inventory as required unless a runtime is explicitly optional', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe { unavailable = { go = true } }
    probe.manifest = vim.deepcopy(probe.manifest)
    probe.manifest.runtimes = {
      { id = 'go', executables = { 'go' } },
      { id = 'optional_runtime', executables = { 'optional-runtime' }, optional = true },
    }
    local report = health.collect(probe)
    h.truthy(find(report.runtimes, 'go').required)
    h.falsy(find(report.runtimes, 'go').available)
    h.falsy(find(report.runtimes, 'optional_runtime').required)
  end)

  h.it('renders platform-specific prerequisite remediation without exposing credentials', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe { os = 'Darwin', unavailable = { git = true } }
    local messages = {}
    local reporter = {}
    for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
      reporter[level] = function(message)
        messages[#messages + 1] = tostring(message)
      end
    end
    health.check(probe, reporter)
    local output = table.concat(messages, '\n')
    h.matches(output, 'brew install git')
    for _, sentinel in pairs(SENTINELS) do
      h.falsy(output:find(sentinel, 1, true), 'remediation leaked a credential')
    end
  end)

  h.it('renders exact platform commands for missing runtimes, terminal actions, and AI integrations', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe {
      unavailable = { go = true, java = true, btop = true, claude = true, ollama = true },
    }
    local messages = {}
    local reporter = {}
    for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
      reporter[level] = function(message)
        messages[#messages + 1] = tostring(message)
      end
    end
    health.check(probe, reporter)
    local output = table.concat(messages, '\n')
    h.matches(output, 'Install Go >= 1.26.0')
    h.matches(output, 'sudo apt install openjdk-21-jdk maven gradle')
    h.matches(output, 'sudo apt install btop')
    h.matches(output, 'npm install --global @anthropic-ai/claude-code')
    h.matches(output, 'curl -fsSL https://ollama.com/install.sh | sh')

    probe = complete_probe { os = 'Darwin', unavailable = { go = true, java = true } }
    messages = {}
    health.check(probe, reporter)
    output = table.concat(messages, '\n')
    h.matches(output, 'brew install go')
    h.matches(output, 'brew install openjdk@21 maven gradle')
  end)

  h.it('renders version and capability constraints with exact platform remediation', function()
    local health = require 'nv_ide.health'
    local probe = complete_probe {
      versions = { go = '1.25.9', javascript = '24.14.0', python = '3.14.0' },
      unsupported_versions = { go = true, javascript = true, python = true },
      unavailable = { ['python:venv'] = true },
    }
    local messages = {}
    local reporter = {}
    for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
      reporter[level] = function(message)
        messages[#messages + 1] = tostring(message)
      end
    end
    health.check(probe, reporter)
    local output = table.concat(messages, '\n')
    h.matches(output, 'Go 1.25.9 requires >= 1.26.0')
    h.matches(output, 'Node.js 24.14.0 requires >= 24.15.0')
    h.matches(output, 'Python 3.14.0 requires >= 3.10.0 and < 3.14.0')
    h.matches(output, 'Python venv capability is unavailable')
    h.matches(output, 'python3 -m venv')
  end)
end)
