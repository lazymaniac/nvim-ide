local M = {}

local SOURCE_RECEIPT_PREFIX = 'nv-ide-ts-v1:source-sha256:'
local SOURCE_RECEIPT_SUFFIX = '.nv-ide-receipt'

local function load_dependency(provided, name)
  if provided then
    return provided
  end
  return require(name)
end

local function trim(value)
  return type(value) == 'string' and vim.trim(value) or ''
end

local function read(path)
  local ok, lines = pcall(vim.fn.readfile, path, 'b')
  if not ok then
    return nil
  end
  return vim.trim(table.concat(lines, '\n'))
end

local function source_files(root, directory, result)
  local entries = {}
  local ok, iterator = pcall(vim.fs.dir, directory)
  if not ok then
    return nil, tostring(iterator)
  end
  for name, kind in iterator do
    entries[#entries + 1] = { name = name, kind = kind }
  end
  table.sort(entries, function(left, right)
    return left.name < right.name
  end)

  for _, entry in ipairs(entries) do
    local path = vim.fs.joinpath(directory, entry.name)
    if entry.kind == 'directory' then
      local walked, walk_error = source_files(root, path, result)
      if not walked then
        return nil, walk_error
      end
    elseif entry.kind == 'file' or entry.kind == 'link' then
      local readable, lines = pcall(vim.fn.readfile, path, 'b')
      if not readable then
        return nil, ('cannot read parser source %s: %s'):format(path, tostring(lines))
      end
      local relative = path:sub(#root + 2)
      result[#result + 1] = ('%s\0%s'):format(relative, vim.fn.sha256(table.concat(lines, '\n')))
    end
  end
  return result
end

local function source_evidence(path)
  local source = vim.fs.joinpath(vim.fs.normalize(path), 'src')
  local stat = vim.uv.fs_stat(source)
  if not stat or stat.type ~= 'directory' then
    return nil, 'local parser source directory is unavailable: ' .. source
  end
  local files, source_error = source_files(source, source, {})
  if not files then
    return nil, source_error
  end
  if #files == 0 then
    return nil, 'local parser source directory is empty: ' .. source
  end
  return SOURCE_RECEIPT_PREFIX .. vim.fn.sha256(table.concat(files, '\n'))
end

local function local_path(info)
  local path = trim(info.path)
  if path == '' then
    local url = trim(info.url)
    if url ~= '' and not url:match '^%a[%w+%.%-]*://' and vim.uv.fs_stat(vim.fs.normalize(url)) then
      path = url
    end
  end
  if path == '' then
    return nil
  end
  path = vim.fs.normalize(path)
  if trim(info.location) ~= '' then
    path = vim.fs.joinpath(path, info.location)
  end
  return path
end

function M.expected(name, options)
  options = options or {}
  local loaded, registry = pcall(load_dependency, options.parser_registry, 'nvim-treesitter.parsers')
  if not loaded or type(registry) ~= 'table' then
    return nil, 'parser provider registry is unavailable: ' .. tostring(registry)
  end
  local parser = registry[name]
  local info = type(parser) == 'table' and parser.install_info or nil
  if type(info) ~= 'table' then
    return nil, 'parser provider is unavailable: ' .. tostring(name)
  end

  local path = local_path(info)
  if path then
    local evidence, evidence_error = source_evidence(path)
    if not evidence then
      return nil, evidence_error
    end
    return { kind = 'source', value = evidence, provider = path }
  end

  local revision = trim(info.revision)
  if revision == '' and trim(info.url) ~= '' then
    revision = trim(info.branch)
    if revision == '' then
      revision = 'main'
    end
  end
  if revision == '' then
    return nil, 'parser provider revision is unavailable: ' .. tostring(name)
  end
  return { kind = 'revision', value = revision }
end

function M.path(name, kind, options)
  options = options or {}
  local config = load_dependency(options.config, 'nvim-treesitter.config')
  local directory = config.get_install_dir 'parser-info'
  local suffix = kind == 'source' and SOURCE_RECEIPT_SUFFIX or '.revision'
  return vim.fs.joinpath(directory, name .. suffix)
end

function M.inspect(name, installed, options)
  if not installed then
    return { status = 'missing' }
  end
  options = options or {}
  local expected = M.expected(name, options)
  if not expected then
    return { status = 'failed' }
  end
  local actual = read(M.path(name, expected.kind, options))
  if actual ~= expected.value then
    return { status = 'failed' }
  end
  return { status = 'installed', revision = actual }
end

local function atomic_write(path, value, options)
  options = options or {}
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  local temporary = path .. ('.tmp-%d-%d'):format(vim.uv.os_getpid(), vim.uv.hrtime())
  local written, write_error = pcall(vim.fn.writefile, { value }, temporary, 'b')
  if not written or write_error ~= 0 then
    pcall(vim.fn.delete, temporary)
    return nil, 'cannot stage parser receipt: ' .. tostring(write_error)
  end
  local renamed, rename_error = (options.rename or vim.uv.fs_rename)(temporary, path)
  if not renamed then
    pcall(vim.fn.delete, temporary)
    return nil, 'cannot publish parser receipt: ' .. tostring(rename_error)
  end
  return true
end

function M.persist(name, options)
  options = options or {}
  local expected, expected_error = M.expected(name, options)
  if not expected then
    return nil, expected_error
  end
  if expected.kind ~= 'source' then
    return true
  end
  return atomic_write(M.path(name, expected.kind, options), expected.value, options)
end

function M.complete(config, parser_registry)
  config = config or require 'nvim-treesitter.config'
  local result = {}
  for _, name in ipairs(config.get_installed 'parsers') do
    if M.inspect(name, true, { config = config, parser_registry = parser_registry }).status == 'installed' then
      result[#result + 1] = name
    end
  end
  return result
end

return M
