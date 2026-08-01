local h = require('tests.headless.harness')

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then
      return spec
    end
  end
  error('plugin spec not found: ' .. name)
end

local function contains(values, expected)
  for _, value in ipairs(values or {}) do
    if value == expected then
      return true
    end
  end
  return false
end

local function configure_lint(executables)
  local lint = {
    linters = {},
    linters_by_ft = {},
    try_lint = function() end,
  }
  local autocmd
  local previous_lint = package.loaded.lint
  local previous_executable = vim.fn.executable
  local previous_autocmd = vim.api.nvim_create_autocmd
  package.loaded.lint = lint
  vim.fn.executable = function(command)
    return executables[command] and 1 or 0
  end
  vim.api.nvim_create_autocmd = function(_, opts)
    autocmd = opts.callback
    return 1
  end

  local spec = plugin(dofile('lua/plugins/lint_and_format.lua'), 'mfussenegger/nvim-lint')
  local ok, err = xpcall(spec.config, debug.traceback)

  package.loaded.lint = previous_lint
  vim.fn.executable = previous_executable
  vim.api.nvim_create_autocmd = previous_autocmd
  if not ok then
    error(err, 0)
  end
  return lint, autocmd
end

h.describe('lint and format policy', function()
  h.it('uses real nvim-lint identifiers and an explicit kube-linter', function()
    local lint = configure_lint({
      ruff = true,
      flake8 = true,
      mypy = true,
      pylint = true,
    })

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

  h.it('registers Python linters only while their executables are available', function()
    local lint, refresh = configure_lint({ ruff = true, mypy = true })
    h.deep_equal(lint.linters_by_ft.python, { 'ruff', 'mypy' })

    local previous_executable = vim.fn.executable
    vim.fn.executable = function(command)
      return ({ flake8 = 1, pylint = 1 })[command] or 0
    end
    local ok, err = xpcall(refresh, debug.traceback)
    vim.fn.executable = previous_executable
    if not ok then error(err, 0) end

    h.deep_equal(lint.linters_by_ft.python, { 'pylint', 'flake8' })
    h.falsy(contains(lint.linters_by_ft.python, 'ruff'))
    h.falsy(contains(lint.linters_by_ft.python, 'mypy'))
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
    h.equal(type(calls.setup.format_on_save), 'function')
    local previous_autoformat = vim.g.autoformat
    vim.g.autoformat = false
    h.falsy(calls.setup.format_on_save(0), 'format-on-save must remain disabled by default')
    vim.g.autoformat = previous_autoformat
  end)
end)
