local Lock = {}
Lock.__index = Lock

local function default_dir()
  return vim.fs.joinpath(vim.fn.stdpath 'state', 'nv_ide', 'toolchain')
end

local function default_pid_alive(pid)
  if type(pid) ~= 'number' or pid <= 0 then
    return nil
  end
  local ok, result, error_name = pcall(vim.uv.kill, pid, 0)
  if not ok then
    return nil
  end
  if result == 0 then
    return true
  end
  if tostring(error_name):find('ESRCH', 1, true) then
    return false
  end
  return nil
end

local function default_token(pid)
  return vim.fn.sha256(('%d:%d:%s'):format(pid, vim.uv.hrtime(), tostring {}))
end

local function default_quarantine(path, pid)
  return ('%s.quarantine-%d-%d'):format(path, pid, vim.uv.hrtime())
end

local function default_claim(path, pid, token)
  return vim.fs.joinpath(path, ('recovery.%d.%s'):format(pid, vim.fn.sha256(token)))
end

local function default_candidate(path, pid, token)
  return ('%s.candidate-%d-%s'):format(path, pid, vim.fn.sha256(token))
end

local function owner_matches(actual, expected)
  return type(actual) == 'table' and type(expected) == 'table' and actual.pid == expected.pid and actual.token == expected.token
end

function Lock:_read_owner_at(path)
  local owner_path = vim.fs.joinpath(path, 'owner.json')
  if vim.fn.filereadable(owner_path) ~= 1 then
    return nil
  end
  local ok, owner = pcall(vim.json.decode, table.concat(vim.fn.readfile(owner_path, 'b'), '\n'))
  return ok and type(owner) == 'table' and owner or nil
end

function Lock:_read_owner()
  return self:_read_owner_at(self.path)
end

function Lock:_write_owner_at(path, owner)
  local owner_path = vim.fs.joinpath(path, 'owner.json')
  local file, open_error = vim.uv.fs_open(owner_path, 'wx', 384)
  if not file then
    return false, open_error
  end
  local written, write_error = vim.uv.fs_write(file, vim.json.encode(owner) .. '\n', 0)
  local synced, sync_error = written and vim.uv.fs_fsync(file) or nil
  local closed, close_error = vim.uv.fs_close(file)
  if not written or not synced or not closed then
    vim.fn.delete(owner_path)
    return false, write_error or sync_error or close_error
  end
  return true
end

function Lock:_remove_candidate(path)
  vim.fn.delete(vim.fs.joinpath(path, 'owner.json'))
  local removed, remove_error = vim.uv.fs_rmdir(path)
  return removed ~= nil, remove_error
end

function Lock:_publish()
  local token = self.make_token(self.pid)
  local candidate = self.make_candidate(self.path, self.pid, token)
  local created, create_error = vim.uv.fs_mkdir(candidate, 448)
  if not created then
    return nil, 'failed to create lock candidate: ' .. tostring(create_error)
  end

  local owner = { pid = self.pid, token = token, acquired_at = self.now() }
  local written, write_error = self:_write_owner_at(candidate, owner)
  if not written then
    self:_remove_candidate(candidate)
    return nil, 'failed to write lock candidate owner: ' .. tostring(write_error)
  end

  if self.before_publish then
    local hooked, hook_error = pcall(self.before_publish, candidate, owner)
    if not hooked then
      local removed, remove_error = self:_remove_candidate(candidate)
      local cleanup = removed and '' or '; cleanup failed: ' .. tostring(remove_error)
      return nil, 'publish hook failed: ' .. tostring(hook_error) .. cleanup
    end
  end

  local published, publish_error = vim.uv.fs_rename(candidate, self.path)
  if published then
    return token
  end
  local removed, remove_error = self:_remove_candidate(candidate)
  local cleanup = removed and '' or '; cleanup failed: ' .. tostring(remove_error)
  return nil, tostring(publish_error) .. cleanup
end

function Lock:_claim_removal(expected)
  local claim_path = self.make_claim(self.path, self.pid, self.make_token(self.pid))
  local claim, claim_error = vim.uv.fs_open(claim_path, 'wx', 384)
  if not claim then
    return nil, 'failed to create recovery claim: ' .. tostring(claim_error)
  end
  vim.uv.fs_close(claim)
  if self.after_marker then
    local hooked, hook_error = pcall(self.after_marker, expected)
    if not hooked then
      vim.fn.delete(claim_path)
      return nil, 'recovery claim hook failed: ' .. tostring(hook_error)
    end
  end

  local active = {}
  local iterator, directory_error = vim.fs.dir(self.path)
  if not iterator then
    vim.fn.delete(claim_path)
    return nil, 'failed to inspect recovery claims: ' .. tostring(directory_error)
  end
  for name in iterator do
    local claimant_pid = tonumber(name:match '^recovery%.(%d+)%..+$')
    if claimant_pid then
      local path = vim.fs.joinpath(self.path, name)
      if path == claim_path then
        active[#active + 1] = name
      else
        local alive = self.pid_alive(claimant_pid)
        if alive == false then
          vim.fn.delete(path)
        else
          active[#active + 1] = name
        end
      end
    end
  end
  table.sort(active)
  if active[1] ~= vim.fs.basename(claim_path) then
    vim.fn.delete(claim_path)
    return nil, 'recovery marker claim is held by another process'
  end
  return claim_path
end

function Lock:_remove_verified_owner(expected)
  local claim_path, claim_error = self:_claim_removal(expected)
  if not claim_path then
    return false, claim_error
  end
  local current = self:_read_owner()
  if not owner_matches(current, expected) then
    vim.fn.delete(claim_path)
    return false, 'owner changed before removal'
  end

  local quarantine = self.make_quarantine(self.path, self.pid)
  local renamed, rename_error = vim.uv.fs_rename(self.path, quarantine)
  if not renamed then
    vim.fn.delete(claim_path)
    return false, rename_error
  end

  local quarantined = self:_read_owner_at(quarantine)
  if not owner_matches(quarantined, expected) then
    vim.uv.fs_rename(quarantine, self.path)
    vim.fn.delete(claim_path)
    return false, 'owner changed during removal'
  end

  local owner_path = vim.fs.joinpath(quarantine, 'owner.json')
  if vim.fn.delete(owner_path) ~= 0 then
    return false, 'failed to remove quarantined owner'
  end
  for name in vim.fs.dir(quarantine) do
    if name:match '^recovery%.%d+%..+$' then
      vim.fn.delete(vim.fs.joinpath(quarantine, name))
    end
  end
  local removed, remove_error = vim.uv.fs_rmdir(quarantine)
  return removed ~= nil, remove_error
end

function Lock:acquire(recovering)
  vim.fn.mkdir(self.dir, 'p')
  local token, publish_error = self:_publish()
  if token then
    return token
  end

  if not vim.uv.fs_stat(self.path) then
    return nil, 'failed to publish toolchain lock: ' .. tostring(publish_error)
  end
  local owner = self:_read_owner()
  if not owner or type(owner.pid) ~= 'number' or type(owner.token) ~= 'string' then
    return nil, 'locked: owner PID cannot be verified'
  end

  local alive = self.pid_alive(owner.pid)
  if alive == true then
    return nil, ('locked by pid %d'):format(owner.pid)
  end
  if alive ~= false then
    return nil, ('locked: pid %d could not be verified'):format(owner.pid)
  end
  if recovering then
    return nil, 'locked: stale recovery failed'
  end

  if self.before_recover then
    local hooked, hook_error = pcall(self.before_recover, owner)
    if not hooked then
      return nil, 'failed to prepare stale recovery: ' .. tostring(hook_error)
    end
  end
  local removed, remove_error = self:_remove_verified_owner(owner)
  if not removed then
    return nil, 'failed to recover stale lock: ' .. tostring(remove_error)
  end
  return self:acquire(true)
end

local function retryable_contention(message)
  message = tostring(message or '')
  return message:find('locked by pid', 1, true) ~= nil
    or message:find('recovery marker claim is held', 1, true) ~= nil
    or message:find('owner changed', 1, true) ~= nil
    or message:find('failed to publish toolchain lock', 1, true) ~= nil
end

function Lock:acquire_wait(options)
  options = options or {}
  local timeout_ms = math.max(0, tonumber(options.timeout_ms) or 0)
  local poll_ms = math.max(1, tonumber(options.poll_ms) or 100)
  local clock_ms = options.clock_ms or function()
    return math.floor(vim.uv.hrtime() / 1000000)
  end
  local sleep = options.sleep or function(milliseconds)
    vim.wait(milliseconds, function()
      return false
    end, milliseconds)
  end
  local deadline = clock_ms() + timeout_ms

  while true do
    local token, lock_error = self:acquire()
    if token then
      return token
    end
    if not retryable_contention(lock_error) then
      return nil, lock_error
    end
    local remaining = deadline - clock_ms()
    if remaining <= 0 then
      return nil, ('timed out waiting for toolchain lock after %d ms: %s'):format(timeout_ms, tostring(lock_error))
    end
    local slept, sleep_error = pcall(sleep, math.min(poll_ms, remaining))
    if not slept then
      return nil, 'failed while waiting for toolchain lock: ' .. tostring(sleep_error)
    end
  end
end

function Lock:release(token)
  local owner = self:_read_owner()
  if not owner or owner.token ~= token then
    return false
  end
  return self:_remove_verified_owner(owner)
end

local M = {}

function M.new(options)
  options = options or {}
  local dir = options.dir or default_dir()
  local path = options.path or vim.fs.joinpath(dir, 'install.lock')
  return setmetatable({
    dir = dir,
    path = path,
    owner_path = vim.fs.joinpath(path, 'owner.json'),
    pid = options.pid or vim.uv.os_getpid(),
    pid_alive = options.pid_alive or default_pid_alive,
    make_token = options.token or default_token,
    make_quarantine = options.quarantine or default_quarantine,
    make_claim = options.claim or default_claim,
    make_candidate = options.candidate or default_candidate,
    before_recover = options.before_recover,
    after_marker = options.after_marker,
    before_publish = options.before_publish,
    now = options.now or os.time,
  }, Lock)
end

return M
