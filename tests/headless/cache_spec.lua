local h = require 'tests.headless.harness'

local function load_cache()
  package.loaded['nv_ide.cache'] = nil
  return require 'nv_ide.cache'
end

local integrations = { 'dap', 'treesitter', 'whichkey' }

local function write_allowed(cache, dir)
  local names = cache.allowed(integrations)
  for _, name in ipairs(names) do
    vim.fn.writefile({ 'return true' }, vim.fs.joinpath(dir, name))
  end
  return names
end

h.describe('Base46 cache loading', function()
  h.it('executes only sorted allowlisted regular files', function()
    h.with_temp_dir(function(tmp)
      local cache = load_cache()
      local names = write_allowed(cache, tmp)
      vim.fn.writefile({ 'return false' }, vim.fs.joinpath(tmp, 'stale-arbitrary-entry'))
      local executed = {}

      cache.load {
        dir = tmp,
        integrations = integrations,
        execute = function(path) executed[#executed + 1] = path end,
      }

      local canonical = assert(vim.uv.fs_realpath(tmp))
      local expected = vim.tbl_map(function(name)
        return vim.fs.joinpath(canonical, name)
      end, names)
      h.deep_equal(executed, expected)
      h.falsy(vim.tbl_contains(vim.tbl_map(vim.fs.basename, executed), 'stale-arbitrary-entry'))
    end)
  end)

  h.it('rejects a named directory with actionable regeneration guidance', function()
    h.with_temp_dir(function(tmp)
      local cache = load_cache()
      write_allowed(cache, tmp)
      local dap = vim.fs.joinpath(tmp, 'dap')
      h.equal(vim.fn.delete(dap), 0)
      h.equal(vim.fn.mkdir(dap), 1)

      local ok, err = pcall(cache.load, {
        dir = tmp,
        integrations = integrations,
        execute = function() error 'must not execute an invalid cache' end,
      })
      h.falsy(ok)
      h.matches(err, 'dap')
      h.matches(err, 'require("base46").compile()')
    end)
  end)

  h.it('stops at an execution failure and names the corrupt entry', function()
    h.with_temp_dir(function(tmp)
      local cache = load_cache()
      write_allowed(cache, tmp)
      local executed = {}
      local ok, err = pcall(cache.load, {
        dir = tmp,
        integrations = { 'dap' },
        execute = function(path)
          local name = vim.fs.basename(path)
          if name == 'dap' then error 'corrupt bytecode' end
          executed[#executed + 1] = name
        end,
      })

      h.falsy(ok)
      h.matches(err, 'dap')
      h.matches(err, 'corrupt bytecode')
      h.matches(err, 'require("base46").compile()')
      h.falsy(vim.tbl_contains(executed, 'defaults'), 'loading must stop after the failing entry')
    end)
  end)
end)
