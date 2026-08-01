local M = {}

local core = {
  'blankline', 'blink', 'cmp', 'colors', 'defaults', 'devicons', 'git', 'lsp',
  'mason', 'notify', 'nvcheatsheet', 'nvimtree', 'statusline', 'syntax', 'tbline',
  'telescope', 'term', 'treesitter', 'whichkey',
}

local regeneration = 'regenerate with :lua require("base46").compile()'

function M.allowed(integrations)
  local names = {}
  local seen = {}
  for _, name in ipairs(vim.list_extend(vim.deepcopy(core), integrations or {})) do
    if type(name) ~= 'string' or not name:match('^[%w_-]+$') then
      error('Invalid Base46 cache entry name: ' .. vim.inspect(name), 0)
    end
    if not seen[name] then
      seen[name] = true
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

function M.load(opts)
  opts = opts or {}
  local requested_dir = vim.fs.normalize(assert(opts.dir, 'Base46 cache directory is required'))
  local realpath = opts.realpath or vim.uv.fs_realpath
  local lstat = opts.fs_lstat or vim.uv.fs_lstat
  local dir = realpath(requested_dir)
  if not dir then
    error('Base46 cache directory is missing; ' .. regeneration, 0)
  end
  dir = vim.fs.normalize(dir)

  local paths = {}
  for _, name in ipairs(M.allowed(opts.integrations)) do
    local lexical_path = vim.fs.joinpath(requested_dir, name)
    local stat = lstat(lexical_path)
    if not stat or stat.type ~= 'file' then
      error(('Invalid Base46 cache entry %q: expected a regular file; %s'):format(name, regeneration), 0)
    end
    local path = realpath(lexical_path)
    path = path and vim.fs.normalize(path) or nil
    if not path or vim.fs.dirname(path) ~= dir then
      error(('Invalid Base46 cache entry %q: path escapes the cache directory; %s'):format(name, regeneration), 0)
    end
    paths[#paths + 1] = { name = name, path = path }
  end

  local execute = opts.execute or dofile
  for _, entry in ipairs(paths) do
    local ok, err = pcall(execute, entry.path)
    if not ok then
      error(('Failed to execute Base46 cache entry %q: %s; %s'):format(entry.name, tostring(err), regeneration), 0)
    end
  end
end

return M
