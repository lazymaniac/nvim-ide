local M = {}

local function default_osc52()
  local osc52 = require 'vim.ui.clipboard.osc52'
  return {
    name = 'OSC 52',
    copy = {
      ['+'] = osc52.copy '+',
      ['*'] = osc52.copy '*',
    },
    paste = {
      ['+'] = osc52.paste '+',
      ['*'] = osc52.paste '*',
    },
  }
end

local function defaults()
  return {
    os = vim.uv.os_uname().sysname,
    home = vim.env.HOME,
    data = vim.fn.stdpath 'data',
    env = vim.env,
    path = vim.env.PATH or '',
    is_dir = function(path)
      local stat = vim.uv.fs_stat(path)
      return stat ~= nil and stat.type == 'directory'
    end,
    set_path = function(path) vim.env.PATH = path end,
    get_clipboard = function() return vim.g.clipboard end,
    set_clipboard = function(provider) vim.g.clipboard = provider end,
    osc52 = default_osc52,
  }
end

local function candidates(deps)
  local common = {
    deps.home .. '/.local/bin',
    deps.home .. '/.asdf/shims',
    deps.data .. '/mason/bin',
  }
  if deps.os == 'Darwin' then
    vim.list_extend(common, {
      '/opt/homebrew/bin',
      '/opt/homebrew/sbin',
      '/usr/local/bin',
      '/usr/local/sbin',
    })
  elseif deps.os == 'Linux' then
    table.insert(common, 2, deps.home .. '/.cargo/bin')
    table.insert(common, 3, deps.home .. '/go/bin')
    vim.list_extend(common, {
      '/home/linuxbrew/.linuxbrew/bin',
      '/home/linuxbrew/.linuxbrew/sbin',
      '/usr/local/bin',
      '/usr/local/sbin',
    })
  end
  return common
end

function M.setup(overrides)
  local deps = vim.tbl_extend('force', defaults(), overrides or {})
  local current, seen = {}, {}
  for entry in (deps.path .. ':'):gmatch '(.-):' do
    if entry ~= '' and not seen[entry] then
      current[#current + 1] = entry
      seen[entry] = true
    end
  end

  local added = {}
  for _, path in ipairs(candidates(deps)) do
    if not seen[path] and deps.is_dir(path) then
      added[#added + 1] = path
      seen[path] = true
    end
  end
  local hydrated = vim.list_extend(vim.deepcopy(added), current)
  deps.set_path(table.concat(hydrated, ':'))

  local clipboard = 'local'
  if deps.get_clipboard() ~= nil then
    clipboard = 'user'
  elseif deps.env.SSH_CONNECTION or deps.env.SSH_TTY then
    deps.set_clipboard(deps.osc52())
    clipboard = 'osc52'
  end

  return {
    os = deps.os,
    path = hydrated,
    added = added,
    clipboard = clipboard,
    shell_invoked = false,
  }
end

return M
