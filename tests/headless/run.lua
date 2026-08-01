local harness = require('tests.headless.harness')

local source = debug.getinfo(1, 'S').source:sub(2)
local headless_dir = vim.fs.dirname(vim.fs.normalize(source))
local root = vim.fs.dirname(vim.fs.dirname(headless_dir))

local specs = {}
for index = 1, #arg do
  local path = arg[index]
  if not vim.startswith(path, '/') then
    path = vim.fs.joinpath(root, path)
  end
  specs[#specs + 1] = vim.fs.normalize(path)
end

if #specs == 0 then
  specs = vim.fn.glob(vim.fs.joinpath(headless_dir, '*_spec.lua'), false, true)
  table.sort(specs)
end

local result = harness.run(specs)
if result.failed > 0 then
  error(('%d headless spec(s) failed'):format(result.failed), 0)
end
