local M = {}

function M.args(fn, wrapper)
  return function(...)
    if wrapper(...) == false then
      return
    end
    return fn(...)
  end
end

function M.get_upvalue(func, name)
  local i = 1
  while true do
    local n, v = debug.getupvalue(func, i)
    if not n then
      break
    end
    if n == name then
      return v
    end
    i = i + 1
  end
end

return M
