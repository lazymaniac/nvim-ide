local Util = require 'util'

local M = {}

function M.option(option, silent, values)
  if values then
    if vim.opt_local[option]:get() == values[1] then
      ---@diagnostic disable-next-line: no-unknown
      vim.opt_local[option] = values[2]
    else
      ---@diagnostic disable-next-line: no-unknown
      vim.opt_local[option] = values[1]
    end
    return Util.info('Set ' .. option .. ' to ' .. vim.opt_local[option]:get(), { title = 'Option' })
  end
  ---@diagnostic disable-next-line: no-unknown
  vim.opt_local[option] = not vim.opt_local[option]:get()
  if not silent then
    if vim.opt_local[option]:get() then
      Util.info('Enabled ' .. option, { title = 'Option' })
    else
      Util.warn('Disabled ' .. option, { title = 'Option' })
    end
  end
end

local nu = { number = true, relativenumber = true }
function M.number()
  if vim.opt_local.number:get() or vim.opt_local.relativenumber:get() then
    nu = { number = vim.opt_local.number:get(), relativenumber = vim.opt_local.relativenumber:get() }
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    Util.warn('Disabled line numbers', { title = 'Option' })
  else
    vim.opt_local.number = nu.number
    vim.opt_local.relativenumber = nu.relativenumber
    Util.info('Enabled line numbers', { title = 'Option' })
  end
end

local enabled = vim.diagnostic.is_enabled()
function M.diagnostics()
  enabled = not enabled
  if enabled then
    vim.diagnostic.enable()
    Util.info('Enabled diagnostics', { title = 'Diagnostics' })
  else
    vim.diagnostic.enable(false)
    Util.warn('Disabled diagnostics', { title = 'Diagnostics' })
  end
end

function M.inlay_hints()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end

setmetatable(M, {
  __call = function(m, ...)
    return m.option(...)
  end,
})

return M
