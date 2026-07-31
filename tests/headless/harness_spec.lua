local h = require('tests.headless.harness')

h.describe('headless harness', function()
  h.it('disables plugin loading in the minimal init', function()
    h.falsy(vim.o.loadplugins, 'minimal_init.lua must disable user and start plugins')
  end)

  h.describe('nested suites', function()
    h.it('retains the complete test name', function()
      h.equal(h.current_test_name(), 'headless harness > nested suites > retains the complete test name')
    end)
  end)

  h.it('compares scalar and nested values', function()
    h.equal('value', 'value')
    h.deep_equal({ one = 1, nested = { true, 'two' } }, { one = 1, nested = { true, 'two' } })
    h.truthy({})
  end)

  h.it('matches raised errors', function()
    h.raises('expected failure', function()
      error('expected failure', 0)
    end)
  end)

  h.it('cleans temporary directories after use', function()
    local temporary_path
    h.with_temp_dir(function(path)
      temporary_path = path
      h.truthy(vim.uv.fs_stat(path), 'temporary directory should exist inside callback')
      local file = assert(io.open(vim.fs.joinpath(path, 'sentinel'), 'w'))
      file:write('test')
      file:close()
    end)
    h.falsy(vim.uv.fs_stat(temporary_path), 'temporary directory should be removed after callback')
  end)

  h.it('captures assertion context without failing the outer test', function()
    local failure = h.capture_failure('captured equality', function()
      h.equal('actual value', 'expected value')
    end)

    h.matches(failure, 'captured equality')
    h.matches(failure, 'actual value')
    h.matches(failure, 'expected value')
  end)
end)
