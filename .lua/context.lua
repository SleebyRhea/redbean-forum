local fm = require("fullmoon")

---@generic T
---@param wrapped_handler T
---@return context
local new_context = function (wrapped_handler)
  local call_handler = wrapped_handler

  ---@class context
  local self = {}

  ---set validators for a specific type of data to be checked upon visit
  ---@return context
  self.need_cookie = function (tbl)
    local validators = {}

    for k, v in pairs(tbl) do
      table.insert(validators, function (_)
        local ok, code, message = v(GetCookie(k))
        if not ok then
          error(fm.serveError(code, message))
        end
      end)
    end

    local old_handler = call_handler
    call_handler = function (req)
      for _, validator in ipairs(validators) do
        validator(req)
      end
      return old_handler(req)
    end

    return self
  end

  ---@param validator fun(req:table):any
  ---@return context
  self.must_pass = function (validator)
    local old_handler = call_handler
    call_handler = function (req)
      local ok, code, message = validator(req)
      if not ok then
        error(fm.serveError(code, message))
      end
    end
    return self
  end

  self.init = function ()
    return call_handler
  end

  return self
end

return {
  new = new_context
}