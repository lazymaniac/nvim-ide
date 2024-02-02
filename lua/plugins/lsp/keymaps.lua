local M = {}

M._keys = nil

function M.get()
  if M._keys then
    return M._keys
  end
  -- stylua: ignore
  M._keys = {
    { '<leader>cl', '<cmd>LspInfo<cr>', desc = 'Lsp Info [cl]' },
    { 'gd', function() require('telescope.builtin').lsp_definitions { reuse_win = true } end, desc = 'Goto Definition <gd>', has = 'definition', },
    { 'gr', '<cmd>Telescope lsp_references<cr>', desc = 'Goto References <gr>' },
    { 'gD', vim.lsp.buf.declaration, desc = 'Goto Declaration <gD>' },
    { 'gI', function() require('telescope.builtin').lsp_implementations { reuse_win = true } end, desc = 'Goto Implementation <gI>', },
    { 'gy', function() require('telescope.builtin').lsp_type_definitions { reuse_win = true } end, desc = 'Goto Type Definition <gy>', },
    { '<leader>cs', function() require('telescope.builtin').lsp_document_symbols() end, desc = 'Document Symbols [cs]', },
    { '<leader>cw', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, desc = 'Workspace Symbols [cw]', },
    { 'K', vim.lsp.buf.hover, desc = 'Hover Documentation <K>' },
    { 'gK', vim.lsp.buf.signature_help, desc = 'Signature Documentation <gK>', has = 'signatureHelp' },
    { '<C-k>', vim.lsp.buf.signature_help, mode = 'i', desc = 'Signature Help <C-k>', has = 'signatureHelp' },
    { '<leader>ca', function() require('actions-preview').code_actions() end, desc = 'Code Action [ca]', mode = { 'n', 'v' }, has = 'codeAction' },
    { '<leader>cWa', vim.lsp.buf.add_workspace_folder, 'Add Workspace Folder [cWa]' },
    { '<leader>cWr', vim.lsp.buf.remove_workspace_folder, 'Remove Workspace Folder [cWr]' },
    { '<leader>cWl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, 'List Workspace Folders [cWl]', },
  }
  if require('util').has 'inc-rename.nvim' then
    M._keys[#M._keys + 1] = {
      '<leader>cr',
      function()
        local inc_rename = require 'inc_rename'
        return ':' .. inc_rename.config.cmd_name .. ' ' .. vim.fn.expand '<cword>'
      end,
      expr = true,
      desc = 'Code Rename [cr]',
      has = 'rename',
    }
  else
    M._keys[#M._keys + 1] = { '<leader>cr', vim.lsp.buf.rename, desc = 'Code Rename [cr]', has = 'rename' }
  end
  return M._keys
end

---@param method string
function M.has(buffer, method)
  method = method:find '/' and method or 'textDocument/' .. method
  local clients = require('util').lsp.get_clients { bufnr = buffer }
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      return true
    end
  end
  return false
end

function M.resolve(buffer)
  local Keys = require 'lazy.core.handler.keys'
  if not Keys.resolve then
    return {}
  end
  local spec = M.get()
  local opts = require('util').opts 'nvim-lspconfig'
  local clients = require('util').lsp.get_clients { bufnr = buffer }
  for _, client in ipairs(clients) do
    local maps = opts.servers[client.name] and opts.servers[client.name].keys or {}
    vim.list_extend(spec, maps)
  end
  return Keys.resolve(spec)
end

function M.on_attach(_, buffer)
  local Keys = require 'lazy.core.handler.keys'
  local keymaps = M.resolve(buffer)

  for _, keys in pairs(keymaps) do
    if not keys.has or M.has(buffer, keys.has) then
      local opts = Keys.opts(keys)
      opts.has = nil
      opts.silent = opts.silent ~= false
      opts.buffer = buffer
      vim.keymap.set(keys.mode or 'n', keys.lhs, keys.rhs, opts)
    end
  end
end

return M
