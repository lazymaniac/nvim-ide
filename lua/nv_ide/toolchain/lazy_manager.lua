local Manager = {}
Manager.__index = Manager

local REPOSITORY = 'https://github.com/folke/lazy.nvim.git'

local function valid_commit(value)
  return type(value) == 'string' and #value == 40 and value:match '^[0-9a-fA-F]+$' ~= nil
end

local function newest_stable_release(output)
  local selected
  for line in tostring(output or ''):gmatch '[^\r\n]+' do
    local commit, tag, major, minor, patch = line:match '^([0-9a-fA-F]+)%s+refs/tags/(v(%d+)%.(%d+)%.(%d+))$'
    if valid_commit(commit) then
      local candidate = {
        commit = commit:lower(),
        tag = tag,
        version = { tonumber(major), tonumber(minor), tonumber(patch) },
      }
      if not selected then
        selected = candidate
      else
        for index = 1, 3 do
          if candidate.version[index] ~= selected.version[index] then
            if candidate.version[index] > selected.version[index] then
              selected = candidate
            end
            break
          end
        end
      end
    end
  end
  return selected
end

local function detail(result)
  if type(result) ~= 'table' then
    return 'process result is unavailable'
  end
  local message = vim.trim(result.stderr or result.stdout or '')
  return message ~= '' and message or ('exit code %s'):format(tostring(result.code))
end

function Manager:_command(command, options, done)
  local process_options = { text = true, timeout = options.timeout_ms or self.timeout_ms }
  if options.wait then
    local spawned, process = pcall(self.system, command, process_options)
    if not spawned then
      done(nil, tostring(process))
      return
    end
    if type(process) ~= 'table' or type(process.wait) ~= 'function' then
      done(nil, 'process handle is unavailable')
      return
    end
    local waited, result = pcall(process.wait, process)
    if not waited then
      done(nil, tostring(result))
    elseif type(result) ~= 'table' or result.code ~= 0 then
      done(nil, detail(result))
    else
      done(result)
    end
    return
  end

  local settled = false
  local function finish(result)
    if settled then
      return
    end
    settled = true
    if type(result) ~= 'table' or result.code ~= 0 then
      done(nil, detail(result))
    else
      done(result)
    end
  end
  local spawned, process = pcall(self.system, command, process_options, finish)
  if not spawned then
    settled = true
    done(nil, tostring(process))
  elseif type(process) ~= 'table' then
    settled = true
    done(nil, 'process handle is unavailable')
  end
end

function Manager:_git(arguments, options, done)
  local command = { 'git', '-C', self.path }
  vim.list_extend(command, arguments)
  self:_command(command, options, done)
end

function Manager:update(options, done)
  options = options or {}
  local final
  local completed = false
  local state = {}
  local function finish(result)
    if completed then
      return
    end
    completed = true
    result.before = result.before or state.before
    final = result
    if done then
      done(result)
    end
  end
  local function fail(stage, message)
    finish { ok = false, error = ('%s: %s'):format(stage, tostring(message)) }
  end

  self:_git({ 'rev-parse', 'HEAD' }, options, function(head, head_error)
    if not head then
      fail('lazy.nvim revision snapshot', head_error)
      return
    end
    state.before = vim.trim(head.stdout or ''):lower()
    if not valid_commit(state.before) then
      fail('lazy.nvim revision snapshot', 'HEAD is not a full commit')
      return
    end

    self:_command({ 'git', 'ls-remote', '--tags', '--refs', REPOSITORY, 'v*' }, options, function(listed, list_error)
      if not listed then
        fail('lazy.nvim stable release lookup', list_error)
        return
      end
      local release = newest_stable_release(listed.stdout)
      if not release then
        fail('lazy.nvim stable release lookup', 'no stable semver release tag was found')
        return
      end
      state.release = release

      self:_git({ 'fetch', '--force', '--filter=blob:none', '--depth=1', 'origin', 'refs/tags/' .. release.tag }, options, function(_, fetch_error)
        if fetch_error then
          fail('lazy.nvim stable tag fetch', fetch_error)
          return
        end
        self:_git({ 'checkout', '--force', '--detach', release.commit }, options, function(_, checkout_error)
          if checkout_error then
            fail('lazy.nvim stable checkout', checkout_error)
            return
          end
          self:_git({ 'rev-parse', 'HEAD' }, options, function(verified, verify_error)
            if not verified then
              fail('lazy.nvim checkout verification', verify_error)
              return
            end
            local actual = vim.trim(verified.stdout or ''):lower()
            if actual ~= release.commit then
              fail('lazy.nvim checkout verification', ('expected %s, got %s'):format(release.commit, actual))
              return
            end
            finish {
              ok = true,
              before = state.before,
              commit = release.commit,
              tag = release.tag,
            }
          end)
        end)
      end)
    end)
  end)

  return final or { ok = true, pending = true }
end

function Manager:restore(options, done)
  options = options or {}
  local commit = options.commit
  if not valid_commit(commit) then
    local result = { ok = false, error = 'lazy.nvim rollback commit is invalid' }
    if done then
      done(result)
    end
    return result
  end

  local final
  self:_git({ 'checkout', '--force', '--detach', commit }, options, function(_, checkout_error)
    if checkout_error then
      final = { ok = false, error = 'lazy.nvim rollback checkout: ' .. tostring(checkout_error) }
      if done then
        done(final)
      end
      return
    end
    self:_git({ 'rev-parse', 'HEAD' }, options, function(verified, verify_error)
      if not verified then
        final = { ok = false, error = 'lazy.nvim rollback verification: ' .. tostring(verify_error) }
      else
        local actual = vim.trim(verified.stdout or ''):lower()
        final = actual == commit:lower()
            and { ok = true, commit = actual }
          or { ok = false, error = ('lazy.nvim rollback verification: expected %s, got %s'):format(commit, actual) }
      end
      if done then
        done(final)
      end
    end)
  end)
  return final or { ok = true, pending = true }
end

function Manager:record(commit)
  if not valid_commit(commit) then
    return nil, 'lazy.nvim lock commit is invalid'
  end
  local file, open_error = io.open(self.lockfile, 'rb')
  if not file then
    return nil, 'cannot read Lazy lockfile: ' .. tostring(open_error)
  end
  local contents = file:read '*a'
  file:close()
  local decoded, lock = pcall(vim.json.decode, contents)
  if not decoded or type(lock) ~= 'table' then
    return nil, 'Lazy lockfile is not valid JSON'
  end
  lock['lazy.nvim'] = { branch = 'main', commit = commit:lower() }

  local temporary = self.lockfile .. ('.manager-%d-%d'):format(vim.uv.os_getpid(), vim.uv.hrtime())
  local descriptor, stage_error = vim.uv.fs_open(temporary, 'wx', 384)
  if not descriptor then
    return nil, 'cannot stage Lazy manager lock entry: ' .. tostring(stage_error)
  end
  local written, write_error = vim.uv.fs_write(descriptor, vim.json.encode(lock), 0)
  local synced, sync_error = written and vim.uv.fs_fsync(descriptor) or nil
  local closed, close_error = vim.uv.fs_close(descriptor)
  if not written or not synced or not closed then
    vim.fn.delete(temporary)
    return nil, 'cannot write Lazy manager lock entry: ' .. tostring(write_error or sync_error or close_error)
  end
  local renamed, rename_error = vim.uv.fs_rename(temporary, self.lockfile)
  if not renamed then
    vim.fn.delete(temporary)
    return nil, 'cannot publish Lazy manager lock entry: ' .. tostring(rename_error)
  end
  return true
end

local M = {}

M.newest_stable_release = newest_stable_release

function M.new(options)
  options = options or {}
  return setmetatable({
    path = options.path or vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy', 'lazy.nvim'),
    lockfile = options.lockfile or vim.fs.joinpath(vim.fn.stdpath 'config', 'lazy-lock.json'),
    system = options.system or vim.system,
    timeout_ms = options.timeout_ms or 120000,
  }, Manager)
end

return M
