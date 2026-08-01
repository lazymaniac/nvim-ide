local M = {}

local function failure(message, checks)
  return {
    ok = false,
    checks = checks or {},
    errors = { tostring(message) },
  }
end

local function validate_lockfile(path)
  local file, open_error = io.open(path, 'rb')
  if not file then
    return false, 'cannot read resolved lockfile: ' .. tostring(open_error)
  end
  local contents = file:read '*a'
  file:close()
  local decoded_ok, decoded = pcall(vim.json.decode, contents)
  if not decoded_ok or type(decoded) ~= 'table' then
    return false, 'resolved lockfile is not valid JSON'
  end
  if type(decoded['lazy.nvim']) ~= 'table' then
    return false, 'resolved lockfile is missing lazy.nvim'
  end
  for name, entry in pairs(decoded) do
    if type(entry) ~= 'table' or type(entry.branch) ~= 'string' or entry.branch == '' then
      return false, ('resolved lockfile has no branch for %s'):format(name)
    end
    if type(entry.commit) ~= 'string' or not entry.commit:match '^[0-9a-fA-F][0-9a-fA-F]+$' or #entry.commit ~= 40 then
      return false, ('resolved lockfile has an invalid commit for %s'):format(name)
    end
  end
  return true
end

function M.publish(options)
  options = options or {}
  if not options.smoke or type(options.smoke.run) ~= 'function' then
    return failure 'fresh-startup smoke is unavailable'
  end
  if type(options.source) ~= 'string' or options.source == '' then
    return failure 'resolved lockfile source is missing'
  end
  if type(options.destination) ~= 'string' or options.destination == '' then
    return failure 'resolved lockfile destination is missing'
  end

  local source = vim.fs.normalize(options.source)
  local destination = vim.fs.normalize(options.destination)
  if source == destination then
    return failure 'resolved lockfile destination must differ from its source'
  end

  if vim.uv.fs_stat(destination) then
    local removed, remove_error = vim.uv.fs_unlink(destination)
    if not removed then
      return failure('cannot remove stale resolved lockfile: ' .. tostring(remove_error))
    end
  end

  local valid, validation_error = validate_lockfile(source)
  if not valid then
    return failure(validation_error)
  end

  local smoke = options.smoke:run()
  if type(smoke) ~= 'table' or smoke.ok ~= true then
    local errors = type(smoke) == 'table' and smoke.errors or nil
    return {
      ok = false,
      checks = type(smoke) == 'table' and vim.deepcopy(smoke.checks or {}) or {},
      errors = type(errors) == 'table' and vim.deepcopy(errors) or { 'fresh-startup smoke failed' },
    }
  end

  vim.fn.mkdir(vim.fs.dirname(destination), 'p')
  local copied, copy_error = vim.uv.fs_copyfile(source, destination)
  if not copied then
    return failure('cannot publish resolved lockfile: ' .. tostring(copy_error), smoke.checks)
  end
  return {
    ok = true,
    checks = vim.deepcopy(smoke.checks or {}),
    destination = destination,
  }
end

return M
