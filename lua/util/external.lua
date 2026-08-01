local M = {}

local function default_adapters()
  return {
    executable = vim.fn.executable,
    notify = vim.notify,
    toggle = function(command)
      Snacks.terminal.toggle(command)
    end,
  }
end

---@param action {id:string, command:string[]}
---@param adapters? {executable:fun(name:string):integer, notify:fun(message:string, level:integer), toggle:fun(command:string[])}
---@return fun():boolean
function M.terminal(action, adapters)
  assert(type(action) == 'table' and type(action.command) == 'table' and action.command[1], 'invalid external action')
  adapters = adapters or default_adapters()

  return function()
    local executable = action.command[1]
    if adapters.executable(executable) == 1 then
      adapters.toggle(vim.deepcopy(action.command))
      return true
    end

    adapters.notify(('%s is not executable. Install it, then run :checkhealth nv_ide for verification.'):format(executable), vim.log.levels.WARN)
    return false
  end
end

return M
