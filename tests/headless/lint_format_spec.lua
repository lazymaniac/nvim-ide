local h = require('tests.headless.harness')

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then
      return spec
    end
  end
  error('plugin spec not found: ' .. name)
end

local function configure_lint()
  local calls = {}
  local trusted = false
  local registration = {}
  local lint = {
    linters = { eslint_d = { env = {} } },
    linters_by_ft = {},
    try_lint = function(names, opts)
      calls[#calls + 1] = { names = vim.deepcopy(names), opts = vim.deepcopy(opts) }
    end,
  }
  local project = {
    root = function(path)
      h.truthy(vim.startswith(path, '/repo/'))
      return '/repo'
    end,
    trusted = function(root)
      h.equal(root, '/repo')
      return trusted
    end,
    contains = function(root, path)
      local relative = vim.fs.relpath(root, path)
      return relative ~= nil and relative ~= '..' and not vim.startswith(relative, '../')
    end,
  }
  local previous_lint = package.loaded.lint
  local previous_project = package.loaded['nv_ide.project']
  local previous_augroup = vim.api.nvim_create_augroup
  local previous_autocmd = vim.api.nvim_create_autocmd
  package.loaded.lint = lint
  package.loaded['nv_ide.project'] = project
  vim.api.nvim_create_augroup = function(name, opts)
    h.equal(name, 'nvide_lint')
    h.deep_equal(opts, { clear = true })
    return 71
  end
  vim.api.nvim_create_autocmd = function(events, opts)
    registration = { events = events, opts = opts }
    return 72
  end

  local spec = plugin(dofile('lua/plugins/lint_and_format.lua'), 'mfussenegger/nvim-lint')
  local ok, err = xpcall(spec.config, debug.traceback)

  package.loaded.lint = previous_lint
  package.loaded['nv_ide.project'] = previous_project
  vim.api.nvim_create_augroup = previous_augroup
  vim.api.nvim_create_autocmd = previous_autocmd
  if not ok then error(err, 0) end

  local function save(path, filetype)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, path)
    vim.bo[bufnr].filetype = filetype
    local saved, failure = xpcall(function()
      registration.opts.callback { buf = bufnr }
    end, debug.traceback)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    if not saved then error(failure, 0) end
  end

  return lint, calls, registration, save, function(value) trusted = value end
end

h.describe('lint and format policy', function()
  h.it('uses real nvim-lint identifiers and an explicit kube-linter', function()
    local lint = configure_lint()

    h.deep_equal(lint.linters_by_ft.ansible, { 'ansible_lint' })
    h.deep_equal(lint.linters_by_ft.go, { 'golangcilint' })
    h.deep_equal(lint.linters_by_ft.helm, { 'kube_linter' })

    local kube = lint.linters.kube_linter
    h.truthy(kube, 'kube_linter must be explicitly defined')
    h.equal(kube.cmd, 'kube-linter')
    h.deep_equal(kube.args, { 'lint', '--format', 'plain' })
    h.falsy(kube.append_fname == false, 'kube-linter must receive the filename exactly once')
    h.equal(kube.stream, 'both')
    h.truthy(kube.ignore_exitcode)
    h.equal(type(kube.parser), 'function')

    local diagnostics = kube.parser(
      'deployment.yaml: (object: default/example apps/v1, Kind=Deployment) missing limits (check: required-label)\n'
        .. 'Error: found 1 lint errors',
      0
    )
    h.equal(#diagnostics, 1)
    h.equal(diagnostics[1].lnum, 0)
    h.equal(diagnostics[1].col, 0)
    h.equal(diagnostics[1].source, 'kube-linter')
    h.truthy(diagnostics[1].message:find('missing limits', 1, true))
  end)

  h.it('runs deterministic lint only after a trusted project save', function()
    local lint, calls, registration, save, set_trusted = configure_lint()
    save('/repo/app.py', 'python')
    h.equal(#calls, 0, 'automatic lint must skip untrusted projects')
    h.equal(registration.events, 'BufWritePost')
    h.equal(registration.opts.group, 71)

    set_trusted(true)
    save('/repo/app.py', 'python')
    save('/repo/config.yml', 'yaml')
    save('/repo/.github/workflows/ci.yml', 'yaml')
    h.deep_equal(calls, {
      { names = { 'ruff' }, opts = { cwd = '/repo' } },
      { names = { 'yamllint' }, opts = { cwd = '/repo' } },
      { names = { 'yamllint', 'actionlint' }, opts = { cwd = '/repo' } },
    })
    h.deep_equal(lint.linters_by_ft.python, { 'ruff' })
    h.deep_equal(lint.linters_by_ft.javascript, { 'eslint_d' })
    h.deep_equal(lint.linters_by_ft.javascriptreact, { 'eslint_d' })
    h.falsy(vim.inspect(lint.linters_by_ft):find('trivy', 1, true))
    h.equal(lint.linters.eslint_d.env.ESLINT_D_MISS, 'fail')
  end)

  h.it('adapts Conform to global and buffer-local format policy', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local previous_conform = package.loaded.conform
    local previous_format = package.loaded['util.format']
    local previous_global = vim.g.autoformat
    local previous_buffer = vim.b[bufnr].autoformat
    package.loaded.conform = {
      formatexpr = function() return 'conform-formatexpr' end,
    }
    package.loaded['util.format'] = nil

    local ok, err = xpcall(function()
      local format = require 'util.format'
      vim.g.autoformat = false
      vim.b[bufnr].autoformat = nil
      h.falsy(format.enabled(bufnr))
      h.falsy(format.format_on_save(bufnr))
      h.equal(format.formatexpr(), 'conform-formatexpr')

      format.toggle()
      h.truthy(vim.g.autoformat)
      h.deep_equal(format.format_on_save(bufnr), { lsp_format = 'fallback' })

      format.toggle(true)
      h.equal(vim.b[bufnr].autoformat, false)
      vim.b[bufnr].autoformat = nil
      h.truthy(format.enabled(bufnr))
    end, debug.traceback)

    package.loaded.conform = previous_conform
    package.loaded['util.format'] = previous_format
    vim.g.autoformat = previous_global
    vim.b[bufnr].autoformat = previous_buffer
    if not ok then error(err, 0) end
  end)

  h.it('uses current Conform fallback policy and the Vue filetype', function()
    local conform = plugin(dofile('lua/plugins/lint_and_format.lua'), 'stevearc/conform.nvim')
    local dependency_text = vim.inspect(conform.dependencies or {})
    h.falsy(dependency_text:find('mason%-bridge'), 'mason-bridge must not own formatter policy')

    local calls = {}
    local previous = package.loaded.conform
    local previous_util = package.loaded.util
    package.loaded.conform = {
      format = function(opts)
        calls[#calls + 1] = opts
      end,
      setup = function(opts)
        calls.setup = opts
      end,
    }
    package.loaded.util = { format = require 'util.format' }

    for _, key in ipairs(conform.keys or {}) do
      if type(key[2]) == 'function' then key[2]() end
    end
    local ok, err = xpcall(conform.config, debug.traceback)
    package.loaded.conform = previous
    package.loaded.util = previous_util
    if not ok then error(err, 0) end

    h.equal(#calls, 2)
    for _, opts in ipairs(calls) do
      h.equal(opts.lsp_format, 'fallback')
      h.falsy(opts.lsp_fallback, 'deprecated lsp_fallback must be absent')
    end
    h.deep_equal(calls.setup.formatters_by_ft.vue, { 'prettierd' })
    h.falsy(calls.setup.formatters_by_ft.vuejs, 'vuejs is not a Neovim filetype')
    local ft = calls.setup.formatters_by_ft
    h.truthy(ft.sh, 'sh formatter alias is missing')
    h.deep_equal({ ft.sh[1], ft.sh[2] }, { 'beautysh', 'shellharden' })
    h.truthy(ft.sh.stop_after_first)
    h.truthy(ft.bash.stop_after_first)
    h.deep_equal(ft.javascriptreact, { 'prettierd' })
    h.deep_equal(ft.typescriptreact, { 'prettierd' })
    h.deep_equal(ft.svelte, { 'prettierd' })
    h.deep_equal(ft.jsonc, { 'prettierd' })
    h.deep_equal(ft.eruby, { 'erb_format' })
    h.deep_equal(ft.cmake, { 'cmake_format' })
    h.deep_equal(ft.xml, { 'xmlformatter' })
    for _, filetype in ipairs { 'angular', 'json', 'sql' } do
      h.truthy(ft[filetype].stop_after_first)
    end
    h.deep_equal(ft.python, { 'black', 'docformatter' })
    h.falsy(ft.python.stop_after_first)
    h.equal(calls.setup.formatters.prettierd.env.PRETTIERD_LOCAL_PRETTIER_ONLY, '1')
    h.equal(type(calls.setup.format_on_save), 'function')
    local previous_autoformat = vim.g.autoformat
    vim.g.autoformat = false
    h.falsy(calls.setup.format_on_save(0), 'format-on-save must remain disabled by default')
    vim.g.autoformat = previous_autoformat
  end)
end)
