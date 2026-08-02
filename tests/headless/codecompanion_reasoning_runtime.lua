require('lazy').load { plugins = { 'codecompanion.nvim' } }

local tools = require('codecompanion.config').interactions.chat.tools
assert(tools.groups.reasoning, 'reasoning group is missing')
assert(vim.tbl_contains(tools.opts.default_tools, 'reasoning'), 'reasoning is not attached by default')
assert(vim.deep_equal(tools.groups.reasoning.tools, {
  'reasoning_frame',
  'reasoning_evidence',
  'reasoning_options',
  'reasoning_review',
  'reasoning_synthesis',
}), 'reasoning tool set differs')
vim.api.nvim_out_write 'CODECOMPANION REASONING PASS\n'
