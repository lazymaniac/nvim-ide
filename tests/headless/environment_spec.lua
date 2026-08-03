local h = require 'tests.headless.harness'

local function load_environment()
  package.loaded['nv_ide.toolchain.environment'] = nil
  return require 'nv_ide.toolchain.environment'
end

local function run(options)
  options = options or {}
  local assigned_path
  local assigned_clipboard
  local existing = {}
  for _, path in ipairs(options.existing or {}) do existing[path] = true end
  local environment = load_environment()
  local result = environment.setup {
    os = options.os or 'Darwin',
    home = '/home/tester',
    data = '/data/nvim',
    env = options.env or {},
    path = options.path or '/usr/bin:/bin',
    is_dir = function(path) return existing[path] == true end,
    set_path = function(path) assigned_path = path end,
    get_clipboard = function() return options.clipboard end,
    set_clipboard = function(clipboard) assigned_clipboard = clipboard end,
    osc52 = function() return { name = 'OSC 52 test provider' } end,
  }
  return result, assigned_path, assigned_clipboard
end

h.describe('portable early environment', function()
  h.it('hydrates deterministic existing Darwin paths without duplicates', function()
    local result, path = run {
      os = 'Darwin',
      path = '/usr/bin:/home/tester/.local/bin',
      existing = {
        '/home/tester/.local/bin',
        '/home/tester/.cargo/bin',
        '/home/tester/go/bin',
        '/home/tester/.asdf/shims',
        '/data/nvim/mason/bin',
        '/opt/homebrew/opt/python@3.13/libexec/bin',
        '/opt/homebrew/opt/ruby/bin',
        '/opt/homebrew/opt/openjdk@21/bin',
        '/opt/homebrew/opt/openjdk/bin',
        '/opt/homebrew/opt/libpq/bin',
        '/opt/homebrew/bin',
      },
    }
    h.equal(path, table.concat({
      '/home/tester/.cargo/bin',
      '/home/tester/go/bin',
      '/home/tester/.asdf/shims',
      '/data/nvim/mason/bin',
      '/opt/homebrew/opt/python@3.13/libexec/bin',
      '/opt/homebrew/opt/ruby/bin',
      '/opt/homebrew/opt/openjdk@21/bin',
      '/opt/homebrew/opt/openjdk/bin',
      '/opt/homebrew/opt/libpq/bin',
      '/opt/homebrew/bin',
      '/usr/bin',
      '/home/tester/.local/bin',
    }, ':'))
    h.deep_equal(result.added, {
      '/home/tester/.cargo/bin',
      '/home/tester/go/bin',
      '/home/tester/.asdf/shims',
      '/data/nvim/mason/bin',
      '/opt/homebrew/opt/python@3.13/libexec/bin',
      '/opt/homebrew/opt/ruby/bin',
      '/opt/homebrew/opt/openjdk@21/bin',
      '/opt/homebrew/opt/openjdk/bin',
      '/opt/homebrew/opt/libpq/bin',
      '/opt/homebrew/bin',
    })
    h.falsy(path:find('/usr/local/bin', 1, true), 'nonexistent directories must not be inserted')
  end)

  h.it('hydrates Intel Homebrew keg-only paths before its generic bin directory', function()
    local _, path = run {
      os = 'Darwin',
      path = '/usr/bin',
      existing = {
        '/usr/local/opt/python@3.13/libexec/bin',
        '/usr/local/opt/ruby/bin',
        '/usr/local/opt/openjdk@21/bin',
        '/usr/local/opt/openjdk/bin',
        '/usr/local/opt/libpq/bin',
        '/usr/local/bin',
      },
    }
    h.equal(path, table.concat({
      '/usr/local/opt/python@3.13/libexec/bin',
      '/usr/local/opt/ruby/bin',
      '/usr/local/opt/openjdk@21/bin',
      '/usr/local/opt/openjdk/bin',
      '/usr/local/opt/libpq/bin',
      '/usr/local/bin',
      '/usr/bin',
    }, ':'))
  end)

  h.it('hydrates deterministic existing Linux paths without running a shell', function()
    local result, path = run {
      os = 'Linux',
      path = '/usr/local/bin:/usr/bin',
      existing = {
        '/home/tester/.local/bin',
        '/home/tester/.cargo/bin',
        '/home/tester/go/bin',
        '/home/linuxbrew/.linuxbrew/bin',
        '/usr/local/bin',
      },
    }
    h.equal(path, table.concat({
      '/home/tester/.local/bin',
      '/home/tester/.cargo/bin',
      '/home/tester/go/bin',
      '/home/linuxbrew/.linuxbrew/bin',
      '/usr/local/bin',
      '/usr/bin',
    }, ':'))
    h.equal(result.os, 'Linux')
    h.falsy(result.shell_invoked, 'PATH discovery must never invoke a login shell')
  end)

  h.it('selects OSC 52 only for SSH without a user clipboard provider', function()
    local result, _, clipboard = run { env = { SSH_CONNECTION = 'host 1 2 3' } }
    h.equal(clipboard.name, 'OSC 52 test provider')
    h.equal(result.clipboard, 'osc52')

    local custom = { name = 'custom provider' }
    local preserved, _, replacement = run {
      env = { SSH_TTY = '/dev/pts/1' },
      clipboard = custom,
    }
    h.equal(replacement, nil)
    h.equal(preserved.clipboard, 'user')
  end)

  h.it('leaves local clipboard detection unchanged', function()
    local result, _, clipboard = run { env = {} }
    h.equal(clipboard, nil)
    h.equal(result.clipboard, 'local')
  end)

  h.it('runs before Lazy bootstrap', function()
    local source = table.concat(vim.fn.readfile('init.lua'), '\n')
    local early = assert(source:find('toolchain.early()', 1, true))
    local lazy = assert(source:find("require 'config.lazy'", 1, true))
    h.truthy(early < lazy, 'portable environment must initialize before Lazy')
  end)
end)
