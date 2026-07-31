local M = {}

local function selected_python()
  local ok, selector = pcall(require, 'venv-selector')
  if not ok or type(selector.python) ~= 'function' then return nil end
  return selector.python()
end

local function absolute(path, cwd)
  if not path or path == '' then return nil end
  if vim.fn.isabsolutepath(path) == 1 then return vim.fs.normalize(path) end
  return vim.fs.normalize(vim.fs.joinpath(cwd, path))
end

function M.resolve_python(overrides)
  local opts = overrides or {}
  local env = opts.env or vim.env
  local cwd = type(opts.cwd) == 'function' and opts.cwd() or opts.cwd or vim.fn.getcwd()
  local executable = opts.executable or function(path)
    return vim.fn.executable(path) == 1
  end
  local exepath = opts.exepath or vim.fn.exepath
  local selected = opts.selected or selected_python
  local candidates = {}
  local function add(path)
    if path and path ~= '' then candidates[#candidates + 1] = path end
  end

  add(selected())
  if env.VIRTUAL_ENV then add(vim.fs.joinpath(env.VIRTUAL_ENV, 'bin', 'python')) end
  add(vim.fs.joinpath(cwd, '.venv', 'bin', 'python'))
  add(vim.fs.joinpath(cwd, 'venv', 'bin', 'python'))
  add(exepath 'python3')
  add(exepath 'python')

  for _, candidate in ipairs(candidates) do
    local path = absolute(candidate, cwd)
    if path and executable(path) then return path end
  end

  error('No executable Python interpreter was found for nvim-dap-python', 0)
end

return M
