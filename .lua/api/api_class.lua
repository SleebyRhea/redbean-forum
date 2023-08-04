local new_api <const> = function (name)
  local string_rep = "Api[" .. name .. "]"

  local __tostring <const> = function ()
    return string_rep
  end

  local self = {
    get    = {},
    post   = {},
    push   = {},
    patch  = {},
    delete = {},
  }

  setmetatable(self, {
    __tostring = __tostring,
  })

  return self
end

return new_api