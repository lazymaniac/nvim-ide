local State = {}
State.__index = State

local function has_missing(missing)
  for _, value in pairs(missing or {}) do
    if type(value) == 'table' then
      if next(value) ~= nil then return true end
    elseif value then
      return true
    end
  end
  return false
end

local function default_dir()
  return vim.fs.joinpath(vim.fn.stdpath 'state', 'nv_ide', 'toolchain')
end

function State:read()
  if vim.fn.filereadable(self.path) ~= 1 then return nil end
  local lines = vim.fn.readfile(self.path, 'b')
  if #lines == 0 then return nil end
  local ok, decoded = pcall(vim.json.decode, table.concat(lines, '\n'))
  return ok and type(decoded) == 'table' and decoded or nil
end

function State:write(value)
  vim.fn.mkdir(self.dir, 'p')
  local suffix = ('%d-%d'):format(vim.uv.os_getpid(), vim.uv.hrtime())
  local temporary = self.path .. '.tmp-' .. suffix
  local encoded = vim.json.encode(value)
  local wrote = vim.fn.writefile({ encoded }, temporary, 'b')
  if wrote ~= 0 then error('failed to write toolchain state temporary file: ' .. temporary) end

  local renamed, rename_error = vim.uv.fs_rename(temporary, self.path)
  if not renamed then
    vim.fn.delete(temporary)
    error('failed to replace toolchain state: ' .. tostring(rename_error))
  end
  return true
end

function State:is_current(value, schema_version, fingerprint)
  return type(value) == 'table'
    and value.schema_version == schema_version
    and value.fingerprint == fingerprint
end

function State:should_run(value, options)
  options = options or {}
  if options.repair or options.force or has_missing(options.missing) then return true end
  if not self:is_current(value, options.schema_version, options.fingerprint) then return true end
  if value.status ~= 'success' or type(value.last_success) ~= 'number' then return true end
  local debounce = options.debounce_seconds or 0
  return self.now() - value.last_success >= debounce
end

local M = {}

function M.new(options)
  options = options or {}
  local dir = options.dir or default_dir()
  return setmetatable({
    dir = dir,
    path = options.path or vim.fs.joinpath(dir, 'state.json'),
    now = options.now or os.time,
  }, State)
end

return M
