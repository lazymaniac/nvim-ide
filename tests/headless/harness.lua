local M = {}

local suites = {}
local tests = {}
local active_test

local function inspect(value)
  return vim.inspect(value, { newline = ' ', indent = '' })
end

local function fail(message, level)
  error(message, (level or 1) + 1)
end

local function test_name(name)
  local parts = vim.list_extend(vim.deepcopy(suites), { name })
  return table.concat(parts, ' > ')
end

function M.describe(name, body)
  suites[#suites + 1] = name
  local ok, err = xpcall(body, debug.traceback)
  suites[#suites] = nil
  if not ok then
    error(err, 0)
  end
end

function M.it(name, body)
  tests[#tests + 1] = { name = test_name(name), body = body }
end

function M.current_test_name()
  return active_test
end

function M.equal(actual, expected, message)
  if actual ~= expected then
    fail(message or ('expected %s, actual %s'):format(inspect(expected), inspect(actual)), 1)
  end
end

function M.deep_equal(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    fail(message or ('expected %s, actual %s'):format(inspect(expected), inspect(actual)), 1)
  end
end

function M.truthy(value, message)
  if not value then
    fail(message or ('expected truthy value, actual %s'):format(inspect(value)), 1)
  end
end

function M.falsy(value, message)
  if value then
    fail(message or ('expected falsy value, actual %s'):format(inspect(value)), 1)
  end
end

function M.matches(value, expected, message)
  local actual = tostring(value)
  if not actual:find(expected, 1, true) then
    fail(message or ('expected %s to contain %s'):format(inspect(actual), inspect(expected)), 1)
  end
end

function M.raises(expected, body)
  local ok, err = pcall(body)
  if ok then
    fail(('expected error containing %s, but no error was raised'):format(inspect(expected)), 1)
  end
  M.matches(err, expected)
end

function M.capture_failure(name, body)
  local ok, err = xpcall(body, debug.traceback)
  if ok then
    fail(('expected captured check %s to fail'):format(inspect(name)), 1)
  end
  return ('%s: %s'):format(name, err)
end

function M.with_temp_dir(body)
  local path = vim.fn.tempname()
  assert(vim.fn.mkdir(path, 'p') == 1, 'failed to create temporary directory: ' .. path)

  local ok, result = xpcall(function()
    return body(path)
  end, debug.traceback)
  local deleted = vim.fn.delete(path, 'rf')

  if deleted ~= 0 then
    error('failed to remove temporary directory: ' .. path, 0)
  end
  if not ok then
    error(result, 0)
  end
  return result
end

local function reset()
  suites = {}
  tests = {}
  active_test = nil
end

function M.run(specs)
  reset()

  local failed = 0
  for _, spec in ipairs(specs) do
    local ok, err = xpcall(function()
      dofile(spec)
    end, debug.traceback)
    if not ok then
      failed = failed + 1
      vim.api.nvim_err_writeln(('FAIL %s\n%s'):format(spec, err))
    end
  end

  local passed = 0
  for _, test in ipairs(tests) do
    active_test = test.name
    local ok, err = xpcall(test.body, debug.traceback)
    if ok then
      passed = passed + 1
      vim.api.nvim_out_write(('PASS %s\n'):format(test.name))
    else
      failed = failed + 1
      vim.api.nvim_err_writeln(('FAIL %s\n%s'):format(test.name, err))
    end
  end
  active_test = nil

  vim.api.nvim_out_write(('RESULT %d passed, %d failed\n'):format(passed, failed))
  return { total = passed + failed, passed = passed, failed = failed }
end

return M
