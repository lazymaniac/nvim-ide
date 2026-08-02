local startup_error = vim.v.errmsg
assert(startup_error == '', 'Neovim startup failed before CodeCompanion reasoning verification: ' .. startup_error)

require('lazy').load { plugins = { 'codecompanion.nvim' } }

local tools = require('codecompanion.config').interactions.chat.tools
local expected_tool_names = {
  'reasoning_frame',
  'reasoning_evidence',
  'reasoning_options',
  'reasoning_review',
  'reasoning_synthesis',
}
local expected_paths = {
  reasoning_frame = '_extensions.reasoning.tools.frame',
  reasoning_evidence = '_extensions.reasoning.tools.evidence',
  reasoning_options = '_extensions.reasoning.tools.options',
  reasoning_review = '_extensions.reasoning.tools.review',
  reasoning_synthesis = '_extensions.reasoning.tools.synthesis',
}

assert(tools.groups.reasoning, 'reasoning group is missing')
assert(vim.tbl_contains(tools.opts.default_tools, 'reasoning'), 'reasoning is not attached by default')
assert(vim.deep_equal(tools.groups.reasoning.tools, expected_tool_names), 'reasoning tool set differs')
for _, name in ipairs(expected_tool_names) do
  assert(type(tools[name]) == 'table', name .. ' tool is missing')
  assert(tools[name].path == expected_paths[name], name .. ' tool path differs')
end
vim.api.nvim_out_write 'CODECOMPANION REASONING PASS\n'
