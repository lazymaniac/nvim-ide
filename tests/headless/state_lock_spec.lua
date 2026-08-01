local h = require 'tests.headless.harness'

local function reload(name)
  package.loaded[name] = nil
  return require(name)
end

h.describe('toolchain state and process lock', function()
  h.it('atomically replaces state and invalidates changed schemas or fingerprints', function()
    h.with_temp_dir(function(dir)
      local state = reload('nv_ide.toolchain.state').new {
        dir = dir,
        now = function()
          return 200
        end,
      }
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
      local state = reload('nv_ide.toolchain.state').new {
        dir = dir,
        now = function()
          return 150
        end,
      }
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
        token = function()
          return 'first-token'
        end,
        pid_alive = function()
          return true
        end,
      }
      local first_token = assert(first:acquire())

      local checked_live = {}
      local live = lock_module.new {
        dir = dir,
        pid = 202,
        token = function()
          return 'live-token'
        end,
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
        token = function()
          return 'recovered-token'
        end,
        pid_alive = function(pid)
          checked_dead[#checked_dead + 1] = pid
          return false
        end,
      }
      h.equal(recovered:acquire(), 'recovered-token')
      h.deep_equal(checked_dead, { 101 })

      h.falsy(recovered:release(first_token), 'another process token must not release the lock')
      h.truthy(recovered:release 'recovered-token')
    end)
  end)

  h.it('waits for a competing cold-start owner before publishing the second process lock', function()
    h.with_temp_dir(function(dir)
      local lock_module = reload 'nv_ide.toolchain.lock'
      local first = lock_module.new {
        dir = dir,
        pid = 101,
        token = function()
          return 'first-token'
        end,
        pid_alive = function()
          return true
        end,
      }
      h.equal(first:acquire(), 'first-token')

      local waited = 0
      local now = 0
      local second = lock_module.new {
        dir = dir,
        pid = 202,
        token = function()
          return 'second-token'
        end,
        pid_alive = function(pid)
          h.equal(pid, 101)
          return true
        end,
      }
      local token, err = second:acquire_wait {
        timeout_ms = 100,
        poll_ms = 10,
        clock_ms = function()
          return now
        end,
        sleep = function(milliseconds)
          h.equal(milliseconds, 10)
          waited = waited + 1
          now = now + milliseconds
          h.truthy(first:release 'first-token')
        end,
      }

      h.equal(token, 'second-token', err)
      h.equal(waited, 1)
      local owner = vim.json.decode(table.concat(vim.fn.readfile(vim.fs.joinpath(dir, 'install.lock', 'owner.json'), 'b'), '\n'))
      h.equal(owner.pid, 202)
      h.truthy(second:release(token))
    end)
  end)

  h.it('holds the shared process lock across the complete Lazy bootstrap and setup callback', function()
    local events = {}
    local process_lock = {
      acquire_wait = function(_, options)
        events[#events + 1] = { 'acquire', options.timeout_ms, options.poll_ms }
        return 'bootstrap-token'
      end,
      release = function(_, token)
        events[#events + 1] = { 'release', token }
        return true
      end,
    }
    local result = reload('nv_ide.toolchain').with_startup_lock(function()
      events[#events + 1] = { 'lazy-setup' }
      return 'configured'
    end, {
      instance = {
        lock = process_lock,
        timeout_ms = 123,
        poll_ms = 7,
      },
    })

    h.equal(result, 'configured')
    h.deep_equal(events, {
      { 'acquire', 123, 7 },
      { 'lazy-setup' },
      { 'release', 'bootstrap-token' },
    })
  end)

  h.it('releases the cold-start lock when Lazy bootstrap fails', function()
    local released
    h.raises('lazy setup exploded', function()
      reload('nv_ide.toolchain').with_startup_lock(function()
        error 'lazy setup exploded'
      end, {
        instance = {
          lock = {
            acquire_wait = function()
              return 'bootstrap-token'
            end,
            release = function(_, token)
              released = token
              return true
            end,
          },
          timeout_ms = 123,
          poll_ms = 7,
        },
      })
    end)
    h.equal(released, 'bootstrap-token')
  end)

  h.it('wraps production Lazy bootstrap and setup in the cold-start lock', function()
    local source = table.concat(vim.fn.readfile 'init.lua', '\n')
    h.truthy(
      source:match("toolchain%.with_startup_lock%(function%(%)%s*.-require 'config%.lazy'%s*end%)"),
      'init.lua must acquire the shared lock before config.lazy bootstraps or installs plugins'
    )
  end)

  h.it('lets a verified read-only fresh Neovim child run while its parent owns the lock', function()
    h.with_temp_dir(function(dir)
      local state_dir = vim.fs.joinpath(dir, 'state')
      local marker = vim.fs.joinpath(dir, 'child-started')
      local parent_pid = vim.uv.os_getpid()
      local parent_token = string.rep('a', 64)
      local parent = reload('nv_ide.toolchain.lock').new {
        dir = state_dir,
        pid = parent_pid,
        token = function()
          return parent_token
        end,
      }
      h.equal(parent:acquire(), parent_token)

      local result = vim.system({
        vim.v.progpath,
        '--clean',
        '--headless',
        '-u',
        'tests/minimal_init.lua',
        '-i',
        'NONE',
        '-l',
        'tests/headless/locked_startup_child.lua',
        state_dir,
        marker,
      }, {
        cwd = vim.fn.getcwd(),
        text = true,
        timeout = 2000,
        env = {
          NV_IDE_TOOLCHAIN_READONLY_CHILD = '1',
          NV_IDE_TOOLCHAIN_PARENT_LOCK_PID = tostring(parent_pid),
          NV_IDE_TOOLCHAIN_PARENT_LOCK_TOKEN = parent_token,
        },
      }):wait()

      h.equal(result.code, 0, vim.trim(result.stderr or result.stdout or ''))
      h.equal(vim.fn.filereadable(marker), 1)
      h.truthy(parent:release(parent_token))
    end)
  end)

  h.it('recognizes libuv ESRCH results in the default PID verifier', function()
    h.with_temp_dir(function(dir)
      local lock_dir = vim.fs.joinpath(dir, 'install.lock')
      vim.fn.mkdir(lock_dir, 'p')
      vim.fn.writefile({ vim.json.encode { pid = 999999, token = 'dead-owner', acquired_at = 1 } }, vim.fs.joinpath(lock_dir, 'owner.json'))

      local process_lock = reload('nv_ide.toolchain.lock').new {
        dir = dir,
        pid = vim.uv.os_getpid(),
        token = function()
          return 'replacement-owner'
        end,
      }
      local token, err = process_lock:acquire()
      h.equal(token, 'replacement-owner', err)
      h.truthy(process_lock:release(token))
    end)
  end)

  h.it('never removes a replacement owner during stale-lock recovery', function()
    h.with_temp_dir(function(dir)
      local lock_dir = vim.fs.joinpath(dir, 'install.lock')
      local owner_path = vim.fs.joinpath(lock_dir, 'owner.json')
      vim.fn.mkdir(lock_dir, 'p')
      vim.fn.writefile({ vim.json.encode { pid = 101, token = 'stale-token', acquired_at = 1 } }, owner_path)

      local process_lock = reload('nv_ide.toolchain.lock').new {
        dir = dir,
        pid = 303,
        token = function()
          return 'recovering-token'
        end,
        pid_alive = function(pid)
          h.equal(pid, 101)
          return false
        end,
        before_recover = function()
          vim.fn.writefile({ vim.json.encode { pid = 202, token = 'replacement-token', acquired_at = 2 } }, owner_path)
        end,
      }

      local token, err = process_lock:acquire()

      h.equal(token, nil)
      h.matches(err, 'owner changed')
      h.deep_equal(vim.json.decode(table.concat(vim.fn.readfile(owner_path, 'b'), '\n')), {
        pid = 202,
        token = 'replacement-token',
        acquired_at = 2,
      })
      h.deep_equal(vim.fn.glob(lock_dir .. '.quarantine-*', false, true), {})
    end)
  end)

  h.it('serializes competing stale recovery with an exclusive marker', function()
    h.with_temp_dir(function(dir)
      local lock_dir = vim.fs.joinpath(dir, 'install.lock')
      vim.fn.mkdir(lock_dir, 'p')
      vim.fn.writefile({ vim.json.encode { pid = 101, token = 'stale-token', acquired_at = 1 } }, vim.fs.joinpath(lock_dir, 'owner.json'))
      local lock_module = reload 'nv_ide.toolchain.lock'
      local contender = lock_module.new {
        dir = dir,
        pid = 202,
        token = function()
          return 'contender-token'
        end,
        pid_alive = function(pid)
          return pid ~= 101
        end,
      }
      local contender_token, contender_error
      local interleaved = false
      local recovering = lock_module.new {
        dir = dir,
        pid = 150,
        token = function()
          return 'recovering-token'
        end,
        pid_alive = function(pid)
          return pid ~= 101
        end,
        after_marker = function()
          if not interleaved then
            interleaved = true
            contender_token, contender_error = contender:acquire()
          end
        end,
      }

      local recovered_token, recovered_error = recovering:acquire()

      h.equal(contender_token, nil)
      h.matches(contender_error, 'marker')
      h.equal(recovered_token, 'recovering-token', recovered_error)
      h.truthy(recovering:release(recovered_token))
    end)
  end)

  h.it('recovers after a recovery claimant crashes and leaves its claim behind', function()
    h.with_temp_dir(function(dir)
      local lock_dir = vim.fs.joinpath(dir, 'install.lock')
      vim.fn.mkdir(lock_dir, 'p')
      vim.fn.writefile({ vim.json.encode { pid = 101, token = 'stale-token', acquired_at = 1 } }, vim.fs.joinpath(lock_dir, 'owner.json'))
      vim.fn.writefile({}, vim.fs.joinpath(lock_dir, 'recovery.404.orphaned-claim'))
      local checked = {}
      local recovering = reload('nv_ide.toolchain.lock').new {
        dir = dir,
        pid = 303,
        token = function()
          return 'recovering-token'
        end,
        pid_alive = function(pid)
          checked[#checked + 1] = pid
          return false
        end,
      }

      local token, err = recovering:acquire()

      h.equal(token, 'recovering-token', err)
      h.truthy(vim.tbl_contains(checked, 101))
      h.truthy(vim.tbl_contains(checked, 404))
      h.truthy(recovering:release(token))
    end)
  end)

  h.it('prepares a complete owner before publishing the fixed lock path', function()
    h.with_temp_dir(function(dir)
      local lock_module = reload 'nv_ide.toolchain.lock'
      local interrupted = lock_module.new {
        dir = dir,
        pid = 101,
        token = function()
          return 'interrupted-token'
        end,
        before_publish = function(candidate)
          h.truthy(vim.uv.fs_stat(vim.fs.joinpath(candidate, 'owner.json')))
          h.falsy(vim.uv.fs_stat(vim.fs.joinpath(dir, 'install.lock')))
          error 'simulated interruption'
        end,
      }

      local token, err = interrupted:acquire()

      h.equal(token, nil)
      h.matches(err, 'publish')
      h.falsy(vim.uv.fs_stat(vim.fs.joinpath(dir, 'install.lock')))
      h.deep_equal(vim.fn.glob(vim.fs.joinpath(dir, 'install.lock.candidate-*'), false, true), {})

      local replacement = lock_module.new {
        dir = dir,
        pid = 202,
        token = function()
          return 'replacement-token'
        end,
      }
      h.equal(replacement:acquire(), 'replacement-token')
      h.truthy(replacement:release 'replacement-token')
    end)
  end)

  h.it('publishes only one of two prepared lock candidates', function()
    h.with_temp_dir(function(dir)
      local lock_module = reload 'nv_ide.toolchain.lock'
      local contender = lock_module.new {
        dir = dir,
        pid = 202,
        token = function()
          return 'contender-token'
        end,
        pid_alive = function()
          return true
        end,
      }
      local contender_token, contender_error
      local first = lock_module.new {
        dir = dir,
        pid = 101,
        token = function()
          return 'first-token'
        end,
        pid_alive = function(pid)
          return pid == 202
        end,
        before_publish = function()
          contender_token, contender_error = contender:acquire()
        end,
      }

      local first_token, first_error = first:acquire()

      h.equal(contender_token, 'contender-token', contender_error)
      h.equal(first_token, nil)
      h.matches(first_error, 'locked by pid 202')
      local owner = vim.json.decode(table.concat(vim.fn.readfile(vim.fs.joinpath(dir, 'install.lock', 'owner.json'), 'b'), '\n'))
      h.equal(owner.pid, 202)
      h.equal(owner.token, 'contender-token')
      h.falsy(first:release 'first-token')
      h.truthy(contender:release 'contender-token')
      h.deep_equal(vim.fn.glob(vim.fs.joinpath(dir, 'install.lock.candidate-*'), false, true), {})
    end)
  end)

  h.it('refuses to remove a malformed fixed lock owner', function()
    h.with_temp_dir(function(dir)
      local lock_dir = vim.fs.joinpath(dir, 'install.lock')
      vim.fn.mkdir(lock_dir, 'p')
      vim.fn.writefile({ '{not-json' }, vim.fs.joinpath(lock_dir, 'owner.json'))
      local lock = reload('nv_ide.toolchain.lock').new {
        dir = dir,
        pid = 202,
        token = function()
          return 'candidate-token'
        end,
        pid_alive = function()
          error 'an unverified owner must not reach PID probing'
        end,
      }

      local token, err = lock:acquire()

      h.equal(token, nil)
      h.matches(err, 'owner PID cannot be verified')
      h.truthy(vim.uv.fs_stat(lock_dir))
      h.deep_equal(vim.fn.glob(vim.fs.joinpath(dir, 'install.lock.candidate-*'), false, true), {})
    end)
  end)
end)
