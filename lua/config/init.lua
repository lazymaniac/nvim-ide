local Util = require 'util'

local M = {}

local options = {
  -- load the default settings
  defaults = {
    autocmds = true, -- config.autocmds
    keymaps = true, -- config.keymaps
    -- config.options can't be configured here since that's loaded before lazyvim setup
    -- if you want to disable loading options, add `package.loaded["config.options"] = true` to the top of your init.lua
  },
  -- icons used by other plugins
  icons = {
    misc = {
      dots = '󰇘',
    },
    dap = {
      Stopped = { '󰁕 ', 'DiagnosticWarn', 'DapStoppedLine' },
      Breakpoint = ' ',
      BreakpointCondition = ' ',
      BreakpointRejected = { ' ', 'DiagnosticError' },
      LogPoint = '.>',
    },
    diagnostics = {
      Error = ' ',
      Warn = ' ',
      Hint = ' ',
      Info = ' ',
    },
    git = {
      added = ' ',
      modified = ' ',
      removed = ' ',
    },
    kinds = {
      Array = ' ',
      Boolean = '󰨙 ',
      Class = ' ',
      Codeium = '󰘦 ',
      Color = ' ',
      Control = ' ',
      Collapsed = ' ',
      Constant = '󰏿 ',
      Constructor = ' ',
      Copilot = ' ',
      Enum = ' ',
      EnumMember = ' ',
      Event = ' ',
      Field = ' ',
      File = ' ',
      Folder = ' ',
      Function = '󰊕 ',
      Interface = ' ',
      Key = ' ',
      Keyword = ' ',
      Method = '󰊕 ',
      Module = ' ',
      Namespace = '󰦮 ',
      Null = ' ',
      Number = '󰎠 ',
      Object = ' ',
      Operator = ' ',
      Package = ' ',
      Property = ' ',
      Reference = ' ',
      Snippet = ' ',
      String = ' ',
      Struct = '󰆼 ',
      TabNine = '󰏚 ',
      Text = ' ',
      TypeParameter = ' ',
      Unit = ' ',
      Value = ' ',
      Variable = '󰀫 ',
    },
  },
}

function M.setup(opts)
  M.load 'autocmds'
  M.load 'keymaps'
  Util.root.setup()
end

function M.load(name)
  local function _load(mod)
    if require('lazy.core.cache').find(mod)[1] then
      Util.try(function()
        require(mod)
      end, { msg = 'Failed loading ' .. mod })
    end
  end
  if M.defaults[name] or name == 'options' then
    _load('config.' .. name)
  end
  _load('config.' .. name)
  if vim.bo.filetype == 'lazy' then
    vim.cmd [[do VimResized]]
  end
  local pattern = 'LazyVim' .. name:sub(1, 1):upper() .. name:sub(2)
  vim.api.nvim_exec_autocmds('User', { pattern = pattern, modeline = false })
end

M.did_init = false
function M.init()
  if M.did_init then
    return
  end
  M.did_init = true

  -- delay notifications till vim.notify was replaced or after 500ms
  require('util').lazy_notify()

  -- load options here, before lazy init while sourcing plugin modules
  -- this is needed to make sure options will be correctly applied
  -- after installing missing plugins
  M.load 'options'
end

setmetatable(M, {
  __index = function(_, key)
    if options == nil then
      return vim.deepcopy(defaults)[key]
    end
    return options[key]
  end,
})

return M
