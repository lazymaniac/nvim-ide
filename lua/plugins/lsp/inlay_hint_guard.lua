local M = {}

local installed = false

function M.setup()
  if installed then return end
  installed = true

  local api = vim.api
  local namespace = api.nvim_create_namespace('nvim.lsp.inlayhint')
  local set_extmark = api.nvim_buf_set_extmark

  api.nvim_buf_set_extmark = function(bufnr, ns, row, col, opts)
    if ns == namespace then
      -- Neovim can redraw a cached hint after its line has changed. Allow
      -- the extmark API to clamp a stale column to the end of that line.
      opts = vim.tbl_extend('force', opts, { strict = false })
    end
    return set_extmark(bufnr, ns, row, col, opts)
  end
end

return M
