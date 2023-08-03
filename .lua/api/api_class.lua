local new_api <const> = function (name)
  local string_rep = "Api[" .. name .. "]"

  local __tostring <const> = function ()
    return string_rep
  end

  local self = {
    get    = { directory = {}, thread = {}, post = {} },
    post   = { directory = {}, thread = {}, post = {} },
    push   = { directory = {}, thread = {}, post = {} },
    patch  = { directory = {}, thread = {}, post = {} },
    delete = { directory = {}, thread = {}, post = {} },
  }

  setmetatable(self, {
    __tostring = __tostring,
  })

  return self
end

return new_api