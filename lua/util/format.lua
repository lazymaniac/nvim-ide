local M = {}

function M.formatexpr()
  return require('conform').formatexpr()
end

function M.enabled(bufnr)
  bufnr = bufnr or 0
  local value = vim.b[bufnr].autoformat
  if value ~= nil then return value == true end
  return vim.g.autoformat == true
end

function M.toggle(buffer_local)
  if buffer_local then
    local bufnr = vim.api.nvim_get_current_buf()
    vim.b[bufnr].autoformat = not M.enabled(bufnr)
    return
  end
  vim.g.autoformat = not (vim.g.autoformat == true)
  vim.b.autoformat = nil
end

function M.format_on_save(bufnr)
  if M.enabled(bufnr) then return { lsp_format = 'fallback' } end
end

return M
