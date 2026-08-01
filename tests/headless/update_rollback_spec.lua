local h = require 'tests.headless.harness'

local function reload(name)
  package.loaded[name] = nil
  return require(name)
end

local function write(path, contents)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  assert(vim.fn.writefile({ contents }, path, 'b') == 0)
end

local function read(path)
  return table.concat(vim.fn.readfile(path, 'b'), '\n')
end

local function transaction(options)
  options = options or {}
  local calls = {}
  local receipt_index = 0
  local function step(name, result, mutate)
    return function(step_options, done)
      calls[#calls + 1] = { name = name, wait = step_options.wait }
      if mutate then
        mutate()
      end
      done(result or { ok = true })
    end
  end
  return calls,
    {
      lazy_update = step('lazy-update', options.lazy_result, options.mutate),
      treesitter_update = step('treesitter-update', options.treesitter_result),
      smoke = {
        run = function()
          calls[#calls + 1] = { name = 'smoke' }
          return options.smoke_result or { ok = true, checks = { 'lazy', 'syntax' } }
        end,
      },
      lazy_restore = step('lazy-restore', options.restore_result),
      receipt_probe = function()
        receipt_index = receipt_index + 1
        return vim.deepcopy((options.receipts or {
          {
            mason_receipts = { stylua = '1.0.0' },
            treesitter_parser_info = { lua = 'revision-before' },
          },
          {
            mason_receipts = { stylua = '1.0.0' },
            treesitter_parser_info = { lua = 'revision-after' },
          },
        })[receipt_index])
      end,
    }
end

h.describe('latest-first plugin update and rollback', function()
  h.it('bootstraps the active LAZY override instead of an unused default checkout', function()
    h.with_temp_dir(function(dir)
      local override = vim.fs.joinpath(dir, 'lazy.nvim')
      vim.fn.mkdir(vim.fs.joinpath(override, 'lua', 'lazy'), 'p')
      write(vim.fs.joinpath(override, 'lua', 'lazy', 'init.lua'), 'return {}')
      local previous = vim.env.LAZY
      vim.env.LAZY = override
      local ok, result = xpcall(function()
        h.equal(reload('nv_ide.toolchain.plugins').bootstrap_lazy(), override)
      end, debug.traceback)
      vim.env.LAZY = previous
      if not ok then
        error(result, 0)
      end
    end)
  end)

  h.it('updates and records the external Lazy manager before fresh-process validation', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      local old_commit = string.rep('1', 40)
      local new_commit = string.rep('2', 40)
      write(lockfile, vim.json.encode { ['lazy.nvim'] = { branch = 'main', commit = old_commit } })
      local calls = {}
      local manager = {
        update = function(_, options, done)
          calls[#calls + 1] = { name = 'manager-update', wait = options.wait }
          done { ok = true, before = old_commit, commit = new_commit, tag = 'v11.17.5' }
        end,
        record = function(_, commit)
          calls[#calls + 1] = { name = 'manager-record', commit = commit }
          local lock = vim.json.decode(read(lockfile))
          lock['lazy.nvim'] = { branch = 'main', commit = commit }
          write(lockfile, vim.json.encode(lock))
          return true
        end,
        restore = function()
          error 'successful update must not restore the manager'
        end,
      }
      local updater = reload('nv_ide.toolchain.plugins').new {
        lockfile = lockfile,
        snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
        manager = manager,
        lazy_update = function(_, done)
          calls[#calls + 1] = { name = 'lazy-update' }
          write(lockfile, '{"plugin":{"branch":"main","commit":"' .. string.rep('3', 40) .. '"}}')
          done { ok = true }
        end,
        treesitter_update = function(_, done)
          calls[#calls + 1] = { name = 'treesitter-update' }
          done { ok = true }
        end,
        lazy_restore = function()
          error 'successful update must not restore plugins'
        end,
        smoke = {
          run = function()
            calls[#calls + 1] = { name = 'smoke' }
            h.equal(vim.json.decode(read(lockfile))['lazy.nvim'].commit, new_commit)
            return { ok = true, checks = { 'isolated-startup' } }
          end,
        },
        receipt_probe = function()
          return { mason_receipts = {}, treesitter_parser_info = {} }
        end,
      }

      local result = updater:update { wait = true }

      h.equal(result.status, 'success')
      h.deep_equal(result.manager, { before = old_commit, commit = new_commit, tag = 'v11.17.5' })
      h.deep_equal(vim.tbl_map(function(call)
        return call.name
      end, calls), { 'manager-update', 'lazy-update', 'treesitter-update', 'manager-record', 'smoke' })
    end)
  end)

  h.it('restores the external manager and the complete prior lock after validation failure', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      local old_commit = string.rep('4', 40)
      local new_commit = string.rep('5', 40)
      local original = vim.json.encode {
        ['lazy.nvim'] = { branch = 'main', commit = old_commit },
        plugin = { branch = 'main', commit = string.rep('6', 40) },
      }
      write(lockfile, original)
      local calls = {}
      local manager_head = old_commit
      local updater = reload('nv_ide.toolchain.plugins').new {
        lockfile = lockfile,
        snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
        manager = {
          update = function(_, _, done)
            calls[#calls + 1] = { name = 'manager-update' }
            manager_head = new_commit
            done { ok = true, before = old_commit, commit = new_commit, tag = 'v11.17.5' }
          end,
          record = function(_, commit)
            calls[#calls + 1] = { name = 'manager-record' }
            h.equal(commit, new_commit)
            return true
          end,
          restore = function(_, options, done)
            calls[#calls + 1] = { name = 'manager-restore', commit = options.commit }
            manager_head = options.commit
            done { ok = true }
          end,
        },
        lazy_update = function(_, done)
          calls[#calls + 1] = { name = 'lazy-update' }
          write(lockfile, '{"advanced":true}')
          done { ok = true }
        end,
        treesitter_update = function(_, done)
          calls[#calls + 1] = { name = 'treesitter-update' }
          done { ok = true }
        end,
        smoke = {
          run = function()
            calls[#calls + 1] = { name = 'smoke' }
            return { ok = false, errors = { 'fresh process failed' } }
          end,
        },
        lazy_restore = function(_, done)
          calls[#calls + 1] = { name = 'lazy-restore' }
          write(lockfile, '{"lazy-writer-omitted-manager":true}')
          done { ok = true }
        end,
        receipt_probe = function()
          return { mason_receipts = {}, treesitter_parser_info = {} }
        end,
      }

      local result = updater:update { wait = true }

      h.equal(result.status, 'failed')
      h.truthy(result.rolled_back)
      h.equal(manager_head, old_commit)
      h.equal(read(lockfile), original)
      h.deep_equal(vim.tbl_map(function(call)
        return call.name
      end, calls), {
        'manager-update',
        'lazy-update',
        'treesitter-update',
        'manager-record',
        'smoke',
        'manager-restore',
        'lazy-restore',
      })
    end)
  end)

  h.it('snapshots the lock, blocks for Lazy and parsers, validates smoke, and retains recovery evidence', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'config', 'lazy-lock.json')
      local snapshots = vim.fs.joinpath(dir, 'state', 'snapshots')
      write(lockfile, '{"known":"good"}')
      local calls, adapters = transaction {
        mutate = function()
          write(lockfile, '{"current":"latest"}')
        end,
      }
      local updater = reload('nv_ide.toolchain.plugins').new(vim.tbl_extend('force', adapters, {
        lockfile = lockfile,
        snapshot_dir = snapshots,
        now = function()
          return 123
        end,
      }))

      local result = updater:update { wait = true }

      h.equal(result.status, 'success')
      h.deep_equal(
        vim.tbl_map(function(call)
          return call.name
        end, calls),
        {
          'lazy-update',
          'treesitter-update',
          'smoke',
        }
      )
      h.truthy(calls[1].wait)
      h.truthy(calls[2].wait)
      h.equal(read(result.snapshot), '{"known":"good"}')
      h.equal(read(lockfile), '{"current":"latest"}')
      h.equal(vim.fn.filereadable(result.snapshot), 1, 'prior snapshot must remain after success')
    end)
  end)

  h.it('atomically restores the prior lock and runs blocking Lazy restore when validation fails', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'config', 'lazy-lock.json')
      write(lockfile, '{"known":"good"}')
      local calls, adapters = transaction {
        mutate = function()
          write(lockfile, '{"broken":"revision"}')
        end,
        smoke_result = { ok = false, errors = { 'startup smoke failed' } },
      }
      local updater = reload('nv_ide.toolchain.plugins').new(vim.tbl_extend('force', adapters, {
        lockfile = lockfile,
        snapshot_dir = vim.fs.joinpath(dir, 'state', 'snapshots'),
        now = function()
          return 456
        end,
      }))

      local result = updater:update { wait = true }

      h.equal(result.status, 'failed')
      h.truthy(result.rolled_back)
      h.matches(table.concat(result.errors, '\n'), 'startup smoke failed')
      h.deep_equal(
        vim.tbl_map(function(call)
          return call.name
        end, calls),
        {
          'lazy-update',
          'treesitter-update',
          'smoke',
          'lazy-restore',
        }
      )
      h.truthy(calls[4].wait)
      h.equal(read(lockfile), '{"known":"good"}')
      h.equal(vim.fn.filereadable(result.snapshot), 1, 'failed update snapshot must be retained')
      h.deep_equal(vim.fn.glob(lockfile .. '.restore-*', false, true), {})
      h.deep_equal(result.observed.before.mason_receipts, { stylua = '1.0.0' })
      h.deep_equal(result.observed.after.treesitter_parser_info, { lua = 'revision-after' })
      h.equal(result.rollback.lazy, 'exact')
      h.equal(result.rollback.mason, 'not-guaranteed')
      h.equal(result.rollback.treesitter, 'not-guaranteed')
      h.matches(result.rollback.limitation, 'Only Lazy rollback is exact')
      h.matches(table.concat(result.errors, '\n'), 'Only Lazy rollback is exact')
    end)
  end)

  h.it('rolls back when a bounded fresh-process startup and LSP composition check fails', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      write(lockfile, '{"known":"good"}')
      local invocation
      local smoke = reload('nv_ide.toolchain.smoke').new {
        root = dir,
        lockfile = lockfile,
        timeout_ms = 4321,
        nvim = '/test/bin/nvim',
        system = function(command, options)
          invocation = { command = vim.deepcopy(command), options = vim.deepcopy(options) }
          return {
            wait = function()
              return { code = 19, stderr = 'fresh startup broke' }
            end,
          }
        end,
      }
      smoke.checks = { smoke.checks[4] }
      local calls, adapters = transaction {
        mutate = function()
          write(lockfile, '{"broken":"revision"}')
        end,
      }
      adapters.smoke = smoke
      local updater = reload('nv_ide.toolchain.plugins').new(vim.tbl_extend('force', adapters, {
        lockfile = lockfile,
        snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
      }))

      local result = updater:update { wait = true }

      h.equal(result.status, 'failed')
      h.truthy(result.rolled_back)
      h.matches(table.concat(result.errors, '\n'), 'fresh startup broke')
      h.deep_equal(
        vim.tbl_map(function(call)
          return call.name
        end, calls),
        { 'lazy-update', 'treesitter-update', 'lazy-restore' }
      )
      h.equal(invocation.command[1], '/test/bin/nvim')
      h.truthy(vim.tbl_contains(invocation.command, '--headless'))
      h.matches(table.concat(invocation.command, '\n'), 'gopls')
      h.matches(table.concat(invocation.command, '\n'), 'clangd')
      h.matches(table.concat(invocation.command, '\n'), 'vtsls')
      h.equal(invocation.options.timeout, 4321)
      h.equal(invocation.options.env.NVIM_TOOLCHAIN_AUTORUN, '0')
      h.equal(read(lockfile), '{"known":"good"}')
    end)
  end)

  h.it('resolves allowed current versions first on a fresh machine', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      write(lockfile, '{"repository":"recovery-evidence"}')
      local calls, adapters = transaction()
      local updater = reload('nv_ide.toolchain.plugins').new(vim.tbl_extend('force', adapters, {
        lockfile = lockfile,
        snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
      }))

      local result = updater:update { wait = true, fresh = true }

      h.equal(result.status, 'success')
      h.equal(calls[1].name, 'lazy-update')
      h.falsy(vim.tbl_contains(
        vim.tbl_map(function(call)
          return call.name
        end, calls),
        'lazy-restore'
      ))
    end)
  end)

  h.it('observes configured Mason receipt versions and Tree-sitter parser-info revisions', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      local parser_info = vim.fs.joinpath(dir, 'parser-info')
      local dap_provider = vim.fs.joinpath(dir, 'nvim-dap-repl-highlights')
      write(lockfile, '{}')
      write(vim.fs.joinpath(parser_info, 'lua.revision'), 'tree-sitter-lua-revision')
      write(vim.fs.joinpath(dap_provider, 'src', 'parser.c'), 'bundled dap repl source')

      local treesitter_config = {
        get_installed = function(kind)
          h.equal(kind, 'parsers')
          return { 'dap_repl', 'lua' }
        end,
        get_install_dir = function(kind)
          h.equal(kind, 'parser-info')
          return parser_info
        end,
      }
      local treesitter_parsers = {
        dap_repl = { install_info = { path = dap_provider } },
        lua = { install_info = { revision = 'tree-sitter-lua-revision' } },
        vim = { install_info = { revision = 'tree-sitter-vim-revision' } },
      }
      assert(require('nv_ide.toolchain.treesitter_receipt').persist('dap_repl', {
        config = treesitter_config,
        parser_registry = treesitter_parsers,
      }))
      local dap_receipt = read(vim.fs.joinpath(parser_info, 'dap_repl.nv-ide-receipt'))

      local calls, adapters = transaction()
      adapters.receipt_probe = nil
      local updater = reload('nv_ide.toolchain.plugins').new(vim.tbl_extend('force', adapters, {
        lockfile = lockfile,
        snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
        manifest = {
          mason = { packages = { 'missing-tool', 'partial-tool', 'stylua' } },
          treesitter = { parsers = { 'dap_repl', 'lua', 'vim' } },
        },
        mason_registry = {
          get_installed_package_names = function()
            return { 'partial-tool', 'stylua' }
          end,
          get_package = function(name)
            return {
              get_receipt = function()
                local receipt = name == 'stylua' and { metrics = { completion_time = 123 } } or { metrics = {} }
                return {
                  or_else = function()
                    return receipt
                  end,
                }
              end,
              get_installed_version = function()
                return name == 'stylua' and '2.1.0' or '9.9.9'
              end,
            }
          end,
        },
        treesitter_config = treesitter_config,
        treesitter_parsers = treesitter_parsers,
      }))

      local result = updater:update { wait = true }

      h.equal(result.status, 'success')
      h.deep_equal(result.observed.before.mason_receipts, {
        ['missing-tool'] = 'missing',
        ['partial-tool'] = 'incomplete',
        stylua = '2.1.0',
      })
      h.deep_equal(result.observed.after.treesitter_parser_info, {
        dap_repl = dap_receipt,
        lua = 'tree-sitter-lua-revision',
        vim = 'missing',
      })
      h.equal(result.rollback.lazy, 'exact')
      h.matches(result.rollback.limitation, 'Only Lazy rollback is exact')
      h.deep_equal(
        vim.tbl_map(function(call)
          return call.name
        end, calls),
        { 'lazy-update', 'treesitter-update', 'smoke' }
      )
    end)
  end)

  h.it('keeps an interactive first-run update asynchronous while preserving stage order', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      write(lockfile, '{}')
      local pending = {}
      local calls = {}
      local completed
      local updater = reload('nv_ide.toolchain.plugins').new {
        lockfile = lockfile,
        snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
        lazy_update = function(options, done)
          calls[#calls + 1] = { name = 'lazy-update', wait = options.wait }
          pending.lazy = done
        end,
        treesitter_update = function(options, done)
          calls[#calls + 1] = { name = 'treesitter-update', wait = options.wait }
          pending.treesitter = done
        end,
        smoke = {
          run = function()
            calls[#calls + 1] = { name = 'smoke' }
            return { ok = true }
          end,
        },
        lazy_restore = function()
          error 'restore must not run'
        end,
        receipt_probe = function()
          return { mason_receipts = {}, treesitter_parser_info = {} }
        end,
      }

      local started = updater:update {
        wait = false,
        fresh = true,
        on_complete = function(result)
          completed = result
        end,
      }
      h.equal(started.status, 'started')
      h.deep_equal(
        vim.tbl_map(function(call)
          return call.name
        end, calls),
        { 'lazy-update' }
      )
      h.falsy(calls[1].wait)
      h.equal(completed, nil)

      pending.lazy { ok = true }
      h.deep_equal(
        vim.tbl_map(function(call)
          return call.name
        end, calls),
        { 'lazy-update', 'treesitter-update' }
      )
      pending.treesitter { ok = true }
      h.equal(completed.status, 'success')
      h.deep_equal(
        vim.tbl_map(function(call)
          return call.name
        end, calls),
        {
          'lazy-update',
          'treesitter-update',
          'smoke',
        }
      )
    end)
  end)

  h.it('force-repairs stale dap_repl evidence before blocking update smoke validation', function()
    h.with_temp_dir(function(dir)
      local previous = package.loaded['nvim-treesitter']
      local calls = {}
      package.loaded['nvim-treesitter'] = {
        update = function(languages, options)
          calls[#calls + 1] = { name = 'treesitter-update', languages = vim.deepcopy(languages), options = vim.deepcopy(options) }
          return {
            wait = function(_, timeout)
              calls[#calls + 1] = { name = 'treesitter-wait', timeout = timeout }
              return true
            end,
          }
        end,
      }

      local ok, failure = xpcall(function()
        local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
        write(lockfile, '{}')
        local updater = reload('nv_ide.toolchain.plugins').new {
          lockfile = lockfile,
          snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
          timeout_ms = 4321,
          manifest = { mason = { packages = {} }, treesitter = { parsers = { 'dap_repl' } } },
          lazy_update = function(_, done)
            calls[#calls + 1] = { name = 'lazy-update' }
            done { ok = true }
          end,
          treesitter = {
            install = function(_, options)
              calls[#calls + 1] = { name = 'dap-repl-repair', options = vim.deepcopy(options) }
              return { ok = true, pending = false, missing = {} }
            end,
          },
          smoke = {
            run = function()
              calls[#calls + 1] = { name = 'smoke' }
              return { ok = true }
            end,
          },
          lazy_restore = function()
            error 'restore must not run'
          end,
          receipt_probe = function()
            return { mason_receipts = {}, treesitter_parser_info = { dap_repl = 'local-source' } }
          end,
        }

        local result = updater:update { wait = true, timeout_ms = 3210 }
        h.equal(result.status, 'success')
        h.deep_equal(vim.tbl_map(function(call) return call.name end, calls), {
          'lazy-update',
          'treesitter-update',
          'treesitter-wait',
          'dap-repl-repair',
          'smoke',
        })
        h.truthy(calls[4].options.wait)
        h.equal(calls[4].options.timeout_ms, 3210)
      end, debug.traceback)
      package.loaded['nvim-treesitter'] = previous
      if not ok then
        error(failure, 0)
      end
    end)
  end)

  h.it('awaits stale dap_repl repair in the interactive update cycle before smoke', function()
    h.with_temp_dir(function(dir)
      local previous = package.loaded['nvim-treesitter']
      local calls = {}
      local update_done
      local repair_done
      local completed
      package.loaded['nvim-treesitter'] = {
        update = function()
          calls[#calls + 1] = 'treesitter-update'
          return {
            await = function(_, callback)
              update_done = callback
            end,
          }
        end,
      }

      local ok, failure = xpcall(function()
        local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
        write(lockfile, '{}')
        local updater = reload('nv_ide.toolchain.plugins').new {
          lockfile = lockfile,
          snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
          manifest = { mason = { packages = {} }, treesitter = { parsers = { 'dap_repl' } } },
          lazy_update = function(_, done)
            calls[#calls + 1] = 'lazy-update'
            done { ok = true }
          end,
          treesitter = {
            install = function(_, options)
              calls[#calls + 1] = 'dap-repl-repair'
              h.falsy(options.wait)
              repair_done = options.on_complete
              return { ok = true, pending = true, missing = { 'dap_repl' } }
            end,
          },
          smoke = {
            run = function()
              calls[#calls + 1] = 'smoke'
              return { ok = true }
            end,
          },
          lazy_restore = function()
            error 'restore must not run'
          end,
          receipt_probe = function()
            return { mason_receipts = {}, treesitter_parser_info = { dap_repl = 'local-source' } }
          end,
        }

        local started = updater:update {
          wait = false,
          on_complete = function(result)
            completed = result
          end,
        }
        h.equal(started.status, 'started')
        h.deep_equal(calls, { 'lazy-update', 'treesitter-update' })
        update_done(nil, true)
        h.deep_equal(calls, { 'lazy-update', 'treesitter-update', 'dap-repl-repair' })
        h.equal(completed, nil)
        repair_done { ok = true, missing = {} }
        h.deep_equal(calls, { 'lazy-update', 'treesitter-update', 'dap-repl-repair', 'smoke' })
        h.equal(completed.status, 'success')
      end, debug.traceback)
      package.loaded['nvim-treesitter'] = previous
      if not ok then
        error(failure, 0)
      end
    end)
  end)

  h.it('returns from an interactive update before fresh-process smoke validation settles', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      write(lockfile, '{}')
      local pending = {}
      local completed
      local updater = reload('nv_ide.toolchain.plugins').new {
        lockfile = lockfile,
        snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
        lazy_update = function(_, done)
          pending.lazy = done
        end,
        treesitter_update = function(_, done)
          pending.treesitter = done
        end,
        smoke = {
          run = function(_, options)
            h.falsy(options.wait)
            pending.smoke = options.on_complete
            return { ok = true, pending = true }
          end,
        },
        lazy_restore = function()
          error 'restore must not run'
        end,
        receipt_probe = function()
          return { mason_receipts = {}, treesitter_parser_info = {} }
        end,
      }

      local started = updater:update {
        wait = false,
        on_complete = function(result)
          completed = result
        end,
      }
      h.equal(started.status, 'started')
      pending.lazy { ok = true }
      pending.treesitter { ok = true }
      h.equal(completed, nil, 'interactive update must return while the child smoke process is running')
      h.truthy(type(pending.smoke) == 'function')

      pending.smoke { ok = true, checks = { 'isolated-startup' } }
      h.equal(completed.status, 'success')
      h.deep_equal(completed.checks, { 'isolated-startup' })
    end)
  end)

  h.it('runs the isolated startup check asynchronously without waiting on the main loop', function()
    h.with_temp_dir(function(dir)
      local callback
      local completed
      local invocation_options
      local smoke = reload('nv_ide.toolchain.smoke').new {
        root = dir,
        lockfile = vim.fs.joinpath(dir, 'lazy-lock.json'),
        nvim = '/test/bin/nvim',
        system = function(_, options, on_exit)
          invocation_options = vim.deepcopy(options)
          callback = on_exit
          return {
            wait = function()
              error 'interactive smoke must not wait on the child process'
            end,
          }
        end,
      }
      smoke.checks = { smoke.checks[4] }

      local started = smoke:run {
        wait = false,
        lock_owner = { pid = 313, token = string.rep('e', 64) },
        on_complete = function(result)
          completed = result
        end,
      }

      h.truthy(started.pending)
      h.equal(completed, nil)
      h.truthy(type(callback) == 'function')
      h.equal(invocation_options.env.NV_IDE_TOOLCHAIN_READONLY_CHILD, '1')
      h.equal(invocation_options.env.NV_IDE_TOOLCHAIN_PARENT_LOCK_PID, '313')
      h.equal(invocation_options.env.NV_IDE_TOOLCHAIN_PARENT_LOCK_TOKEN, string.rep('e', 64))
      callback { code = 0, stdout = '', stderr = '' }
      h.truthy(completed.ok)
      h.deep_equal(completed.checks, { 'isolated-startup' })
    end)
  end)

  h.it('fails closed when a blocking update operation returns without completing', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      write(lockfile, '{}')
      local updater = reload('nv_ide.toolchain.plugins').new {
        lockfile = lockfile,
        snapshot_dir = vim.fs.joinpath(dir, 'snapshots'),
        lazy_update = function() end,
        lazy_restore = function(_, done)
          done { ok = true }
        end,
        treesitter_update = function()
          error 'Tree-sitter must not run after an incomplete Lazy update'
        end,
        smoke = {
          run = function()
            error 'smoke must not run after an incomplete Lazy update'
          end,
        },
        receipt_probe = function()
          return { mason_receipts = {}, treesitter_parser_info = {} }
        end,
      }

      local result = updater:update { wait = true }

      h.equal(result.status, 'failed')
      h.matches(table.concat(result.errors or {}, '\n'), 'Lazy update did not complete')
      h.truthy(result.rolled_back)
    end)
  end)

  h.it('discovers and installs only missing configured plugins at their locked revisions', function()
    h.with_temp_dir(function(dir)
      local install_options
      local runner_callback
      local completed
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      write(lockfile, vim.json.encode {
        missing = { branch = 'main', commit = string.rep('a', 40) },
      })
      local plugin_specs = {
        installed = { name = 'installed', url = 'https://example.test/installed', _ = { installed = true } },
        missing = { name = 'missing', url = 'https://example.test/missing', _ = { installed = false } },
        local_spec = { name = 'local_spec', _ = { installed = false } },
      }
      local adapter = reload('nv_ide.toolchain.plugins').new {
        lockfile = lockfile,
        list_plugins = function()
          return plugin_specs
        end,
        lazy_has_errors = function()
          return false
        end,
        lazy_install = function(options)
          install_options = vim.deepcopy(options)
          return {
            wait = function(_, callback)
              runner_callback = callback
            end,
          }
        end,
      }

      h.deep_equal(adapter:discover(), { 'missing' })
      local result = adapter:install {
        wait = true,
        show = false,
        on_complete = function(value)
          completed = value
        end,
      }

      h.truthy(result.ok)
      h.truthy(result.pending)
      h.deep_equal(install_options, { wait = true, lockfile = true, plugins = { 'missing' }, show = false })
      h.equal(completed, nil)

      plugin_specs.missing._.installed = true
      runner_callback()
      h.truthy(completed.ok)
      h.deep_equal(completed.missing, {})
    end)
  end)

  h.it('fails plugin installation completion when Lazy records an installed plugin error', function()
    local previous_config = package.loaded['lazy.core.config']
    local previous_plugin = package.loaded['lazy.core.plugin']
    local lockfile = vim.fn.tempname()
    write(lockfile, vim.json.encode {
      broken = { branch = 'main', commit = string.rep('d', 40) },
    })
    local plugin_specs = {
      broken = {
        name = 'broken',
        url = 'https://example.test/broken',
        _ = { installed = false, lazy_error = false },
      },
    }
    package.loaded['lazy.core.config'] = { plugins = plugin_specs }
    package.loaded['lazy.core.plugin'] = {
      has_errors = function(spec)
        return spec._.lazy_error
      end,
    }

    local ok, failure = xpcall(function()
      local runner_callback
      local completed
      local adapter = reload('nv_ide.toolchain.plugins').new {
        lockfile = lockfile,
        list_plugins = function()
          return plugin_specs
        end,
        lazy_install = function()
          return {
            wait = function(_, callback)
              runner_callback = callback
            end,
          }
        end,
      }

      local result = adapter:install {
        on_complete = function(value)
          completed = value
        end,
      }
      h.truthy(result.pending)

      plugin_specs.broken._.installed = true
      plugin_specs.broken._.lazy_error = true
      runner_callback()

      h.falsy(completed.ok)
      h.deep_equal(completed.missing, { 'broken' })
      h.matches(table.concat(completed.errors or {}, '\n'), 'Lazy repair failed for broken')
    end, debug.traceback)

    vim.fn.delete(lockfile)
    package.loaded['lazy.core.config'] = previous_config
    package.loaded['lazy.core.plugin'] = previous_plugin
    if not ok then
      error(failure, 0)
    end
  end)

  h.it('discovers installed-but-errored Lazy specs and invokes update to repair them', function()
    h.with_temp_dir(function(dir)
      local repair_options
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      local locked = vim.json.encode {
        broken = { branch = 'main', commit = string.rep('b', 40) },
        unrelated = { branch = 'main', commit = string.rep('c', 40) },
      }
      write(lockfile, locked)
      local plugin_specs = {
        broken = {
          name = 'broken',
          url = 'https://example.test/broken',
          _ = { installed = true, lazy_error = true },
        },
      }
      local adapter = reload('nv_ide.toolchain.plugins').new {
        lockfile = lockfile,
        list_plugins = function()
          return plugin_specs
        end,
        lazy_has_errors = function(spec)
          return spec._.lazy_error
        end,
        lazy_install = function()
          error 'installed-but-errored specs require locked restore, not install'
        end,
        lazy_repair = function(options)
          repair_options = vim.deepcopy(options)
          write(lockfile, '{"unrelated":"advanced"}')
          return {
            wait = function(_, callback)
              plugin_specs.broken._.lazy_error = false
              callback()
            end,
          }
        end,
      }

      h.deep_equal(adapter:discover(), { 'broken' })
      local completed
      local result = adapter:install {
        show = false,
        on_complete = function(value)
          completed = value
        end,
      }

      h.falsy(result.pending)
      h.deep_equal(repair_options, { wait = false, lockfile = true, plugins = { 'broken' }, show = false })
      h.truthy(completed.ok)
      h.deep_equal(adapter:discover(), {})
      h.equal(read(lockfile), locked, 'repair must preserve the known-good lockfile byte-for-byte')
    end)
  end)

  h.it('fails closed when a missing plugin has no tracked revision', function()
    h.with_temp_dir(function(dir)
      local lockfile = vim.fs.joinpath(dir, 'lazy-lock.json')
      write(lockfile, '{}')
      local adapter = reload('nv_ide.toolchain.plugins').new {
        lockfile = lockfile,
        list_plugins = function()
          return {
            missing = { name = 'missing', url = 'https://example.test/missing', _ = { installed = false } },
          }
        end,
        lazy_has_errors = function()
          return false
        end,
        lazy_install = function()
          error 'unlocked plugin must not be installed'
        end,
      }

      local result = adapter:install()

      h.falsy(result.ok)
      h.matches(result.error, 'missing has no tracked revision')
      h.equal(read(lockfile), '{}')
    end)
  end)

  h.it('bootstraps Lazy from the newest stable semver tag and publishes it atomically', function()
    local plugins = reload 'nv_ide.toolchain.plugins'
    local commands = {}
    local renamed
    local commits = {
      ['v9.12.0'] = string.rep('9', 40),
      ['v11.9.20'] = string.rep('a', 40),
      ['v11.17.5'] = string.rep('b', 40),
    }
    local calls = 0
    local path = plugins.bootstrap_lazy {
      path = '/tmp/lazy.nvim-test',
      candidate = '/tmp/lazy.nvim-test.bootstrap-test',
      stat = function()
        return nil
      end,
      mkdir = function() end,
      delete = function()
        error 'successful bootstrap must not delete its candidate'
      end,
      rename = function(source, destination)
        renamed = { source, destination }
        return true
      end,
      system = function(command)
        commands[#commands + 1] = vim.deepcopy(command)
        calls = calls + 1
        if calls == 1 then
          return {
            wait = function()
              return {
                code = 0,
                stdout = table.concat({
                  commits['v9.12.0'] .. '\trefs/tags/v9.12.0',
                  commits['v11.9.20'] .. '\trefs/tags/v11.9.20',
                  commits['v11.17.5'] .. '\trefs/tags/v11.17.5',
                  string.rep('c', 40) .. '\trefs/tags/v12.0.0-beta.1',
                  string.rep('d', 40) .. '\trefs/tags/not-a-release',
                }, '\n'),
              }
            end,
          }
        end
        if calls == 2 then
          return { wait = function() return { code = 0 } end }
        end
        return { wait = function() return { code = 0, stdout = commits['v11.17.5'] .. '\n' } end }
      end,
    }

    h.equal(path, '/tmp/lazy.nvim-test')
    h.deep_equal(renamed, { '/tmp/lazy.nvim-test.bootstrap-test', '/tmp/lazy.nvim-test' })
    h.deep_equal(commands[1], {
      'git',
      'ls-remote',
      '--tags',
      '--refs',
      'https://github.com/folke/lazy.nvim.git',
      'v*',
    })
    h.truthy(vim.tbl_contains(commands[2], '--branch=v11.17.5'))
    h.falsy(vim.tbl_contains(commands[2], '--branch=stable'))
    h.deep_equal(commands[3], {
      'git',
      '-C',
      '/tmp/lazy.nvim-test.bootstrap-test',
      'rev-parse',
      'HEAD',
    })
  end)

  h.it('does not publish a failed Lazy candidate and includes clone diagnostics', function()
    local plugins = reload 'nv_ide.toolchain.plugins'
    local calls = 0
    local deleted
    h.raises('failed to bootstrap lazy.nvim', function()
      plugins.bootstrap_lazy {
        path = '/tmp/lazy.nvim-test',
        candidate = '/tmp/lazy.nvim-test.bootstrap-test',
        stat = function()
          return nil
        end,
        mkdir = function() end,
        delete = function(path, mode)
          deleted = { path, mode }
          return 0
        end,
        rename = function()
          error 'failed candidate must not be published'
        end,
        system = function()
          calls = calls + 1
          return {
            wait = function()
              if calls == 1 then
                return {
                  code = 0,
                  stdout = string.rep('e', 40) .. '\trefs/tags/v11.17.5\n',
                }
              end
              return { code = 128, stderr = 'network unavailable' }
            end,
          }
        end,
      }
    end)
    h.deep_equal(deleted, { '/tmp/lazy.nvim-test.bootstrap-test', 'rf' })
  end)

  h.it('fails closed instead of trusting a partial pre-existing Lazy bootstrap', function()
    local plugins = reload 'nv_ide.toolchain.plugins'
    h.raises('existing lazy.nvim bootstrap is incomplete', function()
      plugins.bootstrap_lazy {
        path = '/tmp/lazy.nvim-test',
        stat = function(path)
          return path == '/tmp/lazy.nvim-test' and { type = 'directory' } or nil
        end,
        system = function()
          error 'partial pre-existing bootstrap must not access the network'
        end,
      }
    end)
  end)

  h.it('never bootstraps a missing manager from a verified read-only smoke child', function()
    local plugins = reload 'nv_ide.toolchain.plugins'
    local previous = vim.g.nv_ide_toolchain_read_only_startup
    vim.g.nv_ide_toolchain_read_only_startup = true
    local ok, failure = pcall(function()
      h.raises('read-only startup requires an existing lazy.nvim checkout', function()
        plugins.bootstrap_lazy {
          path = '/tmp/lazy.nvim-test',
          stat = function()
            return nil
          end,
          system = function()
            error 'read-only child must not clone a missing manager'
          end,
        }
      end)
    end)
    vim.g.nv_ide_toolchain_read_only_startup = previous
    if not ok then
      error(failure, 0)
    end
  end)

  h.it('keeps stable defaults and verified branch exceptions in the Lazy options', function()
    local manifest = require 'nv_ide.toolchain.manifest'
    local options = reload('nv_ide.toolchain.plugins').lazy_options(manifest)
    h.equal(options.defaults.version, '*')
    h.truthy(options.checker.enabled)
    h.equal(options.checker.enable, nil)

    local exceptions = {}
    for _, spec in ipairs(options.spec) do
      if type(spec) == 'table' and type(spec[1]) == 'string' then
        exceptions[spec[1]] = spec
      end
    end
    for plugin, branch in pairs(manifest.plugin_branches) do
      h.equal(exceptions[plugin].branch, branch)
      h.equal(exceptions[plugin].version, false)
    end

    local previous = vim.g.nv_ide_toolchain_read_only_startup
    vim.g.nv_ide_toolchain_read_only_startup = true
    local read_only = reload('nv_ide.toolchain.plugins').lazy_options(manifest)
    vim.g.nv_ide_toolchain_read_only_startup = previous
    h.falsy(read_only.install.missing)
    h.falsy(read_only.checker.enabled)
  end)

  h.it('removes Tree-sitter build-time updates so the locked updater is the sole owner', function()
    local source = table.concat(vim.fn.readfile 'lua/plugins/treesitter.lua', '\n')
    h.falsy(source:find("build = ':TSUpdate'", 1, true))
  end)
end)

h.describe('update orchestration', function()
  local function state(initial)
    return {
      value = initial,
      read = function(self)
        return self.value and vim.deepcopy(self.value) or nil
      end,
      write = function(self, value)
        self.value = vim.deepcopy(value)
        return true
      end,
      should_run = function()
        return false
      end,
    }
  end

  local function lock()
    return {
      pid = 313,
      acquired = 0,
      released = 0,
      acquire = function(self)
        self.acquired = self.acquired + 1
        return 'shared-token'
      end,
      release = function(self, token)
        h.equal(token, 'shared-token')
        self.released = self.released + 1
        return true
      end,
    }
  end

  h.it('registers ToolchainUpdate and records first-run success through the shared lock and state', function()
    local orchestrator = reload 'nv_ide.toolchain.orchestrator'
    local commands = {}
    local process_lock = lock()
    local saved = state()
    local invocations = {}
    local instance = orchestrator.new {
      manifest = {
        schema_version = 1,
        fingerprint = function()
          return 'fingerprint'
        end,
      },
      state = saved,
      lock = process_lock,
      mason = {
        discover = function()
          return {}
        end,
        install = function()
          return { ok = true }
        end,
      },
      treesitter = {
        discover = function()
          return {}
        end,
        install = function()
          return { ok = true }
        end,
      },
      plugins = {
        update = function(_, options)
          invocations[#invocations + 1] = vim.deepcopy(options)
          local result = { status = 'success', snapshot = '/state/known-good.json' }
          result.manager = {
            before = string.rep('1', 40),
            commit = string.rep('2', 40),
            tag = 'v11.17.5',
          }
          result.observed = {
            before = { mason_receipts = { stylua = '1.0.0' }, treesitter_parser_info = { lua = 'before' } },
            after = { mason_receipts = { stylua = '1.1.0' }, treesitter_parser_info = { lua = 'after' } },
          }
          result.rollback = {
            lazy = 'exact',
            mason = 'not-guaranteed',
            treesitter = 'not-guaranteed',
            limitation = 'Only Lazy rollback is exact',
          }
          options.on_complete(result)
          return result
        end,
      },
      now = function()
        return 789
      end,
    }
    orchestrator.register(instance, {
      create_user_command = function(name, callback, options)
        commands[name] = { callback = callback, options = options }
      end,
      headless = function()
        return false
      end,
    })

    h.truthy(commands.ToolchainUpdate.options.bang)
    commands.ToolchainUpdate.callback { bang = true }
    h.truthy(invocations[1].wait)
    h.deep_equal(invocations[1].lock_owner, { pid = 313, token = 'shared-token' })
    h.equal(process_lock.acquired, 1)
    h.equal(process_lock.released, 1)
    h.equal(saved.value.plugin_update.status, 'success')
    h.equal(saved.value.plugin_update.fingerprint, 'fingerprint')
    h.equal(saved.value.plugin_update.last_success, 789)
    h.deep_equal(saved.value.plugin_update.manager, {
      before = string.rep('1', 40),
      commit = string.rep('2', 40),
      tag = 'v11.17.5',
    })
    h.deep_equal(saved.value.plugin_update.observed, {
      before = { mason_receipts = { stylua = '1.0.0' }, treesitter_parser_info = { lua = 'before' } },
      after = { mason_receipts = { stylua = '1.1.0' }, treesitter_parser_info = { lua = 'after' } },
    })
    h.matches(saved.value.plugin_update.rollback.limitation, 'Only Lazy rollback is exact')
  end)

  h.it('requires one first-run resolution per manifest fingerprint', function()
    local orchestrator = reload 'nv_ide.toolchain.orchestrator'
    local instance = orchestrator.new {
      manifest = {
        schema_version = 1,
        fingerprint = function()
          return 'current'
        end,
      },
      state = state(),
      lock = lock(),
      mason = {
        discover = function()
          return {}
        end,
      },
      treesitter = {
        discover = function()
          return {}
        end,
      },
      plugins = {
        update = function()
          return { status = 'success' }
        end,
      },
    }
    h.truthy(instance:needs_plugin_update())
    instance.state.value = {
      plugin_update = { status = 'success', fingerprint = 'current', last_success = 10 },
    }
    h.falsy(instance:needs_plugin_update())
    instance.state.value.plugin_update.fingerprint = 'previous'
    h.truthy(instance:needs_plugin_update())
  end)

  h.it('contains update completion failures and always releases the shared lock', function()
    local orchestrator = reload 'nv_ide.toolchain.orchestrator'
    local process_lock = lock()
    local instance = orchestrator.new {
      manifest = {
        schema_version = 1,
        fingerprint = function()
          return 'fingerprint'
        end,
      },
      state = state(),
      lock = process_lock,
      mason = {
        discover = function()
          return {}
        end,
      },
      treesitter = {
        discover = function()
          return {}
        end,
      },
      plugins = {
        update = function(_, options)
          local result = { status = 'success' }
          options.on_complete(result)
          return result
        end,
      },
      notify = function() end,
    }

    local ok, result = pcall(instance.update, instance, {
      wait = true,
      on_complete = function()
        error 'update completion exploded'
      end,
    })

    h.truthy(ok)
    h.equal(result.status, 'failed')
    h.matches(table.concat(result.errors or {}, '\n'), 'update completion exploded')
    h.equal(process_lock.released, 1)
    h.falsy(instance.running)
  end)

  h.it('contains update state persistence failures and always releases the shared lock', function()
    local orchestrator = reload 'nv_ide.toolchain.orchestrator'
    local process_lock = lock()
    local instance = orchestrator.new {
      manifest = {
        schema_version = 1,
        fingerprint = function()
          return 'fingerprint'
        end,
      },
      state = {
        read = function()
          error 'update state exploded'
        end,
        write = function()
          return true
        end,
      },
      lock = process_lock,
      mason = {
        discover = function()
          return {}
        end,
      },
      treesitter = {
        discover = function()
          return {}
        end,
      },
      plugins = {
        update = function(_, options)
          local result = { status = 'success' }
          options.on_complete(result)
          return result
        end,
      },
      notify = function() end,
    }

    local ok, result = pcall(instance.update, instance, { wait = true })

    h.truthy(ok)
    h.equal(result.status, 'failed')
    h.matches(table.concat(result.errors or {}, '\n'), 'update state exploded')
    h.equal(process_lock.released, 1)
    h.falsy(instance.running)
  end)

  h.it('reports update timeout but retains ownership until the late updater callback completes', function()
    local orchestrator = reload 'nv_ide.toolchain.orchestrator'
    local process_lock = lock()
    local saved = state()
    local watchdog
    local late_completion
    local reported = {}
    local instance = orchestrator.new {
      manifest = {
        schema_version = 1,
        fingerprint = function()
          return 'fingerprint'
        end,
      },
      state = saved,
      lock = process_lock,
      mason = {
        discover = function()
          return {}
        end,
      },
      treesitter = {
        discover = function()
          return {}
        end,
      },
      plugins = {
        update = function(_, options)
          late_completion = options.on_complete
          return { status = 'started' }
        end,
      },
      timeout_ms = 25,
      defer = function(callback, timeout)
        h.equal(timeout, 25)
        watchdog = callback
      end,
    }

    local started = instance:update {
      wait = false,
      on_complete = function(result)
        reported[#reported + 1] = result.status
      end,
    }
    h.equal(started.status, 'started')
    watchdog()

    h.deep_equal(reported, { 'failed' })
    h.matches(table.concat(saved.value.plugin_update.errors, '\n'), 'timed out after 25 ms')
    h.equal(process_lock.released, 0)
    h.truthy(instance.running)
    h.equal(instance:update({ wait = false }).status, 'busy')

    late_completion { status = 'success', snapshot = '/state/late.json' }
    h.deep_equal(reported, { 'failed' }, 'late completion must not report a second terminal result')
    h.equal(process_lock.released, 1)
    h.falsy(instance.running)
    h.equal(saved.value.plugin_update.status, 'failed', 'the visible timeout evidence must be retained')
  end)
end)
