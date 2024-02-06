local M = {}

M._keys = nil

function M.get()
  if M._keys then
    return M._keys
  end
  -- stylua: ignore
  M._keys = {
    { '<leader>li', '<cmd>LspInfo<cr>', desc = 'Lsp Info [li]' },
    { 'gd', '<cmd>Glance definitions<CR>', desc = 'Goto Definition <gd>', has = 'definition', },
    { 'gr', '<cmd>Glance references<CR>', desc = 'Goto References <gr>' },
    { 'gI', '<cmd>Glance implementations<CR>', desc = 'Goto Implementation <gI>', },
    { 'gD', '<cmd>Glance type_definitions<CR>', desc = 'Goto Type Definition <gy>', },
    { '<leader>cs', '<cmd>Telescope lsp_document_symbols<cr>', desc = 'Document Symbols [cs]', },
    { '<leader>cw', '<cmd>Telescope lsp_workspace_symbols<cr>', desc = 'Workspace Symbols [cw]', },
    { '<leader>cW', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', desc = 'Dynamic Workspace Symbols [cW]', },
    { '<leader>ci', '<cmd>Telescope lsp_outgoing_calls<cr>', desc = 'Incoming Calls [ci]', },
    { '<leader>co', '<cmd>Telescope lsp_outgoing_calls<cr>', desc = 'Outgoing Calls [co]', },
    { 'K', vim.lsp.buf.hover, desc = 'Hover Documentation <K>' },
    { 'gK', vim.lsp.buf.signature_help, desc = 'Signature Documentation <gK>', has = 'signatureHelp' },
    { '<C-k>', vim.lsp.buf.signature_help, mode = 'i', desc = 'Signature Help <C-k>', has = 'signatureHelp' },
    { '<leader>ca', function() require('actions-preview').code_actions() end, desc = 'Code Action [ca]', mode = { 'n', 'v' }, has = 'codeAction' },
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
