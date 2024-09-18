local detour = require 'detour'
local features = require 'detour.features'
local telescope = require 'telescope.builtin'

local M = {}

M._keys = nil

function M.get()
  if M._keys then
    return M._keys
  end
  M._keys = {
    { '<leader>li', '<cmd>LspInfo<cr>', desc = 'Lsp Info [li]' },
    {
      'gd',
      '<cmd>Trouble definition_prev<cr>',
      desc = 'Goto Definition <gd>',
    },
    {
      'gr',
      '<cmd>Trouble references_prev<cr>',
      desc = 'Goto References <gr>',
    },
    {
      'gI',
      '<cmd>Trouble implementations_prev<cr>',
      desc = 'Goto Implementation <gI>',
    },
    {
      'gD',
      '<cmd>Trouble type_definition_prev<cr>',
      desc = 'Goto Type Definition <gy>',
    },
    { '<leader>cs', '<cmd>Trouble symbols toggle<cr>', desc = 'Document Symbols [cs]' },
    {
      '<leader>cw',
      function()
        local popup_id = detour.Detour()
        if popup_id then
          vim.bo.bufhidden = 'delete'
          telescope.lsp_workspace_symbols {}
          features.ShowPathInTitle(popup_id)
          vim.keymap.set('n', 'q', function()
            vim.cmd 'close'
          end, { desc = 'Close window [q]' })
        end
      end,
      desc = 'Workspace Symbols [cw]',
    },
    {
      '<leader>cW',
      function()
        local popup_id = detour.Detour()
        if popup_id then
          vim.bo.bufhidden = 'delete'
          telescope.lsp_dynamic_workspace_symbols {}
          features.ShowPathInTitle(popup_id)
          vim.keymap.set('n', 'q', function()
            vim.cmd 'close'
          end, { desc = 'Close window [q]' })
        end
      end,
      desc = 'Dynamic Workspace Symbols [cW]',
    },
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
      '<cmd>Lspsaga code_action<cr>',
      desc = 'Code Action [ca]',
      mode = { 'n', 'v' },
    },
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
