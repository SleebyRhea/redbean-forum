local fm = require("lib.fullmoon")

---@param wrapped_handler fun(req:table): any
local new = function (wrapped_handler)

  ---@class context
  local self = {}

  self.get_handler = function ()
    return wrapped_handler
  end

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

    local old_handler = wrapped_handler
    wrapped_handler = function (req)
      for _, validator in ipairs(validators) do
        validator(req)
      end
      return old_handler(req)
    end

    return self
  end

   self.must_pass = function (validator)
    local old_handler = wrapped_handler
    wrapped_handler = function (req)
      local ok, code, message = validator(req)
      if not ok then
        error(fm.serveError(code, message))
      end
    end
    return self
  end

  return setmetatable(self, {
    __call = self.get_handler
  })
end

return {
  new = new
}