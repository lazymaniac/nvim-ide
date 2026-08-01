local h = require 'tests.headless.harness'

local function load_project()
  package.loaded['nv_ide.project'] = nil
  return require 'nv_ide.project'
end

h.describe('shared project context', function()
  h.it('finds the nearest project root from a path or buffer', function()
    h.with_temp_dir(function(tmp)
      local repo = vim.fs.joinpath(tmp, 'repo')
      local package = vim.fs.joinpath(repo, 'packages', 'web')
      local source = vim.fs.joinpath(package, 'src', 'example.ts')
      vim.fn.mkdir(vim.fs.joinpath(repo, '.git'), 'p')
      vim.fn.mkdir(vim.fs.dirname(source), 'p')
      vim.fn.writefile({ '{}' }, vim.fs.joinpath(package, 'package.json'))
      vim.fn.writefile({ 'export {}' }, source)

      local project = load_project()
      local canonical_package = assert(vim.uv.fs_realpath(package))
      h.equal(project.root(source, { 'package.json', '.git' }), canonical_package)
      local bufnr = vim.fn.bufadd(source)
      h.equal(project.root(bufnr, { 'package.json', '.git' }), canonical_package)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)

  h.it('uses path components for containment', function()
    local project = load_project()
    h.truthy(project.contains('/work/app', '/work/app/src/main.lua'))
    h.truthy(project.contains('/work/app', '/work/app'))
    h.falsy(project.contains('/work/app', '/work/application/main.lua'))
  end)

  h.it('resolves activated, project-local, then ambient executables', function()
    local project = load_project()
    local existing = {
      ['/active/bin/python'] = true,
      ['/repo/.venv/bin/python'] = true,
      ['/usr/bin/python3'] = true,
    }
    local deps = {
      executable = function(path) return existing[path] == true end,
      exepath = function(command) return command == 'python3' and '/usr/bin/python3' or '' end,
    }
    local candidates = {
      activated = { '/active/bin/python' },
      project = { '.venv/bin/python' },
      ambient = { 'python3' },
    }

    h.equal(project.executable('/repo', candidates, deps), '/active/bin/python')
    existing['/active/bin/python'] = nil
    h.equal(project.executable('/repo', candidates, deps), '/repo/.venv/bin/python')
    existing['/repo/.venv/bin/python'] = nil
    h.equal(project.executable('/repo', candidates, deps), '/usr/bin/python3')
  end)

  h.it('discovers JavaScript package and Jest context', function()
    h.with_temp_dir(function(tmp)
      local source = vim.fs.joinpath(tmp, 'src', 'example.test.ts')
      vim.fn.mkdir(vim.fs.joinpath(tmp, 'src'), 'p')
      vim.fn.mkdir(vim.fs.joinpath(tmp, 'node_modules', '.bin'), 'p')
      vim.fn.mkdir(vim.fs.joinpath(tmp, 'spec', 'support'), 'p')
      vim.fn.writefile({ '{}' }, vim.fs.joinpath(tmp, 'package.json'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'pnpm-lock.yaml'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'jest.config.ts'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, '.mocharc.json'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'karma.conf.ts'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'spec', 'support', 'jasmine.json'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'node_modules', '.bin', 'jest'))
      vim.fn.writefile({}, source)

      local context = load_project().javascript(source, {
        executable = function(path)
          return path == vim.fs.joinpath(assert(vim.uv.fs_realpath(tmp)), 'node_modules', '.bin', 'jest')
        end,
      })
      local canonical = assert(vim.uv.fs_realpath(tmp))
      h.equal(context.root, canonical)
      h.equal(context.package_manager, 'pnpm')
      h.deep_equal(context.configs, {
        jasmine = vim.fs.joinpath(canonical, 'spec', 'support', 'jasmine.json'),
        jest = vim.fs.joinpath(canonical, 'jest.config.ts'),
        karma = vim.fs.joinpath(canonical, 'karma.conf.ts'),
        mocha = vim.fs.joinpath(canonical, '.mocharc.json'),
      })
      h.equal(context.executables.jest, vim.fs.joinpath(canonical, 'node_modules', '.bin', 'jest'))
    end)
  end)

  h.it('inherits hoisted JavaScript tooling within a monorepo boundary', function()
    h.with_temp_dir(function(tmp)
      local package_root = vim.fs.joinpath(tmp, 'packages', 'web')
      local source = vim.fs.joinpath(package_root, 'src', 'example.test.ts')
      local jest = vim.fs.joinpath(tmp, 'node_modules', '.bin', 'jest')
      local launch = vim.fs.joinpath(tmp, '.vscode', 'launch.json')
      vim.fn.mkdir(vim.fs.joinpath(tmp, '.git'), 'p')
      vim.fn.mkdir(vim.fs.dirname(source), 'p')
      vim.fn.mkdir(vim.fs.dirname(jest), 'p')
      vim.fn.mkdir(vim.fs.dirname(launch), 'p')
      vim.fn.writefile({ '{}' }, vim.fs.joinpath(package_root, 'package.json'))
      vim.fn.writefile({}, vim.fs.joinpath(tmp, 'pnpm-lock.yaml'))
      vim.fn.writefile({}, jest)
      vim.fn.writefile({ '{ "configurations": [] }' }, launch)
      vim.fn.writefile({ 'export {}' }, source)

      local canonical = assert(vim.uv.fs_realpath(tmp))
      local canonical_jest = vim.fs.joinpath(canonical, 'node_modules', '.bin', 'jest')
      local context = load_project().javascript(source, {
        executable = function(path) return path == canonical_jest end,
      })
      h.equal(context.root, vim.fs.joinpath(canonical, 'packages', 'web'))
      h.equal(context.workspace_root, canonical)
      h.equal(context.package_manager, 'pnpm')
      h.equal(context.executables.jest, canonical_jest)
      h.equal(context.launch_json, vim.fs.joinpath(canonical, '.vscode', 'launch.json'))
    end)
  end)

  h.it('caches only positive directory trust decisions', function()
    local project = load_project()
    local calls, cache = 0, {}
    local deps = {
      cache = cache,
      secure_read = function()
        calls = calls + 1
        return calls >= 2 and true or nil
      end,
    }

    h.falsy(project.trusted('/repo', deps))
    h.truthy(project.trusted('/repo', deps))
    h.truthy(project.trusted('/repo', deps))
    h.equal(calls, 2)
  end)
end)
