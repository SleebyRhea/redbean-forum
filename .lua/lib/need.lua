---@generic T
---@param execute T
---@param ... string
---@return T
return function (execute, ...)
  local argv = { ... }
  local argc = #argv

  -- assign i to which to preserve it within the local scope
  -- (i will be overwritten otherwise, and this is not desired)
  for i = argc, 1, -1 do
    local which = i
    local want = argv[which]
    local execute_after = execute

    if want:match("?$") then
      execute = function (...)
        local t = type(select(which, ...) or nil)
        if t ~= want and not t == nil then
          return nil, "argument " .. which .." needs <" .. want .. ">, but got a <" .. t .. ">"
        end
        return execute_after(...)
      end
    else
      execute = function (...)
        local t = type(select(which, ...) or nil)
        if t ~= want then
          return nil, "argument " .. which .." needs <" .. want .. ">, but got a <" .. t .. ">"
        end
        return execute_after(...)
      end
    end
  end

  return function (...)
    return execute(...)
  end
end