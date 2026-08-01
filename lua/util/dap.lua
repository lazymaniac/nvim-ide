local M = {}

local function selected_python()
  local ok, selector = pcall(require, 'venv-selector')
  if not ok or type(selector.python) ~= 'function' then return nil end
  return selector.python()
end

function M.resolve_python(overrides)
  local opts = overrides or {}
  local env = opts.env or vim.env
  local executable = opts.executable or function(path)
    return vim.fn.executable(path) == 1
  end
  local exepath = opts.exepath or vim.fn.exepath
  local selected = opts.selected or selected_python
  local project = require 'nv_ide.project'
  local target = opts.target == nil and 0 or opts.target
  local cwd = type(opts.cwd) == 'function' and opts.cwd() or opts.cwd
  cwd = cwd or project.root(target, { 'pyproject.toml', 'setup.cfg', 'tox.ini', '.git' })
  if not cwd then
    local path = type(target) == 'number' and vim.api.nvim_buf_get_name(target) or target
    cwd = path and path ~= '' and vim.fs.dirname(vim.fs.normalize(path)) or vim.fn.getcwd()
  end
  local activated = {}
  local selected_path = selected()
  if selected_path then activated[#activated + 1] = selected_path end
  if env.VIRTUAL_ENV then
    activated[#activated + 1] = vim.fs.joinpath(env.VIRTUAL_ENV, 'bin', 'python')
  end
  local path = project.executable(cwd, {
    activated = activated,
    project = { '.venv/bin/python', 'venv/bin/python' },
    ambient = { 'python3', 'python' },
  }, {
    executable = executable,
    exepath = exepath,
  })
  if path then return path end
  error('No executable Python interpreter was found for nvim-dap-python', 0)
end

return M
