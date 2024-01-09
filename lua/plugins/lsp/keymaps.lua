local M = {}

M._keys = nil

function M.get()
  if M._keys then
    return M._keys
  end
  M._keys = {
    { '<leader>cl', '<cmd>LspInfo<cr>', desc = 'Lsp Info' },
    {
      'gd',
      function()
        require('telescope.builtin').lsp_definitions { reuse_win = true }
      end,
      desc = '[G]oto [D]efinition',
      has = 'definition',
    },
    { 'gr', '<cmd>Telescope lsp_references<cr>', desc = '[G]oto [R]eferences' },
    { 'gD', vim.lsp.buf.declaration, desc = '[G]oto [D]eclaration' },
    {
      'gI',
      function()
        require('telescope.builtin').lsp_implementations { reuse_win = true }
      end,
      desc = '[G]oto [I]mplementation',
    },
    {
      'gy',
      function()
        require('telescope.builtin').lsp_type_definitions { reuse_win = true }
      end,
      desc = '[G]oto T[y]pe Definition',
    },
    {
      '<leader>cs',
      function()
        require('telescope.builtin').lsp_document_symbols()
      end,
      desc = 'Do[c]ument [S]ymbols',
    },
    {
      '<leader>cw',
      function()
        require('telescope.builtin').lsp_dynamic_workspace_symbols()
      end,
      desc = 'Workspa[c]e [S]ymbols',
    },
    -- See `:help K` for why this keymap
    { 'K', vim.lsp.buf.hover, desc = 'Hover Documentation' },
    { 'gK', vim.lsp.buf.signature_help, desc = 'Signature Documentation', has = 'signatureHelp' },
    { '<c-k>', vim.lsp.buf.signature_help, mode = 'i', desc = 'Signature Help', has = 'signatureHelp' },
    { '<leader>ca', vim.lsp.buf.code_action, desc = '[C]ode [A]ction', mode = { 'n', 'v' }, has = 'codeAction' },
    {
      '<leader>cA',
      function()
        vim.lsp.buf.code_action {
          context = {
            only = {
              'source',
            },
            diagnostics = {},
          },
        }
      end,
      desc = 'Sour[c]e [A]ction',
      has = 'codeAction',
    },

    -- Workspace actions
    { '<leader>cWa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder' },
    { '<leader>cWr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder' },
    {
      '<leader>cWl',
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      '[W]orkspace [L]ist Folder',
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
      desc = '[C]ode [R]ename',
      has = 'rename',
    }
  else
    M._keys[#M._keys + 1] = { '<leader>cr', vim.lsp.buf.rename, desc = '[C]ode [R]ename', has = 'rename' }
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
