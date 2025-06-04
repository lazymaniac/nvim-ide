local M = {}

M._keys = nil

function M.get()
  if M._keys then
    return M._keys
  end
  M._keys = {
    { '<leader>li', '<cmd>LspInfo<cr>', desc = 'Lsp Info [li]' },
    {
      '<leader>ci',
      '<cmd>Trouble incoming_calls_perv<cr>',
      desc = 'Incoming Calls [ci]',
    },
    {
      '<leader>co',
      '<cmd> Trouble outgoing_calls_prev<cr>',
      desc = 'Outgoing Calls [co]',
    },
    { 'K', vim.lsp.buf.hover, desc = 'Hover Documentation <K>' },
    { 'gK', vim.lsp.buf.signature_help, desc = 'Signature Documentation <gK>', has = 'signatureHelp' },
    { '<C-k>', vim.lsp.buf.signature_help, mode = 'i', desc = 'Signature Help <C-k>', has = 'signatureHelp' },
    {
      '<leader>ca',
      '<cmd>lua require("fastaction").code_action()<cr>',
      desc = 'Code Action [ca]',
      mode = { 'n' },
    },
    {
      '<leader>ca',
      '<esc><cmd>lua require("fastaction").range_code_action()<CR>',
      desc = 'Code Action [ca]',
      mode = { 'v' },
    },
    {
      '<leader>cr',
      '<cmd>lua require "nvchad.lsp.renamer"()<cr>',
      desc = 'Rename [cr]',
      mode = { 'n' },
    },
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
