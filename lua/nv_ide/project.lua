local M = {}

M.markers = {
  'package.json', 'pyproject.toml', 'setup.cfg', 'tox.ini',
  'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts',
  'pom.xml', '.git',
}

local trust_cache = {}
local js_configs = {
  jest = { 'jest.config.ts', 'jest.config.js', 'jest.config.mjs', 'jest.config.cjs' },
  mocha = { '.mocharc.js', '.mocharc.cjs', '.mocharc.mjs', '.mocharc.json' },
  karma = { 'karma.conf.js', 'karma.conf.cjs', 'karma.conf.ts' },
  jasmine = { 'spec/support/jasmine.json', 'spec/support/jasmine.mjs' },
}
local js_bins = { 'jest', 'mocha', 'karma', 'jasmine' }

local function path_from_target(target)
  if type(target) == 'number' then return vim.api.nvim_buf_get_name(target) end
  return target
end

local function existing(path, stat)
  return path and stat(path) ~= nil
end

function M.root(target, markers, deps)
  deps = deps or {}
  local stat = deps.stat or vim.uv.fs_stat
  local find_root = deps.find_root or vim.fs.root
  local realpath = deps.realpath or vim.uv.fs_realpath
  local path = vim.fs.normalize(assert(path_from_target(target), 'project target is required'))
  local path_stat = stat(path)
  local start = path_stat and path_stat.type == 'directory' and path or vim.fs.dirname(path)
  local root = find_root(start, markers or M.markers)
  return root and vim.fs.normalize(realpath(root) or root) or nil
end

function M.contains(root, path)
  root, path = vim.fs.normalize(root), vim.fs.normalize(path)
  local relative = vim.fs.relpath(root, path)
  return relative ~= nil and relative ~= '..' and not vim.startswith(relative, '../')
end

function M.executable(root, candidates, deps)
  deps = deps or {}
  local executable = deps.executable or function(path) return vim.fn.executable(path) == 1 end
  local exepath = deps.exepath or vim.fn.exepath
  for _, path in ipairs(candidates.activated or {}) do
    if path and path ~= '' and executable(path) then return vim.fs.normalize(path) end
  end
  for _, relative in ipairs(candidates.project or {}) do
    local path = vim.fs.joinpath(root, relative)
    if executable(path) then return vim.fs.normalize(path) end
  end
  for _, command in ipairs(candidates.ambient or {}) do
    local path = exepath(command)
    if path and path ~= '' and executable(path) then return vim.fs.normalize(path) end
  end
end

function M.javascript(target, deps)
  deps = deps or {}
  local stat = deps.stat or vim.uv.fs_stat
  local executable = deps.executable or function(path) return vim.fn.executable(path) == 1 end
  local root = M.root(target, { 'package.json' }, deps)
  if not root then return { configs = {}, executables = {} } end
  local workspace_root = M.root(target, { '.git' }, deps) or root
  local roots, cursor = {}, root
  while cursor and M.contains(workspace_root, cursor) do
    roots[#roots + 1] = cursor
    if cursor == workspace_root then break end
    local parent = vim.fs.dirname(cursor)
    if parent == cursor then break end
    cursor = parent
  end

  local function first(names)
    for _, directory in ipairs(roots) do
      for _, name in ipairs(names) do
        local path = vim.fs.joinpath(directory, name)
        if existing(path, stat) then return path end
      end
    end
  end
  local managers = {
    { 'pnpm-lock.yaml', 'pnpm' }, { 'yarn.lock', 'yarn' },
    { 'bun.lockb', 'bun' }, { 'bun.lock', 'bun' }, { 'package-lock.json', 'npm' },
  }
  local manager
  for _, directory in ipairs(roots) do
    for _, item in ipairs(managers) do
      if existing(vim.fs.joinpath(directory, item[1]), stat) then manager = item[2]; break end
    end
    if manager then break end
  end
  local executables = {}
  for _, name in ipairs(js_bins) do
    for _, directory in ipairs(roots) do
      local path = vim.fs.joinpath(directory, 'node_modules', '.bin', name)
      if executable(path) then executables[name] = path; break end
    end
  end
  local configs = {}
  for name, candidates in pairs(js_configs) do
    configs[name] = first(candidates)
  end
  return {
    root = root,
    workspace_root = workspace_root,
    package_manager = manager,
    package_json = vim.fs.joinpath(root, 'package.json'),
    launch_json = first { '.vscode/launch.json' },
    configs = configs,
    executables = executables,
  }
end

function M.trusted(root, deps)
  deps = deps or {}
  local cache = deps.cache or trust_cache
  root = vim.fs.normalize(root)
  if cache[root] == true then return true end
  local secure_read = deps.secure_read or vim.secure.read
  local ok, trusted = pcall(secure_read, root)
  if ok and trusted == true then cache[root] = true; return true end
  return false
end

return M
