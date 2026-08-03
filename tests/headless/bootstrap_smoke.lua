local function fail(message)
  error('bootstrap smoke: ' .. message, 0)
end

local function check(value, message)
  if not value then
    fail(message)
  end
  return value
end

local function normalize(path)
  return vim.fs.normalize(check(path, 'required path is missing'))
end

local function contains(values, expected)
  if type(values) == 'string' then
    return values == expected
  end
  for _, value in ipairs(values or {}) do
    if value == expected then
      return true
    end
  end
  return false
end

local function within(path, root)
  path = normalize(path)
  root = normalize(root)
  return path == root or vim.startswith(path, root .. '/')
end

local function read(path)
  local file, open_error = io.open(path, 'rb')
  check(file, ('cannot read %s: %s'):format(path, tostring(open_error)))
  local value = file:read '*a'
  file:close()
  return value
end

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name or spec.url == name then
      return spec
    end
  end
  fail('plugin spec not found: ' .. name)
end

local mode = arg[1] or 'preflight'
check(vim.tbl_contains({ 'preflight', 'representative', 'full' }, mode), 'invalid mode: ' .. mode)

local smoke_root = normalize(os.getenv 'NV_IDE_SMOKE_ROOT')
local source_root = normalize(os.getenv 'NV_IDE_SMOKE_SOURCE_ROOT')
local config_root = normalize(vim.fn.stdpath 'config')

check(config_root ~= source_root, 'configuration was not copied away from the source checkout')
check(within(config_root, smoke_root), 'stdpath(config) escaped the temporary smoke root')
for _, kind in ipairs { 'data', 'state', 'cache' } do
  check(within(vim.fn.stdpath(kind), smoke_root), ('stdpath(%s) escaped the temporary smoke root'):format(kind))
end
check(within(vim.env.HOME, smoke_root), 'HOME escaped the temporary smoke root')
check(within(debug.getinfo(1, 'S').source:sub(2), config_root), 'smoke script did not execute from the copied config')

if mode ~= 'preflight' then
  check(vim.env.NV_IDE_SMOKE_ALLOW_INSTALL == '1', mode .. ' mode requires NV_IDE_SMOKE_ALLOW_INSTALL=1')
end
if mode == 'full' then
  check(vim.env.NV_IDE_SMOKE_FULL == '1', 'full mode requires NV_IDE_SMOKE_FULL=1')
end

local manifest = require 'nv_ide.toolchain.manifest'
check(manifest.profiles == nil, 'the toolchain must not expose profiles')
check(#manifest.mason.packages == 86, 'the complete Mason declaration changed unexpectedly')
check(#manifest.treesitter.parsers == 60, 'the complete parser declaration changed unexpectedly')
check(type(manifest.fingerprint()) == 'string' and #manifest.fingerprint() == 64, 'manifest fingerprint is invalid')

do
  local commands = {}
  local fake = {
    run = function()
      return { status = 'success' }
    end,
  }
  require('nv_ide.toolchain.orchestrator').register(fake, {
    create_user_command = function(name, callback, options)
      commands[name] = { callback = callback, options = options }
    end,
    headless = function()
      return true
    end,
  })
  check(commands.ToolchainInstall, 'ToolchainInstall was not registered')
  check(commands.ToolchainRepair, 'ToolchainRepair was not registered')
  check(commands.ToolchainUpdate, 'ToolchainUpdate was not registered')
end

do
  local configured, enabled = {}, {}
  require('plugins.lsp.registry').setup({
    defaults = { flags = { debounce_text_changes = 150 } },
    servers = {
      gopls = { settings = { gopls = { gofumpt = true } } },
      clangd = { cmd = { 'clangd', '--background-index' } },
      vtsls = { settings = { vtsls = { autoUseWorkspaceTsdk = true } } },
    },
  }, {
    protocol_capabilities = function()
      return {}
    end,
    blink_capabilities = function(capabilities)
      return capabilities
    end,
    config = function(server, options)
      check(configured[server] == nil, server .. ' was configured more than once')
      configured[server] = options
    end,
    enable = function(server)
      enabled[server] = (enabled[server] or 0) + 1
    end,
  })
  for _, server in ipairs { 'gopls', 'clangd', 'vtsls' } do
    check(configured[server], server .. ' configuration was not composed')
    check(enabled[server] == 1, server .. ' was not enabled exactly once')
  end
end

do
  local leap = plugin(dofile(config_root .. '/lua/plugins/search.lua'), 'https://codeberg.org/andyg/leap.nvim')
  local mappings = {}
  for _, mapping in ipairs(leap.keys or {}) do
    mappings[mapping[1]] = mapping.mode
  end
  check(contains(mappings.s, 'n') and contains(mappings.s, 'x') and contains(mappings.s, 'o'), 'Leap s modes are incomplete')
  check(contains(mappings.S, 'n') and not contains(mappings.S, 'x'), 'Leap S must be normal-mode only')

  local treesitter = plugin(dofile(config_root .. '/lua/plugins/treesitter.lua'), 'nvim-treesitter/nvim-treesitter')
  check(treesitter.opts.ensure_installed == manifest.treesitter.parsers, 'Tree-sitter does not consume the manifest')
  local source = read(config_root .. '/lua/plugins/treesitter.lua')
  check(source:find "'<C%-Space>'" and source:find "'<BS>'", 'Tree-sitter selection mappings are missing')
end

do
  local ok, health = pcall(require, 'nv_ide.health')
  check(ok, 'nv_ide health provider is unavailable: ' .. tostring(health))
  check(type(health.collect) == 'function', 'health collect(probe) is unavailable')
  check(type(health.check) == 'function', 'health check() renderer is unavailable')

  local sentinel = 'nv-ide-smoke-secret-sentinel'
  local probe = {
    manifest = manifest,
    system = function()
      return { os = 'SmokeOS', arch = 'smoke-arch', nvim = '0.12.4' }
    end,
    executable = function()
      return true
    end,
    mason_installed = function()
      return true
    end,
    parser_installed = function()
      return true
    end,
    watcher = function()
      return {
        supported = true,
        backend = 'fs_event',
        inotify = { max_user_watches = 524288, max_user_instances = 128, sufficient = true },
      }
    end,
    clipboard = function()
      return {
        session = 'ssh',
        provider = 'OSC 52',
        available = true,
        tmux = { active = true, passthrough = false },
        local_providers = { pbcopy = false, wl_copy = false, xclip = false },
      }
    end,
    backend_available = function()
      return true
    end,
    credential = function()
      return sentinel
    end,
  }
  local report = health.collect(probe)
  check(not vim.inspect(report):find(sentinel, 1, true), 'health collection leaked a credential value')

  local messages = {}
  local reporter = {}
  for _, level in ipairs { 'start', 'ok', 'info', 'warn', 'error' } do
    reporter[level] = function(message)
      messages[#messages + 1] = ('%s:%s'):format(level, tostring(message))
    end
  end
  health.check(probe, reporter)
  local rendered = table.concat(messages, '\n')
  check(not rendered:find(sentinel, 1, true), 'health renderer leaked a credential value')
  check(rendered:find('OPENAI_API_KEY: present', 1, true), 'health did not render credential presence')
end

if mode ~= 'preflight' then
  local plugin_root = normalize(os.getenv 'NV_IDE_SMOKE_PLUGIN_ROOT')
  local plugins = {
    mason = plugin_root .. '/mason.nvim',
    installer = plugin_root .. '/mason-tool-installer.nvim',
    treesitter = plugin_root .. '/nvim-treesitter',
    snacks = plugin_root .. '/snacks.nvim',
  }
  for _, path in pairs(plugins) do
    check(vim.uv.fs_stat(path), 'smoke dependency is missing: ' .. path)
    vim.opt.runtimepath:prepend(path)
  end

  require('mason').setup {
    install_root_dir = vim.fn.stdpath 'data' .. '/mason',
    log_level = vim.log.levels.WARN,
  }
  local packages = mode == 'full' and manifest.mason.packages or { 'stylua' }
  require('mason-tool-installer').setup {
    ensure_installed = packages,
    auto_update = false,
    run_on_start = false,
    integrations = {
      ['mason-lspconfig'] = false,
      ['mason-null-ls'] = false,
      ['mason-nvim-dap'] = false,
    },
  }
  local registry = require 'mason-registry'
  local install_timeout = mode == 'full' and 1800000 or 300000
  local mason_completed = false
  local mason_completion = vim.api.nvim_create_autocmd('User', {
    pattern = 'MasonToolsUpdateCompleted',
    once = true,
    callback = function()
      mason_completed = true
    end,
  })
  require('mason-tool-installer').check_install(false, false)
  local mason_finished = vim.wait(install_timeout, function()
    return mason_completed
  end, 100)
  if not mason_completed then
    pcall(vim.api.nvim_del_autocmd, mason_completion)
  end
  check(mason_finished, ('Mason installation timed out after %d ms'):format(install_timeout))
  for _, name in ipairs(packages) do
    local package = registry.get_package(name)
    check(not package:is_installing(), 'Mason package is still installing: ' .. name)
    check(package:is_installed(), 'Mason package was not installed: ' .. name)
    local receipt = package:get_receipt():or_else(nil)
    check(
      type(receipt) == 'table' and type(receipt.metrics) == 'table' and tonumber(receipt.metrics.completion_time) ~= nil,
      'Mason package has no completed receipt: ' .. name
    )
    check(package:get_installed_version(), 'Mason package has no installed version: ' .. name)
  end

  local parser_dir = vim.fn.stdpath 'data' .. '/site'
  require('nvim-treesitter').setup { install_dir = parser_dir }
  local parsers = mode == 'full' and manifest.treesitter.parsers or { 'lua' }
  local task = require('nvim-treesitter').install(parsers)
  check(task and type(task.wait) == 'function', 'Tree-sitter did not return an installation task')
  task:wait(install_timeout)

  local installed = {}
  local treesitter_config = require 'nvim-treesitter.config'
  for _, parser in ipairs(treesitter_config.get_installed 'parsers') do
    installed[parser] = true
  end
  local parser_info = treesitter_config.get_install_dir 'parser-info'
  for _, parser in ipairs(parsers) do
    check(installed[parser], 'Tree-sitter parser was not installed: ' .. parser)
    local revision_path = vim.fs.joinpath(parser_info, parser .. '.revision')
    check(vim.fn.filereadable(revision_path) == 1, 'Tree-sitter parser has no revision evidence: ' .. parser)
    check(vim.trim(read(revision_path)) ~= '', 'Tree-sitter parser revision is empty: ' .. parser)
  end

  local health_ok, health_error = pcall(vim.cmd, 'checkhealth nv_ide')
  check(health_ok, 'checkhealth nv_ide failed: ' .. tostring(health_error))
  health_ok, health_error = pcall(vim.cmd, 'checkhealth snacks')
  check(health_ok, 'checkhealth snacks failed: ' .. tostring(health_error))
end

do
  local forbidden = {}
  for _, manager in ipairs { 'sudo', 'brew', 'apt', 'apt-get', 'dnf', 'pacman', 'zypper' } do
    for _, launcher in ipairs { 'vim.system', 'vim.fn.system', 'vim.fn.jobstart' } do
      forbidden[#forbidden + 1] = launcher .. "({ '" .. manager .. "'"
      forbidden[#forbidden + 1] = launcher .. " { '" .. manager .. "'"
      forbidden[#forbidden + 1] = launcher .. '({ "' .. manager .. '"'
      forbidden[#forbidden + 1] = launcher .. ' { "' .. manager .. '"'
    end
    forbidden[#forbidden + 1] = "os.execute('" .. manager
    forbidden[#forbidden + 1] = 'os.execute("' .. manager
    forbidden[#forbidden + 1] = "vim.cmd('!" .. manager
    forbidden[#forbidden + 1] = 'vim.cmd("!' .. manager
  end
  local runtime_files = vim.fn.glob(config_root .. '/lua/**/*.lua', false, true)
  runtime_files[#runtime_files + 1] = config_root .. '/init.lua'
  for _, path in ipairs(runtime_files) do
    local source = read(path)
    for _, needle in ipairs(forbidden) do
      check(not source:find(needle, 1, true), ('background privilege escalation found in %s'):format(path))
    end
  end
end

do
  local workflow_path = config_root .. '/.github/workflows/neovim.yml'
  check(vim.uv.fs_stat(workflow_path), 'portable Neovim CI workflow is missing')
  local workflow = read(workflow_path)
  for _, needle in ipairs {
    'ubuntu-latest',
    'macos-latest',
    'preflight',
    'representative',
    'checkhealth nv_ide',
    'checkhealth snacks',
    'manifest-fingerprint',
    'Resolve latest allowed plugins and verify CodeCompanion reasoning',
    'NV_IDE_SMOKE_LOCK_OUTPUT',
    "NV_IDE_TOOLCHAIN_TIMEOUT_MS: '7200000'",
    'actions/upload-artifact@v4',
    'NVIM_TOOLCHAIN_AUTORUN',
  } do
    check(workflow:find(needle, 1, true), 'workflow is missing ' .. needle)
  end

  local readme = read(config_root .. '/README.md')
  for _, needle in ipairs {
    'https://github.com/lazymaniac/nvim-ide.git',
    ':ToolchainInstall',
    ':ToolchainRepair',
    ':ToolchainUpdate',
    ':checkhealth nv_ide',
    'OSC 52',
  } do
    check(readme:find(needle, 1, true), 'README is missing ' .. needle)
  end
  check(not readme:find('cp ~/.config/nvim/dotfiles/.zshrc', 1, true), 'README still overwrites .zshrc')
  check(not readme:find('uv venv', 1, true), 'README still creates a repository-local Python environment')

  local smoke_runner = read(config_root .. '/tests/headless/no-profile.sh')
  for _, needle in ipairs {
    'locked_plugin.lua',
    'lazy_resolution.lua',
    'codecompanion_reasoning_failing_init.lua',
    'codecompanion_reasoning_runtime.lua',
    'verify_codecompanion_reasoning',
    'verify_codecompanion_reasoning_startup_guard',
    'Neovim startup failed before CodeCompanion reasoning verification',
    'CODECOMPANION STARTUP GUARD PASS',
    'CODECOMPANION REASONING PASS',
    "run_lazy_resolution publish 'LAZY STABLE PASS' 'FRESH STARTUP PASS'",
    'NVIM_TOOLCHAIN_AUTORUN=1',
    'startup_smoke.lua',
    'RESOLVED LOCKFILE',
  } do
    check(smoke_runner:find(needle, 1, true), 'smoke runner is missing ' .. needle)
  end
  local resolver = read(config_root .. '/tests/headless/lazy_resolution.lua')
  for _, needle in ipairs { 'resolution_gate.lua', 'LAZY UPDATE PASS', 'LAZY STABLE PASS', 'FRESH STARTUP PASS' } do
    check(resolver:find(needle, 1, true), 'resolution smoke is missing ' .. needle)
  end

  local false_executable = check(vim.fn.exepath 'false', 'false executable is unavailable')
  check(false_executable ~= '', 'false executable is unavailable')
  local failed_artifact = vim.fs.joinpath(smoke_root, 'failed-resolved-lock.json')
  local smoke = require('nv_ide.toolchain.smoke').new {
    root = config_root,
    lockfile = config_root .. '/lazy-lock.json',
    nvim = false_executable,
    timeout_ms = 1000,
  }
  smoke.checks = { smoke.checks[4] }
  local gate = dofile(config_root .. '/tests/headless/resolution_gate.lua')
  local rejected = gate.publish {
    smoke = smoke,
    source = config_root .. '/lazy-lock.json',
    destination = failed_artifact,
  }
  check(rejected.ok == false, 'nonzero fresh startup did not fail the publication gate')
  check(not vim.uv.fs_stat(failed_artifact), 'failed fresh startup published a resolved lockfile')

  local incomplete_lock = vim.fs.joinpath(smoke_root, 'incomplete-resolved-lock.json')
  vim.fn.writefile({ '{"plugin":{"branch":"main","commit":"invalid"}}' }, incomplete_lock, 'b')
  local invalid_artifact = vim.fs.joinpath(smoke_root, 'invalid-resolved-lock.json')
  local invalid = gate.publish {
    smoke = smoke,
    source = incomplete_lock,
    destination = invalid_artifact,
  }
  check(invalid.ok == false, 'incomplete lockfile passed the publication gate')
  check(table.concat(invalid.errors or {}, '\n'):find('missing lazy.nvim', 1, true), 'missing lazy.nvim was not reported')
  check(not vim.uv.fs_stat(invalid_artifact), 'incomplete lockfile was published')
end

vim.api.nvim_out_write(('SMOKE %s PASS\n'):format(mode))
