local h = require 'tests.headless.harness'

local function reload(name)
  package.loaded[name] = nil
  return require(name)
end

local function process(result, on_exit)
  return {
    wait = function()
      if on_exit then
        error 'asynchronous manager command must not wait'
      end
      return vim.deepcopy(result)
    end,
    finish = function()
      assert(on_exit, 'process is not asynchronous')
      on_exit(vim.deepcopy(result))
    end,
  }
end

h.describe('external lazy.nvim manager lifecycle', function()
  h.it('updates to the newest stable semver tag and records both revisions', function()
    local commands = {}
    local old_commit = string.rep('a', 40)
    local new_commit = string.rep('b', 40)
    local results = {
      { code = 0, stdout = old_commit .. '\n' },
      {
        code = 0,
        stdout = table.concat({
          string.rep('9', 40) .. '\trefs/tags/v9.9.9',
          new_commit .. '\trefs/tags/v11.17.5',
          string.rep('c', 40) .. '\trefs/tags/v12.0.0-rc.1',
        }, '\n'),
      },
      { code = 0 },
      { code = 0 },
      { code = 0, stdout = new_commit .. '\n' },
    }
    local manager = reload('nv_ide.toolchain.lazy_manager').new {
      path = '/test/lazy.nvim',
      system = function(command, _, on_exit)
        commands[#commands + 1] = vim.deepcopy(command)
        return process(table.remove(results, 1), on_exit)
      end,
    }

    local completed
    local result = manager:update({ wait = true, timeout_ms = 1234 }, function(value)
      completed = value
    end)

    h.truthy(result.ok)
    h.deep_equal(completed, result)
    h.equal(result.before, old_commit)
    h.equal(result.commit, new_commit)
    h.equal(result.tag, 'v11.17.5')
    h.deep_equal(commands[1], { 'git', '-C', '/test/lazy.nvim', 'rev-parse', 'HEAD' })
    h.deep_equal(commands[2], {
      'git',
      'ls-remote',
      '--tags',
      '--refs',
      'https://github.com/folke/lazy.nvim.git',
      'v*',
    })
    h.truthy(vim.tbl_contains(commands[3], 'refs/tags/v11.17.5'))
    h.deep_equal(commands[4], {
      'git',
      '-C',
      '/test/lazy.nvim',
      'checkout',
      '--force',
      '--detach',
      new_commit,
    })
  end)

  h.it('returns before an asynchronous stable update settles', function()
    local old_commit = string.rep('d', 40)
    local new_commit = string.rep('e', 40)
    local pending = {}
    local results = {
      { code = 0, stdout = old_commit .. '\n' },
      { code = 0, stdout = new_commit .. '\trefs/tags/v11.17.5\n' },
      { code = 0 },
      { code = 0 },
      { code = 0, stdout = new_commit .. '\n' },
    }
    local manager = reload('nv_ide.toolchain.lazy_manager').new {
      path = '/test/lazy.nvim',
      system = function(_, _, on_exit)
        local handle = process(table.remove(results, 1), on_exit)
        pending[#pending + 1] = handle
        return handle
      end,
    }

    local completed
    local started = manager:update({ wait = false }, function(value)
      completed = value
    end)
    h.truthy(started.pending)
    h.equal(completed, nil)
    for index = 1, 5 do
      pending[index]:finish()
    end
    h.truthy(completed.ok)
    h.equal(completed.before, old_commit)
    h.equal(completed.commit, new_commit)
  end)

  h.it('restores an exact prior manager commit', function()
    local prior = string.rep('f', 40)
    local commands = {}
    local results = {
      { code = 0 },
      { code = 0, stdout = prior .. '\n' },
    }
    local manager = reload('nv_ide.toolchain.lazy_manager').new {
      path = '/test/lazy.nvim',
      system = function(command, _, on_exit)
        commands[#commands + 1] = vim.deepcopy(command)
        return process(table.remove(results, 1), on_exit)
      end,
    }

    local result = manager:restore({ wait = true, commit = prior }, function() end)

    h.truthy(result.ok)
    h.deep_equal(commands[1], {
      'git',
      '-C',
      '/test/lazy.nvim',
      'checkout',
      '--force',
      '--detach',
      prior,
    })
  end)

  h.it('atomically records the external manager in the Lazy lockfile', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      local commit = string.rep('1', 40)
      vim.fn.writefile({ vim.json.encode { plugin = { branch = 'main', commit = string.rep('2', 40) } } }, lockfile, 'b')
      local manager = reload('nv_ide.toolchain.lazy_manager').new {
        path = '/test/lazy.nvim',
        lockfile = lockfile,
      }

      local ok, record_error = manager:record(commit)

      h.truthy(ok, record_error)
      local lock = vim.json.decode(table.concat(vim.fn.readfile(lockfile, 'b'), '\n'))
      h.deep_equal(lock['lazy.nvim'], { branch = 'main', commit = commit })
      h.equal(lock.plugin.commit, string.rep('2', 40))
      h.deep_equal(vim.fn.glob(lockfile .. '.manager-*', false, true), {})
    end)
  end)
end)
