local Lock = {}
Lock.__index = Lock

local function default_dir()
  return vim.fs.joinpath(vim.fn.stdpath 'state', 'nv_ide', 'toolchain')
end

local function default_pid_alive(pid)
  if type(pid) ~= 'number' or pid <= 0 then return nil end
  local ok, result, error_name = pcall(vim.uv.kill, pid, 0)
  if not ok then return nil end
  if result == 0 then return true end
  if tostring(error_name):find('ESRCH', 1, true) then return false end
  return nil
end

local function default_token(pid)
  return vim.fn.sha256(('%d:%d:%s'):format(pid, vim.uv.hrtime(), tostring({})))
end

function Lock:_read_owner()
  if vim.fn.filereadable(self.owner_path) ~= 1 then return nil end
  local ok, owner = pcall(vim.json.decode, table.concat(vim.fn.readfile(self.owner_path, 'b'), '\n'))
  return ok and type(owner) == 'table' and owner or nil
end

function Lock:_write_owner(owner)
  return vim.fn.writefile({ vim.json.encode(owner) }, self.owner_path, 'b') == 0
end

function Lock:_remove_verified_owner()
  if vim.fn.filereadable(self.owner_path) == 1 then vim.fn.delete(self.owner_path) end
  local removed, remove_error = vim.uv.fs_rmdir(self.path)
  return removed ~= nil, remove_error
end

function Lock:acquire(recovering)
  vim.fn.mkdir(self.dir, 'p')
  local created, create_error = vim.uv.fs_mkdir(self.path, 448)
  if created then
    local token = self.make_token(self.pid)
    local owner = { pid = self.pid, token = token, acquired_at = self.now() }
    if not self:_write_owner(owner) then
      vim.uv.fs_rmdir(self.path)
      return nil, 'failed to write lock owner'
    end
    return token
  end

  if not vim.uv.fs_stat(self.path) then
    return nil, 'failed to create toolchain lock: ' .. tostring(create_error)
  end
  local owner = self:_read_owner()
  if not owner or type(owner.pid) ~= 'number' or type(owner.token) ~= 'string' then
    return nil, 'locked: owner PID cannot be verified'
  end

  local alive = self.pid_alive(owner.pid)
  if alive == true then return nil, ('locked by pid %d'):format(owner.pid) end
  if alive ~= false then return nil, ('locked: pid %d could not be verified'):format(owner.pid) end
  if recovering then return nil, 'locked: stale recovery failed' end

  local removed, remove_error = self:_remove_verified_owner()
  if not removed then return nil, 'failed to recover stale lock: ' .. tostring(remove_error) end
  return self:acquire(true)
end

function Lock:release(token)
  local owner = self:_read_owner()
  if not owner or owner.token ~= token then return false end
  return self:_remove_verified_owner()
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
    now = options.now or os.time,
  }, Lock)
end

return M
