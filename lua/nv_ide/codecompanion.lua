local M = {}

local project_filename = '.codecompanion.lua'

local function evaluate(contents, path)
  local chunk, err = loadstring(contents, '@' .. path)
  if not chunk then
    error('failed to compile trusted CodeCompanion config: ' .. err, 0)
  end

  local ok, result = pcall(chunk)
  if not ok then
    error('failed to evaluate trusted CodeCompanion config: ' .. result, 0)
  end
  if type(result) ~= 'table' then
    error('trusted CodeCompanion config must return a table', 0)
  end
  return result
end

function M.resolve(base, options)
  options = options or {}
  local cwd = options.cwd or vim.fn.getcwd()
  local path = vim.fs.joinpath(cwd, project_filename)
  local secure_read = options.secure_read or vim.secure.read

  if not options.secure_read and not vim.uv.fs_stat(path) then return vim.deepcopy(base) end

  local ok, contents = pcall(secure_read, path)
  if not ok or not contents then return vim.deepcopy(base) end

  local project = (options.evaluate or evaluate)(contents, path)
  if type(project) ~= 'table' then error('trusted CodeCompanion config must return a table', 0) end
  return vim.tbl_deep_extend('force', vim.deepcopy(base), project)
end

return M
