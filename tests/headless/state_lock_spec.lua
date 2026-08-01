local h = require 'tests.headless.harness'

local function reload(name)
  package.loaded[name] = nil
  return require(name)
end

h.describe('toolchain state and process lock', function()
  h.it('atomically replaces state and invalidates changed schemas or fingerprints', function()
    h.with_temp_dir(function(dir)
      local state = reload('nv_ide.toolchain.state').new { dir = dir, now = function() return 200 end }
      state:write { schema_version = 1, fingerprint = 'old', status = 'success', last_success = 100 }
      state:write { schema_version = 1, fingerprint = 'current', status = 'success', last_success = 200 }

      h.deep_equal(state:read(), {
        schema_version = 1,
        fingerprint = 'current',
        status = 'success',
        last_success = 200,
      })
      h.deep_equal(vim.fn.glob(dir .. '/*.tmp-*', false, true), {})
      h.truthy(state:is_current(state:read(), 1, 'current'))
      h.falsy(state:is_current(state:read(), 2, 'current'))
      h.falsy(state:is_current(state:read(), 1, 'changed'))
    end)
  end)

  h.it('retries failures and lets repair bypass a valid debounce window', function()
    h.with_temp_dir(function(dir)
      local state = reload('nv_ide.toolchain.state').new { dir = dir, now = function() return 150 end }
      local success = { schema_version = 1, fingerprint = 'same', status = 'success', last_success = 100 }
      h.falsy(state:should_run(success, {
        schema_version = 1,
        fingerprint = 'same',
        debounce_seconds = 100,
        missing = {},
      }))
      h.truthy(state:should_run(success, {
        schema_version = 1,
        fingerprint = 'same',
        debounce_seconds = 100,
        missing = {},
        repair = true,
      }))
      h.truthy(state:should_run(vim.tbl_extend('force', success, { status = 'failed' }), {
        schema_version = 1,
        fingerprint = 'same',
        debounce_seconds = 100,
        missing = {},
      }))
      h.truthy(state:should_run(success, {
        schema_version = 1,
        fingerprint = 'same',
        debounce_seconds = 100,
        missing = { mason = { 'stylua' } },
      }))
    end)
  end)

  h.it('refuses a live owner and recovers a dead owner only after PID verification', function()
    h.with_temp_dir(function(dir)
      local lock_module = reload 'nv_ide.toolchain.lock'
      local first = lock_module.new {
        dir = dir,
        pid = 101,
        token = function() return 'first-token' end,
        pid_alive = function() return true end,
      }
      local first_token = assert(first:acquire())

      local checked_live = {}
      local live = lock_module.new {
        dir = dir,
        pid = 202,
        token = function() return 'live-token' end,
        pid_alive = function(pid)
          checked_live[#checked_live + 1] = pid
          return true
        end,
      }
      local live_token, live_error = live:acquire()
      h.equal(live_token, nil)
      h.matches(live_error, 'locked')
      h.deep_equal(checked_live, { 101 })

      local checked_dead = {}
      local recovered = lock_module.new {
        dir = dir,
        pid = 303,
        token = function() return 'recovered-token' end,
        pid_alive = function(pid)
          checked_dead[#checked_dead + 1] = pid
          return false
        end,
      }
      h.equal(recovered:acquire(), 'recovered-token')
      h.deep_equal(checked_dead, { 101 })

      h.falsy(recovered:release(first_token), 'another process token must not release the lock')
      h.truthy(recovered:release('recovered-token'))
    end)
  end)

  h.it('recognizes libuv ESRCH results in the default PID verifier', function()
    h.with_temp_dir(function(dir)
      local lock_dir = vim.fs.joinpath(dir, 'install.lock')
      vim.fn.mkdir(lock_dir, 'p')
      vim.fn.writefile({ vim.json.encode({ pid = 999999, token = 'dead-owner', acquired_at = 1 }) }, vim.fs.joinpath(lock_dir, 'owner.json'))

      local process_lock = reload('nv_ide.toolchain.lock').new {
        dir = dir,
        pid = vim.uv.os_getpid(),
        token = function() return 'replacement-owner' end,
      }
      local token, err = process_lock:acquire()
      h.equal(token, 'replacement-owner', err)
      h.truthy(process_lock:release(token))
    end)
  end)
end)
