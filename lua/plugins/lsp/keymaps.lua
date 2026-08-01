local M = {}
local configured_handlers = setmetatable({}, { __mode = 'k' })

local hover = vim.lsp.buf.hover
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.hover = function()
    return hover({
        max_width = 100,
        max_height = 14,
        border = 'rounded',
    })
end

local base_keys = {
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

function M.get()
  return vim.deepcopy(base_keys)
end

---@param method string
function M.has(buffer, method, deps)
  method = method:find '/' and method or 'textDocument/' .. method
  local clients = deps and deps.clients or require('util').lsp.get_clients { bufnr = buffer }
  for _, client in ipairs(clients) do
    if client:supports_method(method, buffer) then
      return true
    end
  end
  return false
end

function M.resolve(buffer, deps)
  deps = deps or {}
  local Keys = deps.Keys
  if not Keys and not deps.resolve then Keys = require 'lazy.core.handler.keys' end
  local resolve = deps.resolve or Keys.resolve
  if not resolve then
    return {}
  end
  local spec = M.get()
  local opts = deps.server_opts and { servers = deps.server_opts } or require('util').opts 'nvim-lspconfig'
  local clients = deps.clients or require('util').lsp.get_clients { bufnr = buffer }
  for _, client in ipairs(clients) do
    local maps = opts.servers and opts.servers[client.name] and opts.servers[client.name].keys or {}
    vim.list_extend(spec, vim.deepcopy(maps))
  end
  return resolve(spec)
end

function M.on_attach(_, buffer, deps)
  deps = deps or {}
  local Keys = deps.Keys or require 'lazy.core.handler.keys'
  local keymaps = M.resolve(buffer, deps)

  for _, keys in pairs(keymaps) do
    if not keys.has or M.has(buffer, keys.has, deps) then
      local opts = Keys.opts(keys)
      opts.has = nil
      opts.silent = opts.silent ~= false
      opts.buffer = buffer
      local set = deps.set or vim.keymap.set
      set(keys.mode or 'n', keys.lhs, keys.rhs, opts)
    end
  end
end

function M.setup(deps)
  deps = deps or {}
  local handlers = deps.handlers or vim.lsp.handlers
  if configured_handlers[handlers] then return end
  configured_handlers[handlers] = true
  local register_on_attach = deps.register_on_attach or require('util').lsp.on_attach
  local get_client_by_id = deps.get_client_by_id or vim.lsp.get_client_by_id
  local apply = deps.apply or function(client, buffer)
    M.on_attach(client, buffer)
  end

  register_on_attach(apply)

  local register_capability = handlers['client/registerCapability']
  handlers['client/registerCapability'] = function(err, res, ctx, config)
    local ret
    if register_capability then ret = register_capability(err, res, ctx, config) end
    local client = ctx and get_client_by_id(ctx.client_id)
    if client then
      for buffer in pairs(client.attached_buffers or {}) do
        apply(client, buffer)
      end
    end
    return ret
  end
end

return M
