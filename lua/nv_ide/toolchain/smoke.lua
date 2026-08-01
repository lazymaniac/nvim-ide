local Smoke = {}
Smoke.__index = Smoke

local function lockfile_check(path)
  return {
    name = 'lockfile',
    run = function()
      if vim.fn.filereadable(path) ~= 1 then
        return false, 'Lazy lockfile is missing: ' .. path
      end
      local contents = table.concat(vim.fn.readfile(path, 'b'), '\n')
      local ok, decoded = pcall(vim.json.decode, contents)
      if not ok or type(decoded) ~= 'table' then
        return false, 'Lazy lockfile is not valid JSON'
      end
      return true
    end,
  }
end

local function syntax_check(root)
  return {
    name = 'lua-syntax',
    run = function()
      for _, path in ipairs(vim.fn.glob(vim.fs.joinpath(root, '**', '*.lua'), false, true)) do
        local chunk, load_error = loadfile(path)
        if not chunk then
          return false, ('%s: %s'):format(path, tostring(load_error))
        end
      end
      return true
    end,
  }
end

local function lazy_check()
  return {
    name = 'lazy-state',
    run = function()
      local ok_config, config = pcall(require, 'lazy.core.config')
      local ok_plugin, plugin = pcall(require, 'lazy.core.plugin')
      if not ok_config or not ok_plugin then
        return false, 'Lazy runtime is unavailable'
      end
      local failures = {}
      for name, spec in pairs(config.plugins or {}) do
        if plugin.has_errors(spec) then
          failures[#failures + 1] = name .. ' has update errors'
        elseif spec.url and not spec._.installed then
          failures[#failures + 1] = name .. ' is not installed'
        end
      end
      table.sort(failures)
      return #failures == 0, table.concat(failures, '; ')
    end,
  }
end

local function isolated_startup_check(root, options)
  local init = vim.fs.joinpath(root, 'init.lua')
  local composition = [[lua local ok, err = pcall(function()
    local gopls = assert(vim.lsp.config.gopls, 'gopls configuration was not composed')
    local clangd = assert(vim.lsp.config.clangd, 'clangd configuration was not composed')
    local vtsls = assert(vim.lsp.config.vtsls, 'vtsls configuration was not composed')
    assert(gopls.settings.gopls.gofumpt == true, 'gopls settings were not composed')
    assert(vim.tbl_contains(clangd.cmd, '--background-index'), 'clangd command was not composed')
    assert(vtsls.settings.vtsls.autoUseWorkspaceTsdk == true, 'vtsls settings were not composed')
  end); if not ok then vim.api.nvim_err_writeln(tostring(err)); vim.cmd('cquit 1') end]]
  local function command()
    return {
      options.nvim,
      '--headless',
      '-u',
      init,
      '-i',
      'NONE',
      '--cmd',
      'set shortmess+=I',
      '-c',
      'edit ' .. vim.fn.fnameescape(init),
      '-c',
      composition,
      '-c',
      'qa',
    }
  end

  local function process_options(run_options)
    local env = { NVIM_TOOLCHAIN_AUTORUN = '0' }
    local owner = run_options and run_options.lock_owner
    if type(owner) == 'table' and type(owner.pid) == 'number' and type(owner.token) == 'string' then
      env.NV_IDE_TOOLCHAIN_READONLY_CHILD = '1'
      env.NV_IDE_TOOLCHAIN_PARENT_LOCK_PID = tostring(owner.pid)
      env.NV_IDE_TOOLCHAIN_PARENT_LOCK_TOKEN = owner.token
    end
    return {
      cwd = root,
      text = true,
      timeout = options.timeout_ms,
      env = env,
    }
  end

  local function evaluate(result)
    if type(result) ~= 'table' then
      return false, 'fresh startup result is unavailable'
    end
    if result.code ~= 0 then
      local detail = vim.trim(result.stderr or result.stdout or '')
      if detail == '' then
        detail = 'exit code ' .. tostring(result.code)
      end
      return false, detail
    end
    return true
  end

  return {
    name = 'isolated-startup',
    run = function(run_options)
      local spawned, process = pcall(options.system, command(), process_options(run_options))
      if not spawned then
        return false, tostring(process)
      end
      local waited, result = pcall(process.wait, process)
      if not waited then
        return false, tostring(result)
      end
      return evaluate(result)
    end,
    run_async = function(done, run_options)
      local settled = false
      local function finish(result)
        if settled then
          return
        end
        settled = true
        done(evaluate(result))
      end
      local spawned, process = pcall(options.system, command(), process_options(run_options), finish)
      if not spawned then
        settled = true
        done(false, tostring(process))
      elseif type(process) ~= 'table' then
        settled = true
        done(false, 'fresh startup process handle is unavailable')
      end
    end,
  }
end

function Smoke:run(options)
  options = options or {}
  local passed, errors = {}, {}
  if options.wait == false then
    local index = 0
    local completed
    local function finish()
      completed = { ok = #errors == 0, checks = passed, errors = errors }
      if options.on_complete then
        options.on_complete(completed)
      end
    end
    local function advance()
      index = index + 1
      local check = self.checks[index]
      if not check then
        finish()
        return
      end
      local settled = false
      local function settle(ok, detail)
        if settled then
          return
        end
        if vim.in_fast_event() then
          vim.schedule(function()
            settle(ok, detail)
          end)
          return
        end
        settled = true
        if ok == false then
          errors[#errors + 1] = ('%s: %s'):format(check.name, detail or 'failed')
        else
          passed[#passed + 1] = check.name
        end
        advance()
      end
      if check.run_async then
        local started, start_error = pcall(check.run_async, settle, options)
        if not started then
          settle(false, tostring(start_error))
        end
      else
        local ok, result, detail = pcall(check.run, options)
        if not ok then
          settle(false, tostring(result))
        else
          settle(result, detail)
        end
      end
    end
    advance()
    return completed or { ok = true, pending = true, checks = vim.deepcopy(passed), errors = vim.deepcopy(errors) }
  end

  for _, check in ipairs(self.checks) do
    local ok, result, detail = pcall(check.run, options)
    if not ok then
      errors[#errors + 1] = ('%s: %s'):format(check.name, tostring(result))
    elseif result == false then
      errors[#errors + 1] = ('%s: %s'):format(check.name, detail or 'failed')
    else
      passed[#passed + 1] = check.name
    end
  end
  return { ok = #errors == 0, checks = passed, errors = errors }
end

local M = {}

function M.new(options)
  options = options or {}
  local lockfile = options.lockfile or vim.fs.joinpath(vim.fn.stdpath 'config', 'lazy-lock.json')
  local root = options.root or vim.fn.stdpath 'config'
  local isolated_options = {
    nvim = options.nvim or vim.v.progpath,
    system = options.system or vim.system,
    timeout_ms = options.timeout_ms or 30000,
  }
  return setmetatable({
    checks = options.checks or {
      lockfile_check(lockfile),
      syntax_check(root),
      lazy_check(),
      isolated_startup_check(root, isolated_options),
    },
  }, Smoke)
end

return M
