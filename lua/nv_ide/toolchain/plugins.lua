local Plugins = {}
Plugins.__index = Plugins

local ROLLBACK_CAPABILITIES = {
  lazy = 'exact',
  mason = 'not-guaranteed',
  treesitter = 'not-guaranteed',
  limitation = 'Only Lazy rollback is exact; Mason package and Tree-sitter parser downgrades are not guaranteed.',
}

local function default_lockfile()
  return vim.fs.joinpath(vim.fn.stdpath 'config', 'lazy-lock.json')
end

local function default_snapshot_dir()
  return vim.fs.joinpath(vim.fn.stdpath 'state', 'nv_ide', 'toolchain', 'snapshots')
end

local function default_list_plugins()
  return require('lazy.core.config').plugins
end

local function default_lazy_install(options)
  return require('lazy.manage').install(options)
end

local function set(values)
  local result = {}
  for _, value in ipairs(values or {}) do
    result[value] = true
  end
  return result
end

local function load_dependency(provided, module)
  if provided then
    return provided
  end
  return require(module)
end

local function mason_receipts(manifest, provided_registry, errors)
  local receipts = {}
  local packages = manifest.mason and manifest.mason.packages or {}
  local loaded, registry = pcall(load_dependency, provided_registry, 'mason-registry')
  if not loaded then
    errors[#errors + 1] = 'Mason receipt observation: ' .. tostring(registry)
    for _, name in ipairs(packages) do
      receipts[name] = 'unknown'
    end
    return receipts
  end

  local listed, installed_names = pcall(registry.get_installed_package_names)
  if not listed then
    errors[#errors + 1] = 'Mason receipt observation: ' .. tostring(installed_names)
    for _, name in ipairs(packages) do
      receipts[name] = 'unknown'
    end
    return receipts
  end

  local installed = set(installed_names)
  for _, name in ipairs(packages) do
    if not installed[name] then
      receipts[name] = 'missing'
    else
      local found, package = pcall(registry.get_package, name)
      local receipted, receipt = false, nil
      if found and package and type(package.get_receipt) == 'function' then
        receipted, receipt = pcall(function()
          return package:get_receipt():or_else(nil)
        end)
      end
      local receipt_complete = receipted and type(receipt) == 'table' and type(receipt.metrics) == 'table' and tonumber(receipt.metrics.completion_time) ~= nil
      if found and not receipt_complete then
        errors[#errors + 1] = ('Mason receipt observation for %s: receipt incomplete'):format(name)
        receipts[name] = 'incomplete'
      end

      local versioned, version = false, nil
      if found and receipt_complete and type(package.get_installed_version) == 'function' then
        versioned, version = pcall(package.get_installed_version, package)
      end
      if not found then
        errors[#errors + 1] = ('Mason receipt observation for %s: %s'):format(name, tostring(package))
        receipts[name] = 'unknown'
      elseif receipt_complete and not versioned then
        errors[#errors + 1] = ('Mason receipt observation for %s: %s'):format(name, tostring(version))
      end
      if receipt_complete then
        receipts[name] = type(version) == 'string' and version ~= '' and version or 'unknown'
      end
    end
  end
  return receipts
end

local function treesitter_revisions(manifest, provided_config, provided_parsers, provided_receipt, errors)
  local revisions = {}
  local parsers = manifest.treesitter and manifest.treesitter.parsers or {}
  local loaded, config = pcall(load_dependency, provided_config, 'nvim-treesitter.config')
  if not loaded then
    errors[#errors + 1] = 'Tree-sitter parser-info observation: ' .. tostring(config)
    for _, name in ipairs(parsers) do
      revisions[name] = 'unknown'
    end
    return revisions
  end

  local listed, installed_names = pcall(config.get_installed, 'parsers')
  local resolved, parser_info = pcall(config.get_install_dir, 'parser-info')
  if not listed or not resolved then
    errors[#errors + 1] = 'Tree-sitter parser-info observation: ' .. tostring(not listed and installed_names or parser_info)
    for _, name in ipairs(parsers) do
      revisions[name] = 'unknown'
    end
    return revisions
  end

  local providers_loaded, parser_registry = pcall(load_dependency, provided_parsers, 'nvim-treesitter.parsers')
  local receipt_loaded, receipt = pcall(load_dependency, provided_receipt, 'nv_ide.toolchain.treesitter_receipt')
  local installed = set(installed_names)
  for _, name in ipairs(parsers) do
    if not installed[name] then
      revisions[name] = 'missing'
    else
      local inspected, status = false, nil
      if providers_loaded and receipt_loaded then
        inspected, status = pcall(receipt.inspect, name, true, {
          config = config,
          parser_registry = parser_registry,
        })
      end
      if inspected and status.status == 'installed' then
        revisions[name] = status.revision
      elseif inspected then
        errors[#errors + 1] = ('Tree-sitter parser-info observation for %s: receipt is stale'):format(name)
        revisions[name] = 'stale'
      else
        local path = vim.fs.joinpath(parser_info, name .. '.revision')
        local readable, lines = pcall(vim.fn.readfile, path, 'b')
        local revision = readable and vim.trim(table.concat(lines, '\n')) or ''
        if revision == '' then
          errors[#errors + 1] = ('Tree-sitter parser-info observation for %s: revision unavailable'):format(name)
        end
        revisions[name] = revision ~= '' and revision or 'unknown'
      end
    end
  end
  return revisions
end

local function default_receipt_probe(manifest, mason_registry, treesitter_config, treesitter_parsers, treesitter_receipt)
  return function()
    local errors = {}
    return {
      mason_receipts = mason_receipts(manifest, mason_registry, errors),
      treesitter_parser_info = treesitter_revisions(manifest, treesitter_config, treesitter_parsers, treesitter_receipt, errors),
      errors = errors,
    }
  end
end

local function result_errors(stage, result)
  if result == false then
    return { stage .. ' failed' }
  end
  if type(result) ~= 'table' then
    return {}
  end
  if result.ok ~= false and result.status ~= 'failed' then
    return {}
  end
  if type(result.errors) == 'table' and #result.errors > 0 then
    return vim.deepcopy(result.errors)
  end
  return { result.error or (stage .. ' failed') }
end

local function lazy_has_errors(provided)
  if provided then
    return provided
  end
  local ok_plugin, plugin = pcall(require, 'lazy.core.plugin')
  if not ok_plugin then
    return nil
  end
  return plugin.has_errors
end

local function lazy_errors(operation, list_plugins, provided_has_errors)
  operation = operation or 'update'
  local has_errors = lazy_has_errors(provided_has_errors)
  if type(has_errors) ~= 'function' then
    return { ('Lazy runtime is unavailable after %s'):format(operation) }
  end

  local listed, plugins = pcall(list_plugins or default_list_plugins)
  if not listed or type(plugins) ~= 'table' then
    return { ('Lazy %s status observation failed: %s'):format(operation, tostring(plugins)) }
  end

  local errors = {}
  for name, spec in pairs(plugins) do
    local checked, failed = pcall(has_errors, spec)
    if not checked then
      errors[#errors + 1] = ('Lazy %s status observation failed for %s: %s'):format(operation, name, tostring(failed))
    elseif failed then
      errors[#errors + 1] = ('Lazy %s failed for %s'):format(operation, name)
    end
  end
  table.sort(errors)
  return errors
end

local function lazy_step(method)
  return function(options, done)
    local ok, runner = pcall(function()
      return require('lazy.manage')[method] {
        wait = options.wait,
        show = options.show,
      }
    end)
    if not ok then
      done { ok = false, error = tostring(runner) }
      return
    end

    local function finish()
      if vim.in_fast_event() then
        vim.schedule(finish)
        return
      end
      local errors = lazy_errors(method)
      done { ok = #errors == 0, errors = errors }
    end
    if options.wait then
      finish()
    else
      runner:wait(finish)
    end
  end
end

local function treesitter_step(manifest, timeout_ms, repair, provided_runtime)
  return function(options, done)
    local bounded_timeout = math.min(options.timeout_ms or timeout_ms, timeout_ms)
    local function repair_stale_parsers()
      local completed = false
      local function finish(result)
        if completed then
          return
        end
        completed = true
        done(result)
      end
      local repaired, result = pcall(repair.install, repair, {
        wait = options.wait == true,
        timeout_ms = bounded_timeout,
        on_complete = finish,
      })
      if not repaired then
        finish { ok = false, error = tostring(result) }
      elseif type(result) ~= 'table' then
        finish { ok = false, error = 'Tree-sitter local parser repair returned no result' }
      elseif result.pending ~= true then
        finish(result)
      end
    end

    local runtime = provided_runtime or require 'nvim-treesitter'
    local ok, task = pcall(runtime.update, manifest.treesitter.parsers, { summary = true })
    if not ok then
      done { ok = false, error = tostring(task) }
      return
    end

    if options.wait then
      local waited, result = pcall(task.wait, task, bounded_timeout)
      if not waited or result == false then
        done {
          ok = false,
          error = not waited and tostring(result) or 'Tree-sitter update failed',
        }
        return
      end
      repair_stale_parsers()
      return
    end

    local function after_update(err, result)
      if vim.in_fast_event() then
        vim.schedule(function()
          after_update(err, result)
        end)
        return
      end
      if err ~= nil or result == false then
        done {
          ok = false,
          error = err and tostring(err) or 'Tree-sitter update failed',
        }
        return
      end
      repair_stale_parsers()
    end
    local awaited, await_error = pcall(task.await, task, after_update)
    if not awaited then
      done { ok = false, error = tostring(await_error) }
    end
  end
end

function Plugins:_snapshot()
  if vim.fn.filereadable(self.lockfile) ~= 1 then
    return nil
  end
  vim.fn.mkdir(self.snapshot_dir, 'p')
  local base = vim.fs.joinpath(self.snapshot_dir, ('lazy-lock-%d.json'):format(self.now()))
  local path, suffix = base, 0
  while vim.uv.fs_stat(path) do
    suffix = suffix + 1
    path = base:gsub('%.json$', ('-%d.json'):format(suffix))
  end
  local copied, copy_error = vim.uv.fs_copyfile(self.lockfile, path)
  if not copied then
    error('failed to snapshot Lazy lockfile: ' .. tostring(copy_error))
  end
  return path
end

function Plugins:_restore_file(snapshot)
  vim.fn.mkdir(vim.fs.dirname(self.lockfile), 'p')
  local temporary = self.lockfile .. ('.restore-%d-%d'):format(vim.uv.os_getpid(), vim.uv.hrtime())
  local copied, copy_error = vim.uv.fs_copyfile(snapshot, temporary)
  if not copied then
    error('failed to stage Lazy lockfile rollback: ' .. tostring(copy_error))
  end
  local renamed, rename_error = vim.uv.fs_rename(temporary, self.lockfile)
  if not renamed then
    vim.fn.delete(temporary)
    error('failed to restore Lazy lockfile: ' .. tostring(rename_error))
  end
end

function Plugins:_read_lock_contents()
  local file, open_error = io.open(self.lockfile, 'rb')
  if not file then
    error('failed to read Lazy lockfile: ' .. tostring(open_error))
  end
  local contents = file:read '*a'
  file:close()
  return contents
end

function Plugins:_replace_lock_contents(contents)
  vim.fn.mkdir(vim.fs.dirname(self.lockfile), 'p')
  local temporary = self.lockfile .. ('.repair-%d-%d'):format(vim.uv.os_getpid(), vim.uv.hrtime())
  local file, open_error = vim.uv.fs_open(temporary, 'wx', 384)
  if not file then
    error('failed to stage Lazy lockfile preservation: ' .. tostring(open_error))
  end
  local written, write_error = vim.uv.fs_write(file, contents, 0)
  local synced, sync_error = written and vim.uv.fs_fsync(file) or nil
  local closed, close_error = vim.uv.fs_close(file)
  if not written or not synced or not closed then
    vim.fn.delete(temporary)
    error('failed to preserve Lazy lockfile: ' .. tostring(write_error or sync_error or close_error))
  end
  local renamed, rename_error = vim.uv.fs_rename(temporary, self.lockfile)
  if not renamed then
    vim.fn.delete(temporary)
    error('failed to replace preserved Lazy lockfile: ' .. tostring(rename_error))
  end
end

function Plugins:_invoke(stage, operation, options, done)
  local completed = false
  local function finish(result)
    if completed then
      return
    end
    if vim.in_fast_event() then
      vim.schedule(function()
        finish(result)
      end)
      return
    end
    completed = true
    done(result or { ok = true })
  end
  local ok, result = pcall(operation, options, finish)
  if not ok then
    finish { ok = false, error = tostring(result) }
  elseif options.wait and not completed then
    if result == nil then
      finish { ok = false, error = stage .. ' did not complete' }
    else
      finish(result)
    end
  end
end

function Plugins:_problems()
  local missing, errored = {}, {}
  local has_errors = lazy_has_errors(self.lazy_has_errors)
  for name, spec in pairs(self.list_plugins() or {}) do
    if type(spec) == 'table' and type(spec.url) == 'string' then
      local installed = spec._ and spec._.installed
      local failed = false
      if installed then
        if type(has_errors) ~= 'function' then
          failed = true
        else
          local observed, result = pcall(has_errors, spec)
          failed = not observed or result == true
        end
      end
      if not installed then
        missing[#missing + 1] = spec.name or name
      elseif failed then
        errored[#errored + 1] = spec.name or name
      end
    end
  end
  table.sort(missing)
  table.sort(errored)
  return missing, errored
end

function Plugins:discover()
  local missing, errored = self:_problems()
  return vim.list_extend(missing, errored)
end

function Plugins:install(options)
  options = options or {}
  local missing, errored = self:_problems()
  local problems = vim.list_extend(vim.deepcopy(missing), errored)
  if #problems == 0 then
    local errors = lazy_errors('install', self.list_plugins, self.lazy_has_errors)
    return { ok = #errors == 0, pending = false, missing = {}, errors = errors }
  end

  local captured, lock_contents = pcall(self._read_lock_contents, self)
  if not captured then
    return { ok = false, error = tostring(lock_contents), missing = problems }
  end
  local decoded, lock = pcall(vim.json.decode, lock_contents)
  if not decoded or type(lock) ~= 'table' then
    return { ok = false, error = 'Lazy lockfile is not valid JSON', missing = problems }
  end
  for _, name in ipairs(problems) do
    local entry = lock[name]
    if type(entry) ~= 'table'
      or type(entry.branch) ~= 'string'
      or entry.branch == ''
      or type(entry.commit) ~= 'string'
      or not entry.commit:match '^[0-9a-fA-F]+$'
      or #entry.commit ~= 40
    then
      return { ok = false, error = name .. ' has no tracked revision in lazy-lock.json', missing = problems }
    end
  end

  local operations = {}
  if #missing > 0 then
    operations[#operations + 1] = { name = 'install', run = self.lazy_install, plugins = missing }
  end
  if #errored > 0 then
    operations[#operations + 1] = { name = 'repair', run = self.lazy_repair, plugins = errored }
  end

  local completed = false
  local function finish(extra_errors)
    if completed then
      return
    end
    completed = true
    local errors = extra_errors or {}
    local preserved, preserve_error = pcall(self._replace_lock_contents, self, lock_contents)
    if not preserved then
      errors[#errors + 1] = tostring(preserve_error)
    end
    local remaining = self:discover()
    vim.list_extend(errors, lazy_errors('repair', self.list_plugins, self.lazy_has_errors))
    if options.on_complete then
      options.on_complete {
        ok = #remaining == 0 and #errors == 0,
        missing = remaining,
        errors = errors,
      }
    end
  end

  local index = 0
  local function next_operation()
    if vim.in_fast_event() then
      vim.schedule(next_operation)
      return
    end
    index = index + 1
    local operation = operations[index]
    if not operation then
      finish {}
      return
    end
    local ok, result = pcall(operation.run, {
      wait = options.wait == true,
      lockfile = true,
      plugins = vim.deepcopy(operation.plugins),
      show = options.show,
    })
    if not ok then
      finish { ('Lazy %s failed: %s'):format(operation.name, tostring(result)) }
      return
    end
    if type(result) ~= 'table' or type(result.wait) ~= 'function' then
      finish { ('Lazy %s did not return a runner'):format(operation.name) }
      return
    end
    local waited, wait_error = pcall(result.wait, result, next_operation)
    if not waited then
      finish { ('Lazy %s completion failed: %s'):format(operation.name, tostring(wait_error)) }
    end
  end
  next_operation()
  return { ok = true, pending = not completed, missing = problems }
end

function Plugins:update(options)
  options = options or {}
  local wait = options.wait == true
  local final
  local finished = false
  local snapshot
  local manager_before
  local manager_after
  local manager_tag
  local observed = {}

  local function observe(phase)
    if observed[phase] then
      return
    end
    local ok, receipts = pcall(self.receipt_probe)
    if not ok or type(receipts) ~= 'table' then
      observed[phase] = { errors = { 'receipt observation: ' .. tostring(receipts) } }
      return
    end
    observed[phase] = vim.deepcopy(receipts)
  end

  local function complete(result)
    if finished then
      return
    end
    finished = true
    result.snapshot = snapshot
    result.fresh = options.fresh == true
    result.observed = vim.deepcopy(observed)
    result.rollback = vim.deepcopy(ROLLBACK_CAPABILITIES)
    if manager_before or manager_after or manager_tag then
      result.manager = {
        before = manager_before,
        commit = manager_after,
        tag = manager_tag,
      }
    end
    final = result
    if options.on_complete then
      options.on_complete(result)
    end
  end

  observe 'before'

  local snapshotted, snapshot_or_error = pcall(self._snapshot, self)
  if not snapshotted then
    observed.after = vim.deepcopy(observed.before)
    complete { status = 'failed', errors = { tostring(snapshot_or_error) }, rolled_back = false }
    return final
  end
  snapshot = snapshot_or_error

  local function rollback(errors)
    observe 'after'
    if not vim.tbl_contains(errors, ROLLBACK_CAPABILITIES.limitation) then
      errors[#errors + 1] = ROLLBACK_CAPABILITIES.limitation
    end
    if not snapshot then
      complete { status = 'failed', errors = errors, rolled_back = false }
      return
    end
    local restored, restore_error = pcall(self._restore_file, self, snapshot)
    if not restored then
      errors[#errors + 1] = tostring(restore_error)
      complete { status = 'failed', errors = errors, rolled_back = false }
      return
    end

    local rollback_errors = {}
    local function restore_plugins()
      self:_invoke('Lazy restore', self.lazy_restore, {
        wait = wait,
        show = options.show,
      }, function(result)
        vim.list_extend(rollback_errors, result_errors('Lazy restore', result))
        local lock_restored, final_restore_error = pcall(self._restore_file, self, snapshot)
        if not lock_restored then
          rollback_errors[#rollback_errors + 1] = tostring(final_restore_error)
        end
        vim.list_extend(errors, rollback_errors)
        complete {
          status = 'failed',
          errors = errors,
          rolled_back = #rollback_errors == 0,
        }
      end)
    end

    if self.manager and manager_before then
      self:_invoke('lazy.nvim manager restore', function(manager_options, done)
        return self.manager:restore(manager_options, done)
      end, {
        wait = wait,
        timeout_ms = options.timeout_ms,
        commit = manager_before,
      }, function(result)
        vim.list_extend(rollback_errors, result_errors('lazy.nvim manager restore', result))
        restore_plugins()
      end)
      return
    end
    restore_plugins()
  end

  local function validate_smoke()
    if self.manager and manager_after then
      local called, recorded, record_error = pcall(self.manager.record, self.manager, manager_after)
      if not called then
        rollback { 'lazy.nvim manager lock recording: ' .. tostring(recorded) }
        return
      end
      if not recorded then
        rollback { 'lazy.nvim manager lock recording: ' .. tostring(record_error) }
        return
      end
    end

    local smoke_settled = false
    local function finish_smoke(smoke_result)
      if smoke_settled then
        return
      end
      smoke_settled = true
      local errors = result_errors('smoke validation', smoke_result)
      if #errors > 0 then
        rollback(errors)
        return
      end
      observe 'after'
      complete { status = 'success', rolled_back = false, checks = smoke_result.checks or {} }
    end

    local smoked, smoke_result = pcall(self.smoke.run, self.smoke, {
      wait = wait,
      lock_owner = options.lock_owner,
      on_complete = finish_smoke,
    })
    if not smoked then
      rollback { tostring(smoke_result) }
    elseif not smoke_settled and (type(smoke_result) ~= 'table' or smoke_result.pending ~= true) then
      finish_smoke(smoke_result)
    end
  end

  local function update_manager()
    if not self.manager then
      validate_smoke()
      return
    end
    self:_invoke('lazy.nvim manager update', function(manager_options, done)
      return self.manager:update(manager_options, done)
    end, {
      wait = wait,
      timeout_ms = options.timeout_ms,
    }, function(result)
      manager_before = type(result) == 'table' and result.before or nil
      manager_after = type(result) == 'table' and result.commit or nil
      manager_tag = type(result) == 'table' and result.tag or nil
      local errors = result_errors('lazy.nvim manager update', result)
      if #errors == 0
        and (type(manager_before) ~= 'string' or #manager_before ~= 40 or not manager_before:match '^[0-9a-fA-F]+$')
      then
        errors[#errors + 1] = 'lazy.nvim manager update did not report its prior exact revision'
      end
      if #errors == 0
        and (type(manager_after) ~= 'string' or #manager_after ~= 40 or not manager_after:match '^[0-9a-fA-F]+$')
      then
        errors[#errors + 1] = 'lazy.nvim manager update did not report its selected exact revision'
      end
      if #errors > 0 then
        if snapshot then
          rollback(errors)
        else
          complete { status = 'failed', errors = errors, rolled_back = false }
        end
        return
      end
      manager_before = manager_before:lower()
      manager_after = manager_after:lower()
      validate_smoke()
    end)
  end

  self:_invoke('Lazy update', self.lazy_update, {
    wait = wait,
    show = options.show,
    fresh = options.fresh == true,
  }, function(lazy_result)
    local errors = result_errors('Lazy update', lazy_result)
    if #errors > 0 then
      rollback(errors)
      return
    end

    self:_invoke('Tree-sitter update', self.treesitter_update, {
      wait = wait,
      timeout_ms = options.timeout_ms,
    }, function(treesitter_result)
      errors = result_errors('Tree-sitter update', treesitter_result)
      if #errors > 0 then
        rollback(errors)
        return
      end
      update_manager()
    end)
  end)

  if wait then
    return final
      or {
        status = 'failed',
        errors = { 'blocking plugin update did not complete' },
        snapshot = snapshot,
        rolled_back = false,
        observed = vim.deepcopy(observed),
        rollback = vim.deepcopy(ROLLBACK_CAPABILITIES),
      }
  end
  return {
    status = 'started',
    snapshot = snapshot,
    fresh = options.fresh == true,
    observed = vim.deepcopy(observed),
    rollback = vim.deepcopy(ROLLBACK_CAPABILITIES),
  }
end

local M = {}

local LAZY_REPOSITORY = 'https://github.com/folke/lazy.nvim.git'

local function run_bootstrap_command(system, command, timeout_ms)
  local spawned, process = pcall(system, command, { text = true, timeout = timeout_ms })
  if not spawned then
    return nil, tostring(process)
  end
  if type(process) ~= 'table' or type(process.wait) ~= 'function' then
    return nil, 'process handle is unavailable'
  end
  local waited, result = pcall(process.wait, process)
  if not waited then
    return nil, tostring(result)
  end
  if type(result) ~= 'table' then
    return nil, 'process result is unavailable'
  end
  if result.code ~= 0 then
    local detail = vim.trim(result.stderr or result.stdout or '')
    return nil, detail ~= '' and detail or ('exit code %s'):format(tostring(result.code))
  end
  return result
end

local function newest_stable_release(output)
  local selected
  for line in tostring(output or ''):gmatch '[^\r\n]+' do
    local commit, tag, major, minor, patch = line:match '^([0-9a-fA-F]+)%s+refs/tags/(v(%d+)%.(%d+)%.(%d+))$'
    if commit and #commit == 40 then
      local candidate = {
        commit = commit:lower(),
        tag = tag,
        version = { tonumber(major), tonumber(minor), tonumber(patch) },
      }
      if not selected then
        selected = candidate
      else
        for index = 1, 3 do
          if candidate.version[index] ~= selected.version[index] then
            if candidate.version[index] > selected.version[index] then
              selected = candidate
            end
            break
          end
        end
      end
    end
  end
  return selected
end

function M.bootstrap_lazy(options)
  options = options or {}
  local path = options.path or vim.env.LAZY or vim.fs.joinpath(vim.fn.stdpath 'data', 'lazy', 'lazy.nvim')
  local stat = options.stat or vim.uv.fs_stat
  local entrypoint = vim.fs.joinpath(path, 'lua', 'lazy', 'init.lua')
  if stat(path) then
    if stat(entrypoint) then
      return path
    end
    error('existing lazy.nvim bootstrap is incomplete: ' .. path)
  end
  if vim.g.nv_ide_toolchain_read_only_startup == true then
    error('read-only startup requires an existing lazy.nvim checkout: ' .. path)
  end

  local system = options.system or vim.system
  local timeout_ms = options.timeout_ms or 120000
  local listed, list_error = run_bootstrap_command(system, {
    'git',
    'ls-remote',
    '--tags',
    '--refs',
    LAZY_REPOSITORY,
    'v*',
  }, timeout_ms)
  if not listed then
    error('failed to bootstrap lazy.nvim: stable release lookup: ' .. list_error)
  end
  local release = newest_stable_release(listed.stdout)
  if not release then
    error('failed to bootstrap lazy.nvim: no stable semver release tag was found')
  end

  local mkdir = options.mkdir or vim.fn.mkdir
  local made, mkdir_error = pcall(mkdir, vim.fs.dirname(path), 'p')
  if not made then
    error('failed to bootstrap lazy.nvim: cannot create parent directory: ' .. tostring(mkdir_error))
  end

  local candidate = options.candidate or path .. ('.bootstrap-%d-%d'):format(vim.uv.os_getpid(), vim.uv.hrtime())
  if not vim.startswith(candidate, path .. '.bootstrap-') then
    error('failed to bootstrap lazy.nvim: unsafe candidate path: ' .. candidate)
  end
  if stat(candidate) then
    error('failed to bootstrap lazy.nvim: candidate path already exists: ' .. candidate)
  end

  local delete = options.delete or vim.fn.delete
  local function cleanup(detail)
    local deleted, delete_result = pcall(delete, candidate, 'rf')
    if not deleted or (delete_result ~= 0 and stat(candidate)) then
      detail = detail .. '; candidate cleanup failed: ' .. tostring(delete_result)
    end
    error('failed to bootstrap lazy.nvim: ' .. detail)
  end

  local cloned, clone_error = run_bootstrap_command(system, {
    'git',
    'clone',
    '--filter=blob:none',
    '--depth=1',
    '--single-branch',
    '--branch=' .. release.tag,
    LAZY_REPOSITORY,
    candidate,
  }, timeout_ms)
  if not cloned then
    cleanup('clone ' .. release.tag .. ': ' .. clone_error)
  end

  local resolved, resolve_error = run_bootstrap_command(system, {
    'git',
    '-C',
    candidate,
    'rev-parse',
    'HEAD',
  }, timeout_ms)
  if not resolved then
    cleanup('revision verification: ' .. resolve_error)
  end
  local actual = vim.trim(resolved.stdout or ''):lower()
  if actual ~= release.commit then
    cleanup(('revision verification: expected %s, got %s'):format(release.commit, actual ~= '' and actual or 'empty output'))
  end

  local rename = options.rename or vim.uv.fs_rename
  local renamed, rename_error = rename(candidate, path)
  if not renamed then
    if stat(path) and stat(entrypoint) then
      local deleted, delete_result = pcall(delete, candidate, 'rf')
      if not deleted or (delete_result ~= 0 and stat(candidate)) then
        error('failed to bootstrap lazy.nvim: concurrent bootstrap won but candidate cleanup failed: ' .. tostring(delete_result))
      end
      return path
    end
    cleanup('atomic publish: ' .. tostring(rename_error))
  end
  return path
end

function M.lazy_options(manifest)
  manifest = manifest or require 'nv_ide.toolchain.manifest'
  local read_only_startup = vim.g.nv_ide_toolchain_read_only_startup == true
  local spec = {
    { import = 'plugins' },
    { import = 'plugins.lsp.lang' },
  }
  local names = vim.tbl_keys(manifest.plugin_branches)
  table.sort(names)
  for _, name in ipairs(names) do
    spec[#spec + 1] = {
      name,
      branch = manifest.plugin_branches[name],
      version = false,
    }
  end
  return {
    spec = spec,
    defaults = { lazy = false, version = '*' },
    install = { colorscheme = { 'tokyonight', 'habamax' }, missing = not read_only_startup },
    checker = { enabled = not read_only_startup },
    concurrency = 16,
    performance = {
      rtp = {
        disabled_plugins = { 'netrwPlugin', 'tarPlugin', 'tutor' },
      },
    },
    ui = { border = 'rounded' },
    rocks = { enabled = false },
  }
end

function M.new(options)
  options = options or {}
  local manifest = options.manifest or require 'nv_ide.toolchain.manifest'
  local lockfile = options.lockfile or default_lockfile()
  local manager = options.manager
  if manager == nil and options.lazy_update == nil then
    manager = require('nv_ide.toolchain.lazy_manager').new {
      lockfile = lockfile,
      timeout_ms = options.timeout_ms or 120000,
    }
  end
  local treesitter = options.treesitter
  if not treesitter and not options.treesitter_update then
    treesitter = require('nv_ide.toolchain.treesitter').new {
      manifest = manifest,
      timeout_ms = options.timeout_ms or 300000,
    }
  end
  return setmetatable({
    lockfile = lockfile,
    snapshot_dir = options.snapshot_dir or default_snapshot_dir(),
    now = options.now or os.time,
    manager = manager,
    lazy_update = options.lazy_update or lazy_step 'update',
    lazy_restore = options.lazy_restore or lazy_step 'restore',
    list_plugins = options.list_plugins or default_list_plugins,
    lazy_has_errors = options.lazy_has_errors,
    lazy_install = options.lazy_install or default_lazy_install,
    lazy_repair = options.lazy_repair or function(repair_options)
      return require('lazy.manage').restore(repair_options)
    end,
    treesitter_update = options.treesitter_update
      or treesitter_step(manifest, options.timeout_ms or 300000, treesitter, options.nvim_treesitter),
    receipt_probe = options.receipt_probe
      or default_receipt_probe(
        manifest,
        options.mason_registry,
        options.treesitter_config,
        options.treesitter_parsers,
        options.treesitter_receipt
      ),
    smoke = options.smoke or require('nv_ide.toolchain.smoke').new { lockfile = lockfile },
  }, Plugins)
end

return M
