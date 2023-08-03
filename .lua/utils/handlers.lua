local handlers = {}

local only_on_init; do
  local _stub = function () end
  only_on_init = function (fn)
    if unix.getpid() == unix.getppid() then
      return fn
    end
    return _stub
  end
end

local register_handler = function (handler_name, fn)
  if not handlers[handler_name] then
    handlers[handler_name] = {}
  end
  table.insert(handlers[handler_name], fn)
end

local call_handlers = function (handler_name, ...)
  for _, callback in ipairs(handlers[handler_name] or {}) do
    callback(...)
  end
end

return {
  call_handlers = call_handlers,
  register_handler = only_on_init(register_handler)
}