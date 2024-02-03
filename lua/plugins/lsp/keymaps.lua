local M = {}

M._keys = nil

function M.get()
  if M._keys then
    return M._keys
  end
  -- stylua: ignore
  M._keys = {
    { '<leader>li', '<cmd>LspInfo<cr>', desc = 'Lsp Info [li]' },
    { '<leader>cl', '<cmd>Lspsaga finder<CR>', desc = 'Symbol Finder [cl]' },
    { 'gd', '<cmd>Lspsaga peek_definition<CR>', desc = 'Goto Definition <gd>' },
    { 'gr', '<cmd>Lspsaga finder ref<CR>', desc = 'Goto References <gr>' },
    { 'gI', '<cmd>Lspsaga finder imp<CR>', desc = 'Goto Implementation <gI>', },
    { 'gD', '<cmd>Lspsaga peek_type_definitions<CR>', desc = 'Goto Type Definition <gy>', },
    { '<leader>cs', function() require('telescope.builtin').lsp_document_symbols() end, desc = 'Document Symbols [cs]', },
    { '<leader>cw', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, desc = 'Workspace Symbols [cw]', },
    { 'K', '<cmd>Lspsaga hover_doc<cr>', desc = 'Hover Documentation <K>' },
    { 'gK', vim.lsp.buf.signature_help, desc = 'Signature Documentation <gK>', has = 'signatureHelp' },
    { '<C-k>', vim.lsp.buf.signature_help, mode = 'i', desc = 'Signature Help <C-k>', has = 'signatureHelp' },
    { '<leader>ca', '<cmd>Lspsaga code_action<cr>', desc = 'Code Action [ca]', mode = { 'n', 'v' }},
    { '<leader>ci', '<cmd>Lspsaga incoming_calls<cr>', desc = 'Incoming Calls [ci]', mode = {'n'}},
    { '<leader>co', '<cmd>Lspsaga outgoing_calls<cr>', desc = 'Outgoing Calls [co]', mode = {'n'}},
    { '<leader>cr', '<cmd>Lspsaga rename<cr>', desc = 'Rename [cr]', mode = {'n', 'v'}},
  }
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
