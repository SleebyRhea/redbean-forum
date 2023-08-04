local fm = require("lib.fullmoon")

local require_body = function (req)
  if not req.body then
    error(fm.serveError(401, "bad request (missing request body)"))
  end
end

local require_content = function (wanted_content)
  local lower = string.lower
  wanted_content = lower(assert(wanted_content, "please provide a content type"))
  return function (req)
    if lower(req.headers["Content-Type"]) ~= wanted_content then
      error(fm.serveError(401, "bad request (invalid content type)"))
    end
  end
end


---@param wrapped_handler fun(req:table): any
local new = function (wrapped_handler)

  ---@class endpoint
  local self = setmetatable({}, {
    __call = function ()
      return wrapped_handler
    end
  })

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

  self.has_param = function (param, want_type)
    local old_handler = wrapped_handler
    wrapped_handler = function (req)
      if type(req.params[param]) ~= want_type then
        error(fm.serveError(403, "missing parameter (%s must be %s)" % {
          param, want_type
        }))
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
      return old_handler(req)
    end
    return self
  end

  return self
end

return {
  new = new,
  middleware = {
    require_body = require_body,
    require_content = require_content
  }
}